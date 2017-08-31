fun func a b c d {e={f, g}, ...} = f

(*
2012-12-04 katsu

This causes BUG at RecordUnboxing.

t11
#{e$00001: t9, e$00002: t10}
e
option in filedType (2)recordTy
t11
newRecordTy
t11
e[BUG] CTX filedType
*)
(*
2013-01-26 katsu

This does not cause any error on LLVM backend.

*)
