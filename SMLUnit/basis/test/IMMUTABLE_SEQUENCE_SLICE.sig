(**
 * common interface of the polymorphic Vector and mono-Vectors.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
signature IMMUTABLE_SEQUENCE_SLICE =
sig

  include SEQUENCE_SLICE
  
  val concat : slice list -> sequence
  val mapi : (int * elem -> elem) -> slice -> vector
  val map  : (elem -> elem) -> slice -> vector

end
