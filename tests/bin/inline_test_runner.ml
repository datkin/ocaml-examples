open! Core.Std

include Example_lib.Foo

let () =
  let open Ppx_inline_test_lib in
  Runtime.exit ();
;;
