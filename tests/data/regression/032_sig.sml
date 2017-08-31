signature A =
sig
  val f : 'a -> unit
end
structure B : A =
struct
  fun f _ = ()
end

(*
2011-08-18 katsu

This causes an unexpected type error.

/Users/katsu/smlsharp-ng/doc/tests/032_sig.sml:5.11-8.3 Error:
  (type inference 012) type and type annotation don't agree
  inferred type: 'b -> unit(t7)
  type annotation: 'c('RIGID(tv20)) -> unit(t7)

2011-08-18 ohori

This is the same bug as 028_utvar.sml and has been fixed.

*)
