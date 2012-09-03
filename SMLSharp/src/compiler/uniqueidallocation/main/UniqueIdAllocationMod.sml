(**
 * Unique Id allocation for module part
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: UniqueIdAllocationMod.sml,v 1.27 2008/08/06 17:23:41 ohori Exp $
 *)
structure UniqueIdAllocationMod  = 
struct
local

  structure T  = Types
  structure P = Path
  structure FAU = FunctorApplyUtils
  structure UIACore = UniqueIdAllocationCore
  structure VIC = VarIDContext
  structure UIAU = UniqueIdAllocationUtils
  structure EIA = ExternalIdAllocator
  structure UIAC = UniqueIdAllocationContext
  structure TFC = TypedFlatCalc 
  structure NM = NameMap
  structure NPEnv = NM.NPEnv

  open TypedCalc 

  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")
  fun typeToString ty = TypeFormatter.tyToString ty
  fun printx x = if false then print x else ()
                        
  datatype decGroup = 
           STRDEC of tpstrdecl list
         | FUNDEC of {funBindInfo :Types.funBindInfo,
                      argName : string,
                      argSpec : PatternCalc.plsigexp * NameMap.basicNameNPEnv,
                      bodyDec : (tpstrdecl list * NameMap.basicNameMap * PatternCalc.plsigexp option)} list
                     * loc
