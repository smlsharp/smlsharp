(**
 * fixity of operator.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: Fixity.sml,v 1.1 2008/08/06 07:37:49 ohori Exp $
 *)
structure Fixity =
struct

  (***************************************************************************)

  datatype fixity = INFIX of int | INFIXR of int | NONFIX
  fun fixityToString fixity =
      case fixity of
         INFIX n => "infix " ^ (Int.toString n)
       | INFIXR n => "infixr " ^ (Int.toString n)
       | NONFIX => "nonfix"

  (***************************************************************************)

end
