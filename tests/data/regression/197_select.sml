fun f12 r = #x (#a r);
val v121 = f12 {a = {x = 2, y = 3}, b = true};

(*
2012-05-18 katsu

This causes segmentation fault.
Fixed.
*)
