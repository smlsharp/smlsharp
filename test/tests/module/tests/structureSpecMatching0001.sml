(*
matching of structure specification.

<ul>
  <li>specification in the inner signature
    <ul>
      <li>empty</li>
      <li>val spec</li>
      <li>type spec</li>
      <li>eqtype spec</li>
      <li>datatype spec</li>
      <li>datatype replication spec</li>
      <li>exception spec</li>
      <li>structure spec</li>
    </ul>
  </li>
  <li>signature constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature SEmpty = sig structure S : sig end end;
structure SEmptyTrans : SEmpty = struct structure S = struct end end;
structure SEmptyOpaque :> SEmpty = struct structure S = struct end end;

signature SVal = sig structure S : sig val x : int end end;
structure SValTrans : SVal = struct structure S = struct val x = 1 end end;
structure SValOpaque :> SVal = struct structure S = struct val x = 1 end end;

signature SType = sig structure S : sig type t end end;
structure STypeTrans : SType = 
struct structure S = struct type t = int end end;
structure STypeOpaque :> SType = 
struct structure S = struct type t = int end end;

signature SEqtype = sig structure S : sig eqtype t end end;
structure SEqtypeTrans : SEqtype = 
struct structure S = struct type t = int end end;
structure SEqtypeOpaque :> SEqtype = 
struct structure S = struct type t = int end end;

signature SDatatype = sig structure S : sig datatype dt = D end end;
structure SDatatypeTrans : SDatatype = 
struct structure S = struct datatype dt = D end end;
structure SDatatypeOpaque :> SDatatype = 
struct structure S = struct datatype dt = D end end;

datatype dtDatatypeReplication = DDatatypeReplication
signature SDatatypeReplication = 
sig structure S : sig datatype dt = datatype dtDatatypeReplication end end;
structure SDatatypeReplicationTrans : SDatatypeReplication =
struct
  structure S = struct datatype dt = datatype dtDatatypeReplication end 
end;
structure SDatatypeReplicationOpaque :> SDatatypeReplication =
struct
  structure S = struct datatype dt = datatype dtDatatypeReplication end 
end;

signature SException = sig structure S : sig exception E end end;
structure SExceptionTrans : SException = 
struct structure S = struct exception E end end;
structure SExceptionOpaque :> SException = 
struct structure S = struct exception E end end;

signature SStructure = 
sig structure S : sig structure S : sig val x : int end end end;
structure SStructureTrans : SStructure =
struct structure S = struct structure S = struct val x = 1 end end end;
structure SStructureOpaque :> SStructure =
struct structure S = struct structure S = struct val x = 1 end end end;
