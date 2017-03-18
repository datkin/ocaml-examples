#!/bin/bash

opam switch 4.03.0 && eval $(opam config env)

ocamlbuild \
  -use-ocamlfind \
  -pkg core \
  -pkg async \
  -pkg websocket \
  -pkg websocket.async \
  -pkg cohttp \
  -tag 'ppx(ppx-jane -as-ppx)' \
  -tag debug \
  -tag thread \
  main.native
