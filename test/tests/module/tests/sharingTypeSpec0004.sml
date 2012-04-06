(*
type equality of tyCons in a "sharing type" specification.

<ul>
  <li>the left tyCon
    <ul>
      <li>declared by type specification</li>
      <li>declared by eqtype specification</li>
      <li>declared by datatype specification not admitting equality</li>
      <li>declared by datatype specification admitting equality</li>
    </ul>
  </li>
  <li>the right tyCon
    <ul>
      <li>declared by type specification</li>
      <li>declared by eqtype specification</li>
      <li>declared by datatype specification not admitting equality</li>
      <li>declared by datatype specification admitting equality</li>
    </ul>
  </li>
</ul>
*)
signature S11 =
sig
  type s
  type t
  sharing type s = t
end;
structure S11 : S11 = struct type s = real type t = real end;

signature S12 =
sig
  type s
  eqtype t
  sharing type s = t
end;
structure S121 : S12 = struct type s = real type t = real end;
structure S122 : S12 = struct type s = int type t = int end;

signature S13 =
sig
  type s
  datatype t = D of real
  sharing type s = t
end;
structure S13 : S13 = struct datatype t = D of real type s = t end;

signature S14 =
sig
  type s
  datatype t = D of int
  sharing type s = t
end;
structure S14 : S14 = struct datatype t = D of int type s = t end;

(********************)

signature S21 =
sig
  eqtype s
  type t
  sharing type s = t
end;
structure S211 : S21 = struct type s = real type t = real end;
structure S212 : S21 = struct type s = int type t = int end;

signature S22 =
sig
  eqtype s
  eqtype t
  sharing type s = t
end;
structure S221 : S22 = struct type s = real type t = real end;
structure S222 : S22 = struct type s = int type t = int end;

signature S23 =
sig
  eqtype s
  datatype t = D of real
  sharing type s = t
end;
structure S23 : S23 = struct datatype t = D of real type s = t end;

signature S24 =
sig
  eqtype s
  datatype t = D of int
  sharing type s = t
end;
structure S24 : S24 = struct datatype t = D of int type s = t end;

(********************)

signature S31 =
sig
  datatype s = D of real
  type t
  sharing type s = t
end;
structure S31 : S31 = 
struct datatype s = D of real datatype t = datatype s end;

signature S32 =
sig
  datatype s = D of real
  eqtype t
  sharing type s = t
end;
structure S32 : S32 = 
struct datatype s = D of real datatype t = datatype s end;

signature S33 =
sig
  datatype s = D of real
  datatype t = E of real
  sharing type s = t
end;
(* But, how can we define a structure conforming with S33 ? *)

signature S34 =
sig
  datatype s = D of real
  datatype t = E of int
  sharing type s = t
end;

(********************)

signature S41 =
sig
  datatype s = D of int
  type t
  sharing type s = t
end;
structure S41 : S41 = 
struct datatype s = D of int datatype t = datatype s end;

signature S42 =
sig
  datatype s = D of int
  eqtype t
  sharing type s = t
end;
structure S42 : S42 = 
struct datatype s = D of int datatype t = datatype s end;

signature S43 =
sig
  datatype s = D of int
  datatype t = E of int
  sharing type s = t
end;
(* But, how can we define a structure conforming with S43 ? *)

signature S44 =
sig
  datatype s = D of int
  datatype t = E of int
  sharing type s = t
end;


