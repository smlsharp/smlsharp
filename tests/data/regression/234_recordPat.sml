fun f {a=(b,c),...} = b
(*
2012-08-28 katsu

This causes BUG.

t31
#{a$00001: t29, a$00002: t30}
a
option in filedType (2)recordTy
t31
newRecordTy
t31
a[BUG] CTX filedType
*)

(*
2012-09-18 katsu
This bug does not occur in interactive mode.
*)

(*
2012-09-21 ohori
This does not reproduce. Perhaps, some of fixes made after this should have
been fixed this.
*)
