(**
 *
 * identifier of type, term, label and etc.
 * @copyright (c) 2006-2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 *)
signature GLOBAL_ID =
sig

  eqtype id (* type should be better *)

  structure Map
    : sig
        include ORD_MAP
        val fromList : (Key.ord_key * 'item) list -> 'item map
        val pu_map
          : (Key.ord_key Pickle.pu * 'value Pickle.pu) -> 'value map Pickle.pu
      end
  sharing type id = Map.Key.ord_key

  structure Set
    : sig
        include ORD_SET
        val pu_set : (Key.ord_key Pickle.pu) -> set Pickle.pu
      end 
  sharing type id = Set.Key.ord_key

  val format_id : id -> SMLFormat.FormatExpression.expression list
  val toString : id -> string
  val pu_ID : id Pickle.pu
  (**
   * compare(id1,id2) = LESS means  id1 was allocated before id2.
   *)
  val compare : id * id -> order
  val eq : id * id -> bool

  val toInt : id -> int
  val fromInt : int -> id

 (* make the counter ready with the next id *)
  val init : id -> unit

 (* stop the counter and return the seed id is the next id *)
  val reset : unit -> id 

  val generate : unit -> id 

  (* peakNth 0 = generate (); (peakNth n;generate ()) = generate() *)
  val peekNth : int -> id 

  (* (advance 0;generate())  = generate () *)
  val advance : int -> unit 

end
