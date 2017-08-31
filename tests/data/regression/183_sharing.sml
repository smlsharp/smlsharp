signature S =
sig
  structure S1 : sig
    datatype 'a t = T of 'a
  end
  structure S2 : sig
    datatype 'a t = T of 'a
  end
  sharing type S1.t = S2.t
end

(*
2011-12-06 katsu

This causes an unexpected error.

r/smlsharp -c 183_sharing.sml 
183_sharing.sml:9.3-9.26 Error:
  (name evaluation Sig-050) Signature mismatch in sharing type clause:S2.t

*)
