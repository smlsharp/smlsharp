(**
 *  This module analyses dependency relation between the compilation units
 * the parser generated.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: DEPENDENCY_ANALYZER.sig,v 1.2 2004/10/20 03:18:39 kiyoshiy Exp $
 *)
signature DEPENDENCY_ANALYZER =
sig

  (***************************************************************************)

  (**
   * sort a list of compilation units on dependency relation.
   * <p>
   *  If any module in the compilation unit A depends on some module in
   * the other compilation unit B, the B precedes the A in the returned list.
   * </p>
   * @params parameter units
   * @param parameter global parameter
   * @param units compilation unit to be sorted
   * @return sorted compilation unit
   * @author YAMATODANI Kiyoshi
   * @version 1.0
   *)
  val sort :
      DocumentGenerationParameter.parameter ->
      AnnotatedAst.compileUnit list ->
      (** sorted list. depended module comes first before depending module.*)
      AnnotatedAst.compileUnit list

  (***************************************************************************)

end