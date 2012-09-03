(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: WOrd.sml,v 1.1 2007/11/13 03:50:53 katsu Exp $
 *)
structure WOrd : ORD_KEY =
struct 
  type ord_key = word
  val compare = Word.compare
end
