signature Sig1 = sig
  val v1 : int
  val f1 : int -> int
  type t1 = int
  datatype d1 = D1
  datatype d2 = D2 of int
  val v2 : d1
  val f2 : int -> d2
  exception Exn1
  structure Str11 : sig
    type t11
    exception Exn11
  end
  structure Str12 : sig
    type t11 = t1
    exception Exn11
  end
end

