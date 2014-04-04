(**
 * common interface of the polymorphic ArraySlice and mono-ArraySlices.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
signature MUTABLE_SEQUENCE_SLICE =
sig

  include SEQUENCE_SLICE

  type vector_slice

  val update : slice * int * elem -> unit
  val copy : {src : slice, dst : sequence, di : int} -> unit
  val copyVec : {src : vector_slice, dst : sequence, di : int} -> unit
  val modifyi : (int * elem -> elem) -> slice -> unit
  val modify  : (elem -> elem) -> slice -> unit

  val sliceVec : vector * int * int option -> vector_slice

end;
