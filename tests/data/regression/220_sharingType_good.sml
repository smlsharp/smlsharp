signature S =
sig
  type t
  type s
  sharing type t = s
end

structure S : S =
struct
  datatype t = D of int
  type s = t
end

(*
2017-08-07 katsu
*)
