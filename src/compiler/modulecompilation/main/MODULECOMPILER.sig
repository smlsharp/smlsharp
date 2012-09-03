(**
 *
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: MODULECOMPILER.sig,v 1.12 2006/03/02 12:46:47 bochao Exp $
 *)
signature MODULECOMPILER =
sig

  (***************************************************************************)
  (* interactive mode *)
  val moduleCompile :
      StaticModuleEnv.moduleEnv ->
      TypedCalc.tptopdecl list -> 
      (StaticModuleEnv.deltaModuleEnv * TypedFlatCalc.tfpdecl list)

  val compileLinkageUnit :
      TypedCalc.tptopdecl list -> 
      (StaticModuleEnv.staticModuleEnv * TypedFlatCalc.tfpdecl list)
  (***************************************************************************)

end
