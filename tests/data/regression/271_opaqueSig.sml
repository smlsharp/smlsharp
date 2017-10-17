structure S :> sig
  eqtype t
  val x : t
end
=
struct
  type t = int
  val x = 0
end

(*
2013-12-12 katsu

This causes an unexpected provide check failure.

271_opaqueSig.smi:3.9-3.17 Error:
  (name evaluation "CP-350") Provide check fails (equality type expected): S.t

*)

(* 2013-12-13 ohori
この現象はng版（SML# version 1.3.0-pre4 (2013-11-07 17:44:36 JST 4bb530163c1c)），
llvm版（SML# 1.3.0-pre4 (2013-12-13 11:56:17 JST ee620666ed3d)）ともに再現しない．
*)

(*
2014-01-26 katsu

This ticket seems to be my mistake.
I withdraw this ticket.
*)
