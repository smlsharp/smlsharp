(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: IOrd.sml,v 1.1 2007/09/07 14:19:47 kiyoshiy Exp $
 *)
structure IOrd =
struct 
  type ord_key = int
  val compare = Int.compare
end
