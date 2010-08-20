(**
 * common interface of the polymorphic Array2 and mono-2D-Arrays.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
signature MUTABLE_2D_SEQUENCE =
sig

  eqtype array
  type elem
  type vector
  type region =
       {
         base : array,
         row : int,
         col : int,
         nrows : int option,
         ncols : int option
       }
  datatype traversal = datatype Array2.traversal

  val array : int * int * elem -> array
  val fromList : elem list list -> array
  val tabulate : traversal -> int * int * (int * int -> elem) -> array

  val sub : array * int * int -> elem
  val update : array * int * int * elem -> unit

  val dimensions : array -> int * int
  val nCols : array -> int
  val nRows : array -> int

  val row : array * int -> vector
  val column : array * int -> vector

  val copy : {src : region, dst : array, dst_row : int, dst_col : int} -> unit

  val appi : traversal -> (int * int * elem -> unit) -> region -> unit
  val app  : traversal -> (elem -> unit) -> array -> unit
  val foldi : traversal -> (int * int * elem * 'b -> 'b) -> 'b -> region -> 'b
  val fold : traversal -> (elem * 'b -> 'b) -> 'b -> array -> 'b
  val modifyi : traversal -> (int * int * elem -> elem) -> region -> unit
  val modify  : traversal -> (elem -> elem) -> array -> unit 

  (* following functions are used to write test code. *)
  val intToElem : int -> elem
  val nextElem : elem -> elem
  val elemToString : elem -> string
  val compareElem : (elem * elem) -> General.order
  val listToVector : elem list -> vector
  val vectorToList : vector -> elem list

end;
