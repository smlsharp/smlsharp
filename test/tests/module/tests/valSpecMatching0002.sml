(*
matching of val specification.
mono type, poly type.
<ul>
  <li>type of val in signature
    <ul>
      <li>mono type</li>
      <li>poly type</li>
    </ul>
  <li>
  <li>type of val in structure
    <ul>
      <li>mono type</li>
      <li>poly type</li>
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
signature Smm1 =
sig
  val x : int
end;
structure Smm1Trans : Smm1 =
struct
  val x = 1
end;
structure Smm1Opaque :> Smm1 =
struct
  val x = 1
end;

signature Smp1 =
sig
  val f : int -> int * int
end;
structure Smp1Trans : Smp1 =
struct
  fun f x = (1, x)
end;
structure Smp1Opaque :> Smp1 =
struct
  fun f x = (1, x)
end;

signature Spm1 =
sig
  val f : 'a -> int * 'a
end;
structure Spm1Trans : Spm1 =
struct
  fun f x = (1, x + 1)
end;
structure Spm1Opaque :> Spm1 =
struct
  fun f x = (1, x + 1)
end;

signature Spp1 =
sig
  val f : 'a -> int * 'a
end;
structure Spp1Trans : Spp1 =
struct
  fun f x = (1, x)
end;
structure Spp1Opaque :> Spp1 =
struct
  fun f x = (1, x)
end;
