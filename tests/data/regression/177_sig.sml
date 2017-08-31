structure S :> sig
  type t
  type 'a s
  val x : t s
end =
struct
  type t = unit
  type 'a s = 'a * 'a
  val x = ((), ())
end

(*
2011-12-01 katsu

This causes an unexpected type error.

t.sml:1.11-10.3 Error:
  (type inference 012) signature mismatch at S.x
    inferred type: unit(t7[]) * unit(t7[])
  type annotation: t(t32[[opaque(rv1,t(t7[]))]]) s(t31[[opaque(rv1,['a. 'a * 'a])]])

*)

(*
2011-12-04 ohori

Fixed. CONSTRUCTOR arguments need to be reduced of cource.
*)
