(* 2013-4-29 ohori

This causes unexpected type error

$ smlc -c temp.sml
temp.smi:3.8-9.8 Error:
  (type inference 075) type and type annotation don't agree
    inferred type: ['a#{A: 'b}, 'b, 'c#{B: int}. 'a * 'c -> unit]
  type annotation: ['a#{A: 'b}, 'b, 'c#{B: int}. 'a * 'c -> unit]
*)

structure A =
struct
  fun pairMeta  ({A : 'a, ...}, {B : int,...})
    = ()

end


