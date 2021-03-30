(**
 * Test case of CharArray structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure CharArray001 = 
MutableSequence001(struct
                     open CharArray
                     type elem = Char.char
                     type sequence = array
                     fun intToElem n = Char.chr (Char.ord #"A" + n)
                     fun nextElem c = Char.chr (Char.ord c + 1)
                     val elemToString = Char.toString
                     val compareElem = Char.compare
                     val listToVector = CharVector.fromList
                     val vectorToList = CharVector.foldr List.:: []
                   end)
