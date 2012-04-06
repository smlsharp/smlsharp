(*
matching of sharing specification.
error case.
Type constructors are declared independently by "datatype" declaration 
in the same form.

<ul>
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

structure S2Trans : S2 =
struct
  datatype t1 = D
  datatype t2 = D
end;
structure S2Opaque :> S2 =
struct
  datatype t1 = D
  datatype t2 = D
end;

(********************)

signature S3 =
sig
  type t1
  type t2
  type t3
  sharing type t1 = t2 = t3
end;

structure S31Trans : S3 =
struct
  datatype t1 = D
  datatype t2 = D
  datatype t3 = D
end;
structure S31Opaque :> S3 =
struct
  datatype t1 = D
  datatype t2 = D
  datatype t3 = D
end;

structure S32Trans : S3 =
struct
  datatype t1 = D
  type t2 = t1
  datatype t3 = D
end;
structure S32Opaque : S3 =
struct
  datatype t1 = D
  type t2 = t1
  datatype t3 = D
end;

