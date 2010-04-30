(**
 * generates printer code and formatter definition.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: PRINTER_GENERATOR.sig,v 1.19 2008/08/04 13:25:37 bochao Exp $
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
   * @params {nameMap, context, newContext, printBinds, declarations}
   * @param nameMap
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
        stamps : Counters.stamps,
        newContext : TypeContext.context,
        flattenedNamePathEnv:NameMap.basicNameNPEnv,
        printBinds : bool,
        declarations : TypedCalc.tptopdecl list
      }
      -> TypeContext.context * NameMap.basicNameNPEnv * Counters.stamps * TypedCalc.tptopdecl list

end
