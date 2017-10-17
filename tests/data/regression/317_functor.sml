functor F (type elem) =
struct
  type elem = elem
  datatype tree = EMPTY | TREE of elem * tree * tree
end

structure IntTree = F (struct type elem = int end)

val a = IntTree.EMPTY

(*
2014-11-12 Sasaki

This code raises 
Compiler bug:EvalITy: free tvar:'elem
in interactive mode.

if skipPrinter is yes, this bug is note raised.
*)
(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
