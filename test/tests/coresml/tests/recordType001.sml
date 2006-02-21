(*
record type expression.
rule 45, 49

test for field labels.
<ul>
  <li>
    <ul>
      <li>no field</li>
      <li>single field</li>
      <li>2 fields with alphabetic order</li>
      <li>2 fields with reverse alphabetic order</li>
    </ul>
  </li>
</ul>
 *)
type t1 = {};
val v1 : t1 = {};

type t2 = {x : int};
val v2 : t2 = {x = 2};

type t3 = {a : int, z : bool};
val v31 : t3 = {a = 3, z = true};
val v32 : t3 = {z = true, a = 3};

type t4 = {z : bool, a : int};
val v41 : t4 = {a = 4, z = true};
val v42 : t4 = {z = true, a = 4};
