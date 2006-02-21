(*
multiple applications of a functor to a structure.

<ul>
  <li>the number of applications
    <ul>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
structure S = struct datatype dt = D val x = D end;
functor F(S : sig type dt val x : dt end) = struct val x = S.x end;

structure S1 = F(S);
structure S2 = F(S);
structure S3 = F(S);

val x = [S1.x, S2.x, S3.x];
