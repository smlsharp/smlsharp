signature SType = 
sig
  type t
end;
structure PType = struct type t = real end;

functor FTypeOpaque(S : sig type t end) = 
struct datatype t = D of S.t end :> SType;
structure STypeOpaque = FTypeOpaque(PType);

(*
2012-07-11 endom

[BUG] EvalITy: free tvar:'t

functorの本体にopaqueでsignatureを適用し、かつそのfunctorを実際に使ってstructureを作ろうとすると以上のバグメッセージがでる。
opaqueでなくtransitionで適用したり、実際に使おうとしないとバグは出ない。
*)

(*
2012-7-19 ohori
Same as 210_functor.sml and was fixed by 4316:de46c532c718.
*)
