(**
 * Test case of Vector structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure Vector101 = 
Sequence101(struct
              open Vector
              type elem = int
              type sequence = int vector
              fun intToElem n = n
              fun nextElem n = n + 1
              val elemToString = Int.toString
              val compareElem = Int.compare
            end)
