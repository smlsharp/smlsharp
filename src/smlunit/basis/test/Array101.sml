(**
 * Test case of Array structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Array101 = 
Sequence101(struct
              open Array
              type elem = int
              type sequence = int array
              fun intToElem n = n
              fun nextElem n = n + 1
              val elemToString = Int.toString
              val compareElem = Int.compare
            end)
