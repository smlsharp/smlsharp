(**
 * parser of SML source code.
 *
 * @author 2001 Lucent Technologies, Bell Labs
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: MLPARSER.sig,v 1.3 2004/10/20 02:50:56 kiyoshiy Exp $
 *)
signature MLPARSER =
sig

  (***************************************************************************)

  (**
   * exception when any error in parse is found.
   *)
  exception ParseError of string

  (***************************************************************************)

  (**
   * parse a SML source file.
   *
   * @params (fileName, stream)
   * @param fileName the name of source file
   * @param stream the source stream of SML code
   * @return a pair of a list of declarations and a function which maps
   *         the character position of its range to its line number and column
   *         position in the line.
   * @exception ParseError if any error occurs in parsing.
   *)
  val parse :
      (string * TextIO.instream) -> (Ast.dec list * (int -> (int * int)))

  val getErrorMessage :
      string -> (int -> (int * int)) -> (string * (int * int)) -> string

  (***************************************************************************)

end
