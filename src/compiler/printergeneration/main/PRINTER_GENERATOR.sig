(**
 * generates printer code and formatter definition.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: PRINTER_GENERATOR.sig,v 1.11 2006/03/24 13:57:54 kiyoshiy Exp $
 *)
signature PRINTER_GENERATOR =
sig

  (***************************************************************************)

  (**
   * generates formatter function binding.
   *  This function traverses whole declarations and their bound
   * expressions one time, generates formatter function declrations
   * for each type/datatype declaration, and insert those formatter
   * declarations just after the type/datatype declaration.
   *
   * @params {context, newContext, printBinds, declarations}
   * @param context
   * @param newContext
   * @param printBinds true if binding informations should be printed.
   * @param declarations list of top level declarations
   * @return declarations extended with generated formatters and printing code,
   *        and a context which is sum of newContext and every formatters
   *        generated.
   *)
  val generate :
      {
        context : InitialTypeContext.topTypeContext,
        newContext : TypeContext.context,
        printBinds : bool,
        declarations : TypedCalc.tptopdecl list
      }
      -> TypeContext.context * TypedCalc.tptopdecl list

  val generateForSeparateCompile :
      {
        newTypeEnv : StaticTypeEnv.staticTypeEnv,
        printBinds : bool,
        declarations : TypedCalc.tptopdecl list
      }
      -> StaticTypeEnv.staticTypeEnv * TypedCalc.tptopdecl list

  (***************************************************************************)

end
