(**
 * Copyright (c) 2006, Tohoku University.
 *
 * a kinded type inference with type operators for ML core
 * (imperative version).
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypeInferCore.sml,v 1.55 2006/02/19 10:52:34 ohori Exp $
 *)
structure TypeInferCore  =
struct
local 
  structure A = Absyn
  structure E = TypeInferenceError
  structure P = Path
  structure PT = PatternCalcWithTvars
  structure SE = StaticEnv
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

  val emptyContext = TC.emptyContext

  open Types
  open TypedCalc
in
 (* for debugging *)
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

 (* type generalization *)
 fun generalizer (ty, {varEnv, utvarEnv,...}: TIC.currentContext) =
   if E.isError()
     then {boundEnv = IEnv.empty, removedTyIds = OTSet.empty}
   else TypesUtils.generalizer (ty, varEnv, utvarEnv)

  type rawty = A.ty

  fun getRuleLocM nil = raise Control.Bug "emptyruke in getRuleLocM"
    | getRuleLocM [(pat::_,exp)] =
        Loc.mergeLocs (PT.getLocPat pat, PT.getLocExp exp)
    | getRuleLocM rules =
        let
          val (pat1::_, _) = List.hd rules
          val (_, exp2) = List.last rules
        in
          Loc.mergeLocs (PT.getLocPat pat1, PT.getLocExp exp2)
        end
  fun evalRawty currentContext rawty =
      case rawty of
        A.TYID ({name=string,ifeq=isEq}, loc) =>
        (case TIC.lookupUtvar (currentContext, string) of
           NONE =>
             (E.enqueueError(loc, E.NotBoundTyvar{tyvar = string}); ERRORty)
         | SOME ty => 
             if isEq then 
               if TU.admitEqTy ty then ty
               else (E.enqueueError(loc, E.InconsistentEQInDatatype {tyvar = string}); ERRORty)
             else 
               if TU.admitEqTy ty then 
                 (E.enqueueError(loc, E.InconsistentEQInDatatype {tyvar = string}); ERRORty)
               else ty
             )
      | A.TYRECORD (stringRawtyList, loc) =>
          RECORDty
          (foldr
           (fn ((l, rawty), fields) => 
            SEnv.insert (fields, l, evalRawty currentContext rawty))
           SEnv.empty
           stringRawtyList)
      | A.TYCONSTRUCT (rawtyList, stringList, loc) =>
          let
            val tyList = map (evalRawty currentContext) rawtyList
          in
            case TIC.lookupLongTyCon(currentContext, stringList) of
              (_, SOME(TYCON tyCon)) =>
                let
                  val wants = List.length (#tyvars tyCon)
                  val given = List.length tyList
                in
                  if wants = given
                    then CONty{tyCon = tyCon, args = tyList}
                  else
                    (
                     E.enqueueError
                     (
                      loc, 
                      E.ArityMismatchInTypeDeclaration
                      {
                       wants = wants,
                       given = given,
                       tyCon = Absyn.longidToString(stringList)
                       }
                      ); 
                     ERRORty
                     )
                end
            | (_, SOME(TYFUN {tyargs = btvKindIEnvMap, body = ty,...})) => 
                let
                  val intList = IEnv.listKeys btvKindIEnvMap
                  val wants = List.length intList
                  val given = List.length tyList
                in
                  if wants = given
                    then
                      TU.substBTvar
                      (foldr
                        (fn ((tid, ty), tyIEnvMap) => IEnv.insert(tyIEnvMap, tid, ty))
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
                       tyCon = Absyn.longidToString(stringList)
                       }
                      );
                     ERRORty
                     )
                end
            | (_,SOME(TYSPEC {spec = {name, id, strpath, eqKind, tyvars, boxedKind},
                              impl = implOpt})) => 
                let
                  val wants = List.length tyvars
                  val given = List.length tyList
                  val newtyCon = {
                                  name = name,
                                  strpath = strpath,
                                  abstract = false, 
                                  tyvars = tyvars,
                                  id = id,
                                  eqKind = ref eqKind,
                                  boxedKind = ref boxedKind,
                                  datacon = ref SEnv.empty
                                  }
                  val specTy = CONty{tyCon = newtyCon, args = tyList}
                  val implOpt = case implOpt of
                                     NONE => NONE
                                   | SOME impl => SOME (TU.peelTySpec impl)
                in
                  if wants = given
                    then 
                      case implOpt of
                        NONE => SPECty specTy
                      | SOME (TYFUN tyFun) =>
                          let
                            val implTy = TU.betaReduceTy (tyFun,tyList)
                          in
                            ABSSPECty(specTy, implTy)
                          end
                      | SOME (TYCON tyCon) =>
                          let
                            val implTy = CONty{tyCon = tyCon, args = tyList}
                          in
                            ABSSPECty(specTy, implTy)
                          end
                      | SOME (TYSPEC _) => raise Control.Bug "tyspec can not be implementation tybindinfo"
                  else
                    (
                     E.enqueueError
                     (
                      loc, 
                      E.ArityMismatchInTypeDeclaration
                      {
                       wants = wants,
                       given = given,
                       tyCon = Absyn.longidToString(stringList)
                       }
		      ); 
                     ERRORty
                     )
                end
            | (_,NONE) => 
                (
                 E.enqueueError
                 (loc, E.TyConNotFoundInRawTy{tyCon = Absyn.longidToString(stringList)});
                 ERRORty
                 )
          end
      | A.TYTUPLE (rawtyList, loc) =>
          RECORDty
          (#2
           (foldl
            (fn (rawty, (n, tyFields)) => 
             (
              n + 1,
              SEnv.insert
              (tyFields, Int.toString n, evalRawty currentContext rawty))
             )
            (1, SEnv.empty)
            rawtyList))
      | A.TYFUN (rawty1, rawty2, loc) =>
          FUNMty([evalRawty currentContext rawty1], evalRawty currentContext rawty2)

  fun isVar ptexp = 
      case ptexp of
        PT.PTVAR _ => true
      | PT.PTTYPED (ptexp, _, _) => isVar ptexp
      | _ => false

  fun makeLocalVarPathInfo ({name, ty}) =
      {name = name, strpath = NilPath, ty = ty}

  fun stripRawty ptexp = 
      let 
        fun strip ptexp rawTyList = 
          case ptexp of
            PT.PTVAR (path, loc) => (path, loc, rawTyList)
          | PT.PTTYPED (ptexp, rawty, _) => strip ptexp (rawty :: rawTyList)
          | _ => raise Control.Bug "not var in stripRwaTy"
      in
        strip ptexp nil
      end

  fun expansiveCon (conPathInfo : conPathInfo) =
      #id (#tyCon conPathInfo) = StaticEnv.refTyConid

  fun expansive tpexp =
      case tpexp of 
        TPFOREIGNAPPLY _ => true
      | TPERROR => true
      | TPCONSTANT _ => false
      | TPVAR _ => false
      | TPRECFUNVAR _ => false
      | TPPRIMAPPLY _ => true
      | TPOPRIMAPPLY _ => true
      | TPCONSTRUCT {con, instTyList, argExpOpt=NONE, loc} => false
      | TPCONSTRUCT {con, instTyList, argExpOpt= SOME tpexp, loc} => 
          expansiveCon con orelse expansive tpexp
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
      | TPSEQ _ => true
      | TPFFIVAL _ => true
      | TPCAST _ => true

  datatype abscontext = FINITE of int | INFINITE

  val inf = INFINITE
  val zero = FINITE 0
  fun inc INFINITE = INFINITE
    | inc (FINITE n) = FINITE (n + 1)
  fun decl INFINITE = INFINITE
    | decl (FINITE n) = FINITE (if n = 0 then 0 else (n - 1))
  fun iszero (FINITE 0) = true
    | iszero _ = false
    
  fun freeVarsInPat currentContext ptpat =
      case ptpat of
        PT.PTPATWILD _ => SSet.empty
      | PT.PTPATID (nil, _) => raise Control.Bug "nil longid in freeVarsInPat"
      | PT.PTPATID ([string], _) => 
        (case TIC.lookupLongVar (currentContext, [string]) of
              (_, SOME(CONID _)) => SSet.empty
            | _ => SSet.singleton string
         )
      | PT.PTPATID (stringList, loc) => 
        (case TIC.lookupLongVar (currentContext, stringList) of
           (_, SOME(CONID _)) => SSet.empty
         | (_, SOME _) => 
             (E.enqueueError(loc, E.NonConstructorPathInPat stringList); 
              SSet.empty)
         | (_, NONE) => 
             (E.enqueueError(loc, E.ConstructorPathNotFound stringList);
              SSet.empty)
         )
      | PT.PTPATCONSTANT _ => SSet.empty
      | PT.PTPATCONSTRUCT (ptpatCon, ptpat, _) => 
         (case ptpatCon of
             PT.PTPATID ([string], loc) => 
               (case TIC.lookupLongVar (currentContext, [string]) of
                  (_, SOME(CONID _)) => freeVarsInPat currentContext ptpat
                | _ => 
                    (E.enqueueError(loc, E.NonConstruct {pat = ptpatCon}); 
                     SSet.empty
                     )
               )
           | PT.PTPATID (stringList, loc) => 
              (case TIC.lookupLongVar (currentContext, stringList) of
                 (_, SOME(CONID _)) => freeVarsInPat currentContext ptpat
               | (_, SOME _) => 
                   (E.enqueueError(loc, E.NonConstructorPathInPat stringList); 
                    SSet.empty)
               | (_, NONE) => 
                   (E.enqueueError(loc, E.ConstructorPathNotFound stringList);
                    SSet.empty)
                   )
           | _ => raise Control.Bug "Non PTPATID in PTPATCONSTRUCT"
          )
      | PT.PTPATRECORD (_, stringPtpatList, loc) => 
          foldl 
          (fn ((_, ptpat), set2) => 
           let
             val set1 = freeVarsInPat currentContext ptpat
             val duplicates = SSet.intersection (set1,set2)
           in
             if SSet.isEmpty duplicates
               then SSet.union(set1, set2)
             else
               (
                E.enqueueError
                (
                 loc,
                 E.DuplicatePatternVar{vars = SSet.listItems duplicates}
                 );
                SSet.union(set1, set2)
                )
           end)
          SSet.empty
          stringPtpatList
      | PT.PTPATLAYERED (string, _, ptpat, loc) => 
        (case TIC.lookupVar(currentContext, string) of
           SOME(CONID _) =>
           raise Control.Bug "not id in layered pat in typeinf"
         | _ =>
           let val set1 = freeVarsInPat currentContext ptpat
           in
             if SSet.member(set1, string)
             then 
               (
                 E.enqueueError (loc,E.DuplicatePatternVar{vars = [string]});
                 SSet.add(set1, string)
               )
             else SSet.add(set1, string)
           end)
      | PT.PTPATTYPED (ptpat, _, _) => freeVarsInPat currentContext ptpat


  
  (**
   * Preform monomorphic modus ponens.
   *)
  fun monoApplyM currentContext {termLoc, 
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
               | _ => TPTAPP {exp=funTpexp, expTy=funTy, instTyList=instlist, loc=termLoc}
      in 
        (U.unify (ListPair.zip(argTyList, domtyList));
         (
          ranty, 
          TPAPPM {funExp = newFunTpexp, 
                  funTy = FUNMty(domtyList, ranty), 
                  argExpList = argTpexpList, 
                  loc=termLoc}
          )
         )
        handle U.Unify =>
               ( 
                E.enqueueError (termLoc, E.TyConListMismatch {argTyList = argTyList, domTyList = domtyList});
                (ERRORty, TPERROR)
               ) 
      end
         handle TU.CoerceFun =>
                  (
                   E.enqueueError (funLoc, E.NonFunction {ty = funTy});
                   (ERRORty, TPERROR)
                   )

  fun transFunDecl loc (funPat as (PT.PTPATID ([funId], patLoc)), ruleList as (([pat], exp)::_)) =
         (funPat, PT.PTFNM(SEnv.empty, ruleList, loc))
    | transFunDecl loc (funPat as (PT.PTPATID ([funId], patLoc)), [(patList, exp)]) =
         (funPat,
          foldr (fn (pat, funBody) => PT.PTFNM(SEnv.empty, [([pat], funBody)], loc)) exp patList)
    | transFunDecl loc (funPat as (PT.PTPATID ([funId], patLoc)), ruleList as ((patList, exp)::_)) =
        let
          val funBody = 
            let
              fun listToTuple list =
                #2
                (foldl
                 (fn (x, (n, y)) => (n + 1, y @ [(Int.toString n, x)]))
                 (1, nil)
                 list)
              val newNames = map (fn x => Vars.newPTVarName()) patList 
              val newVars = map (fn x => PT.PTVAR([x], loc)) newNames
              val newVarPats = map (fn x => PT.PTPATID([x], loc)) newNames
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
        (funPat, funBody)
      end
    | transFunDecl _ _ = raise Control.Bug "illegal fun decl "

  fun coerceToDummyTy tyvarRef =
      case tyvarRef of
        ref (TVAR {id, recKind = UNIV, eqKind, tyvarName}) => 
        let
          val dummyty = TIU.nextDummyTy ()
          val _ = tyvarRef := (SUBSTITUTED dummyty)
        in
          dummyty
        end
      | (**** temporary fix of BUG 200 ***)
        ref (TVAR {id, recKind = REC tySEnvMap, eqKind, tyvarName}) =>
          RECORDty tySEnvMap                          
      | _ => (printType (TYVARty tyvarRef) ; raise Control.Bug "coerceToDummyTy")


  (**
   *)
  fun typeinfConst (const, loc) =
    let
      fun staticEvalConst const =
        case const of
          PT.INT (int, _) => TPCONSTANT (INT int, loc) 
        | PT.WORD (word, _) => TPCONSTANT (WORD word, loc)
        | PT.REAL (real, _) => TPCONSTANT (REAL real, loc)
        | PT.STRING (string, _) => TPCONSTANT (STRING string, loc)
        | PT.CHAR (char, _) => TPCONSTANT (CHAR char, loc)
      val (ty, _) = TIU.freshTopLevelInstTy (ITC.constTy const)
    in
      (ty, staticEvalConst const)
    end

  fun mergeBoundEnvs (boundEnv1, boundEnv2) =
    let
      val shiftIndex = IEnv.numItems boundEnv2
    in
      IEnv.unionWith (fn _ => raise Control.Bug "duplicate boundtvars in mergeBoundEnvs")
      (
       boundEnv2,
       IEnv.map 
         (fn {index,recKind,eqKind} => {index=index+shiftIndex, recKind=recKind, eqKind=eqKind})
         boundEnv1
       )
    end
  (*
    contextForValbind : outer context
    currentContext : context for ptexp
    ifGenTerm : ifGenTerm is true then it also return the reconstructed term 
                which is used to bind the variable in a layered pattern.
    ptpat : pattern
    ptexp : expression

    Translate a valbind of the form
      val ptpat = ptexp 
   to a sequence of simpler bindings.
   *
   * exception: 
      E.RecordLabelSetMismatch
   *)
  fun decomposeValbind
      (contextForValbind, currentContext, ifGenTerm)
      (ptpat, ptexp) =
    let
      fun generalizeIfNotExpansive ((ty, tpexp), loc) = 
        if E.isError() then
          (ty, tpexp)
        else
         if expansive tpexp then 
           (ty, tpexp)
          else
            let
              val {boundEnv,...} = generalizer (ty, contextForValbind)
            in 
              if IEnv.isEmpty boundEnv
                then (ty, tpexp)
              else
                (case tpexp of
                   TPFNM {argVarList=argVarPathInfoList, bodyTy=ranTy, bodyExp=typedExp, loc=loc} =>
                     (
                      POLYty{boundtvars = boundEnv, body = FUNMty(map #ty argVarPathInfoList, ranTy)},
                      TPPOLYFNM {btvEnv=boundEnv, 
                                 argVarList=argVarPathInfoList, 
                                 bodyTy=ranTy, 
                                 bodyExp=typedExp, 
                                 loc=loc}
                      )
                 | TPPOLY{btvEnv=boundEnv1, expTyWithoutTAbs=ty1, exp=tpexp1, loc=loc1} =>
                     (
                      case ty of 
                        POLYty{boundtvars=boundEnv2, body= ty2} =>
                          (POLYty{boundtvars = mergeBoundEnvs (boundEnv, boundEnv2),
                                  body = ty2},
                           TPPOLY{btvEnv=mergeBoundEnvs (boundEnv, boundEnv1),
                                  expTyWithoutTAbs=ty1,
                                  exp=tpexp1,
                                  loc=loc1}
                           )
                      | _ => raise Control.Bug "non polyty for TPPOLY"
                    )
                 | TPPOLYFNM {btvEnv=boundEnv1, 
                              argVarList=argVarPathInfo, 
                              bodyTy=ranTy, 
                              bodyExp=tpexp1, 
                              loc=loc1} =>
                     (
                      case ty of 
                        POLYty{boundtvars=boundEnv2, body= ty2} =>
                          (POLYty{boundtvars = mergeBoundEnvs (boundEnv, boundEnv2),
                                  body = ty2},
                           TPPOLYFNM {btvEnv=mergeBoundEnvs (boundEnv, boundEnv1),
                                      argVarList=argVarPathInfo,   
                                      bodyTy=ranTy,
                                      bodyExp=tpexp1,
                                      loc=loc1}
                           )
                      | _ => raise Control.Bug "non polyty for TPPOLY"
                    )
                 | _ => (
                         POLYty{boundtvars = boundEnv, body = ty},
                         TPPOLY{btvEnv=boundEnv, expTyWithoutTAbs=ty, exp=tpexp, loc=loc}
                         )
                )
            end

      fun isStrictValuePat currentContext ptpat =
          case ptpat of
            PT.PTPATWILD _ => true
          | PT.PTPATID (path, _) => 
            (case TIC.lookupLongVar (currentContext, path) of 
               (path, SOME(CONID _)) => false 
             |  _ => true)
          | PT.PTPATCONSTANT _ => false
          | PT.PTPATCONSTRUCT _ => false
          | PT.PTPATRECORD (_, stringPtpatList, _) => 
            foldr
                (fn ((_, ptpat1), bool) =>
                    bool andalso isStrictValuePat currentContext ptpat1)
                true
                stringPtpatList
          | PT.PTPATLAYERED (string, _, ptpat1, _) =>
            isStrictValuePat currentContext  ptpat1
          | PT.PTPATTYPED (ptpat1, _,  _) =>
            isStrictValuePat currentContext ptpat1
       (*
         This returns
           (localBinds, varBinds, extraBinds, tpexp, ty)
       *)
      fun decompose
          (currentContext:TIC.currentContext, ifGenTerm)
          (ptpat, ptexp) = 
        let
          val ptpatLoc = PT.getLocPat ptpat
          val ptexpLoc = PT.getLocExp ptexp

          fun makeCase (ptpat, ptexp) = 
            let
              val idSet = freeVarsInPat currentContext ptpat
              val ptpatLoc = PT.getLocPat ptpat
              val ptexpLoc = PT.getLocExp ptexp
              val loc = Loc.mergeLocs (ptpatLoc, ptexpLoc)
            in
              if SSet.isEmpty idSet
                then
                  let
                    val newPtexp =
                      PT.PTCASEM
                      (
                       [ptexp], 
                       [([ptpat], PT.PTTUPLE(nil, ptpatLoc))],
                       BIND,
                       loc
                       )
                    val (ty, tpexp) = typeinfExp inf currentContext newPtexp
                    val varID = {name = Vars.newTPVarName(), ty = ty}
                    val varPathInfo = makeLocalVarPathInfo varID
                    val patid =
                      if ifGenTerm
                        then (VALIDVAR varID)
                      else VALIDWILD ty
                  in
                    (nil, [(patid, tpexp)], nil, TPVAR (varPathInfo, loc), ty)
                  end
              else
                if SSet.numItems idSet = 1
                  then
                    let
                      val [x] = SSet.listItems idSet
                      val newPtexp =
                        PT.PTCASEM
                        (
                         [ptexp], 
                         [([ptpat], PT.PTVAR([x], ptpatLoc))],
                         BIND,
                         loc
                         )
                      val (ty, tpexp) = typeinfExp inf currentContext newPtexp
                      val varID = {name = x, ty = ty}
                      val varPathInfo = makeLocalVarPathInfo varID
                    in
                      (
                        nil,
                        [(VALIDVAR varID, tpexp)],
                        nil,
                        TPVAR (varPathInfo, loc),
                        ty
                      )
                    end
                else
                  let
                    val resTuple =  
                      SSet.foldr
                      (fn (x, resTuple) =>
                       PT.PTVAR([x], ptpatLoc) :: resTuple)
                      nil
                      idSet
                    val newPtexp =
                      PT.PTCASEM
                      (
                       [ptexp], 
                       [([ptpat], PT.PTTUPLE (resTuple, ptpatLoc))],
                       BIND,
                       loc
                       )
                    val (tupleTy, tpexp) =
                        typeinfExp inf currentContext newPtexp
                    val newVarId = Vars.newTPVarName ()
                    val varID = {name = newVarId, ty = tupleTy}
                    val varPathInfo = makeLocalVarPathInfo varID
                    val tyList = 
                      case tupleTy of 
                        RECORDty tyFields => SEnv.listItems tyFields
                      | ERRORty => map (fn x => ERRORty) resTuple
                      | _ => raise Control.Bug "decompose"
                    val (_, resBinds) = 
                      foldl
                      (fn ((varId, ty), (i, varIDTpexpList)) => 
                       (
                        i + 1,
                        (
                         VALIDVAR {name = varId, ty = ty}, 
                         TPSELECT
                         {
                          label=Int.toString i,
                          exp=TPVAR (varPathInfo, loc),
                          expTy=tupleTy,
                          loc=loc
                          }
                         ) :: varIDTpexpList
                        ))
                      (1, nil)
                      (ListPair.zip (SSet.listItems idSet, tyList))
                  in
                    (
                     [(VALIDVAR varID, tpexp)],
                     List.rev resBinds,
                     nil,
                     TPVAR (varPathInfo, loc),
                     tupleTy
                     )
                  end
            end
        in (* decompose body *)
          if not (isStrictValuePat currentContext ptpat)
            then makeCase (ptpat, ptexp)
          else
            case ptpat of 
              PT.PTPATWILD loc =>
                let
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    (typeinfExp inf currentContext ptexp, ptexpLoc)
                  val varID = {name = Vars.newTPVarName(), ty = ty}
                  val varPathInfo = makeLocalVarPathInfo varID
                  val patid =
                    if ifGenTerm then VALIDVAR varID else VALIDWILD ty
                in
                  (nil, [(patid, tpexp)], nil, TPVAR (varPathInfo, loc), ty)
                end
            | PT.PTPATID (varId, loc) =>
                let
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    (typeinfExp zero currentContext ptexp, ptexpLoc)
                  val varID  = {name = Absyn.longidToString(varId), ty = ty}
                  val varPathInfo = makeLocalVarPathInfo varID
                in
                  (
                   nil,
                   [(VALIDVAR varID, tpexp)],
                   nil,
                   TPVAR (varPathInfo, loc),
                   ty
                   )
                end
            | PT.PTPATRECORD (flex, stringPtpatList, loc1) =>
                (case ptexp of
                   PT.PTTUPLE (ptexpList, loc) =>
                     if not flex andalso (List.length ptexpList <> List.length stringPtpatList)
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
                              val (localBinds1, patternVarBinds1, extraBinds1, tpexp, ty) =
                                decompose
                                (currentContext, ifGenTerm)
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
                           RECORDty
                           (foldr
                            (fn ((l, ty), fields) => SEnv.insert(fields, l, ty))
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
                           val (localBinds1, patternVarBinds1, extraBinds1, tpexp, ty) =
                             decompose
                             (currentContext, ifGenTerm)
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
                        RECORDty
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
                        typeinfExp inf currentContext ptexp
                      val (_, tyPat, _ ) = typeinfPat currentContext ptpat
                      val _ =
                        (U.unify [(tyBody, tyPat)])
                        handle U.Unify =>
                          raise
                            E.PatternExpMismatch
                            {patTy = tyPat, expTy= tyBody}
                      val strPath = #strLevel currentContext
                      val bodyVar = Vars.newPTVarName ()
                      val ptBodyVar =
                        PT.PTVAR ([bodyVar], loc1)
                      val tpVarID = {name = bodyVar, ty = tyBody}
                      val tpVarPathInfo =
                        {name = bodyVar, strpath = strPath, ty = tyBody}
                      val tpBodyVar = VALIDVAR tpVarID
                      val currentContext = TIC.bindVarInCurrentContext (currentContext, 
                                                                        bodyVar, 
                                                                        VARID tpVarPathInfo)
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
                           val (localBinds1, variableBinds1, extraBinds1, tpexp, ty) =
                             decompose
                             (currentContext, ifGenTerm)
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
                       TPVAR (makeLocalVarPathInfo tpVarID, loc1),
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
                    (currentContext, true)
                    (ptpat, ptexp)
                in
                  (
                   localBinds,
                   variableBinds,
                   extraBinds@[(VALIDVAR {name = id, ty = ty}, tpexp)],
                   tpexp,
                   ty
                   )
                end
            | PT.PTPATTYPED (ptpat, rawTy, loc)  => 
                let 
                  val ptexp = PT.PTTYPED (ptexp, rawTy, ptexpLoc)
                in
                  decompose
                  (currentContext, ifGenTerm)
                  (ptpat, ptexp)
                end
            | _ => raise Control.Bug "non strictvalue pat in decompoes"
        end (* end of decpomose *)

    in
      (
       (* 
          The following is to check the well formedness of the pattern.
          Not very elegant.
        *)
       freeVarsInPat currentContext ptpat;
       if E.isError() then (nil, nil, nil)
       else
         let
           val (localBinds, variableBinds, extraBinds, _, _) =
             decompose (currentContext, ifGenTerm) (ptpat, ptexp)
         in
           (localBinds, variableBinds, extraBinds)
         end
       )
    end

  and tyinfApplyId
          applyDepth
          (currentContext:TIC.currentContext)
          (loc, longvid, idloc, rawTyList, ptexpList) =
    let 
      val ((varStrPath,vid), varState) = TIC.lookupLongVar (currentContext, longvid)
      val idState =
          case varState of
            SOME v => v
          | NONE =>
            (
              E.enqueueError (idloc, 
			      E.VarNotFound {id = Absyn.longidToString(longvid)});
              VARID
                  {
                   name = vid,
                   strpath = varStrPath,
                   ty = ERRORty
                  }
            )

      val (tyList, tpexpList) = 
               foldr (fn (ptexp, (tyList, tpexpList)) =>
                      let 
                        val (ty, tpexp) = typeinfExp inf currentContext ptexp
                        val (ty, tpexp) = TPU.freshInst(ty, tpexp)
                      in (ty::tyList, tpexp::tpexpList)
                      end
                      )
               (nil,nil)
               ptexpList
    in
      case (idState, tyList, tpexpList) of 
        (CONID (conPathInfo as {name, strpath, ty = ty, tyCon, funtyCon, tag}), [ty2], [tpexp2]) =>
        let
	  val termconPathInfo =
              {
                name =  Absyn.getLastIdOfLongid(longvid),
                strpath =  varStrPath,
                ty = ty,
                tyCon = tyCon,
		tag = tag,
                funtyCon = funtyCon
              }
          val (instTy, instTyList) = TIU.freshTopLevelInstTy ty
          val _ = 
              foldl
                  (fn (rawty, _) =>
                      let val annotatedTy1 = evalRawty currentContext rawty
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
               ([ERRORty], ERRORty, nil)
               )
          val domty = case domtyList of [ty] => ty | _ => raise Control.Bug "arity mismatch"
          val newTermBody = 
              TPCONSTRUCT
                  { 
		   con=termconPathInfo,
                   instTyList=instTyList,
                   argExpOpt=SOME tpexp2,
                   loc=loc
                  }
        in
          (
            U.unify [(ty2, domty)];
            if iszero applyDepth andalso not (expansiveCon conPathInfo)
            then
              let 
                val {boundEnv, ...} = generalizer (ranty, currentContext)
              in
                 if IEnv.isEmpty boundEnv
                  then (ranty, newTermBody)
                else
                   (
                     POLYty{boundtvars = boundEnv, body = ranty},
                     TPPOLY{btvEnv=boundEnv, expTyWithoutTAbs=ranty, exp=newTermBody, loc=loc}
                   )
              end
            else (ranty, newTermBody))
          handle U.Unify =>
                 (
                   E.enqueueError
                       (loc, E.TyConMismatch {domTy = domty, argTy = ty2});
                   (ERRORty, TPERROR)
                 )
        end
      | (CONID (conPathInfo as {name, strpath, ty = ty, tyCon, funtyCon, tag}), _, _) =>
          raise Control.Bug "CONID in multiple apply"
      | (FFID (foreignFunPathInfo as {name, strpath, ty, argTys}),[ty2], [tpexp2]) =>
        let 
          val (instTy, instTyList) =
              case TIU.freshTopLevelInstTy ty of
                (instTy, []) => (instTy, [])
              | (_, _ :: _) => raise Control.Bug "polytype foreign function"
          val _ = 
              foldl
                  (fn (rawty, _) =>
                      let val annotatedTy1 = evalRawty currentContext rawty
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
                       ([ERRORty], ERRORty, nil)
                     )
          val domty = case domtyList of [ty] => ty | _ => raise Control.Bug "arity mismatch"
	  val tpexp1 = TPVAR ({name=name, strpath = varStrPath, ty=ty}, loc)
          val newTermBody =
              TPFOREIGNAPPLY{funExp=tpexp1, instTyList=instTyList, argExp=tpexp2, argTyList=argTys, loc=loc}
        in
          (
            U.unify [(ty2, domty)];
            (ranty, newTermBody)
          )
          handle U.Unify =>
                 (
                   E.enqueueError
                       (loc, E.TyConMismatch {domTy = domty, argTy = ty2});
                   (ERRORty, TPERROR)
                 )
        end
      | (FFID (foreignFunPathInfo as {name, strpath, ty, argTys}), _, _) =>
          raise Control.Bug "FFID in multiple apply"
      | (PRIM (primInfo as {ty = ty,...}), [ty2], [tpexp2]) =>
        let 
          val (instTy, instTyList) = TIU.freshTopLevelInstTy ty
          val _ = 
              foldl
                  (fn (rawty, _) =>
                      let val annotatedTy1 = evalRawty currentContext rawty
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
               ([ERRORty], ERRORty, nil)
               )
          val domty = case domtyList of [ty] => ty | _ => raise Control.Bug "arity mismatch"
          val newTermBody = 
              TPPRIMAPPLY{primOp=primInfo, instTyList=instTyList, argExpOpt=SOME tpexp2, loc=loc}
        in
          (
            U.unify [(ty2, domty)];
            (ranty, newTermBody)
          )
          handle U.Unify =>
                 (
                   E.enqueueError
                       (loc, E.TyConMismatch {domTy = domty, argTy = ty2});
                   (ERRORty, TPERROR)
                 )
        end
      | (PRIM (primInfo as {ty = ty,...}), _, _) =>
          raise Control.Bug "PrimOp in multiple apply"
      | (OPRIM {name, ty = ty, instances}, [ty2], [tpexp2]) =>
        let 
          val (instTy, instTyList) = TIU.freshTopLevelInstTy ty
          val _ = 
              foldl
                  (fn (rawty, _) =>
                      let val annotatedTy1 = evalRawty currentContext rawty
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
               ([ERRORty], ERRORty, nil)
               )
          val domty = case domtyList of [ty] => ty | _ => raise Control.Bug "arity mismatch"
          val newTermBody =
              TPOPRIMAPPLY
                  {
                    oprimOp={name = name, ty = ty, instances = instances},
                    instances=instTyList, 
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
                   (ERRORty, TPERROR)
                 )
        end
      | (OPRIM {name, ty = ty, instances}, _, _) =>
          raise Control.Bug "PrimOp in multiple apply"
      | (VARID {name, strpath, ty}, _, _) => 
        (
	 let
	   val term = TPVAR ({name=name, strpath = varStrPath, ty=ty}, loc)
	 in
	   case rawTyList of
             nil =>
               monoApplyM
               currentContext
               {termLoc=loc, funTy=ty, argTyList=tyList, funTpexp=term, funLoc=idloc, argTpexpList=tpexpList}
           | _ =>
             let 
               val (instTy, tpexp1) = TPU.freshInst (ty,term)
               val _ = 
                   foldl
                     (fn (rawty, _) =>
                         let val annotatedTy1 = evalRawty currentContext rawty
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
               val (domtyList, ranty, instlist) = TU.coerceFunM (instTy, tyList)
                 handle TU.CoerceFun =>
                   (
                    E.enqueueError (idloc, E.NonFunction {ty = instTy});
                    (map (fn x => ERRORty) tyList, ERRORty, nil)
                    )
               val tpexp1 =
                   case instlist of
                     nil => tpexp1
                   | _ => TPTAPP {exp=tpexp1, expTy=instTy, instTyList=instlist, loc=loc}
             in 
               (
		U.unify (ListPair.zip(tyList, domtyList));
		(ranty, TPAPPM({funExp = tpexp1, 
                                funTy = FUNMty(domtyList, ranty), 
                                argExpList = tpexpList, 
                                loc = loc}))
		)
               handle U.Unify =>
                      (
                       E.enqueueError
                         (loc, E.TyConListMismatch {domTyList = domtyList, argTyList = tyList});
			 (ERRORty, TPERROR)
			 )
             end
	 end
       )
      | (RECFUNID ({name, strpath, ty}, arity), _, _) => 
        (
	 let
	   val term = TPRECFUNVAR ({var = {name=name, strpath = varStrPath, ty=ty}, arity = arity, loc=loc})
	 in
	   case rawTyList of
             nil =>
               monoApplyM
               currentContext
               {termLoc=loc, funTy=ty, argTyList=tyList, funTpexp=term, funLoc=idloc, argTpexpList=tpexpList}
           | _ =>
             let 
               val (instTy, tpexp1) = TPU.freshInst (ty,term)
               val _ = 
                   foldl
                     (fn (rawty, _) =>
                         let val annotatedTy1 = evalRawty currentContext rawty
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
               val (domtyList, ranty, instlist) = TU.coerceFunM (instTy, tyList)
                 handle TU.CoerceFun =>
                   (
                    E.enqueueError (idloc, E.NonFunction {ty = instTy});
                    (map (fn x => ERRORty) tyList, ERRORty, nil)
                    )
               val tpexp1 =
                   case instlist of
                     nil => tpexp1
                   | _ => TPTAPP {exp=tpexp1, expTy=instTy, instTyList=instlist, loc=loc}
             in 
               (
		U.unify (ListPair.zip(tyList, domtyList));
		(ranty, TPAPPM({funExp = tpexp1, 
                                funTy = FUNMty(domtyList, ranty), 
                                argExpList = tpexpList, 
                                loc = loc}))
		)
               handle U.Unify =>
                      (
                       E.enqueueError
                         (loc, E.TyConListMismatch {domTyList = domtyList, argTyList = tyList});
			 (ERRORty, TPERROR)
			 )
             end
	 end
       )
    end

  (**
   * infer a type for an expression
   *
   * @params applyDepth compileContext exp
   * @param applyDepth the depth of application in which exp occurres
   * @param compileContext static context
   * @param exp expression
   * @return (ty, tpterm)
   *
   *)
  and typeinfExp applyDepth (currentContext : TIC.currentContext) ptexp =
      (case ptexp of
         PT.PTCONSTANT (const, loc) => typeinfConst (const, loc)
       | PT.PTVAR (longvid, loc) => 
         (case TIC.lookupLongVar(currentContext,longvid) of 
            ((varStrPath,vid), NONE) => 
            (
              E.enqueueError (loc, E.VarNotFound {id = Absyn.longidToString(longvid)});
              (
                ERRORty,
                TPVAR
                    (
                      {
                        name = Absyn.getLastIdOfLongid longvid,
		        strpath = varStrPath,
		        ty = ERRORty
                      },
                      loc
                    )
              )
            )
          | ((varStrPath,vid), SOME (VARID ({name,strpath,ty}))) => 
	    (ty,
	     TPVAR ({name = name, strpath = varStrPath,ty = ty}, loc)
	     )
          | ((varStrPath,vid), SOME (RECFUNID ({name,strpath,ty},arity))) => 
	    (ty,
	     TPRECFUNVAR {var={name = name, strpath = varStrPath,ty = ty}, arity=arity, loc=loc}
	     )
          |  ((varStrPath,vid), SOME idState) =>
            (* When this case matches, varId is not in the head position.
             * So we perform eta expansion for the constructor name.
             *)
	       TIU.etaExpandCon (varStrPath,vid) loc idState
	       )
       | PT.PTTYPED (ptexp, rawty, loc) =>
         let
           val (ty1, tpexp) = typeinfExp inf currentContext ptexp
           val (instTy, tpexp) = TPU.freshInst (ty1, tpexp)
           val ty2 = evalRawty currentContext rawty
         in
           (
             U.unify [(instTy, ty2)];
             (ty2, tpexp)
           )
           handle U.Unify =>
                 (
                   E.enqueueError
                       (
                         loc,
                         E.TypeAnnotationNotAgree {ty = instTy, annotatedTy = ty2}
                       );
                   (ERRORty, TPERROR)
                 )
         end
       | PT.PTAPPM(PT.PTRECORD_SELECTOR(label, loc1), [ptexp], loc2) =>
         typeinfExp applyDepth currentContext (PT.PTSELECT(label, ptexp, loc2))
       | PT.PTAPPM (ptexp, ptexpList, loc) =>
         if isVar ptexp
         then
           let 
             val (path, pathLoc, rawTyList) = stripRawty ptexp
           in
             tyinfApplyId
                 applyDepth
                 currentContext
                 (loc, path, pathLoc, rawTyList, ptexpList)
           end
         else
           let 
             val (ty1, tpexp) = typeinfExp (inc applyDepth) currentContext ptexp
             val (tyList, tpexpList) = 
               foldr (fn (ptexp, (tyList, tpexpList)) =>
                      let val (ty, tpexp) = typeinfExp inf currentContext ptexp
                          val (ty, tpexp) = TPU.freshInst(ty, tpexp)
                      in (ty::tyList, tpexp::tpexpList)
                      end
                      )
               (nil,nil)
               ptexpList
           in
             monoApplyM
             currentContext
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
               typeinfPtdeclList false currentContext ptdeclList 
           val newCurrentContext =
               TIC.extendCurrentContextWithContext (currentContext, context1)
           val (tyList, tpexpList) = 
               foldr
                   (fn (ptexp, (tyList, tpexpList)) =>
                       let 
                         val (ty, tpexp) = 
                             typeinfExp applyDepth newCurrentContext ptexp
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
                       typeinfExp applyDepth currentContext ptexp
                 in 
                   if expansive tpexp then
                     let
                       val tpvarPathInfo = 
                         {name = Vars.newTPVarName (), strpath = NilPath, ty = ty}
                     in
                       (
                        SEnv.insert (tpexpSmap, label, TPVAR (tpvarPathInfo, loc)),
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
           val resultTy = RECORDty tySmap
         in
           (
             resultTy,
             case tpbinds of
               nil => TPRECORD {fields=tpexpSmap, recordTy=resultTy, loc=loc}
             | _ => TPMONOLET{binds=tpbinds, 
                              bodyExp=TPRECORD {fields=tpexpSmap, recordTy=resultTy, loc=loc}, 
                              loc=loc}
           )
         end
       | PT.PTRECORD_UPDATE (ptexp, stringPtexpList, loc) =>
         let
           val (ty1, tpexp1) =
               TPU.freshInst (typeinfExp applyDepth currentContext ptexp)
           val (modifyTpexp, tySmap) =
               foldl
	       (fn ((label, ptexp), (modifyTpexp, tySmap)) =>
                    let
                      val (ty, tpexp) =
                          TPU.freshInst
                              (typeinfExp applyDepth currentContext ptexp)
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
               newty { recKind = REC tySmap, eqKind = NONEQ, tyvarName = NONE }
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
		     (ERRORty, TPERROR)
		   )
         end
       | PT.PTTUPLE (ptexpList, loc) =>
         let 
           val (_, tpexpSmap, tySmap) =
               foldl
               (fn (ptexp, (n, tpexpSmap, tySmap)) =>
                   let 
                     val (ty, tpexp) =
                         typeinfExp applyDepth currentContext ptexp
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
           val resultTy = RECORDty tySmap
         in
           (resultTy, TPRECORD {fields=tpexpSmap, recordTy=resultTy, loc=loc})
         end
       | PT.PTRAISE (ptexp, loc) =>
         let 
           val (ty1, tpexp) = typeinfExp applyDepth currentContext ptexp
           val resultTy = newty univKind
         in 
           (
             U.unify [(ty1, SE.exnty)];
             (resultTy, TPRAISE (tpexp, resultTy, loc))
           )
           handle U.Unify =>
                  (
                    E.enqueueError (loc, E.RaiseArgNonExn {ty = ty1});
                    (ERRORty, TPERROR)
                  )
         end
       | PT.PTHANDLE (ptexp, ptpatPtexpList, loc) =>
         let 
           val (ty1, tpexp) =
               TPU.freshInst (typeinfExp inf currentContext ptexp)
           val (ruleTy, tppatTpexpList) =
               monoTypeinfMatch [SE.exnty] currentContext (map (fn (pat,exp) => ([pat], exp)) ptpatPtexpList)
           val (domTy, ranTy) = 
               (* here we try maching the type of rules with exn -> ty1 
                * Also, the result type must be mono.
                *)
               case TU.derefTy ruleTy of
                 FUNMty([domTy], ranTy)=>(domTy, ranTy)
               | ERRORty => (ERRORty, ERRORty)
               | _ => raise Control.Bug "Case Type Inference"
           val newVarPathInfo = 
	       {name = Vars.newTPVarName (), strpath = NilPath, ty = domTy}
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
                           caseKind=HANDLE,
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
                    (ERRORty, TPERROR)
                  )
         end
       | PT.PTFNM (tvarNameSet, matchM, loc) =>
         (case matchM of
            [(patList, exp)] =>
              let
                exception NonVar
              in
(*
(* This naive optimization does not work since D in fn D => exp may be CON.
*)
                let
                  fun getId (PT.PTPATID ([x],loc)) = (x, NONE)
                    | getId (PT.PTPATWILD loc) = (Vars.newPTVarName(), NONE)
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
                  typeinfExp applyDepth currentContext newPtexp
                end
              handle NonVar =>
*)
                let
                  val nameList = map  (fn x => (Vars.newPTVarName(), NONE)) patList
                  val newPtexp =
                    PT.PTFNM1(
                              tvarNameSet,
                              nameList,
                              PT.PTCASEM
                              (
                               map (fn (x, _) => PT.PTVAR([x], loc)) nameList,
                               matchM,
                               MATCH,
                               loc
                               ),
                              loc)
                in 
                  typeinfExp applyDepth currentContext newPtexp
                end
              end
          | ((patList, exp) :: rest) => 
                let
                  val nameList = map  (fn x => (Vars.newPTVarName(), NONE)) patList
                  val newPtexp =
                    PT.PTFNM1(
                              tvarNameSet,
                              nameList,
                              PT.PTCASEM
                              (
                               map (fn (x,_) => PT.PTVAR([x], loc)) nameList,
                               matchM,
                               MATCH,
                               loc
                               ),
                              loc)
                in 
                  typeinfExp applyDepth currentContext newPtexp
                end
              )
       | PT.PTFNM1(tvarNameSet, stringTyListOptionList, ptexp, loc) =>
         let 
           val (newCurrentContext, _) =
               TIC.addUtvarIfNotthere(currentContext, tvarNameSet)
           val nameDomTyVarPathInfoList = 
             map (fn (name, tyListOption) => 
                  let 
                    val domTy = newty univKind
                    val rawTyList = case tyListOption of NONE => nil | SOME tyList => tyList
                    val _ = 
                        foldl
                        (fn (rawty, _) =>
                         let val annotatedTy1 = evalRawty newCurrentContext rawty
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
                    (name, domTy, {name = name, strpath = NilPath, ty = domTy})
                  end
                  )
             stringTyListOptionList
           val newCurrentContext =
               foldl 
               (fn ((name, domTy, varPathInfo),
                    newCurrentContext)
                =>
                TIC.bindVarInCurrentContext
                (newCurrentContext, name, VARID varPathInfo)
                )
               newCurrentContext
               nameDomTyVarPathInfoList
           val (ranTy, typedExp) =
               typeinfExp (decl applyDepth) newCurrentContext ptexp
           val ty = FUNMty(map #2 nameDomTyVarPathInfoList, ranTy)
         in
           if iszero applyDepth
           then
             let
               val {boundEnv, ...} = generalizer (ty, currentContext)
             in
               if IEnv.isEmpty boundEnv
               then (ty, TPFNM {argVarList = map #3 nameDomTyVarPathInfoList, bodyTy = ranTy, 
                                bodyExp = typedExp, 
                                loc = loc})
               else
                 (
                   POLYty{boundtvars = boundEnv, body = ty},
                   TPPOLYFNM {btvEnv=boundEnv, 
                              argVarList=map #3 nameDomTyVarPathInfoList, 
                              bodyTy=ranTy, 
                              bodyExp=typedExp, 
                              loc=loc}
                 )
             end
           else 
             (ty, TPFNM {argVarList = map #3 nameDomTyVarPathInfoList, 
                         bodyTy = ranTy, 
                         bodyExp = typedExp, 
                         loc = loc}) 
         end 
       | PT.PTCASEM (ptexpList, matchM, Kind, loc) =>
         let 
           val (tyList, tpexpList) =
               foldr 
               (fn (ptexp, (tyList, tpexpList)) =>
                let
                  val (ty, tpexp) = TPU.freshInst (typeinfExp inf currentContext ptexp)
                in
                  (ty::tyList, tpexp::tpexpList)
                end
                )
               (nil,nil)
               ptexpList
           val (ruleTy, tpMatchM) =
               typeinfMatch applyDepth tyList currentContext matchM
           val ranTy = 
               case TU.derefTy ruleTy of 
                 FUNMty(_, ranTy) => ranTy
               | ERRORty => ERRORty
               | _ => raise Control.Bug "Case Type Inference"
         in
           (ranTy, TPCASEM{expList=tpexpList, 
                           expTyList=tyList, 
                           ruleList=tpMatchM, 
                           ruleBodyTy=ranTy, 
                           caseKind=Kind, 
                           loc=loc})
         end
       | PT.PTRECORD_SELECTOR(label, loc) => 
         let
           val newName = Vars.newTPVarName()
         in
           typeinfExp
               applyDepth
               currentContext
               (PT.PTFNM1
                    (
                      SEnv.empty, 
                      [(newName, NONE)],
                      PT.PTSELECT
                      (
                        label,
                        PT.PTVAR([newName], loc),
                        loc
                      ), 
                      loc
                    ))
         end
       | PT.PTSELECT(label, ptexp, loc) =>
         let 
           val (ty1, tpexp) = typeinfExp applyDepth currentContext ptexp
           val ty1 = TU.derefTy ty1
         in
           case ty1 of
             RECORDty tyFields =>
             (* here we do not U.unify, since U.unify is restricted to monotype
              *)
             (case SEnv.find(tyFields, label) of
                SOME elemTy => (elemTy, TPSELECT{label=label, exp=tpexp, expTy=ty1, loc=loc})
              | _ => 
                (
                  E.enqueueError (loc, E.FieldNotInRecord {label = label});
                  (ERRORty, TPERROR)
                ))
           | _ =>
             let
               val elemTy = newty univKind
               val recordTy =
                   newty
                       {
                         recKind = REC (SEnv.singleton(label, elemTy)),
                         eqKind = NONEQ,
                         tyvarName = NONE
                       }
             in
               (
                 U.unify [(ty1, recordTy)];
                 (elemTy, TPSELECT{label=label, exp=tpexp, expTy=recordTy, loc=loc})
               )
               handle U.Unify =>
                      (
                        E.enqueueError
                        (loc, E.TyConMismatch {domTy = recordTy, argTy = ty1});
                        (ERRORty, TPERROR)
                      )
             end
         end
       | PT.PTSEQ (ptexpList, loc) =>
         let
           val (tyList, tpexpList) =
               foldr 
                   (fn (ptexp, (tyList, tpexpList)) =>
                       let
                         val (ty, tpexp) =
                             typeinfExp applyDepth currentContext ptexp
                       in 
                         (ty :: tyList, tpexp :: tpexpList)
                       end)
                   (nil, nil)
                   ptexpList
         in
           (List.last tyList, TPSEQ {expList=tpexpList, expTyList=tyList, loc=loc})
         end
       | PT.PTCAST(ptexp, loc) =>
         let
           val (ty1, tpexp) = typeinfExp inf currentContext ptexp
           val ty = newty univKind
         in
           (ty, TPCAST(tpexp, ty, loc))
         end)

  (**
   * infer a possibly polytype for a match
   *)
  and typeinfMatch applyDepth argtyList currentContext [rule] = 
      let 
        val (ty1, typedRule) = typeinfRule applyDepth argtyList currentContext rule
      in (ty1, [typedRule]) end
    | typeinfMatch _ argtyList currentContext (rule :: rules) =
      let 
        val (tyRule, typedRule) = monoTypeinfRule argtyList currentContext rule
        val (tyRules, typedRules) = monoTypeinfMatch argtyList currentContext rules
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
                 (ERRORty, nil)
               )
      end
    | typeinfMatch _ argtyList currentContext nil = 
      raise Control.Bug "typeinfMatch, empty rule"

  (**
   * infer a mono type for a match
   * @params argTy currentContext match
   *)
  and monoTypeinfMatch argtyList currentContext [rule] =
      let val (ty1, typedRule) = monoTypeinfRule argtyList currentContext rule
      in (ty1, [typedRule]) end
    | monoTypeinfMatch argtyList currentContext (rule :: rules) =
      let
        val (ruleTy, typedRule) = monoTypeinfRule argtyList currentContext rule
        val (rulesTy, typedRules) = monoTypeinfMatch argtyList currentContext rules
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
                 (ERRORty, nil)
               )
      end
    | monoTypeinfMatch argty currentContext nil =
      raise Control.Bug "monoTypeinfMatch, empty rule"

  (**
   * infer a possibly polytype for a rule
   * @params applyDepth argTy currentContext rule
   *)
  and typeinfRule applyDepth argtyList currentContext (patList,exp) = 
      let 
        val (varEnv1, patTyList, typedPatList) = typeinfPatList currentContext patList
        val (bodyTy, typedExp) = 
            typeinfExp
            applyDepth
            (TIC.extendCurrentContextWithVarEnv(currentContext, varEnv1))
            exp
      in
        (
          U.unify (ListPair.zip(patTyList, argtyList));
          (FUNMty(patTyList, bodyTy), (typedPatList, typedExp))
        )
        handle U.Unify =>
               let val ruleLoc = getRuleLocM [(patList, exp)]
               in
                 E.enqueueError
                     (ruleLoc, E.TyConListMismatch {argTyList = argtyList, domTyList = patTyList});
                 (ERRORty, (map (fn x => TPPATWILD(ERRORty, ruleLoc)) patList, TPERROR))
               end
      end

  (**
   * infer a monotype for a rule
   * @params argTy currentContext rule
   *)
  and monoTypeinfRule argtyList currentContext (patList,exp) = 
      let 
        val (varEnv1, patTyList, typedPatList) = typeinfPatList currentContext patList
        val (bodyTy, typedExp) = 
            TPU.freshInst
                (typeinfExp inf (TIC.extendCurrentContextWithVarEnv(currentContext, varEnv1)) exp)
      in
        (
          U.unify (ListPair.zip(patTyList, argtyList));
          (FUNMty(patTyList, bodyTy), (typedPatList, typedExp))
        )
        handle U.Unify =>
               let val ruleLoc = getRuleLocM [(patList, exp)]
               in
                 E.enqueueError
                     (ruleLoc, E.TyConListMismatch {argTyList = argtyList, domTyList = patTyList});
                 (ERRORty, ([TPPATWILD(ERRORty, ruleLoc)], TPERROR))
               end
      end

  and typeinfPatList currentContext ptpatList =
        foldr
        (fn (ptpat, (varEnv1, tyPatList, tppatList)) =>
         let
           val (varEnv2, ty, tppat) = typeinfPat currentContext ptpat
         in
           (
            SEnv.unionWith
              (fn (VARID{name, ...}, _) =>
               raise E.DuplicatePatternVar{vars = [name]})
              (varEnv2, varEnv1),
            ty::tyPatList,
            tppat::tppatList
            )
         end)
        (SE.emptyVarEnv, nil, nil)
        ptpatList

  (**
   * infer a mono type for a pattern
   * @params currentContext pattern
   * @return a varEnv of the pattern, pattern type, and a typed pattern
   *
   * exceptions
       E.DuplicatePatternVar
   *)
  and typeinfPat currentContext ptpat =
      (case ptpat of
         PT.PTPATWILD loc => 
         let val ty1 = newty univKind
         in (SE.emptyVarEnv, ty1, TPPATWILD (ty1, loc)) end
       | PT.PTPATID ([varId], loc) =>
         let 
	   val ((varStrPath,vid), idState) = TIC.lookupLongVar (currentContext, [varId])
         in
           (case idState of 
              SOME(CONID(con as {name, strpath, funtyCon, ty, tyCon, tag})) =>
              if not funtyCon
              then
                let 
		  val termconPathInfo =
                      {
                        name = varId,
                        strpath = varStrPath,
                        ty = ty,
                        tyCon = tyCon,
			tag = tag,
                        funtyCon = funtyCon
                      }
                  val (ty1, tylist) = 
                      case ty of
                        (POLYty{boundtvars, body, ...}) =>
                        let val subst = TU.freshSubst boundtvars
                        in (TU.substBTvar subst body, IEnv.listItems subst) end
                      | _ => (ty, nil)
                in
                  (
                    SE.emptyVarEnv,
                    ty1,
                    TPPATCONSTRUCT{conPat=termconPathInfo, 
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
                    E.ConRequireArg{con = name});
                 (
                  SE.emptyVarEnv,
                  ERRORty,
                  TPPATWILD (ERRORty, loc)
                  )
                 )
            | _ => 
              let
                val ty1 = newty univKind
                val varPathInfo = {name = varId, strpath = NilPath, ty = ty1}
                val varEnv1 =
                    SEnv.insert (SE.emptyVarEnv, varId, VARID varPathInfo)
              in
                (varEnv1, ty1, TPPATVAR (varPathInfo, loc))
              end)
         end
       | PT.PTPATID (longId, loc) =>
         let 
	   val ((varStrPath,vid), idState) = 
	       TIC.lookupLongVar (currentContext, longId)
         in
           (case idState of 
              SOME(CONID(con as {name,strpath,funtyCon, ty, tyCon, tag})) =>
              if not funtyCon
              then
                let 
		  val termconPathInfo =
                      {
                        name = Absyn.getLastIdOfLongid longId,
                        strpath = varStrPath,
                        ty = ty,
                        tyCon = tyCon,
			tag = tag,
                        funtyCon = funtyCon
                      }
                  val (ty1, tylist) = 
                      case ty of
                        (POLYty{boundtvars, body, ...}) =>
                        let val subst = TU.freshSubst boundtvars
                        in (TU.substBTvar subst body, IEnv.listItems subst) end
                      | _ => (ty, nil)
                in
                  (
                    SE.emptyVarEnv,
                    ty1,
                    TPPATCONSTRUCT{conPat=termconPathInfo, 
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
                    E.ConRequireArg{con = name});
                 (
                  SE.emptyVarEnv,
                  ERRORty,
                  TPPATWILD (ERRORty, loc)
                  )
                 )
	    | SOME _ => 
              (
               E.enqueueError(loc, E.NonConstructorPathInPat longId);
               (SE.emptyVarEnv, ERRORty, TPPATWILD (ERRORty, loc))
               )                
            | NONE => 
              (
                E.enqueueError(loc, E.ConstructorPathNotFound longId);
                (SE.emptyVarEnv, ERRORty, TPPATWILD (ERRORty, loc))
              )                
            )
         end
       | PT.PTPATCONSTANT (PT.INT(c, _), loc) => 
         (SE.emptyVarEnv, SE.intty, TPPATCONSTANT(INT c, SE.intty, loc))
       | PT.PTPATCONSTANT (PT.STRING(c, _), loc) => 
         (SE.emptyVarEnv, SE.stringty, TPPATCONSTANT(STRING c, SE.stringty, loc))
       | PT.PTPATCONSTANT (PT.REAL(c, _), loc) => 
         (SE.emptyVarEnv, SE.realty, TPPATCONSTANT (REAL c, SE.realty, loc))
       | PT.PTPATCONSTANT (PT.CHAR(c, _), loc) => 
         (SE.emptyVarEnv, SE.charty, TPPATCONSTANT (CHAR c, SE.charty, loc))
       | PT.PTPATCONSTANT (PT.WORD(c, _), loc) => 
         (SE.emptyVarEnv, SE.wordty, TPPATCONSTANT (WORD c, SE.wordty, loc))
       | PT.PTPATCONSTRUCT (ptpat1, ptpat2, loc) =>
         (case ptpat1 of
            PT.PTPATID(patId, _) =>
            (case TIC.lookupLongVar(currentContext, patId) of 
              ((patStrPath,vid), SOME (CONID (con as {name, strpath,funtyCon, ty, tyCon, tag})))
                =>
                 if funtyCon
                   then
                     let 
		       val termconPathInfo =
                           {
                             name = vid,
                             strpath = patStrPath,
                             ty = ty, 
			     tyCon = tyCon,
                             tag = tag,
                             funtyCon = funtyCon
                           }
                       val (varEnv1, patTy2, tppat2) =
                           typeinfPat currentContext ptpat2
                       val (domtyList, ranty, instTyList) = TU.coerceFunM (ty, [patTy2])
                       val domty = case domtyList of [ty] => ty | _ => raise Control.Bug "arity mismatch"
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
                         TPPATCONSTRUCT
                         {conPat=termconPathInfo, 
                          instTyList=instTyList, 
                          argPatOpt=SOME tppat2, 
                          patTy=ranty, 
                          loc=loc}
                        )
                     end
                 else 
                   (
                     E.enqueueError(loc,E.ConstantConApplied{con = name});
                    (SE.emptyVarEnv, ERRORty,TPPATWILD (ERRORty, loc))
                   )
             | _ => 
               (
                 E.enqueueError(loc, E.NonConstruct {pat = ptpat1});
                 (SE.emptyVarEnv, ERRORty, TPPATWILD (ERRORty, loc))
               ))
          | _ => 
              (
                E.enqueueError(loc, E.NonConstruct {pat = ptpat1});
                (SE.emptyVarEnv, ERRORty, TPPATWILD (ERRORty, loc))
              ))
       | PT.PTPATRECORD (flex, ptpatFields, loc) =>
         let 
           val (varEnv1, tyFields, tppatFields) =
               foldr
                   (fn ((label, ptpat), (varEnv1, tyFields, tppatFields)) =>
                       let
                         val (varEnv2, ty, tppat) =
                             typeinfPat currentContext ptpat
                       in
                         (
                           SEnv.unionWith
                               (fn (VARID{name, ...}, _) =>
                                   raise E.DuplicatePatternVar{vars = [name]})
                               (varEnv2, varEnv1),
                           SEnv.insert(tyFields, label, ty),
                           SEnv.insert(tppatFields, label, tppat)
                         )
                       end)
                   (SE.emptyVarEnv, SE.emptyTyfield, SEnv.empty)
                   ptpatFields
           val ty1 =
               if flex
               then
                 newty
                     {recKind = REC tyFields, eqKind = NONEQ, tyvarName = NONE}
               else RECORDty tyFields
         in
           (varEnv1, ty1, TPPATRECORD{fields=tppatFields, recordTy=ty1, loc=loc})
         end
       | PT.PTPATLAYERED (string, optTy, ptpat, loc) =>
         (case TIC.lookupVar(currentContext, string) of 
           SOME(CONID _) =>
            (
              E.enqueueError (loc, E.NonIDInLayered {id = string});
              (SEnv.empty, ERRORty, TPPATWILD (ERRORty, loc))
            )
          | _ => 
            let
              val (varEnv1, ty1, tpat) = typeinfPat currentContext ptpat
              val _ = 
                case optTy of
                    NONE => ()
                  | SOME rawTy => 
                      let val ty2 = evalRawty currentContext rawTy
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
              val varPathInfo = {name = string, strpath = NilPath, ty = ty1}
            in 
              (
                SEnv.insert (varEnv1, string, VARID varPathInfo),
                ty1,
                TPPATLAYERED{varPat=TPPATVAR (varPathInfo, loc), asPat=tpat, loc=loc}
              )
            end)
       | PT.PTPATTYPED (ptpat, rawTy, loc)  => 
         let
           val (varEnv1, ty1, tppat) = typeinfPat currentContext ptpat
           val ty2 = evalRawty currentContext rawTy
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
         end)

  (**
   * infer a type for ptdecl
   * @params currentContext ptdeclList
   * @return  a new currentContext and tpdeclList
   *)
  and typeinfPtdeclList isTop (currentContext:TIC.currentContext) nil = 
        (emptyContext, nil)
    | typeinfPtdeclList isTop currentContext (PT.PTEMPTY :: ptdeclList) = 
        typeinfPtdeclList isTop currentContext ptdeclList
    | typeinfPtdeclList isTop currentContext (ptdecl :: ptdeclList) =  
        let 
          val (newContext1, tpdeclList1) =
              typeinfPtdecl isTop currentContext ptdecl
          val (newContext2, tpdeclList) = 
               typeinfPtdeclList isTop
               (TIC.extendCurrentContextWithContext (currentContext, newContext1))
               ptdeclList
        in 
          (
           TC.extendContextWithContext {newContext = newContext2, oldContext =newContext1},
           tpdeclList1 @ tpdeclList
           )
      end

  (**
   * infer types for datatype declaration
   *)
  and typeinfConbind (currentContext:TIC.currentContext) (tyCon, (tyvars, tyConName, constructorList)) =
      let
        val (_, conbinds) = 
            foldl
            (fn ((_, cid, argTyOption), (index, conbinds)) =>
                let
                  val (utvarEnv, argTyvarStateRefs) = 
                    foldr 
                    (fn ({name=tid, ifeq=isEq}, (utvarEnv, argTyvarStateRefs)) => 
                           if SEnv.inDomain(utvarEnv, tid) then
                             raise E.DuplicateTvarNameInDatatypeArgs {tyvar=tid}
                           else 
                             let 
                               val newTvStateRef =
                                 newUtvar(if isEq then EQ else NONEQ, tid)
                             in 
                               (
                                SEnv.insert(utvarEnv, tid, newTvStateRef),
                                newTvStateRef :: argTyvarStateRefs
                                )
                             end)
                    (SEnv.empty, nil)
                    tyvars
                  val newCurrentContext =
                    TIC.extendCurrentContextWithUtvarEnv(currentContext, utvarEnv)
                  val resultTy = CONty {tyCon = tyCon, args = map TYVARty argTyvarStateRefs}
                  val (funtyCon, tyBody) =  
                    case argTyOption of
                        SOME ty => 
                        let
                          val argTy = evalRawty newCurrentContext ty
                        in
                          (true, FUNMty([argTy], resultTy))
                        end
                      | NONE => (false, resultTy)
                  val (_, btvs) =
                    (
                            foldl
                            (
                             fn (r as ref(TVAR (k as {id, ...})), (next, btvs)) =>
                                let
                                  val btvid = nextBTid()
                                in
                                 (
                                  r := SUBSTITUTED (BOUNDVARty btvid);
                                  (
                                   next + 1,
                                   IEnv.insert
                                   (
                                    btvs,
                                    btvid,
                                    {
                                     index = next,
                                     recKind = (#recKind k),
                                     eqKind = (#eqKind k)
                                     }
                                    )
                                   )
                                  )
                                end
                              | _ => raise Control.Bug "generalizeTy"
                             )
                            (0, IEnv.empty)
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
                    CONID
                    {
                     name = cid,
                     strpath = #strLevel currentContext,
                     funtyCon = funtyCon,
                     ty = if IEnv.isEmpty btvs
                            then tyBody
                          else                             
                            POLYty
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
            constructorList
      in 
        (tyCon, conbinds)
      end
  and makeTyFun (currentContext : TIC.currentContext) (tyvarList, string, rawty) =
      let
          val (_, tvarSEnv, tvarIEnv) = 
              foldl
                  (fn ({name=tyvarName,ifeq}, (n, tvarSEnv, tvarIEnv)) =>
                      let 
                          val newTy =
			      case newty {
					  recKind = UNIV, 
					  eqKind = NONEQ (*if bool then EQ else NONEQ*),
                                          (* 
                                           * Ignore eq attribute in tyfun. 
					   * This should be checked.
					   * NONEQ 
                                           *) 
					  tyvarName = NONE
                                   } of 
				TYVARty newTy => newTy
			      | _ => raise Control.Bug "newty returns non TYVARty"
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
	  val newcc = TIC.extendCurrentContextWithUtvarEnv(currentContext, tvarSEnv)
	  val originTy = evalRawty newcc rawty
	  val eqKind = if TU.admitEqTy originTy then EQ else NONEQ
	  (* tobe : opaque *)
          val newTyCon = TU.newTyCon {name = string, 
                                      abstract = false,
                                      strpath = #strLevel currentContext,
                                      tyvars = map (fn {name,ifeq} => ifeq) tyvarList,
                                      eqKind = ref eqKind, 
                                      boxedKind = ref (TU.boxedKindOptOfType originTy),
                                      datacon = ref SEnv.empty}
          val aliasTy = CONty {tyCon = newTyCon, args = map TYVARty (IEnv.listItems tvarIEnv)}
          val ty = ALIASty(aliasTy,originTy)
          val btvEnv = 
              IEnv.foldli
                  (fn (i, tvar as ref(TVAR (k as {id, ...})), btvEnv) => 
                      let 
                          val btvid = nextBTid()
                      in
                          (
                           tvar := SUBSTITUTED (BOUNDVARty btvid);
                           IEnv.insert
                               (
                                btvEnv,
                                btvid,
                                {
                                 index = i,
                                 recKind = (#recKind k),
                                 eqKind = (#eqKind k)
                                 }
                                )
                               )
                      end)
                  IEnv.empty
                  tvarIEnv
          val tyFun = {name = string, tyargs = btvEnv, body = ty}
      in
          (
           TC.bindTyConInEmptyContext (string,TYFUN tyFun),
           tyFun
           )
      end
  and typeinfDatatypeDecl currentContext datbinds loc =	
    let 
      val (tyConEnv, tyCons, varEnv) = typeinfDatabinds currentContext datbinds loc
      val newContext =
        TC.extendContextWithVarEnv
        (
         TC.injectTyConEnvToContext tyConEnv,
         varEnv
         )
    in
      (newContext, tyCons)
    end
  and typeinfDatabinds currentContext datbinds loc =
         let
           val (tyCons, tyConEnv1) = 
               foldr
                   (fn ((args, tid, _), (tyCons, tyConEnv1)) => 
                       let
                         val tyCon =
                             TU.newTyCon
                                 {
                                   name = tid,
				   strpath = #strLevel currentContext,
				   abstract = false,
                                   tyvars = map (fn {name, ifeq} => ifeq) args,
                                   eqKind = ref EQ,
				   boxedKind = ref (SOME ATOMty),
                                   datacon = ref SEnv.empty
                                 }
                       in
                         (
                           tyCon :: tyCons,
                           SEnv.insert(tyConEnv1, tid, TYCON tyCon)
                         )
                       end)
                   (nil, SEnv.empty)
                   datbinds
           val _ =
               foldr (fn ({name, ...}, s) => 
                      if SSet.member(s, name) then
                        raise E.DuplicateTypeNameInDatatypes {tyConName=name}
                      else SSet.add(s, name))
               SSet.empty 
               tyCons
           val tyConSet =
               foldr (fn ({id, ...}, s) => ID.Set.add(s, id))
               ID.Set.empty tyCons
           val datacons = 
               (map
                (typeinfConbind (TIC.extendCurrentContextWithTyConEnv (currentContext, tyConEnv1))) 
                (ListPair.zip (tyCons, datbinds)))
               handle exn as E.DuplicateTvarNameInDatatypeArgs _ =>
                 (E.enqueueError(loc, exn);
                  nil
                  )


           (* tyCon * datacon *)
           fun depends {name, strpath, funtyCon, ty, tyCon, tag} = 
               let 
                 fun dep ty = 
                     (case ty of 
                        FUNMty _ => ID.Set.empty
                      | CONty {tyCon = {eqKind, id, ...}, args} =>
                        foldr
                            (fn (ty, depset) => ID.Set.union(dep ty, depset))
                            (if ID.Set.member(tyConSet, id)
                             then ID.Set.singleton id
                             else ID.Set.empty)
                            args
                      | TYVARty tid => ID.Set.empty
                      | BOUNDVARty _ => ID.Set.empty
                      | POLYty _ => raise Control.Bug "polyty in combind"
                      | RECORDty fl => 
                        SEnv.foldr
                            (fn (ty, depsep) => ID.Set.union (dep ty, depsep))
                            ID.Set.empty
                            fl
                      | ERRORty => ID.Set.empty
                      | ALIASty (_, ty) => dep ty
		      | ABSSPECty(specTy,_) => dep specTy
                      | SPECty ty => dep ty
                      | _ => raise Control.Bug "illegal type in combind")
               in 
                 if funtyCon
                 then
                   case ty of
                     FUNMty([ty1], ty2) => dep ty1
                   | POLYty{body, ...} =>
                     (case body of
                        FUNMty([ty1], ty2) => dep ty1
                      | _ => raise Control.Bug "depends")
                   | _ => raise Control.Bug "depends"
                 else ID.Set.empty
               end
           (* 
              transitive closure computation of the dependency relation encoded in IEnv.
            *)
           fun tc ss = 
               if ID.Map.isEmpty ss
               then ss
               else 
                 let 
                   val (i, si) = valOf (ID.Map.firsti ss)
                   val rest = #1 (ID.Map.remove(ss, i))
                   val rest = 
                       tc
                       (ID.Map.map
                        (fn x => 
                            ID.Set.foldr
                            (fn (j, sx) =>
                                ID.Set.union
                                (
                                  sx,
                                  if i = j
                                  then ID.Set.add(si, j)
                                  else ID.Set.singleton j
                                ))
                            ID.Set.empty
                            x)
                        rest)
                   val si = 
                       ID.Set.foldr
                           (fn (j, csi) =>
                               ID.Set.union
                                   (
                                     csi,
                                     if j = i
                                     then ID.Set.singleton j
                                     else
                                       case ID.Map.find(rest, j) of
                                         SOME s => ID.Set.add(s, j)
                                       | _ => ID.Set.singleton j
                                   ))
                           ID.Set.empty
                           si
                 in 
                   ID.Map.insert (rest, i, si)
                 end
           val depEnv = 
               tc
               (foldr
                (fn (({name, strpath, abstract, tyvars, 
		       id, eqKind, boxedKind, datacon}, conbind), depset) =>
                    ID.Map.insert
                        (
                          depset,
                          id,
                          SEnv.foldr
                              (fn (CONID conInfo, s) =>
                                  ID.Set.union(depends conInfo,s)
                                | _ => raise Control.Bug "illegal data con")
                              ID.Set.empty
                              conbind
                        ))
                ID.Map.empty
                datacons)
           fun admitEq {name,strpath, funtyCon, ty, tyCon, tag} = 
               let 
                 fun eqCon ty =
                     (case ty of 
                        FUNMty _ => false
                      | CONty {tyCon = {eqKind, id, ...}, args} =>
                        if (foldr (fn (x,b) => eqCon x andalso b) true args)
                        then 
                          (if ID.Set.member(tyConSet, id)
                           then true
                           else (case !eqKind of EQ => true | _ => false))
                        else false
                      | TYVARty (ref(SUBSTITUTED ty)) => eqCon ty
                      | TYVARty (ref(TVAR k)) =>
                        (case k of
                           {eqKind = EQ, ...} => true
                         | {eqKind = NONEQ, ...} => false)
                      | BOUNDVARty _ => true
                      | POLYty _ => raise Control.Bug "polyty in combind"
                      | RECORDty fl => 
                        SEnv.foldr (fn (ty, b) => (eqCon ty) andalso b) true fl
                      | ALIASty (_, ty) => eqCon ty
                      | ERRORty => true
		      | ABSSPECty(specTy,_) => eqCon specTy
                      | SPECty ty => eqCon ty
                      | _ => raise Control.Bug "illegal type in combind")
               in
                 if funtyCon
                 then
                   case ty of
                     FUNMty([ty1], ty2) => eqCon ty1
                   | POLYty{body, ...} =>
                     (case body of
                        FUNMty([ty1], ty2) => eqCon ty1
                      | _ => raise Control.Bug "depends")
                   | ERRORty => true
                   | _ => raise Control.Bug "depends"
                 else true
               end
           val eqEnv = 
               foldr
                   (fn (({id, ...}, conbind), eqEnv) =>
                       ID.Map.insert
                           (
                             eqEnv,
                             id,
                             SEnv.foldr
                                 (fn (CONID conInfo, b) =>
                                     (admitEq conInfo) andalso b
                                   | _ => raise Control.Bug "datatype, eqEnv")
                                 true
                                 conbind
                           ))
                   ID.Map.empty
                   datacons
           val eqFlags = 
               ID.Map.mapi
                   (fn (originalId,depset) =>
                       ID.Set.foldr
                           (fn (dependId, b) => 
                               case ID.Map.find(eqEnv, dependId) of
                                 SOME b1 => (b1 andalso b)
                               | _ => raise Control.Bug "eqflagus")
                           (case ID.Map.find(eqEnv, originalId) of
                              SOME b => b
                            | _ => raise Control.Bug "eqflagus")
                           depset)
                   depEnv
           val datbind = 
               map
                 (fn ({name, strpath, abstract, tyvars, id, eqKind, boxedKind, datacon}, datcon) =>
                     (datacon := datcon;
		      (* 
		       * if dealing with datatype spec, it can not decide if it involves 
		       * a TYSPEC. The decision postpones to signature matching to 
		       * instantiate this field by the actual constrained structure
		       *)
(*
		      boxedKind := TU.calcTyConBoxedKindOpt datcon;
*)
                      eqKind :=
                      (if valOf(ID.Map.find(eqFlags, id)) then EQ else NONEQ)
                      handle Option => raise Control.Bug "datbind"
		     )
                 )
                 datacons
           val _ = TU.updateBoxedKinds tyCons
           val varEnv1 = 
               foldr
                   (fn ((_, con), vEnv)=> SEnv.unionWith #1 (con, vEnv))
                   SEnv.empty
                   datacons
         in
           (tyConEnv1, tyCons, varEnv1)
         end
       handle exn as E.DuplicateTypeNameInDatatypes _ =>
         (E.enqueueError(loc, exn);
          (SEnv.empty, nil, SEnv.empty)
          )

  and typeinfExnbind (currentContext:TIC.currentContext) exbind =
      case exbind of
        PT.PTEXBINDDEF(_, name, optRawty, loc) =>
        let 
          val optty =
              case optRawty of
                SOME rawty =>
                SOME(evalRawty currentContext rawty)
              | NONE => NONE
          val conPathInfo 
		as { name,funtyCon,ty,tyCon,tag,...}
	    = 
	      ITC.makeExnConpath (name,(#strLevel currentContext), optty)
          val idState = CONID conPathInfo
	  val termConPathInfo = 
	      { name = name, 
		strpath = NilPath,
		funtyCon = funtyCon, 
		ty = ty, 
		tyCon = tyCon,
		tag = tag}
        in
          (TC.bindVarInEmptyContext(name, idState), [TPEXNBINDDEF(termConPathInfo)])
        end
      | PT.PTEXBINDREP (_, string1, _, longid, loc) => 
        (case TIC.lookupLongVar(currentContext, longid)  of
           ((exnStrPath,exnid), SOME (idState as (CONID (conPathInfo as {tyCon = {id,...}, ...})))) => 
           if id = SE.exnTyConid
           then
	     let
	       val newIdState = CONID 
				  {
				   name = string1,
				   strpath = #strpath conPathInfo,
				   funtyCon = #funtyCon conPathInfo,
				   ty = #ty conPathInfo,
				   tag = #tag conPathInfo,
				   tyCon = #tyCon conPathInfo
				   }
	     in
               (
		TC.bindVarInEmptyContext(string1, newIdState),
		[TPEXNBINDREP (string1, (exnStrPath,exnid))]
		)
	     end
           else 
             (
               E.enqueueError(loc, E.NotExnCon{tyCon = Absyn.longidToString(longid)});
               (TC.emptyContext, nil)
             )
         | (_, SOME _)  =>
           (
             E.enqueueError (loc, E.NotExnCon{tyCon = Absyn.longidToString(longid)});
             (TC.emptyContext, nil)
           )
         | _ => 
           (
             E.enqueueError (loc, E.VarNotFound{id = Absyn.longidToString(longid)});
             (TC.emptyContext, nil)
           ))

  (**
   * infer types for declaration
   * @params currentContext ptdecl
   * @return a new currentContext a tpdec
   *
   * exceptions
      E.RecValNotID
      E.DuplicateTargsInTypeDef
   *)
  and typeinfPtdecl isTop (currentContext:TIC.currentContext) ptdecl =
      (case ptdecl of
         PT.PTVAL (tvarNameSet1, tvarNameSet2, ptpatPtexpList, loc) => 
         let 
           val _ =
             foldl 
             (fn ((ptpat, _), set2) => 
              let
                val set1 = freeVarsInPat currentContext ptpat
                val duplicates = SSet.intersection (set1,set2)
              in
                if SSet.isEmpty duplicates
                  then SSet.union(set1, set2)
                else
                  (
                   E.enqueueError
                   (
                    loc,
                    E.DuplicatePatternVar{vars = SSet.listItems duplicates}
                    );
                   SSet.union(set1, set2)
                   )
              end)
             SSet.empty
             ptpatPtexpList
             
           (* we continue compiling *)

           val (localBinds, patternVarBinds, extraBinds) = 
               foldr
               (fn ((ptpat, ptexp), (localBinds, patternVarBinds, extraBinds)) =>
                   let
                     val (newCurrentContext, addedUtvars1) =
                       TIC.addUtvarOverride(currentContext, tvarNameSet1)
                     val (newCurrentContext, addedUtvars2) =
                       TIC.addUtvarIfNotthere(newCurrentContext, tvarNameSet2)
                     val (localBinds1, patternVarBinds1, extraBinds1) = 
                         (decomposeValbind
                             (
                              currentContext,
                              newCurrentContext,
                              false
                              )
                             (ptpat, ptexp))
                         handle exn as E.RecordLabelSetMismatch =>
                                (
                                  E.enqueueError
                                   (Loc.mergeLocs (PT.getLocPat ptpat, PT.getLocExp ptexp),
                                    exn);
                                  (nil, nil, nil)
                                )
                              | exn as E.DuplicatePatternVar _ => 
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
                       (fn ((VALIDVAR {name, ty}, _), tyvarSet) =>
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
                       (fn (tyname, (ifeq, ref (SUBSTITUTED (BOUNDVARty _)))) =>()
                         | (tyname, (ifeq, ref (SUBSTITUTED ty))) =>
                            (
                              printType ty; 
                              raise Control.Bug "SUBSTITUTED to Non BoundVarTy"
                            )
                         | (tyname, (ifeq, tvstateRef))  => 
                             if OTSet.member(tyvarSet, tvstateRef) then
                               E.enqueueError(loc, E.UserTvarNotGeneralized {utvarName = 
                                                                             (if ifeq then "''" else "'")
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
           fun bindVarInVarEnv (varEnv, string, varPathInfo) = SEnv.insert(varEnv, string, varPathInfo)
           val newVarEnv = 
               foldl 
                   (fn ((VALIDVAR {name, ty}, _), newVarEnv) =>
                       let
                         val path = #strLevel currentContext
                         val varPathInfo =
                             {name = name, strpath = path, ty = ty}
                       in
		         bindVarInVarEnv(newVarEnv, name, VARID varPathInfo)
                       end
                     | (_, newVarEnv) => newVarEnv)
                   SE.emptyVarEnv
                   (patternVarBinds@extraBinds)
         in
           (
             TC.injectVarEnvToContext newVarEnv,
             let
               val exportDecls = 
                 (if null patternVarBinds then nil else [TPVAL (patternVarBinds, loc)])
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
       | PT.PTDECFUN (tvarNameSet1, tvarNameSet2, ptpatPtpatListPtexpListList, loc) =>
         let
           val (newCurrentContext, addedUtvars1) =
               TIC.addUtvarOverride(currentContext, tvarNameSet1)
           val (newCurrentContext, addedUtvars2) =
               TIC.addUtvarIfNotthere(newCurrentContext, tvarNameSet2)
           fun getFunIdFromPat (PT.PTPATID ([id], _)) = id
             | getFunIdFromPat (PT.PTPATTYPED(pat, _,_)) = getFunIdFromPat pat
             | getFunIdFromPat _ = raise Control.Bug "non id pat in fundecl"
           fun arityAndArgTyListOfMatch match =
             case match of
               nil => raise Control.Bug "empty match in fundecl"
             | (patList,exp)::_ => (List.length patList,
                                    map (fn _ => newty univKind) patList)
           val (newCurrentContext, funTyList) =
             foldr
             (fn ((funPat, ptmatch), (newCurrentContext, funTyList)) =>
              let
                val funId = getFunIdFromPat funPat
                val (arity, argTyList) = arityAndArgTyListOfMatch ptmatch
                val funTy = newty univKind
(*
                val strpath = NilPath
*)
                val strpath = #strLevel currentContext
                val funVarPathInfo = {name = funId, strpath = strpath, ty = funTy}
              in
                (
                  TIC.bindVarInCurrentContext
                  (newCurrentContext, 
                   funId, 
                   RECFUNID (funVarPathInfo, length argTyList)
                   ),
                  funTy::funTyList)
              end
            )
             (newCurrentContext, nil)
             ptpatPtpatListPtexpListList
           val ptpatRuleFunTyList = ListPair.zip (ptpatPtpatListPtexpListList,funTyList)
           val funBindList = 
             foldr
             (fn (((funPat, ptmatch),funTy), funBindList) =>
              let
                val funId = getFunIdFromPat funPat
                val (arity, argTyList) = arityAndArgTyListOfMatch ptmatch
                val strpath = NilPath
                val funVarPathInfo = {name = funId, strpath = strpath, ty = funTy}
                val (tpmatchTy, tpmatch) =
                  monoTypeinfMatch argTyList newCurrentContext ptmatch
                fun curryTy (FUNMty(argTyList, ty)) = 
                       foldr (fn (ty, body) => FUNMty([ty], body)) ty argTyList
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
                      id = funId,
                      definition = funType,
                      occurrence = funTy
                      }
                     )
              in
                {
                  funVar = funVarPathInfo,
                  bodyTy = case TU.derefTy tpmatchTy of
                             FUNMty (_, bodyTy) => bodyTy
                           | _ => raise Control.Bug "non fun type in fundecl",
                  argTyList = argTyList,
                  ruleList = tpmatch
                  } ::funBindList
              end 
            )
             nil
             ptpatRuleFunTyList

           val TypesOfAllElements =  
               RECORDty
                   (foldr
                        (fn ({funVar={name, strpath, ty},...}, tyFields) =>
                            SEnv.insert(tyFields, name, ty))
                        SEnv.empty
                        funBindList)
           val {boundEnv, ...} =
               generalizer (TypesOfAllElements, currentContext)
           val _ =
             SEnv.appi
               (fn (tyname, (ifeq, ref (SUBSTITUTED (BOUNDVARty _)))) =>()
                 | (tyname, (ifeq, _))  => 
                     E.enqueueError(loc, E.UserTvarNotGeneralized {utvarName = 
                                                                   (if ifeq then "''" else "'")
                                                                      ^ tyname}))
               (SEnv.unionWith #1 (addedUtvars1, addedUtvars2))
         in
           if IEnv.isEmpty boundEnv
           then
             (
               foldr
               (fn ({
                     funVar as {name, ty, strpath},
                     argTyList,
                     bodyTy,
                     ruleList
                     }, 
                    newContext) =>
                TC.bindVarInContext
                (
                 newContext, 
                 name,
                 if isTop then
                   VARID {
                          name = name, 
                          ty = ty, 
                          strpath = #strLevel currentContext (* !!!!!!!! *)
                          }
                 else
                   RECFUNID (
                             {
                              name = name, 
                              ty = ty, 
                              strpath = #strLevel currentContext (* !!!!!!!! *)
                              },
                             length argTyList
                             )
                 )
                )
               TC.emptyContext
               funBindList,
               [TPFUNDECL (funBindList, loc)] 
               )
           else 
             (
               foldr
               (fn ({funVar=funVar as {name, ty, strpath}, argTyList,...},newContext) => 
                TC.bindVarInContext
                (
                 newContext, 
                 name, 
                 if isTop then
                   VARID {
                          name = name,
                          ty = POLYty{boundtvars=boundEnv, body = ty},
                          strpath = #strLevel currentContext (* !!!!!!!! *)
                          }
                 else 
                   RECFUNID
                   (
                    {
                     name = name,
                     ty = POLYty{boundtvars=boundEnv, body = ty},
                     strpath = #strLevel currentContext (* !!!!!!!! *)
                     },
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
       | PT.PTNONRECFUN (tvarNameSet1, tvarNameSet2, ptpatPtpatListPtexp, loc) =>
         typeinfPtdecl isTop
         currentContext
         (PT.PTVAL
          (tvarNameSet1, 
           tvarNameSet2, 
           [transFunDecl loc ptpatPtpatListPtexp], 
           loc)
          )
       | PT.PTVALREC (tvarNameSet1, tvarNameSet2, ptpatPtexpList, loc) => 
         let
           val (newCurrentContext, addedUtvars1) =
               TIC.addUtvarOverride(currentContext, tvarNameSet1)
           val (newCurrentContext, addedUtvars2) =
               TIC.addUtvarIfNotthere(newCurrentContext, tvarNameSet2)
           val funIds = 
                map
                    (fn (PT.PTPATID ([string], _), _) => string
                      | (PT.PTPATTYPED
                             (PT.PTPATID
                                  ([string], _),_,_),_) =>
                        string
                      | _ => raise Control.Bug "recvalnotid in typeinf")
                    ptpatPtexpList
           val (tys, newCurrentContext) = 
               foldr
                   (fn (varId, (tys, newCurrentContext)) => 
                       let
                         val ty = newty univKind
                         val path = #strLevel currentContext
                         val varPathInfo =
                             {name = varId, strpath = path, ty = ty}
                       in
                         (
                           ty :: tys,
                           TIC.bindVarInCurrentContext
                           (newCurrentContext, varId, VARID varPathInfo)
                         )
                       end)
                   (nil, newCurrentContext)
                   funIds
           val varIDTyTpexpList = 
               map
               (fn ((PT.PTPATID ([string], _), ptexp) |
                    (PT.PTPATTYPED
                         (PT.PTPATID
                              ([string], _), _, _), ptexp))
                =>
                   let 
                     val (ptexpTy, tpexp) =
                         typeinfExp inf newCurrentContext ptexp
                     val stringTy =
                         case TIC.lookupVar(newCurrentContext, string) of
                           SOME (VARID{ty, ...}) => ty
                         | _ => raise Control.Bug "typeinfRecbind" 
                     val _ =
                         U.unify [(stringTy, ptexpTy)]
                         handle U.Unify =>
                                E.enqueueError
                                    (
                                      loc,
                                      E.RecDefinitionAndOccurrenceNotAgree
                                          {
                                            id = string,
                                            definition = ptexpTy,
                                            occurrence = stringTy
                                          }
                                          )
                     val varID = {name = string, ty = ptexpTy}
                   in
                     {var=varID, expTy=ptexpTy, exp=tpexp}
                   end 
                 | _ => raise Control.Bug "typeinfRecbind, not a variable")
               ptpatPtexpList
           val TypesOfAllElements =  
               RECORDty
                   (foldr
                        (fn ({var={name = funId, ...}, expTy, ...}, tyFields) =>
                            SEnv.insert(tyFields,funId, expTy))
                        SEnv.empty
                        varIDTyTpexpList)
           val {boundEnv, ...} =
               generalizer (TypesOfAllElements, currentContext)
           val _ =
             SEnv.appi
               (fn (tyname, (ifeq, ref (SUBSTITUTED (BOUNDVARty _)))) =>()
                 | (tyname, (ifeq, _))  => 
                     E.enqueueError(loc, E.UserTvarNotGeneralized {utvarName = 
                                                                   (if ifeq then "''" else "'")
                                                                      ^ tyname}))
               (SEnv.unionWith #1 (addedUtvars1, addedUtvars2))
         in
           if IEnv.isEmpty boundEnv
           then
             (
               foldr
                   (fn ({var=varID as {name,ty}, ...}, newContext) =>
                    TC.bindVarInContext
                        (
                         newContext, 
                         name, 
                         VARID 
                         {
                          name = name, 
                          strpath = #strLevel currentContext, 
                          ty = ty
                          }
                         ))
                   (TC.emptyContext)
                   varIDTyTpexpList,
               [TPVALREC (varIDTyTpexpList, loc)]
             )
           else 
             (
               foldr
                   (fn ({var=varID as {name, ty},...}, newContext) => 
                       TC.bindVarInContext
                           (
                             newContext, 
                             name, 
                             VARID
                             {
                               name = name,
			       strpath = #strLevel currentContext,
                               ty = POLYty{boundtvars = boundEnv, body = ty}
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
               typeinfPtdeclList isTop currentContext ptdecls
         in
           (newContext, [TPVALRECGROUP(ids, tpdeclList, loc)])
         end

       | PT.PTDATATYPE (datbinds, loc) =>
	 let
	   val (newContext, tyCons) =
               typeinfDatatypeDecl currentContext datbinds loc
	 in 
	   (newContext, [TPDATADEC(tyCons, loc)])
	 end
       | PT.PTABSTYPE (datbinds, ptdecls, loc) =>
	 let
	   val (tyConEnv, tyCons, varEnv) = typeinfDatabinds currentContext datbinds loc
           val newContext =
             TC.extendContextWithVarEnv
             (
              TC.injectTyConEnvToContext tyConEnv,
              varEnv
              )
           val newCurrentContext = TIC.extendCurrentContextWithContext (currentContext, newContext)
           val (newContext, newDecls) = typeinfPtdeclList isTop newCurrentContext ptdecls
	   (* tobe : abstract *)
           val (tyConSubst, newTyCons, newTyConEnv) =
               foldr (fn ({name, strpath, abstract, tyvars, id, eqKind, boxedKind, datacon}, 
			  (tyConSubst, newTyCons, newTyConEnv)) =>
			 let
                           val newtycon =
                               TU.newTyCon
				 {
				  name = name,
				  strpath = strpath,
				  abstract = true, (* abstract type *)
                                  tyvars = tyvars,
				  eqKind = ref NONEQ,
				  boxedKind = boxedKind,
				  datacon = datacon
				  }
			 in
                           (ID.Map.insert(tyConSubst, id, TYCON newtycon),
                            newtycon::newTyCons,
                            SEnv.insert(newTyConEnv, name, TYCON newtycon))
			 end)
		     (ID.Map.empty, nil, SEnv.empty)
		     tyCons
           val newContext = TCU.substTyConInContext tyConSubst newContext
	   val absLocalContext = TC.injectTyConEnvToContext newTyConEnv
           val newContext =
               TC.extendContextWithContext
		 {
		  newContext = newContext,
		  oldContext = absLocalContext
		  }
	 in 
	   (newContext, [TPABSDEC({absTyCons = newTyCons, rawTyCons = tyCons,  decls = newDecls}, loc)])
	 end
       | PT.PTLOCALDEC (ptdecls1, ptdecls2, loc) =>
           let 
             val (newContext1, tpdeclList1) =
               typeinfPtdeclList false currentContext ptdecls1
             val (newContext2, tpdeclList2) =
               typeinfPtdeclList isTop
               (TIC.extendCurrentContextWithContext(currentContext, newContext1))
               ptdecls2
           in
             (newContext2,  [TPLOCALDEC (tpdeclList1, tpdeclList2, loc)])
           end
       | PT.PTOPEN(longStrids,loc) =>
           let
	     val (newContext,newStrPathInfos)  = 
		 foldl (fn (longStrid, (newContext,newStrPathInfos)) => 
                           case TIC.lookupLongStructureEnv (currentContext, longStrid) of
                             (path, SOME {id = id, name = name, env = Env, strpath = strpath}) => 
			     let
			       val E as (te,ve,se)  = 
				   TCU.updateStrpathInTopEnv {
							  newStrpath = (#strLevel currentContext),
							  currentStrpath = P.appendPath(strpath,id,name)
							  }
							 Env
			       val {id, name} = P.getLastElementOfPath path
			       val strpath = P.getParentPath path
			       val strPathInfo = 
				   {id = id, name = name, strpath = strpath, env = E}
			       val newContext1 = 
				   TC.extendContextWithEnv(newContext,E)
			     in
			       (newContext1,
				newStrPathInfos @ [strPathInfo])
			     end
                           | (_, NONE) => (E.enqueueError
                                             (
                                              loc,
                                              E.StructureNotFound
						({id = Absyn.longidToString(longStrid)})
						);
                                             (newContext,nil)
					     )
			)
		       (TC.emptyContext,nil)
		       longStrids
           in
	     (newContext,[TPOPEN (newStrPathInfos, loc)])
           end
       | PT.PTTYPE (tvarListStringRawtyList, loc) => 
         (let
            val (newContext, tyFunList) =
                foldr
                    (fn (tydecl, (newContext, tyFunList)) => 
                        let
                          val (tyFunContext, tyFun as {name,tyargs,body}) =
                              makeTyFun currentContext tydecl
                        in
                          (
                            TC.extendContextWithContext
                               {newContext = tyFunContext, oldContext = newContext},
                            (TYFUN tyFun) :: tyFunList
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
       | PT.PTREPLICATEDAT (string1, longid , loc) => 
         (case TIC.lookupLongTyCon(currentContext, longid) of
            ((tyConStrPath,tyConName), SOME tyBindInfo) =>
            (
             case tyBindInfo of
	       TYCON rightTyCon => 
	       let
		 val {name,strpath,abstract,tyvars,id,eqKind,boxedKind,datacon} : tyCon= rightTyCon
		 val leftTyCon : tyCon = 
		     { name = string1,
		       strpath = #strLevel currentContext,
		       abstract = abstract,
                       tyvars = tyvars,
		       id = id,
		       eqKind = eqKind,
		       boxedKind = boxedKind,
		       datacon = ref SEnv.empty } 
		 val tyConSubst = ID.Map.singleton(id,TYCON leftTyCon)
		 val (visited,newDatacon) = 
		     TCU.substTyConInVarEnv ID.Set.empty tyConSubst (!datacon)
		 val _ = (#datacon leftTyCon):= newDatacon
		 val context1 =
                     TC.bindTyConInEmptyContext
                       (
                        string1,
			TYCON leftTyCon
                        )
		 val context2 = 
		     if not abstract then
		       TC.extendContextWithVarEnv(context1, !(#datacon leftTyCon))
		     else
		       context1
	       in
		 (
                   context2,
                   [TPDATAREPDEC
                        (
                          {
			    left = leftTyCon, 
			    right =
                            {
			      relativePath = (tyConStrPath,tyConName),
			      tyCon = rightTyCon
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
                   E.TyConNotFoundInReplicateData{tyCon = Absyn.longidToString(longid)}
                   );
		  (
                   TC.emptyContext,
                   nil
                   )
                  )
	       )
          | (_, NONE) =>
            (
             E.enqueueError
               (loc, E.TyConNotFoundInReplicateData{tyCon = Absyn.longidToString(longid)});
               (TC.emptyContext, nil)
               ))
      | PT.PTEXD (exnBinds, loc) =>
        let 
          val (newContext, newExnBinds) =
              foldr
                  (fn (exnBind, (newContext, newExnBinds)) =>
                      let
                        val (localContext, newExnBind) =
                            typeinfExnbind currentContext exnBind
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
      | PT.PTFFIVAL{name, funExp, libExp, argTyList, resultTy, loc} =>
        let
          val (funExpTy, tpFunExp) = typeinfExp inf currentContext funExp
          val (libExpTy, tpLibExp) = typeinfExp inf currentContext libExp
          val _ =
              U.unify [(SE.stringty, funExpTy)]
              handle U.Unify => E.enqueueError (loc, E.FFIFunctionLibraryName)
          val _ =
              U.unify [(SE.stringty, libExpTy)]
              handle U.Unify => E.enqueueError (loc, E.FFIFunctionLibraryName)

          val newArgTys = map (evalRawty currentContext) argTyList
          val newResultTy = evalRawty currentContext resultTy

          val (newTy, newArgTy) = 
              case newArgTys of
                [] => (FUNMty([SE.unitty], newResultTy), SE.unitty)
              | [argTy] => (FUNMty([argTy], newResultTy), argTy)
              | _ :: _ =>
                let
                  val (_, tySmap) = 
                      foldl
                          (fn (argTy, (n, tySmap)) =>
                              let val label = Int.toString n
                              in (n + 1, SEnv.insert(tySmap, label, argTy))
                              end)
                          (1, SEnv.empty)
                          newArgTys
                in (FUNMty([RECORDty tySmap], newResultTy), RECORDty tySmap)
                end
          val foreignInfo =
              {
                name = name,
                strpath = #strLevel currentContext,
                ty = newTy,
                argTys = newArgTys
              }
          val exportFunInfo =
              {
                name = name,
                strpath = #strLevel currentContext,
                ty = newTy
              }
          val tpffival = 
            TPFFIVAL
            {
             funExp=tpFunExp, 
             libExp=tpLibExp, 
             argTyList=newArgTys, 
             resultTy=newResultTy, 
             funTy=newTy, 
             loc=loc
             }
          val etaExpandedTpFffival = 
            let
             val funVarPathInfo =
                 {name = name, strpath = #strLevel currentContext, ty = newTy}
             val funVarExp = TPVAR(funVarPathInfo, loc)
             val newVarPathInfo =
                 {name = Vars.newTPVarName(), strpath = NilPath, ty = newArgTy}
           in
             TPFNM
                   {
                     argVarList=[newVarPathInfo],
                     bodyTy=newResultTy,
                     bodyExp=
                       TPFOREIGNAPPLY
                         {
                           funExp=funVarExp,
                           instTyList=nil,
                           argExp=TPVAR (newVarPathInfo, loc),
                           argTyList=newArgTys,
                           loc=loc
                         },
                     loc=loc
                   }
            end
        in
          if isTop then
            (
             TC.bindVarInEmptyContext(name, VARID exportFunInfo),
              (* this is a temporal fix *)
              [
               TPLOCALDEC
               (
                [
                 TPVAL
                 (
                  [
                   (
                    VALIDVAR {name = name, ty = newTy}, 
                    tpffival
                    )
                   ],
                  loc
                  )
                 ],
                [
                 TPVAL
                 (
                  [(
                    VALIDVAR {name = name, ty = newTy}, 
                    etaExpandedTpFffival
                    )],
                  loc
                  )
                 ],
                loc
                )
               ]
              )
            else
            (
             TC.bindVarInEmptyContext(name, FFID foreignInfo),
              [
               TPVAL
               (
                [(
                  VALIDVAR {name = name, ty = newTy}, 
                  tpffival
                  )],
                loc
                )
               ]
          )
        end
      | PT.PTEMPTY => raise Control.Bug "try to infer type for the empty dec")

   fun typeinfTopPtdecl (currentContext:TIC.currentContext) ptdecl =
     let
        val _ = kindedTyvarList := nil
        val (newContext, tpdeclList) = typeinfPtdecl true currentContext ptdecl
        val tyvars = TypeContextUtils.tyvarsContext newContext
        val dummyTyList =
          (foldr
           (fn (r as ref(TVAR {recKind = OVERLOADED (h :: tl), ...}),dummyTyList) => 
                 (r := SUBSTITUTED h; dummyTyList)
             | (r as ref (TVAR {id, recKind=UNIV, eqKind, tyvarName}), dummyTyList) =>
                 let
                   val dummyty = TIU.nextDummyTy ()
                   val _ = r := (SUBSTITUTED dummyty)
                 in
                   dummyty :: dummyTyList
                 end
            | (**** temporary fix of BUG 200 ***)
               (r as ref (TVAR {id, recKind=REC tySEnvMap, eqKind, tyvarName}), dummyTyList) =>
                 let
                   val _ = r := (SUBSTITUTED (RECORDty tySEnvMap))
                 in
                   dummyTyList
                 end
             | (r as ref (SUBSTITUTED _), dummyTyList) => dummyTyList
                 )
            nil
            (OTSet.listItems tyvars)
            )
            handle x => raise x
        val _ =
          if E.isError()
            then ()
          else 
            case dummyTyList of
              nil => ()
            | _ =>
                E.enqueueWarning
                (PT.getLocDec ptdecl, E.ValueRestriction {dummyTyList = dummyTyList})
        val _ = TU.eliminateVacuousTyvars()
     in
       (newContext, tpdeclList)
     end
   handle x => raise x
end
end
