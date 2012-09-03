(**
 * Test case of CharArray2 structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure CharArray2001 = 
Mutable2DSequence001(struct
                       open CharArray2
                       type elem = Char.char
                       type array = array
                       type vector = vector
                       type region = region
                       fun intToElem n = Char.chr n
                       fun nextElem n = Char.chr(Char.ord n + 1)
                       val elemToString = Char.toString
                       val compareElem = Char.compare
                       val listToVector = CharVector.fromList
                       val vectorToList = CharVector.foldr List.:: []
                     end)
