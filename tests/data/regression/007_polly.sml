fun f x = x
val y = f 1

(*
2011-08-12 ohori

The original bound type variables are instantiated.
Type Inference:
  ...
val f(0) = ['a. fn {x(1)} => x(1) :int(t0)]  <=====
val y(2) =
    (f(0) :['a. int(t0) -> int(t0)] {int(t0)} : (int(t0) -> int(t0)))
    1 : (int(t0))

2011-08-12 ohori
Fixed the bug in substBTvar in TypesUtils. This potion is re-writen in
the new version by eliminating complicated typetransducer. The bug is
in the case of TYVARty:
* T.TYVARty (ref (T.TVAR tvkind)) 
  In this case, the code should return ty itself, since a free type
  variable does not contain bound type variables.
* T.TYVARty (ref (T.SUBSTITUTED ty))
  In this case, the code should return (substBTvar subst ty) and the
  original ref as it is.

*)
