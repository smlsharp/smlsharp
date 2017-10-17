_interface "055_exception.smi"
exception E = Bind

(*
2011-08-23 katsu

This should causes an provide error
since E and Bind are same but they are distinct in the interface file.

*)


(*
2011-08-23 ohori
Fixed.

例外のリプリケーションは，インタフェイスと一致することが必要，とする．
047_exnrep.sml参照．

*)
