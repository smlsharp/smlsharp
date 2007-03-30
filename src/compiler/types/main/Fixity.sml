(**
 * fixity of operator.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: Fixity.sml,v 1.2 2007/02/14 15:04:54 kiyoshiy Exp $
 *)
structure Fixity =
struct

  (***************************************************************************)

  datatype fixity = INFIX of int | INFIXR of int | NONFIX

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

end;