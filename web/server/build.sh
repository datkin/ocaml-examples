#!/bin/bash

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
