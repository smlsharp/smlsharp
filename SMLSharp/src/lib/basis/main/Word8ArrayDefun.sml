(**
 * Word8Array structure, defunctorized.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Word8Array.sml,v 1.5 2007/12/19 02:00:56 kiyoshiy Exp $
 *)
local
    type elem = Word8.word
    type array = CharArray.array
    val maxLen = CharArray.maxLen
    val makeMutableArray =
        fn (size, initial) =>
           CharArray.array (size, Char.chr(Word8.toInt initial))
    val makeEmptyMutableArray = fn () => CharArray.fromList []
    val makeImmutableArray =
        fn (size, initial) =>
           CharArray.array (size, Char.chr(Word8.toInt initial))
    val makeEmptyImmutableArray = fn () => CharArray.fromList []
    val length = CharArray.length
    val update =
        fn (vector, index, byte) =>
           CharArray.update (vector, index, Char.chr(Word8.toInt byte))
    val copy = CharArray.copySlice
    val sub =
        fn (vector, index) =>
           Word8.fromInt(Char.ord(CharArray.sub (vector, index)))
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
  structure Word8Array = 
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
