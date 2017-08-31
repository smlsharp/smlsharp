structure S1 =
struct
  datatype t = XXXXXXXXXXXXXXX of int
end

structure S2 : sig
  type t
end =
struct
  open S1
end

structure S3 : sig
  type t
end
where type t = S2.t
=
struct
  type t = S2.t
end

(*
2011-08-25 katsu

This causes BUG.

[BUG] NameEval: realizer Con not found
    raised at: ../nameevaluation/main/EvalSig.sml:331.40-331.68
   handled at: ../nameevaluation/main/EvalSig.sml:530.24
                ../nameevaluation/main/NameEval.sml:2773.31
                ../nameevaluation/main/NameEval.sml:2792.27-2792.30
                ../toplevel2/main/Top.sml:756.66-756.69
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-27 ohori

Fixed. 
In the case of SIGWHERE in EvalSig.sml, when setting a dty realizer,
code is added to suppress the generation of realizerVarE when 
the realizee is non datatype.

*)