in

   fun tpmFunbindToFunPathEnv topVarExternalVarIDBasis varIDBasis (fundec, loc) = 
       let
           val {funBindInfo = {functorSig = {argStrPrefixedEnv = (tyConEnv, varEnv),
                                             generativeExnTagSet,
                                             ...},
                               funName,
                               ...}:Types.funBindInfo,
                argName, 
                argSpec = (argSpec, formalArgNamePathEnv), 
                bodyDec = (bodyDecs, bodyNameMap, sigExpOpt)} = fundec
           fun varEnvToVarIDEnv varEnv = 
               (* strArgVarIDEnv : environment with argument structure prefixed.
                * sigArgVarIDEnv : environment without argument structure perfixed.
                *)
               NPEnv.foldli (fn (varNamePath, T.VARID {ty,...}, 
                                 (strArgVarIDEnv, 
                                  sigArgVarIDEnv,
                                  varIDSet)) => 
                                let
                                    val strVarName = NM.namePathToString varNamePath
                                    val sigVarNamePath = 
                                        (* remove the injection structure formal name *) 
                                        NM.getTailNamePath
                                            (* remove the formal name in source language *)
                                            (NM.getTailNamePath varNamePath)
                                    val sigVarName = 
                                        (* Without argument structure name prefix *)
                                        NM.namePathToString sigVarNamePath
                                    val newExternalVarID = Counters.newExternalID ()
                                in
                                    (
                                     NPEnv.insert(strArgVarIDEnv,
                                                  varNamePath,
                                                  VIC.External newExternalVarID
                                                  ),
                                     NPEnv.insert (sigArgVarIDEnv,
                                                   sigVarNamePath,
                                                   (VIC.External newExternalVarID)
                                                   ),
                                     ExternalVarID.Set.add(varIDSet, newExternalVarID)
                                     )
                                end
                              | (varNamePath, _ , result) => result)
                            (NPEnv.empty, NPEnv.empty, ExternalVarID.Set.empty)
                            varEnv
           val (strArgVarIDEnv, sigArgVarIDEnv, formalVarIDSet) = varEnvToVarIDEnv varEnv
           val newVarIDBasis = 
               VIC.extendVarIDBasisWithVarIDEnv 
                   {varIDBasis = varIDBasis, newVarIDEnv = strArgVarIDEnv}
           val newContext =
               {
                topVarExternalVarIDBasis = topVarExternalVarIDBasis,
                varIDBasis = newVarIDBasis
               }
           val (bodyVarIDEnv, tfpdecs) = tpstrdecsToTfpdecs newContext bodyDecs
           val (newBodyVarIDEnv, generativeExternalVarIDSet, newTfpdecs) = 
               FAU.externalizeBodyTfpdecs (bodyVarIDEnv, tfpdecs)
           val functorEnv = 
               SEnv.singleton (funName,
                               {name = funName,
                                argName = argName, 
                                argExternalVarIDEnv = sigArgVarIDEnv,
                                bodyExternalVarIDEnv = newBodyVarIDEnv,
                                generativeExternalVarIDSet = generativeExternalVarIDSet
                              })
           val formalExnIDSet = 
               NPEnv.foldl (fn (Types.EXNID {tag,...}, exnIDSet) =>
                               ExnTagID.Set.add(exnIDSet, tag)
                             | (_, exnIDSet) => exnIDSet)
                           ExnTagID.Set.empty
                           varEnv

       in
           (
            functorEnv,
            TFC.TFPFUNCTORDEC {name = funName, 
                               formalAbstractTypeIDSet = FAU.collectAbstractTypeIDSet tyConEnv,
                               formalVarIDSet = formalVarIDSet,
                               formalExnIDSet = formalExnIDSet,
                               generativeVarIDSet = generativeExternalVarIDSet,
                               generativeExnIDSet = generativeExnTagSet,
                               bodyCode = newTfpdecs}
            )
       end

   and tpstrdecToTfpdecs (context: UIAC.context) tpdec =
       case tpdec of
           TPCOREDEC (decs, loc) =>
           let
               val (varIDEnv, newTfpdecs) =
                   UIACore.tpdecsToTfpdecs context decs
           in
               (varIDEnv, newTfpdecs)
           end
         | TPCONSTRAINT (decs, basicNameNPEnv, loc) =>
           let
               val (newVarIDEnv, newTfpdecs) = tpstrdecsToTfpdecs context decs 
               val filteredVarIDEnv = UIAU.filterPathVE (newVarIDEnv, basicNameNPEnv)
           in
               (filteredVarIDEnv, newTfpdecs)
           end
         | TPFUNCTORAPP ({prefix = prefix,
                          funBindInfo = funBindInfo, 
                          argNameMapInfo = {argNamePath, env = actualNameNPEnv}, 
                          typeResolutionTable,
                          exnTagResolutionTable,
                          refreshedExceptionTagTable,
                          loc}) =>
           let
               val functorName = #funName funBindInfo
               val {name, 
                    argName, 
                    argExternalVarIDEnv, 
                    bodyExternalVarIDEnv, 
                    generativeExternalVarIDSet} =
                   case UIAC.lookupFunctorInContext (context, functorName) of
                       NONE => 
                       raise Control.Bug ("undefined functor:" ^ functorName)
                     | SOME funInfo => funInfo

               val actualArgVarIDEnv = 
                   UIAU.reconstructVarIDEnvFromNameMapWithoutActualStrName
                       actualNameNPEnv context loc
               val (externalizedActualArgVarIDEnv, externalizedActualArgTfpdecs) =
                   FAU.externalizeArgTfpdecs actualArgVarIDEnv loc
                   
               val externalVarIDResolutionTable =
                   FAU.makeArgIDMap (argExternalVarIDEnv, externalizedActualArgVarIDEnv) loc
               val refreshedExternalVarIDTable =
                   ExternalVarID.Set.foldr
                       (fn (generativeExternalVarID, refreshedExternalVarIDTable) => 
                           ExternalVarID.Map.insert(refreshedExternalVarIDTable,
                                                    generativeExternalVarID,
                                                    Counters.newExternalID ()))
                       ExternalVarID.Map.empty
                       generativeExternalVarIDSet

               val newBodyVarIDEnv = 
                   FAU.fixVarIDEnv 
                       bodyExternalVarIDEnv externalVarIDResolutionTable refreshedExternalVarIDTable prefix
           in
               (newBodyVarIDEnv,
                externalizedActualArgTfpdecs @ 
                [TFC.TFPLINKFUNCTORDEC {name = functorName,
                                        actualArgName = Path.pathToString argNamePath,
                                        typeResolutionTable = typeResolutionTable,
                                        exnTagResolutionTable = exnTagResolutionTable,
                                        externalVarIDResolutionTable = externalVarIDResolutionTable,
                                        refreshedExceptionTagTable = refreshedExceptionTagTable,
                                        refreshedExternalVarIDTable = refreshedExternalVarIDTable,
                                        loc = loc}]
               )

           end
         | TPANDFLATTENED(decUnits, loc) =>
           let
               val (varIDEnv, newDecs) = 
                   foldl (fn ((_, decUnit), (newVarIDEnv, newDecs)) =>
                             let
                                 val (varIDEnv1, decs) = tpstrdecsToTfpdecs context decUnit
                             in
                                 (VIC.mergeVarIDEnv {newVarIDEnv = varIDEnv1,
                                                      oldVarIDEnv = newVarIDEnv},
                                  newDecs @ decs)
                             end)
                         (NPEnv.empty, nil)
                         decUnits
           in
               (varIDEnv, newDecs)
           end
         | TPSTRLOCAL (localDecs, decs, loc) => 
           let
               val (varIDEnv1, tfplocalDecs) = tpstrdecsToTfpdecs context localDecs
               val newContext = UIAC.extendContextWithVarIDEnv (context, varIDEnv1)
               val (varIDEnv2, tfpdecs) = tpstrdecsToTfpdecs newContext decs
           in 
               (varIDEnv2, tfplocalDecs @ tfpdecs) 
           end
               
   and tpstrdecsToTfpdecs context tpdecs =
       let
           val ( _, incVarIDEnv, newTfpdecs) =
               foldl (fn (tpdec, (context, incVarIDEnv, newTfpdecs)) =>
                         let
                             val (varIDEnv1, tfpdecs1) = 
                                 tpstrdecToTfpdecs context tpdec
                             val newContext = 
                                 UIAC.extendContextWithVarIDEnv (context, varIDEnv1)
                         in
                             (
                              newContext,
                              VIC.mergeVarIDEnv {newVarIDEnv=varIDEnv1,
                                                       oldVarIDEnv=incVarIDEnv
                                                      },
                              newTfpdecs  @ tfpdecs1
                             )
                         end)
                     (context, NPEnv.empty, nil)
                     tpdecs
       in
           (incVarIDEnv, newTfpdecs)
       end

   fun STRDECGroupToTfpdecs topVarExternalVarIDBasis varIDBasis tpdecs =
       foldl 
         (fn (tpdec,(deltaVarIDBasis, accVarIDBasis, accTfpdecs)) =>
             let
               val context = 
                   {
                    topVarExternalVarIDBasis = topVarExternalVarIDBasis,
                    varIDBasis = accVarIDBasis
                   }
               val (deltaPathEnv, tfpdecs) =
                   tpstrdecToTfpdecs context tpdec
               val newDeltaVarIDBasis = (SEnv.empty, deltaPathEnv)
             in
               (
                VIC.mergeVarIDBasis
                    {newVarIDBasis = newDeltaVarIDBasis, 
                     oldVarIDBasis = deltaVarIDBasis},
                VIC.mergeVarIDBasis
                    {newVarIDBasis = newDeltaVarIDBasis, 
                     oldVarIDBasis = accVarIDBasis},
                accTfpdecs @ tfpdecs
                )
               end
         )
         (VIC.emptyVarIDBasis, varIDBasis, nil)
         tpdecs

   fun FUNDECGroupToTfpdecs topVarExternalVarIDBasis liftedVarIDBasis (tpfundecs, loc) =
       foldl (
              fn (fundec, (pathFunEnv, funDecs)) => 
                 let
                     val (pathFunEnv1, newFunDec) = 
                         tpmFunbindToFunPathEnv topVarExternalVarIDBasis
                                                liftedVarIDBasis 
                                                (fundec, loc)
                 in
                     (SEnv.unionWith #1 (pathFunEnv1, pathFunEnv),
                      funDecs @ [newFunDec])
                 end
             )
             (SEnv.empty, nil)
             tpfundecs

   (* reason for introducing groups: eg.
    * fun f x = x + 1   (* no semicolon here *)
    * functor F(S : sig end) = struct fun g x = f x end;
    * structure S = F(struct end);
    *   f appearring in functor must know the global  to 
    * generate a global variable reference. So we discard
    * the method that assign global  after the 
    * whole session, instead we use Functor as separator and
    * each STRDEC group is proccessed for allocating global .
    *)
   fun tptopdecsToTpTopGroups tptopdecs =
       let
           val (headGroup, decGroups) =
               foldr (fn (tptopdec, (headGroup, decGroups)) =>
                         case (tptopdec, headGroup) of
                             (TPDECSTR (coredecs, loc), STRDEC args) => 
                             (STRDEC (coredecs @ args), decGroups)
                           | (TPDECSIG _, _) => (headGroup, decGroups)
                           | (TPDECFUN (fundecs, loc), _) =>
                             (STRDEC nil, FUNDEC (fundecs, loc) :: headGroup :: decGroups)
                           | (TPDECSTR (coredecs, loc) , _) =>
                             (STRDEC coredecs, headGroup :: decGroups))
                     (STRDEC nil, nil)
                     tptopdecs
       in
           headGroup :: decGroups
       end

   fun STRDECGroupToTopdecs tptopdecs topVarExternalVarIDBasis currentVarIDBasis =
       let
           val (deltaVarIDBasis, _, tfpdecs) =
               STRDECGroupToTfpdecs topVarExternalVarIDBasis currentVarIDBasis tptopdecs
           val deltaIDMap = EIA.allocateExternalIdForVarIDBasis deltaVarIDBasis
