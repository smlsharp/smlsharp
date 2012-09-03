(*
module declarations in a basic structure expression.

<ul>
  <li>the inner declaration
    <ul>
      <li>structure</li>
      <li>local (module level)</li>
      <li>sequence</li>
    </ul>
  </li>
</ul>
*)
structure S1 = struct structure S = struct datatype dt = D val x = D end end;
datatype dt1 = datatype S1.S.dt;
type t1 = S1.S.dt;
val x11 = S1.S.x;
val x12 : t1 = S1.S.D;

structure S2 = 
struct 
  local structure S1 = struct datatype t = D end
  in structure S2 = struct val x = S1.D end
  end
end;
val x2 = S2.S2.x;

structure S3 = 
struct
  structure S1 = struct datatype dt = E end;
  structure S2 = struct val x = S1.E end
end;
datatype dt3 = datatype S3.S1.dt;
type t3 = S3.S1.dt;
val x3 = S3.S2.x;