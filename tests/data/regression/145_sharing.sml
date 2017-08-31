signature S =
sig
  datatype t = A | B of t
end
signature X =
sig
  structure S : S
  structure T : S
  sharing S = T
end

(*
2011-11-25 katsu

This causes an unexpected sigature mismatch error.

145_sharing.sml:9.3-9.15 Error:
  (name evaluation Sig-050) Signature mismatch in sharing type clause:T.t
*)


(*
2011-11-25 ohori

Fixed.

For sharing types, we need to check the consistency of datatype constructor.
This is something beyond the semantics defined in the Definition, since we
need to generate a structure instantce for functor.

To do this, type equality checking must be performed under the assumption that
all type ids specified in sharing types are equivalent. This mechanism is added.

*)
