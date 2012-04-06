(*
functor constrained by a signature.

<ul>
  <li>specification in the constraining signature
    <ul>
      <li>structure spec</li>
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
signature SStructure = 
sig
  structure S : 
  sig
    datatype dt = D of int
    val x : int 
  end
end;
structure PStructure = struct val x = ~1 datatype dt = D of int end;

functor FStructure1Trans(S : sig val x : int datatype dt = D of int end) = 
struct 
  structure S = struct val x = 1 datatype dt = D of int end
end : SStructure;
structure SStructure1Trans = FStructure1Trans(PStructure);
structure SSTrans = SStructure1Trans.S;
val xStructureTrans = SStructure1Trans.S.x;

functor FStructure1Opaque(S : sig val x : int datatype dt = D of int end) = 
struct 
  structure S = struct val x = 1 datatype dt = D of int end
end :> SStructure;
structure SStructure1Opaque = FStructure1Opaque(PStructure);
structure SSOpaque = SStructure1Opaque.S;
val xStructureOpaque = SStructure1Opaque.S.x;

(* error case *)
functor FStructure2Trans(S : sig val x : int datatype dt = D of int end) = 
struct end : SStructure;

functor FStructure2Opaque(S : sig val x : int datatype dt = D of int end) = 
struct end :> SStructure;
