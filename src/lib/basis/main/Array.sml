(**
 * Array structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Array.sml,v 1.8 2005/12/19 03:44:07 kiyoshiy Exp $
 *)
structure Array =
struct

  (***************************************************************************)

  (*
   * The representation of array type is the same with those of Vector.vector
   * type. And implementation of most members are borrowed from the Vector
   * structure.
   *)
  open Vector

  type 'a array = 'a vector

  fun 'a update (array, index, newValue) = 
      if index < 0 orelse length array <= index
      then raise Subscript (* if buffer = NONE, the sub always fails. *)
      else arrayUpdate (array, index, newValue)

  (**
   * utility function to copy an array.
   * @params srcArray destArrayOpt
   * @param srcArray the array from which elements are copied.
   * @param destArrayOpt the array into which elements are copied.
   * @return the array into which elements are written.
   *        If destArrayOpt is NONE, a new array is generated and returned.
   *)
  fun copyArray srcArray destArray destStart =
      case length srcArray of
        0 => destArray
      | length =>
        let
          fun write ~1 = ()
            | write index =
              let val value = sub(srcArray, index)
              in
                update (destArray, destStart + index, value); write (index - 1)
              end
        in
          write (length - 1); destArray
        end

  fun copy {src, dst, di} =
      if (di < 0) orelse (length dst < di + length src)
      then raise General.Subscript
      else let val _ = copyArray src dst di in () end

  val copyVec = copy

  (* NOTE: A fresh copy is generated. *)
  fun vector array =
      fromList(foldr (fn (element, accum) => element :: accum) [] array)

  fun modifyi modifyFun array =
      appi
          (fn (index, element) =>
              update (array, index, (modifyFun (index, element))))
          array

  fun modify modifyFun array =
      modifyi (fn (_, element) => modifyFun element) array

  fun array (length, initial) =
      if (length < 0) orelse (maxLen < length)
      then raise General.Size
      else makeArray(length, initial)

  (***************************************************************************)

end;
