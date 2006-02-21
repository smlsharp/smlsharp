(*
functor constrained by a signature.

<ul>
  <li>specification in the constraining signature
    <ul>
      <li>exception spec</li>
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
signature SExn = 
sig
  exception E of int
end;
structure PExn = struct exception E of string end;

functor FExnTrans(S : sig exception E of string end) = 
struct exception E of int end : SExn;
structure SExnTrans = FExnTrans(PExn);
val xExnTrans = SExnTrans.E 1;
val eExnTrans =
    (raise SExnTrans.E 1) handle PExn.E s => 0 | SExnTrans.E n => n;

functor FExnOpaque(S : sig exception E of string end) = 
struct exception E of int end :> SExn;
structure SExnOpaque = FExnOpaque(PExn);
val xExnOpaque = SExnOpaque.E 1;
val eExnOpaque =
    (raise SExnOpaque.E 1) handle PExn.E s => 0 | SExnOpaque.E n => n;
