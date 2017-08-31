(* testlink -> README と仮定 *)
val x = OS.FileSys.realPath "testlink";
val y = OS.FileSys.fullPath "testlink";

val _ = case x of "README" => () | _ => raise Fail "ng";
val _ = case String.isSuffix "README" y of true => () | _ => raise Fail "ng";

(* 2014-01-27 ohori
リンクが展開されない．
# OS.FileSys.realPath "testlink";
val it = "testlink" : string
# OS.FileSys.fullPath "testlink";
val it = "/home/ohori/work/smlsharpHg/smlsharp_llvm/doc/tests/testlink" : string

*)

(*
2014-01-30 katsu

fixed by changeset 7fc664ee0180
*)
