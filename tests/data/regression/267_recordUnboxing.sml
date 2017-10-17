datatype t = C of string * int | D of string * t
fun f (_:int, _:int, x:int) = C ("hoge", x)
fun g x = D ("fuga", f (#l x))

(*
2013-10-16 katsu

This causes BUG at RecordUnboxing.

t42
#{l$00001: int(t0[]), l$00002: int(t0[]), l$00003: int(t0[])}
l
option in filedType (2)recordTy
t42
newRecordTy
t42
l[BUG] CTX filedType

*)
(*
2014-01-26 katsu

The above error does not occur on LLVM backend.
*)
