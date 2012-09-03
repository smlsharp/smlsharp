(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypeInferenceContext.sml,v 1.32 2008/05/31 12:18:23 ohori Exp $
 *)
structure TypeInferenceContext =
struct
  local
    structure TC = TypeContext
    structure T = Types
    structure TU = TypesUtils
    structure NM = NameMap
    structure NPEnv = NameMap.NPEnv
    structure P = Path
  in

  type currentContext = 
       {
        utvarEnv:T.utvEnv,
        tyConEnv:T.tyConEnv,
        varEnv:T.varEnv,
        sigEnv:T.sigEnv,
        funEnv:T.funEnv
       }

  type basis = {global : TC.topContext, 
                current : currentContext}

  val emptyCurrentContext = 
      {
       utvarEnv = SEnv.empty,
       tyConEnv = T.emptyTyConEnv,
       varEnv = T.emptyVarEnv,
       sigEnv = T.emptySigEnv,
       funEnv = T.emptyFunEnv
       } : currentContext

  local
      val initialCurrentContext =
          {
           utvarEnv = SEnv.empty,
           tyConEnv = T.emptyTyConEnv,
           varEnv = T.emptyVarEnv,
           sigEnv = T.emptySigEnv,
           funEnv = T.emptyFunEnv
           } : currentContext
  in
       fun makeInitialBasis globalContext =
           {global = globalContext, 
            current = initialCurrentContext
           }
  end

  fun bindTyConInCurrentContext 
          ({utvarEnv, tyConEnv, varEnv, sigEnv, funEnv } : currentContext,
           namePath, tyCon) = 
          {
           utvarEnv = utvarEnv,
           tyConEnv = NPEnv.insert(tyConEnv, namePath, tyCon),
           varEnv = varEnv,
           sigEnv = sigEnv,
           funEnv = funEnv
           }:currentContext

  local
      fun bindVarInCurrentContext 
              (lambdaDepth,
               {utvarEnv, tyConEnv, varEnv, sigEnv, funEnv} : currentContext,
               namePath, 
               idstate)
        = 
        (
         TU.adjustDepthInIdstate lambdaDepth idstate;
         {
          utvarEnv = utvarEnv,
          tyConEnv = tyConEnv,
          varEnv = NPEnv.insert(varEnv, namePath, idstate),
          sigEnv = sigEnv,
          funEnv = funEnv
          }:currentContext
            )
  in
     fun bindVarInBasis (lambdaDepth, basis:basis, varName, idstate) =
         {global = #global basis, 
          current = bindVarInCurrentContext(lambdaDepth, 
                                            #current basis,
                                            varName,
                                            idstate)
          }:basis
  end

  fun bindSigInCurrentContext 
          ({
            utvarEnv,
            tyConEnv, 
            varEnv, 
            sigEnv,
            funEnv
            } : currentContext,
           string, 
           sigexp) 
    = 
    {
     utvarEnv = utvarEnv,
     tyConEnv = tyConEnv,
     varEnv = varEnv,
     sigEnv = SEnv.insert(sigEnv, string, sigexp),
     funEnv = funEnv
     }

  fun extendCurrentContextWithVarEnv
          (
           {utvarEnv, tyConEnv, varEnv, sigEnv, funEnv} : currentContext,
           newVarEnv
           ) = 
          {
           utvarEnv = utvarEnv,
           tyConEnv = tyConEnv,
           varEnv = NPEnv.unionWith #1 (newVarEnv, varEnv),
           sigEnv = sigEnv,
           funEnv = funEnv
           }

  fun extendBasisWithVarEnv (basis:basis, newVarEnv) =
      {global = #global basis,
       current = extendCurrentContextWithVarEnv (#current basis, newVarEnv)
       }:basis
      
  fun extendCurrentContextWithTyConEnv 
          (
           {utvarEnv, tyConEnv, varEnv, sigEnv, funEnv} : currentContext,
           newTyConEnv
           ) = 
          {
           utvarEnv = utvarEnv,
           tyConEnv = NPEnv.unionWith #1 (newTyConEnv, tyConEnv),
           varEnv = varEnv,
           sigEnv = sigEnv,
           funEnv = funEnv
           }

  fun extendBasisWithTyConEnv (basis:basis, newTyConEnv) =
      {global = #global basis,
       current = extendCurrentContextWithTyConEnv (#current basis, newTyConEnv)
       } :basis

  fun extendCurrentContextWithUtvarEnv
          (
           {
            utvarEnv, 
            tyConEnv,
            varEnv,
            sigEnv,
            funEnv
            } : currentContext,
           newUtvarEnv
           )
    =
    {
     utvarEnv = SEnv.unionWith #1 (newUtvarEnv, utvarEnv),
     tyConEnv = tyConEnv,
     varEnv = varEnv,
     sigEnv = sigEnv,
     funEnv = funEnv
     }

  fun overrideCurrentContextWithUtvarEnv
          (
           {
            utvarEnv, 
            tyConEnv,
            varEnv,
            sigEnv,
            funEnv
            } : currentContext,
           newUtvarEnv
           )
    =
    {
     utvarEnv = newUtvarEnv,
     tyConEnv = tyConEnv,
     varEnv = varEnv,
     sigEnv = sigEnv,
     funEnv = funEnv
     }

  fun extendBasisWithUtvarEnv (basis:basis, newUtvarEnv) =
      {global = #global basis,
       current = extendCurrentContextWithUtvarEnv (#current basis, newUtvarEnv)
      }: basis
      
  fun overrideBasisWithUtvarEnv (basis:basis, newUtvarEnv) =
      {global = #global basis,
       current = overrideCurrentContextWithUtvarEnv
                   (#current basis, newUtvarEnv)
      }: basis
      
  fun extendCurrentContextWithBasicEnv 
          (
           {
            utvarEnv, 
            tyConEnv, 
            varEnv, 
            sigEnv, 
            funEnv
            }
           : currentContext,
           (newTyConEnv, newVarEnv))
    =
    {
     utvarEnv = utvarEnv, 
     tyConEnv = NPEnv.unionWith #1 (newTyConEnv, tyConEnv),
     varEnv =  NPEnv.unionWith #1 (newVarEnv, varEnv),
     sigEnv = sigEnv,
     funEnv = funEnv
     }

  fun extendCurrentContextWithContext 
          (
           {
            utvarEnv, 
            tyConEnv, 
            varEnv, 
            sigEnv, 
            funEnv
            }
           : currentContext,
           {
            tyConEnv = newTyConEnv, 
            varEnv = newVarEnv,
            sigEnv = newSigEnv, 
            funEnv = newFunEnv
            }
           : TC.context
             )
          =
          {
           utvarEnv = utvarEnv, 
           tyConEnv = NPEnv.unionWith #1 (newTyConEnv, tyConEnv),
           varEnv =  NPEnv.unionWith #1 (newVarEnv, varEnv),
           sigEnv = SEnv.unionWith #1 (newSigEnv, sigEnv),
           funEnv = SEnv.unionWith #1 (newFunEnv, funEnv)
           }

  fun injectContextToCurrentContext
          (
           { 
            tyConEnv,
            varEnv, 
            sigEnv, 
            funEnv
            } : TC.context
                )
    =
    {
     utvarEnv = SEnv.empty : T.utvEnv, 
     tyConEnv = tyConEnv : T.tyConEnv,
     varEnv =  varEnv : T.varEnv,
     sigEnv = sigEnv : T.sigEnv,
     funEnv = funEnv : T.funEnv
                       }

  fun injectContextToBasis ({tyConEnv, varEnv, sigEnv, funEnv} : TC.context) 
    =
    {
     global = TypeContext.emptyTopContext,
     current = {utvarEnv = SEnv.empty : T.utvEnv, 
                tyConEnv = tyConEnv : T.tyConEnv,
                varEnv =  varEnv : T.varEnv,
                sigEnv = sigEnv : T.sigEnv,
                funEnv = funEnv : T.funEnv}
    }:basis

  fun injectBasicEnvToBasis (tyConEnv, varEnv)  =
      {
       global = TypeContext.emptyTopContext,
       current = {utvarEnv = SEnv.empty : T.utvEnv, 
                  tyConEnv = tyConEnv : T.tyConEnv,
                  varEnv =  varEnv : T.varEnv,
                  sigEnv = SEnv.empty : T.sigEnv,
                  funEnv = SEnv.empty : T.funEnv}
       }:basis

  fun extendBasisWithContext (basis : basis, context) =
      {global = #global basis,
       current = extendCurrentContextWithContext (#current basis, context)
      }:basis

  fun extendBasisWithBasicEnv (basis : basis, basicEnv) =
      {global = #global basis,
       current = extendCurrentContextWithBasicEnv (#current basis, basicEnv)
      }:basis

  fun extendBasisWithUtvarEnv (basis : basis, utvarEnv) =
      {global = #global basis,
       current = extendCurrentContextWithUtvarEnv (#current basis, utvarEnv)
      }:basis
      
  fun lookupVarInBasis (basis:basis, namePath) = 
      if P.isExternPath (#2 namePath) then
          SEnv.find(#varEnv(#global basis), NameMap.namePathToString(NM.getTailNamePath namePath))
      else NPEnv.find(#varEnv(#current basis), namePath)
           
  fun lookupTyConInBasis (basis:basis, namePath : NM.namePath) =
      if P.isExternPath (#2 namePath) then
          SEnv.find(#tyConEnv(#global basis), NameMap.namePathToString(NM.getTailNamePath namePath))
      else NPEnv.find(#tyConEnv(#current basis), namePath) 
           
  fun lookupUtvarInCurrentContext ({utvarEnv,...} : currentContext, string) =
      case SEnv.find(utvarEnv, string) of
          SOME tvStateRef => SOME(T.TYVARty tvStateRef)
        | NONE => NONE

  fun lookupUtvarInBasis (basis : basis, utvar) =
      lookupUtvarInCurrentContext(#current basis, utvar)

  fun lookupSigmaInBasis (basis : basis, sigName) = 
      case SEnv.find(#sigEnv (#current basis), sigName) of
          SOME x => SOME x
        | NONE => SEnv.find(#sigEnv (#global basis), sigName)

  fun lookupFunctor ({funEnv,...}:currentContext, funName) =
      SEnv.find(funEnv, funName) 

  fun lookupFunctorInBasis (basis : basis, funName) =
      case SEnv.find(#funEnv(#current basis), funName) of
          SOME x => SOME x
        | NONE => SEnv.find(#funEnv(#global basis), funName)

  (* ToDo : this function and addUtvarIfNotThere should be refactored to share codes. *)
  local
      fun addUtvarOverrideInCurrentContext 
              (lambdaDepth, {utvarEnv, tyConEnv, varEnv, sigEnv, funEnv}, kindedTvarSet) 
              loc =
          let
              val (newUtvarEnv, addedUtvars) = 
                  SEnv.foldli
                      (fn (
                           string, 
                           {eqKind, recordKind},
                           (newUtvarEnv, addedUtvars)
                           ) =>
                          let 
                              val newTvStateRef =
                                  T.newUtvar (lambdaDepth, 
                                              if eqKind = Absyn.EQ then T.EQ else T.NONEQ, 
                                              string)
                          in 
                              (SEnv.insert(newUtvarEnv, string, newTvStateRef),
                               SEnv.insert(addedUtvars, string, (newTvStateRef, recordKind))
                               )
                          end)
                      (utvarEnv, SEnv.empty)
                      kindedTvarSet
          in
              ({
                utvarEnv = newUtvarEnv, 
                tyConEnv=tyConEnv, 
                varEnv=varEnv, 
                sigEnv=sigEnv,
                funEnv = funEnv
                }:currentContext,
               addedUtvars)
          end
  in
    fun addUtvarOverride  (lambdaDepth, basis:basis, kindedTvarSet) loc =
        let
            val (newCC, addedUtvars) = 
                addUtvarOverrideInCurrentContext 
                    (lambdaDepth, #current basis, kindedTvarSet) 
                    loc 
        in
            ({global = #global basis, 
              current = newCC
             } : basis, 
             addedUtvars)
        end
  end          

  local
      fun addUtvarIfNotthereInCurrentContext 
        (lambdaDepth, {utvarEnv, tyConEnv, varEnv, sigEnv, funEnv}, tvarNameSet) 
        =
        let
            val (newUtvarEnv, addedUtvars) = 
                SEnv.foldli
                    (fn (string, eq, (newUtvarEnv, addedUtvars)) =>
                        if SEnv.inDomain(newUtvarEnv, string)
                        then (newUtvarEnv, addedUtvars)
                        else
                            let
                                val newTvStateRef =
                                    T.newUtvar (lambdaDepth,
                                                if eq = Absyn.EQ then T.EQ else T.NONEQ, 
                                                string)
                            in 
                                (
                                 SEnv.insert(newUtvarEnv, string, newTvStateRef),
                                 SEnv.insert(addedUtvars, string, newTvStateRef)
                                 )
                            end)
                    (utvarEnv, SEnv.empty)
                    tvarNameSet
        in
            ({utvarEnv = newUtvarEnv, 
              tyConEnv = tyConEnv,
              varEnv=varEnv, 
              sigEnv = sigEnv, 
              funEnv = funEnv
              }:currentContext,
             addedUtvars)
        end
  in
     fun addUtvarIfNotthere (lambdaDepth, basis:basis, tvarNameSet)  =
      let
          val (newCC, addedUtvars) = 
              addUtvarIfNotthereInCurrentContext (lambdaDepth, #current basis, tvarNameSet) 
      in
          ({global = #global basis, 
            current = newCC
           } : basis, 
           addedUtvars)
      end
  end

end
end
