structure Str1 = struct
  val v1 = 1
  fun f1 x = x
  type t1 = int
  datatype d1 = D1
  datatype d2 = D2 of int
  val v2 = D1
  fun f2 x = D2 x
  exception Exn1
  structure Str11 = struct
    type t11 = t1
    exception Exn11 = Exn1
  end
  structure Str12 = Str11
end


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


structure Str2 : Sig1 = struct
  val v1 = 1
  fun f1 x = x
  type t1 = int
  datatype d1 = D1
  datatype d2 = D2 of int
  val v2 = D1
  fun f2 x = D2 x
  exception Exn1
  structure Str11 = struct
    type t11 = t1
    exception Exn11 = Exn1
  end
  structure Str12 = Str11
end


structure Str3 :> Sig1 = struct
  val v1 = 1
  fun f1 x = x
  type t1 = int
  datatype d1 = D1
  datatype d2 = D2 of int
  val v2 = D1
  fun f2 x = D2 x
  exception Exn1
  structure Str11 = struct
    type t11 = t1
    exception Exn11 = Exn1
  end
  structure Str12 = Str11
end
