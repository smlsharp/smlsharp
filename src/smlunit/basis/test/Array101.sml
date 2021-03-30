(**
 * Test case of Array structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
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
