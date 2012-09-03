(*
functor constrained by a signature.

<ul>
  <li>specification in the constraining signature
    <ul>
      <li>eqtype spec</li>
    </ul>
  </li>
  <li>the equality of the type t matching with the eqtype spec depends on the
     type S.t or not
    <ul>
      <li>t does not depends on S.t</li>
      <li>t depends on S.t</li>
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
  eqtype t
  val x : t
end;

structure P = struct type t = real val x = 1.23 end;

functor FTypeNotDependsTrans(S : sig type t val x : t end) = 
struct type t = S.t ref val x = ref S.x end : SType;
structure STypeNotDependsTrans = FTypeNotDependsTrans(P);
val xTypeTrans = STypeNotDependsTrans.x;
datatype dtTrans = DTrans of STypeNotDependsTrans.t;
val aTypeTrans = DTrans(STypeNotDependsTrans.x);

functor FTypeNotDependsOpaque(S : sig type t val x : t end) = 
struct type t = S.t ref val x = ref S.x end :> SType;
structure STypeNotDependsOpaque = FTypeNotDependsOpaque(P);
val xTypeOpaque = STypeNotDependsOpaque.x;
datatype dtOpaque = DOpaque of STypeNotDependsOpaque.t;
val aTypeOpaque = DOpaque(STypeNotDependsOpaque.x);


functor FTypeDependsTrans(S : sig type t val x : t end) = 
struct datatype t = D of S.t val x = D(S.x) end : SType;

functor FTypeDependsOpaque(S : sig type t val x : t end) = 
struct datatype t = D of S.t val x = D(S.x) end :> SType;
