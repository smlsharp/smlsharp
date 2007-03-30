(**
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ModuleCompileMod.sml,v 1.56 2007/01/21 13:41:32 kiyoshiy Exp $
 *)
structure ModuleCompileMod  = 
struct
local

  structure T  = Types
  structure P = Path
  structure TO = TopObject
  structure FAU = FunctorApplyUtils
  structure MCC = ModuleCompileCore
  structure MCFA = ModuleCompileFunctorApp            
  structure PE = PathEnv
  structure MCU = ModuleCompileUtils
  structure IA = IndexAllocator
  structure MC = ModuleContext
  structure TFC = TypedFlatCalc 
  open TypedCalc 

  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")
  fun typeToString ty = TypeFormatter.tyToString ty
                        
  datatype decGroup = 
           STRDEC of tpmstrdecl list
         | FUNDEC of (funBindInfo  * string * tpmsigexp  * tpmstrexp) list
         | IMPORTDEC of (tpmspec * T.Env) list
in

   fun makeArgVarMap (sigVarEnv:PE.pathVarEnv, strVarEnv:PE.pathVarEnv) loc =
        SEnv.foldli ( 
                     fn (vName, PE.CurItem (holePath, holeId, _, _), newPathHoleIdEnv) =>
                        let
                          val item = 
                              case SEnv.find(strVarEnv, vName) of
                                NONE => 
                                raise Control.BugWithLoc 
                                        (("makeArgVarMap:functor application failed : variable " 
                                          ^ vName ^ " undefined"),
                                         loc)
                              | SOME item => item
                        in
                          ID.Map.insert(newPathHoleIdEnv, holeId, item)
                        end
                      | (_, PE.TopItem _ , _) => 
                        raise Control.BugWithLoc ("signature constains TopItem",loc)
                    )
                    PE.emptyPathHoleIdEnv
                    sigVarEnv

   and makeArgStrMap (sigStrEnv , strStrEnv) loc =
        SEnv.foldli (
                     fn (strName, PE.PATHAUX(argPathVarEnv,argPathStrEnv), newPathHoleIdEnv) =>
                        let
                          val (actPathVarEnv,actPathStrEnv) =
                              case SEnv.find(strStrEnv, strName) of
                                NONE => 
                                raise Control.Bug ("functor application failed : structue "^
                                                   strName ^ " undefined")
                              | SOME (PE.PATHAUX env) => env
                          val pathHoleIdEnv1 = 
                              makeArgVarMap (argPathVarEnv, actPathVarEnv) loc
                          val pathHoleIdEnv2 = 
                              makeArgStrMap (argPathStrEnv, actPathStrEnv) loc
                        in
                          PE.mergePathHoleIdEnv
                            (
                             PE.mergePathHoleIdEnv
                               (pathHoleIdEnv1, pathHoleIdEnv2),
                             newPathHoleIdEnv
                            )
                        end
                    )
                    PE.emptyPathHoleIdEnv
                    sigStrEnv
                            
   and tpmstrexpToTfpdecs context tpmstrexp =
       case tpmstrexp of
         TPMSTRUCT (tpmstrdecs, _) => tpmstrdecsToTfpdecs context tpmstrdecs
       | TPMLONGSTRID ({id, name, strpath, env=env}, loc) =>
         let
           val path = Path.appendPath(strpath, id, name)
           val pathEnv = 
               case MC.lookupStructureInContext (context, path) of
                 SOME pathEnv => pathEnv
               | NONE => raise Control.BugWithLoc ("undefined structure:"^P.pathToString(path),loc)
         in
           (pathEnv , nil)
         end
       | TPMOPAQCONS (tpmstrexp, tpmsigexp, sigEnv, loc) => 
         let
           val (newPathEnv, newTfpdecs) =
               tpmstrexpToTfpdecs context tpmstrexp 
           val filteredPathEnv = MCU.filterPathEnv (newPathEnv, sigEnv)
         in
           (filteredPathEnv, newTfpdecs)
         end
       | TPMTRANCONS (tpmstrexp, tpmsigexp, sigEnv, loc) => 
         let
           val (newPathEnv, newTfpdecs) =
               tpmstrexpToTfpdecs context tpmstrexp 
           val filteredPathEnv = MCU.filterPathEnv (newPathEnv, sigEnv)
         in
           (filteredPathEnv, newTfpdecs)
         end
       | TPMFUNCTORAPP(
                       funBindInfo as {
                                       func = { name = funcName,id = funcID},
                                       ...
                                       },
                       {strArg = tpmodexp, env},
                       exnTagSubst,
                       instTyConSubst,
                       argStrpath,
                       loc
                       )
         =>
         let
           val (argPathStrEnv, funBodyPathEnv, tfpdecs) =
             case MC.lookupFunctorInContext (context,funcName) of
               NONE => 
               raise Control.Bug ("undefined functor:" ^ funcName)
               | SOME funSig => funSig
           (* elab functor argument *)
           val newContext =
               MC.updateContextWithPrefix (context, argStrpath)
           val ((actArgPathVarEnv,actArgPathStrEnv), tfpdecs1) =
               tpmstrexpToTfpdecs newContext tpmodexp
           (*
            * map from hole id to actual
            *)
           val pathHoleIdEnv = 
               SEnv.foldli 
                 ( 
                  fn (strName, 
                      PE.PATHAUX(argPathVarEnv,argPathStrEnv), 
                      pathHoleIdEnv) =>
                     let
                       val argVarPathIdEnv = 
                           makeArgVarMap (argPathVarEnv, actArgPathVarEnv) loc
                       val argStrPathIdEnv = 
                           makeArgStrMap (argPathStrEnv, actArgPathStrEnv) loc
                     in
                       PE.mergePathHoleIdEnv
                         (
                          PE.mergePathHoleIdEnv
                            (argVarPathIdEnv,argStrPathIdEnv),
                            pathHoleIdEnv
                            )
                     end
                       )
                 PE.emptyPathHoleIdEnv
                 argPathStrEnv

           val (newtfpdecs, pathIdEnv) = 
               MCFA.substituteHoleTfpdecs pathHoleIdEnv
                                          PE.emptyPathIdEnv
                                          instTyConSubst
                                          exnTagSubst
                                          tfpdecs

           (* 1. pathHoldIdEnv: 
            *    instantiate functor body environment with actual argument 
            * 2. pathIdEnv:
            *    refresh declared value identifiers 
            *)
           val newPathEnv = 
               let
                 val pathVarEnv = 
                     FAU.fixPathVarEnv 
                       (#1 (funBodyPathEnv:PE.pathEnv)) 
                       context
                       pathIdEnv
                       pathHoleIdEnv
                       instTyConSubst
                 val pathStrEnv = 
                     FAU.fixPathStrEnv 
                       (#2 (funBodyPathEnv:PE.pathEnv)) 
                       context
                       pathIdEnv
                       pathHoleIdEnv
                       instTyConSubst
               in
                 (pathVarEnv,pathStrEnv)
               end
         in
           (
            newPathEnv,
            tfpdecs1 @ newtfpdecs
            )
         end
       | TPMLET (tpmstrdecs,tpmstrexp, _) =>
         let
           val (pathEnv1,tfpdecs1) = 
               tpmstrdecsToTfpdecs context tpmstrdecs
           val newContext =
               MC.extendContextWithPathEnv (context, pathEnv1)
           val (pathEnv2,tfpdecs2) = 
               tpmstrexpToTfpdecs newContext tpmstrexp
         in
           (pathEnv2,
            tfpdecs1 @ tfpdecs2)
         end
           
   and tpmstrdecToTfpdecs context tpmstrdec =
       case tpmstrdec of
         TPMCOREDEC (tpdecs,loc) => MCC.tpdecsToTfpdecs context tpdecs
       | TPMSTRBIND (tpmstrbinds,loc) =>
         let
           fun tpmstrbindsToTfpdecs topPathBasis pathBasis pathStrEnv_R  nil = 
               (pathStrEnv_R, nil)
             | tpmstrbindsToTfpdecs topPathBasis pathBasis pathStrEnv_R  (tpmstrbind::rem) =
               let
                 val (strVarInfo as {id,name,env},tpmstrexp) = tpmstrbind
                 val newContext =
                     {
                      topPathBasis = topPathBasis,
                      pathBasis = pathBasis,
                      prefix = PE.addPrefix (#prefix context) (id,name)
                      }
                 val (pathEnv1,tfpdecs1) = 
                     tpmstrexpToTfpdecs newContext tpmstrexp
                 val newPathStrEnv_R = SEnv.insert(pathStrEnv_R,name,PE.PATHAUX(pathEnv1))
                 val (pathStrEnv,tfpdecs2) = 
                     tpmstrbindsToTfpdecs topPathBasis pathBasis newPathStrEnv_R rem
               in
                 (pathStrEnv,
                  tfpdecs1 @ tfpdecs2)
               end
           val (pathStrEnv,tfpdecs) = 
               tpmstrbindsToTfpdecs (#topPathBasis context)
                                    (#pathBasis context)
                                    PE.emptyPathStrEnv
                                    tpmstrbinds
         in
           ((PE.emptyPathVarEnv,pathStrEnv),
            tfpdecs)
         end
       | TPMLOCALDEC (tpmstrdecs1,tpmstrdecs2,loc) =>
         let
           val newContext1 = MC.updateContextWithPrefix(context, P.NilPath)
           val (pathEnv1,tfpdecs1) = 
               tpmstrdecsToTfpdecs newContext1 tpmstrdecs1
           val newContext2 =
               MC.extendContextWithPathEnv (context, pathEnv1)
           val (pathEnv2,tfpdecs2) = 
               tpmstrdecsToTfpdecs newContext2 tpmstrdecs2
         in
           (
            pathEnv2,
            tfpdecs1 @ tfpdecs2
            )
         end
           
           
   and tpmstrdecsToTfpdecs context nil = 
       ((PE.emptyPathVarEnv,PE.emptyPathStrEnv),nil)
     | tpmstrdecsToTfpdecs context (tpmstrdec::rem) =
       let
         val (pathEnv1, tfpdecs1) = 
             tpmstrdecToTfpdecs context tpmstrdec
         val newContext =
             MC.extendContextWithPathEnv(context,pathEnv1)
         val (pathEnv2, tfpdecs2) = 
             tpmstrdecsToTfpdecs newContext rem
       in
         (
          PE.mergePathEnv  { newPathEnv=pathEnv2,
                             oldPathEnv=pathEnv1},
          tfpdecs1 @ tfpdecs2
          )
       end

   fun tpmfunbindToFunPathEnv topPathBasis pathBasis fundec = 
       let
         val (funBindInfo as 
                          { func = {name = funcName,id = funcID},
                            functorSig = {
                                          exnTagSet = exnT,
                                          tyConIdSet = argT,
                                          func = {arg = (argTyconEnv,argVarEnv,argStrEnv), 
                                                  body = {constrained = (resT,resE),
                                                          unConstrained = bareEnv}
                                                 }
                                         },
                            ...}:funBindInfo,
              strName,
              tpsigexp,
              tpmodexp) = fundec 

         fun varEnvToPathVarEnv varEnv = 
             SEnv.foldli (fn (varName, T.VARID {ty,...}, pathVarEnv) => 
                             SEnv.insert(pathVarEnv,
                                         varName,
                                         PE.CurItem ((P.NilPath, varName),
                                                     T.newVarId(),
                                                     ty,
                                                     Loc.noloc)
                                        )
                           | (varName, _ , pathVarEnv) => pathVarEnv
                         )
                         SEnv.empty
                         varEnv
         fun strEnvToPathStrEnv (T.STRUCTURE strEnvCont) =
             SEnv.mapi (
                        fn (strName, {env = (TE,VE,SE),...}) =>
                           let
                             val newPathVarEnv  = varEnvToPathVarEnv VE
                             val newPathStrEnv = strEnvToPathStrEnv SE
                           in
                             PE.PATHAUX(
                                        newPathVarEnv,
                                        newPathStrEnv
                                        )
                           end
                       )
                       strEnvCont
         val argPathStrEnv = 
             SEnv.singleton(
                            strName,
                            PE.PATHAUX(
                                       varEnvToPathVarEnv argVarEnv,
                                       strEnvToPathStrEnv argStrEnv
                                       )
                            )

         val newPathBasis = 
             PE.extendPathBasisWithPathEnv 
               { 
                pathBasis = pathBasis,
                pathEnv = (PE.emptyPathVarEnv,argPathStrEnv)
                }

         val newContext =
             {
              topPathBasis = topPathBasis,
              pathBasis = newPathBasis,
              prefix = P.PStructure(funcID,funcName,P.NilPath)
              }
         val (pathEnv, tfpdecs) = tpmstrexpToTfpdecs newContext tpmodexp
       in
         SEnv.singleton(funcName,
                        (argPathStrEnv,
                         pathEnv,
                         tfpdecs)
                        )
       end                        


   fun STRDECGroupToTfpdecs topPathBasis pathBasis prefix tptopstrdecs =
       foldl 
         (fn (tptopstrdec,(deltaPathBasis, accPathBasis, accTfpdecs)) =>
             let
               val context = 
                   {
                    topPathBasis = topPathBasis,
                    pathBasis = accPathBasis,
                    prefix = prefix
                    }
               val (deltaPathEnv, tfpdecs) =
                   tpmstrdecToTfpdecs context tptopstrdec
               val newDeltaPathBasis = (SEnv.empty, deltaPathEnv)
             in
               (
                PE.mergePathBasis{newPathBasis = newDeltaPathBasis, oldPathBasis = deltaPathBasis},
                PE.mergePathBasis{newPathBasis = newDeltaPathBasis, oldPathBasis = accPathBasis},
                accTfpdecs @ tfpdecs
                )
               end
         )
         (PE.emptyPathBasis, pathBasis, nil)
         tptopstrdecs

   fun FUNDECGroupToTfpdecs topPathBasis liftedPathBasis tpfundecs =
       foldl (
              fn (fundec,pathFunEnv) => 
                 let
                   val pathFunEnv1 = 
                       tpmfunbindToFunPathEnv
                         topPathBasis liftedPathBasis fundec
                 in
                   SEnv.unionWith #1 (pathFunEnv1,pathFunEnv)
                 end
                   )
             SEnv.empty
             tpfundecs

   (* reason for introducing groups: eg.
    * fun f x = x + 1   (* no semicolon here *)
    * functor F(S : sig end) = struct fun g x = f x end;
    * structure S = F(struct end);
    *   f appearring in functor must know the global index to 
    * generate a global variable reference. So we discard
    * the method that assign global index after the 
    * whole session, instead we use Functor as separator and
    * each STRDEC group is proccessed for allocating global index.
    *)
   fun tptopdecsToTpTopGroups tptopdecs =
       let
         val (headGroup, decGroups) =
             foldr (fn (tptopdec, (headGroup, decGroups)) =>
                       case (tptopdec, headGroup) of
                         (TPMDECSTR (tptopstrdec, loc), STRDEC args) => 
                         (STRDEC (tptopstrdec :: args), decGroups)
                       | (TPMDECSIG _, _) => (headGroup, decGroups)
                       | (TPMDECIMPORT (tpmspec, Env, loc), IMPORTDEC args) =>
                         (IMPORTDEC ((tpmspec,Env) :: args), decGroups)
                       | (TPMDECFUN (fundecs, loc), _) =>
                         (STRDEC nil, FUNDEC (fundecs) :: headGroup :: decGroups)
                       | (TPMDECSTR (tptopstrdec, loc) , _) =>
                         (STRDEC [tptopstrdec], headGroup :: decGroups)
                       | (TPMDECIMPORT(tpmspec, Env,loc), _) =>
                         (IMPORTDEC [(tpmspec,Env)], headGroup :: decGroups)
                   )
                   (STRDEC nil, nil)
                   tptopdecs
       in
         headGroup :: decGroups
       end

   fun STRDECGroupToTopdecs tptopstrdecs 
                            freeGlobalArrayIndex 
                            freeEntryPointer 
                            prefix 
                            topPathBasis 
                            accPathBasis =
       let
         val (deltaPathBasis, _, tfpdecs) =
             STRDECGroupToTfpdecs 
               topPathBasis accPathBasis prefix tptopstrdecs
         val (newFreeGlobalArrayIndex, newFreeEntryPointer, deltaIndexMap, preludeDecs, finaleDecs) = 
             if !Control.doCompileObj then
               IA.makePreludeAndFinaleDecs_ObjFile(freeGlobalArrayIndex, freeEntryPointer, deltaPathBasis)
             else IA.makePreludeAndFinaleDecs(freeGlobalArrayIndex, freeEntryPointer, deltaPathBasis)
         val deltaLiftedPathBasis = 
             PE.liftUpPathBasisToTop deltaPathBasis deltaIndexMap
       in
         (newFreeGlobalArrayIndex,
          newFreeEntryPointer,
          deltaPathBasis,
          deltaLiftedPathBasis,
          (preludeDecs, tfpdecs,  finaleDecs))
       end
         
   fun tptopGroupsToTfpdecs 
           freeGlobalArrayIndex freeEntryPointer topPathBasis accPathBasis prefix tptopGroups =
       let
           val (freeGlobalArrayIndex, freeEntryPointer, pathBasis, liftedPathBasis, tfpdecs) =
             foldl 
             (fn (tpTopGroup, 
                  (freeGlobalArrayIndex, freeEntryPointer, accPathBasis, liftedPathBasis, newTfpdecs)) 
                 =>
                 case tpTopGroup of
                   STRDEC tptopstrdecs =>
                   let
                     val (newFreeGlobalArrayIndex,
                          newFreeEntryPointer,
                          deltaPathBasis,
                          deltaLiftedPathBasis,
                          (prelude, body, finale)) = STRDECGroupToTopdecs tptopstrdecs  
                                                          freeGlobalArrayIndex
                                                          freeEntryPointer
                                                          prefix
                                                          topPathBasis
                                                          accPathBasis
                   in
                     (
                      newFreeGlobalArrayIndex,
                      newFreeEntryPointer,
                      PE.mergePathBasis{newPathBasis = deltaPathBasis,
                                        oldPathBasis = accPathBasis},
                      PE.mergePathBasis{newPathBasis = deltaLiftedPathBasis,
                                        oldPathBasis = liftedPathBasis},
                      newTfpdecs @ (prelude @ body @ finale)
                     )
                   end
                 | FUNDEC tpfundecs =>
                   let
                     val pathFunEnv = 
                         FUNDECGroupToTfpdecs topPathBasis liftedPathBasis tpfundecs
                   in
                     (
                      freeGlobalArrayIndex,
                      freeEntryPointer,
                      PE.mergePathBasis{newPathBasis = (pathFunEnv, PE.emptyPathEnv),
                                        oldPathBasis = accPathBasis},
                      PE.mergePathBasis{newPathBasis = (pathFunEnv, PE.emptyPathEnv),
                                        oldPathBasis = liftedPathBasis},
                      newTfpdecs
                     )
                   end
                 | IMPORTDEC tpmspecEnvs =>
                   raise Control.Bug "import should occur in separate compilation"
             )
             (freeGlobalArrayIndex, freeEntryPointer, accPathBasis, PE.emptyPathBasis, nil)
             tptopGroups
       in
         (
          freeGlobalArrayIndex,
          freeEntryPointer, 
          liftedPathBasis, 
          tfpdecs)
       end

   fun tptopGroupdecsToTfpdecs' freeGlobalArrayIndex freeEntryPointer topPathBasis prefix tptopGroups =
       let
         val (
              freeGlobalArrayIndex,
              freeEntryPointer, 
              accPathBasis,  (* for compiling structure and core *)
              liftedPathBasis, (* for compilation functor *)
              incImportPathBasis, (* incremental import *)
              incLiftedPathBasis, (* incremental export *)
              tfpdecs) =
             foldl 
             (fn (tpTopGroup, 
                  (
                   freeGlobalArrayIndex,
                   freeEntryPointer, 
                   accPathBasis, 
                   liftedPathBasis, 
                   incImportPathBasis, 
                   incLiftedPathBasis,
                   newTfpdecs)) =>
                 case tpTopGroup of
                   IMPORTDEC tpmspecEnvs =>
                   let
                       val (newFreeEntryPointer, newImportPathBasis) =
                           foldl (fn ((tpmspec, Env), 
                                      (freeEntryPointer, 
                                       importPathBasis)) =>
                                     let
                                         val _ = print 
                                         val (newFreeEntryPointer, pathBasis) =
                                             MCU.genImportPathBasisFromEnv Env
                                                                           freeEntryPointer
                                     in
                                         (
                                          newFreeEntryPointer,
                                          PE.extendPathBasisWithPathBasis
                                              { 
                                               newPathBasis = pathBasis,
                                               oldPathBasis = importPathBasis
                                               })
                                     end
                                         )
                                 (freeEntryPointer, PE.emptyPathBasis)
                                 tpmspecEnvs
                       val newAccPathBasis =
                           PE.extendPathBasisWithPathBasis 
                               {newPathBasis = newImportPathBasis,
                                oldPathBasis = accPathBasis}
                       val newLiftedPathBasis =
                           PE.extendPathBasisWithPathBasis
                               {newPathBasis = newImportPathBasis,
                                oldPathBasis = liftedPathBasis}
                       val newImportPathBasis =
                           PE.extendPathBasisWithPathBasis
                               {newPathBasis = newImportPathBasis,
                                oldPathBasis = incImportPathBasis}
                   in
                       (
                        freeGlobalArrayIndex,
                        newFreeEntryPointer,
                        newAccPathBasis,
                        newLiftedPathBasis,
                        newImportPathBasis,
                        incLiftedPathBasis,
                        nil
                        )
                   end
                 | STRDEC tptopstrdecs =>
                   let
                     val (newGlobalArrayIndex,
                          newFreeEntryPointer,
                          deltaPathBasis,
                          deltaLiftedPathBasis,
                          (prelude, body, finale)) = STRDECGroupToTopdecs tptopstrdecs 
                                                          freeGlobalArrayIndex 
                                                          freeEntryPointer 
                                                          prefix
                                                          topPathBasis
                                                          accPathBasis
                   in
                     (newGlobalArrayIndex,
                      newFreeEntryPointer,
                      PE.mergePathBasis{newPathBasis = deltaPathBasis,
                                        oldPathBasis = accPathBasis},
                      PE.mergePathBasis{newPathBasis = deltaLiftedPathBasis,
                                        oldPathBasis = liftedPathBasis},
                      incImportPathBasis,
                      PE.mergePathBasis{newPathBasis = deltaLiftedPathBasis,
                                        oldPathBasis = incLiftedPathBasis},
                      newTfpdecs @ (prelude @ body @ finale))
                   end
                 | FUNDEC tpfundecs =>
                   let
                     val pathFunEnv = 
                         FUNDECGroupToTfpdecs topPathBasis liftedPathBasis tpfundecs
                   in
                     (freeGlobalArrayIndex,                      
                      freeEntryPointer,
                      PE.mergePathBasis{newPathBasis = (pathFunEnv, PE.emptyPathEnv),
                                        oldPathBasis = accPathBasis},
                      PE.mergePathBasis{newPathBasis = (pathFunEnv, PE.emptyPathEnv),
                                        oldPathBasis = liftedPathBasis},
                      incImportPathBasis,
                      PE.mergePathBasis{newPathBasis = (pathFunEnv, PE.emptyPathEnv),
                                        oldPathBasis = incLiftedPathBasis},
                      newTfpdecs)
                   end)
             (
              freeGlobalArrayIndex,
              freeEntryPointer, 
              PE.emptyPathBasis, 
              PE.emptyPathBasis, 
              PE.emptyPathBasis, 
              PE.emptyPathBasis,
              nil)
             tptopGroups
       in
         (
          freeGlobalArrayIndex,
          freeEntryPointer, 
          incLiftedPathBasis,
          incImportPathBasis,
          tfpdecs)
       end
end
end
