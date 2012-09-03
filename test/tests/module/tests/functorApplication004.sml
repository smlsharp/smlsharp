(*
structure expression of argument of functor application.

<ul>
  <li>argument structure expression
    <ul>
      <li>basic strexp</li>
    </ul>
  </li>
</ul>
*)
functor F(P : sig type dt val x : dt end) =
struct datatype dt = D of P.dt val x = D(P.x) end;

structure T = F(struct datatype dt = D val x = D end);

val x = T.x;

