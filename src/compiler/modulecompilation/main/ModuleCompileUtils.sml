(**
 * Module compiler utilities.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ModuleCompileUtils.sml,v 1.24 2006/03/02 12:46:47 bochao Exp $
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
  structure IA = IndexAllocator
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


  fun genImportPathVarEnv varEnv freeGlobalArrayIndex freeEntryPointer  =
      SEnv.foldli (fn (varName, idState, (freeGlobalArrayIndex, freeEntryPointer, pathVarEnv)) =>
                      case idState of
                        T.VARID {name, strpath, ty} =>
                        let
                          val (newFreeGlobalArrayIndex,
                               newFreeEntryPointer,
                               allocatedIndex) =
                              IA.allocateAbstractIndex freeGlobalArrayIndex freeEntryPointer
                          val newPathVarEnv =
                              SEnv.insert(pathVarEnv,
                                          varName,
                                          PE.TopItem ((strpath, name), allocatedIndex, ty)
                                          )
                        in
                          (newFreeGlobalArrayIndex, newFreeEntryPointer, newPathVarEnv)
                        end
                      | _ => (freeGlobalArrayIndex, freeEntryPointer, pathVarEnv)
                  )
                  (freeGlobalArrayIndex, freeEntryPointer, SEnv.empty)
                  varEnv

  fun genImportPathStrEnv strEnv freeGlobalArrayIndex freeEntryPointer =
      SEnv.foldli (fn (strName, 
                       T.STRUCTURE {env = (tyConEnv, varEnv, strEnv),...}, 
                       (freeGlobalArrayIndex, freeEntryPointer,pathStrEnv)) =>
                      let
                        val (newFreeGlobalArrayIndex1, newFreeEntryPointer1, pathVarEnv) =
                            genImportPathVarEnv varEnv freeGlobalArrayIndex freeEntryPointer
                        val (newFreeGlobalArrayIndex2, newFreeEntryPointer2, pathStrEnv) =
                            genImportPathStrEnv strEnv newFreeGlobalArrayIndex1 newFreeEntryPointer1
                        val pathStrEnv =
                            SEnv.insert (pathStrEnv,
                                         strName,
                                         PE.PATHAUX (pathVarEnv, pathStrEnv))
                      in
                        (
                         newFreeGlobalArrayIndex2,
                         newFreeEntryPointer2, 
                         pathStrEnv)
                      end
                  )
                  (freeGlobalArrayIndex, freeEntryPointer,SEnv.empty)
                  strEnv

  fun genImportPathBasisFromEnv (Env as (tyConEnv, varEnv, strEnv) : T.Env)
                                freeGlobalArrayIndex
                                freeEntryPointer
    =
    let
        val pathFunEnv = SEnv.empty
        val (newFreeGlobalArrayIndex1, newFreeEntryPointer1, pathVarEnv) = 
            genImportPathVarEnv varEnv freeGlobalArrayIndex freeEntryPointer 
        val (newFreeGlobalArrayIndex2, newFreeEntryPointer2, pathStrEnv) =
            genImportPathStrEnv strEnv newFreeGlobalArrayIndex1 newFreeEntryPointer1
        val pathEnv = (pathVarEnv, pathStrEnv)
    in
        (
         newFreeGlobalArrayIndex2,
         newFreeEntryPointer2,
         (pathFunEnv, pathEnv))
    end
end
end
