(**
 * a kinded type inference with type operators for ML core
 * (imperative version).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypeInferCore.sml,v 1.119.6.10 2010/02/10 05:17:29 hiro-en Exp $
 *)
structure TypeInferCore  =
struct
local 
  structure T = Types
  structure A = Absyn
  structure E = TypeInferenceError
  structure P = Path
  structure PDT = PredefinedTypes
  structure PT = PatternCalcWithTvars
  structure TB = TypeinfBase
  structure TIC = TypeInferenceContext
  structure TPU = TypedCalcUtils
  structure ITC = InitialTypeContext
  structure U = Unify
  structure UE = UserError 
  structure TIT = TypeInstantiationTerm
  structure TIU = TypeInferenceUtils
  structure TU = TypesUtils
  structure TC = TypeContext
  structure TCU = TypeContextUtils
  structure CT = ConstantTerm
  structure NM = NameMap
  structure NPEnv = NM.NPEnv
  structure NPSet = NM.NPSet
  structure PCF = PatternCalcFlattened

  exception CyclicReckindSpec of string

  val emptyContext = TC.emptyContext

  open TypedCalc

  val maxDepth = ref 0
  fun incDepth () = (maxDepth := !maxDepth + 1; !maxDepth)

  val ffiApplyTyvars = ref nil : (T.ty * Loc.loc) list ref

