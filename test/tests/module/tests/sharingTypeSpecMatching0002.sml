(*
matching of sharing specification.
safe case.
Type constructors are declared by "type" declaration and bound to the same
type expression.

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
  type t1 = int * int
  type t2 = int * int
end;
structure S2Opaque :> S2 =
struct
  type t1 = int * int
  type t2 = int * int
end;

(********************)

signature S3 =
sig
  type t1
  type t2
  type t3
  sharing type t1 = t2 = t3
end;

structure S3Trans : S3 =
struct
  type t1 = int -> int
  type t2 = int -> int
  type t3 = int -> int
end;
structure S3Opaque :> S3 =
struct
  type t1 = int -> int
  type t2 = int -> int
  type t3 = int -> int
end;
