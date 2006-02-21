(*
raise expression.
rule 11

A raise expression can be typed as any type.
 *)

exception E1;
val v1 = if false then raise E1 else 1;
