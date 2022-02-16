val r = _dynamic (_dynamic Dynamic.dynamic {x=0, y=42} as Dynamic.dynamic) as {x:int} Dynamic.dyn;

(*
 _dynamic を入れ子にすると Bug.Bug: compileExp: TPDYNAMIC #67 
leque opened this issue on 3 May 2021 · 0 comments 

次のように _dynamic を入れ子にすると Bug.Bug: compileExp: TPDYNAMIC 例外が発生します。

$ smlsharp
SML# 4.0.0 (2021-04-06 05:12:50 JST) for x86_64-apple-darwin20.4.0 with LLVM 12.0.0
# _dynamic (_dynamic Dynamic.dynamic {x=0, y=42} as Dynamic.dynamic) as {x:int} Dynamic.dyn;
Bug.Bug: compileExp: TPDYNAMIC at src/compiler/compilePhases/datatypecompilation/main/DatatypeCompilation.sml:678.14(25068)
*)
