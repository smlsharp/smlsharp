(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: SOrd.sml,v 1.1 2007/09/07 14:19:47 kiyoshiy Exp $
 *)
structure SOrd : ORD_KEY =
struct 
  type ord_key = string
  fun compare (x,y) = 
      let val (a,b) = (valOf(Int.fromString x),valOf(Int.fromString y))
      in Int.compare (a,b)
      end
        handle Option => String.compare (x,y)
end
