(*
matching of sharing specification.
safe case.
type constructors are connected by abbreviation by type declaration or 
datatype replication declaration.

<ul>
  <li>how type constructors are related in the structure.
    <ul>
      <li>type declaration</li>
      <li>datatype replication</li>
      <li>both of type delcaration and datatype replication</li>
    </ul>
  </li>
  <li>the number of type constructors related
    <ul>
      <li>2</li>
      <li>3</li>
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
signature S2 =
sig
  type t1
  type t2
  sharing type t1 = t2
end;

structure SType2Trans : S2 =
struct
  datatype t1 = D
  type t2 = t1
end;
structure SType2Opaque :> S2 =
struct
  datatype t1 = D
  type t2 = t1
end;

structure SDatatypeReplication2Trans : S2 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
end;
structure SDatatypeReplication2Opaque :> S2 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
end;

(****************************************)

signature S3 =
sig
  type t1
  type t2
  type t3
  sharing type t1 = t2 = t3
end;

structure SType31Trans : S3 =
struct
  datatype t1 = D
  type t2 = t1
  type t3 = t1
end;
structure SType32Trans : S3 =
struct
  datatype t1 = D
  type t2 = t1
  type t3 = t2
end;
structure SType31Opaque :> S3 =
struct
  datatype t1 = D
  type t2 = t1
  type t3 = t1
end;
structure SType32Opaque :> S3 =
struct
  datatype t1 = D
  type t2 = t1
  type t3 = t2
end;

structure SDatatypeReplication31Trans : S3 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
  datatype t3 = datatype t1
end;
structure SDatatypeReplication32Trans : S3 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
  datatype t3 = datatype t2
end;
structure SDatatypeReplication31Opaque :> S3 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
  datatype t3 = datatype t1
end;
structure SDatatypeReplication32Opaque :> S3 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
  datatype t3 = datatype t2
end;

structure SMixed31Trans : S3 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
  type t3 = t1
end;
structure SMixed32Trans : S3 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
  type t3 = t2
end;
structure SMixed31Opaque :> S3 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
  type t3 = t1
end;
structure SMixed32Opaque :> S3 =
struct
  datatype t1 = D
  datatype t2 = datatype t1
  type t3 = t2
end;
