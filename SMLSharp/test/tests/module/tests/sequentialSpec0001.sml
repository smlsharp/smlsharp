(*
sequential specification.

<ul>
  <li>the number of specifications
    <ul>
      <li>non-empty</li>
      <li>empty</li>
    </ul>
  </li>
  <li>separated by comma
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
*)
signature S11 = sig type s val y : s type t val x : t end;

signature S12 = sig type s; val y : s; type t; val x : t; end;

signature S21 = sig end;

signature S22 = sig ; end;
