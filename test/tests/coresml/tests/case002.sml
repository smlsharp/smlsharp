(*
case expression whose rule have only atom pattern.

<ul>
  <li>pattern
    <ul>
      <li>a wild pattern only</li>
      <li>a variable pattern only</li>
      <li>a constant pattern only</li>
      <li>a constant pattern and variable (= default) pattern</li>
      <li>two constant patterns and variable (= default) pattern</li>
      <li>a typed pattern</li>
      <li>a layered "AS" pattern</li>
      <li>a typed and layered pattern</li>
    </ul>
  </li>
</ul>
 *)

(*****************************************************************************)

fun f x = x;

val case_wild1 = case (f 1) of _ => true;
val case_var1 = case (f 1) of x => true;
val case_const1 = case (f 1) of 1 => true | x => false;
val case_const2 = case (f 1) of 0 => false | 1 => true | x => false;
val case_const3 =
    case (f 1) of 0 => false | 1 => true | 2 => false | x => false;
val case_typed1 = case (f 1) of 1 : int => true | x => false;
val case_layered1 = case (f 1) of x as 1 => true | x => false;
val case_layeredtyped1 = case (f 1) of x as (1 : int) => true | x => false;
val case_typedlayered1 = case (f 1) of (x as 1) : int => true | x => false;
