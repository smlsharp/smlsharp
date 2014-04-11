(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: SOrd.sml,v 1.1 2007/09/07 14:19:47 kiyoshiy Exp $
 *)
structure LabelOrd =
struct 
  type ord_key = string
  fun compare (x,y) =
      case (Int.fromString x, Int.fromString y) of
        (SOME i, SOME j) =>
        (case Int.compare (i, j) of
           EQUAL => String.compare (x, y)
         | order => order)
      | _ => String.compare (x, y)
end
