(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Module compiler flattens structure.
 *
 * @author Liu Bochao
 * @version $Id: MODULECOMPILER.sig,v 1.10 2006/02/18 11:06:33 duchuu Exp $
 *)
signature MODULECOMPILER =
sig

  (***************************************************************************)
  type moduleEnv
  type deltaModuleEnv 
  (***************************************************************************)
  val extendModuleEnvWithDeltaModuleEnv :
      {deltaModuleEnv : deltaModuleEnv,
       moduleEnv : moduleEnv} -> moduleEnv

  val modulecompile :
      moduleEnv ->
      TypedCalc.tptopdecl list -> 
      (deltaModuleEnv * TypedFlatCalc.tfpdecl list)

  (***************************************************************************)

end
