open! Core.Std

let%test_unit _ =
  assert false;
;;

let%expect_test _ =
  printf "x";
  [%expect {| |}];
;;
