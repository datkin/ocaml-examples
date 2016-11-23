#!/bin/bash

set -o errexit

ocamlbuild \
  -use-ocamlfind \
  -pkg core,ppx_expect.evaluator \
  -tag thread \
  -tag 'ppx(ppx-jane -as-ppx -inline-test-lib example_lib)' \
  -cflags -w,+a-40-42-44 \
  example_lib.cmxa \
  inline_test_runner.native

./inline_test_runner.native \
  inline-test-runner \
  example_lib \
  -verbose

echo done
