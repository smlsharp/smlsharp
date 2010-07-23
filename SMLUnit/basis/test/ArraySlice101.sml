(**
 * Test case of ArraySlice structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure ArraySlice101 = 
SequenceSlice101(struct
                   open ArraySlice
                   type elem = int
                   type sequence = int array
                   type slice = int slice
                   type vector = int vector
                   fun intToElem n = n
                   fun nextElem n = n + 1
                   val elemToString = Int.toString
                   val compareElem = Int.compare
                   val listToSequence = Array.fromList
                   val sequenceToList = Array.foldr List.:: ([] : elem list)
                   val vectorToList = Vector.foldr List.:: ([] : elem list)
                   val listToVector = Vector.fromList
                 end)
