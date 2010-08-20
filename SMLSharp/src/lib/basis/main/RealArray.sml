(**
 * RealArray structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: RealArray.sml,v 1.5 2008/03/11 08:53:57 katsu Exp $
 *)
local
  structure Operations =
  struct
    type elem = real
    type array = elem array
    val maxLen = Vector.maxLen
    fun makeMutableArray (intSize, initial) =
        SMLSharp.PrimArray.array(intSize, initial)
    fun makeEmptyMutableArray _ =
        _cast (SMLSharp.PrimArray.array(0, 0.0)) : array
    fun makeImmutableArray (intSize, initial) =
        SMLSharp.PrimArray.vector(intSize, initial)
    fun makeEmptyImmutableArray _ =
        _cast (SMLSharp.PrimArray.vector(0, 0.0)) : array
    fun length array = SMLSharp.PrimArray.length array
    fun sub (array, intIndex) = SMLSharp.PrimArray.sub_unsafe (array, intIndex)
    fun update (array, intIndex, value) =
        SMLSharp.PrimArray.update_unsafe (array, intIndex, value)
    fun copy {src, si, dst, di, len} =
        SMLSharp.PrimArray.copy_unsafe (src, si, dst, di, len)
  end
in
structure RealArray = MonoArrayBase(Operations)
end;
