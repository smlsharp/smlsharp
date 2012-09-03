(**
 * RealVector structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RealVector.sml,v 1.2 2006/02/20 01:41:12 kiyoshiy Exp $
 *)
local
  structure Operations =
  struct
    type elem = real
    type array = real Array.array
    val maxLen = Array.maxLen
    val makeArray = fn (size, initial) => Array.array(size, initial)
    val length = Array.length
    val update = Array.update
    val sub = Array.sub
    val emptyArray = fn () => Array.array (0, 0.0)
  end
in
structure RealVector = MonoVectorBase(Operations)
end;
