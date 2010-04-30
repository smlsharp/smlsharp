(**
 * base implementation of MONO_ARRAY_SLICE.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MonoArraySliceBase.sml,v 1.4 2007/09/01 03:21:16 kiyoshiy Exp $
 *)
functor MonoArraySliceBase
            (
               structure A : MONO_ARRAY
               structure V
                         : sig
                             include MONO_VECTOR
                             type slice = vector * int * int
                             val copy
                                 : {src : vector, si : int, dst : vector, di : int, len : int}
                                   -> unit
                             val concatSlices : slice list -> vector
                           end
               sharing type A.elem = V.elem
               sharing type A.vector = V.vector
               sharing type A.array = V.vector
            ) =
struct

  (***************************************************************************)

  structure VS = MonoVectorSliceBase(V)

  (***************************************************************************)

  (*
   * The representation of slice and implementation of functions are shared
   * with MonoVectorSliceBase.
   *)
  open VS

  (***************************************************************************)

  type array = VS.vector
  type vector_slice = slice

  (***************************************************************************)

  fun update ((array, start, length), index, value) =
      if (index < 0) orelse (length <= index)
      then raise General.Subscript
      else A.update (array, start + index, value)

  fun copy {src = (srcArray, srcStart, srcLen), dst, di} =
      if (di < 0) orelse (A.length dst < di + srcLen)
      then raise General.Subscript
      else
        V.copy{src = srcArray, si = srcStart, dst = dst, di = di, len = srcLen}
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
