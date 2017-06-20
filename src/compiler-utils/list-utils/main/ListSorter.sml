(**
 * sort a list.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ListSorter.sml,v 1.5 2006/02/28 16:11:11 kiyoshiy Exp $
 *)
structure ListSorter
  : sig

      (**
       * @params compare list
       * @param compare a function which indicates which of two elements is
       *               less than or equal to or more than the other.
       * @param list unsorted list
       * @return sorted list
       *)
      val sort : ('a * 'a -> order) -> 'a list -> 'a list

    end =
struct

  (***************************************************************************)

  (* ToDo : implement efficient sort algorithm (ex. merge sort). *)
(*
  fun sort compare list =
      let
        (* return true if value is less than base. *)
        fun lessThan base value = LESS = compare (value, base)
        fun sort_part [] trailer = trailer
          | sort_part (head :: tail) trailer =
            let
              val (smallers, greaters) = List.partition (lessThan head) tail
              val greaters = sort_part greaters trailer
            in sort_part smallers (head :: greaters)
            end
      in sort_part list []
      end
*)

  fun sort compare list =
      let
        val array = Array.fromList list
        fun sub index = Array.sub (array, index)
        fun update (index, value) = Array.update (array, index, value)
        fun swap (i, j) =
            let val tmp = sub i in update (i, sub j); update (j, tmp) end
        fun quickSort (left, right) =
	    if left < right
            then
              let
	        val center = (left + right) div 2
	        val pivotValue = sub center

	        val _ = update (center, sub left)
                (* ensure that values left to pivot are less than pivotValue,
                 * and value to rigth to pivot are greater than or equal to
                 * pivotValue. *)
                fun scan (cursor, pivot) =
                    if cursor <= right
                    then
                      if LESS = compare(sub cursor, pivotValue)
                      then
                        (
                          swap (pivot + 1, cursor);
                          scan (cursor + 1, pivot + 1)
                        )
                      else scan (cursor + 1, pivot)
                    else pivot
                val pivot = scan (left + 1, left)
              in
                update (left, sub pivot);
                update (pivot, pivotValue);
                (* now, array is partitioned at pivot. *)

	        quickSort(left, pivot - 1);
	        quickSort(pivot + 1, right)
              end
            else ()
      in
        quickSort (0, Array.length array - 1);
        Array.foldr (fn (value, list) => value :: list) [] array
      end


  (***************************************************************************)

end;
