(*
multiple functor bindings in a functor declaration.

<ul>
  <li>the number of binidngs in a declaration
    <ul>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
functor F1(S : sig val x : int end) = struct val x = S.x + 1 end
and F2(S : sig val x : int end) = struct val x = S.x + 1 end
and F3(S : sig val x : int end) = struct val x = S.x + 1 end;

structure S = struct val x = 1 end;

structure S1 = F1(S)
and S2 = F2(S)
and S3 = F3(S);
val sx1 = S1.x;
val sx2 = S2.x;
val sx3 = S3.x;

structure T1 = F1(S)
and T2 = F2(T1)
and T3 = F3(T2);
