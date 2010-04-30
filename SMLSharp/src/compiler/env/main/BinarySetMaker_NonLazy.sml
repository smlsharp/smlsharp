(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: BinarySetMaker_NonLazy.sml,v 1.3 2007/09/22 02:41:47 ohori Exp $
 *)
functor BinarySetMaker(Key : ORD_KEY)
  : sig
      include ORD_SET
(*
      val fromList2 : Key.ord_key list -> set
*)
      val pu_set : (Key.ord_key Pickle.pu) -> set Pickle.pu
    end =
struct

  structure P = Pickle
  structure M = BinarySetFn(Key)
  open M

(*
  fun fromList2 list = List.foldl (fn (item, m) => add (m, item)) empty list
*)

  fun pu_set (value_pu : Key.ord_key P.pu) =
      let
        fun setToList set = listItems set
        fun listToSet list =
            List.foldl (fn (value, set) => add (set, value)) empty list
      in
        P.conv (listToSet, setToList) (P.list value_pu)
      end

end;
