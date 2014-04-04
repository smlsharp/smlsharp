(**
 * Test case of CharArray structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure CharArray101 = 
Sequence101(struct
              open CharArray
              type elem = Char.char
              type sequence = array
              fun intToElem n = Char.chr (Char.ord #"A" + n);
              fun nextElem c = Char.chr (Char.ord c + 1)
              val elemToString = Char.toString
              val compareElem = Char.compare
            end)