in
 (* for debugging *)
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

  fun bug s = Control.Bug ("TypeInferCode: " ^ s)

 (* type generalization *)
  fun generalizer (ty, lambdaDepth) =
    if E.isError()
      then {boundEnv = IEnv.empty, removedTyIds = OTSet.empty}
    else 
      let
        val newTy = TypesUtils.generalizer (ty, lambdaDepth)
      in
        newTy
      end

  type rawty = A.ty

  fun getRuleLocM nil = raise bug "empty rule in getRuleLocM"
    | getRuleLocM [(pat::_,exp)] =
        Loc.mergeLocs (PT.getLocPat pat, PT.getLocExp exp)
    | getRuleLocM rules =
        let
          val pat1 = 
            case rules of
              (pat1::_, _):: _ => pat1
            | _ =>
                raise
                  bug
                  "empty pattern in rules\
                  \ (typeinference/main/TypeInferCore.sml)"
          val (_, exp2) = List.last rules
        in
          Loc.mergeLocs (PT.getLocPat pat1, PT.getLocExp exp2)
        end

  fun evalRawty (basis : TIC.basis) rawty =
    case rawty of
        (* Since this is a wild type annotation, we use infinite lambda
           depth here *)
        A.TYWILD loc => T.newtyWithLambdaDepth (T.infiniteDepth, T.univKind)
      | A.TYID ({name=string,eq}, loc) =>
        (case TIC.lookupUtvarInBasis (basis, string) of
           NONE =>
             (E.enqueueError(loc, E.NotBoundTyvar{tyvar = string}); T.ERRORty)
         | SOME ty => 
             if eq = Absyn.EQ  then 
               if TU.admitEqTy ty then ty
               else (
                     E.enqueueError
                      (loc,E.InconsistentEQInDatatype {tyvar = string});
                     T.ERRORty
                    )
             else 
               if TU.admitEqTy ty then 
                 (
                  E.enqueueError
                    (loc,E.InconsistentEQInDatatype {tyvar = string});
                  T.ERRORty
                  )
               else ty
             )
      | A.TYRECORD (nil, loc) => PDT.unitty
      | A.TYRECORD (stringRawtyList, loc) =>
          T.RECORDty
          (foldr
           (fn ((l, rawty), fields) => 
             SEnv.insert (fields, l, evalRawty basis rawty))
           SEnv.empty
           stringRawtyList)
      | A.TYCONSTRUCT (rawtyList, namePath, loc) =>
          raise bug "Absyn.TYCONSTRUCT"
      | A.TYCONSTRUCT_WITH_NAMEPATH (rawtyList, namePath, loc) =>
          let
            val tyList = map (evalRawty basis) rawtyList
          in
            case TIC.lookupTyConInBasis(basis, namePath) of
              SOME(T.TYCON {tyCon, datacon}) =>
                let
                  val wants = List.length (#tyvars tyCon)
                  val given = List.length tyList
                in
                  if wants = given
                    then T.RAWty{tyCon = tyCon, args = tyList}
                    (*  
                     *  Why tyCon is re-calculated here? 
                     *
                     then
                      T.RAWty
                        {
                         tyCon = {name = #name tyCon,
                                  strpath = #strpath tyCon,
                                  id = #id tyCon,
                                  abstract = #abstract tyCon,
                                  eqKind = #eqKind tyCon,
                                  tyvars = #tyvars tyCon,
                                  constructorHasArgFlagList =
                                    SOME (SEnv.numItems datacon)
                                  }, 
                         args = tyList
                        }
                      *)
                  else
                    (
                     E.enqueueError
                     (
                      loc, 
                      E.ArityMismatchInTypeDeclaration
                      {
                       wants = wants,
                       given = given,
                       tyCon = NM.usrNamePathToString(namePath)
                       }
                      ); 
                     T.ERRORty
                     )
                end
              | SOME(T.TYFUN {tyargs = btvKindIEnvMap, body = ty,...}) => 
                let
                  val intList = IEnv.listKeys btvKindIEnvMap
                  val wants = List.length intList
                  val given = List.length tyList
                in
                  if wants = given
                    then
                      TU.substBTvar
                      (foldr
                        (fn ((tid, ty), tyIEnvMap)
                          => IEnv.insert(tyIEnvMap, tid, ty))
                        IEnv.empty
                        (ListPair.zip (intList, tyList))
                       )
                      ty
                  else
                    (
                     E.enqueueError
                     (
                      loc, 
                      E.ArityMismatchInTypeDeclaration
                      {
                       wants = wants,
                       given = given,
                       tyCon = NM.usrNamePathToString(namePath)
                       }
                      );
                     T.ERRORty
                     )
                end
              | SOME(T.TYOPAQUE {spec = tyCon, impl}) => 
                let
                  val wants = List.length (#tyvars tyCon)
                  val given = List.length tyList
                in
                  if wants = given
                    then 
                      case (TU.peelTyOPAQUE impl) of
                        T.TYFUN tyFun =>
                          let
                            val implTy = TU.betaReduceTy (tyFun,tyList)
                          in
                            T.OPAQUEty {spec = {tyCon = tyCon, args = tyList},
                                        implTy = implTy}
                          end
                      | (T.TYCON {tyCon = tyCon', datacon}) =>
                          T.OPAQUEty
                            {spec = {tyCon = tyCon, args = tyList}, 
                             implTy = T.RAWty {tyCon = tyCon', args = tyList}}
                      | (T.TYSPEC tyCon') => 
                          T.OPAQUEty
                            {spec = {tyCon = tyCon, args = tyList}, 
                             implTy = T.SPECty {tyCon = tyCon', args = tyList}}
                      | (T.TYOPAQUE _) =>
                          raise
                            bug "TYOPAQUE occurs after peelTyOPAQUE"
                  else
                    (
                     E.enqueueError
                     (
                      loc, 
                      E.ArityMismatchInTypeDeclaration
                      {
                       wants = wants,
                       given = given,
                       tyCon = NM.usrNamePathToString(namePath)
                       }
		      ); 
                     T.ERRORty
                     )
                end
              | SOME(T.TYSPEC tyCon) =>
                let
                  val wants = List.length (#tyvars tyCon)
                  val given = List.length tyList
                in
                  if wants = given
                    then T.SPECty {tyCon = tyCon, args = tyList}
                  else
                    (
                     E.enqueueError
                       (
                        loc, 
                        E.ArityMismatchInTypeDeclaration
                          {
                           wants = wants,
                           given = given,
                           tyCon = NM.usrNamePathToString(namePath)
                           }
                          ); 
                     T.ERRORty
                    )
                end
              | NONE => 
                (
                 E.enqueueError
                   (loc,
                    E.TyConNotFoundInRawTy
                      {tyCon = NM.usrNamePathToString(namePath)});
                 T.ERRORty
                )
          end
      | A.TYTUPLE (rawtyList, loc) =>
          T.RECORDty
          (#2
           (foldl
            (fn (rawty, (n, tyFields)) => 
             (
              n + 1,
              SEnv.insert
              (tyFields, Int.toString n, evalRawty basis rawty))
             )
            (1, SEnv.empty)
            rawtyList))
      | A.TYFUN (rawty1, rawty2, loc) =>
          T.FUNMty([evalRawty basis rawty1], evalRawty basis rawty2)
      | A.TYFFI (attributes, _, domTys, ranTy, loc) =>
         (* Although TYFFI has no denotation, we return T.FUNMty here
          * in order to detect un-interoperable type construction at
          *  foreign function stub generation.
          *)
         evalRawty basis (A.TYFUN (A.TYTUPLE(domTys, loc), ranTy, loc))
      | A.TYPOLY (kindedTvarList, ty, loc) => 
        (
         case kindedTvarList of
           nil => evalRawty basis ty
         | _ =>
         (
          let
            fun extendKindedTvarSet (({name, eq},tvarKind), kindedTvarSet) = 
              SEnv.unionWith
              (fn _ => raise E.DuplicateUserTvars {tyvar = name})
              (SEnv.singleton
                 (name, {eqKind = eq, recordKind = tvarKind}), kindedTvarSet)
            val kindedTvarSet =
              foldr extendKindedTvarSet SEnv.empty kindedTvarList
            val (newBasis, tids) =
              (* lambda depth is not used since the set of type variables to
               * be bound are those listed in kindedeTvarList
               *)
              evalKindedTvarSet T.infiniteDepth basis kindedTvarSet loc
            val newTy = evalRawty newBasis ty
            val btvs =
              SEnv.foldl
              (
               fn (r as ref(T.TVAR (k as {id, ...})), btvs) =>
                  let 
                    val btvid = Counters.nextBTid ()
                  in
                    (
                     r := T.SUBSTITUTED (T.BOUNDVARty btvid);
                     (
                      IEnv.insert
                      (
                       btvs,
                       btvid,
                       {
                        recordKind = (#recordKind k),
                        eqKind = (#eqKind k)
                        }
                       )
                      )
                     )
                  end
               | _ => raise bug "generalizeTy"
              )
              IEnv.empty
              tids
          in
            T.POLYty {boundtvars = btvs, body = newTy}
          end
        handle E.DuplicateUserTvars {tyvar} =>
          (
           E.enqueueError (loc, E.DuplicateUserTvars {tyvar = tyvar});
           T.ERRORty
           )
       )
      ) (* end of the case TYPOLY *)
          
  and evalReckind (basis:TIC.basis) reckind =
    case reckind of
      A.UNIV => T.UNIV
    | A.REC fields => 
        T.REC 
        (foldl 
         (fn ((l,ty), tySEnv) => SEnv.insert(tySEnv, l, evalRawty basis ty))
         SEnv.empty
         fields)

  and evalKindedTvarSet lambdaDepth (basis:TIC.basis) kindedTvarSet  loc =
    let
      fun occurresTvarInReckind (tvstateRef, T.UNIV) = false
        | occurresTvarInReckind (tvstateRef, T.OCONSTkind tyList) =
          Unify.occurresTyList tvstateRef tyList
        | occurresTvarInReckind (tvstateRef, T.OPRIMkind {instances,...}) =
          Unify.occurresTyList tvstateRef instances
        | occurresTvarInReckind (tvstateRef, T.REC fields) =
          Unify.occurres tvstateRef (T.RECORDty fields)
      fun setReckind (
                       tvstateRef
                         as (ref (T.TVAR{lambdaDepth,
                                         id,
                                         recordKind,
                                         eqKind,
                                         tyvarName})), 
                       newReckind
                       )
                      =
            if occurresTvarInReckind (tvstateRef, newReckind) then
              raise
                CyclicReckindSpec
                 ((case eqKind of T.EQ => "''" | T.NONEQ  => "'") ^ 
                  (case tyvarName of SOME string => string | NONE => ""))
            else 
              tvstateRef := T.TVAR{
                                   lambdaDepth = lambdaDepth, 
                                   id = id, 
                                   recordKind = newReckind, 
                                   eqKind = eqKind, 
                                   tyvarName = tyvarName
                                  }
        | setReckind _ =
              raise bug "tvsteteRef must be TVAR in setRecKind"
      val (newBasis, newTvarReckindSEnv) =
        TIC.addUtvarOverride (lambdaDepth, basis, kindedTvarSet) loc
      val newTvarReckindSEnv =
        SEnv.map
        (fn (newTvstateRef, reckind)
           => (newTvstateRef, evalReckind newBasis reckind))
        newTvarReckindSEnv
      val newUtvarSet = 
          SEnv.map (fn (newTvstateRef, reckind) => 
                    (setReckind (newTvstateRef, reckind);
                     newTvstateRef)
                    )
          newTvarReckindSEnv
    in
      (newBasis, newUtvarSet)
    end
  handle CyclicReckindSpec string => 
            (
             E.enqueueError
             (
              loc,
              E.CyclicReckindSpec string
              );
             (basis, SEnv.empty)
             )

  fun isVar ptexp = 
      case ptexp of
        PT.PTVAR _ => true
      | PT.PTTYPED (ptexp, _, _) => isVar ptexp
      | _ => false

  fun stripRawty ptexp = 
      let 
        fun strip ptexp rawTyList = 
          case ptexp of
            PT.PTVAR (path, loc) => (path, loc, rawTyList)
          | PT.PTTYPED (ptexp, rawty, _) => strip ptexp (rawty :: rawTyList)
          | _ => raise bug "not var in stripRwaTy"
      in
        strip ptexp nil
      end

  fun expansiveCon (conPathInfo : conPathInfo) =
      TyConID.eq (#id(#tyCon conPathInfo), #id (PDT.refTyCon))

  fun expansiveExnCon (exnPathInfo : exnPathInfo) =
      TyConID.eq (#id(#tyCon exnPathInfo), #id (PDT.refTyCon))

  fun expansive tpexp =
      case tpexp of 
        TPFOREIGNAPPLY _ => true
      | TPEXPORTCALLBACK _ => true
      | TPSIZEOF _ => true
      | TPERROR => true
      | TPCONSTANT _ => false
      | TPGLOBALSYMBOL _ => false
      | TPVAR _ => false
      | TPRECFUNVAR _ => false
      | TPPRIMAPPLY _ => true
      | TPOPRIMAPPLY _ => true
      | TPDATACONSTRUCT {con, instTyList, argExpOpt=NONE, loc} => false
      | TPEXNCONSTRUCT {exn, instTyList, argExpOpt=NONE, loc} => false
      | TPDATACONSTRUCT {con, instTyList, argExpOpt= SOME tpexp, loc} => 
          expansiveCon con orelse expansive tpexp
      | TPEXNCONSTRUCT {exn, instTyList, argExpOpt= SOME tpexp, loc} => 
          expansiveExnCon exn orelse expansive tpexp
      | TPAPPM _ => true
      | TPMONOLET {binds=varPathInfoTpexpList, bodyExp=tpexp, loc} =>
          foldl
          (fn ((v,tpexp1), isExpansive) => isExpansive orelse expansive tpexp1)
          (expansive tpexp)
          varPathInfoTpexpList
      | TPLET (tpdeclList, tpexpList, tyList, loc) => true
      | TPRECORD {fields, recordTy=ty, loc=loc} =>
          SEnv.foldli
          (fn (string, tpexp1, isExpansive) =>
           isExpansive orelse expansive tpexp1)
          false
          fields
      | TPSELECT _ => true
      | TPMODIFY _ => true
      | TPRAISE _ => true
      | TPHANDLE _ => true
      | TPCASEM _ => true
      | TPFNM _ => false
      | TPPOLYFNM _ => false
      | TPPOLY {exp=tpexp,...} => expansive tpexp
      | TPTAPP {exp, ...} => expansive exp
      | TPLIST {expList,...} => 
          foldl
          (fn (tpexp1, isExpansive) =>
           isExpansive orelse expansive tpexp1)
          false
          expList
      | TPSEQ _ => true
      | TPCAST _ => true
      | TPSQLSERVER _ => false

  datatype abscontext = FINITE of int | INFINITE

  val inf = INFINITE
  val zero = FINITE 0
  fun inc INFINITE = INFINITE
    | inc (FINITE n) = FINITE (n + 1)
  fun decl INFINITE = INFINITE
    | decl (FINITE n) = FINITE (if n = 0 then 0 else (n - 1))
  fun iszero (FINITE 0) = true
    | iszero _ = false
    
  fun freeVarsInPat basis ptpat =
      case ptpat of
        PT.PTPATWILD _ => NPSet.empty
      | PT.PTPATID (namePath, loc) => 
        (case TIC.lookupVarInBasis (basis, namePath) of
           SOME(T.CONID _) => NPSet.empty
         | SOME(T.EXNID _) => NPSet.empty
         | _ => 
           (* Liu: 
            * 1. Unbound long constructor error is captured in module compiler.
            * 2. This case involves flattened long names.
            *)
           NPSet.singleton (namePath))
      | PT.PTPATCONSTANT _ => NPSet.empty
      | PT.PTPATCONSTRUCT (ptpatCon, ptpat, loc) => 
         (case ptpatCon of
            PT.PTPATID (namePath as (name, Path.NilPath), loc) => 
              (case TIC.lookupVarInBasis (basis, namePath) of
                 SOME(T.CONID _) => freeVarsInPat basis ptpat
               | SOME(T.EXNID _) => freeVarsInPat basis ptpat
               | _ => 
                   (E.enqueueError(loc, E.NonConstruct {pat = ptpatCon}); 
                    NPSet.empty
                    )
              )
          | PT.PTPATID (namePath, loc) => 
              (case TIC.lookupVarInBasis (basis, namePath) of
                 SOME(T.CONID _) => freeVarsInPat basis ptpat
               | SOME(T.EXNID _) => freeVarsInPat basis ptpat
               | SOME _ => 
                   (E.enqueueError
                    (loc,
                     E.ConstructorPathNotFound 
                      (NM.namePathToList(NM.namePathToUsrNamePath(namePath))));
                    NPSet.empty)
               | NONE => 
                   (E.enqueueError
                     (loc,
                      E.ConstructorPathNotFound 
                       (NM.namePathToList
                          (NM.namePathToUsrNamePath(namePath))));
                    NPSet.empty)
                   )
           | PT.PTPATTYPED (ptpatCon, _, _) => 
               freeVarsInPat basis (PT.PTPATCONSTRUCT (ptpatCon, ptpat, loc))
           | _ => 
              (
               E.enqueueError
                (PT.getLocPat ptpatCon, E.NonConstruct {pat = ptpatCon}); 
               NPSet.empty
               )
          )
      | PT.PTPATRECORD (_, stringPtpatList, loc) => 
          foldl 
          (fn ((_, ptpat), set2) => 
           let
             val set1 = freeVarsInPat basis ptpat
             val duplicates = NPSet.intersection (set1,set2)
           in
             if NPSet.isEmpty duplicates
               then NPSet.union(set1, set2)
             else
               (
                E.enqueueError
                (
                 loc,
                 E.DuplicatePatternVar
                  {vars =
                     map NM.usrNamePathToString (NPSet.listItems duplicates)}
                 );
                NPSet.union(set1, set2)
                )
           end)
          NPSet.empty
          stringPtpatList
      | PT.PTPATLAYERED (string, _, ptpat, loc) => 
        (case TIC.lookupVarInBasis(basis, (string, P.NilPath)) of
           SOME(T.CONID _) =>
           raise bug "not id in layered pat in typeinf"
         | SOME(T.EXNID _) =>
           raise bug "not id in layered pat in typeinf"
         | _ =>
           let val set1 = freeVarsInPat basis ptpat
           in
             if NPSet.member(set1, (string, P.NilPath))
             then 
               (
                E.enqueueError (loc,E.DuplicatePatternVar{vars = [string]});
                 set1
               )
             else NPSet.add(set1, (string, P.NilPath))
           end)
      | PT.PTPATTYPED (ptpat, _, _) => freeVarsInPat basis ptpat
      | PT.PTPATORPAT (ptpat1, ptpat2, loc) => 
          let
            val set1 = freeVarsInPat basis ptpat1
            val set2 = freeVarsInPat basis ptpat2
            val diff1 = NPSet.difference(set1, set2)
            val diff2 = NPSet.difference(set2, set1)
            val diffs = NPSet.union(diff1,diff2)
         in
            if NPSet.isEmpty diffs 
              then set1
            else
              (
               E.enqueueError
               (
                loc,
                E.DIfferentOrPatternVars
                 {vars = map NM.usrNamePathToString (NPSet.listItems diffs)}
                );
               NPSet.union(set1, set2)
               )
          end

  (**
   * Preform monomorphic modus ponens.
   *)
  fun monoApplyM basis {termLoc, 
                        funTy, 
                        argTyList, 
                        funTpexp, 
                        funLoc, 
                        argTpexpList} = 
      let 
        val (domtyList, ranty, instlist) = TU.coerceFunM (funTy, argTyList)
        val newFunTpexp =
          case instlist of
            nil => funTpexp 
          | _ =>
              TPTAPP
               {exp=funTpexp,
                expTy=funTy,
                instTyList=instlist,
                loc=termLoc}
      in 
        (U.unify (ListPair.zip(argTyList, domtyList));
         (
          ranty, 
          TPAPPM {funExp = newFunTpexp, 
                  funTy = T.FUNMty(domtyList, ranty), 
                  argExpList = argTpexpList, 
                  loc=termLoc}
          )
         )
        handle
          U.Unify =>
            ( 
             E.enqueueError
             (termLoc,
              E.TyConListMismatch
               {argTyList = argTyList, domTyList = domtyList});
             (T.ERRORty, TPERROR)
            ) 
      end
    handle TU.CoerceFun =>
      (
       E.enqueueError (funLoc, E.NonFunction {ty = funTy});
       (T.ERRORty, TPERROR)
       )

  fun transFunDecl (basis : TIC.basis)
                   loc
                   (funPat, ruleList as ((patList, exp)::_)) =
      let
        val funBody = 
          let
            fun listToTuple list =
              #2
              (foldl
               (fn (x, (n, y)) => (n + 1, y @ [(Int.toString n, x)]))
               (1, nil)
               list)
            val newNames = map (fn x => Counters.newVarName ()) patList
            val newVars =
                map (fn x => PT.PTVAR((x,Path.NilPath), loc)) newNames
            val newVarPats =
              map (fn x => PT.PTPATID((x, Path.NilPath), loc)) newNames
            val argRecord = PT.PTRECORD (listToTuple newVars, loc)
            val funRules =
              map
              (fn (args, exp) =>
               ([PT.PTPATRECORD(false, listToTuple args, loc)], exp)
               )
              ruleList
          in
            foldr
            (fn (x, y) =>PT.PTFNM(SEnv.empty, [([x], y)], loc))
            (PT.PTAPPM
             (
              PT.PTFNM(SEnv.empty, funRules, loc),
              [argRecord],
              loc
              ))
            newVarPats
          end
      in
        [(funPat, funBody)]
      end
    | transFunDecl _ _ _ = raise bug "illegal fun decl "


  (* foreign function stub generation *)
  fun getRealTy ty =
      case TU.derefTy ty of
        T.OPAQUEty {implTy, ...} => getRealTy implTy
      | ty => ty

  fun userTyvars ty =
      OTSet.filter (fn tvState as ref(T.TVAR{tyvarName=SOME _,...}) => true
                     | _ => false)
                   (TU.EFTV ty)

  datatype dir = IMPORT of bool | EXPORT

  fun isInteroperableType allowTyvar dir ty =
      case getRealTy ty of
        T.TYVARty _ => allowTyvar
      | T.RECORDty record =>
        SEnv.foldl
        (fn (ty, z) => z andalso isInteroperableType true dir ty)
        true
        record
      | ty as T.RAWty {tyCon, args} =>
        (
          case (dir,
                TyConID.Map.find
                  (#interoperableKindMap BuiltinContext.builtinContext,
                   #id tyCon)) of
            (_, SOME RuntimeTypes.INTEROPERABLE) => true
          | (IMPORT false, SOME RuntimeTypes.IMPORT_ONLY) => true
          | (IMPORT true, SOME RuntimeTypes.EXPORT_ONLY) => true
          | (EXPORT, SOME RuntimeTypes.EXPORT_ONLY) => true
          | (IMPORT _,
             SOME RuntimeTypes.INTEROPERABLE_BUT_EXPORT_ONLY_ON_VM) =>
            Control.nativeGen ()
          | (EXPORT, 
             SOME RuntimeTypes.INTEROPERABLE_BUT_EXPORT_ONLY_ON_VM) => true
          | _ => false
        )
      | T.ERRORty => true
      | _ => false

  fun checkInteroperableType allowTyvar dir (rawty, ty) =
      if isInteroperableType allowTyvar dir ty
      then ()
      else E.enqueueError (A.getLocTy rawty, E.NonInteroperableType rawty)

  fun checkSafeStubType (T.FUNMty (domTys, ranTy), loc) =
      let
        val domTyvars =
            foldl (fn (domty, tyvars) =>
                      (checkSafeStubType (domty, loc);
                       OTSet.union (tyvars, userTyvars domty)))
                  OTSet.empty domTys
        val _ = checkSafeStubType (ranTy, loc)
        val ranTyvars = userTyvars ranTy

        (* EFTV(ranTy) must be a subset of EFTV(domTys). *)
        val dif = OTSet.difference (ranTyvars, domTyvars)
      in
        if OTSet.isEmpty dif
        then ()
        else
          OTSet.app
          (fn tvState
             => E.enqueueError (loc, E.FFIInvalidTyvar (T.TYVARty tvState)))
          dif
      end
    | checkSafeStubType _ = ()

  local
    fun newVar basis ty =
        {namePath = (Counters.newVarName (), Path.NilPath), ty = ty}

    fun newTyvar basis =
        T.newty {recordKind = T.UNIV, eqKind = T.NONEQ, tyvarName = NONE}

    fun isUnitTy ty =
        case TU.derefTy ty of
          T.RAWty {tyCon = {id,...}, ...} =>
            TyConID.eq (id, #id (PDT.unitTyCon))
        | _ => false

    fun foldrTuple f z l =
        #2 (foldr (fn (x, (n, z)) => (n - 1, f (Int.toString n, x, z)))
                  (length l, z) l)

    fun tupleRecord l =
        foldrTuple (fn (n, x, z) => SEnv.insert (z, n, x)) SEnv.empty l

    fun implodeTupleTy nil = PDT.unitty
      | implodeTupleTy [ty] = ty
      | implodeTupleTy tys = T.RECORDty (tupleRecord tys)

    fun implodeTuple (nil, loc) =
        (PDT.unitty, TPCONSTANT (CT.UNIT, PDT.unitty, loc))
      | implodeTuple ([(ty, exp)], loc) =
        (ty, exp)
      | implodeTuple (fields, loc) =
        let
          val tys = map #1 fields
          val exps = map #2 fields
          val tupleTy = T.RECORDty (tupleRecord tys)
        in
          (tupleTy, TPRECORD {fields = tupleRecord exps,
                              recordTy = tupleTy,
                              loc = loc})
        end

    fun explodeTuple ([rawty], expTy, exp, loc) =
        [(rawty, expTy, exp, loc)]
      | explodeTuple (rawtys, expTy as T.RECORDty fieldTys, exp, loc) =
        foldrTuple (fn (n, rawty, z) =>
                    let
                      val fieldTy = case SEnv.find (fieldTys, n) of
                          SOME ty => ty
                        | NONE => raise bug ("explodeTuple: " ^ n)
                    in
                       (rawty,
                        fieldTy,
                        TPSELECT {
                                  label = n,
                                  exp = exp,
                                  expTy = expTy,
                                  resultTy = fieldTy,
                                  loc = loc
                                  },
                        loc) 
                    end
                    :: z)
                   nil rawtys
      | explodeTuple (rawtys, expTy, exp, loc) =
        if isUnitTy expTy
        then []
        else raise bug "explodeTuple: not a record"

    fun implodeRecordTy nil = PDT.unitty
      | implodeRecordTy fields =
        T.RECORDty
            (foldl (fn ((name, ty), z) => SEnv.insert (z, name, ty))
                   SEnv.empty fields)

    fun implodeRecord (nil, nil, loc) =
        (PDT.unitty, TPCONSTANT (CT.UNIT, PDT.unitty, loc))
      | implodeRecord (names, exps, loc) =
        let
          fun implode (recordTy, fields, name::names, (ty,exp)::exps) =
              implode (SEnv.insert (recordTy, name, ty),
                       SEnv.insert (fields, name, exp),
                       names, exps)
            | implode (recordTy, fields, nil, nil) =
              (T.RECORDty recordTy,
               TPRECORD {fields = fields,
                         recordTy = T.RECORDty recordTy,
                         loc = loc})
            | implode _ =
              raise bug "implodeRecord"
        in
          implode (SEnv.empty, SEnv.empty, names, exps)
        end

    fun explodeRecord (rawFieldTys, expTy as T.RECORDty fieldTys, exp, loc) =
        map (fn (name, rawty) =>
             let
               val fieldTy = case SEnv.find (fieldTys, name) of
                   SOME ty => ty
                 | NONE => raise bug ("explodeRecord: " ^ name)
             in
                (rawty,
                 fieldTy,
                 TPSELECT {
                           label = name,
                           exp = exp,
                           expTy = expTy,
                           resultTy = fieldTy,
                           loc = loc
                           },
                 loc)
             end
            )
            rawFieldTys
      | explodeRecord (rawFieldTys, expTy, exp, loc) =
        if isUnitTy expTy
        then []
        else raise bug "explodeRecord: not a record"

    fun stubUnit basis (expTy, exp, loc) =
        (U.unify [(PDT.unitty, expTy)];
         (false, (PDT.unitty, exp)))
        handle U.Unify =>
               (E.enqueueError (loc, E.FFIStubMismatch (PDT.unitty, expTy));
                (true, (T.ERRORty, TPERROR)))

    fun stubMap stub fields =
        foldr (fn (field, (changed, rets)) =>
                  let
                    val (changed2, ret) = stub field 
                  in
                    (changed orelse changed2, ret::rets)
                  end)
              (false, nil)
              fields

    fun stubTuple (basis : TIC.basis) stub (rawtys, expTy, exp, loc) =
        let
          val rawFieldTys = foldrTuple (fn (n,ty,z) => (n,ty)::z) nil rawtys
          val fieldNames = map #1 rawFieldTys
          val fieldTys =
              map (fn (name,_) => (name, newTyvar basis)) rawFieldTys
          val recordTy = implodeRecordTy fieldTys
          val fields = explodeRecord (rawFieldTys, recordTy, exp, loc)
          val (changed, rets) = stubMap stub fields
        in
          (U.unify [(recordTy, expTy)];
           if changed
           then (changed, implodeRecord (fieldNames, rets, loc))
           else (false, (expTy, exp)))
                (* stubMap unifies expTy with rawtys *)
          handle U.Unify =>
                 (E.enqueueError (loc, E.FFIStubMismatch (recordTy, expTy));
                  (true, (T.ERRORty, TPERROR)))
        end

    fun stubDirect (basis : TIC.basis)
                   allowTyvar
                   dir
                   (rawty, expTy, exp, loc)
      =
        let
          val ty = evalRawty basis rawty
          val _ = checkInteroperableType allowTyvar dir (rawty, ty)
        in
          (U.unify [(ty, expTy)];
           (false, (ty, exp)))
          handle U.Unify =>
                 (E.enqueueError (loc, E.FFIStubMismatch (ty, expTy));
                  (true, (T.ERRORty, TPERROR)))
        end

  in

  fun stubImport (basis : TIC.basis)
                 allowTyvar
                 forceImport
                 (A.TYFFI (attributes, _, rawArgTys, rawRetTy, _),
                  expTy,
                  exp,
                  loc) =
      let
        val expTy = getRealTy expTy

        val argTys = map (fn _ => newTyvar basis) rawArgTys
        val argTy = implodeTupleTy argTys
        val argVar = newVar basis argTy
        val argVarExp = TPVAR (argVar, loc)
        val args = explodeTuple (rawArgTys, argTy, argVarExp, loc)
        val (_, ffiArgs) = stubMap (stubExport basis false) args
        val ffiArgTys = map #1 ffiArgs
        val ffiArgExps = map #2 ffiArgs

        val ffiRetTy = newTyvar basis
        val ffiRetVar = newVar basis ffiRetTy
        val ffiRetVarExp = TPVAR (ffiRetVar, loc)
        val (_, (retTy, retExp)) =
            stubImportAllowingUnit
            basis
            false
            (#allocMLValue attributes)
            (rawRetTy, ffiRetTy, ffiRetVarExp, loc)

        val ffiFunty = T.FUNMty(ffiArgTys, ffiRetTy)
        val _ = checkSafeStubType (ffiFunty, loc)
        val ffiFunVar = newVar basis PDT.ptrty
      in
        (U.unify [(PDT.ptrty, expTy)];
         (*
          * fn x : domTy =>
          *   let f = M
          *       y = FFI (f:funty, Phi(#1 x), ..., Phi(#n x))
          *   in Psi(y)
          * : retTy
          *)
         (true,
         (T.FUNMty ([argTy], retTy),
          TPFNM
          {
            loc = loc,
            argVarList = [argVar],
            bodyTy = retTy,
            bodyExp =
              TPMONOLET
              {
                loc = loc,
                binds =
                  [(ffiFunVar, exp),
                   (ffiRetVar,
                    TPFOREIGNAPPLY
                    {
                      loc = loc,
                      funExp = TPVAR (ffiFunVar, loc),
                         (* only VAR may be here *)
                      funTy = ffiFunty,
                      instTyList = nil,
                      argExpList = ffiArgExps,
                      argTyList = ffiArgTys,
                      attributes = attributes
                    })],
                bodyExp = retExp
              }
          })))
        handle U.Unify =>
               (E.enqueueError (loc, E.FFIStubMismatch (PDT.ptrty, expTy));
                (true, (T.ERRORty, TPERROR)))
      end

    | stubImport basis
                 allowTyvar 
                 forceImport
                 (A.TYRECORD (rawFieldTys, _), expTy, exp, loc) =
      let
        val fieldNames = map #1 rawFieldTys
        val rawTupleFieldTys =
          foldrTuple (fn (n,(_,ty),z) => (n,ty)::z) nil rawFieldTys
        val tupleFieldTys =
          map (fn (name,_) => (name, newTyvar basis)) rawTupleFieldTys
        val tupleTy = implodeRecordTy tupleFieldTys
        val fields = explodeRecord (rawTupleFieldTys, tupleTy, exp, loc)
        val (changed, rets) = stubMap (stubImport basis true false) fields
      in
        (U.unify [(tupleTy, expTy)];
         if changed
         then (changed, implodeRecord (fieldNames, rets, loc))
         else (false, (expTy, exp)))
            (* stubImport unifies expTy with rawtys *)
        handle U.Unify =>
               (E.enqueueError (loc, E.FFIStubMismatch (tupleTy, expTy));
                (true, (T.ERRORty, TPERROR)))
      end

    | stubImport basis allowTyvar forceImport
                 (A.TYTUPLE (rawtys, _), expTy,exp,loc) =
      stubTuple basis (stubImport basis true false) (rawtys, expTy, exp, loc)

    | stubImport basis allowTyvar forceImport (rawty, expTy, exp, loc) =
      stubDirect basis allowTyvar (IMPORT forceImport) (rawty, expTy, exp, loc)

  and stubImportAllowingUnit basis allowTyvar forceImport
                             (ffirawty, expTy, exp, loc) =
      if isUnitTy (evalRawty basis ffirawty)
      then stubUnit basis (expTy, exp, loc)
      else stubImport basis false forceImport (ffirawty, expTy, exp, loc)

  and stubExport basis
                 allowTyvar
                 (A.TYFFI (attributes, _, rawArgTys, rawRetTy, _),
                  expTy,
                  exp,
                  loc) =
      let
        val ffiArgs = map (fn rawty =>
                              let val ty = newTyvar basis
                                  val var = newVar basis ty
                              in (rawty, ty, var, TPVAR (var, loc))
                              end)
                      rawArgTys
        val ffiArgTys = map #2 ffiArgs
        val ffiArgVars = map #3 ffiArgs
        val ffiArgExps = map #4 ffiArgs
        val (_, args) =
            stubMap (fn (rawty, ty, var, exp) =>
                        stubImport basis false false (rawty, ty, exp, loc))
                    ffiArgs
        val (argTy, argExp) = implodeTuple (args, loc)

        val retTy = newTyvar basis
        val retVar = newVar basis retTy
        val retVarExp = TPVAR (retVar, loc)
        val (_, (ffiRetTy, ffiRetExp)) =
            if isUnitTy (evalRawty basis rawRetTy)
            then stubUnit basis (retTy, retVarExp, loc)
            else stubExport basis false (rawRetTy, retTy, retVarExp, loc)

        val ffiFunty = T.FUNMty (ffiArgTys, ffiRetTy)
        val _ = checkSafeStubType (ffiFunty, loc)

        val ffiFunVar = newVar basis ffiFunty
        val funTy = T.FUNMty ([argTy], retTy)
      in
        let
          val (domTys, ranTy, instList) = TU.coerceFunM (expTy, [argTy])
          val monoExpTy = T.FUNMty (domTys, ranTy)
          val exp = case instList of
                      nil => exp
                    | _ => TPTAPP {exp = exp, expTy = expTy,
                                   instTyList = instList, loc = loc}
        in
          (U.unify [(funTy, monoExpTy)];
           (*
            * EXPORTCALLBACK(fn {x1,...,xn} : ffiArgTys =>
            *                  let y = (f:funTy) (Psi(x1), ..., Psi(xn))
            *                  in Phi(y))
            *)
           (true,
            (PDT.ptrty,
             TPEXPORTCALLBACK
             {
               loc = loc,
               argTyList = ffiArgTys,
               resultTy = ffiRetTy,
               attributes = attributes,
               funExp =
                 TPFNM
                 {
                   loc = loc,
                   argVarList = ffiArgVars,
                   bodyTy = ffiRetTy,
                   bodyExp =
                     TPMONOLET
                     {
                       loc = loc,
                       binds =
                         [(retVar,
                           TPAPPM
                           {
                             loc = loc,
                             funExp = exp,
                             funTy = monoExpTy,
                             argExpList = [argExp]
                           })],
                       bodyExp = ffiRetExp
                     }}})))
          handle U.Unify =>
                 (E.enqueueError (loc, E.FFIStubMismatch (funTy, monoExpTy));
                  (true, (T.ERRORty, TPERROR)))
        end
        handle TU.CoerceFun =>
               (E.enqueueError (loc, E.NonFunction {ty = expTy});
                (true, (T.ERRORty, TPERROR)))
      end

    | stubExport basis
                 allowTyvar
                 (A.TYRECORD (rawFieldTys, _), expTy, exp, loc) =
      let
        val fieldTys = map (fn (name, _) => (name, newTyvar basis)) rawFieldTys
        val recordTy = implodeRecordTy fieldTys
        val fields = explodeRecord (rawFieldTys, recordTy, exp, loc)
        val (changed, rets) = stubMap (stubExport basis true) fields
        val recordFields = foldrTuple (fn (n,x,z) => (n,x)::z) nil rets
      in
        (U.unify [(recordTy, expTy)];
         if changed
         then (changed,
               implodeRecord (map #1 recordFields, map #2 recordFields, loc))
         else (false, (expTy, exp)))
            (* stubExport unifies expTy with rawtys *)
        handle U.Unify =>
               (E.enqueueError (loc, E.FFIStubMismatch (recordTy, expTy));
                (true, (T.ERRORty, TPERROR)))
      end

    | stubExport basis allowTyvar (A.TYTUPLE (rawtys, _), expTy, exp, loc) =
      stubTuple basis (stubExport basis true) (rawtys, expTy, exp, loc)

    | stubExport basis allowTyvar (rawty, expTy, exp, loc) =
      stubDirect basis allowTyvar EXPORT (rawty, expTy, exp, loc)

  fun generalizeStub (basis : TIC.basis) (stubTy, stubExp, lambdaDepth, loc) =
      let
        val {boundEnv, ...} = 
            generalizer (stubTy, lambdaDepth)
      in
        if IEnv.isEmpty boundEnv
        then (stubTy, stubExp)
        else (T.POLYty {boundtvars = boundEnv, body = stubTy},
              case stubExp of
                TPFNM {argVarList, bodyTy, bodyExp, loc} =>
                TPPOLYFNM {btvEnv = boundEnv,
                           argVarList = argVarList,
                           bodyTy = bodyTy,
                           bodyExp = bodyExp,
                           loc = loc}
              | _ =>
                TPPOLY {btvEnv = boundEnv,
                        expTyWithoutTAbs = stubTy,
                        exp = stubExp,
                        loc = loc})
      end

  fun makeMulWord (arg1, arg2, loc) =
      let
        val (argTy, argExp) =
          implodeTuple ([(PDT.wordty, arg1), (PDT.wordty, arg2)], loc)
      in
        (PDT.intty,
         TPPRIMAPPLY
         {
           primOp = PredefinedTypes.wordMulPrimInfo,
           instTyList = nil,
           argExpOpt = SOME argExp,
           loc = loc
         })
      end
  end

  fun stubImportOldPrim basis lambdaDepth (ptexp, ffirawty, loc) =
      let
        fun generalize ty =
            let
              val {boundEnv, ...} = generalizer (ty, lambdaDepth)
            in
              (boundEnv,
               if IEnv.isEmpty boundEnv then ty
               else T.POLYty {boundtvars = boundEnv, body = ty})
            end

        val name = case ptexp of
                     PT.PTGLOBALSYMBOL (name,_,_) => name
                   | _ => raise bug "stubImportOldPrim"
        val (argTy, retTy) =
            case ffirawty of
              A.TYFFI (_,_,[],retTy,_) =>
              (PDT.unitty, evalRawty basis retTy)
            | A.TYFFI (_,_,[argTy],retTy,_) =>
              (evalRawty basis argTy, evalRawty basis retTy)
            | _ => raise bug "stubImportOldPrim"
        val stubTyBody = T.FUNMty ([argTy], retTy)
        val (stubBoundEnv, stubTy) = generalize stubTyBody

        val subst = TU.freshSubst stubBoundEnv
        val primTyBody = TU.substBTvar subst stubTyBody
        val (_, primTy) = generalize primTyBody
        val prim = BuiltinPrimitive.P (BuiltinPrimitive.RuntimePrim name)
        val primInfo = {prim_or_special = prim, ty = primTy}

        val argVar = {namePath = (Counters.newVarName (), Path.NilPath),
                      ty = argTy}
        val argVarExp = TPVAR (argVar, loc)

        val (argTy2, argExp) = TPU.freshInst (argTy, argVarExp)
        val (instTy, instTyList) = TIU.freshTopLevelInstTy primTy
        val (domTys, ranTy, _) = TU.coerceFunM (instTy, [argTy2])
        val _ = U.unify [(argTy2, List.hd domTys)]

        val stubExp = TPPRIMAPPLY {primOp = primInfo,
                                   instTyList = instTyList,
                                   argExpOpt = SOME argExp,
                                   loc = loc}
      in
        (stubTy,
         if IEnv.isEmpty stubBoundEnv
         then TPFNM {loc = loc,
                     argVarList = [argVar],
                     bodyTy = retTy,
                     bodyExp = stubExp}
         else TPPOLYFNM {btvEnv = stubBoundEnv,
                         loc = loc,
                         argVarList = [argVar],
                         bodyTy = retTy,
                         bodyExp = stubExp})
      end

  local
    fun lookupOperator oprimId nil = raise Control.Bug "lookupOperator"
      | lookupOperator oprimId ((operator:T.operator)::operators) =
        if OPrimID.eq (oprimId, #oprimId operator)
        then operator
        else lookupOperator oprimId operators

    fun lookupInstKey oprimId nil = raise Control.Bug "oprimInstKey"
      | lookupInstKey oprimId (ty::tys) =
        case TU.derefTy ty of
          T.TYVARty(ref(T.TVAR{recordKind=T.OPRIMkind{operators,...},...})) =>
          #keyTyList (lookupOperator oprimId operators)
        | _ => lookupInstKey oprimId tys

    fun freshOPrimInst ({oprimPolyTy, oprimId, ...}:T.oprimInfo) =
        let
          val (instTy, instTyList) = TIU.freshTopLevelInstTy oprimPolyTy
          val oprimInstKey = lookupInstKey oprimId instTyList
        in
          case TU.derefTy instTy of
            T.FUNMty ([domTy], ranTy) => (domTy, ranTy, oprimInstKey)
          | _ => raise Control.Bug "freshOPrimInst"
        end
  in

  fun freshInst_toSQL () =
      case freshOPrimInst PredefinedTypes.toSQLOPrimInfo of
        (ty as T.TYVARty (ref (T.TVAR _)), _, instKey) => (ty, instKey)
      | _ => raise Control.Bug "freshInst_toSQL"

  (* if ty consists only of RAWty and can be applied to a conversion
   * function between SQL and ML values, then yes. *)
  fun compatibleWithSQL ty =
      let
        fun isOnlyRAWty ty =
            case TU.derefTy ty of
              T.RAWty {tyCon, args} => List.all isOnlyRAWty args
            | _ => false
      in
        isOnlyRAWty ty
        andalso (U.unify [(ty, #1 (freshInst_toSQL ()))]; true)
        handle U.Unify => false
      end

  end (* local *)

  (**
   *)
  fun typeinfConst basis absynConst =
    let
      fun staticEvalConst const =
        case const of
          A.INT (int, _) => CT.LARGEINT int
        | A.WORD (word, _) => CT.WORD word
        | A.REAL (real, _) => CT.REAL real
        | A.STRING (string, _) => CT.STRING string
        | A.CHAR (char, _) => CT.CHAR char
        | A.UNITCONST _ => CT.UNIT
        | A.NULLCONST _ => CT.NULL
      val const = staticEvalConst absynConst
      val (ty, _) = TIU.freshTopLevelInstTy (CT.constTy const)
    in
      (ty, const)
    end

  fun mergeBoundEnvs (boundEnv1, boundEnv2) =
      IEnv.unionWith
      (fn _ => raise bug "duplicate boundtvars in mergeBoundEnvs")
      (
       boundEnv2,
       IEnv.map 
         (fn {recordKind,eqKind}
            => {recordKind=recordKind, eqKind=eqKind})
         boundEnv1
       )

  (*
    lambdaDepth : outer lambda depth
    basis : context for ptexp
    ifGenTerm : ifGenTerm is true then it also return the reconstructed term 
                which is used to bind the variable in a layered pattern.
    ptpat : pattern
    ptexp : expression

    Translate a valbind of the form
      val ptpat = ptexp 
    to a sequence of simpler bindings.
  
    exception: E.RecordLabelSetMismatch
   *)
  fun decomposeValbind
      lambdaDepth
      (basis, ifGenTerm)
      (ptpat, ptexp) =
    let
      fun generalizeIfNotExpansive lambdaDepth ((ty, tpexp), loc) = 
        if E.isError() then
          (ty, tpexp)
        else
         if expansive tpexp then 
           (ty, tpexp)
          else
            let
              val {boundEnv,...} = generalizer (ty, lambdaDepth)
            in 
              if IEnv.isEmpty boundEnv
                then (ty, tpexp)
              else
                (case tpexp of
                   TPFNM {argVarList=argVarPathInfoList,
                          bodyTy=ranTy,
                          bodyExp=typedExp,
                          loc=loc} =>
                     (
                      T.POLYty
                        {boundtvars = boundEnv,
                         body = T.FUNMty(map #ty argVarPathInfoList, ranTy)},
                      TPPOLYFNM {btvEnv=boundEnv,
                                 argVarList=argVarPathInfoList, 
                                 bodyTy=ranTy, 
                                 bodyExp=typedExp, 
                                 loc=loc}
                      )
                 | TPPOLY{btvEnv=boundEnv1,
                          expTyWithoutTAbs=ty1,
                          exp=tpexp1,
                          loc=loc1} =>
                     (
                      case ty of 
                        T.POLYty{boundtvars=boundEnv2, body= ty2} =>
                          (T.POLYty
                            {boundtvars = mergeBoundEnvs (boundEnv, boundEnv2),
                             body = ty2},
                           TPPOLY{btvEnv=mergeBoundEnvs (boundEnv, boundEnv1),
                                  expTyWithoutTAbs=ty1,
                                  exp=tpexp1,
                                  loc=loc1}
                           )
                      | _ => raise bug "non polyty for TPPOLY"
                     )
                 | TPPOLYFNM {btvEnv=boundEnv1, 
                              argVarList=argVarPathInfo, 
                              bodyTy=ranTy, 
                              bodyExp=tpexp1, 
                              loc=loc1} =>
                     (
                      case ty of 
                        T.POLYty{boundtvars=boundEnv2, body= ty2} =>
                          (T.POLYty
                            {boundtvars = mergeBoundEnvs (boundEnv, boundEnv2),
                             body = ty2},
                           TPPOLYFNM
                             {btvEnv=mergeBoundEnvs (boundEnv, boundEnv1),
                              argVarList=argVarPathInfo,   
                              bodyTy=ranTy,
                              bodyExp=tpexp1,
                              loc=loc1}
                           )
                      | _ => raise bug "non polyty for TPPOLY"
                    )
                 | _ => (
                         T.POLYty
                           {boundtvars = boundEnv, body = ty},
                         TPPOLY
                           {btvEnv=boundEnv,
                            expTyWithoutTAbs=ty,
                            exp=tpexp,
                            loc=loc}
                         )
                )
            end

      fun isStrictValuePat basis ptpat =
          case ptpat of
            PT.PTPATWILD _ => true
          | PT.PTPATID (longid, _) => 
            (case TIC.lookupVarInBasis(basis, longid) of 
                 SOME(T.CONID _) => false 
               | SOME(T.EXNID _) => false 
               |  _ => true)
          | PT.PTPATCONSTANT _ => false
          | PT.PTPATCONSTRUCT _ => false
          | PT.PTPATRECORD (_, stringPtpatList, _) => 
            foldr
                (fn ((_, ptpat1), bool) =>
                    bool andalso isStrictValuePat basis ptpat1)
                true
                stringPtpatList
          | PT.PTPATLAYERED (string, _, ptpat1, _) =>
            isStrictValuePat basis  ptpat1
          | PT.PTPATTYPED (ptpat1, _,  _) =>
            isStrictValuePat basis ptpat1
          | PT.PTPATORPAT _ => false
       (*
         This returns
           (localBinds, varBinds, extraBinds, tpexp, ty)
       *)
      fun decompose
          lambdaDepth
          (basis:TIC.basis, ifGenTerm)
          (ptpat, ptexp) = 
        let
          val ptpatLoc = PT.getLocPat ptpat
          val ptexpLoc = PT.getLocExp ptexp

          fun makeCase (ptpat, ptexp) = 
            let
              val idSet = freeVarsInPat basis ptpat
              val ptpatLoc = PT.getLocPat ptpat
              val ptexpLoc = PT.getLocExp ptexp
              val loc = Loc.mergeLocs (ptpatLoc, ptexpLoc)
            in
              if NPSet.isEmpty idSet
                then
                  let
                    val newPtexp =
                      PT.PTCASEM
                      (
                       [ptexp], 
                       [([ptpat], PT.PTTUPLE(nil, ptpatLoc))],
                       PatternCalc.BIND,
                       loc
                       )
                    val (ty, tpexp) = typeinfExp lambdaDepth inf basis newPtexp
                    val newName = Counters.newVarName()
                    val varIDPath = {namePath = (newName, P.NilPath), ty = ty}
                    val patid =
                      if ifGenTerm
                        then (T.VALIDVAR varIDPath)
                      else T.VALIDWILD ty
                  in
                    (nil, [(patid, tpexp)], nil, TPVAR (varIDPath, loc), ty)
                  end
              else
                case NPSet.listItems idSet of
                  [x] =>
                    let
                      val newPtexp =
                        PT.PTCASEM
                        (
                         [ptexp], 
                         [([ptpat], PT.PTVAR(x, ptpatLoc))],
                         PatternCalc.BIND,
                         loc
                         )
                      val (ty, tpexp) =
                        typeinfExp lambdaDepth inf basis newPtexp
                      val varIDPath = {namePath = x, ty = ty}
                    in
                      (
                        nil,
                        [(T.VALIDVAR varIDPath, tpexp)],
                        nil,
                        TPVAR (varIDPath, loc),
                        ty
                      )
                    end
                | _ =>
                  let
                    val resTuple =  
                      NPSet.foldr
                      (fn (x, resTuple) =>
                       PT.PTVAR(x, ptpatLoc) :: resTuple)
                      nil
                      idSet
                    val newPtexp =
                      PT.PTCASEM
                      (
                       [ptexp], 
                       [([ptpat], PT.PTTUPLE (resTuple, ptpatLoc))],
                       PatternCalc.BIND,
                       loc
                       )
                    val (tupleTy, tpexp) =
                        typeinfExp lambdaDepth inf basis newPtexp
                    val newVarId = Counters.newVarName ()
                    val varIDPath =
                        {namePath = (newVarId, P.NilPath), ty = tupleTy}
                    val tyList = 
                      case tupleTy of 
                        T.RECORDty tyFields => SEnv.listItems tyFields
                      | T.ERRORty => map (fn x => T.ERRORty) resTuple
                      | _ => raise bug "decompose"
                    val (_, resBinds) = 
                      foldl
                      (fn ((varId, ty), (i, varIDTpexpList)) => 
                       (
                        i + 1,
                        (
                         T.VALIDVAR {namePath = varId, ty = ty}, 
                         TPSELECT
                         {
                          label=Int.toString i,
                          exp=TPVAR (varIDPath, loc),
                          expTy=tupleTy,
                          resultTy = ty,
                          loc=loc
                          }
                         ) :: varIDTpexpList
                        ))
                      (1, nil)
                      (ListPair.zip (NPSet.listItems idSet, tyList))
                  in
                    (
                     [(T.VALIDVAR {namePath = (newVarId, P.NilPath),
                                   ty = tupleTy},
                       tpexp)],
                     List.rev resBinds,
                     nil,
                     TPVAR (varIDPath, loc),
                     tupleTy
                     )
                  end
            end
        in (* decompose body *)
          if not (isStrictValuePat basis ptpat)
            then makeCase (ptpat, ptexp)
          else
            case ptpat of 
              PT.PTPATWILD loc =>
                let
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    lambdaDepth
                    (typeinfExp lambdaDepth inf basis ptexp, ptexpLoc)
                  val newName = Counters.newVarName ()
                  val varIDPath = {namePath = (newName, P.NilPath), ty = ty}
                  val patid =
                    if ifGenTerm then 
                        T.VALIDVAR {namePath = (newName, P.NilPath), ty = ty} 
                    else T.VALIDWILD ty
                in
                  (nil, [(patid, tpexp)], nil, TPVAR (varIDPath, loc), ty)
                end
            | PT.PTPATID (varId, loc) =>
                let
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    lambdaDepth
                    (typeinfExp lambdaDepth zero basis ptexp, ptexpLoc)
                  val varIDPath  = {namePath = varId, ty = ty}
                in
                  (
                   nil,
                   [(T.VALIDVAR varIDPath, tpexp)],
                   nil,
                   TPVAR (varIDPath, loc),
                   ty
                   )
                end
            | PT.PTPATRECORD (flex, stringPtpatList, loc1) =>
                (case ptexp of
                   PT.PTTUPLE (ptexpList, loc) =>
                     if not flex
                            andalso
                            (List.length ptexpList <>
                             List.length stringPtpatList)
                       then 
                         raise E.RecordLabelSetMismatch
                     else
                       let 
                         val ptpatSEnvMap = 
                           foldl
                           (fn ((l, ptpat), ptpatSEnvMap) => 
                            SEnv.insert(ptpatSEnvMap, l, ptpat))
                           SEnv.empty
                           stringPtpatList
                         val labelPtpatPtexpList = 
                           List.rev
                           (#2 
                            (foldl
                             (fn (ptexp, (n, labelPtpatPtexpList)) =>
                              let 
                                val label = Int.toString n
                                val (ptpat, ptexp) = 
                                  case SEnv.find(ptpatSEnvMap, label) of
                                    SOME ptpat => (ptpat, ptexp)
                                  | NONE =>
                                      if flex
                                        then (PT.PTPATWILD loc1, ptexp)
                                      else raise E.RecordLabelSetMismatch
                              in
                                (
                                 n + 1,
                                 (label, ptpat, ptexp)::
                                 labelPtpatPtexpList
                                 )
                              end)
                             (1, nil)
                             ptexpList))
                         val (
                              localBinds,
                              patternVarBinds,
                              extraBinds,
                              labelTpexpList,
                              labelTyList
                              ) =
                           foldr
                           (fn (
                                (label, ptpat, ptexp),
                                (
                                 localBinds,
                                 patternVarBinds,
                                 extraBinds,
                                 labelTpexpList,
                                 labelTyList
                                 )
                                ) =>
                            let 
                              val (localBinds1,
                                   patternVarBinds1,
                                   extraBinds1,
                                   tpexp,
                                   ty) =
                                decompose
                                lambdaDepth
                                (basis, ifGenTerm)
                                (ptpat, ptexp) 
                            in
                              (
                               localBinds1 @ localBinds,
                               patternVarBinds1 @ patternVarBinds,
                               extraBinds1 @ extraBinds,
                               (label, tpexp) :: labelTpexpList,
                               (label, ty) :: labelTyList
                               )
                            end)
                           (nil, nil, nil, nil, nil)
                           labelPtpatPtexpList
                         val resultTy = 
                           T.RECORDty
                           (foldr
                            (fn ((l, ty), fields)
                               => SEnv.insert(fields, l, ty))
                            SEnv.empty
                            labelTyList)
                       in
                         (
                          localBinds, 
                          patternVarBinds, 
                          extraBinds,
                          TPRECORD
                          {
                           fields=foldr
                                  (fn ((l, tpexp), fields) =>
                                   SEnv.insert(fields, l, tpexp))
                                  SEnv.empty
                                  labelTpexpList,
                           recordTy=resultTy,
                           loc=loc1
                           },
                          resultTy
                          )
                       end
                 | PT.PTRECORD(stringPtexpList, loc2) =>
                    let 
                      val ptpatSEnvMap = 
                        foldl
                        (fn ((l, ptpat), ptpatSEnvMap) => 
                         SEnv.insert(ptpatSEnvMap, l, ptpat))
                        SEnv.empty
                        stringPtpatList
                      val expLabelSet =
                        foldl
                        (fn ((l, _), lset) => SSet.add(lset, l))
                        SSet.empty
                        stringPtexpList
                      val _ = 
                        (* check that the labels of patterns is 
                         * included in the labels of expressions
                         *)
                        SEnv.appi 
                        (fn (l, _) =>
                         if SSet.member(expLabelSet, l)
                           then ()
                         else raise E.RecordLabelSetMismatch)
                        ptpatSEnvMap
                      val labelPtpatPtexpList = 
                        foldr
                        (fn ((label, ptexp), labelPtpatPtexpList) =>
                         let 
                           val ptpat = 
                             case SEnv.find(ptpatSEnvMap, label) of
                               SOME ptpat => ptpat
                             | NONE =>
                                 if flex
                                   then PT.PTPATWILD loc1
                                 else raise E.RecordLabelSetMismatch 
                        in
                           (label, ptpat, ptexp) :: labelPtpatPtexpList
                         end)
                        nil
                        stringPtexpList
                      val (
                           localBinds,
                           patternVarBinds,
                           extraBinds,
                           labelTpexpList,
                           labelTyList
                           ) =
                        foldr
                        (fn (
                             (label, ptpat, ptexp),
                             (
                              localBinds,
                              patternVarBinds,
                              extraBinds,
                              labelTpexpList,
                              labelTyList
                              )
                             ) =>
                         let 
                           val (localBinds1,
                                patternVarBinds1,
                                extraBinds1,
                                tpexp,
                                ty) =
                             decompose
                             lambdaDepth
                             (basis, ifGenTerm)
                             (ptpat, ptexp) 
                         in
                           (
                            localBinds1 @ localBinds,
                            patternVarBinds1 @ patternVarBinds,
                            extraBinds1 @ extraBinds,
                            (label, tpexp) :: labelTpexpList,
                            (label, ty) :: labelTyList
                            )
                         end)
                        (nil, nil, nil, nil, nil)
                        labelPtpatPtexpList
                      val resultTy = 
                        T.RECORDty
                        (foldr
                         (fn ((l,ty), fields) => SEnv.insert(fields, l, ty))
                         SEnv.empty
                         labelTyList)
                    in
                      (
                       localBinds, 
                       patternVarBinds, 
                       extraBinds,
                       TPRECORD
                       {
                        fields=foldr
                               (fn ((l, tpexp), fields) =>
                                SEnv.insert(fields, l, tpexp))
                               SEnv.empty
                               labelTpexpList,
                        recordTy=resultTy,
                        loc=loc2
                        },
                       resultTy
                       )
                    end
                 | _ =>
                    let
                      val (tyBody, tpexpBody) =
                        typeinfExp lambdaDepth inf basis ptexp
                      val (_, tyPat, _ ) = typeinfPat lambdaDepth basis ptpat
                      val _ =
                        (U.unify [(tyBody, tyPat)])
                        handle U.Unify =>
                          raise
                            E.PatternExpMismatch
                            {patTy = tyPat, expTy= tyBody}
                      val bodyVar = Counters.newVarName ()
                      val ptBodyVar =
                        PT.PTVAR ((bodyVar, Path.NilPath), loc1)
                      val tpVarIDPath =
                          {namePath = (bodyVar,P.NilPath), ty = tyBody}
                      val tpBodyVar = T.VALIDVAR tpVarIDPath
                      val basis = TIC.bindVarInBasis (lambdaDepth,
                                                      basis, 
                                                      (bodyVar, P.NilPath), 
                                                      T.VARID tpVarIDPath)
                      val labelPtpatPtexpList = 
                        foldr
                        (fn ((label, ptpat), labelPtpatPtexpList) =>
                         (
                          label,
                          ptpat,
                          PT.PTSELECT(label, ptBodyVar, loc1)
                          ) ::
                         labelPtpatPtexpList)
                        nil
                        stringPtpatList
                      val (
                           localBinds,
                           variableBinds,
                           extraBinds,
                           labelTpexpList,
                           labelTyList
                           ) =
                        foldr
                        (fn (
                             (label, ptpat, ptexp),
                             (
                              localBinds,
                              variableBinds,
                              extraBinds,
                              labelTpexpList,
                              labelTyList
                              )
                             ) =>
                         let 
                           val (localBinds1,
                                variableBinds1,
                                extraBinds1,
                                tpexp,
                                ty) =
                             decompose
                             lambdaDepth
                             (basis, ifGenTerm)
                             (ptpat, ptexp) 
                         in
                           (
                            localBinds1 @ localBinds,
                            variableBinds1 @ variableBinds,
                            extraBinds @ extraBinds1,
                            (label, tpexp) :: labelTpexpList,
                            (label, ty) :: labelTyList
                            )
                         end)
                        (nil, nil, nil, nil, nil)
                        labelPtpatPtexpList
                    in
                      (
                       [(tpBodyVar,tpexpBody)]@localBinds, 
                       variableBinds, 
                       extraBinds,
                       TPVAR (tpVarIDPath, loc1),
                       tyBody
                       )
                    end
                  )
            | PT.PTPATLAYERED (id, optTy, ptpat, loc) =>
                let
                  val ptexp =
                    case optTy of 
                      SOME rawty => PT.PTTYPED (ptexp, rawty, ptexpLoc)
                    | NONE => ptexp
                  val (localBinds, variableBinds, extraBinds, tpexp, ty) =
                    decompose
                    lambdaDepth
                    (basis, true)
                    (ptpat, ptexp)
                in
                  (
                   localBinds,
                   variableBinds,
                   extraBinds 
                    @ [(T.VALIDVAR {namePath = (id, P.NilPath), ty = ty},
                        tpexp)],
                   tpexp,
                   ty
                   )
                end
            | PT.PTPATTYPED (ptpat, rawTy, loc)  => 
                let 
                  val ptexp = PT.PTTYPED (ptexp, rawTy, ptexpLoc)
                in
                  decompose
                  lambdaDepth
                  (basis, ifGenTerm)
                  (ptpat, ptexp)
                end
            | _ => raise bug "non strictvalue pat in decompoes"
        end (* end of decpomose *)

    (* decomposeValbind body *)
    in 
      (
       (* 
         The following is to check the well formedness of the pattern.
          Not very elegant.

          This should not be necessary.
          decomposeValbind is only called from 
            typeinfPtdecl on (PT.PTVAL ...) 
          where this check has already been made, 
          and ptpat is guaranteed to be well formed.
         freeVarsInPat currentContext ptpat;
         if E.isError() then (nil, nil, nil)
         else
      *)
         let
           val (localBinds, variableBinds, extraBinds, _, _) =
             decompose lambdaDepth (basis, ifGenTerm) (ptpat, ptexp)
         in
           (localBinds, variableBinds, extraBinds)
         end
       )
    end

  and tyinfApplyId lambdaDepth
                   applyDepth
                   (basis:TIC.basis)
                   (loc, longvid, idloc, rawTyList, ptexpList) =
    let 
      val varState = TIC.lookupVarInBasis (basis, longvid)
      val idState =
          case varState of
            SOME v => v
          | NONE =>
            (E.enqueueError
              (idloc,E.VarNotFound {id = NM.usrNamePathToString(longvid)});
              T.VARID {namePath = longvid, ty = T.ERRORty}
            ) 
(*
      val (tyList, tpexpList) = 
        foldr (fn (ptexp, (tyList, tpexpList)) =>
                 let 
                   val (ty, tpexp) = typeinfExp lambdaDepth inf basis ptexp
                   val (ty, tpexp) = TPU.freshInst(ty, tpexp)
                 in (ty::tyList, tpexp::tpexpList)
                 end
               )
               (nil,nil)
               ptexpList
*)
   in
      case (idState, ptexpList) of 
        (T.CONID (conPathInfo as {namePath, ty = ty, tyCon, funtyCon, tag}),
         [ptexp2]) =>
        let
          val lambdaDepth = incDepth ()
          val (ty2, tpexp2) = typeinfExp lambdaDepth inf basis ptexp2
          val (ty2, tpexp2) = TPU.freshInst (ty2, tpexp2)
	  val termconPathInfo =
              {
                namePath = longvid,
                ty = ty,
                tyCon = tyCon,
		tag = tag,
                funtyCon = funtyCon
              }
          val (instTy, instTyList) = TIU.freshTopLevelInstTy ty
          val _ = 
              foldl
                (fn (rawty, _) =>
                   let val annotatedTy1 = evalRawty basis rawty
                   in
                     U.unify [(instTy, annotatedTy1)]
                     handle U.Unify =>
                       E.enqueueError
                       (
                        loc,
                        E.TypeAnnotationNotAgree
                        {ty = instTy, annotatedTy = annotatedTy1}
                        )
                   end)
                ()
                rawTyList
          val (domtyList, ranty, instlist) = TU.coerceFunM (instTy,[ty2])
            handle TU.CoerceFun =>
              (
               E.enqueueError (idloc, E.NonFunction {ty = instTy});
               ([T.ERRORty], T.ERRORty, nil)
               )
          val domty =
            case domtyList of
              [ty] => ty
            | _ => raise bug "arity mismatch"
          val newTermBody = 
            TPDATACONSTRUCT
            { 
             con=termconPathInfo,
             instTyList=instTyList,
             argExpOpt=SOME tpexp2,
             loc=loc
             }
        in
          (
           U.unify [(ty2, domty)];
            if iszero applyDepth andalso not (expansive newTermBody) then
              let 
                val {boundEnv, ...} = generalizer (ranty, lambdaDepth)
              in
                if IEnv.isEmpty boundEnv
                  then (ranty, newTermBody)
                else
                  (
                   T.POLYty{boundtvars = boundEnv, body = ranty},
                   TPPOLY
                     {btvEnv=boundEnv,
                      expTyWithoutTAbs=ranty,
                      exp=newTermBody,
                      loc=loc}
                   )
              end
            else (ranty, newTermBody))
          handle
            U.Unify =>
              (
               E.enqueueError
               (loc, E.TyConMismatch {domTy = domty, argTy = ty2});
               (T.ERRORty, TPERROR)
               )
        end
      | (T.CONID (conPathInfo
                   as {namePath, ty = ty, tyCon, funtyCon, tag}), _) =>
          raise bug "CONID in multiple apply"
      | (T.EXNID (exnPathInfo
                   as {namePath, ty = ty, tyCon, funtyCon, tag}),
         [ptexp2]) =>
        let
          val lambdaDepth = incDepth ()
          val (ty2, tpexp2) = typeinfExp lambdaDepth inf basis ptexp2
          val (ty2, tpexp2) = TPU.freshInst (ty2, tpexp2)
	  val termconPathInfo =
              {
                namePath = longvid,
                ty = ty,
                tyCon = tyCon,
		tag = tag,
                funtyCon = funtyCon
              }
          val (instTy, instTyList) = TIU.freshTopLevelInstTy ty
          val _ = 
              foldl
              (fn (rawty, _) =>
                 let val annotatedTy1 = evalRawty basis rawty
                 in
                   U.unify [(instTy, annotatedTy1)]
                   handle U.Unify =>
                     E.enqueueError
                     (
                      loc,
                      E.TypeAnnotationNotAgree
                      {ty = instTy, annotatedTy = annotatedTy1}
                      )
                 end)
              ()
              rawTyList
          val (domtyList, ranty, instlist) = TU.coerceFunM (instTy,[ty2])
            handle TU.CoerceFun =>
              (
               E.enqueueError (idloc, E.NonFunction {ty = instTy});
               ([T.ERRORty], T.ERRORty, nil)
               )
          val domty =
            case domtyList of
              [ty] => ty
            | _ => raise bug "arity mismatch"
          val newTermBody = 
              TPEXNCONSTRUCT
                  { 
		   exn=termconPathInfo,
                   instTyList=instTyList,
                   argExpOpt=SOME tpexp2,
                   loc=loc
                  }
        in
          (
           U.unify [(ty2, domty)];
           if iszero applyDepth andalso not (expansive newTermBody) then
             let 
               val {boundEnv, ...} = generalizer (ranty, lambdaDepth)
             in
               if IEnv.isEmpty boundEnv
                 then (ranty, newTermBody)
               else
                 (
                  T.POLYty{boundtvars = boundEnv, body = ranty},
                  TPPOLY
                    {btvEnv=boundEnv,
                     expTyWithoutTAbs=ranty,
                     exp=newTermBody,
                     loc=loc}
                 )
              end
            else (ranty, newTermBody))
          handle
            U.Unify =>
              (
               E.enqueueError
               (loc, E.TyConMismatch {domTy = domty, argTy = ty2});
               (T.ERRORty, TPERROR)
               )
        end
      | (T.EXNID (conPathInfo
                    as {namePath, ty = ty, tyCon, funtyCon, tag}), _) =>
          raise bug "EXNID in multiple apply"
      | (T.PRIM (primInfo as {ty = ty,...}), [ptexp2]) =>
        let 
          val (ty2, tpexp2) = typeinfExp lambdaDepth inf basis ptexp2
          val (ty2, tpexp2) = TPU.freshInst (ty2, tpexp2)
          val (instTy, instTyList) = TIU.freshTopLevelInstTy ty
          val _ = 
              foldl
                  (fn (rawty, _) =>
                      let val annotatedTy1 = evalRawty basis rawty
                      in
                          U.unify [(instTy, annotatedTy1)]
                          handle U.Unify =>
                               E.enqueueError
                                  (
                                   loc,
                                   E.TypeAnnotationNotAgree
                                   {ty = instTy, annotatedTy = annotatedTy1}
                                   )
                      end)
                  ()
                  rawTyList
          val (domtyList, ranty, instlist) = TU.coerceFunM (instTy, [ty2])
            handle TU.CoerceFun =>
              (
               E.enqueueError (idloc, E.NonFunction {ty = instTy});
               ([T.ERRORty], T.ERRORty, nil)
               )
          val domty =
            case domtyList of
              [ty] => ty
            | _ => raise bug "arity mismatch"
          val newTermBody = 
              TPPRIMAPPLY
               {primOp=primInfo,
                instTyList=instTyList,
                argExpOpt=SOME tpexp2,
                loc=loc}
        in
          (
            U.unify [(ty2, domty)];
            (ranty, newTermBody)
          )
          handle U.Unify =>
                 (
                   E.enqueueError
                       (loc, E.TyConMismatch {domTy = domty, argTy = ty2});
                   (T.ERRORty, TPERROR)
                 )
        end
      | (T.PRIM (primInfo as {ty = ty,...}), _) =>
          raise bug "PrimOp in multiple apply"
      | (T.OPRIM {name, oprimPolyTy, oprimId}, [ptexp2]) =>
        let 
          val (ty2, tpexp2) = typeinfExp lambdaDepth inf basis ptexp2
          val (ty2, tpexp2) = TPU.freshInst (ty2, tpexp2)
          val (instTy, instTyList) = TIU.freshTopLevelInstTy oprimPolyTy
          fun findOperators nil = raise bug "operator not found"
            | findOperators (ty::rest) = 
              case TU.derefTy ty of
                T.TYVARty(ref (T.TVAR {recordKind=T.OPRIMkind{operators,...},
                                       ...})) => operators
              | _ => findOperators rest
          val operators = findOperators instTyList
          fun findKeyTyList (nil:T.operator list) =
                raise bug "oprimId not found"
            | findKeyTyList (operator::rest) =
              if OPrimID.eq(oprimId, #oprimId operator) then
                (#keyTyList operator)
              else findKeyTyList rest
          val keyTyList = findKeyTyList operators
          val (domtyList, ranty, instlist) = TU.coerceFunM (instTy, [ty2])
              handle TU.CoerceFun =>
                     (
                      E.enqueueError (idloc, E.NonFunction {ty = instTy});
                      ([T.ERRORty], T.ERRORty, nil)
                     )
          val domty =
              case domtyList of
                [ty] => ty
              | _ => raise bug "arity mismatch"
          val newTermBody =
              TPOPRIMAPPLY
                {
                 oprimOp={name = name,
                          oprimPolyTy = oprimPolyTy,
                          oprimId = oprimId},
                 instances=instTyList,
                 keyTyList = keyTyList,
                 argExpOpt=SOME tpexp2,
                 loc=loc
                }
        in
          (
           U.unify [(ty2, domty)];
           (ranty, newTermBody)
          )
          handle U.Unify =>
                 (
                   E.enqueueError
                       (loc, E.TyConMismatch {domTy = domty, argTy = ty2});
                   (T.ERRORty, TPERROR)
                 )
        end
      | (T.OPRIM {name, oprimPolyTy, oprimId}, _) =>
          raise bug "PrimOp in multiple apply"
      | (T.VARID {ty,...}, _) => 
        (
	 let
           val (tyList, tpexpList) = 
             foldr
               (fn (ptexp, (tyList, tpexpList)) =>
                  let 
                    val (ty, tpexp) = typeinfExp lambdaDepth inf basis ptexp
                    val (ty, tpexp) = TPU.freshInst (ty, tpexp)
                  in (ty::tyList, tpexp::tpexpList)
                  end
                )
               (nil,nil)
               ptexpList
	   val term = TPVAR ({namePath = longvid, ty=ty}, loc)
	 in
	   case rawTyList of
             nil =>
               monoApplyM
               basis
               {termLoc=loc,
                funTy=ty,
                argTyList=tyList,
                funTpexp=term,
                funLoc=idloc,
                argTpexpList=tpexpList}
           | _ =>
             let 
               val (instTy, tpexp1) = TPU.freshInst (ty,term)
               val _ = 
                 foldl
                 (fn (rawty, _) =>
                    let val annotatedTy1 = evalRawty basis rawty
                    in
                      (U.unify [(instTy, annotatedTy1)])
                      handle U.Unify =>
                        E.enqueueError
                        (
                         loc,
                         E.TypeAnnotationNotAgree
                         {ty = instTy, annotatedTy = annotatedTy1}
                         )
                    end)
                 ()
                 rawTyList
               val (domtyList, ranty, instlist) =
                 TU.coerceFunM (instTy, tyList)
                 handle TU.CoerceFun =>
                   (
                    E.enqueueError (idloc, E.NonFunction {ty = instTy});
                    (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
                    )
               val tpexp1 =
                   case instlist of
                     nil => tpexp1
                   | _ =>
                       TPTAPP
                        {exp=tpexp1,
                         expTy=instTy,
                         instTyList=instlist,
                         loc=loc}
             in 
               (
		U.unify (ListPair.zip(tyList, domtyList));
		(ranty, TPAPPM({funExp = tpexp1, 
                                funTy = T.FUNMty(domtyList, ranty), 
                                argExpList = tpexpList, 
                                loc = loc}))
		)
               handle
                 U.Unify =>
                   (
                    E.enqueueError
                    (loc,
                     E.TyConListMismatch
                       {domTyList = domtyList, argTyList = tyList});
                    (T.ERRORty, TPERROR)
                   )
             end
	 end
       )
      | (T.RECFUNID ({ty,...}, arity), _) => 
        (
	 let
           val (tyList, tpexpList) = 
             foldr
               (fn (ptexp, (tyList, tpexpList)) =>
                  let 
                    val (ty, tpexp) = typeinfExp lambdaDepth inf basis ptexp
                    val (ty, tpexp) = TPU.freshInst (ty, tpexp)
                  in (ty::tyList, tpexp::tpexpList)
                  end
                )
               (nil,nil)
               ptexpList
	   val term = TPRECFUNVAR ({var = {namePath = longvid, ty=ty}, 
                                    arity = arity, 
                                    loc = loc})
	 in
	   case rawTyList of
             nil =>
               monoApplyM
               basis
               {termLoc=loc,
                funTy=ty,
                argTyList=tyList,
                funTpexp=term,
                funLoc=idloc,
                argTpexpList=tpexpList}
           | _ =>
             let 
               val (instTy, tpexp1) = 
                   TPU.freshInst (ty,term)
               val _ = 
                 foldl
                 (fn (rawty, _) =>
                    let val annotatedTy1 = evalRawty basis rawty
                    in
                      (U.unify [(instTy, annotatedTy1)])
                      handle U.Unify =>
                        E.enqueueError
                        (
                         loc,
                         E.TypeAnnotationNotAgree
                         {ty = instTy, annotatedTy = annotatedTy1}
                         )
                    end)
                 ()
                 rawTyList
               val (domtyList, ranty, instlist) =
                 TU.coerceFunM (instTy, tyList)
                 handle TU.CoerceFun =>
                   (
                    E.enqueueError (idloc, E.NonFunction {ty = instTy});
                    (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
                    )
               val tpexp1 =
                   case instlist of
                     nil => tpexp1
                   | _ =>
                       TPTAPP
                       {exp=tpexp1, expTy=instTy, instTyList=instlist, loc=loc}
             in 
               (
		U.unify (ListPair.zip(tyList, domtyList));
		(ranty, TPAPPM({funExp = tpexp1, 
                                funTy = T.FUNMty(domtyList, ranty), 
                                argExpList = tpexpList, 
                                loc = loc}))
		)
               handle
                 U.Unify =>
                   (
                    E.enqueueError
                    (loc,
                     E.TyConListMismatch
                       {domTyList = domtyList, argTyList = tyList});
                    (T.ERRORty, TPERROR)
                    )
             end
	 end
       )
    end



  (**
   * infer a type for an expression
   *
   * @params lambdaDepth applyDepth compileContext exp
   * @param lambdaDepth the length of \Gamma
   * @param applyDepth the depth of application in which exp occurres
   * @param compileContext static context
   * @param exp expression
   * @return (ty, tpterm)
   *
   *)
  (*
    A new control parameter lambdaDepth is added.
    This is used to determine the set T of free type variables that are not 
    in the context  when a type is generalized. 
    The value of lambdaDepth is the nesting depth of the type generalization 
    context of e. We write
       \Gamma |-(d) e : \tau
    to denote that e is typed in the context of depth d.
    The program maintain the invariant:
      d > lambdaDepth(t) for any t in \Gamma
    so that we can compute the set T of bound type variables to be bound as:
        T = FTV(\tau) \ FTV(\Gamma)
          = 2{t | t in FTV(tau), lambdaDepth(t) >= d}
    Here is how the parameter is maintainiend and used as follows.
    The lambdaDepth of the toplevel is 0.
    Each time, it enter a type binding context, lambdaDepth is incremented.
    A type variable is refined to have lambdaDepth attribute:
      and tvState =
          TVAR of tvKind                  
        | SUBSTITUTED of ty
      and ty =
         ...
        | TYVARty of tvState ref                  
         ...
      withtype tvKind =
        {
          lambdaDepth : lambdaDepth
          id : int, 
          recordKind : recordKind, 
          eqKind : eqKind, 
          tyvarName : string option
       }
    When a binding {x:tau} is entered in the typeInferenceContext (basis),
    the lambdaDepth of each t in tau is set to the lambdaDepth of the context
    where x occurres.
    When two types are unified, their lambda depth is adjusted by taking 
    the minimal.
   *)
  and typeinfExp lambdaDepth applyDepth (basis : TIC.basis) ptexp =
      (case ptexp of
         PT.PTCONSTANT (const, loc) => 
           let
             val (ty, staticConst) = typeinfConst basis const
           in
             (ty, TPCONSTANT (staticConst,ty,loc))
           end
       | PT.PTGLOBALSYMBOL (name, kind, loc) =>
         (
           case kind of
             Absyn.ForeignCodeSymbol =>
             (PDT.ptrty, TPGLOBALSYMBOL (name, kind, PDT.ptrty, loc))
         )
       | PT.PTVAR (namePath, loc) => 
         (
          case TIC.lookupVarInBasis(basis, namePath) of 
              NONE => 
              (E.enqueueError
                 (loc,
                  E.VarNotFound{id = NM.usrNamePathToString namePath});
               (
                T.ERRORty,
                TPVAR
                    (
                     {
                      namePath = namePath,
		      ty = T.ERRORty
                      },
                      loc
                    )
                ))
            | SOME (T.VARID ({ty,...})) => 
	      (ty, TPVAR ({namePath = namePath, ty = ty}, loc))
            | SOME (T.RECFUNID ({ty,...}, arity)) => 
	      (ty, TPRECFUNVAR {var={namePath = namePath,
                                     ty = ty}, 
                                arity=arity, 
                                loc=loc}
	           )
            |  SOME idState =>
               (* When this case matches, varId is not in the head position.
                * So we perform eta expansion for the constructor name.
                *)
	       TIU.etaExpandCon namePath loc idState
	)
       | PT.PTTYPED (ptexp, rawty, loc) =>
         let
           val (ty1, tpexp) = typeinfExp lambdaDepth inf basis ptexp
           val (instTy, tpexp) = 
               TPU.freshInst (ty1, tpexp)
           val ty2 = evalRawty basis rawty
         in
           (
             U.unify [(instTy, ty2)];
             (ty2, tpexp)
           )
           handle
             U.Unify =>
               (
                E.enqueueError
                (
                 loc,
                 E.TypeAnnotationNotAgree {ty = instTy, annotatedTy = ty2}
                 );
                (T.ERRORty, TPERROR)
                )
         end
       | PT.PTAPPM(PT.PTRECORD_SELECTOR(label, loc1), [ptexp], loc2) =>
         typeinfExp
         lambdaDepth
         applyDepth
         basis
         (PT.PTSELECT(label, ptexp, loc2))
       | PT.PTAPPM (ptexp, ptexpList, loc) =>
         if isVar ptexp
         then
           let 
             val (path, pathLoc, rawTyList) = stripRawty ptexp
           in
             tyinfApplyId
                 lambdaDepth
                 applyDepth
                 basis
                 (loc, path, pathLoc, rawTyList, ptexpList)
           end
         else
           let 
             val (ty1, tpexp) =
               typeinfExp lambdaDepth (inc applyDepth) basis ptexp
             val (tyList, tpexpList) = 
               foldr (fn (ptexp, (tyList, tpexpList)) =>
                      let
                        val (ty, tpexp) =
                          typeinfExp lambdaDepth inf basis ptexp
                        val (ty, tpexp) = 
                          TPU.freshInst (ty, tpexp)
                      in
                        (ty::tyList, tpexp::tpexpList)
                      end
                      )
               (nil,nil)
               ptexpList
           in
             monoApplyM
             basis
             {termLoc=loc, 
              funTy=ty1, 
              argTyList=tyList, 
              funTpexp=tpexp, 
              funLoc=PT.getLocExp ptexp, 
              argTpexpList=tpexpList}
           end
       | PT.PTLET (ptdeclList, ptexpList, loc) =>
         let 
           val (context1, tpdeclList) =
               typeinfPtdeclList lambdaDepth false basis ptdeclList 
           val newBasis =
               TIC.extendBasisWithContext (basis, context1)
           val (tyList, tpexpList) = 
               foldr
                   (fn (ptexp, (tyList, tpexpList)) =>
                       let 
                         val (ty, tpexp) = 
                             typeinfExp lambdaDepth applyDepth newBasis ptexp
                       in 
                         (ty::tyList, tpexp :: tpexpList
                          )
                       end)
                   (nil, nil)
                   ptexpList
         in
           (List.last tyList, TPLET(tpdeclList, tpexpList, tyList, loc))
         end
       | PT.PTRECORD (stringPtexpList, loc) =>
         let 
           val (tpexpSmap, tySmap, tpbinds) =
             foldr 
               (fn ((label, ptexp), (tpexpSmap, tySmap, tpbinds)) =>
                 let 
                   val (ty, tpexp) =
                     typeinfExp lambdaDepth applyDepth basis ptexp
                 in 
                   if expansive tpexp then
                     let
                       val tpvarPathInfo = 
                         {namePath = (Counters.newVarName (), Path.NilPath),
                          ty = ty}
                     in
                       (
                        SEnv.insert
                          (tpexpSmap, label, TPVAR (tpvarPathInfo, loc)),
                        SEnv.insert(tySmap, label, ty),
                        (tpvarPathInfo, tpexp) :: tpbinds
                        )
                     end
                   else 
                     (
                      SEnv.insert (tpexpSmap, label, tpexp),
                      SEnv.insert(tySmap, label, ty),
                      tpbinds
                      )
                 end)
               (SEnv.empty, SEnv.empty, nil)
               stringPtexpList
           val resultTy = T.RECORDty tySmap
         in
           (
             resultTy,
             case tpbinds of
               nil => TPRECORD {fields=tpexpSmap, recordTy=resultTy, loc=loc}
             | _ =>
                TPMONOLET
                  {binds=tpbinds, 
                   bodyExp=
                     TPRECORD {fields=tpexpSmap, recordTy=resultTy, loc=loc}, 
                   loc=loc}
           )
         end
       | PT.PTRECORD_UPDATE (ptexp, stringPtexpList, loc) =>
         let
           val (ty1, tpexp1) =
             TPU.freshInst (typeinfExp lambdaDepth applyDepth basis ptexp)
           val (modifyTpexp, tySmap) =
             foldl
	       (fn ((label, ptexp), (modifyTpexp, tySmap)) =>
                  let
                    val (ty, tpexp) =
                      TPU.freshInst
                        (typeinfExp lambdaDepth applyDepth basis ptexp)
                    in
                      (TPMODIFY {label=label, 
                                 recordExp=modifyTpexp, 
                                 recordTy=ty1, 
                                 elementExp=tpexp, 
                                 elementTy=ty, 
                                 loc=loc},
                       SEnv.insert (tySmap, label, ty))
                    end)
               (tpexp1, SEnv.empty)
               stringPtexpList
           val modifierTy =
               T.newtyRaw 
                   {
                    lambdaDepth = lambdaDepth,
                    recordKind = T.REC tySmap, 
                    eqKind = T.NONEQ, 
                    tyvarName = NONE 
                   }
         in
            (
              U.unify [(ty1, modifierTy)];
              (ty1, modifyTpexp)
            )
            handle U.Unify =>
                   (
                     E.enqueueError
	               (
			 loc,
			 E.TyConMismatch {argTy = ty1, domTy = modifierTy}
		       );
		     (T.ERRORty, TPERROR)
		   )
         end
       | PT.PTTUPLE (ptexpList, loc) =>
         let 
           val (_, tpexpSmap, tySmap) =
               foldl
               (fn (ptexp, (n, tpexpSmap, tySmap)) =>
                   let 
                     val (ty, tpexp) =
                         typeinfExp lambdaDepth applyDepth basis ptexp
                     val label = Int.toString n
                   in 
                     (
                       n + 1,
                       SEnv.insert(tpexpSmap, label, tpexp),
                       SEnv.insert(tySmap, label, ty)
                     )
                   end)
               (1, SEnv.empty, SEnv.empty)
               ptexpList
           val resultTy = T.RECORDty tySmap
         in
           (resultTy, TPRECORD {fields=tpexpSmap, recordTy=resultTy, loc=loc})
         end
       | PT.PTRAISE (ptexp, loc) =>
         let 
           val (ty1, tpexp) = typeinfExp lambdaDepth applyDepth basis ptexp
           val resultTy = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
         in 
           (
             U.unify [(ty1, PDT.exnty)];
             (resultTy, TPRAISE (tpexp, resultTy, loc))
           )
           handle U.Unify =>
                  (
                    E.enqueueError (loc, E.RaiseArgNonExn {ty = ty1});
                    (T.ERRORty, TPERROR)
                  )
         end
       | PT.PTHANDLE (ptexp, ptpatPtexpList, loc) =>
         let 
           val (ty1, tpexp) =
               TPU.freshInst (typeinfExp lambdaDepth inf basis ptexp)
           val (ruleTy, tppatTpexpList) =
               monoTypeinfMatch
               lambdaDepth
               [PDT.exnty]
               basis
               (map (fn (pat,exp) => ([pat], exp)) ptpatPtexpList)
           val (domTy, ranTy) = 
               (* here we try maching the type of rules with exn -> ty1 
                * Also, the result type must be mono.
                *)
               case TU.derefTy ruleTy of
                 T.FUNMty([domTy], ranTy)=>(domTy, ranTy)
               | T.ERRORty => (T.ERRORty, T.ERRORty)
               | _ => raise bug "Case Type Inference"
           val newVarPathInfo = 
	       {namePath = (Counters.newVarName (), Path.NilPath), 
                ty = domTy}
         in
           (
             U.unify [(ty1, ranTy)];
             (
               ty1,
               TPHANDLE
                   {
                     exp=tpexp,
                     exnVar=newVarPathInfo,
                     handler=TPCASEM
                         {
                           expList=[TPVAR (newVarPathInfo, loc)],
                           expTyList=[domTy],
                           ruleList=tppatTpexpList,
                           ruleBodyTy=ranTy,
                           caseKind= PatternCalc.HANDLE,
                           loc=loc
                         },
                     loc=loc
                   }
             )
           )
           handle U.Unify =>
                  (
                    E.enqueueError
                        (loc, E.HandlerTy {expTy = ty1, handlerTy = ranTy});
                    (T.ERRORty, TPERROR)
                  )
         end
       | PT.PTFNM (tvarNameSet, matchM, loc) =>
         (case matchM of
            nil =>
              raise
                bug
                "empty rule in PTFNM (typeinference/main/TypeInferCore.sml)" 
          | [(patList, exp)] =>
              let
                exception NonVar
              in
(*
  (* This naive optimization does not work since D in fn D => exp may be CON.
   *)
                let
                  fun getId (PT.PTPATID ([x],loc)) = (x, NONE)
                    | getId (PT.PTPATWILD loc) = (Counters.newVarName(), NONE)
                    | getId (PT.PTPATTYPED (ptpat, rawTy, _)) = 
                       let
                         val (x, tyListOpt) = getId ptpat
                       in
                         case tyListOpt of
                           NONE => (x, SOME [rawTy])
                         | SOME tyList => (x, SOME(rawTy::tyList))
                       end
                    | getId _ = raise NonVar
                  val varList = map getId patList
                  val newPtexp = PT.PTFNM1(tvarNameSet, varList, exp, loc)
                in
                  typeinfExp lambdaDepth applyDepth basis newPtexp
                end
              handle NonVar =>
*)
                let
                  val nameList =
                    map (fn x => (Counters.newVarName (), NONE)) patList
                  val newPtexp =
                    PT.PTFNM1
                     (
                      tvarNameSet,
                      nameList,
                      PT.PTCASEM
                        (
                         map
                           (fn (x, _) => PT.PTVAR((x, Path.NilPath), loc))
                           nameList,
                         matchM,
                         PatternCalc.MATCH,
                         loc
                         ),
                      loc
                     )
                in 
                  typeinfExp lambdaDepth applyDepth basis newPtexp
                end
              end
          | ((patList, exp) :: rest) => 
                let
                  val nameList =
                    map (fn x => (Counters.newVarName (), NONE)) patList
                  val newPtexp =
                    PT.PTFNM1
                    (
                     tvarNameSet,
                     nameList,
                     PT.PTCASEM
                       (
                        map
                          (fn (x,_) => PT.PTVAR((x, Path.NilPath), loc))
                          nameList,
                        matchM,
                        PatternCalc.MATCH,
                        loc
                        ),
                     loc)
                in 
                  typeinfExp lambdaDepth applyDepth basis newPtexp
                end
              )
       | PT.PTFNM1(tvarNameSet, stringTyListOptionList, ptexp, loc) =>
         let 
           val lambdaDepth = incDepth ()
           val (newBasis, _) =
               TIC.addUtvarIfNotthere(lambdaDepth, 
                                      basis, 
                                      tvarNameSet)
           val nameDomTyVarPathInfoList = 
             map (fn (name, tyListOption) => 
                  let 
                    val domTy =
                      T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                    val rawTyList =
                      case tyListOption of NONE => nil | SOME tyList => tyList
                    val _ = 
                      foldl
                      (fn (rawty, _) =>
                         let val annotatedTy1 = evalRawty newBasis rawty
                         in
                           U.unify [(domTy, annotatedTy1)]
                           handle U.Unify =>
                             E.enqueueError
                             (
                              loc,
                              E.TypeAnnotationNotAgree
                              {ty = domTy, annotatedTy = annotatedTy1}
                              )
                         end)
                      ()
                      rawTyList
                  in
                    (name,
                     domTy,
                     {namePath = (name, Path.NilPath), ty = domTy})
                  end
                  )
             stringTyListOptionList
           val newBasis =
               foldl 
               (fn ((name, domTy, varPathInfo), newBasis)
                  => TIC.bindVarInBasis
                     (lambdaDepth,
                      newBasis,
                      (name, P.NilPath), T.VARID varPathInfo)
                )
               newBasis
               nameDomTyVarPathInfoList
           val (ranTy, typedExp) =
               typeinfExp lambdaDepth (decl applyDepth) newBasis ptexp
           val ty = T.FUNMty(map #2 nameDomTyVarPathInfoList, ranTy)
           val (ty, tpexp) = 
             if iszero applyDepth
               then
                 let
                   val {boundEnv, ...} = generalizer (ty, lambdaDepth)
                 in
                   if IEnv.isEmpty boundEnv
                     then (ty,
                           TPFNM
                             {argVarList =
                                map
                                #3
                                nameDomTyVarPathInfoList,
                              bodyTy = ranTy, 
                              bodyExp = typedExp, 
                              loc = loc})
                   else
                     (
                      T.POLYty{boundtvars = boundEnv, body = ty},
                      TPPOLYFNM {
                                 btvEnv=boundEnv, 
                                 argVarList=map #3 nameDomTyVarPathInfoList, 
                                 bodyTy=ranTy, 
                                 bodyExp=typedExp, 
                                 loc=loc
                                 }
                      )
                 end
             else 
             (ty, TPFNM {argVarList = map #3 nameDomTyVarPathInfoList,
                         bodyTy = ranTy,
                         bodyExp = typedExp,
                         loc = loc})
         in
           (ty, tpexp)
         end 
       | PT.PTCASEM (ptexpList, matchM, Kind, loc) =>
         let
           val (tyList, tpexpList) =
             foldr 
             (fn (ptexp, (tyList, tpexpList)) =>
                let
                  val (ty, tpexp) =
                    TPU.freshInst (typeinfExp lambdaDepth inf basis ptexp)
                in
                  (ty::tyList, tpexp::tpexpList)
                end
                )
               (nil,nil)
               ptexpList
           val (ruleTy, tpMatchM) =
               typeinfMatch lambdaDepth applyDepth tyList basis matchM
           val ranTy = 
               case TU.derefTy ruleTy of 
                 T.FUNMty(_, ranTy) => ranTy
               | T.ERRORty => T.ERRORty
               | _ => raise bug "Case Type Inference"
         in
           (ranTy, TPCASEM{
                           expList=tpexpList, 
                           expTyList=tyList, 
                           ruleList=tpMatchM, 
                           ruleBodyTy=ranTy, 
                           caseKind=Kind, 
                           loc=loc
                           })
         end
       | PT.PTRECORD_SELECTOR(label, loc) => 
         let
           val newName = Counters.newVarName ()
         in
           typeinfExp
           lambdaDepth
           applyDepth
           basis
           (PT.PTFNM1
             (
              SEnv.empty, 
              [(newName, NONE)],
              PT.PTSELECT
                (
                 label,
                 PT.PTVAR((newName, Path.NilPath), loc),
                 loc
                 ), 
              loc
             )
           )
         end
       | PT.PTSELECT(label, ptexp, loc) =>
         let 
           val (ty1, tpexp) = typeinfExp lambdaDepth applyDepth basis ptexp
           val ty1 = TU.derefTy ty1
         in
           case ty1 of
             T.RECORDty tyFields =>
             (* here we do not U.unify, since U.unify is restricted to monotype
              *)
             (case SEnv.find(tyFields, label) of
                SOME elemTy => (elemTy, 
                                TPSELECT{
                                         label=label, 
                                         exp=tpexp, 
                                         expTy=ty1, 
                                         resultTy = elemTy,
                                         loc=loc
                                         })
              | _ => 
                (
                  E.enqueueError (loc, E.FieldNotInRecord {label = label});
                  (T.ERRORty, TPERROR)
                ))
           | T.TYVARty (ref (T.TVAR tvkind)) =>
             let
               val elemTy =
                 T.newtyWithLambdaDepth (#lambdaDepth tvkind, T.univKind)
               val recordTy =
                   T.newtyRaw
                   {
                    lambdaDepth = lambdaDepth,
                    recordKind = T.REC (SEnv.singleton(label, elemTy)),
                    eqKind = T.NONEQ,
                    tyvarName = NONE
                   }
             in
               (
                 U.unify [(ty1, recordTy)];
                 (elemTy, TPSELECT{label=label, 
                                   exp=tpexp, 
                                   expTy=recordTy, 
                                   resultTy = elemTy,
                                   loc=loc})
               )
               handle U.Unify =>
                      (
                        E.enqueueError
                        (loc, E.TyConMismatch {domTy = recordTy, argTy = ty1});
                        (T.ERRORty, TPERROR)
                      )
             end
           | _ => (* this case may be empty *)
             let
               val elemTy = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
               val recordTy =
                   T.newtyRaw
                    {
                     lambdaDepth = lambdaDepth,
                     recordKind = T.REC (SEnv.singleton(label, elemTy)),
                     eqKind = T.NONEQ,
                     tyvarName = NONE
                    }
             in
               (
                 U.unify [(ty1, recordTy)];
                 (elemTy, TPSELECT{label=label, 
                                   exp=tpexp, 
                                   expTy=recordTy, 
                                   resultTy = elemTy,
                                   loc=loc})
               )
               handle U.Unify =>
                      (
                        E.enqueueError
                        (loc, E.TyConMismatch {domTy = recordTy, argTy = ty1});
                        (T.ERRORty, TPERROR)
                      )
             end
         end
       | PT.PTLIST (ptexpList, loc) =>
         let
             val lambdaDepth = incDepth ()
             val elemTy = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
             val tpexpList =
                 foldr 
                     (fn (ptexp, tpexpList) =>
                         let
                             val (ty, tpexp) =
                                 typeinfExp lambdaDepth applyDepth basis ptexp
                             val (ty, tpexp) = TPU.freshInst (ty, tpexp)
                             val _ = U.unify [(elemTy, ty)]
                                 handle
                                   U.Unify =>
                                     E.enqueueError
                                     (loc,
                                      E.InconsistentListElementType
                                        {prevTy=elemTy, nextTy=ty}
                                     )
                         in 
                           tpexp :: tpexpList
                         end)
                     nil
                     ptexpList
             val resultTy =
               T.RAWty {tyCon = PDT.listTyCon, args = [elemTy]}
             val newTermBody =
               TPLIST {expList=tpexpList, listTy=resultTy, loc=loc}
         in
            if iszero applyDepth andalso not (expansive newTermBody) then
              let 
                val {boundEnv, ...} = generalizer (resultTy, lambdaDepth)
              in
                if IEnv.isEmpty boundEnv then
                  (resultTy, newTermBody)
                 else
                   (
                     T.POLYty{boundtvars = boundEnv, body = resultTy},
                     TPPOLY
                       {btvEnv=boundEnv,
                        expTyWithoutTAbs=resultTy,
                        exp=newTermBody,
                        loc=loc}
                     )
              end
            else (resultTy, newTermBody)
         end
       | PT.PTSEQ (ptexpList, loc) =>
         let
           val (tyList, tpexpList) =
               foldr 
                   (fn (ptexp, (tyList, tpexpList)) =>
                       let
                         val (ty, tpexp) =
                             typeinfExp lambdaDepth applyDepth basis ptexp
                       in 
                         (ty :: tyList, tpexp :: tpexpList)
                       end)
                   (nil, nil)
                   ptexpList
         in
           (List.last tyList,
            TPSEQ {expList=tpexpList, expTyList=tyList, loc=loc}
           )
         end
       | PT.PTCAST(ptexp, loc) =>
         let
           val (ty1, tpexp) = typeinfExp lambdaDepth inf basis ptexp
           val ty = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
         in
           (ty, TPCAST(tpexp, ty, loc))
         end
       | PT.PTFFIIMPORT (ptexp, ffirawty as A.TYFFI _, loc) =>
         (* if native codegen is turned off, _import "symbol" without
          * calling convention attributes is used for importing
          * runtime primtives. *)
         if not (Control.nativeGen ())
            andalso (case ptexp of
                       PT.PTGLOBALSYMBOL (_,Absyn.ForeignCodeSymbol,_) => true
                     | _ => false)
         then
            if (case ffirawty of
                  A.TYFFI ({callingConvention = NONE, ...}, _, argTys, _, _)
                  => length argTys < 2
                | _ => false)
           then stubImportOldPrim basis lambdaDepth (ptexp, ffirawty, loc)
           else raise bug "not supported"
         else
         let
           val (expTy, tpExp) = typeinfExp lambdaDepth inf basis ptexp
           val (expTy, tpExp) = TPU.freshInst (expTy, tpExp)

           val var = {namePath = (Counters.newVarName (), Path.NilPath), 
                      ty = expTy}
           val varExp = TPVAR (var, loc)
           val (_, (stubTy, stubExp)) =
               stubImport basis false false (ffirawty, expTy, varExp, loc)

           val (stubTy, stubExp) =
               generalizeStub basis (stubTy, stubExp, lambdaDepth, loc)
         in
           (stubTy,
            TPMONOLET
            {
              loc = loc,
              binds = [(var, tpExp)],
              bodyExp = stubExp
            })
         end
       | PT.PTFFIIMPORT (ptexp, ffirawty, loc) =>
         raise bug "PTFFIIMPORT: not a function type"
       | PT.PTFFIEXPORT (ptexp, ffirawty as A.TYFFI _, loc) =>
         let
           val (expTy, tpExp) = typeinfExp lambdaDepth inf basis ptexp

           val var = {namePath = (Counters.newVarName (), Path.NilPath), 
                      ty = expTy}
           val varExp = TPVAR (var, loc)
           val (_, (stubTy, stubExp)) =
               stubExport basis false (ffirawty, expTy, varExp, loc)
           (* stubTy never include any free type variables.
              No need to generalize here. *)
         in
           (stubTy,
            TPMONOLET
            {
              loc = loc,
              binds = [(var, tpExp)],
              bodyExp = stubExp
            })
         end
       | PT.PTFFIEXPORT (ptexp, ffirawty, loc) =>
         raise bug "PTFFIEXPORT: not a function type"
       | PT.PTFFIAPPLY (attributes, ptfunExp, ptargs, rawRetTy, loc) =>
         let
           val (funTy, funExp) =
             typeinfExp lambdaDepth applyDepth basis ptfunExp
           val (funTy, funExp) =
             TPU.freshInst (funTy, funExp)
           val funTy = getRealTy funTy
           val _ = U.unify [(PDT.ptrty, funTy)]
             handle U.Unify =>
               E.enqueueError (loc, E.FFIStubMismatch (PDT.ptrty, funTy))
           fun typeinfFFIArg arg =
             case arg of
               PT.PTFFIARG (ptexp, ffirawty, loc) =>
                 let
                   val (argTy, argExp) =
                     typeinfExp lambdaDepth applyDepth basis ptexp
                   val (argTy, argExp) = TPU.freshInst (argTy, argExp)
                   val var =
                     {namePath = (Counters.newVarName (), Path.NilPath), 
                      ty = argTy}
                   val varExp = TPVAR (var, loc)
                   val (_, (stubTy, stubExp)) =
                     stubExport basis false (ffirawty, argTy, varExp, loc)
                 in
                   (stubTy,
                    TPMONOLET
                      {
                       loc = loc,
                       binds = [(var, argExp)],
                       bodyExp = stubExp
                      },
                    userTyvars stubTy)
                 end
             | PT.PTFFIARGSIZEOF (rawty, factorExpOpt, loc) =>
                 let
                   val ty = evalRawty basis rawty
                   val tyvars = userTyvars ty
                 in
                   case factorExpOpt of
                     NONE =>
                       (PDT.wordty, TPSIZEOF (ty, loc), tyvars)
                   | SOME ptfactorExp =>
                       let
                         val (factorTy, factorExp) =
                           typeinfExp lambdaDepth applyDepth basis ptfactorExp
                         val (factorTy, factorExp) =
                           TPU.freshInst (factorTy, factorExp)
                         val _ = U.unify [(PDT.wordty, factorTy)]
                           handle U.Unify =>
                             E.enqueueError
                               (loc,
                                E.FFIStubMismatch (PDT.wordty, factorTy))
                         val (ty, exp) =
                           makeMulWord (TPSIZEOF (ty, loc), factorExp, loc)
                       in
                         (ty, exp, tyvars)
                       end
                 end

           fun typeinfFFIArgs nil = (nil, nil, OTSet.empty)
             | typeinfFFIArgs (arg::args) =
               let
                 val (argTy, arg, tyvars2) = typeinfFFIArg arg
                 val (argTys, argExps, tyvars) = typeinfFFIArgs args
               in
                 (argTy::argTys, arg::argExps, OTSet.union (tyvars2, tyvars))
               end

           val (argTys, argExps, tyvars) = typeinfFFIArgs ptargs

           val funVar = {namePath = (Counters.newVarName (), P.NilPath), 
                         ty = funTy}
           val retTy =
             T.newty {recordKind = T.UNIV, eqKind = T.NONEQ, tyvarName = NONE}

           val retVar =
             {namePath = (Counters.newVarName (), P.NilPath), 
              ty = retTy}
           val retVarExp = TPVAR (retVar, loc)
           val (_, (stubTy, stubExp)) =
             stubImportAllowingUnit
             basis
             false
             false
             (rawRetTy, retTy, retVarExp, loc)

           val _ = checkSafeStubType (T.FUNMty (argTys, retTy), loc)

           (* For safety, user type variables appearing in
              _ffiapply must not be vacuous. *)
           val tyvars = OTSet.union (tyvars, userTyvars retTy)
           val _ =
             OTSet.app
             (fn tvState =>
              ffiApplyTyvars := (T.TYVARty tvState, loc) :: !ffiApplyTyvars)
             tyvars
         in
           (stubTy,
            TPMONOLET
              {
               loc = loc,
               binds =
               [(funVar, funExp),
                (retVar,
                 TPFOREIGNAPPLY
                   {
                    loc = loc,
                    funExp = TPVAR (funVar, loc),
                    funTy = T.FUNMty (argTys, retTy),
                    instTyList = nil,
                    argExpList = argExps,
                    argTyList = argTys,
                    attributes = attributes
                    }
                 )
                ],
               bodyExp = stubExp
              })
         end
         
    | PT.PTSQLSERVER (str, rawTy, loc) =>
      let
        val ty = evalRawty basis rawTy
        val schema =
            case TU.derefTy ty of
              T.RECORDty x =>
              (SEnv.app
                 (fn ty =>
                     case TU.derefTy ty of
                       T.RECORDty fields =>
                       SEnv.app
                         (fn ty =>
                             if compatibleWithSQL ty then ()
                             else (E.enqueueError (loc,
                                                   E.IncompatibleWithSQL ty)))
                         fields
                     | _ => (E.enqueueError (loc, E.InvalidSQLTableDecl ty))) x;
               x)
            | T.RAWty {tyCon,...} =>
              if TyConID.eq (#id PDT.unitTyCon, #id tyCon)
              then SEnv.empty
              else (E.enqueueError (loc, E.InvalidSQLTableDecl ty); SEnv.empty)
            | _ => (E.enqueueError (loc, E.InvalidSQLTableDecl ty);
                    SEnv.empty)
        val recordTy = ty
        val schemaTy = T.RAWty {tyCon = PDT.sqlServerTyCon,
                                args = [recordTy]}
        val strs = map (fn (l,e) =>
                           let
                             val (ty,tpe) =
                                 TPU.freshInst(typeinfExp lambdaDepth applyDepth
                                                          basis e)
                             val _ = U.unify [(ty,PDT.stringty)]
                                 handle U.Unify =>
                                        E.enqueueError
                                          (loc,E.TyConMismatch
                                                 {argTy = ty,
                                                  domTy = PDT.stringty})
                           in
                             (l,tpe)
                           end) str
      in
        (schemaTy,
         TPSQLSERVER {server = strs, schema = schema,
                      resultTy = schemaTy, loc = loc})
      end
    | PT.PTSQLDBI (ptpat, ptexp, loc) =>
      let
        (*
         *  T{x:t dbi} |- e : tau   t \not\in FTV(T)   t \not\in FTV(tau)
         * ----------------------------------------------------------------
         *  T |- sqldbi x in e : tau
         *
         * This term is derived from "abstype" of Mitchell-Protokin's
         * exsitential type. This term means the following:
         *   abstype X with x : X dbi is DBI in e
         *)
        val lambdaDepth = incDepth ()
        val tv = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
        val dbiTy = T.RAWty {tyCon = PDT.sqlDBITyCon, args = [tv]}

        val (patVarEnv, patTy, tppat) = typeinfPat lambdaDepth basis ptpat
        val _ = U.unify [(patTy, dbiTy)]
                handle U.Unify =>
                       E.enqueueError (loc,
                                       E.RuleTypeMismatch
                                         {thisRule=patTy, otherRules=dbiTy})
        val newBasis = TIC.extendBasisWithVarEnv (basis, patVarEnv)
        val (expTy, tpexp) = typeinfExp lambdaDepth applyDepth newBasis ptexp

        val _ =
            if (case TU.derefTy tv of
                  T.TYVARty (tvs as ref (T.TVAR {lambdaDepth=depth, ...})) =>
                  T.youngerDepth {contextDepth = lambdaDepth,
                                  tyvarDepth = depth}
                  andalso not (OTSet.member (TU.EFTV expTy, tvs))
                | _ => false)
            then ()
            else E.enqueueError (loc, E.InvalidSQLDBI tv)
      in
        (expTy,
         TPCASEM
           {expList=[TPDATACONSTRUCT {con = PDT.sqlDBIConPathInfo,
                                      instTyList = [tv],
                                      argExpOpt = NONE,
                                      loc = loc}],
            expTyList = [dbiTy],
            ruleList = [([tppat], tpexp)],
            ruleBodyTy = expTy,
            caseKind = PatternCalc.MATCH,
            loc = loc})
      end
      )


  (**
   * infer a possibly polytype for a match
   *)
  and typeinfMatch lambdaDepth applyDepth argtyList basis [rule] = 
      let 
        val (ty1, typedRule) =
          typeinfRule lambdaDepth applyDepth argtyList basis rule
      in (ty1, [typedRule]) end
    | typeinfMatch lambdaDepth _ argtyList basis (rule :: rules) =
      let 
        val (tyRule, typedRule) =
          monoTypeinfRule lambdaDepth argtyList basis rule
        val (tyRules, typedRules) =
          monoTypeinfMatch lambdaDepth argtyList basis rules
      in 
        (
          U.unify [(tyRule, tyRules)];
          (tyRules, typedRule::typedRules)
        )
        handle U.Unify =>
               (
                 E.enqueueError
                     (
                       getRuleLocM [rule],
                       E.RuleTypeMismatch
                           {thisRule = tyRule, otherRules = tyRules}
                     );
                 (T.ERRORty, nil)
               )
      end
    | typeinfMatch _ _ argtyList basis nil = 
      raise bug "typeinfMatch, empty rule"

  (**
   * infer a mono type for a match
   * @params argTy basis match
   *)
  and monoTypeinfMatch lambdaDepth argtyList basis [rule] =
      let
        val (ty1, typedRule) =
          monoTypeinfRule lambdaDepth argtyList basis rule
      in
        (ty1, [typedRule])
      end
    | monoTypeinfMatch lambdaDepth argtyList basis (rule :: rules) =
      let
        val (ruleTy, typedRule) =
          monoTypeinfRule lambdaDepth argtyList basis rule
        val (rulesTy, typedRules) =
          monoTypeinfMatch lambdaDepth argtyList basis rules
      in 
        (
          U.unify [(ruleTy, rulesTy)];
          (rulesTy, typedRule :: typedRules)
        )
        handle U.Unify =>
               (
                 E.enqueueError
                     (
                       getRuleLocM [rule],
                       E.RuleTypeMismatch
                           {thisRule = ruleTy, otherRules = rulesTy}
                     );
                 (T.ERRORty, nil)
               )
      end
    | monoTypeinfMatch lambdaDepth argty basis nil =
      raise bug "monoTypeinfMatch, empty rule"


  (**
   * infer a possibly polytype for a rule
   * @params applyDepth argTy basis rule
   *)
  and typeinfRule lambdaDepth applyDepth argtyList basis (patList,exp) = 
      let 
        val (varEnv1, patTyList, typedPatList) =
          typeinfPatList lambdaDepth basis patList
        val (bodyTy, typedExp) = 
            typeinfExp
            lambdaDepth
            applyDepth
            (TIC.extendBasisWithVarEnv(basis, varEnv1))
            exp
      in
        (
          U.unify (ListPair.zip(patTyList, argtyList));
          (T.FUNMty(patTyList, bodyTy), (typedPatList, typedExp))
        )
        handle U.Unify =>
               let val ruleLoc = getRuleLocM [(patList, exp)]
               in
                 E.enqueueError
                 (ruleLoc,
                  E.TyConListMismatch
                    {argTyList = argtyList, domTyList = patTyList});
                 (T.ERRORty,
                  (map (fn x => TPPATWILD(T.ERRORty, ruleLoc)) patList,
                   TPERROR))
               end
      end

  (**
   * infer a monotype for a rule
   * @params argTy basis rule
   *)
  and monoTypeinfRule lambdaDepth argtyList basis (patList,exp) = 
      let 
        val (varEnv1, patTyList, typedPatList) =
          typeinfPatList lambdaDepth basis patList
        val (bodyTy, typedExp) = 
          TPU.freshInst (typeinfExp 
                         lambdaDepth
                         inf (TIC.extendBasisWithVarEnv(basis, varEnv1)) exp)
      in
        (
          U.unify (ListPair.zip(patTyList, argtyList));
          (T.FUNMty(patTyList, bodyTy), (typedPatList, typedExp))
        )
        handle U.Unify =>
               let val ruleLoc = getRuleLocM [(patList, exp)]
               in
                 E.enqueueError
                 (ruleLoc,
                  E.TyConListMismatch
                    {argTyList = argtyList, domTyList = patTyList});
                 (T.ERRORty, ([TPPATWILD(T.ERRORty, ruleLoc)], TPERROR))
               end
      end

  and typeinfPatList lambdaDepth basis ptpatList =
        foldr
        (fn (ptpat, (varEnv1, tyPatList, tppatList)) =>
         let
           val (varEnv2, ty, tppat) = typeinfPat lambdaDepth basis ptpat
         in
           (
            NPEnv.unionWith
              (fn (varId as (T.VARID{namePath, ...}), _) =>
               (E.enqueueError
                (
                 PT.getLocPat ptpat, 
                 E.DuplicatePatternVar
                   {vars = [NM.usrNamePathToString(namePath)]});
                varId)
                | _ =>
               raise
                 bug
                 "non VARID in varEnv1 or 2\
                 \ (typeinference/main/TypeInferCore.sml)"
              )
              (varEnv2, varEnv1),
            ty::tyPatList,
            tppat::tppatList
            )
         end)
        (T.emptyVarEnv, nil, nil)
        ptpatList

  (**
   * infer a mono type for a pattern
   * @params basis pattern
   * @return a varEnv of the pattern, pattern type, and a typed pattern
   *)
  and typeinfPat lambdaDepth basis ptpat =
      (case ptpat of
         PT.PTPATWILD loc => 
         let val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
         in (T.emptyVarEnv, ty1, TPPATWILD (ty1, loc)) end
       | PT.PTPATID (namePath as (varId, Path.NilPath), loc) =>
         let 
	   val idState = TIC.lookupVarInBasis(basis, namePath)
         in
           (case idState of 
              SOME(T.CONID(con as {funtyCon, ty, tyCon, tag, ...})) =>
              if not funtyCon
              then
                let 
		  val termconPathInfo =
                      {
                        namePath = namePath,
                        ty = ty,
                        tyCon = tyCon,
			tag = tag,
                        funtyCon = funtyCon
                      }
                  val (ty1, tylist) = 
                      case ty of
                        (T.POLYty{boundtvars, body, ...}) =>
                        let val subst = TU.freshSubst boundtvars
                        in
                          (TU.substBTvar subst body, IEnv.listItems subst)
                        end
                      | _ => (ty, nil)
                in
                  (
                    T.emptyVarEnv,
                    ty1,
                    TPPATDATACONSTRUCT{conPat=termconPathInfo, 
                                       instTyList=tylist, 
                                       argPatOpt=NONE, 
                                       patTy=ty1, 
                                       loc=loc}
                  )
                end
              else 
                (
                 E.enqueueError
                   (loc,
                    E.ConRequireArg{con = varId});
                 (
                  T.emptyVarEnv,
                  T.ERRORty,
                  TPPATWILD (T.ERRORty, loc)
                  )
                 )
            | SOME(T.EXNID(con as {funtyCon, ty, tyCon, tag, ...})) =>
              if not funtyCon
              then
                let 
		  val termconPathInfo =
                      {
                        namePath = namePath,
                        ty = ty,
                        tyCon = tyCon,
			tag = tag,
                        funtyCon = funtyCon
                      }
                  val (ty1, tylist) = 
                      case ty of
                        (T.POLYty{boundtvars, body, ...}) =>
                        let val subst = TU.freshSubst boundtvars
                        in (TU.substBTvar subst body, IEnv.listItems subst) end
                      | _ => (ty, nil)
                in
                  (
                    T.emptyVarEnv,
                    ty1,
                    TPPATEXNCONSTRUCT{exnPat=termconPathInfo, 
                                      instTyList=tylist, 
                                      argPatOpt=NONE, 
                                      patTy=ty1, 
                                      loc=loc}
                  )
                end
              else 
                (
                 E.enqueueError
                   (loc,
                    E.ConRequireArg{con = varId});
                 (
                  T.emptyVarEnv,
                  T.ERRORty,
                  TPPATWILD (T.ERRORty, loc)
                  )
                 )
            | _ => 
              let
                val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                val varPathInfo = {namePath = namePath, ty = ty1}
                val varEnv1 =
                    NPEnv.insert (T.emptyVarEnv, namePath, T.VARID varPathInfo)
              in
                (varEnv1, ty1, TPPATVAR (varPathInfo, loc))
              end)
         end
       | PT.PTPATID (namePath, loc) =>
         (* liu: Note that flattened longids appear here.
          *      structure A = struct val x = 1 end
          * is flattened into 
          *      val A.x = 1
          * Here "A.x" appears as PTPATID([A,x], loc).
          *)
         let 
	   val idState = TIC.lookupVarInBasis(basis, namePath)
         in
           (case idState of 
              SOME(T.CONID(con as {funtyCon, ty, tyCon, tag,...})) =>
              if not funtyCon
              then
                let 
		  val termconPathInfo =
                      {
                        namePath = namePath,
                        ty = ty,
                        tyCon = tyCon,
			tag = tag,
                        funtyCon = funtyCon
                      }
                  val (ty1, tylist) = 
                      case ty of
                        (T.POLYty{boundtvars, body, ...}) =>
                        let val subst = TU.freshSubst boundtvars
                        in
                          (TU.substBTvar subst body, IEnv.listItems subst)
                        end
                      | _ => (ty, nil)
                in
                  (
                    T.emptyVarEnv,
                    ty1,
                    TPPATDATACONSTRUCT{conPat=termconPathInfo, 
                                       instTyList=tylist, 
                                       argPatOpt=NONE, 
                                       patTy=ty1, 
                                       loc=loc}
                  )
                end
              else 
                (
                 E.enqueueError
                   (loc,
                    E.ConRequireArg{con = NM.usrNamePathToString(namePath)});
                 (
                  T.emptyVarEnv,
                  T.ERRORty,
                  TPPATWILD (T.ERRORty, loc)
                  )
                 )
            | SOME(T.EXNID(exn as {funtyCon, ty, tyCon, tag,...})) =>
              if not funtyCon
              then
                let 
		  val termconPathInfo =
                      {
                        namePath = namePath,
                        ty = ty,
                        tyCon = tyCon,
			tag = tag,
                        funtyCon = funtyCon
                      }
                  val (ty1, tylist) = 
                      case ty of
                        (T.POLYty{boundtvars, body, ...}) =>
                        let val subst = TU.freshSubst boundtvars
                        in
                          (TU.substBTvar subst body, IEnv.listItems subst)
                        end
                      | _ => (ty, nil)
                in
                  (
                    T.emptyVarEnv,
                    ty1,
                    TPPATEXNCONSTRUCT{exnPat=termconPathInfo, 
                                      instTyList=tylist, 
                                      argPatOpt=NONE, 
                                      patTy=ty1, 
                                      loc=loc}
                  )
                end
              else 
                (
                 E.enqueueError
                   (loc,
                    E.ConRequireArg{con = NM.usrNamePathToString(namePath)});
                 (
                  T.emptyVarEnv,
                  T.ERRORty,
                  TPPATWILD (T.ERRORty, loc)
                  )
                 )
	    | _ => 
              let
                val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                val varPathInfo = {namePath = namePath, ty = ty1}
                val varEnv1 =
                    NPEnv.insert (T.emptyVarEnv, namePath, T.VARID varPathInfo)
              in
                (varEnv1, ty1, TPPATVAR (varPathInfo, loc))
              end
            (*| NONE => 
              (
                E.enqueueError(loc, E.ConstructorPathNotFound longIds);
                (T.emptyVarEnv, T.ERRORty, TPPATWILD (T.ERRORty, loc))
              )*)
            )
         end
       | PT.PTPATCONSTANT (const, loc) => 
         let
           val (ty, staticConst) = typeinfConst basis const
         in
           (T.emptyVarEnv, ty, TPPATCONSTANT(staticConst, ty, loc))
         end
       | PT.PTPATCONSTRUCT (ptpat1, ptpat2, loc) =>
         (case ptpat1 of
            PT.PTPATID(patIdPath, _) =>
            (case TIC.lookupVarInBasis(basis, patIdPath) of 
               SOME (T.CONID (con as {funtyCon, ty, tyCon, tag, ...}))
                =>
                 if funtyCon
                   then
                     let 
		       val termconPathInfo =
                           {
                             namePath = patIdPath,
                             ty = ty, 
                             tyCon = tyCon,
                             tag = tag,
                             funtyCon = funtyCon
                           }
                       val (varEnv1, patTy2, tppat2) =
                           typeinfPat lambdaDepth basis ptpat2
                       val (domtyList, ranty, instTyList) = 
                           TU.coerceFunM (ty, [patTy2])
                       val domty =
                         case domtyList of
                           [ty] => ty
                         | _ => raise bug "arity mismatch"
                       val _ =
                           U.unify [(patTy2, domty)]
                           handle U.Unify =>
                                    E.enqueueError
                                        (
                                          loc,
                                          E.TyConMismatch
                                              {argTy = patTy2, domTy = domty}
                                        )
                     in
                       (
                         varEnv1,
                         ranty,
                         TPPATDATACONSTRUCT
                         {conPat=termconPathInfo, 
                          instTyList=instTyList, 
                          argPatOpt=SOME tppat2, 
                          patTy=ranty, 
                          loc=loc}
                        )
                     end
                 else 
                   (
                     E.enqueueError
                     (loc,
                      E.ConstantConApplied
                        {con = NM.usrNamePathToString(patIdPath)});
                    (T.emptyVarEnv, T.ERRORty,TPPATWILD (T.ERRORty, loc))
                   )
               | SOME (T.EXNID (con as {funtyCon, ty, tyCon, tag, ...}))
                =>
                 if funtyCon
                   then
                     let 
		       val termconPathInfo =
                           {
                             namePath = patIdPath,
                             ty = ty, 
                             tyCon = tyCon,
                             tag = tag,
                             funtyCon = funtyCon
                           }
                       val (varEnv1, patTy2, tppat2) =
                           typeinfPat lambdaDepth basis ptpat2
                       val (domtyList, ranty, instTyList) = 
                           TU.coerceFunM (ty, [patTy2])
                       val domty =
                         case domtyList of
                           [ty] => ty
                         | _ => raise bug "arity mismatch"
                       val _ =
                           U.unify [(patTy2, domty)]
                           handle U.Unify =>
                                    E.enqueueError
                                        (
                                          loc,
                                          E.TyConMismatch
                                              {argTy = patTy2, domTy = domty}
                                        )
                     in
                       (
                         varEnv1,
                         ranty,
                         TPPATEXNCONSTRUCT
                         {exnPat=termconPathInfo, 
                          instTyList=instTyList, 
                          argPatOpt=SOME tppat2, 
                          patTy=ranty, 
                          loc=loc}
                        )
                     end
                 else 
                   (
                     E.enqueueError
                     (loc,
                      E.ConstantConApplied
                        {con = NM.usrNamePathToString(patIdPath)});
                    (T.emptyVarEnv, T.ERRORty,TPPATWILD (T.ERRORty, loc))
                   )
             | _ => 
               (
                 E.enqueueError(loc, E.NonConstruct {pat = ptpat1});
                 (T.emptyVarEnv, T.ERRORty, TPPATWILD (T.ERRORty, loc))
               ))
          | _ => 
              (
                E.enqueueError(loc, E.NonConstruct {pat = ptpat1});
                (T.emptyVarEnv, T.ERRORty, TPPATWILD (T.ERRORty, loc))
              ))
       | PT.PTPATRECORD (flex, ptpatFields, loc) =>
         let 
           val (varEnv1, tyFields, tppatFields) =
               foldr
                   (fn ((label, ptpat), (varEnv1, tyFields, tppatFields)) =>
                       let
                         val (varEnv2, ty, tppat) =
                             typeinfPat lambdaDepth basis ptpat
                       in
                         (
                           NPEnv.unionWith
                           (fn (varId as (T.VARID{namePath, ...}), _) =>
                            (E.enqueueError
                             (loc, 
                              E.DuplicatePatternVar
                                {vars = [NM.usrNamePathToString(namePath)]});
                             varId)
                             | _ =>
                               raise
                                 bug
                                 "non VARID in varEnv1 or 2\
                                 \ (typeinference/main/TypeInferCore.sml)"
                            )
                           (varEnv2, varEnv1),
                            SEnv.insert(tyFields, label, ty),
                            SEnv.insert(tppatFields, label, tppat)
                         )
                       end)
                   (T.emptyVarEnv, T.emptyTyfield, SEnv.empty)
                   ptpatFields
           val ty1 =
               if flex
               then
                 T.newtyRaw {
                             lambdaDepth = lambdaDepth,
                             recordKind = T.REC tyFields, 
                             eqKind = T.NONEQ, 
                             tyvarName = NONE
                            }
               else T.RECORDty tyFields
         in
           (varEnv1,
            ty1,
            TPPATRECORD{fields=tppatFields, recordTy=ty1, loc=loc})
         end
       | PT.PTPATLAYERED (string, optTy, ptpat, loc) =>
         (case TIC.lookupVarInBasis(basis, (string, Path.NilPath)) of 
           SOME(T.CONID _) =>
            (
              E.enqueueError (loc, E.NonIDInLayered {id = string});
              (NPEnv.empty, T.ERRORty, TPPATWILD (T.ERRORty, loc))
            )
         | SOME(T.EXNID _) =>
            (
             E.enqueueError (loc, E.NonIDInLayered {id = string});
             (NPEnv.empty, T.ERRORty, TPPATWILD (T.ERRORty, loc))
            )
          | _ => 
            let
              val (varEnv1, ty1, tpat) = typeinfPat lambdaDepth basis ptpat
              val _ = 
                case optTy of
                    NONE => ()
                  | SOME rawTy => 
                      let val ty2 = evalRawty basis rawTy
                      in
                        U.unify [(ty1, ty2)]
                        handle U.Unify =>
                           E.enqueueError
                           (
                            loc,
                            E.TypeAnnotationNotAgree
                            {ty = ty1, annotatedTy = ty2}
                            )
                      end
              val namePath = (string, Path.NilPath)
              val varPathInfo = {namePath = namePath, ty = ty1}
            in 
              (
                NPEnv.insert (varEnv1, namePath, T.VARID varPathInfo),
                ty1,
                TPPATLAYERED
                  {varPat=TPPATVAR (varPathInfo, loc), asPat=tpat, loc=loc}
              )
            end)
       | PT.PTPATTYPED (ptpat, rawTy, loc)  => 
         let
           val (varEnv1, ty1, tppat) = typeinfPat lambdaDepth basis ptpat
           val ty2 = evalRawty basis rawTy
           val _ = U.unify [(ty1, ty2)]
               handle U.Unify =>
                        E.enqueueError
                            (
                              loc,
                              E.TypeAnnotationNotAgree
                                  {ty = ty1, annotatedTy = ty2}
                            )
         in
           (varEnv1, ty2, tppat)
         end
       | PT.PTPATORPAT (ptpat1, ptpat2, loc)  => 
          let
            val set1 = freeVarsInPat basis ptpat1
            val set2 = freeVarsInPat basis ptpat2
            val diff1 = NPSet.difference(set1, set2)
            val diff2 = NPSet.difference(set2, set1)
            val diffs = NPSet.union(diff1,diff2)
         in
            if NPSet.isEmpty diffs 
              then
              let
                val (varEnv1, ty1, tppat1) =
                  typeinfPat lambdaDepth basis ptpat1
                val (varEnv2, ty2, tppat2) =
                  typeinfPat lambdaDepth basis ptpat2
                val _ =  
                  NPEnv.appi 
                  (fn (varNamePath, T.VARID {ty,...})
                   => (case NPEnv.find(varEnv2, varNamePath) of
                         SOME(T.VARID {ty=ty2,...}) => 
                           (U.unify [(ty1,ty2)]
                            handle U.Unify =>
                              (*
                               * type error informtion is incorrect
                               *)
                              E.enqueueError
                              (
                               loc,
                               E.InconsistentOrVarTypes
                               {var = NM.usrNamePathToString(varNamePath),
                                tys = [ty1, ty2]}
                               )
                              )
                       | _ => ()
                           )
                 | _ =>
                   raise
                     bug
                     "non VARID in varEnv\
                     \ (typeinference/main/TypeInferCore.sml)"
                   )
                  varEnv1
                val _ = U.unify [(ty1,ty2)]
                  handle U.Unify =>
                    (*
                     * different or pattern type
                     *)
                    E.enqueueError
                    (
                     loc,
                     E.DifferentOrPatternTypes
                     {ty1 = ty1, ty2= ty2}
                     )
              in
                (varEnv1, ty2, TPPATORPAT(tppat1,tppat2, loc))
              end
            else
              (
               E.enqueueError
               (
                loc,
                E.DIfferentOrPatternVars
                 {vars = map NM.usrNamePathToString (NPSet.listItems diffs)}
                );
               (NPEnv.empty, T.ERRORty, TPPATWILD (T.ERRORty, loc))
               )
            end)


  (**
   * infer a type for ptdecl
   * @params basis ptdeclList
   * @return  a new basis and tpdeclList
   *)
  and typeinfPtdeclList lambdaDepth isTop (basis:TIC.basis) nil = 
        (emptyContext, nil)
    | typeinfPtdeclList lambdaDepth isTop basis (PT.PTEMPTY :: ptdeclList) = 
        typeinfPtdeclList lambdaDepth isTop basis ptdeclList
    | typeinfPtdeclList lambdaDepth isTop basis (ptdecl :: ptdeclList) =  
        let 
          val (newContext1, tpdeclList1) =
              typeinfPtdecl lambdaDepth isTop basis ptdecl
          val (newContext2, tpdeclList) = 
               typeinfPtdeclList lambdaDepth isTop
               (TIC.extendBasisWithContext (basis, newContext1))
               ptdeclList
        in 
          (
           TC.extendContextWithContext
             {newContext = newContext2, oldContext =newContext1},
           tpdeclList1 @ tpdeclList
           )
      end

  (**
   * infer types for datatype declaration
   *)

  and typeinfConbind lambdaDepth
         (basis:TIC.basis) 
         ({tyCon, datacon} : T.dataTyInfo,
          (tyvars, tyConName, constructorList)) =
      let
(*
        val span = SOME (length constructorList)
*)
          (*
           * constructorEnv is established to maintain a canonical order 
           * on constructors. See the bug in email: imlcomp 1738.
           *)
        val constructorEnv = 
          foldl
          (fn (con as (_, constructorName, tyOption), constructorEnv) =>
             SEnv.insert(constructorEnv, constructorName, con))
          SEnv.empty
          constructorList
        val (_, conbinds) = 
          SEnv.foldl
          (fn ((_, cid, argTyOption), (index, conbinds)) =>
             let
               val (utvarEnv, argTyvarStateRefs) = 
                 foldr 
                 (fn ({name=tid, eq}, (utvarEnv, argTyvarStateRefs)) => 
                    if SEnv.inDomain(utvarEnv, tid) then
                      raise E.DuplicateTvarNameInDatatypeArgs {tyvar=tid}
                    else 
                      let 
                        val eq = if eq = Absyn.EQ then T.EQ else T.NONEQ
                        val newTvStateRef =
                          T.newUtvar (lambdaDepth, eq, tid)
                      in 
                        (
                         SEnv.insert(utvarEnv, tid, newTvStateRef),
                         newTvStateRef :: argTyvarStateRefs
                         )
                      end)
                 (SEnv.empty, nil)
                 tyvars
               val newBasis = TIC.overrideBasisWithUtvarEnv(basis, utvarEnv)
(*
  The following should be rejected:
   fun 'a f x = let datatype foo = A of 'a in A end
  For this, we need to flush the utvarEnv.

               val newBasis = TIC.extendBasisWithUtvarEnv(basis, utvarEnv)
*)
               val resultTy =
                 T.RAWty
                 {tyCon = tyCon, args = map T.TYVARty argTyvarStateRefs}
(*
 * Why should we re-calculate tyCon here?
                  val resultTy =
                    T.RAWty {tyCon = {name = #name tyCon,
                                      strpath = #strpath tyCon,
                                      id = #id tyCon,
                                      abstract = #abstract tyCon,
                                      eqKind = #eqKind tyCon,
                                      tyvars = #tyvars tyCon,
                                      span = span}, 
                             args = map T.TYVARty argTyvarStateRefs}
*)
                  val (funtyCon, tyBody) =  
                    case argTyOption of
                      SOME ty => 
                        let
                          val argTy = evalRawty newBasis ty
                        in
                          (true, T.FUNMty([argTy], resultTy))
                        end
                    | NONE => (false, resultTy)
                  val btvs =
                    (
                     foldl
                     (
                      fn (r as ref(T.TVAR (k as {id, ...})), btvs) =>
                          let
                            val btvid = Counters.nextBTid ()
                          in
                            (
                             r := T.SUBSTITUTED (T.BOUNDVARty btvid);
                             (
                              IEnv.insert
                              (
                               btvs,
                               btvid,
                               {
                                recordKind = (#recordKind k),
                                eqKind = (#eqKind k)
                                }
                               )
                              )
                             )
                          end
                       | _ => raise bug "generalizeTy"
                          )
                     IEnv.empty
                     (OTSet.listItems (TU.EFTV tyBody))
                    )
                    handle x => raise x
                in
                  (
                   index + 1,
                   SEnv.insert
                   (
                    conbinds,
                    cid,
                    T.CONID
                    {
                     namePath = (cid, P.NilPath),
                     funtyCon = funtyCon,
                     ty = if IEnv.isEmpty btvs
                            then tyBody
                          else                             
                            T.POLYty
                              {
                               boundtvars = btvs,
                               body = tyBody
                               },
                     tag = index,
                     tyCon = tyCon
                     }
                    )
                   )
                end)
            (0, SEnv.empty)
            constructorEnv
      in 
        (tyCon, conbinds)
      end

  and makeTyFun lambdaDepth
                (basis : TIC.basis)
                (tyvarList, (name, strpath), rawty) =
      let
        val (_, tvarSEnv, tvarIEnv) = 
          foldl
          (fn ({name=tyvarName, eq}, (n, tvarSEnv, tvarIEnv)) =>
             let 
               val newTy =
                 case T.newtyRaw{
                                 lambdaDepth = lambdaDepth,
                                 recordKind = T.UNIV, 
                                 eqKind =
                                   T.NONEQ (*if bool then EQ else T.NONEQ*),
                                   (* 
                                    * Ignore eq attribute in tyfun. 
                                    * This should be checked.
                                    * NONEQ 
                                    *) 
                                  tyvarName = NONE
                                 } 
                   of 
                     T.TYVARty newTy => newTy
                   | _ => raise bug "newty returns non TYVARty"
             in
               (
                n + 1,
                if SEnv.inDomain(tvarSEnv, tyvarName)
                  then
                    raise
                      E.DuplicateTargsInTypeDef
                      {tvars = [tyvarName]}
                else SEnv.insert(tvarSEnv, tyvarName, newTy),
                  IEnv.insert(tvarIEnv, n, newTy)
                  )
             end)
          (0, SEnv.empty, IEnv.empty)
          tyvarList
        val newcc = TIC.extendBasisWithUtvarEnv(basis, tvarSEnv)
        val originTy = evalRawty newcc rawty
        val eqKind = if TU.admitEqTy originTy then T.EQ else T.NONEQ
        val newTyCon = 
          TU.newTyCon 
          (Counters.newTyConId ())
          {name = name,
           strpath = strpath,
           abstract = false,
           tyvars =
             map
             (fn {eq,...} => if eq = Absyn.EQ then T.EQ else T.NONEQ)
             tyvarList,
           eqKind = ref eqKind, 
           constructorHasArgFlagList = nil}
        val aliasTy = 
          T.RAWty
            {tyCon = newTyCon, args = map T.TYVARty (IEnv.listItems tvarIEnv)}
        val ty = T.ALIASty(aliasTy,originTy)
        val btvEnv = 
          IEnv.foldl
          (fn (tvar as ref(T.TVAR (k as {id, ...})), btvEnv) => 
             let 
               val btvid = Counters.nextBTid ()
             in
               (
                tvar := T.SUBSTITUTED (T.BOUNDVARty btvid);
                IEnv.insert
                (
                 btvEnv,
                 btvid,
                 {
                  recordKind = (#recordKind k),
                  eqKind = (#eqKind k)
                  }
                 )
                )
             end
           | _ =>
             raise
             bug
             "non TYVAR in tvarEnv (typeinference/main/TypeInferCore.sml)"
          )
          IEnv.empty
          tvarIEnv
        val tyFun =
          {name = name, strpath = strpath, tyargs = btvEnv, body = ty}
      in
        (
         TC.bindTyConInEmptyContext ((name, strpath), T.TYFUN tyFun),
         tyFun
         )
      end

  and typeinfDatatypeDecl lambdaDepth
                          basis
                          (constructorPrefix, datbinds)
                          loc =
    let 
      val (tyConEnv, dataTyInfoList, dataCon) =
        typeinfDatabinds lambdaDepth basis datbinds loc
      val (newDataCon, _) = TIU.setPrefixDataCon(dataCon, constructorPrefix) 
      val newContext =
          TC.extendContextWithVarEnv (TC.injectTyConEnvToContext tyConEnv,
                                      newDataCon)
    in
        (newContext, dataTyInfoList)
    end

  and typeinfDatabinds lambdaDepth basis datbinds loc =
    let
      val (dataTyInfos, tyConEnv1) = 
        foldr
        (fn ((args,
              namePath
               as (name, strpath),
               conList : (bool * string * A.ty option) list), 
             (dataTyInfos, tyConEnv1)) => 
         let
           (* Liu: dummyDatacon is only used for calculating tagNumber 
            * in evalRawty function above; should be overwritten.
            *)
           val constructorHasArgFlagList = 
             map (fn (bool,string, SOME ty) => true | _ => false) conList
           val dummyDatacon = 
             let
               val dummyTyCon = 
                 {name = name,
                  strpath = strpath,
                  id = Counters.newTyConId (),
                  abstract = false,
                  eqKind = ref T.EQ,
                  tyvars = [],
                  constructorHasArgFlagList = constructorHasArgFlagList}
             in
               (#2
                 (foldl
                  (fn ((_, conName, argOpt), (dummyIndex, dummyDatacon)) =>
                     (dummyIndex + 1,
                      SEnv.insert(dummyDatacon,
                                  conName, 
                                  T.CONID
                                  {namePath = (conName, strpath),
                                   funtyCon =
                                     case argOpt of
                                       NONE => false
                                     | SOME _ => true,
                                   ty = T.DUMMYty dummyIndex,
                                   tag = 0,
                                   tyCon = dummyTyCon})))
                    (0, SEnv.empty)
                    conList))
             end
           val tyCon =
             TU.newTyCon
             (Counters.newTyConId ())
             {
              name = name,
              strpath = strpath,
              abstract = false,
              tyvars = map (fn {eq = Absyn.EQ,...} => T.EQ
                             | {eq = Absyn.NONEQ,...} => T.NONEQ)
                       args,
              eqKind = ref T.EQ,
              constructorHasArgFlagList = constructorHasArgFlagList
              }
           val dataTyInfo =
             {tyCon = tyCon, datacon = dummyDatacon} : T.dataTyInfo
         in
           (
            dataTyInfo :: dataTyInfos,
            NPEnv.insert(tyConEnv1, namePath, T.TYCON dataTyInfo)
            )
         end)
        (nil, NPEnv.empty)
        datbinds
      val _ =
        foldr
        (fn ({tyCon = {name, ...}, ...}, s) => 
           if SSet.member(s, name) then
             raise E.DuplicateTypeNameInDatatypes {tyConName=name}
           else SSet.add(s, name))
        SSet.empty 
        dataTyInfos
      val tyConSet =
        foldr (fn ({tyCon = {id, ...}, ...}, s) => TyConID.Set.add(s, id))
        TyConID.Set.empty
        dataTyInfos
      val datacons =
        (map
         (typeinfConbind
            lambdaDepth
            (TIC.extendBasisWithTyConEnv (basis, tyConEnv1)))
         (ListPair.zip (dataTyInfos, datbinds)))
        handle exn as E.DuplicateTvarNameInDatatypeArgs _ =>
          (E.enqueueError(loc, exn);
           nil
           )

      (* tyCon * datacon *)
      fun depends {namePath, funtyCon, ty, tyCon, tag} = 
        let 
          fun dep ty = 
            (case ty of 
               T.FUNMty _ => TyConID.Set.empty
             | T.RAWty {tyCon = {id, ...}, args} =>
                 foldr
                 (fn (ty, depset) => TyConID.Set.union(dep ty, depset))
                 (if TyConID.Set.member(tyConSet, id)
                    then TyConID.Set.singleton id
                  else TyConID.Set.empty)
                    args
               | T.TYVARty tid => TyConID.Set.empty
               | T.BOUNDVARty _ => TyConID.Set.empty
               | T.POLYty _ => raise bug "polyty in combind"
               | T.RECORDty fl => 
                   SEnv.foldr
                   (fn (ty, depsep) => TyConID.Set.union (dep ty, depsep))
                   TyConID.Set.empty
                   fl
               | T.ERRORty => TyConID.Set.empty
               | T.ALIASty (_, ty) => dep ty
               | T.OPAQUEty ({spec = {tyCon = {id, ...}, args}, ...}) =>
                   foldr
                   (fn (ty, depset) => TyConID.Set.union(dep ty, depset))
                   (if TyConID.Set.member(tyConSet, id)
                      then TyConID.Set.singleton id
                    else TyConID.Set.empty)
                      args
               | T.SPECty {tyCon = {id, ...}, args} =>
                   foldr
                   (fn (ty, depset) => TyConID.Set.union(dep ty, depset))
                   (if TyConID.Set.member(tyConSet, id)
                      then TyConID.Set.singleton id
                    else TyConID.Set.empty)
                      args
               | _ => raise bug "illegal type in combind")
        in 
          if funtyCon
            then
              case ty of
                T.FUNMty([ty1], ty2) => dep ty1
              | T.POLYty{body, ...} =>
                  (case body of
                     T.FUNMty([ty1], ty2) => dep ty1
                   | _ => raise bug "depends")
              | _ => raise bug "depends"
          else TyConID.Set.empty
        end

      (* 
       transitive closure computation of the dependency relation encoded in
       IEnv.
       *)
      fun tc ss = 
        if TyConID.Map.isEmpty ss
          then ss
        else 
          let 
            val (i, si) = valOf (TyConID.Map.firsti ss)
            val rest = #1 (TyConID.Map.remove(ss, i))
            val rest = 
              tc
              (TyConID.Map.map
               (fn x => 
                TyConID.Set.foldr
                (fn (j, sx) =>
                 TyConID.Set.union
                 (
                  sx,
                  if TyConID.eq(i,j)
                    then TyConID.Set.add(si, j)
                  else TyConID.Set.singleton j
                    ))
                TyConID.Set.empty
                x)
               rest)
            val si = 
              TyConID.Set.foldr
              (fn (j, csi) =>
               TyConID.Set.union
               (
                csi,
                if TyConID.eq(j, i)
                  then TyConID.Set.singleton j
                else
                  case TyConID.Map.find(rest, j) of
                    SOME s => TyConID.Set.add(s, j)
                  | _ => TyConID.Set.singleton j
                      ))
              TyConID.Set.empty
              si
          in 
            TyConID.Map.insert (rest, i, si)
          end
      val depEnv = 
        tc
        (foldr
          (fn (({name, strpath, abstract, tyvars, id, eqKind,...} : T.tyCon,
                conbind), depset) =>
             TyConID.Map.insert
               (
                depset,
                id,
                SEnv.foldr
                (fn (T.CONID conInfo, s) =>
                 TyConID.Set.union(depends conInfo,s)
              | _ => raise bug "illegal data con")
                TyConID.Set.empty
                conbind)
         )
         TyConID.Map.empty
         datacons)
      fun admitEq {namePath, funtyCon, ty, tyCon, tag} = 
        let 
          fun eqCon ty =
            (case ty of 
               T.FUNMty _ => false
             | T.RAWty {tyCon = {eqKind, id, ...}, args} =>
               if TyConID.eq(id, #id (PredefinedTypes.refTyCon)) then true
               else
                 if (foldr (fn (x,b) => eqCon x andalso b) true args)
                   then 
                     (if TyConID.Set.member(tyConSet, id)
                        then true
                      else (case !eqKind of T.EQ => true | _ => false))
                 else false
             | T.TYVARty (ref(T.SUBSTITUTED ty)) => eqCon ty
             | T.TYVARty (ref(T.TVAR k)) =>
                 (case k of
                    {eqKind = T.EQ, ...} => true
                  | {eqKind = T.NONEQ, ...} => false)
             | T.BOUNDVARty _ => true
             | T.POLYty _ => raise bug "polyty in combind"
             | T.RECORDty fl =>
                 SEnv.foldr (fn (ty, b) => (eqCon ty) andalso b) true fl
             | T.ALIASty (_, ty) => eqCon ty
             | T.ERRORty => true
             | T.OPAQUEty {spec = {tyCon = {eqKind, id, ...}, args}, ...} =>
                 if (foldr (fn (x,b) => eqCon x andalso b) true args)
                   then 
                     (if TyConID.Set.member(tyConSet, id)
                        then true
                      else (case !eqKind of T.EQ => true | _ => false))
                 else false
             | T.SPECty {tyCon = {eqKind, id, ...}, args} =>
                 if (foldr (fn (x,b) => eqCon x andalso b) true args)
                   then 
                     (if TyConID.Set.member(tyConSet, id)
                        then true
                      else (case !eqKind of T.EQ => true | _ => false))
                 else false
             | _ => raise bug "illegal type in combind")
        in
          if funtyCon
            then
              case ty of
                T.FUNMty([ty1], ty2) => eqCon ty1
              | T.POLYty{body, ...} =>
                  (case body of
                     T.FUNMty([ty1], ty2) => eqCon ty1
                   | _ => raise bug "depends")
              | T.ERRORty => true
              | _ => raise bug "depends"
          else true
        end
      val eqEnv = 
        foldr
        (fn (({id, ...}, conbind), eqEnv) =>
         TyConID.Map.insert
         (
          eqEnv,
          id,
          SEnv.foldr
          (fn (T.CONID conInfo, b) =>
               (admitEq conInfo) andalso b
            | _ => raise bug "datatype, eqEnv")
          true
          conbind
          ))
        TyConID.Map.empty
        datacons
      val eqFlags = 
        TyConID.Map.mapi
        (fn (originalId,depset) =>
         TyConID.Set.foldr
         (fn (dependId, b) => 
              case TyConID.Map.find(eqEnv, dependId) of
                SOME b1 => (b1 andalso b)
              | _ => raise bug "eqflagus")
         (case TyConID.Map.find(eqEnv, originalId) of
            SOME b => b
          | _ => raise bug "eqflagus")
            depset)
        depEnv
      val (tyConEnv2, newDataTyInfos) = 
        foldr
        (fn (({name,
               strpath,
               abstract,
               tyvars,
               id,
               eqKind,
               constructorHasArgFlagList},
              conBind), 
             (newTyConEnv, newDataTyInfos)
             ) =>
         let
           val _ =
             eqKind :=
             (if valOf(TyConID.Map.find(eqFlags, id)) then T.EQ else T.NONEQ)
                handle Option => raise bug "datbind"
           val newDataTyInfo = 
             {tyCon = {name = name, 
                       strpath = strpath, 
                       abstract = abstract,
                       tyvars = tyvars, 
                       id = id, 
                       eqKind = eqKind, 
                       constructorHasArgFlagList = constructorHasArgFlagList},
              datacon = conBind}
         in
           (NPEnv.insert
             (newTyConEnv, (name, strpath),  T.TYCON newDataTyInfo),
            newDataTyInfo :: newDataTyInfos)
         end)
        (NPEnv.empty, nil)
        datacons
(*
        val _ = TU.updateBoxedKinds tyCons
*)
      val varEnv1 = 
        foldr
        (fn ((_, con), vEnv)=> SEnv.unionWith #1 (con, vEnv))
        SEnv.empty
        datacons
    in
      (tyConEnv2, newDataTyInfos, varEnv1)
    end
  handle exn as E.DuplicateTypeNameInDatatypes _ =>
    (E.enqueueError(loc, exn);
     (NPEnv.empty, nil, SEnv.empty)
     )

  and typeinfExnbind lambdaDepth (basis:TIC.basis) exbind =
      case exbind of
        PT.PTEXBINDDEF(_, namePath, optRawty, loc) =>
        let 
          val optty =
              case optRawty of
                SOME rawty =>
                SOME(evalRawty basis rawty)
              | NONE => NONE
          val exnPathInfo as {namePath,funtyCon,ty,tyCon,tag} 
	    = (TIU.makeExnConPath namePath
                                  optty): Types.exnPathInfo
          val idState = T.EXNID exnPathInfo
	  val termConPathInfo = 
	      { namePath = namePath,
		funtyCon = funtyCon, 
		ty = ty, 
		tyCon = tyCon,
		tag = tag
                }
        in
          (TC.bindVarInEmptyContext
            (lambdaDepth, namePath, idState), [TPEXNBINDDEF(termConPathInfo)])
        end
      | PT.PTEXBINDREP (_, leftNamePath, _, rightNamePath, loc) => 
        (case TIC.lookupVarInBasis(basis, rightNamePath)  of
           SOME (idState
                   as (T.EXNID (conPathInfo as {tyCon = {id,...}, ...}))) => 
             if TyConID.eq(id, #id (PDT.exnTyCon))
             then
               let
                 val newIdState = T.EXNID 
				          {
				           namePath = leftNamePath,
				           funtyCon = #funtyCon conPathInfo,
				           ty = #ty conPathInfo,
				           tag = #tag conPathInfo,
				           tyCon = #tyCon conPathInfo
				           }
	         in
                   (
                    TC.bindVarInEmptyContext
                      (lambdaDepth, leftNamePath, newIdState),
		    [TPEXNBINDREP (leftNamePath, rightNamePath)]
                   )
	         end
             else 
                 (
                  E.enqueueError
                  (loc,
                   E.NotExnCon{tyCon = NM.usrNamePathToString(rightNamePath)});
                  (TC.emptyContext, nil)
                  )
         | SOME _  =>
           (
             E.enqueueError
              (loc,
               E.NotExnCon{tyCon = NM.usrNamePathToString(rightNamePath)});
             (TC.emptyContext, nil)
           )
         | _ => 
           (
             E.enqueueError
             (loc,
              E.VarNotFound{id = NM.usrNamePathToString(rightNamePath)});
             (TC.emptyContext, nil)
           ))

            
  (**
   * infer types for declaration
   * @params basis ptdecl
   * @return a new basis a tpdec
   *
   * exceptions
      E.RecValNotID
      E.DuplicateTargsInTypeDef
   *)
  and typeinfPtdecl lambdaDepth isTop (basis:TIC.basis) ptdecl =
    let
      val lambdaDepth = lambdaDepth
    in
      (case ptdecl of
         PT.PTVAL (kindedTvarSet, tvarNameSet, ptpatPtexpList, loc) => 
         let 
           val lambdaDepth = incDepth ()
           val _ =
             foldl 
             (fn ((ptpat, _), set2) => 
              let
                val set1 = freeVarsInPat basis ptpat
                val duplicates = NPSet.intersection (set1,set2)
              in
                if NPSet.isEmpty duplicates
                  then NPSet.union(set1, set2)
                else
                  (
                   E.enqueueError
                   (
                    loc,
                    E.DuplicatePatternVar
                     {vars =
                       map NM.usrNamePathToString (NPSet.listItems duplicates)}
                    );
                   NPSet.union(set1, set2)
                   )
              end)
             NPSet.empty
             ptpatPtexpList
             
(*
           (* if the above error check fails then we change the pattern
              to wild pattern and continue compiling
            *)
           val ptpatPtexpList =
             if E.isError() then  
               map
               (fn (ptPat,ptExp)
                  => (PT.PTPATWILD (PT.getLocPat ptPat),ptExp))
               ptpatPtexpList
             else ptpatPtexpList
*)

           val (localBinds, patternVarBinds, extraBinds) = 
             foldr
             (fn ((ptpat, ptexp), (localBinds, patternVarBinds, extraBinds)) =>
              let
                val (newBasis, addedUtvars1) =
                  evalKindedTvarSet lambdaDepth basis kindedTvarSet loc
                val (newBasis, addedUtvars2) =
                  TIC.addUtvarIfNotthere(lambdaDepth, newBasis, tvarNameSet)
                val (localBinds1, patternVarBinds1, extraBinds1) = 
                  (decomposeValbind
                    lambdaDepth
                    (
                     newBasis,
                     false
                     )
                    (ptpat, ptexp))
                  handle
                    exn as E.RecordLabelSetMismatch =>
                    (
                     E.enqueueError
                     (Loc.mergeLocs (PT.getLocPat ptpat, PT.getLocExp ptexp),
                      exn);
                     (nil, nil, nil)
                     )
                  | exn as E.PatternExpMismatch _ => 
                    (
                     E.enqueueError
                     (Loc.mergeLocs (PT.getLocPat ptpat, PT.getLocExp ptexp),
                      exn);
                     (nil, nil, nil)
                     )

                (*
                 The following is added to fix the bug 68.
                 *)
                val tyvarSet =
                  (
                   foldl 
                   (fn ((T.VALIDVAR {namePath, ty}, _), tyvarSet) =>
                      OTSet.union(TU.EFTV ty, tyvarSet)
                     | (_, tyvarSet) =>  tyvarSet
                    )
                   OTSet.empty
                   (patternVarBinds1@extraBinds1)
                   )
                  handle x => raise x
                val _ =
                  (
                   SEnv.appi
                   (fn (tyname, ref (T.SUBSTITUTED ty)) =>
                       (case TU.derefSubstTy ty of
                          T.BOUNDVARty _ => ()
                        | T.TYVARty (tvstateRef as ref (T.TVAR {eqKind,...}))
                          =>
                          if OTSet.member(tyvarSet, tvstateRef) then
                            E.enqueueError
                              (loc,
                               E.UserTvarNotGeneralized
                                 {utvarName =
                                  (case eqKind of T.EQ => "''"
                                                | T.NONEQ  => "'")
                                  ^ tyname})
                          else ()
                        | _ => 
                          (
                           printType ty; 
                           raise bug "SUBSTITUTED to Non BoundVarTy"
                          )
                       )
                     | (tyname, tvstateRef as (ref (T.TVAR {eqKind,...})))  => 
                       if OTSet.member(tyvarSet, tvstateRef) then
                         E.enqueueError
                         (loc,
                          E.UserTvarNotGeneralized
                           {utvarName =
                             (case eqKind of T.EQ => "''" | T.NONEQ  => "'")
                                ^ tyname})
                       else ()
                    )
                   (SEnv.unionWith #1 (addedUtvars1, addedUtvars2))
                  )
                  handle x => raise x
              in
                (
                 localBinds1 @ localBinds,
                 patternVarBinds1 @ patternVarBinds,
                 extraBinds1 @ extraBinds
                 )
              end)
             (nil, nil, nil)
             ptpatPtexpList
           fun bindVarInVarEnv (lambdaDepth, varEnv, namePath, idstate) = 
               (TU.adjustDepthInIdstate lambdaDepth idstate;
                NPEnv.insert(varEnv, namePath, idstate))
           val newVarEnv = 
             foldl 
             (fn ((T.VALIDVAR {namePath, ty}, _), newVarEnv) =>
                let
                  val varInfo =
                    {namePath = namePath, ty = ty}
                in
                  bindVarInVarEnv
                    (lambdaDepth, newVarEnv, namePath, T.VARID varInfo)
                end
               | (_, newVarEnv) => newVarEnv
             )
             T.emptyVarEnv
             (patternVarBinds@extraBinds)
         in
           (
             TC.injectVarEnvToContext newVarEnv,
             let
               val exportDecls = 
                 (if null patternVarBinds then nil
                  else [TPVAL (patternVarBinds, loc)])
                    @
                 (if null extraBinds then nil else [TPVAL (extraBinds, loc)])
             in
               case localBinds of
                 nil => exportDecls
               | _ => 
                   [
                    TPLOCALDEC
                    (
                     map (fn x => TPVAL ([x], loc)) localBinds,
                     exportDecls,
                     loc
                     )
                    ]
             end
            )
         end
       | PT.PTDECFUN (kindedTvarSet,
                      tvarNameSet,
                      ptpatPtpatListPtexpListList,
                      loc) =>
         let
           val lambdaDepth = incDepth ()
           val (newBasis, addedUtvars1) =
               evalKindedTvarSet lambdaDepth basis kindedTvarSet loc
           val (newBasis, addedUtvars2) =
               TIC.addUtvarIfNotthere(lambdaDepth, newBasis, tvarNameSet)
           fun getFunIdFromPat (PT.PTPATID (longid, _)) = longid
             | getFunIdFromPat (PT.PTPATTYPED(pat, _,_)) = getFunIdFromPat pat
             | getFunIdFromPat _ = raise bug "non id pat in fundecl"
           fun arityAndArgTyListOfMatch match =
             case match of
               nil => raise bug "empty match in fundecl"
             | (patList,exp)::_ =>
                 (List.length patList,
                  map
                    (fn _ => T.newtyWithLambdaDepth (lambdaDepth, T.univKind))
                    patList
                  )
           val (newBasis, funTyList) =
             foldr
             (fn ((funPat, ptmatch), (newBasis, funTyList)) =>
              let
                val funId = getFunIdFromPat funPat
                val (arity, argTyList) = arityAndArgTyListOfMatch ptmatch
                val funTy = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
(*
                val strpath = T.NilPath
*)
                val funVarPathInfo = {namePath = funId, ty = funTy}
              in
                (
                  TIC.bindVarInBasis
                   (lambdaDepth,
                    newBasis, 
                    funId, 
                    T.RECFUNID (funVarPathInfo, length argTyList)
                    ),
                  funTy::funTyList)
              end
            )
             (newBasis, nil)
             ptpatPtpatListPtexpListList
           val ptpatRuleFunTyList =
             ListPair.zip (ptpatPtpatListPtexpListList,funTyList)
           val funBindList = 
             foldr
             (fn (((funPat, ptmatch),funTy), funBindList) =>
              let
                val funId = getFunIdFromPat funPat
                val (arity, argTyList) = arityAndArgTyListOfMatch ptmatch
                val funVarPathInfo = {namePath = funId, ty = funTy}
                val (tpmatchTy, tpmatch) =
                  monoTypeinfMatch lambdaDepth argTyList newBasis ptmatch
                fun curryTy (T.FUNMty(argTyList, ty)) = 
                    foldr (fn (ty, body) => T.FUNMty([ty], body)) ty argTyList
                  | curryTy ty = ty
                val funType = curryTy (TU.derefTy tpmatchTy)
                val _ =
                  U.unify [(funTy, funType)]
                  handle U.Unify =>
                    E.enqueueError
                    (
                     loc,
                     E.RecDefinitionAndOccurrenceNotAgree
                     {
                      id = NM.usrNamePathToString(funId),
                      definition = funType,
                      occurrence = funTy
                      }
                     )
              in
                {
                  funVar = funVarPathInfo,
                  bodyTy = case TU.derefTy tpmatchTy of
                             T.FUNMty (_, bodyTy) => bodyTy
                           | T.ERRORty =>  T.ERRORty
                           | _ => raise bug "non fun type in fundecl",
                  argTyList = argTyList,
                  ruleList = tpmatch
                  } ::funBindList
              end 
            )
             nil
             ptpatRuleFunTyList

           val TypesOfAllElements =  
               T.RECORDty
               (foldr
                (fn ({funVar={namePath, ty},...}, tyFields) =>
                   SEnv.insert(tyFields, NM.usrNamePathToString(namePath), ty))
                SEnv.empty
                funBindList)
           val {boundEnv, ...} =
               generalizer (TypesOfAllElements, lambdaDepth)
           val _ =
             SEnv.appi
               (fn (tyname, ref (T.SUBSTITUTED ty)) =>
                   (case TU.derefSubstTy ty of
                      T.BOUNDVARty _ => ()
                    | T.TYVARty (tvstateRef as ref (T.TVAR {eqKind,...}))
                      =>
                      E.enqueueError
                        (loc,
                         E.UserTvarNotGeneralized
                           {utvarName =
                            (case eqKind of T.EQ => "''"
                                          | T.NONEQ  => "'")
                            ^ tyname})
                    | _ => 
                      (
                       printType ty; 
                       raise
                         bug
                           "illeagal utvar instance in\
                           \ UserTvarNotGeneralized  check"
                      )
                   )
                 | (tyname, ref (T.TVAR {eqKind,...}))  => 
                     E.enqueueError
                     (loc, 
                      E.UserTvarNotGeneralized 
                      {
                       utvarName = 
                       (case eqKind of T.EQ => "''" | T.NONEQ  => "'") 
                          ^ tyname
                          }
                      )
               )
               (SEnv.unionWith #1 (addedUtvars1, addedUtvars2))
         in
           if IEnv.isEmpty boundEnv
           then
             (
               foldr
               (fn ({
                     funVar as {namePath, ty},
                     argTyList,
                     bodyTy,
                     ruleList
                     }, 
                    newContext) =>
                TC.bindVarInContext
                (
                 lambdaDepth,
                 newContext, 
                 namePath,
                 if isTop then
                   T.VARID {namePath = namePath, ty = ty}
                 else
                   T.RECFUNID
                   ({namePath = namePath, ty = ty}, length argTyList)
                 )
                )
               TC.emptyContext
               funBindList,
               [TPFUNDECL (funBindList, loc)] 
               )
           else 
             (
               foldr
               (fn ({funVar=funVar as {namePath, ty}, argTyList,...},
                    newContext) => 
                TC.bindVarInContext
                (
                 lambdaDepth,
                 newContext, 
                 namePath, 
                 if isTop then
                   T.VARID
                   {namePath = namePath,
                    ty = T.POLYty{boundtvars=boundEnv,
                                  body = ty}}
                 else 
                   T.RECFUNID
                   (
                    {namePath = namePath,
                     ty = T.POLYty{boundtvars=boundEnv, body = ty}},
                    length argTyList
                    )
                 )
                )
               TC.emptyContext
               funBindList,
               [TPPOLYFUNDECL
                (boundEnv, 
                 funBindList, 
                 loc)]
               )
         end
       | PT.PTNONRECFUN (kindedTvarSet,
                         tvarNameSet,
                         ptpatPtpatListPtexp,
                         loc) =>
         let
           val lambdaDepth = lambdaDepth
           val ptdecls = 
             case ptpatPtpatListPtexp of
               (funPat
                 as (PT.PTPATID (_, patLoc)), ruleList as (([pat], exp)::_)) =>
                 [(funPat, PT.PTFNM(SEnv.empty, ruleList, loc))]
             | (funPat
                 as (PT.PTPATID (_, patLoc)), [(patList as (pat::_), exp)]) =>
                 (let
                   val (_, (firstLoc, patFields, lastLoc)) = 
                     foldl
                     (fn (pat, (n, (firstLoc, patFields, lastLoc))) => 
                        (n+1,
                         (
                          firstLoc,
                          (Int.toString n,pat)::patFields,
                          PT.getLocPat pat)
                         )
                        )
                     (1,(PT.getLocPat pat, nil, PT.getLocPat pat))
                     patList
                   val _ =
                     freeVarsInPat
                     basis
                     (PT.PTPATRECORD
                       (false, 
                        patFields,
                        Loc.mergeLocs(firstLoc, lastLoc)))
                  in
                    [(funPat,
                      foldr
                      (fn (pat, funBody) =>
                         PT.PTFNM(SEnv.empty, [([pat], funBody)], loc))
                      exp
                      patList)
                     ]
                  end
                )
              | _ => transFunDecl basis loc ptpatPtpatListPtexp
         in 
             typeinfPtdecl lambdaDepth
                           isTop
                           basis
                           (PT.PTVAL
                                (kindedTvarSet, 
                                 tvarNameSet, 
                                 ptdecls, 
                                 loc)
                           )
         end
       | PT.PTVALREC (kindedTvarSet, tvarNameSet, ptpatPtexpList, loc) => 
         let
           val lambdaDepth = incDepth ()
           val (newBasis, addedUtvars1) =
               evalKindedTvarSet lambdaDepth basis kindedTvarSet loc
           val (newBasis, addedUtvars2) =
               TIC.addUtvarIfNotthere(lambdaDepth, newBasis, tvarNameSet)
           val funIds = 
                map
                    (fn (PT.PTPATID (longid, _), _) => longid
                      | (PT.PTPATTYPED
                             (PT.PTPATID
                                  (longid, _),_,_),_) => longid
                      | _ => raise bug "recvalnotid in typeinf")
                    ptpatPtexpList
           val (tys, newBasis) = 
               foldr
               (fn (varId, (tys, newBasis)) => 
                  let
                    val ty = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                    val varInfo =
                      {namePath = varId, ty = ty}
                  in
                    (
                     ty :: tys,
                     TIC.bindVarInBasis
                     (lambdaDepth, newBasis, varId, T.VARID varInfo)
                     )
                  end)
               (nil, newBasis)
               funIds
           val varIDTyTpexpList = 
             let
               fun inferRule (namePath, ptexp) =
                   let 
                     val (ptexpTy, tpexp) =
                         typeinfExp lambdaDepth inf newBasis ptexp
                     val stringTy =
                         case TIC.lookupVarInBasis(newBasis, namePath) of
                           SOME (T.VARID{ty, ...}) => ty
                         | _ => raise bug "typeinfRecbind" 
                     val _ =
                         U.unify [(stringTy, ptexpTy)]
                         handle
                           U.Unify =>
                             E.enqueueError
                             (
                              loc,
                              E.RecDefinitionAndOccurrenceNotAgree
                              {
                               id = NM.usrNamePathToString(namePath),
                               definition = ptexpTy,
                               occurrence = stringTy
                               }
                              )
                     val varID = {namePath = namePath, ty = ptexpTy}
                   in
                     {var=varID, expTy=ptexpTy, exp=tpexp}
                   end 
             in
               map
               (fn (PT.PTPATID (longid, _), ptexp) => 
                   inferRule (longid, ptexp)
                 | (PT.PTPATTYPED
                     (PT.PTPATID((string, Path.NilPath), _), _, _), ptexp) => 
                   inferRule ((string, Path.NilPath), ptexp)
                 | _ => raise bug "typeinfRecbind, not a variable"
                )
               ptpatPtexpList
             end
           val TypesOfAllElements =  
               T.RECORDty
               (foldr
                (fn ({var={namePath = funId, ...}, expTy, ...}, tyFields) =>
                   SEnv.insert(tyFields,NM.usrNamePathToString(funId), expTy))
                SEnv.empty
                varIDTyTpexpList)
           val {boundEnv, ...} =
               generalizer (TypesOfAllElements, lambdaDepth)
           val _ =
             SEnv.appi
               (fn (tyname, ref (T.SUBSTITUTED (T.BOUNDVARty _))) =>()
                 | (tyname, ref (T.TVAR{eqKind,...}))  => 
                     E.enqueueError
                     (loc, 
                      E.UserTvarNotGeneralized 
                        {utvarName = 
                         (case eqKind of T.EQ => "''" | T.NONEQ  => "'") 
                            ^ tyname}
                     )
                 | _ =>
                     raise
                       bug
                       "illeagal utvar instance in\
                       \ UserTvarNotGeneralized  check"
               )
               (SEnv.unionWith #1 (addedUtvars1, addedUtvars2))
         in
           if IEnv.isEmpty boundEnv
           then
             (
               foldr
                   (fn ({var=varID as {namePath,ty}, ...}, newContext) =>
                    TC.bindVarInContext
                        (
                         lambdaDepth,
                         newContext, 
                         namePath, 
                         T.VARID 
                         {namePath = namePath,ty = ty}
                         ))
                   (TC.emptyContext)
                   varIDTyTpexpList,
               [TPVALREC (varIDTyTpexpList, loc)]
             )
           else 
             (
               foldr
                   (fn ({var=varID as {namePath, ty},...}, newContext) => 
                       TC.bindVarInContext
                           (
                            lambdaDepth,
                            newContext, 
                            namePath, 
                            T.VARID
                             {
                               namePath = namePath,
                               ty = T.POLYty{boundtvars = boundEnv, body = ty}
                             }
                           ))
                   TC.emptyContext
                   varIDTyTpexpList,
               [TPVALPOLYREC (boundEnv, varIDTyTpexpList, loc)]
             )
         end
       | PT.PTVALRECGROUP(ids, ptdecls, loc) =>
         let 
           val (newContext, tpdeclList) =
               typeinfPtdeclList lambdaDepth isTop basis ptdecls
         in
           (newContext, [TPVALRECGROUP(ids, tpdeclList, loc)])
         end

       | PT.PTDATATYPE (constructorPrefix, datbinds, loc) =>
	 let
	   val (newContext, dataTyInfoList) =
               typeinfDatatypeDecl
               lambdaDepth
               basis
               (constructorPrefix, datbinds) loc
	 in 
	   (newContext, [TPDATADEC(dataTyInfoList, loc)])
	 end
       | PT.PTABSTYPE (constructorPrefix, datbinds, ptdecls, loc) =>
	 let
	   val (tyConEnv, tyCons, dataCon) = 
               typeinfDatabinds lambdaDepth basis datbinds loc
           val (newDataCon, _) =
             TIU.setPrefixDataCon(dataCon, constructorPrefix) 
           val newContext =
             TC.extendContextWithVarEnv
             (
              TC.injectTyConEnvToContext tyConEnv,
              newDataCon
              )
           val newBasis = TIC.extendBasisWithContext (basis, newContext)
           val (newContext, newDecls) =
             typeinfPtdeclList lambdaDepth isTop newBasis ptdecls
           val (tyConSubst, newDataTyInfos, newTyConEnv) =
               foldr
               (fn ({tyCon =
                     {name,
                      strpath,
                      abstract,
                      tyvars,
                      id,
                      eqKind,
                      constructorHasArgFlagList}, 
                     datacon}, 
                    (tyConSubst, newDataTyInfos, newTyConEnv)) =>
                  let
                    val newDataTyInfo =
                      {tyCon =
                         TU.newTyCon
                         (Counters.newTyConId ())
                         {
                          name = name,
                          strpath = strpath,
                          abstract = true, 
                          tyvars = tyvars,
                          eqKind = ref T.NONEQ,
                          constructorHasArgFlagList = constructorHasArgFlagList
                         },
                       datacon = datacon}
                  in
                    (TyConID.Map.insert(tyConSubst, id, T.TYCON newDataTyInfo),
                     newDataTyInfo :: newDataTyInfos,
                     NPEnv.insert
                       (newTyConEnv, (name, strpath), T.TYCON newDataTyInfo))
                  end
                )
               (TyConID.Map.empty, nil, NPEnv.empty)
               tyCons
           val newContext = TCU.substTyConInContextFully tyConSubst newContext
	   val absLocalContext = TC.injectTyConEnvToContext newTyConEnv
           val newContext =
               TC.extendContextWithContext
		 {
		  newContext = newContext,
		  oldContext = absLocalContext
		  }
	 in 
	     (
              newContext, 
              [TPABSDEC
               ({absDataTyInfos = newDataTyInfos,
                 rawDataTyInfos = tyCons,
                 decls = newDecls},
                loc
                )
               ]
              )
	 end
       | PT.PTLOCALDEC (ptdecls1, ptdecls2, loc) =>
           let 
             val (newContext1, tpdeclList1) =
               typeinfPtdeclList lambdaDepth false basis ptdecls1
             val (newContext2, tpdeclList2) =
               typeinfPtdeclList lambdaDepth isTop
               (TIC.extendBasisWithContext(basis, newContext1))
               ptdecls2
           in
             (newContext2,  [TPLOCALDEC (tpdeclList1, tpdeclList2, loc)])
           end
       | PT.PTINTRO ((tyNamePathEnv, varNamePathEnv), strPathPair, loc) =>
         let
           val tyConEnv =
             NPEnv.foldli
             (fn (namePath, tyState, newTyConEnv) =>
                let
                  val actualNamePath = NM.getNamePathFromTyState tyState
                in
                  case TIC.lookupTyConInBasis(basis, actualNamePath) of 
                    NONE => 
                      (E.enqueueError
                         (loc,
                          E.TyConNotFoundInIntro
                          {tyCon = 
                           NM.usrNamePathToString actualNamePath});
                         newTyConEnv)
                  | SOME tyBindInfo => 
                      NPEnv.insert(newTyConEnv, namePath, tyBindInfo)
                end)
             NPEnv.empty
             tyNamePathEnv
           val varEnv = 
             NPEnv.foldli
             (fn (namePath, varState, newVarEnv) =>
                let
                  val actualNamePath = NM.getNamePathFromIdstate varState
                in
                  case TIC.lookupVarInBasis(basis, actualNamePath) of 
                    NONE => 
                      (E.enqueueError
                         (loc,
                          E.VarNotFound
                            {id = NM.usrNamePathToString actualNamePath});
                         newVarEnv)
                  | SOME idstate => 
                      NPEnv.insert(newVarEnv, namePath, idstate)
                end)
             NPEnv.empty
             varNamePathEnv

             val newContext = 
               let
                 val freshStrpathEnv =
                   TIU.updateStrpathInEnv (tyConEnv, varEnv) strPathPair
                 in
                     TC.injectEnvToContext freshStrpathEnv
                 end
         in
           (newContext, [TPINTRO ((tyNamePathEnv, varNamePathEnv),
                                  (tyConEnv, varEnv), 
                                  strPathPair,
                                  loc)])
         end
       | PT.PTTYPE (tvarListStringRawtyList, loc) => 
         (let
            val (newContext, tyFunList) =
              foldr
              (fn (tydecl, (newContext, tyFunList)) => 
                 let
                   val (tyFunContext, tyFun as {name, strpath, tyargs, body}) =
                     makeTyFun lambdaDepth basis tydecl
                 in
                   (
                    TC.extendContextWithContext
                    {newContext = tyFunContext, oldContext = newContext},
                    (T.TYFUN tyFun) :: tyFunList
                    )
                 end)
              (
               TC.emptyContext,
               nil
               )
              tvarListStringRawtyList
          in
            (newContext, [TPTYPE (tyFunList, loc)])
          end
            handle exn as E.DuplicateTargsInTypeDef _ =>
                   (
                     E.enqueueError (loc,exn);
                     (
                       TC.emptyContext,
                       nil
                     )
                   ))
       | PT.PTREPLICATEDAT ((string1, strpath1), namePath2 , loc) => 
         (case TIC.lookupTyConInBasis(basis, namePath2) of
            SOME tyBindInfo =>
              (case tyBindInfo of
                 T.TYCON (rightDataTyInfo as {tyCon = rightTyCon, datacon}) => 
	           let
                     val {name,
                          strpath,
                          abstract,
                          tyvars,
                          id,
                          eqKind,
                          constructorHasArgFlagList} : tyCon = rightTyCon
		       val leftTyCon : tyCon = 
		           {name = string1,
                            strpath = strpath1,
		            abstract = abstract,
                            tyvars = tyvars,
		            id = id,
		            eqKind = eqKind,
                            constructorHasArgFlagList =
                              constructorHasArgFlagList
                           } 
		       val tyConSubst = 
                           TyConID.Map.singleton
                             (id, T.TYCON {tyCon=leftTyCon, datacon = datacon})
		       val newDatacon = 
                           TCU.substTyConInDataConFully tyConSubst datacon
		       val leftTyCon = 
                           {
                            name = #name leftTyCon,
                            strpath = #strpath leftTyCon,
                            id = #id leftTyCon,
                            abstract = #abstract leftTyCon,
                            eqKind = #eqKind leftTyCon,
                            tyvars = #tyvars leftTyCon,
                            constructorHasArgFlagList =
                              #constructorHasArgFlagList leftTyCon
                           }
                       val leftDataTyInfo =
                         {tyCon = leftTyCon, datacon = newDatacon}
		       val context1 =
                           TC.bindTyConInEmptyContext
                               (
                                (string1, strpath1),
			        T.TYCON leftDataTyInfo
                               )
		       val context2 = 
		           if not abstract then
                             let
                               val (newDatacon, _) =
                                 TIU.setPrefixDataCon (newDatacon, strpath1)
                             in
                               TC.extendContextWithVarEnv
                                 (context1, newDatacon)
                             end
		           else context1
	           in
		       (
                        context2,
                        [TPDATAREPDEC
                             (
                              {
			       left = leftDataTyInfo, 
			       right =
                               {
			        name = NM.usrNamePathToString namePath2,
			        dataTyInfo = rightDataTyInfo
			       }
			      },
                              loc
                        )]
	               )
	           end
	         | _ =>
                   (
                    E.enqueueError
                    (
                     loc,
                     E.TyConNotFoundInReplicateData
                       {tyCon = NM.usrNamePathToString(namePath2)}
                       );
		    (
                     TC.emptyContext,
                     nil
                    )
                   )
	      )
          | NONE =>
            (
             E.enqueueError
               (loc,
                E.TyConNotFoundInReplicateData
                  {tyCon = NM.namePathToString(namePath2)});
               (TC.emptyContext, nil)
               ))
      | PT.PTEXD (exnBinds, loc) =>
        let 
          val (newContext, newExnBinds) =
              foldr
                  (fn (exnBind, (newContext, newExnBinds)) =>
                      let
                        val (localContext, newExnBind) =
                            typeinfExnbind lambdaDepth basis exnBind
                      in
                        (
                          TC.extendContextWithContext
                          {oldContext = localContext, newContext = newContext},
                          newExnBind :: newExnBinds
                        )
                      end)
                  (TC.emptyContext, nil)
                  exnBinds
        in
          (newContext, [TPEXNDEC (List.concat(newExnBinds), loc)])
        end
      | PT.PTINFIXDEC (n, idlist, loc) =>
        (TC.emptyContext, [TPINFIXDEC(n, idlist, loc)])
      | PT.PTINFIXRDEC (n, idlist, loc) =>
        (TC.emptyContext, [TPINFIXRDEC(n, idlist, loc)])
      | PT.PTNONFIXDEC (idlist, loc) =>
        (TC.emptyContext, [TPNONFIXDEC(idlist, loc)])
      | PT.PTEMPTY => raise bug "try to infer type for the empty dec"
    )
   end
  
   fun typeinfTopPtdecl lambdaDepth (basis:TIC.basis) ptdecl =
     let
        val _ = maxDepth := T.toplevelDepth
(*
        val _ = T.kindedTyvarList := nil
*)
        val _ = ffiApplyTyvars := nil
        val (newContext, tpdeclList) =
          typeinfPtdecl lambdaDepth true basis ptdecl
     in
       if E.isError() then 
         (newContext, tpdeclList)
       else
         let
(*
           val tyvars = TypeContextUtils.tyvarsContext newContext
           val dummyTyList =
             (foldr
              (fn (r
                   as
                   ref(T.TVAR
                        {recordKind = T.OCONSTkind (h::_), ...}),
                   dummyTyList) => 
                  (r := T.SUBSTITUTED h; dummyTyList)
                | (r
                   as
                   ref(T.TVAR
                     {recordKind = T.OPRIMkind {instances = (h::_),...},...}),
                   dummyTyList) => 
                  (r := T.SUBSTITUTED h; dummyTyList)
                | (r as ref (T.TVAR {recordKind=T.UNIV, ...}), dummyTyList) =>
                  let
                    val dummyty = TIU.nextDummyTy ()
                    val _ = r := (T.SUBSTITUTED dummyty)
                  in
                    dummyty :: dummyTyList
                  end
                | (**** temporary fix of BUG 200 ***)
                  (r as ref (T.TVAR {recordKind=T.REC tySEnvMap, ...}),
                             dummyTyList) =>
                    let
                      val _ = r := (T.SUBSTITUTED (T.RECORDty tySEnvMap))
                    in
                      dummyTyList
                    end
                | (r as ref (T.SUBSTITUTED _), dummyTyList) => dummyTyList
                | _ =>
                    raise
                      bug
                      "non tvar in dummytyvars\
                      \ (typeinference/main/TypeInferCore.sml)"
             )
              nil
              (OTSet.listItems tyvars)
              )
             handle x => raise x
           val _ =
             case dummyTyList of
               nil => ()
             | _ =>
                 E.enqueueWarning
                 (PT.getLocDec ptdecl,
                  E.ValueRestriction {dummyTyList = dummyTyList})
           val _ = TIU.eliminateVacuousTyvars()
*)
           val _ = List.app (fn (ty as T.TYVARty(ref(T.TVAR _)), loc) =>
                                E.enqueueError (loc, E.FFIInvalidTyvar ty)
                              | _ => ())
                            (!ffiApplyTyvars)
         in
           (newContext, tpdeclList)
         end
     end
   handle x => raise x
end
end
