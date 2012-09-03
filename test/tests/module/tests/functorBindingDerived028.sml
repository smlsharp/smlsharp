(*
derived form of functor binding.
<pre>
  funid(spec) : sigexp = ...
  funid(spec) :> sigexp = ...
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>structure spec</li>
    </ul>
  </li>
  <li>constraint
    <ul>
      <li>none</li>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature SStructure = sig structure T : sig datatype dt = D end end;
structure PStructure = struct structure T = struct datatype dt = D end end;

functor FStructure(structure T : sig datatype dt = D end) =
struct structure T = T end;
structure TStructure = FStructure(PStructure);
structure SStructure = TStructure.T;
val xStructure = TStructure.T.D;

functor FStructureTrans(structure T : sig datatype dt = D end) : SStructure =
struct structure T = T end;
structure TStructureTrans = FStructureTrans(PStructure);
structure SStructureTrans = TStructureTrans.T;
val xStructureTrans = TStructureTrans.T.D;

functor FStructureOpaq(structure T : sig datatype dt = D end) :> SStructure =
struct structure T = T end;
structure TStructureOpaq = FStructureOpaq(PStructure);
structure SStructureOpaq = TStructureOpaq.T;
val xStructureOpaq = TStructureOpaq.T.D;

