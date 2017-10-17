abstype at3 = D of string
withtype t3 = string * at3
with val ax3 : at3 = D "c"
end
val gx3 : t3 = ("c", ax3)

(*
2012-05-18 katsu

This causes an unexpected name error.
t3 should be seen from outside of abstype.

196_abstype.sml:1.1-4.3 Warning:
  abstype is obsolete; use opaque signature instead
196_abstype.sml:5.11-5.12 Error:
  (name evaluation Ty-040) unbound type constructor or type alias: t3

*)

(*
2012-06-20 katsu

fixed by changeset 2743536d89c8.
*)
