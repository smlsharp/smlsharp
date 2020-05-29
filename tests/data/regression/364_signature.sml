fun id x = x
structure S : sig
  val e : 'a list
end =
struct
  val e = id nil (* ?X0 list *)
end

(*
2020-05-18 katsu

This must cause compile error.

*)
