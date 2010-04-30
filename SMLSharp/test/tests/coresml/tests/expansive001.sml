(*
non-expansive expressions is typed to polymorphic.

<ul>
  <li>non-expansive expression
    <ul>
      <li>constants</li>
      <li>variable</li>
      <li>variable with "op" modifier</li>
      <li>record every whose field is non-expansive</li>
      <li>application of constructor to non-expansive</li>
      <li>application of typed constructor to non-expansive</li>
      <li>typed non-expansive</li>
      <li>fn</li>
    </ul>
  </li>
</ul>
*)
fun id x = x;

(* The following records should be expansive, because constant is
 * non-expansive. *)
val vconstant1 = {a = id, b = 1};
val vconstant2 = {a = id, b = 2.34};
val vconstant3 = {a = id, b = 0w2};
val vconstant4 = {a = id, b = #"x"};
val vconstant5 = {a = id, b = "abc"};

val vvar1 = id;

fun fopvar1 (x, y) = (x, y);
infix fopvar1;
val vopvar1 = op fopvar1;

val vrecord = {a = id};

datatype 'a dt1 = D of int;
val vconstructed1 = D 1;
(*
val vtypedconstructed1 = (D : int -> 'a dt1) 2;
*)
val vtyped1 = id : 'a -> 'a;

val vfn1 = fn x => x;
