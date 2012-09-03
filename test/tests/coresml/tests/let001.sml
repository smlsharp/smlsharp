(*
let expression.
rule 4

<ul>
  <li>the entity declared local
    <ul>
      <li>variable</li>
      <li>type</li>
      <li>datatype</li>
      <li>datatype replication</li>
      <li>exception</li>
      <li>abstype</li>
    </ul>
  </li>
</ul>
 *)

val x = true;
let
  val x = 1
in
  x + 2
end;

type t = string;
let
  type t = int * bool
in
  (1, false) : t
end;

datatype dt = C of int;
let
  datatype dt = C of int * bool
in
  C (2, true)
end;

datatype dt = D of int;
datatype ds = D of (int * bool);
let
  datatype dt = datatype ds
in
  D (2, true)
end;

exception F of int;
let
  exception F of int * bool
in
  F(3, false)
end;

(* ToDo : case for abstype *)
