signature MONO_VECTOR =
sig
  type vector
  type elem
  val maxLen : int
  val length : vector -> int
  val sub : vector * int -> elem
  val foldli : (int * elem * 'a -> 'a) -> 'a -> vector -> 'a
  val foldl : (elem * 'a -> 'a) -> 'a -> vector -> 'a
  val foldri : (int * elem * 'a -> 'a) -> 'a -> vector -> 'a
  val foldr : (elem * 'a -> 'a) -> 'a -> vector -> 'a
  val appi : (int * elem -> unit) -> vector -> unit
  val app : (elem -> unit) -> vector -> unit
  val findi : (int * elem -> bool) -> vector -> (int * elem) option
  val find : (elem -> bool) -> vector -> elem option
  val exists : (elem -> bool) -> vector -> bool
  val all : (elem -> bool) -> vector -> bool
  val collate : (elem * elem -> order) -> vector * vector -> order
  val fromList : elem list -> vector
  val tabulate : int * (int -> elem) -> vector
  val update : vector * int * elem -> vector
  val concat : vector list -> vector
  val mapi : (int * elem -> elem) -> vector -> vector
  val map : (elem -> elem) -> vector -> vector
end
