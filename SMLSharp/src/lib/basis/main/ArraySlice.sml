(**
 * ArraySlice structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ArraySlice.sml,v 1.4 2007/09/01 03:21:15 kiyoshiy Exp $
 *)
structure ArraySlice =
struct

  (***************************************************************************)

  structure A = Array
  structure V = Vector

  (***************************************************************************)

  (*
   * The representation of slice and implementation of functions are shared
   * with VectorSlice.
   *)
  open VectorSlice

  (***************************************************************************)

  type 'a array = 'a V.vector
  type 'a vector_slice = 'a slice

  (***************************************************************************)

  fun update ((array, start, length), index, value) =
      if (index < 0) orelse (length <= index)
      then raise General.Subscript
      else A.update (array, start + index, value)

  fun copy {src = (srcArray, srcStart, srcLen), dst, di} =
      if (di < 0) orelse (A.length dst < di + srcLen)
      then raise General.Subscript
      else
        V.copy
            {src = srcArray, si = srcStart, dst = dst, di = di, len = srcLen}
  val copyVec = copy

  fun modifyi modifyFun slice =
      appi
          (fn (index, element) =>
              update (slice, index, (modifyFun (index, element))))
          slice

  fun modify modifyFun slice =
      modifyi (fn (_, element) => modifyFun element) slice

  (***************************************************************************)

end;
