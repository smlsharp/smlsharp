(*
structure expression of argument of functor application.

<ul>
  <li>argument structure expression
    <ul>
      <li>let strexp</li>
    </ul>
  </li>
</ul>
*)
functor F(P : sig type dt val x : dt end) =
struct datatype dt = D of P.dt val x = D(P.x) end;

structure T =
          F(let structure S = struct datatype dt = D end
            in struct datatype dt = datatype S.dt val x = S.D end
            end);

val x = T.x;

