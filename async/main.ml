open Core.Std
open Async.Std

type message = {
  sender : string;
  time : Time.t;
  data : string;
} [@@deriving bin_io, sexp]

let write_message writer message =
  Writer.write_bin_prot writer bin_writer_message message

let iter_messages reader ~f =
  Unpack_sequence.unpack_iter
    ~from:(Reader reader)
    ~using:(Unpack_buffer.create_bin_prot bin_reader_message)
    ~f

let server =
  Command.async
    ~summary:"The server"
    Command.Spec.(empty +> anon ("port" %: int))
    (fun port () ->
      let bus : (_, read_write) Bus.t =
        Bus.create [%here] Arity3 ~allow_subscription_after_first_write:true ~on_callback_raise:ignore
      in
      let bus_ro = Bus.read_only bus in
      Tcp.Server.create (Tcp.on_port port) (fun addr reader writer ->
        let file_descr = Writer.fd writer |> Fd.file_descr_exn in
        Core.Std.printf !"%{Socket.Address.Inet} connected\n%!" addr;
        let subscriber =
          Bus.subscribe_exn bus_ro [%here] ~f:(fun buf (`Pos pos) (`Len len) ->
            let written = Bigstring.write file_descr buf ~pos ~len in
            if written < len
            then begin
              Reader.close reader;
              Core.Std.printf !"Booting %{Socket.Address.Inet}\n%!" addr;
            end)
        in
        Reader.read_one_chunk_at_a_time
          reader
          ~handle_chunk:(fun buf ~pos ~len ->
            let header_length = Bin_prot.Utils.size_header_length in
            if len < header_length
            then return (`Consumed (0, `Need header_length))
            else begin
              let pos_ref = ref pos in
              let size = Bin_prot.Utils.bin_read_size_header buf ~pos_ref in
              assert (!pos_ref = pos + header_length);
              if size > len - header_length
              then return (`Consumed (0, `Need (header_length + size)))
              else begin
                Bus.write bus buf (`Pos pos) (`Len (header_length + size));
                return (`Consumed (header_length + size, `Need_unknown))
              end
            end)
        >>= fun _ ->
        Bus.unsubscribe bus_ro subscriber;
        Core.Std.printf !"%{Socket.Address.Inet} disconnected\n%!" addr;
        Deferred.unit)
      >>= fun server ->
      Core.Std.printf "listening\n%!";
      Tcp.Server.close_finished server)

let client =
  Command.async
    ~summary:"The client"
    (Command.Spec.(
      empty
      +> flag "user" (optional string) ~doc:"name Name of user"
      +> anon ("host:port" %: (Arg_type.create Host_and_port.of_string))
    ))
    (fun sender host_and_port () ->
      let sender = Option.value sender ~default:(Core.Std.Unix.getlogin ()) in
      let host, port = Host_and_port.tuple host_and_port in
      Tcp.with_connection (Tcp.to_host_and_port host port) (fun _ reader writer ->
        Core.Std.printf "connected\n%!";
        Deferred.any [
          iter_messages reader ~f:(fun message ->
            printf !"%{sexp:message} %{Time.Span}\n%!"
              message (Time.diff (Time.now ()) message.time))
          >>| ignore;
          Pipe.iter_without_pushback (Reader.lines (force Reader.stdin))
            ~f:(fun data -> write_message writer { sender; time = Time.now (); data })
        ]))

let () =
  Command.group
    ~summary:"Basic echo-style broadcast server/client"
    [ "server", server; "client", client; ]
  |> Command.run
