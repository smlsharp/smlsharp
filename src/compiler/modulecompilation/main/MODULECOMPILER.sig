(**
 *
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: MODULECOMPILER.sig,v 1.13 2006/03/14 01:39:13 bochao Exp $
 *)
signature MODULECOMPILER =
sig

  (***************************************************************************)
  (* interactive mode *)
  val moduleCompile :
      StaticModuleEnv.moduleEnv ->
      TypedCalc.tptopdecl list -> 
      (StaticModuleEnv.deltaModuleEnv * TypedFlatCalc.tfpdecl list)

  (* linking *)
  val moduleCompileCodeFragmentWithPathBasis :
      StaticModuleEnv.deltaModuleEnv ->
      TypedCalc.tpmstrdecl list -> 
      (StaticModuleEnv.deltaModuleEnv * TypedFlatCalc.tfpdecl list)
  val compileLinkageUnit :
      TypedCalc.tptopdecl list -> 
      (StaticModuleEnv.staticModuleEnv * TypedFlatCalc.tfpdecl list)
  (***************************************************************************)

end
