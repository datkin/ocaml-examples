open! Example_lib (* Ensure the test depends on [Example_lib]. *)

let () =
  let open Ppx_inline_test_lib in
  (*
  Runtime.summarize () |> Runtime.Test_result.to_string |> print_endline;
  *)
  Runtime.exit ();
;;
