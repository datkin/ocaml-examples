open Core.Std
open Async.Std

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
        let subscriber = Bus.subscribe_exn bus_ro [%here] ~f:(Writer.write writer) in
        Pipe.iter_without_pushback (Reader.pipe reader) ~f:(Bus.write bus)
        >>= fun () ->
        Bus.unsubscribe bus_ro subscriber;
        Core.Std.printf !"%{Socket.Address.Inet} disconnected\n%!" addr;
        Deferred.unit)
      >>= fun server ->
      Core.Std.printf "listening\n%!";
      Tcp.Server.close_finished server)

let client =
  Command.async
    ~summary:"The client"
    (Command.Spec.(empty +> anon ("host:port" %: (Arg_type.create Host_and_port.of_string))))
    (fun host_and_port () ->
      let host, port = Host_and_port.tuple host_and_port in
      Tcp.with_connection (Tcp.to_host_and_port host port) (fun _ reader writer ->
        Core.Std.printf "connected\n%!";
        Deferred.any [
          Pipe.iter_without_pushback (Reader.pipe reader) ~f:(printf "got: %s\n%!");
          Pipe.iter_without_pushback (Reader.lines (force Reader.stdin)) ~f:(Writer.write writer);
        ]))

let () =
  Command.group
    ~summary:"Basic echo-style broadcast server/client"
    [ "server", server; "client", client; ]
  |> Command.run
