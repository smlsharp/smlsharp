(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Module compiler flattens structure.
 * @author Liu Bochao
 * @version $Id: ModuleCompileUtils.sml,v 1.22 2006/02/18 04:59:23 ohori Exp $
 *)
structure ModuleCompileUtils =
struct
local
  structure T  = Types
  structure P = Path
  structure TO = TopObject
  structure TU = TypesUtils
  structure SE = StaticEnv
  structure PE = PathEnv
  structure MC = ModuleContext
  open TypedCalc TypedFlatCalc 
in
  fun debug_sigVarEnvToString sigVE indent =
      SEnv.foldli (fn (k,_, string) =>
                      string ^ indent ^ (k^"=>") ^"(...)\n"
                      )
                  ""
                  sigVE
  and debug_sigStrEnvToString sigSE indent =
      SEnv.foldli (fn (k, T.STRUCTURE {env = (_, subSigVE, subSigSE),...}, string) =>
                      let
                        val strName = (indent^ k ^ ":" ^"\n") 
                        val indent = indent ^ "   "
                        val varString = debug_sigVarEnvToString subSigVE indent
                        val strString = debug_sigStrEnvToString subSigSE indent
                      in
                        string ^ strName ^ varString ^ strString
                      end
                        )
                  ""
                  sigSE

  fun sigEnvToString (sigEnv as (sigTE, sigVE, sigSE)) =
      let
        val indent = ""
        val varString = debug_sigVarEnvToString sigVE indent
        val strString = debug_sigStrEnvToString sigSE indent
      in
        varString ^ strString
      end


  fun filterPathVE pathVE sigVE =
      SEnv.filteri (fn (k,v) => SEnv.inDomain(sigVE,k)) pathVE

  fun filterPathSE pathSE sigSE =
      SEnv.foldli
      ( fn (k, PE.PATHAUX (subPathVE,subPathSE), newPathSE) => 
           case SEnv.find(sigSE,k) of
             SOME (T.STRUCTURE {env=(_, subSigVE, subSigSE),...}) =>
             let
               val newSubPathVE = filterPathVE subPathVE subSigVE
               val newSubPathSE = filterPathSE subPathSE subSigSE
             in
               SEnv.insert(
                           newPathSE,
                           k,
                           PE.PATHAUX (newSubPathVE, newSubPathSE)
                           )
             end
           | NONE => newPathSE)
      SEnv.empty
      pathSE

  fun filterPathEnv (pathEnv as (pathVE,pathSE), sigEnv as (_, sigVE, sigSE)) =
      let
        val newPathVE = filterPathVE pathVE sigVE
        val newPathSE = filterPathSE pathSE sigSE
      in
        (newPathVE,newPathSE)
      end
            
end
end
