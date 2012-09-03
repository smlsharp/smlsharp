(*
peculiar cases in matching of datatype specification.

<ul>
  <li>datatype declared in the structure
    <ul>
      <li>more data constructors than specification</li>
      <li>less data constructors than specification</li>
      <li>data constructor with an argument different to specification</li>
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
signature S =
sig
  datatype dt = D of int | E of string
end;

structure S1Trans : S =
struct
  datatype dt = D of int | E of string | F of bool
end;
structure S1Opaque :> S =
struct
  datatype dt = D of int | E of string | F of bool
end;

structure S2Trans : S =
struct
  datatype dt = D of int
  fun E string = D string
end;
structure S2Opaque :> S =
struct
  datatype dt = D of int
  fun E string = D string
end;

structure S3Trans : S =
struct
  datatype dt = D of bool | E of string
end;
structure S3Opaque :> S =
struct
  datatype dt = D of bool | E of string
end;
