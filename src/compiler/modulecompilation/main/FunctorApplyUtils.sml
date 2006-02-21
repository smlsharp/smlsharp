(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author Liu Bochao
 * @version $Id: FunctorApplyUtils.sml,v 1.47 2006/02/18 04:59:23 ohori Exp $
 *)
structure FunctorApplyUtils =
struct
  local 
    open TypedFlatCalc 
    structure TFCU = TypedFlatCalcUtils
    structure T = Types
    structure TCU = TypeContextUtils
    structure TU = TypesUtils
    structure P = Path
    structure PE = PathEnv
    structure TO = TopObject
    structure SE = StaticEnv
    structure MCU = ModuleCompileUtils
    structure MC = ModuleContext
  in
    fun substTyEnvFromTyConEnv (sigTyConEnv, strTyConEnv) =
        SEnv.foldli (
		     fn (tyCon,tyBind1,substTyEnv) =>
                        case SEnv.find(strTyConEnv,tyCon) of 
                          NONE => 
                          raise Control.Bug "structure does not match signature in TyConEnv"
                        | SOME tyBind2 => 
                          ( case tyBind1 of
                              T.TYSPEC{spec = {id,...},...} => 
                              ID.Map.insert(substTyEnv,id , tyBind2)
                            | T.TYCON{id,...} =>
                              ID.Map.insert(substTyEnv,id , tyBind2)
                            | _ => substTyEnv
                          )
		    )
                    ID.Map.empty
                    sigTyConEnv

    fun substTyEnvFromEnv (
                           (sigTyConEnv,sigVarEnv,sigStrEnv), 
                           (strTyConEnv,strVarEnv,strStrEnv)
                           ) 
      =
      let
        val substTyEnv1 = substTyEnvFromTyConEnv (sigTyConEnv,strTyConEnv)
        val substTyEnv2 =
            SEnv.foldli (
                         fn (strId, T.STRUCTURE{env=sigEnv,...}, newTyBindsMap) =>
                            case SEnv.find(strStrEnv,strId) of
                              NONE => 
                              raise Control.Bug "structure does not match signature in StrEnv"
                            | SOME (T.STRUCTURE{env=strEnv,...}) => 
                              ID.Map.unionWith #1 (
                                                   newTyBindsMap, 
                                                   substTyEnvFromEnv (sigEnv,strEnv)
                                                   )
                        )
                        substTyEnv1
                        sigStrEnv
      in
        substTyEnv2
      end

    fun instantiateTy substTyEnv ty =
        let
          val (ty, visited) = TCU.substTyConInTy ID.Set.empty substTyEnv ty
        in 
          ty
        end

    fun instantiateBtvKind substTyEnv btvKind = 
        let
          val (visited, btvKind) =
              TCU.substTyConInBtvKind ID.Set.empty substTyEnv btvKind
        in
          btvKind
        end
          
    fun instantiateTyCon substTyEnv tyCon =
        let
          val (visited,tyCon) =  TCU.substTyConInTyCon ID.Set.empty substTyEnv tyCon
        in
          tyCon
        end

    fun fixPathVarEnv pathVarEnv (context:MC.context) pathIdEnv pathHoleIdEnv substTyEnv =
        SEnv.foldli (
                     fn (varName, 
                         PE.CurItem (pathVarInfo as ((strPath,vName), id, ty, loc)), 
                         newPathVarEnv)
                        =>
                        (
                         case ID.Map.find(pathIdEnv, id) of
                           SOME (displayName, newValId) =>
                           (* declared value identifier inside functor body *)
                           let
                             val newStrPath =
                                 PE.joinPrefix (#prefix context) (PE.getTailPrefix strPath)
                           in
                             SEnv.insert(
                                         newPathVarEnv,
                                         varName,
                                         PE.CurItem ((newStrPath, vName), 
                                                     newValId,
                                                     instantiateTy substTyEnv ty,
                                                     loc)
                                         )
                           end
                         | NONE => 
                           case ID.Map.find(pathHoleIdEnv, id) of
                             (* functor argument provides the actual value id *)
                             SOME item =>
                             SEnv.insert(newPathVarEnv, varName, item)
                           | NONE => 
                             raise Control.Bug
                                     ("unbound identifier:" ^ PE.pathVarToString(strPath,vName))
                        )
                      | (varName, PE.TopItem item, newPathVarEnv) =>
                        (* if functor body is a structure of previous compilation 
                         * unit, then untouched
                         *) 
                        SEnv.insert(newPathVarEnv, varName, PE.TopItem item)
                    ) 
                    SEnv.empty
                    pathVarEnv

    fun fixPathStrEnv pathStrEnv context declaredValIdSubst pathHoleIdEnv substTyEnv =
        SEnv.foldli (
                     fn (str, PE.PATHAUX (pathVarEnv,pathStrEnv), newPathStrEnv) =>
                        let
                          val fixedPathVarEnv = 
                              fixPathVarEnv 
                                pathVarEnv context declaredValIdSubst pathHoleIdEnv substTyEnv
                          val fixedPathStrEnv = 
                              fixPathStrEnv 
                                pathStrEnv context declaredValIdSubst pathHoleIdEnv substTyEnv
                        in
                          SEnv.insert(
                                      newPathStrEnv,
                                      str,
                                      PE.PATHAUX (fixedPathVarEnv,fixedPathStrEnv)
                                      )
                        end
                    )
                    SEnv.empty
                    pathStrEnv
  end
end
