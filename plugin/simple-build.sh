#!/bin/bash

# Here's a simpler build script which makes use of ocamlfind rules.

set -o errexit
set -x

opam switch 4.02.3 && eval $(opam config env)

ocamlbuild -clean

# The following options to `ocamlbuild` may be helpful...
#   -just-plugin \
#   -verbose 3 \

# The top two flags are *just* for building myocamlbuild.ml with access to the
# Ocaml_plugin_ocamlbuild module. I would imagine there's a better way, but I
# haven't found it yet.
ocamlbuild \
  -lflag "-I" -lflag $(opam config var lib)/ocaml_plugin \
  -lflag $(opam config var lib)/ocaml_plugin/ocaml_plugin_ocamlbuild.cmxa \
  -use-ocamlfind \
  -pkg core \
  -pkg async \
  -pkg ocaml_plugin \
  -tag 'ppx(ppx-jane -as-ppx)' \
  -tag debug \
  -tag thread \
  -tag use_archive \
  main.native
