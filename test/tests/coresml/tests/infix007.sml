(*
multiple identities in a infix declaration.

<ul>
  <li>the type of infix
    <ul>
      <li>infix</li>
      <li>infixr</li>
      <li>nonfix</li>
    </ul>
  </li>
  <li>the number of identities
    <ul>
      <li>3</li>
    </ul>
  </li>
  <li>with precedence
    <ul>
      <li>yes</li>
      <li>no</li>
    </ul>
  </li>
</ul>
 *)
infix 1 P111 P112 P113;
datatype t11 =
         P111 of int * int
       | P112 of bool * bool
       | P113 of string * string;
val v11 = (1 P111 2, true P112 false, "foo" P113 "bar");

infix P121 P122 P123;
datatype t12 =
         P121 of int * int
       | P122 of bool * bool
       | P123 of string * string;
val v12 = (1 P121 2, true P122 false, "foo" P123 "bar");

infixr 1 P211 P212 P213;
datatype t21 =
         P211 of int * int
       | P212 of bool * bool
       | P213 of string * string;
val v21 = (1 P211 2, true P212 false, "foo" P213 "bar");

infixr P221 P222 P223;
datatype t22 =
         P221 of int * int
       | P222 of bool * bool
       | P223 of string * string;
val v22 = (1 P221 2, true P222 false, "foo" P223 "bar");

infix P311;
infix P312;
infix P313;
nonfix P311 P312 P313;
datatype t31 =
         P311 of int * int
       | P312 of bool * bool
       | P313 of string * string;
val v31 = (P311 (1, 2), P312 (true, false), P313 ("foo", "bar"));

