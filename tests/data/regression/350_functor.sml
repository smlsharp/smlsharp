functor G(
  S2 : sig
    datatype a = A of a | B 
 end
) =

struct
    datatype a = datatype S2.a
end

structure R = struct datatype a = A of a | B end 

signature S =
sig
  datatype a = A of a | B
end
structure P = G(R) :  S

(* 348_functor.smlのバグの１つ。
*)
