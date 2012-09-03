(*
identity of type name is changed or not by constraint.
This test case checks that a type that is declared in a structure is given
different type identity by signature constraint or not.

<ul>
  <li>declaration which introduces the type name.
    <ul>
      <li>type declaration</li>
      <li>datatype declaration</li>
      <li>datatype replication</li>
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
signature SType =
sig
  type t
  val x : t
end;
signature SDatatype =
sig
  datatype dt = E
  val x : dt
end;
signature SReplication =
sig
  datatype dtr = datatype dt
  val x : dtr
end;

(********************)

structure SType = struct type t = int val x = 1 end;

structure STypeTrans1 = SType : SType;
structure STypeTrans2 = SType : SType;
val eqSTypeTrans = STypeTrans1.x = STypeTrans2.x;

structure STypeOpaque1 = SType :> SType;
structure STypeOpaque2 = SType :> SType;
val eqSTypeOpaque = STypeOpaque1.x = STypeOpaque2.x;

(********************)

structure SDatatype = struct datatype dt = E val x = E end;

structure SDatatypeTrans1 = SDatatype : SDatatype;
structure SDatatypeTrans2 = SDatatype : SDatatype;
val eqSDatatypeTrans = SDatatypeTrans1.x = SDatatypeTrans2.x;

structure SDatatypeOpaque1 = SDatatype :> SDatatype;
structure SDatatypeOpaque2 = SDatatype :> SDatatype;
val eqSDatatypeOpaque = SDatatypeOpaque1.x = SDatatypeOpaque2.x;

(********************)

structure SReplication = struct datatype dtr = datatype dt val x = D end;

structure SReplicationTrans1 = SReplication : SReplication;
structure SReplicationTrans2 = SReplication : SReplication;
val eqSReplicationTrans = SReplicationTrans1.x = SReplicationTrans2.x;

structure SReplicationOpaque1 = SReplication :> SReplication;
structure SReplicationOpaque2 = SReplication :> SReplication;
val eqSReplicationOpaque = SReplicationOpaque1.x = SReplicationOpaque2.x;
