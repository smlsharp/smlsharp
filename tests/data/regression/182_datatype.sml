structure S : sig
  datatype 'a t = T of 'a
end =
struct
  datatype 'a t = T of 'a
end

(*
2011-12-06 katsu

This causes an unexpected mismatch error.

182_datatype.sml:1.11-6.3 Error:
  (name evaluation 280) Signature mismatch (datatype): S.t(4)
*)
