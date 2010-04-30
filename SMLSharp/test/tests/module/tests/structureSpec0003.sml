(*
various signature expression bound to inner structure specification.

<ul>
  <li>body sigexp of inner structure
    <ul>
      <li>basic signature exp</li>
      <li>signature identifier</li>
      <li>type realisation by "where type" clause</li>
    </ul>
  </li>
</ul>
*)

signature S1 = 
sig
  structure S : sig type t datatype dt = D of t val x : dt end
end;

signature T2 = sig type t datatype dt = D of t val x : dt end;
signature S2 =
sig
  structure S : T2
end;

