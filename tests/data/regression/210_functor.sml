signature SType = sig type dt end
structure PType = struct type t = real end
functor FTypeOpaq(type t) :> SType = struct datatype dt = D of t end;
structure TTypeOpaq = FTypeOpaq(PType);

(*
2012-7-13 hikaru

This causes a BUG at structure made from functor.
[BUG] EvalITy: free tvar:'t 
*)

(*
2012-7-19 ohori
Fixed by 4316:de46c532c718.
The bug is roughly as follows.
The opaque signature generates a new data type definition
  TFUN_DTY that contain the original tfun in the 
  dtyKind as OPAQUE{tfun=tfun, revealKey=...}.
But setLiftedTy does not trace the dtyKind and thefore 
the liftedTys in tfun is incorrect.

This is solved by making a depenndency link from the new tfun to
the original tfun. The SCC computation in liftedTys then works properly.

*)

