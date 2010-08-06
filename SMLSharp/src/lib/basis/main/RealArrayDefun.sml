(**
 * RealArray structure, defunctorized
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @version $Id: RealArray.sml,v 1.5 2008/03/11 08:53:57 katsu Exp $
 *)
local
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
  structure M = MonoArrayUtils
  val B = 
      {maxLen = maxLen,
       makeMutableArray = makeMutableArray,
       makeEmptyMutableArray = makeEmptyMutableArray,
       makeImmutableArray = makeImmutableArray,
       makeEmptyImmutableArray = makeEmptyImmutableArray,
       length = length,
       sub = sub,
       update = update,
       copy = copy}
in
  structure RealArray = 
  struct
    type elem = elem
    type array = array
    type vector = array
    val maxLen = M.maxLen B
    val makeArray = fn x => M.makeArray B x
    val makeVector = fn x => M.makeVector B x
    val makeEmptyArray = fn x => M.makeEmptyArray B x
    val makeEmptyVector = fn x => M.makeEmptyVector B x
    val array = fn x => M.array B x
    val fromList = fn x => M.fromList B x
    val tabulate = fn x => M.tabulate B x
    val length = fn x => M.length B x
    val sub = fn x => M.sub B x   
    val update = fn x => M.update B x
    val copy = fn x => M.copy B x
    val copyVec = fn x => M.copyVec B x
    val vector = fn x => M.vector B x
    val appi = fn x => M.appi B x
    val app = fn x => M.app B x
    val modifyi = fn x => M.modifyi B x
    val modify = fn x => M.modify B x
    val foldli = fn x => M.foldli B x
    val foldri = fn x => M.foldri B x
    val foldl = fn x => M.foldl B x
    val foldr = fn x => M.foldr B x
    val findi = fn x => M.findi B x
    val find = fn x => M.find B x
    val exists = fn x => M.exists B x
    val all = fn x => M.all B x
    val collate = fn x => M.collate B x
  end
end;
