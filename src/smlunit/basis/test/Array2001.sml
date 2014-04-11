(**
 * Test case of Array2 structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Array2001 = 
Mutable2DSequence001(struct
                       open Array2
                       type elem = int
                       type array = int array
                       type vector = int vector
                       type region = int region
                       fun intToElem n = n
                       fun nextElem n = n + 1
                       val elemToString = Int.toString
                       val compareElem = Int.compare
                       val listToVector = Vector.fromList
                       val vectorToList = Vector.foldr List.:: ([] : int list)
                     end)
