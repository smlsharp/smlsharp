(**
 * Test case of RealArray structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
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
