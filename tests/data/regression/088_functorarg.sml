_interface "088_functorarg.smi"
functor F(structure S : sig end) =
struct
  type t = S.must_be_hidden
end

(*
2011-08-29 katsu

This causes an unexpected tycon error.
An "unbound type" error is expected.

088_functorarg.sml:4.12-4.27 Error:
  (name evaluation 062) type constructor arity does't agree: S.must_be_hidden
*)

(*
2011-08-31 ohori

Fixed.

*)
