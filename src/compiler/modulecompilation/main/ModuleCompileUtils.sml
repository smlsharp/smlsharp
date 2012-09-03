(**
 * Module compiler utilities.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ModuleCompileUtils.sml,v 1.29 2007/01/21 13:41:32 kiyoshiy Exp $
 *)
structure ModuleCompileUtils =
struct
local
  structure T  = Types
  structure P = Path
  structure TO = TopObject
  structure PE = PathEnv
  structure MC = ModuleContext
  structure IA = IndexAllocator
  structure STE = StaticTypeEnv
  structure SME = StaticModuleEnv
  open TypedCalc TypedFlatCalc 
in
  fun debug_sigVarEnvToString sigVE indent =
      SEnv.foldli (fn (k,_, string) =>
                      string ^ indent ^ (k^"=>") ^"(...)\n"
                      )
                  ""
                  sigVE
  and debug_sigStrEnvToString (T.STRUCTURE sigSECont) indent =
      SEnv.foldli (fn (k, {env = (_, subSigVE, subSigSE),...}, string) =>
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
                  sigSECont

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

  fun filterPathSE pathSE (T.STRUCTURE sigSECont) =
      SEnv.foldli
      ( fn (k, PE.PATHAUX (subPathVE,subPathSE), newPathSE) => 
           case SEnv.find(sigSECont,k) of
             SOME {env=(_, subSigVE, subSigSE),...} =>
             let
               val newSubPathVE = filterPathVE subPathVE subSigVE
               val newSubPathSE = filterPathSE subPathSE subSigSE
             in
               SEnv.insert(newPathSE,
                           k,
                           PE.PATHAUX (newSubPathVE, newSubPathSE))
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


  fun filterStaticModuleEnv (staticModuleEnv : SME.staticModuleEnv,
                             staticTypeEnv : STE.staticTypeEnv)
                             
    =
    let
        val exportTypeEnv = #exportTypeEnv staticTypeEnv
        val (exportPathFunEnv, exportPathEnv) = #exportModuleEnv staticModuleEnv
        val newExportPathEnv = filterPathEnv(exportPathEnv, STE.typeEnvToEnv exportTypeEnv)
    in
        SME.injectExportModuleEnvInStaticModuleEnv ((exportPathFunEnv, newExportPathEnv),
                                                    staticModuleEnv)
    end
        
  fun genImportPathVarEnv varEnv freeEntryPointer  =
      SEnv.foldli (fn (varName, idState, (freeEntryPointer, pathVarEnv)) =>
                      case idState of
                        T.VARID {name, strpath, ty} =>
                        let
                          val (newFreeEntryPointer,
                               allocatedIndex) =
                              IA.allocateAbstractIndex freeEntryPointer
                          val newPathVarEnv =
                              SEnv.insert(pathVarEnv,
                                          varName,
                                          PE.TopItem ((strpath, name), allocatedIndex, ty)
                                          )
                        in
                            (newFreeEntryPointer, newPathVarEnv)
                        end
                      | _ => (freeEntryPointer, pathVarEnv)
                  )
                  (freeEntryPointer, SEnv.empty)
                  varEnv

  fun genImportPathStrEnv (T.STRUCTURE strEnvCont) freeEntryPointer =
      SEnv.foldli (fn (strName, 
                       {env = (tyConEnv, varEnv, strEnv),...}, 
                       (freeEntryPointer,incPathStrEnv)) =>
                      let
                          val (newFreeEntryPointer1, pathVarEnv) =
                              genImportPathVarEnv varEnv freeEntryPointer
                          val (newFreeEntryPointer2, pathStrEnv) =
                              genImportPathStrEnv strEnv newFreeEntryPointer1
                      in
                          (newFreeEntryPointer2, 
                           SEnv.insert (incPathStrEnv,
                                        strName,
                                        PE.PATHAUX (pathVarEnv, pathStrEnv)))
                      end
                  )
                  (freeEntryPointer,SEnv.empty)
                  strEnvCont

  fun genImportPathBasisFromEnv (Env as (tyConEnv, varEnv, strEnv) : T.Env)
                                freeEntryPointer
    =
    let
        val pathFunEnv = SEnv.empty
        val (newFreeEntryPointer1, pathVarEnv) = 
            genImportPathVarEnv varEnv freeEntryPointer 
        val (newFreeEntryPointer2, pathStrEnv) =
            genImportPathStrEnv strEnv newFreeEntryPointer1
        val pathEnv = (pathVarEnv, pathStrEnv)
    in
        (newFreeEntryPointer2, (pathFunEnv, pathEnv))
    end
end
end
 
