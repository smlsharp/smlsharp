fun f x =
    let
      fun f1 () = #a x
      fun f2 () = #b x 0
      fun f3 () = (#b x 0) + 1
    in () end;
fun f x =
    let
      fun f2 () = #b x 0
      fun f3 () = (#b x 0) + 1
    in () end;
fun f x =
    let
      fun f1 () = #a x
      fun f3 () = (#b x 0) + 1
    in () end;
fun f x =
    let
      fun f1 () = #a x
      fun f2 () = #b x 0
    in () end;
