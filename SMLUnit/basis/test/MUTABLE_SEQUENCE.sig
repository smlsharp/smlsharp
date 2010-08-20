(**
 * common interface of the polymorphic Array and mono-Arrays.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
signature MUTABLE_SEQUENCE =
sig

  include SEQUENCE

  eqtype array
  type vector
  sharing type array = sequence

  val array : int * elem -> array
  val update : array * int * elem -> unit
  val vector : array -> vector
  val copy : {src : array, dst : array, di : int} -> unit
  val copyVec : {src : vector, dst : array, di : int} -> unit
  val modifyi : (int * elem -> elem) -> array -> unit
  val modify : (elem -> elem) -> array -> unit

  val listToVector : elem list -> vector
  val vectorToList : vector -> elem list

end;
