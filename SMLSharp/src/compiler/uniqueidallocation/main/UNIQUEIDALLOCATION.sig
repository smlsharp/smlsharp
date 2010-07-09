(**
 *
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: UNIQUEIDALLOCATION.sig,v 1.16 2008/08/04 13:25:37 bochao Exp $
 *)
signature UNIQUEIDALLOCATION =
sig

  (***************************************************************************)
  (* interactive mode *)
  val allocateID :
      VarIDContext.topExternalVarIDBasis ->
      NameMap.varNameNPEnv -> 
      TypedCalc.tptopdecl list -> 
      (VarIDContext.topExternalVarIDBasis *
       TypedFlatCalc.topBlock list)
end
