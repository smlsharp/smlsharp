(**
 * Word8Vector structure, defunctorized.
 * @author Atsushi Ohori
 * @copyright 2010, Tohoku University.
 * @version $Id: Word8Vector.sml,v 1.6 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
local
  (* ToDo : use primitives for bytearray. *)
    type elem = Word8.word
    type vector = CharVector.vector
    val maxLen = CharVector.maxLen
    val makeVector =
        fn (size, initial) =>
           SMLSharp.PrimString.vector (size, Char.chr(Word8.toInt initial))
    val makeEmptyVector = fn () => CharVector.fromList []
    val length = CharVector.length
    val update =
        fn (vector, index, byte) =>
           CharArray.update (vector, index, Char.chr(Word8.toInt byte))
    val copy = CharVector.copy
    val sub =
        fn (vector, index) =>
           Word8.fromInt(Char.ord(CharVector.sub (vector, index)))
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
  structure Word8Vector = struct
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
end;
