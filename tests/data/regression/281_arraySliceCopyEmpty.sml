val array0 = Array.fromList [] : int array
val slice00 = ArraySlice.slice(array0, 0, NONE)
val _ = ArraySlice.copy{src=slice00, dst=array0, di=0};
(* 2014-01-26 ohori
uncaught exception: Subscript at src/basis/main/./ArraySlice_common.sml:189
srcの長さが0の場合，例外は起こらないはず．
*)

(*
2014-01-29 katsu

fixed by changeset 7b37734ad177
*)
