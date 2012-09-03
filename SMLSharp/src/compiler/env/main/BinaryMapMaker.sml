(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BinaryMapMaker_NonLazy.sml,v 1.2 2007/09/25 10:10:26 kiyoshiy Exp $
 *)
functor BinaryMapMaker(Key : ORD_KEY)
  : sig
      include ORD_MAP
      val fromList : (Key.ord_key * 'item) list -> 'item map
      val insertWith : ('a -> unit) -> 'a map * Key.ord_key * 'a -> 'a map
    end =
struct

  structure M = BinaryMapFn(Key)
  open M

  fun fromList list =
      List.foldl (fn ((key, item), m) => insert (m, key, item)) empty list

end;
