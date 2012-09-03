signature ARRAY =
  sig
    type 'a array
    type 'a vector
    val maxLen : int
    val array : int * 'a -> 'a array
    val tabulate : int * (int -> 'a) -> 'a array
    val fromList : 'a list -> 'a array
    val length : 'a array -> int
    val sub : 'a array * int -> 'a
    val update : 'a array * int * 'a -> unit
    val extract : 'a array * int * int option -> 'a vector
    val copy : {di:int, dst:'a array, len:int option, si:int, src:'a array}
               -> unit
    val copyVec : {di:int, dst:'a array, len:int option, si:int, src:'a vector}
                  -> unit
    val app : ('a -> unit) -> 'a array -> unit
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a array -> 'b
    val modify : ('a -> 'a) -> 'a array -> unit
    val appi : (int * 'a -> unit) -> 'a array * int * int option -> unit
    val foldli : (int * 'a * 'b -> 'b)
                 -> 'b -> 'a array * int * int option -> 'b
    val foldri : (int * 'a * 'b -> 'b)
                 -> 'b -> 'a array * int * int option -> 'b
    val modifyi : (int * 'a -> 'a) -> 'a array * int * int option -> unit
  end
