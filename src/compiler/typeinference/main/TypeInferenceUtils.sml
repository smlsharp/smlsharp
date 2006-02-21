(**
 * Copyright (c) 2006, Tohoku University.
 *
 * utility functions for manupilating types (needs re-writing).
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypeInferenceUtils.sml,v 1.24 2006/02/18 04:59:34 ohori Exp $
 *)
structure TypeInferenceUtils =
struct
  local 
    structure PT = PatternCalcWithTvars
    open Types StaticEnv TypesUtils TypedCalc
  in
  
  val dummyTyId = ref 0
  fun nextDummyTy () = DUMMYty (!dummyTyId) before dummyTyId := !dummyTyId + 1

  val NAME_OF_ANONYMOUS_FUNCTOR_PARAMETER = "X?" 

  fun stripSignature tpmstrexp =
      case tpmstrexp of
        TPMOPAQCONS (tpmstrexp, tpmsigexp, sigenv, loc) => stripSignature tpmstrexp
      | TPMTRANCONS (tpmstrexp, tpmsigexp, sigenv, loc) => stripSignature tpmstrexp
      | _ => tpmstrexp

  fun isAnonymousStrExp ptstrexp =
      case ptstrexp of
        PT.PTSTREXPBASIC _ => true
      | PT.PTSTRID _ => false
      | PT.PTSTRTRANCONSTRAINT (ptstrexp,_,_) => isAnonymousStrExp ptstrexp
      | PT.PTSTROPAQCONSTRAINT (ptstrexp,_,_) => isAnonymousStrExp ptstrexp
      | PT.PTFUNCTORAPP _ => true
      | PT.PTSTRUCTLET (_, ptstrexp, _) => isAnonymousStrExp ptstrexp
  (*
   * make a fresh instance of ty by instantiating the top-level type
   * abstractions (only)
   *)
  fun freshTopLevelInstTy ty =
      case ty of
        (POLYty{boundtvars, body, ...}) =>
        let 
          val subst = freshSubst boundtvars
          val bty = substBTvar subst body
        in  
          (bty, IEnv.listItems subst)
        end
      | _ => (ty, nil)

  fun etaExpandCon (varStrPath,vid) loc idState = 
      case idState of
        CONID (conPathInfo as {name, strpath, funtyCon, ty, tag, tyCon}) =>
        let
          val termconPathInfo =
              {
                name = vid,
                strpath = varStrPath,
                funtyCon = funtyCon,
                ty = ty,
                tyCon = tyCon,
                tag = tag
              }
        in
          if funtyCon
          then
            case ty of
              POLYty{boundtvars, body = FUNMty([argTy], resultTy)} =>
              let
                val newVarPathInfo =
                  {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
              in
                (
                  ty,
                  TPPOLYFNM
                      {
                        btvEnv=boundtvars,
                        argVarList=[newVarPathInfo],
                        bodyTy=resultTy,
                        bodyExp=
                          TPCONSTRUCT
                           {
                            con=termconPathInfo,
                            instTyList=map BOUNDVARty (IEnv.listKeys boundtvars),
                            argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                            loc=loc
                            },
                        loc=loc
                      }
                )
              end
            | POLYty{boundtvars, body = FUNMty(_, ty)} =>
              raise Control.Bug "Uncurried fun type in OPRIM"
            | FUNMty([argTy], resultTy) => (* ty should be mono; data constructor has a closed type *)
              let
                val newVarPathInfo =
                  {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
              in
                (
                  ty,
                  TPFNM
                  {
                   argVarList=[newVarPathInfo],
                   bodyTy=resultTy,
                   bodyExp=
                     TPCONSTRUCT
                     {
                       con=termconPathInfo,
                       instTyList=nil,
                       argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                       loc=loc
                      },
                     loc=loc
                     }
                  )
              end
            | FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
            | _ => raise Control.Bug "datacon type"
          else (ty, TPCONSTRUCT{con=termconPathInfo, instTyList=nil, argExpOpt=NONE, loc=loc})
        end
      | PRIM (primInfo as {name, ty}) =>
        (case ty of
           POLYty{boundtvars, body = FUNMty([argTy], resultTy)} =>
           let
             val newVarPathInfo  = 
                 {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
           in
             (
               ty,
               TPPOLYFNM
                  {
                    btvEnv=boundtvars,
                    argVarList=[newVarPathInfo],
                    bodyTy=resultTy,
                    bodyExp=
                      TPPRIMAPPLY
                      {
                       primOp=primInfo,
                       instTyList=map BOUNDVARty (IEnv.listKeys boundtvars),
                       argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                       loc=loc
                       },
                     loc=loc
                   }
             )
           end
         | POLYty{boundtvars, body = FUNMty(_, ty)} =>
             raise Control.Bug "Uncurried fun type in OPRIM"
         | FUNMty([argTy], resultTy) =>
           let
             val newVarPathInfo =
                 {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
           in
             (
               ty,
               TPFNM
                   {
                     argVarList=[newVarPathInfo],
                     bodyTy=resultTy,
                     bodyExp=
                       TPPRIMAPPLY
                         {
                           primOp=primInfo,
                           instTyList=nil,
                           argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                           loc=loc
                         },
                     loc=loc
                   }
             )
           end
         | FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
         | _ =>raise Control.Bug "datacon type"
        )
      | OPRIM (oprimInfo as {name, ty, instances}) =>
          let
            val (instTy, instTyList) = freshTopLevelInstTy ty
          in
            case instTy of
              FUNMty([argTy], resultTy) =>
                let
                  val newVarPathInfo =
                    {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
                in
                  (
                   instTy,
                   TPFNM
                   {
                    argVarList=[newVarPathInfo],
                    bodyTy=resultTy,
                    bodyExp=
                    TPOPRIMAPPLY
                    {
                     oprimOp=oprimInfo,
                     instances=instTyList,
                     argExpOpt=SOME (TPVAR (newVarPathInfo, loc)),
                     loc=loc
                     },
                    loc=loc
                    }
                   )
                end
            | FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in OPRIM"
            | _ =>raise Control.Bug "oprim type"
          end
      | FFID (foreignFunPathInfo as {name, strpath, ty, argTys}) =>
        (case ty of
           FUNMty([argTy], resultTy) =>
           let
             val funVarPathInfo =
                 {name = name, strpath = varStrPath, ty = ty}
             val funVarExp = TPVAR(funVarPathInfo, loc)
             val newVarPathInfo =
                 {name = Vars.newTPVarName(), strpath = NilPath, ty = argTy}
           in
             (
               ty,
               TPFNM
                   {
                     argVarList=[newVarPathInfo],
                     bodyTy=resultTy,
                     bodyExp=
                       TPFOREIGNAPPLY
                         {
                           funExp=funVarExp,
                           instTyList=nil,
                           argExp=TPVAR (newVarPathInfo, loc),
                           argTyList=argTys,
                           loc=loc
                         },
                     loc=loc
                   }
             )
           end
         | FUNMty(_,_) =>raise Control.Bug "Uncurried fun type in FFID"
         | _ =>raise Control.Bug "datacon type")
      | RECFUNID _ => raise Control.Bug "recfunid in etaExpandCon"
      | VARID _ => raise Control.Bug "var in etaExpandCon"

end
end
