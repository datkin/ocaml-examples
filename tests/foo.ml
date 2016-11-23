open! Core.Std

let%expect_test _ =
  printf "x";
  [%expect {| |}];
;;
