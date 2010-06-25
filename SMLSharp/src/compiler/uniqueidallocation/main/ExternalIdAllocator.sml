(**
 * Assign global index to val declarations
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ExternalIdAllocator.sml,v 1.8 2008/08/06 17:23:41 ohori Exp $
 *)
structure ExternalIdAllocator =
struct
local
    structure T = Types
    structure TFCU = TypedFlatCalcUtils
    structure VIC = VarIDContext
    structure BT = BasicTypes
    structure NPEnv = NameMap.NPEnv
    open TypedFlatCalc 
in

  fun allocateExternalVarIDForVarInfo (varIdInfo as {id,displayName}) =
       let
           val deltaMap = 
               VarID.Map.singleton (id, (displayName, Counters.newExternalID ()))
       in
           deltaMap
       end

   fun visibleVarsInPathVarEnv pathVarEnv =
       NPEnv.foldli (fn (namePath, item, visibleVars) =>
                        case item of
                            VIC.Internal (id, ty) =>
                            {id = id, displayName = NameMap.namePathToString namePath}
                           :: visibleVars
                          | VIC.External _ => visibleVars
                          | VIC.Dummy => visibleVars)
                  nil
                  pathVarEnv

   fun visibleVarsInPathBasis (pathBasis as (pathFunEnv, pathVarEnv)) =
       visibleVarsInPathVarEnv pathVarEnv

   fun allocateExternalIdForVarIDBasis pathBasis =
       let
           val visibleVars = visibleVarsInPathBasis pathBasis 
           val deltaMap =
               foldl (fn (varIdInfo, accMap) =>
                         let
                             val deltaMap = allocateExternalVarIDForVarInfo varIdInfo
                         in
                             VarID.Map.unionWith #1 (deltaMap, accMap)
                         end)
                     VarID.Map.empty
                     visibleVars
       in
           deltaMap
       end

   fun allocateExternalIdForVarEnv varEnv =
       NPEnv.foldli (fn (namePath, T.VARID _, pathVarEnv) =>
                        let
                            val displayName = NameMap.usrNamePathToString namePath
                        in
                            NPEnv.insert(pathVarEnv, 
                                         namePath,
                                         VIC.External (Counters.newExternalID ())
                                        )
                        end
                      | (_, _, pathVarEnv) => pathVarEnv)
                    NPEnv.empty
                    varEnv

end
end
