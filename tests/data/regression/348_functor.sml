signature S =
sig
  datatype a = A of a | B
end

signature T =
sig
  structure T : S
end

functor G(S1 : S) : T =
struct
  structure T = F(S1)
end

(*
2019-11-11 katsu

This code is correct but causes the following error.

348_functor2.smi:3.17-3.17 Error:
  (name evaluation "300") Signature mismatch. constructor type mismatch: T.A

*)
