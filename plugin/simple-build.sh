#!/bin/bash

# Here's a simpler build script which makes use of ocamlfind rules.

set -o errexit
set -x

opam switch 4.02.3 && eval $(opam config env)

ocamlbuild -clean

  #-ocamlopt "ocamlopt $(opam config var lib)/ocaml_plugin/ocaml_plugin_ocamlbuild.cmx" \
  #-just-plugin \
  #-verbose 3 \
ocamlbuild \
  -use-ocamlfind \
  -pkg core \
  -pkg async \
  -pkg ocaml_plugin \
  -tag 'ppx(ppx-jane -as-ppx)' \
  -tag debug \
  -tag thread \
  -tag use_archive \
  main.native
