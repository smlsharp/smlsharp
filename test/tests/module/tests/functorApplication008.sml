(*
structure expression of argument of functor application.

<ul>
  <li>argument structure expression
    <ul>
      <li>application of another functor</li>
      <li>application of the functor itself</li>
      <li>id strexp indicating an application of another functor</li>
    </ul>
  </li>
</ul>
*)
functor F(P : sig type dt val x : dt end) =
struct datatype dt = F of P.dt val x = F(P.x) end;

functor F1(P : sig type dt val x : dt end) =
struct datatype dt = E of P.dt val x = E(P.x) end;

structure P = struct datatype dt = D val x = D end;

(********************)
structure T1 = F(F1(P));
val x1 = T1.x;

(********************)
structure T2 = F(F(P));
val x2 = T2.x;

(********************)
structure T31 = F1(P);
val x31 = T31.x;

structure T32 = F(T31);
val x32 = T32.x;
val b = case x32 of T32.F(T31.E(P.D)) => true;

(********************)
