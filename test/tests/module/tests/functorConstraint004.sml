(*
functor constrained by a signature.

<ul>
  <li>specification in the constraining signature
    <ul>
      <li>datatype spec</li>
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
signature SDatatype = 
sig
  datatype t = D
  val x : t
end;
structure PDatatype = struct type t = real end;

functor FDatatypeTrans(S : sig type t end) = 
struct type t = int datatype t = D val x = D end : SDatatype;
structure SDatatypeTrans = FDatatypeTrans(PDatatype);
datatype dtTrans = DTrans of SDatatypeTrans.t;
val aDatatypeTrans = DTrans(SDatatypeTrans.x);
val xDatatypeTrans = SDatatypeTrans.D;

functor FDatatypeOpaque(S : sig type t end) = 
struct type t = int datatype t = D val x = D end :> SDatatype;
structure SDatatypeOpaque = FDatatypeOpaque(PDatatype);
datatype dtOpaque = DOpaque of SDatatypeOpaque.t;
val aDatatypeOpaque = DOpaque(SDatatypeOpaque.x);
val xDatatypeOpaque = SDatatypeOpaque.D;

