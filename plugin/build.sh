#!/bin/bash

# Here's a build script which does most of the work "manually".

opam switch 4.02.3 && eval $(opam config env)

stubs=embedded_compiler_stubs

rm ${stubs}.c

ocamlbuild -clean

ocamlbuild \
  -pkg ocaml_plugin \
  plugin_intf.cmi

ocaml-embed-compiler \
  -cc $(which ocamlopt.opt) \
  -ppx $(which ppx-jane) \
  _build/plugin_intf.cmi \
  $(ocamlfind query ocaml_plugin)/ocaml_plugin.cmi \
  $(ocamlfind query sexplib)/sexplib.cmi \
  $(ocamlfind query core)/core.cmi \
  $(opam config var lib)/ocaml/pervasives.cmi \
  $(opam config var lib)/ocaml/camlinternalFormatBasics.cmi \
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
  -lflag -ccopt,${stubs}.o \
  main.native
