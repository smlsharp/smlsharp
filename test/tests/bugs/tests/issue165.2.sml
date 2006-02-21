exception E;
fun raiseE () = raise E;
val xFree =
    let
      fun outer () =
          let val vOuter = 2
          in fn x => raiseE () handle E => vOuter end
    in outer () ()
    end;
xFree + 1;
