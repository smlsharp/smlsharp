(*
duplicated type constructor names in type bind should be rejected.
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
type t12 = int and t12 = string;

type t13 = int and t13 = string and t13 = bool;

type t221 = int and t222 = string and t221 = bool and t222 = char;
