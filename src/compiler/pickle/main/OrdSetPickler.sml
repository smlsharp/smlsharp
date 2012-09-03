(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: OrdSetPickler.sml,v 1.1 2006/01/11 11:47:57 kiyoshiy Exp $
 *)
functor OrdSetPickler(Set : ORD_SET)
  : sig
      val set : Set.item Pickle.pu -> Set.set Pickle.pu
  end =
struct

  (***************************************************************************)

  structure P = Pickle

  (***************************************************************************)

  fun set (item_pu : Set.item P.pu) =
      let
        fun setToList set = Set.listItems set
        fun listToSet list =
            foldl
                (fn (value, set) => Set.add (set, value))
                Set.empty
                list
      in
        P.conv (listToSet, setToList) (P.list item_pu)
      end

end
