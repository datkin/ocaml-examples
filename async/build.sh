#!/bin/bash

opam switch 4.03.0 && eval $(opam config env)

ocamlbuild \
  -use-ocamlfind \
  -pkg core \
  -pkg async \
  -tag 'ppx(ppx-jane -as-ppx)' \
  -tag debug \
  -tag thread \
  main.native
