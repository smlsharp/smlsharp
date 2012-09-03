(**
 * base implementation of MONO_ARRAY_SLICE.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MonoArraySliceBase.sml,v 1.3 2005/08/10 12:38:34 kiyoshiy Exp $
 *)
functor MonoArraySliceBase
            (
               structure A : MONO_ARRAY
               structure V : MONO_VECTOR
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

  local
    fun copyArray (srcArray, srcStart, destArray, destStart, length) =
        let
          fun write ~1 = ()
            | write index =
              let val value = A.sub(srcArray, srcStart + index)
              in
                A.update(destArray, destStart + index, value);
                write (index - 1)
              end
        in write (length - 1)
        end
  in
  fun copy {src = (srcArray, srcStart, srcLength), dst, di} =
      if (di < 0) orelse (A.length dst < di + srcLength)
      then raise General.Subscript
      else copyArray (srcArray, srcStart, dst, di, srcLength)
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
