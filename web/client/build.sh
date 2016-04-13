#!/bin/bash

set -o errexit

# opam switch install for-js --alias-of 4.02.3+32bit-natdynlink
opam switch for-js && eval $(opam config env)

ocamlbuild \
  test.byte \
  -pkg js_of_ocaml \
  -pkg js_of_ocaml.async \
  -pkg async_kernel \
  -tag "ppx($(opam config var lib)/js_of_ocaml/ppx_js)" \
  -tag 'ppx(ppx-jane -as-ppx)' \
  -tag debug

js_of_ocaml \
  +bin_prot.js \
  +core_kernel.js \
  +nat.js \
  test.byte \
  --source-map-inline
