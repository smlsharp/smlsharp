(**
 * Test case of CharArraySlice structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure CharArraySlice101 = 
SequenceSlice101(struct
                   open CharArraySlice
                   type elem = char
                   type sequence = array
                   type slice = slice
                   type vector = vector
                   fun intToElem n = Char.chr (Char.ord #"A" + n)
                   fun nextElem c = Char.chr (Char.ord c + 1)
                   val elemToString = Char.toString
                   val compareElem = Char.compare
                   val listToSequence = CharArray.fromList
                   val sequenceToList =
                       CharArray.foldr List.:: ([] : elem list)
                   val vectorToList = CharVector.foldr List.:: ([] : elem list)
                   val listToVector = CharVector.fromList
                 end)
