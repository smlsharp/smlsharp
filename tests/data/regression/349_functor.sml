functor G(S : sig  datatype a = A of a end ) =
struct
   datatype a = datatype S.a
end
structure R = struct datatype a = A of a end 
structure P = G(R) : sig  datatype a = A of a end

(* 348_functor.smlのバグの１つ。
*)



