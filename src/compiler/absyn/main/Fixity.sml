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

  (*
   * see
   *  "Appendix C: The Initial Static Basis" and "Appendix E: Overloading"
   *)
  val initialFixEnv =
      foldr
          (fn ((x, fix), fEnv) =>SEnv.insert(fEnv, x, fix))
          SEnv.empty
          [
            ("div", INFIX 7),
            ("mod", INFIX 7),
            ("*", INFIX 7),
            ("/", INFIX 7),
            ("+", INFIX 6),
            ("-", INFIX 6),
            ("::", INFIXR 5),
            ("=", INFIX 4),
            ("<", INFIX 4),
            (">", INFIX 4),
            ("<=", INFIX 4),
            (">=", INFIX 4),
            (":=", INFIX 3)
          ]

  (***************************************************************************)

end
