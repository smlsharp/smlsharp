_interface "047_exnrep.smi"
structure S =
struct
  exception E = Bind
end

(*
2011-08-22 katsu

This causes unexpected name error.

047_exnrep.smi:3.13-3.13 Error:
  (name evaluation 140) Provide check fail (missing exception name) : S.E.E

2011-08-23 ohori
Fixed. Added a case of IDEXEXN in CheckProvide.sml.
例外のリプリケーションは，インタフェイスと一致することが必要，とする．
055_exception.sml

*)
