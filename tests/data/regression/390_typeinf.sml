datatype exp = LET of dec and dec = FUN of exp
datatype exp2 = LET2 of dec2 and dec2 = FUN2 of int option * exp2
fun transExp (LET dec) = LET2 (transDec dec)
and transDec (FUN exp) = FUN2 (transFun exp)
and transFun exp = transBody exp
and transBody exp = (NONE, transExp exp)

(*
2025-11-22 katsu

This causes an unexpected type error.

o.sml:3.0(113)-6.39(275) Error:
  (type inference 072) definition and occurrence of "transBody" don't agree.
  definition: exp -> ['a. 'a option] * exp2
  occurrence: exp -> int option * exp2
*)
