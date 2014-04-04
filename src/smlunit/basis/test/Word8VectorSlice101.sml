(**
 * Test case of Word8VectorSlice structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Word8VectorSlice101 = 
SequenceSlice101(struct
                   open Word8VectorSlice
                   type elem = Word8.word
                   type sequence = vector
                   type slice = slice
                   type vector = vector
                   fun intToElem n = Word8.fromInt n
                   fun nextElem (b : elem) = b + 0w1
                   val elemToString = Word8.toString
                   val compareElem = Word8.compare
                   val listToSequence = Word8Vector.fromList
                   val sequenceToList =
                       Word8Vector.foldr List.:: ([] : elem list)
                   val vectorToList = sequenceToList
                   val listToVector = listToSequence
                 end)
