signature S0 =
sig
  type t
end

signature S1 =
sig
  datatype t0 = T0
  datatype t1 = T1
  structure A0 : S0
  structure A1 : S0
  sharing type A0.t = t0
  sharing type A1.t = t1
end

signature S2 =
sig
  structure B0 : S1
  structure B1 : S1
  sharing B0 = B1
end

(*
2011-12-01 katsu

This causes an unexpected mismatch error.

172_sharing.sml:20.3-20.17 Error:
  (name evaluation Sig-050) Signature mismatch in sharing type
  clause:B0.A1.t,B1.A1.t
*)

(*
2011-12-01 ohori

Fixed.
*)
