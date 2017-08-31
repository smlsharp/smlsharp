functor F(
  A : sig
    structure S1 : sig
      datatype t = T
    end
    structure S2 : sig
      datatype t = T
    end
    sharing type S1.t = S2.t
  end
) =
struct
end

structure S =
struct
  datatype t = T
end

structure X = F(
  structure S1 = S
  structure S2 = S
)

(*
2011-11-29 katsu

This causes BUG.

[BUG] NameEval: non conid
    raised at: ../nameevaluation/main/NameEval.sml:1777.39-1777.54
   handled at: ../nameevaluation/main/NameEval.sml:2248.8
                ../nameevaluation/main/NameEval.sml:2460.31
                ../nameevaluation/main/NameEval.sml:2493.27-2493.30
                ../toplevel2/main/Top.sml:753.66-753.69
                ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53

*)

(*
2011-11-29 ohori

Fixed. This was due to the fact that  varE in TSTR_DTY is not updated 
at instantiation (checkEnv/checkTstr in NameEval.sml).
*)
