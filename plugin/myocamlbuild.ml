open Ocamlbuild_plugin
open Ocaml_plugin_ocamlbuild

let program = "compiler"

let () =
  dispatch (function
    | After_rules ->
      embed
        ~program
        ~libraries:["sexplib"; "core"]
        ~local_cmi_files:["plugin_intf.cmi"]
        ~ppx:"ppx-jane"
        ();
      dep [ "ocaml"; "use_archive"; "link" ] [program ^ ".archive.o"];
    | _ -> ()
  )
