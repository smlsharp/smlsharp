structure X = F(exception E)
structure Y = G(X)

(*
2011-12-01 katsu

This causes an unexpected type error.

174_functorexn.sml:2.15-2.18 Error:
  (type inference 091) operator and operand don't agree
  operator domain: exnTag(t13[]), exnTag(t13[])
  operand: exnTag(t13[])

*)

(*
2011-12-04 ohori

Fixed. Actual exception tag parameters to a functor must be determined
from the formal parameter signature, not an actual parameter structure,
since exception declaration in signature may be exception replication
in the actual structure.

*)
