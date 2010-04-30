(*
open declaration.

<ul>
  <li>
    <ul>
      <li>val declaration</li>
      <li>type declaration</li>
      <li>datatype declaration</li>
      <li>datatype replication</li>
      <li>abstype declaration</li>
      <li>exception declaration</li>
      <li>open declaration</li>
      <li>infix declaration</li>
      <li>infixr declaration</li>
      <li>nonfix declaration</li>
      <li>structure decalration</li>
    </ul>
  <li>
</ul>
*)
structure Sval1 = struct val x = (1, 2) end;
structure Sval2 = struct open Sval1 val y = x end;
val xval = Sval2.x;

structure Stype1 = struct type t = int * int end;
structure Stype2 = struct open Stype1 val y = (1, 2) : t end;
val xtype : Stype2.t = (2, 3);

structure Sdatatype1 = struct datatype dt = D end;
structure Sdatatype2 = struct open Sdatatype1 val y = D : dt end;
val xdatatype : Sdatatype2.dt = Sdatatype2.D;

local
  datatype dt = D
in
structure SdatatypeReplication1 = struct datatype dt = datatype dt end
end;
structure SdatatypeReplication2 = 
struct open SdatatypeReplication1 val y = D : dt end;
val xdatatypeReplication : Sdatatype2.dt = Sdatatype2.D;

structure Sabstype1 =
struct
  abstype at = D of t withtype t = int * int with val x = D (1, 2) end 
end;
structure Sabstype2 = struct open Sabstype1 val y = x : at end;
val xabstype : Sabstype2.at = Sabstype2.x;

structure Sexception1 = struct exception E of int end;
structure Sexception2 = struct open Sexception1 val y = E 1 end;
val xexception = Sexception2.E 1;

structure Sopen1 = struct datatype dt = D val x = D end;
structure Sopen2 = struct open Sopen1 end;
structure Sopen3 = struct open Sopen2 val y = D : dt end;
val xopen = (Sopen3.x : Sopen3.dt, Sopen3.D);

(* infix attribute is not imported. *)
structure Sinfix1 = struct infix ## fun x ## y = x + y end;
structure Sinfix2 = struct open Sinfix1 fun ## (x, y) = x + y end;

(* infix attribute is not imported. *)
structure Sinfixr1 = struct infixr ## fun x ## y = x + y end;
structure Sinfixr2 = struct open Sinfixr1 fun ## (x, y) = x + y end;

(* infix attribute is not imported. *)
structure Snonfix1 = struct nonfix ## end;
structure Snonfix2 = struct infix ## open Snonfix1 fun x ## y = x + y end;

structure Sstructure1 =
struct structure S = struct datatype dt = D val x = D end end;
structure Sstructure2 = struct open Sstructure1 structure T = S end;
structure T = Sstructure2.S;
val xstructure = (Sstructure2.S.x : Sstructure2.S.dt, Sstructure2.S.D);
