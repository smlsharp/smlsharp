_interface "039_type.smi"
structure G =
struct
  datatype t = T
end
type t = G.t

(*
2011-08-21 katsu

This causes BUG at NameEval.

[BUG] NameEvalEnv: nil to lookupTy
    raised at: ../nameevaluation/main/NameEvalEnv.ppg.sml:407.20-407.41
   handled at: ../nameevaluation/main/NameEval.sml:2685.27-2685.30
                ../toplevel2/main/Top.sml:752.66-752.69
                ../toplevel2/main/Top.sml:864.37
                main/SimpleMain.sml:359.53


2011-08-22 ohori
Fixed and rewrote CheckProvide.sml
*)
