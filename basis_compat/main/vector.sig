signature VECTOR =
  sig
    eqtype 'a vector
    val maxLen : int
    val fromList : 'a list -> 'a vector
    val tabulate : int * (int -> 'a) -> 'a vector
    val length : 'a vector -> int
    val sub : 'a vector * int -> 'a
    val extract : 'a vector * int * int option -> 'a vector
    val concat : 'a vector list -> 'a vector
    val app : ('a -> unit) -> 'a vector -> unit
    val map : ('a -> 'b) -> 'a vector -> 'b vector
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val appi : (int * 'a -> unit) -> 'a vector * int * int option -> unit
    val mapi : (int * 'a -> 'b) -> 'a vector * int * int option -> 'b vector
    val foldli : (int * 'a * 'b -> 'b)
                 -> 'b -> 'a vector * int * int option -> 'b
    val foldri : (int * 'a * 'b -> 'b)
                 -> 'b -> 'a vector * int * int option -> 'b
  end
