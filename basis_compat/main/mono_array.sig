signature MONO_ARRAY =
  sig
    eqtype array
    type elem
    type vector
    val maxLen : int
    val array : int * elem -> array
    val tabulate : int * (int -> elem) -> array
    val fromList : elem list -> array
    val length : array -> int
    val sub : array * int -> elem
    val update : array * int * elem -> unit
    val extract : array * int * int option -> vector
    val copy : {di:int, dst:array, len:int option, si:int, src:array} -> unit
    val copyVec : {di:int, dst:array, len:int option, si:int, src:vector}
                  -> unit
    val app : (elem -> unit) -> array -> unit
    val foldl : (elem * 'a -> 'a) -> 'a -> array -> 'a
    val foldr : (elem * 'a -> 'a) -> 'a -> array -> 'a
    val modify : (elem -> elem) -> array -> unit
    val appi : (int * elem -> unit) -> array * int * int option -> unit
    val foldli : (int * elem * 'a -> 'a)
                 -> 'a -> array * int * int option -> 'a
    val foldri : (int * elem * 'a -> 'a)
                 -> 'a -> array * int * int option -> 'a
    val modifyi : (int * elem -> elem) -> array * int * int option -> unit
  end
