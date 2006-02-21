(*
value bindings with rec
rule 26, 42, 43

<ul>
  <li>pattern containing a variable pattern
    <ul>
      <li>typed</li>
      <li>aliased</li>
      <li>typed and aliased</li>
      <li>aliasing</li>
    </ul>
</ul>
 *)
val rec v1 : int -> int = fn x => if 0 = x then 1 else v1 (x - 1);
val w1 = v1 1;

val rec v2 as y = fn x => if 0 = x then 2 else v2 (x - 1);

val rec v3 : int -> int as y = fn x => if 0 = x then 3 else v3 (x - 1);

val rec v4 as y = fn x => if 0 = x then 4 else v4 (x - 1);
