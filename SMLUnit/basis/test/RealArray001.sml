(**
 * Test case of RealArray structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure RealArray001 = 
MutableSequence001(struct
                     open RealArray
                     type elem = Real.real
                     type sequence = array
                     fun intToElem n = Real.fromInt n
                     fun nextElem (b : elem) = b + 1.0
                     val elemToString = Real.toString
                     val compareElem = Real.compare
                     val listToVector = RealVector.fromList
                     val vectorToList = RealVector.foldr List.:: []
                   end)
