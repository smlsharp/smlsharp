(*
matching of include specification.

<ul>
  <li>specification in the included signature
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
signature TEmpty = sig end;
signature SEmpty = sig include TEmpty end;
structure SEmptyTrans : SEmpty = struct end;
structure SEmptyOpaque :> SEmpty = struct end;

signature TVal = sig val x : int end;
signature SVal = sig include TVal end;
structure SValTrans : SVal = struct val x = 1 end;
structure SValOpaque :> SVal = struct val x = 1 end;

signature TType = sig type t end;
signature SType = sig include TType end;
structure STypeTrans : SType = struct type t = int end;
structure STypeOpaque :> SType = struct type t = int end;

signature TEqtype = sig eqtype t end;
signature SEqtype = sig include TEqtype end;
structure SEqtypeTrans : SEqtype = struct type t = int end;
structure SEqtypeOpaque :> SEqtype = struct type t = int end;

signature TDatatype = sig datatype dt = D end;
signature SDatatype = sig include TDatatype end;
structure SDatatypeTrans : SDatatype = struct datatype dt = D end;
structure SDatatypeOpaque :> SDatatype = struct datatype dt = D end;

datatype dtDatatypeReplication = DDatatypeReplication
signature TDatatypeReplication =
sig datatype dt = datatype dtDatatypeReplication end;
signature SDatatypeReplication = sig include TDatatypeReplication end;
structure SDatatypeReplicationTrans : SDatatypeReplication =
struct datatype dt = datatype dtDatatypeReplication end;
structure SDatatypeReplicationOpaque :> SDatatypeReplication =
struct datatype dt = datatype dtDatatypeReplication end;

signature TException = sig exception E end;
signature SException = sig include TException end;
structure SExceptionTrans : SException = struct exception E end;
structure SExceptionOpaque :> SException = struct exception E end;

signature TStructure = sig structure S : sig val x : int end end;
signature SStructure = sig include TStructure end;
structure SStructureTrans : SStructure =
struct structure S = struct val x = 1 end end;
structure SStructureOpaque :> SStructure =
struct structure S = struct val x = 1 end end;
