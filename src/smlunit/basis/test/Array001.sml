(**
 * Test case of Array structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Array001 = 
MutableSequence001(struct
                     open Array
                     type elem = int
                     type sequence = int array
                     type array = int array
                     type vector = int vector
                     fun intToElem n = n
                     fun nextElem n = n + 1
                     val elemToString = Int.toString
                     val compareElem = Int.compare
                     val listToVector = Vector.fromList
                     val vectorToList = Vector.foldr List.:: ([] : int list)
                   end)