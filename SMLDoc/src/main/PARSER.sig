(**
 * Parser of ML program which may contain documentation comments.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PARSER.sig,v 1.3 2004/11/07 13:16:19 kiyoshiy Exp $
 *)
signature PARSER =
sig

  (***************************************************************************)

  (** type of context of parsing *)
  type context

  (***************************************************************************)

  (** empty context *)
  val emptyContext : context

  (**
   * add a name of the infix operator into the context.
   * @params (name, context)
   * @param name the name of the infix operator
   * @param context a context
   * @return a new context which includes the name as infix operator.
   *
   * @author YAMATODANI Kiyoshi
   * @version 1.0                                                            
   *)
  val addInfix : (string * context) -> context

  (**
   *  parses a file which contains ML program annotated with documentation
   * comments.
   * @params parameter context fileName
   * @param parameter the global parameter
   * @param context the context
   * @param fileName the name of the file containing ML program.
   * @return a compilation unit which contains abstract syntax tree of the
   *       ML program
   *
   * @author YAMATODANI Kiyoshi
   * @version 1.0                                                            
   *)
  val parseFile :
      DocumentGenerationParameter.parameter ->
      context ->
      string ->
      AnnotatedAst.compileUnit

  (***************************************************************************)

end
