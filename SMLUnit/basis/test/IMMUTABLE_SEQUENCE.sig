(**
 * common interface of the polymorphic Vector and mono-Vectors.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
signature IMMUTABLE_SEQUENCE =
sig

  include SEQUENCE
  
  type vector
  sharing type vector = sequence

  val update : vector * int * elem -> vector
  val concat : vector list -> vector
  val mapi : (int * elem -> elem) -> vector -> vector
  val map : (elem -> elem) -> vector -> vector

end
