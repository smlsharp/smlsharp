(**
 * Test case of ArraySlice structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure ArraySlice001 = 
MutableSequenceSlice001(struct
                          open ArraySlice
                          type elem = int
                          type sequence = int array
                          type slice = int slice
                          type vector = int vector
                          type vector_slice = int VectorSlice.slice
                          fun intToElem n = n
                          fun nextElem n = n + 1
                          val elemToString = Int.toString
                          val compareElem = Int.compare
                          val listToSequence = Array.fromList
                          val sequenceToList =
                              Array.foldr List.:: ([] : elem list)
                          val vectorToList =
                              Vector.foldr List.:: ([] : elem list)
                          val listToVector = Vector.fromList 
                          val sliceVec = VectorSlice.slice
                        end)
