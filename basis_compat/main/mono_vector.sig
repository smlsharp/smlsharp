signature MONO_VECTOR =
  sig
    type elem
    type vector
    val maxLen : int
    val fromList : elem list -> vector
    val tabulate : int * (int -> elem) -> vector
    val length : vector -> int
    val sub : vector * int -> elem
    val extract : vector * int * int option -> vector
    val concat : vector list -> vector
    val app : (elem -> unit) -> vector -> unit
    val map : (elem -> elem) -> vector -> vector
    val foldl : (elem * 'a -> 'a) -> 'a -> vector -> 'a
    val foldr : (elem * 'a -> 'a) -> 'a -> vector -> 'a
    val appi : (int * elem -> unit) -> vector * int * int option -> unit
    val mapi : (int * elem -> elem) -> vector * int * int option -> vector
    val foldli : (int * elem * 'a -> 'a)
                 -> 'a -> vector * int * int option -> 'a
    val foldri : (int * elem * 'a -> 'a)
                 -> 'a -> vector * int * int option -> 'a
  end
