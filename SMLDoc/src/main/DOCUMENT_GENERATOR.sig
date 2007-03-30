(**
 *  The signature of modules which generates documents describing the given
 * program.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: DOCUMENT_GENERATOR.sig,v 1.3 2004/11/06 16:15:02 kiyoshiy Exp $
 *)
signature DOCUMENT_GENERATOR =
sig

  (***************************************************************************)

  (**
   * generates document describing the given program.
   * @params parameter compileUnits
   * @param parameter parameters which control the behavior and output of the
   *                  generator.
   * @param compileUnits compile unit list
   * @return unit
   *)
  val generateDocument :
      DocumentGenerationParameter.parameter
      -> ElaboratedAst.compileUnit list
      -> unit

  (***************************************************************************)

end