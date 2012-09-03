(**
 * ArraySlice structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ArraySlice.sml,v 1.3 2005/08/10 12:38:34 kiyoshiy Exp $
 *)
structure ArraySlice =
struct

  (***************************************************************************)

  structure A = Array

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

  local
    fun copyArray (srcArray, srcStart, destArray, destStart, length) =
        let
          fun write ~1 = ()
            | write index =
              let val value = A.sub(srcArray, srcStart + index)
              in
                A.update
                    (destArray, destStart + index, value); write (index - 1)
              end
        in write (length - 1)
        end
  in
  fun copy {src = (srcArray, srcStart, srcLength), dst, di} =
      copyArray (srcArray, srcStart, dst, di, srcLength)
  val copyVec = copy
  end

  fun modifyi modifyFun slice =
      appi
          (fn (index, element) =>
              update (slice, index, (modifyFun (index, element))))
          slice

  fun modify modifyFun slice =
      modifyi (fn (_, element) => modifyFun element) slice

  (***************************************************************************)

end;
