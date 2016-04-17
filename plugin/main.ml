open Core.Std
open Async.Std
open Ocaml_plugin.Std

module Plugin = Ocaml_dynloader.Make (struct
  type t = (module Plugin_intf.S)
  let t_repr = "Plugin_intf.S"
  let univ_constr = Plugin_intf.univ_constr
  let univ_constr_repr = "Plugin_intf.univ_constr"
end)

let config = Plugin_cache.Config.create ~dir:"/tmp" ()

(* If we specify this, start up should be faster on additional runs. *)
let persistent_archive_dirpath = "/tmp/plugin-example-archive"

let command =
  Command.async_or_error
    ~summary:"Continually load the plugin, print the message as it updates"
    Command.Spec.(
      empty
      +> anon ("plugin.ml" %: file)
    )
    (fun file () ->
      Ocaml_compiler.create ~use_cache:config ~persistent_archive_dirpath ()
      >>=? fun (`this_needs_manual_cleaning_after ocaml_compiler) ->
      let loader = Ocaml_compiler.loader ocaml_compiler in
      Deferred.forever None (fun prev_md5 ->
        let md5 = Some (Digest.file file |> Digest.to_hex) in
        begin
          if Option.equal String.equal prev_md5 md5
          then Deferred.unit
          else begin
            Plugin.load_ocaml_src_files loader [file]
            >>| function
            | Error err -> eprintf !"%{Error#hum}\n%!" err
            | Ok plugin ->
              let module M = (val plugin : Plugin_intf.S) in
              printf "%s\n%!" M.message
          end
        end
        >>= fun () ->
        Clock.after (sec 1.)
        >>= fun () ->
        return md5);
      Deferred.create (fun ivar ->
        Signal.handle Signal.terminating ~f:(fun (_ : Signal.t) ->
          Ivar.fill ivar ()))
      >>= fun () ->
      return (Ok ())
      (*Ocaml_compiler.clean ocaml_compiler*))

let () = Command.run command