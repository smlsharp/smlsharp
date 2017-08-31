OS.FileSys.mkDir "testdir";
(OS.FileSys.remove "testdir"; raise Fail "ng") handle OS.SysErr _ => ();

(* 2014-01-27 ohori
OS.FileSys.mkDir "testdir";
# val it = () : unit
# OS.FileSys.remove "testdir";
val it = () : unit

OS.FileSys.remove "testdir";は失敗するはず．
*)

(*
2014-01-29 katsu

fixed by changeset 66eb3875cb9a
*)
