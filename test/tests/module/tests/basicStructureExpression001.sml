(*
core declarations in a basic structure expression.

<ul>
  <li>the inner declaration
    <ul>
      <li>none</li>
      <li>val</li>
      <li>type</li>
      <li>datatype</li>
      <li>datatype replication</li>
      <li>abstype</li>
      <li>exception</li>
      <li>local</li>
      <li>open</li>
      <li>infix</li>
      <li>infixr</li>
      <li>nonfix</li>
    </ul>
  </li>
</ul>
*)
structure S1 = struct end;

structure S2 = struct val x = 1 end;
val x2 = S2.x;

structure S3 = struct type t = int end;
type t3 = S3.t;
val x3 = 1 : S3.t;

structure S4 = struct datatype t = D end;
datatype t4 = datatype S4.t;
val x4 = D : S4.t;

datatype t5 = D5;
structure S5 = struct datatype t = datatype t5 end;
datatype t5' = datatype S5.t;
val x5 : t5 = S5.D5 : S5.t;

structure S6 = struct abstype t = D with val x = D end end;
val (x6 : S6.t) = S6.x;

structure S71 = struct exception e end;
exception e71 = S71.e;
val x71 = S71.e;

exception e72;
structure S72 = struct exception e = e72 end;
val x72 = S72.e;

structure S8 = struct local datatype t = D in val x = D end end;
val x8 = S8.x;

structure S91 = struct val x = (1, 2) end;
structure S92 = struct open S91 end;
val x9 = S92.x;

structure S10 = struct infix ++ fun x ++ y = x + y end;
val ++ = S10.++;

structure S11 = struct infixr -- fun x -- y = x - y end;
val -- = S11.--;

structure S12 = struct infixr // fun x // y = x - y nonfix // end;
val // = S12.//;