(*
           val deltaLiftedVarIDBasis = 
               VIC.liftUpVarIDBasisToTop deltaVarIDBasis deltaIDMap
*)
       in
           ((* deltaLiftedVarIDBasis, *)
            deltaVarIDBasis,
            deltaIDMap, 
            tfpdecs)
       end
         
   fun tptopGroupsToTfpdecs topVarExternalVarIDBasis tptopGroups =
       let
           val (liftedVarIDBasis, IDMap, tfpdecs) =
               foldl 
                   (fn (tpTopGroup, 
                        (currentVarIDBasis, 
                         IDMap, 
                         newTfpdecs)) 
                       =>
                       case tpTopGroup of
                           STRDEC tptopstrdecs =>
                           let
                               val ((* deltaLiftedVarIDBasis, *)
                                    deltaVarIDBasis, deltaIDMap, body) = 
                                   STRDECGroupToTopdecs tptopstrdecs 
                                                        topVarExternalVarIDBasis
                                                        currentVarIDBasis
                           in
                               (
                                VIC.mergeVarIDBasis
                                    {newVarIDBasis = deltaVarIDBasis,
                                     oldVarIDBasis = currentVarIDBasis},
                                LocalVarID.Map.unionWith #1 (IDMap, deltaIDMap),
                                newTfpdecs @ body)
                           end
                         | FUNDEC (tpfundecs, loc) =>
                           let
                               val (pathFunEnv, funDecs) = 
                                   FUNDECGroupToTfpdecs topVarExternalVarIDBasis
                                                        currentVarIDBasis
                                                        (tpfundecs, loc)
                           in
                               (
                                VIC.mergeVarIDBasis
                                    {newVarIDBasis = (pathFunEnv, VIC.emptyVarIDEnv),
                                     oldVarIDBasis = currentVarIDBasis},
                                IDMap,
                                newTfpdecs @ funDecs
                               )
                           end)
                   (VIC.emptyVarIDBasis, LocalVarID.Map.empty, nil)
                   tptopGroups
       in
           (liftedVarIDBasis, IDMap, tfpdecs)
       end

end
end
