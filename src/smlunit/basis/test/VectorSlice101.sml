(**
 * Test case of VectorSlice structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure VectorSlice101 = 
SequenceSlice101(struct
                   open VectorSlice
                   type elem = int
                   type sequence = int vector
                   type slice = int slice
                   type vector = int vector
                   fun intToElem n = n
                   fun nextElem n = n + 1
                   val elemToString = Int.toString
                   val compareElem = Int.compare
                   val listToSequence = Vector.fromList
                   val sequenceToList = Vector.foldr List.:: ([] : elem list)
                   val vectorToList = sequenceToList
                   val listToVector = listToSequence
                 end)
