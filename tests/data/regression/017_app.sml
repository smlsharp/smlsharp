infixr ::
fun app f = 
    let
      fun app_rec [] = ()
        | app_rec (a::L) = (f a; app_rec L)
    in
      app_rec
    end

(*
2011-8-14 ohori.
This code causes a BUG exception in toYAANormal

[BUG] searchEnvAcc
    raised at: ../toyaanormal/main/ToYAANormal.sml:731.39-731.65
   handled at: ../toyaanormal/main/ToYAANormal.sml:746.74
		../toyaanormal/main/ToYAANormal.sml:783.46
		../toplevel2/main/Top.sml:797.37
		main/SimpleMain.sml:269.53

*)

(*
2011-08-14 katsu

This ticket is same as 015_app and this bug is already fixed.

*)
