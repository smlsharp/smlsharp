(*
structure expression of argument of functor application.

<ul>
  <li>argument structure expression
    <ul>
      <li>opaque constraint</li>
    </ul>
  </li>
  <li>constrained strucutre expression
    <ul>
      <li>basic strexp</li>
      <li>strucutre identifier</li>
    </ul>
  </li>
</ul>
*)
functor F(P : sig type dt val x : dt end) =
struct datatype dt = D of P.dt val x = D(P.x) end;

signature SIG = sig type dt val x : dt end;

(********************)

structure TBasic = F(struct datatype dt = D val x = D end :> SIG);
val xBasic = TBasic.x;

(********************)

structure SId = struct datatype dt = D val x = D end;
structure TId = F(SId :> SIG);
val xId = TId.x;

(********************)
