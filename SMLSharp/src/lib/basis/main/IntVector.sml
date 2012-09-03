(**
 * IntVector structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: IntVector.sml,v 1.9 2008/03/11 08:53:57 katsu Exp $
 *)
local
  structure Operations =
  struct
    type elem = int
    type vector = int array
    val maxLen = Vector.maxLen
    fun makeVector (intSize, initial) =
        SMLSharp.PrimArray.vector(intSize, initial)
    fun makeEmptyVector _ = _cast (SMLSharp.PrimArray.vector(0, 0)) : vector
    fun length array = SMLSharp.PrimArray.length array
    fun sub (array, intIndex) = SMLSharp.PrimArray.sub_unsafe (array, intIndex)
    fun update (array, intIndex, value) =
        SMLSharp.PrimArray.update_unsafe (array, intIndex, value)
    fun copy {src, si, dst, di, len} =
        SMLSharp.PrimArray.copy_unsafe (src, si, dst, di, len)
  end
in
structure IntVector = MonoVectorBase(Operations)
end
