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
        Bus.create [%here] Arity1 ~allow_subscription_after_first_write:true ~on_callback_raise:ignore
      in
      let bus_ro = Bus.read_only bus in
      Tcp.Server.create (Tcp.on_port port) (fun addr reader writer ->
        Core.Std.printf !"%{Socket.Address.Inet} connected\n%!" addr;
        let subscriber = Bus.subscribe_exn bus_ro [%here] ~f:(write_message writer) in
        iter_messages reader ~f:(Bus.write bus)
        >>= fun (_ : _ Unpack_sequence.Unpack_iter_result.t) ->
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