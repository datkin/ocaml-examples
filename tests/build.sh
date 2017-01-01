#!/bin/bash

set -o errexit

  #-verbose 1 \
ocamlbuild \
  -use-ocamlfind \
  -pkg core,ppx_expect.evaluator \
  -tag thread \
  -tag 'ppx(ppx-jane -as-ppx -inline-test-lib example_lib)' \
  -cflags -verbose,-w,+a-40-42-44 \
  -lflags -verbose \
  example_lib.cmxa \
  bin/inline_test_runner.native

./inline_test_runner.native \
  inline-test-runner \
  example_lib \
  -verbose

echo done
