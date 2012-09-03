(*
functor constrained by a signature.

<ul>
  <li>specification in the constraining signature
    <ul>
      <li>type spec</li>
    </ul>
  </li>
  <li>constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature SType = 
sig
  type t
  val x : t
end;
structure PType = struct type t = real val x = 1.23 end;

functor FTypeTrans(S : sig type t val x : t end) = 
struct type t = int datatype t = D of S.t val x = D(S.x) end : SType;
structure STypeTrans = FTypeTrans(PType);
datatype dtTrans = DTrans of STypeTrans.t;
val aTypeTrans = DTrans(STypeTrans.x);

functor FTypeOpaque(S : sig type t val x : t end) = 
struct type t = int datatype t = D of S.t val x = D(S.x) end :> SType;
structure STypeOpaque = FTypeOpaque(PType);
datatype dtOpaque = DOpaque of STypeOpaque.t;
val aTypeOpaque = DOpaque(STypeOpaque.x);

