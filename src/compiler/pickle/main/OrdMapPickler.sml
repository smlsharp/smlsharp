(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OrdMapPickler.sml,v 1.3 2006/02/28 16:11:03 kiyoshiy Exp $
 *)
functor OrdMapPickler(Map : ORD_MAP)
  : sig
      val map
          : (Map.Key.ord_key Pickle.pu * 'value Pickle.pu)
            -> 'value Map.map Pickle.pu
  end =
struct

  (***************************************************************************)

  structure P = Pickle

  (***************************************************************************)

  fun map (key_pu : Map.Key.ord_key P.pu, value_pu : 'value P.pu) =
      let
        fun mapToList map = Map.listItemsi map
        fun listToMap list =
            foldl
                (fn ((key, value), map) => Map.insert (map, key, value))
                Map.empty
                list
      in
        P.conv (listToMap, mapToList) (P.list (P.tuple2 (key_pu, value_pu)))
      end

end
