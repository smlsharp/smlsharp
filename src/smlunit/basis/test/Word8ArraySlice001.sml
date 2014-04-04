(**
 * Test case of Word8ArraySlice structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Word8ArraySlice001 = 
MutableSequenceSlice001(struct
                          open Word8ArraySlice
                          type elem = Word8.word
                          type sequence = array
                          type slice = slice
                          type vector = vector
                          type vector_slice = Word8VectorSlice.slice
                          fun intToElem n = Word8.fromInt n
                          fun nextElem (b : elem) = b + 0w1
                          val elemToString = Word8.toString
                          val compareElem = Word8.compare
                          val listToSequence = Word8Array.fromList
                          val sequenceToList =
                              Word8Array.foldr List.:: ([] : elem list)
                          val vectorToList =
                              Word8Vector.foldr List.:: ([] : elem list)
                          val listToVector = Word8Vector.fromList 
                          val sliceVec = Word8VectorSlice.slice
                        end)
