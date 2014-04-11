(**
 * common functions which array and vector provide.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
signature SEQUENCE =
sig

  type elem
  type sequence

  val maxLen : int
  val fromList : elem list -> sequence
  val tabulate : int * (int -> elem) -> sequence
  val length : sequence -> int
  val sub : sequence * int -> elem
  val appi : (int * elem -> unit) -> sequence -> unit
  val app : (elem -> unit) -> sequence -> unit
  val foldli : (int * elem * 'b -> 'b) -> 'b -> sequence -> 'b
  val foldri : (int * elem * 'b -> 'b) -> 'b -> sequence -> 'b
  val foldl : (elem * 'b -> 'b) -> 'b -> sequence -> 'b
  val foldr : (elem * 'b -> 'b) -> 'b -> sequence -> 'b
  val findi : (int * elem -> bool) -> sequence -> (int * elem) option
  val find : (elem -> bool) -> sequence -> elem option
  val exists : (elem -> bool) -> sequence -> bool
  val all : (elem -> bool) -> sequence -> bool
  val collate : (elem * elem -> order) -> sequence * sequence -> order

  (* following functions are used to write test code. *)
                                                                 
  val intToElem : int -> elem
  val nextElem : elem -> elem
  val elemToString : elem -> string
  val compareElem : (elem * elem) -> General.order

end
