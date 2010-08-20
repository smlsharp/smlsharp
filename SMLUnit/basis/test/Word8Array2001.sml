(**
 * Test case of Word8Array2 structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Word8Array2001 = 
Mutable2DSequence001(struct
                       open Word8Array2
                       type elem = Word8.word
                       type array = array
                       type vector = vector
                       type region = region
                       fun intToElem n = Word8.fromInt n
                       fun nextElem n = n + 0w1 : elem
                       val elemToString = Word8.toString
                       val compareElem = Word8.compare
                       val listToVector = Word8Vector.fromList
                       val vectorToList = Word8Vector.foldr List.:: []
                     end)
