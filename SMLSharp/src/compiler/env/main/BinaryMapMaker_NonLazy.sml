(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BinaryMapMaker_NonLazy.sml,v 1.2 2007/09/25 10:10:26 kiyoshiy Exp $
 *)
functor BinaryMapMaker(Key : ORD_KEY)
  : sig
      include ORD_MAP
      val fromList : (Key.ord_key * 'item) list -> 'item map
      val pu_map
          : (Key.ord_key Pickle.pu * 'value Pickle.pu) -> 'value map Pickle.pu
    end =
struct

  structure P = Pickle
  structure M = BinaryMapFn(Key)
  open M

  fun fromList list =
      List.foldl (fn ((key, item), m) => insert (m, key, item)) empty list

  fun pu_map (key_pu : Key.ord_key P.pu, value_pu : 'value P.pu) =
      let
        fun mapToList map = listItemsi map
        fun listToMap list =
            List.foldl
                (fn ((key, value), map) => insert (map, key, value))
                empty
                list
      in
        P.conv (listToMap, mapToList) (P.list (P.tuple2 (key_pu, value_pu)))
      end

end;
