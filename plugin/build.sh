#!/bin/bash

opam swithc 4.02.3 && eval $(opam config env)

stubs=embedded_compiler_stubs

rm ${stubs}.c

ocamlbuild \
  -pkg ocaml_plugin \
  plugin_intf.cmi

ocaml-embed-compiler \
  -cc $(which ocamlopt.opt) \
  _build/plugin_intf.cmi \
  $(ocamlfind query ocaml_plugin)/ocaml_plugin.cmi \
  $(opam config var lib)/ocaml/pervasives.cmi \
  -o ${stubs}.c

gcc \
  -I$(opam config var lib)/ocaml \
  -c ${stubs}.c \
  -o _build/${stubs}.o

ocamlbuild \
  -use-ocamlfind \
  -pkg core \
  -pkg async \
  -pkg ocaml_plugin \
  -tag 'ppx(ppx-jane -as-ppx)' \
  -tag debug \
  -tag thread \
  main.native
