(*
multiple applications of functors to a structure.

<ul>
  <li>the number of applications
    <ul>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
structure S = struct datatype dt = D val x = D end;
functor F1(S : sig type dt val x : dt end) = struct val x = S.x end;
functor F2(S : sig type dt val x : dt end) = struct val x = S.x end;
functor F3(S : sig type dt val x : dt end) = struct val x = S.x end;

structure S1 = F1(S);
structure S2 = F2(S);
structure S3 = F3(S);

val x = [S1.x, S2.x, S3.x];
