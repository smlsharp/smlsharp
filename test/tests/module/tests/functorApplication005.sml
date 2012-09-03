(*
structure expression of argument of functor application.

<ul>
  <li>argument structure expression
    <ul>
      <li>structure identifier</li>
    </ul>
  </li>
</ul>
*)
functor F(P : sig type dt val x : dt end) =
struct datatype dt = D of P.dt val x = D(P.x) end;

structure S = struct datatype dt = D val x = D end;
structure T = F(S);

val x = T.x;

