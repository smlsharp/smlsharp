(*
equality admission of "where type" sigExp.

<ul>
  <li>type name of the left side admits equality.
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
  <li>type expression of the right side admits equality.
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
*)
datatype dtEq = D;
datatype dtNonEq = E of real;
signature S11 = sig type t end where type t = dtNonEq;
signature S12 = sig type t end where type t = dtEq;
signature S21 = sig eqtype t end where type t = dtNonEq;
signature S22 = sig eqtype t end where type t = dtEq;

