(**
 * IntVector structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: IntVector.sml,v 1.6 2006/02/20 01:41:11 kiyoshiy Exp $
 *)
local
  structure Operations =
  struct
    type elem = int
    type array = int Array.array
    val maxLen = Array.maxLen
    val makeArray = fn (size, initial) => Array.array(size, initial)
    val length = Array.length
    val update = Array.update
    val sub = Array.sub
    val emptyArray = fn () => Array.array (0, 0)
  end
in
structure IntVector = MonoVectorBase(Operations)
end;
