(*
longid structure expression.

<ul>
  <li>referring location
    <ul>
      <li>at the top level</li>
      <li>in a global structure</li>
      <li>in a local structure</li>
    </ul>
  </li>
  <li>referred structure
    <ul>
      <li>global structure</li>
      <li>local structure declared in the same global structure</li>
      <li>local structure declared in the another global structure</li>
    </ul>
  </li>
</ul>
*)
(* refer = top, referred = global *)
structure S11 = struct datatype dt = D val x = D end;
structure T11 = S11;
val x11 : T11.dt = T11.x;

(* refer = top, referred = local str in the same global str *)
structure S12 = struct
  structure S12 = struct datatype dt = D val x = D end 
end;
structure T12 = S12.S12;
val x12 : T12.dt = T12.x;

(* refer = top, referred = local str in a different global str *)
(* snip *)

(* refer = in a global str, referred = global *)
structure S21 = struct datatype dt = D val x = D end;
structure T21 = struct structure T21 = S21 end;
val x21 : T21.T21.dt = T21.T21.x;

(* refer = in a global str, referred = local str in the same global str *)
structure S22 = 
struct
  structure S22 = struct datatype dt = D val x = D end
  structure T22 = S22
end;
val x22 : S22.T22.dt = S22.T22.x;

(* refer = in a global str, referred = local str in another global str *)
structure S23 =
struct structure S23 = struct datatype dt = D val x = D end end;
structure T23 = struct structure T23 = S23.S23 end;
val x23 : T23.T23.dt = T23.T23.x;

(* refer = in a local str, referred = global *)
structure S31 = struct datatype dt = D val x = D end;
structure T31 = struct structure T31 = struct structure T31 = S31 end end;
val x31 : T31.T31.T31.dt = T31.T31.T31.x;

(* refer = in a local str, referred = local str in the same global str *)
structure S32 = 
struct
  structure S32 = struct datatype dt = D val x = D end;
  structure T32 = struct structure T32 = S32 end
end;
val x32 : S32.T32.T32.dt = S32.T32.T32.x;

(* refer = in a local str, referred = local str in another global str *)
structure S33 = 
struct structure S33 = struct datatype dt = D val x = D end end;
structure T33 = struct structure T33 = struct structure T33 = S33.S33 end end;
val x33 : T33.T33.T33.dt = T33.T33.T33.x;

