(**
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author YAMATODANI Kiyoshi
 * @version $Id: InitialTypeContext.sml,v 1.63 2008/05/31 12:18:23 ohori Exp $
 *)
structure InitialTypeContext =
struct
 
local
  structure TY = Types
  structure TP = TypeParser
  structure P = Path
  structure PT = PredefinedTypes
  structure TU = TypesUtils
  structure TC = TypeContext
  structure NM = NameMap
  structure NPEnv = NameMap.NPEnv
in

  type topTypeContext =
       {
        varEnv : TY.topVarEnv,
        tyConEnv : TY.topTyConEnv,
        sigEnv : TY.sigEnv, 
        funEnv : TY.funEnv
        }

  val emptyTopTypeContext = 
      {
       varEnv = SEnv.empty : TY.topVarEnv,
       tyConEnv = SEnv.empty : TY.topTyConEnv,
       sigEnv = SEnv.empty : TY.sigEnv, 
       funEnv = SEnv.empty : TY.funEnv
      } : topTypeContext

  val initialTopTypeContext =
      {
       tyConEnv = #topTyConEnv BuiltinContext.builtinContext,
       varEnv = #topVarEnv BuiltinContext.builtinContext,
       sigEnv = TY.emptySigEnv,
       funEnv = TY.emptyFunEnv
      } : topTypeContext


  local
      fun injectPathToTop path = 
          P.PSysStructure(P.externStrName, P.pathToUsrPath path)
          
      fun injectBtvKindToTop ({index, recordKind, eqKind} : TY.btvKind) =
          {
           index = index,
           recordKind = injectRecKindToTop recordKind,
           eqKind = eqKind
           }

      and injectRecKindToTop recordKind =
          case recordKind of
              TY.REC tyMap => TY.REC(SEnv.map injectTyToTop tyMap)
            | TY.OVERLOADED tys => TY.OVERLOADED (map injectTyToTop tys)
            | TY.UNIV => TY.UNIV

      and injectTyConToTop
              ({name, strpath, abstract, tyvars, id, eqKind, constructorHasArgFlagList} : TY.tyCon) =
              (
               {
                name = name,
                strpath = injectPathToTop strpath,
                abstract = abstract,
                tyvars = tyvars,
                id = id,
                eqKind = eqKind,
                constructorHasArgFlagList = constructorHasArgFlagList
                }
               )

      and injectTyToTop ty =
          case ty of
              TY.TYVARty(tyRef as ref(TY.SUBSTITUTED destTy)) =>
              (tyRef := TY.SUBSTITUTED(injectTyToTop destTy); ty)
            | TY.TYVARty(tyRef as ref(TY.TVAR _)) =>
              raise Control.Bug "free type varialbe in top level"
            | TY.FUNMty(domainTyList, rangeTy) =>
              TY.FUNMty(map injectTyToTop domainTyList, injectTyToTop rangeTy)
            | TY.RECORDty tyMap => TY.RECORDty(SEnv.map injectTyToTop tyMap)
            | TY.RAWty{tyCon, args} =>
              TY.RAWty {tyCon = injectTyConToTop tyCon, 
                        args = map injectTyToTop args}
            | TY.POLYty{boundtvars, body} =>
              TY.POLYty
                  {
                   boundtvars = IEnv.map injectBtvKindToTop boundtvars,
                   body = injectTyToTop body
                   }
            | TY.ALIASty(alias, actual) =>
              TY.ALIASty(injectTyToTop alias, injectTyToTop actual)
            | TY.OPAQUEty {spec = {tyCon, args}, implTy} =>
              TY.OPAQUEty {spec = {tyCon = injectTyConToTop tyCon, 
                                   args = map injectTyToTop args}, 
                           implTy = implTy}
            | TY.SPECty {tyCon, args} => 
              TY.SPECty {tyCon = tyCon, args = map injectTyToTop args}
            | TY.ERRORty => raise Control.Bug "ERRORty in top level"
            | TY.DUMMYty _ => ty
            | TY.BOUNDVARty _ => ty
                   
      and injectVarPathInfoToTop {namePath = (name, path), ty} =
          {
           namePath = (name, injectPathToTop path),
           ty = injectTyToTop ty
           }

      and injectConPathInfoToTop {namePath = (name, path), funtyCon, ty, tag, tyCon} =
          {
           namePath = (name, injectPathToTop path),
           funtyCon = funtyCon,
           ty = injectTyToTop ty,
           tag = tag,
           tyCon = injectTyConToTop tyCon
           }

      and injectIdStateToTop idState =
          case idState of 
              TY.VARID varPathInfo =>
              TY.VARID (injectVarPathInfoToTop varPathInfo)
            | TY.CONID conPathInfo =>
              TY.CONID (injectConPathInfoToTop conPathInfo)
            | TY.RECFUNID (varPathInfo, int) =>
              TY.RECFUNID (injectVarPathInfoToTop varPathInfo, int) 
            | other => other

      and injectDataConToTop varEnv =
          SEnv.map injectIdStateToTop varEnv
              
      and injectTyBindInfoToTop tyBindInfo =
          case tyBindInfo of
              TY.TYCON {tyCon, datacon} => 
              TY.TYCON {tyCon = (injectTyConToTop tyCon),
                        datacon = injectDataConToTop datacon}
            | TY.TYFUN tyFun => TY.TYFUN(injectTyFunToTop tyFun)
            | TY.TYSPEC tyCon => TY.TYSPEC (injectTyConToTop tyCon)
            | TY.TYOPAQUE {spec, impl} => TY.TYOPAQUE {spec = injectTyConToTop spec, impl = impl}
                                  
      and injectTyFunToTop ({name, strpath, tyargs, body} : TY.tyFun) =
          {
           name = name,
           strpath = injectPathToTop strpath,
           tyargs = IEnv.map injectBtvKindToTop tyargs,
           body = injectTyToTop body
           }

      fun injectIdstateToTop idstate =
          case idstate of
              TY.VARID varPathInfo =>
              TY.VARID (injectVarPathInfoToTop varPathInfo)
            | TY.CONID conPathInfo =>
              TY.CONID (injectConPathInfoToTop conPathInfo)
            | TY.RECFUNID (varPathInfo, int) =>
              TY.RECFUNID (injectVarPathInfoToTop varPathInfo, int) 
            | other => other
  in
      fun extendTopTypeContextWithContext 
              ({varEnv = topVarEnv,
                tyConEnv = topTyConEnv,
                sigEnv = topSigEnv, 
                funEnv = topFunEnv} : topTypeContext)
              {varEnv = newVarEnv, 
               tyConEnv = newTyConEnv, 
               sigEnv = newSigEnv,  
               funEnv = newFunEnv} =
              let
                  fun NPEnvToSEnv injectFunction npEnv =
                      NPEnv.foldli (fn (namePath, entry, newSEnv) =>
                                       SEnv.insert(newSEnv,
                                                   NM.usrNamePathToString namePath,
                                                   injectFunction entry))
                                   SEnv.empty
                                   npEnv
                  fun NPVarEnvToSEnv npEnv =
                      NPEnvToSEnv injectIdStateToTop npEnv
                  fun NPTyConEnvToSEnv npEnv =
                      NPEnvToSEnv injectTyBindInfoToTop npEnv
                  fun injectFunctorEnv functorEnv = 
                      SEnv.map (fn {funName, 
                                    argName,
                                    functorSig = {generativeExnTagSet,
		                                  argTyConIdSet,
		                                  argSigEnv,
                                                  argStrPrefixedEnv,
			                          body = (bodyTyConIdSet, bodyEnv)
                                                 }
                                   } : Types.funBindInfo =>
                                   let
                                       fun stripSysPathNPEnv injectFun NPVarEnv = 
                                           NPEnv.foldli (fn (namePath, idState, newNPVarEnv) =>
                                                            NPEnv.insert(newNPVarEnv,
                                                                         NameMap.namePathToUsrNamePath namePath,
                                                                         injectFun idState)
                                                        )
                                                        NPEnv.empty
                                                        NPVarEnv
                                   in
                                       {funName = funName, 
                                        argName = argName,
                                        functorSig = {generativeExnTagSet = generativeExnTagSet,
		                                      argTyConIdSet = argTyConIdSet,
		                                      argSigEnv = argSigEnv,
                                                      argStrPrefixedEnv = argStrPrefixedEnv,
			                              body = (bodyTyConIdSet, 
                                                              (
                                                               stripSysPathNPEnv injectTyBindInfoToTop (#1 bodyEnv),
                                                               stripSysPathNPEnv injectIdstateToTop (#2 bodyEnv)
                                                              )
                                                             )
                                                     }
                                       }   
                                   end)
                               functorEnv
              in
                  {
                   varEnv = SEnv.unionWith #1 (NPVarEnvToSEnv newVarEnv, topVarEnv),
                   tyConEnv = SEnv.unionWith #1 (NPTyConEnvToSEnv newTyConEnv, topTyConEnv),
                   sigEnv = SEnv.unionWith #1 (newSigEnv, topSigEnv),
                   funEnv = SEnv.unionWith #1 (injectFunctorEnv newFunEnv, topFunEnv)
                   }
              end
                  
      fun projectTypeContextInTopTypeContext {varEnv, tyConEnv, sigEnv, funEnv} =
          {funEnv = funEnv,
           tyConEnv = tyConEnv,
           varEnv = varEnv,
           sigEnv = sigEnv}
  end
end
end
