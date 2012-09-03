(*
 * @author Atsushi Ohori
 * @copyright 2010, Tohoku University.
 *)
structure IntVector =
struct
local
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
  val B = 
      {maxLen = maxLen,
       makeVector =makeVector,
       makeEmptyVector =makeEmptyVector,
       length = length,
       sub = sub,
       update = update,
       copy  = copy}
  structure M = MonoVectorUtils

in
  type elem = elem
  type vector = vector
  type slice = vector * int * int
  val maxLen = M.maxLen B
  val makeVector = fn x => M.makeVector B x
  val fromList = fn x => M.fromList B x
  val tabulate = fn x => M.tabulate B x
  val length = fn x => M.length B x
  val sub = fn x => M.sub B x
  val foldli = fn x => M.foldli B x
  val foldl = fn x => M.foldl B x
  val foldri = fn x => M.foldri B x
  val foldr = fn x => M.foldr B x
  val mapi = fn x => M.mapi B x
  val map = fn x => M.map B x
  val appi = fn x => M.appi B x
  val app = fn x => M.app B x
  val update = fn x => M.update B x
  val copy = fn x => M.copy B x
  val concatSlices = fn x => M.concatSlices B x
  val concat = fn x => M.concat B x
  val findi = fn x => M.findi B x 
  val find = fn x => M.find B x
  val exists = fn x => M.exists B x
  val all = fn x => M.all B x
  val collate = fn x => M.collate B x
end
end
