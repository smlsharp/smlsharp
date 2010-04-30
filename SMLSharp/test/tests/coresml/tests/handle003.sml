(*
"handle" expression which refers to variables which are bound in various locations.

<ul>
  <li>variable which is referred by a handler expression of a handle expression
    <ul>
      <li>global variable</li>
      <li>free variable bound in a outer function body</li>
      <li>function argument</li>
      <li>local variable in a function body</li>
    </ul>
  </li>
</ul>
*)
exception E;
fun raiseE () = raise E;

val vGlobal = 1;

val xGlobal = (raiseE ()) handle E => vGlobal;

val xFree =
    let
      fun outer () =
          let val vOuter = 2
          in fn x => raiseE () handle E => vOuter end
    in outer () ()
    end;

val xArg = let fun f vArg = (raiseE () handle E => vArg) in f 3 end;

val xLocal =
    let
      fun f () = let val vLocal = 4 in raiseE () handle E => vLocal end
    in f () end;
