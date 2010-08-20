(**
 * IntVectorSlice structure, defunctoried.
 * @author Atsushi Ohori
 * @copyright (c) 2010, Tohoku University.
 *)
structure IntVectorSlice = 
struct
local
  structure IV = IntVector
  val B = 
      {fromList = IV. fromList,
       length = IV.length,
       sub = IV.sub,
       collate = IV.collate,
       concatSlices = IV.concatSlices
       }
  structure M = MonoVectorSliceUtils
in
  type elem = IV.elem
  type vector = IV.vector
  type slice = IV.vector * int * int
    val length = fn x => M.length B x 
    val sub = fn x => M.sub B x 
    val full = fn x => M.full B x 
    val slice = fn x => M.slice B x 
    val subslice = fn x => M.subslice B x 
    val base = fn x => M.base B x 
    val foldli = fn x => M.foldli B x 
    val foldri = fn x => M.foldri B x 
    val foldl = fn x => M.foldl B x 
    val foldr = fn x => M.foldr B x 
    val mapi = fn x => M.mapi B x 
    val map = fn x => M.map B x 
    val appi = fn x => M.appi B x 
    val app = fn x => M.app B x 
    val vector = fn x => M.vector B x 
    val concat = fn x => M.concat B x 
    val isEmpty = fn x => M.isEmpty B x 
    val getItem = fn x => M.getItem B x 
    val findi = fn x => M.findi B x 
    val find = fn x => M.find B x 
    val exists = fn x => M.exists B x 
    val all = fn x => M.all B x 
    val collate = fn x => M.collate B x
end
end
