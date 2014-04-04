(**
 * Test case of CharVectorSlice structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure CharVectorSlice001 = 
ImmutableSequenceSlice001(struct
                            open CharVectorSlice
                            type elem = char
                            type sequence = vector
                            type slice = slice
                            type vector = vector
                            fun intToElem n = Char.chr (Char.ord #"A" + n)
                            fun nextElem c = Char.chr (Char.ord c + 1)
                            val elemToString = Char.toString
                            val compareElem = Char.compare
                            val listToSequence = CharVector.fromList
                            val sequenceToList =
                                CharVector.foldr List.:: ([] : elem list)
                            val vectorToList = sequenceToList
                            val listToVector = listToSequence
                          end)
