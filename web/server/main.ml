open Core.Std
open Async.Std

let command =
  Command.async
    ~summary:"Webserver!"
    Command.Spec.(
      empty
      +> flag "ws-port" (optional_with_default 8081 int) ~doc:"int ws:// port"
      +> flag "http-port" (optional_with_default 8080 int) ~doc:"int http:// port"
    )
    (fun ws_port http_port () ->
      Tcp.Server.create
        (Tcp.on_port ws_port)
        (fun address reader writer ->
          let from_ws_r, from_ws_w = Pipe.create () in
          let to_ws_r, to_ws_w = Pipe.create () in
          don't_wait_for (
            Pipe.iter_without_pushback from_ws_r ~f:(fun frame ->
              Log.Global.info
                !"from %{sexp:Socket.Address.Inet.t}: %{sexp:Websocket_async.Frame.t}"
                address frame)
          );
          Clock.every (sec 1.) (fun () ->
            let frame : Websocket_async.Frame.t = {
              opcode = Text;
              extension = 0;
              final = true;
              content = Time.to_string (Time.now ());
            }
            in
            Pipe.write_without_pushback to_ws_w frame
          );
          Websocket_async.server
            ~app_to_ws:to_ws_r
            ~ws_to_app:from_ws_w
            ~net_to_ws:(Reader.pipe reader)
            ~ws_to_net:(Writer.pipe writer)
            (address :> Socket.Address.t))
      >>= fun server ->
      Tcp.Server.close_finished server)

let () = Command.run command
