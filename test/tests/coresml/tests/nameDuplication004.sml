(*
duplicated value constructor names in datatype bind should be rejected.
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
datatype t12a = D12 of int and t12b = D12 of string;

datatype t13a = D13 of int and t13b = D13 of string and t13c = D13 of bool;

datatype t22a = D22 of int
and t22b = E22 of string
and t22c = D22 of bool
and t22d = E22 of char;
