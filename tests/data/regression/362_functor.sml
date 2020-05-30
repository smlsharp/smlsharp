functor F (P : sig type t end) =
struct
  type u = {y : int}
  fun f _ : u = { y = 5 }
end

(*
2020-05-19 katsu

This causes the following unexpected type error.

(none)-1.8 Error:
  (type inference 083) type and type annotation don't agree
    inferred type: ['a. ({1: 'a} -> {1: 'a}) -> {1: ['b. 'b -> {y: int}]}]
  type annotation: ['a. ({1: 'a} -> {1: 'a}) -> {1: int -> {y: int}}]

*)
