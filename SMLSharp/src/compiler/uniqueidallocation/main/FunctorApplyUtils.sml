(**
 * Functor Application Utilities.
 *
 * @copyright (c) 2006, Tohoku University.
 *
 * @author Liu Bochao
 * @version $Id: FunctorApplyUtils.sml,v 1.19 2008/08/06 17:23:41 ohori Exp $
 *)
structure FunctorApplyUtils =
struct
local 

    open TypedFlatCalc 
    structure TFCU = TypedFlatCalcUtils
    structure T = Types
    structure TU = TypesUtils
    structure TCU = TypeContextUtils
    structure P = Path
    structure VIC = VarIDContext
    structure UIAU = UniqueIdAllocationUtils
    structure UIAC = UniqueIdAllocationContext
    structure NPEnv = NameMap.NPEnv
    structure UIAU = UniqueIdAllocationUtils

in 
  fun makeArgIDMap (formalArgVarEnv, actualArgVarEnv) loc =
      NPEnv.foldli (fn (_, VIC.Internal _, _) =>
                       raise Control.BugWithLoc ("functor argument without abstract index", loc)
                     | (_, VIC.Dummy, _) =>
                       raise Control.BugWithLoc ("functor argument without dummy", loc)
                     | (varNamePath, VIC.External index, newPathHoleEnv) => 
                       (case NPEnv.find(actualArgVarEnv, varNamePath) of
                            NONE => 
                            raise Control.BugWithLoc 
                                      (("Functor application failed : variable " 
                                        ^ NameMap.namePathToString(varNamePath) ^ " undefined"),
                                       loc)
                          | SOME (VIC.External newIndex) =>
                            ExternalVarID.Map.insert(newPathHoleEnv, index, newIndex)
                          | SOME VIC.Dummy =>
                            raise Control.BugWithLoc ("argument should not be dummy: " ^ NameMap.namePathToString(varNamePath), loc)
                          | SOME (VIC.Internal _) => 
                            raise Control.BugWithLoc 
                                      (("argument should be global: " 
                                        ^ NameMap.namePathToString(varNamePath) ^ " is local id"),
                                       loc)
                                      ))
                   ExternalVarID.Map.empty
                   formalArgVarEnv

           
   fun fixVarIDEnv varIDEnv externalVarIDResolutionTable refreshedExternalVarIDTable prefix =
       NPEnv.foldli (
                     fn (varNamePath, 
                         varItem as VIC.Internal (id, _), 
                         newVarIDEnv)
                        =>
                        raise Control.Bug ("functor inner declared vaiable should be topItem:" ^ 
                                           (NameMap.namePathToString(varNamePath)) ^
                                           LocalVarID.toString(id))
                      | (varNamePath, VIC.Dummy, newVarIDEnv) =>
                        raise Control.Bug ("functor inner declared variable should not be dummy:" ^ NameMap.namePathToString varNamePath)
                      | (varNamePath, VIC.External index, newVarIDEnv) =>
                        case ExternalVarID.Map.find(externalVarIDResolutionTable, index) of
                            (* functor argument provides the actual item *)
                            SOME index =>
                            NPEnv.insert
                                (newVarIDEnv, 
                                 (#1 varNamePath, Path.joinPath(prefix, #2 varNamePath)),
                                 (VIC.External index))
                          | NONE => 
                            (case ExternalVarID.Map.find(refreshedExternalVarIDTable, index) of
                                 SOME index =>
                                 NPEnv.insert(newVarIDEnv, 
                                              (#1 varNamePath, Path.joinPath(prefix, #2 varNamePath)),
                                              (VIC.External index))
                               | NONE =>
                                 (* if functor body is a structure of previous compilation 
                                  * unit, then untouched
                                  *) 
                                 NPEnv.insert(newVarIDEnv, 
                                              (#1 varNamePath, Path.joinPath(prefix, #2 varNamePath)),
                                              (VIC.External index))
                                 ))
                    NPEnv.empty
                    varIDEnv


   (*
    * Make the global declared varaible inside functor have external kind.
    *)
   fun externalizeBodyTfpdecs (varIDEnv, tfpdecs) =
       case tfpdecs of
           nil => 
           (* functor body is a structure name *)
           (varIDEnv, ExternalVarID.Set.empty, tfpdecs)
         | _ => 
           (* functor body is a sequence of code. *)
           let
               val (IDMap, newVarIDEnv) =
                   (* This step computes the variables that
                    * will be externalized according to varIDEnv that
                    * is the bodyEnv of functor
                    *)
                   NPEnv.foldli (fn (namePath, item, (IDMap, newVarIDEnv)) =>
                                    case item of
                                        (VIC.Internal (oldId, ty)) =>
                                        (* Internal must represent the inner declared variable *)
                                        let
                                            val newExternalVarID = 
                                                Counters.newExternalID ()
                                        in
                                            (LocalVarID.Map.insert(IDMap, oldId, (NameMap.namePathToString namePath, newExternalVarID)),
                                             NPEnv.insert(newVarIDEnv, 
                                                          namePath, 
                                                          (VIC.External (newExternalVarID))))
                                        end
                                      | (VIC.External index) =>
                                        (* External Value is untouched:
                                         * 1. real global value outside functor body, e.g.
                                         *      structure A =.....
                                         *      F(S:sig end) = A
                                         * 2. functor argument
                                         *)
                                        (IDMap, 
                                         NPEnv.insert(newVarIDEnv, 
                                                      namePath, 
                                                      VIC.External index)
                                        )
                                      | VIC.Dummy =>
                                        (IDMap, NPEnv.insert(newVarIDEnv, namePath, VIC.Dummy))
                                )
                                (LocalVarID.Map.empty, VIC.emptyVarIDEnv)
                                varIDEnv
               val newTfpdecs = 
                   map (UIAU.annotateExternalIdTfpdec UIAU.externalizeVarIdInfo IDMap) tfpdecs
               val generativeExternalVarIDList = 
                   UIAU.collectVarExternalVarIDTfpdecs newTfpdecs
           in
               (newVarIDEnv, generativeExternalVarIDList, newTfpdecs)
           end

   fun externalizeArgTfpdecs actualArgVarIDEnv loc =
       NPEnv.foldli (fn (namePath, item, (newActualArgVarIDEnv, newTfpdecs)) =>
                        case item of
                            VIC.Internal (oldId, ty) =>
                            let
                                val name = NameMap.namePathToString namePath
                                val newExternalVarID = Counters.newExternalID ()
                                val newTfpdec =
                                    TFPVAL ([(T.VALIDENT {displayName = name,
                                                          ty = ty,
                                                          varId = T.EXTERNAL newExternalVarID},
                                              TFPVAR ({displayName = name,
                                                       ty = ty,
                                                       varId = T.INTERNAL oldId},
                                                      loc))],
                                            loc)
                            in
                                (NPEnv.insert(newActualArgVarIDEnv,
                                              namePath,
                                              (VIC.External (newExternalVarID))),
                                 newTfpdecs @ [newTfpdec])
                            end
                          | (VIC.External x) =>
                            (NPEnv.insert(newActualArgVarIDEnv,
                                          namePath,
                                          (VIC.External x)),
                             newTfpdecs
                            )
                          | VIC.Dummy =>
                            (NPEnv.insert(newActualArgVarIDEnv, namePath, VIC.Dummy), newTfpdecs)
                    )
                    (NPEnv.empty, nil)
                    actualArgVarIDEnv

   fun collectAbstractTypeIDSet tyConEnv = 
       NPEnv.foldl (fn (tyBindInfo, absIDSet) =>
                       case tyBindInfo of
                           Types.TYSPEC {id, ...} =>
                           TyConID.Set.add(absIDSet, id)
                         | _ => absIDSet)
                  TyConID.Set.empty
                  tyConEnv
end (* end local*)
end (* end structure *)
