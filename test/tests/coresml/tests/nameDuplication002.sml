(*
duplicated type constructor names in datatype bind should be rejected.
(syntax restriction)

<ul>
  <li>the number of duplicated names
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  <li>
  <li>the number of bindings sharing a duplicated name
    <ul>
      <li>2</li>
      <li>3</li>
    </ul>
  <li>
</ul>
*)
datatype t12 = D12 of int and t12 = E12 of string;

datatype t13 = D13 of int and t13 = E13 of string and t13 = F13 of bool;

datatype t221 = D22 of int
and t222 = E22 of string
and t221 = F22 of bool
and t222 = G22 of char;
