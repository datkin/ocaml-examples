open Core_kernel.Std
open Async_kernel.Std

let (_ : string) = sprintf !"%{sexp:Unit.t}" ()

let () = Async_js.init ()

let () =
  Clock_ns.every (Time_ns.Span.of_int_sec 1) (fun () ->
    let ns_since_epoch = Time_ns.to_int63_ns_since_epoch (Time_ns.now ()) in
    Firebug.console##log (Js.string (sprintf !"%{Int63}" ns_since_epoch)))
;;
