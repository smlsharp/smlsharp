_interface "103_unit.smi"
val x = ()

(*
2011-09-02 katsu

This causes an unexpected type error.
The "unit" type must be identical to the empty record type.
(The Definition, p.67)

103_unit.smi:1.5-1.10 Error:
  (type inference 063) type and type annotation don't agree
    inferred type: unit(t7[])
  type annotation: {}
*)

(*
2011-09-02 ohori

Name evaluation translate the empty record type to unitTy,
and will not generate the empty record type.
So this should fix the bug.

*)

(*
2016-12-19 katsu

空のレコード型{}とunit型を区別するように仕様変更
unitは直積の単位元である一方，レコード構築には単位元はない，という発想に基づく．
*)
