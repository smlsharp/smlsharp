fun id x = x
structure S =
struct
  val e = id nil (* ?X0 list *)
end

(*
2020-05-18 katsu

This must cause compile error.

*)
