signature G =
sig
  datatype t = D of t
end

signature C =
sig
  structure G1 : G
  structure G2 : G
  structure G3 : G
  sharing type G1.t = G2.t = G3.t
end

(*
2011-11-30 katsu

This causes an unexpected mismatch error.

168_sharing.sml:11.3-11.33 Error:
  (name evaluation Sig-050) Signature mismatch in sharing type clause:G2.t
*)

(*
2011-11-30 ohori

Fixed the bug in the makeTypIdEquiv (NormalizeTy.sml)

*)
