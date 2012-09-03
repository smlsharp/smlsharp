(*
matching of exception specification.

<ul>
  <li>binding
    <ul>
      <li>val binding</li>
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
signature S =
sig
  exception E of int
end;

structure SExn1Trans : S =
struct
  exception E of int
end;
structure SExn1Opaque :> S =
struct
  exception E of int
end;

structure SVal1Trans : S =
struct
  exception F
  val E = fn (x : int) => F
end;
structure SVal1Opaque :> S =
struct
  exception F
  val E = fn (x : int) => F
end;

structure SVal2Trans : S =
struct
  exception F of int
  val E = F
end;
structure SVal2Opaque :> S =
struct
  exception F of int
  val E = F
end;

