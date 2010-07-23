(**
 * Test case of CharVector structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure CharVector001 = 
ImmutableSequence001(struct
                       open CharVector
                       type elem = Char.char
                       type sequence = vector
                       fun intToElem n = Char.chr (Char.ord #"A" + n)
                       fun nextElem c = Char.chr (Char.ord c + 1)
                       val elemToString = Char.toString
                       val compareElem = Char.compare
                     end)
