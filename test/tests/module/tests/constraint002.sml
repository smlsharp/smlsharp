(*
representation of type is hidden or not by constraint.

<ul>
  <li>specification of the type
    <ul>
      <li>type declaration</li>
      <li>datatype declaration</li>
      <li>datatype replication</li>
      <li>type declaration with a body (= derived form of "where type"
        declaration)</li>
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
signature SType = sig type t end;
signature SDatatype = sig datatype dt = E end;
signature SReplication = sig datatype dtr = datatype dt end;
signature SWhereType = sig include sig type t end where type t = dt end;

(********************)

structure SType = struct datatype t = E end;

structure STypeTrans = SType : SType;
val xSTypeTrans = STypeTrans.E;

structure STypeOpaque = SType :> SType;
val xSTypeOpaque = STypeOpaque.E;

(********************)

structure SDatatype = struct datatype dt = E end;

structure SDatatypeTrans = SDatatype : SDatatype;
val xSDatatypeTrans = SDatatypeTrans.E;

structure SDatatypeOpaque = SDatatype :> SDatatype;
val xSDatatypeOpaque = SDatatypeOpaque.E;

(********************)

structure SReplication = struct datatype dtr = datatype dt end;

structure SReplicationTrans = SReplication : SReplication;
val xSReplicationTrans = SReplicationTrans.D;

structure SReplicationOpaque = SReplication :> SReplication;
val xSReplicationOpaque = SReplicationOpaque.D;

(********************)

structure SWhereType = struct datatype t = datatype dt end;

structure SWhereTypeTrans = SWhereType : SWhereType;
val xSWhereTypeTrans = SWhereTypeTrans.E;

structure SWhereTypeOpaque = SWhereType :> SWhereType;
val xSWhereTypeOpaque = SWhereTypeOpaque.E;

(********************)
