(*
multiple application of a functor.

<ul>
  <li>the number of applications of a function
    <ul>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
val r = ref 0;
functor F(S : sig end) = struct val _ = r := (!r) + 1 datatype dt = D end;
structure S = struct end;

structure F1 = F(S);
val r1 = !r;

structure F2 = F(S);
val r2 = !r;

structure F3 = F(S);
val r3 = !r;

val x = (F1.D = F2.D);
