(**
 * Test case of Word8Array structure.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Word8Array101 = 
Sequence101(struct
              open Word8Array
              type elem = Word8.word
              type sequence = array
              fun intToElem n = Word8.fromInt n
              fun nextElem (b : elem) = b + 0w1
              val elemToString = Word8.toString
              val compareElem = Word8.compare
            end)
