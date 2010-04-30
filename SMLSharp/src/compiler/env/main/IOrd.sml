(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: IOrd.sml,v 1.1 2007/09/07 14:19:47 kiyoshiy Exp $
 *)
structure IOrd : ORD_KEY =
struct 
  type ord_key = int
  val compare = Int.compare
end
