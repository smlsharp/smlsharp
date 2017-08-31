_interface "076_typeerror.smi"
fun f x =
    let
      val (_, x) = g x
      val (_, x) = g x
    in
      ()
    end

(*
2011-08-27 katsu

This causes BUG at InferTypes.
An type error is expected.

[BUG] InferType: var not found
    raised at: ../typeinference2/main/InferTypes.sml:1556.26-1556.45
   handled at: ../typeinference2/main/InferTypes.sml:3621.28
		../typeinference2/main/InferTypes.sml:2500.19
		../typeinference2/main/InferTypes.sml:3621.28
		../toplevel2/main/Top.sml:766.65-766.68
		../toplevel2/main/Top.sml:868.37
		main/SimpleMain.sml:359.53

*)

(*
2011-08-28 ohori

Fixed. 

decompoeValbind does not increment varEnv when some type error occurres.
So the assumption of every variable has an entry in varEnv is wrong.
The only case is user error. So if var = {path,id} is not found then simply
proceed by adding {path=path, id=id, ty=T.ERRORty} in the context and proceeds.

*)
