(*
matching of val specification.

<ul>
  <li>binding
    <ul>
      <li>val binding</li>
      <li>constructor binding</li>
      <li>exception constructor binding</li>
    </ul>
  <li>
  <li>signature constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature SVal =
sig
  val x : int
end;

signature SCon =
sig
  type dt
  val D : int -> dt
end;

signature SExn =
sig
  val E : int -> exn
end;

structure SVal1Trans : SVal =
struct
  val x = 1
end;
structure SVal1Opaque :> SVal =
struct
  val x = 1
end;

structure SVal2Trans : SCon =
struct
  datatype dt = E of int;
  val D = fn x => E x;
end;
structure SVal2Opaque :> SCon =
struct
  datatype dt = E of int;
  val D = fn x => E x;
end;

structure SVal3Trans : SExn =
struct
  exception foo
  val E = fn (x : int) => foo
end;
structure SVal3Opaque :> SExn =
struct
  exception foo
  val E = fn (x : int) => foo
end;

structure SCon1Trans : SCon =
struct
  datatype t = D of int | E
  type dt = t
end;
structure SCon1Opaque :> SCon =
struct
  datatype t = D of int | E
  type dt = t
end;

structure SExn1Trans : SExn =
struct
  exception E of int
end;
structure SExn1Opaque :> SExn =
struct
  exception E of int
end;