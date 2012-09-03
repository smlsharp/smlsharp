(*
functor constrained by a signature.

<ul>
  <li>specification in the constraining signature
    <ul>
      <li>datatype replication spec</li>
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
datatype dt = D;
signature SDatatype = 
sig
  datatype t = datatype dt
  val x : t
end;
structure PDatatype = struct type t = real end;

functor FDatatypeTrans(S : sig type t end) = 
struct type t = int datatype t = datatype dt val x = D end : SDatatype;
structure SDatatypeTrans = FDatatypeTrans(PDatatype);
datatype dt2Trans = ETrans of SDatatypeTrans.t;
val aDatatypeTrans = ETrans(SDatatypeTrans.x);
val xDatatypeTrans = SDatatypeTrans.D;
val eqDatatypeTrans = SDatatypeTrans.D = D;

functor FDatatypeOpaque(S : sig type t end) = 
struct type t = int datatype t = datatype dt val x = D end :> SDatatype;
structure SDatatypeOpaque = FDatatypeOpaque(PDatatype);
datatype dt2Opaque = EOpaque of SDatatypeOpaque.t;
val aDatatypeOpaque = EOpaque(SDatatypeOpaque.x);
val xDatatypeOpaque = SDatatypeOpaque.D;
val eqDatatypeOpaque = SDatatypeOpaque.D = D;
