(**
 * a kinded type inference with type operators for ML core
 * (imperative version).
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TypeInferCore.sml,v 1.88 2007/06/19 22:19:12 ohori Exp $
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

  val emptyContext = TC.emptyContext

  open TypedCalc

  val maxDepth = ref 0
  fun incDepth () = (maxDepth := !maxDepth + 1; !maxDepth)

  val ffiApplyTyvars = ref nil : (T.ty * Loc.loc) list ref

in
 (* for debugging *)
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

 (* type generalization *)
  fun generalizer (ty, lambdaDepth) =
    if E.isError()
      then {boundEnv = IEnv.empty, removedTyIds = OTSet.empty}
    else TypesUtils.generalizer (ty, lambdaDepth)

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
             (E.enqueueError(loc, E.NotBoundTyvar{tyvar = string}); T.ERRORty)
         | SOME ty => 
             if isEq then 
               if TU.admitEqTy ty then ty
               else (E.enqueueError(loc, E.InconsistentEQInDatatype {tyvar = string}); T.ERRORty)
             else 
               if TU.admitEqTy ty then 
                 (E.enqueueError(loc, E.InconsistentEQInDatatype {tyvar = string}); T.ERRORty)
               else ty
             )
      | A.TYRECORD (nil, loc) => PDT.unitty
      | A.TYRECORD (stringRawtyList, loc) =>
          T.RECORDty
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
              (_, SOME(T.TYCON tyCon)) =>
                let
                  val wants = List.length (#tyvars tyCon)
                  val given = List.length tyList
                in
                  if wants = given
                    then T.CONty{tyCon = tyCon, args = tyList}
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
                     T.ERRORty
                     )
                end
            | (_, SOME(T.TYFUN {tyargs = btvKindIEnvMap, body = ty,...})) => 
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
                     T.ERRORty
                     )
                end
            | (_,SOME(T.TYSPEC {spec = {name, id, strpath, eqKind, tyvars, boxedKind},
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
                  val specTy = T.CONty{tyCon = newtyCon, args = tyList}
                  val implOpt = case implOpt of
                                     NONE => NONE
                                   | SOME impl => SOME (TU.peelTySpec impl)
                in
                  if wants = given
                    then 
                      case implOpt of
                        NONE => T.SPECty specTy
                      | SOME (T.TYFUN tyFun) =>
                          let
                            val implTy = TU.betaReduceTy (tyFun,tyList)
                          in
                            T.ABSSPECty(specTy, implTy)
                          end
                      | SOME (T.TYCON tyCon) =>
                          let
                            val implTy = T.CONty{tyCon = tyCon, args = tyList}
                          in
                            T.ABSSPECty(specTy, implTy)
                          end
                      | SOME (T.TYSPEC _) => raise Control.Bug "tyspec can not be implementation tybindinfo"
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
                     T.ERRORty
                     )
                end
            | (_,NONE) => 
                (
                 E.enqueueError
                 (loc, E.TyConNotFoundInRawTy{tyCon = Absyn.longidToString(stringList)});
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
              (tyFields, Int.toString n, evalRawty currentContext rawty))
             )
            (1, SEnv.empty)
            rawtyList))
      | A.TYFUN (rawty1, rawty2, loc) =>
          T.FUNMty([evalRawty currentContext rawty1], evalRawty currentContext rawty2)
      | A.TYFFI (cconv, domTys, ranTy, loc) =>
        (* Although TYFFI has no denotation, we return T.FUNMty here in order to
         * detect un-interoperable type construction at foreign function stub generation. *)
        evalRawty currentContext (A.TYFUN (A.TYTUPLE(domTys, loc), ranTy, loc))

  fun isVar ptexp = 
      case ptexp of
        PT.PTVAR _ => true
      | PT.PTTYPED (ptexp, _, _) => isVar ptexp
      | _ => false

  fun makeLocalVarPathInfo ({name, ty}) =
      {name = name, strpath = T.NilPath, ty = ty}

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
      T.eqTyCon (#tyCon conPathInfo, PDT.refTyCon)

  fun expansive tpexp =
      case tpexp of 
        TPFOREIGNAPPLY _ => true
      | TPEXPORTCALLBACK _ => true
      | TPSIZEOF _ => true
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
      | TPLIST {expList,...} => 
          foldl
          (fn (tpexp1, isExpansive) =>
           isExpansive orelse expansive tpexp1)
          false
          expList
      | TPSEQ _ => true
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
              (_, SOME(T.CONID _)) => SSet.empty
            | _ => SSet.singleton string
         )
      | PT.PTPATID (stringList, loc) => 
        (case TIC.lookupLongVar (currentContext, stringList) of
           (_, SOME(T.CONID _)) => SSet.empty
         | (_, SOME _) => 
             (E.enqueueError(loc, E.NonConstructorPathInPat stringList); 
              SSet.empty)
         | (_, NONE) => 
             (E.enqueueError(loc, E.ConstructorPathNotFound stringList);
              SSet.empty)
         )
      | PT.PTPATCONSTANT _ => SSet.empty
      | PT.PTPATCONSTRUCT (ptpatCon, ptpat, loc) => 
         (case ptpatCon of
             PT.PTPATID ([string], loc) => 
               (case TIC.lookupLongVar (currentContext, [string]) of
                  (_, SOME(T.CONID _)) => freeVarsInPat currentContext ptpat
                | _ => 
                    (E.enqueueError(loc, E.NonConstruct {pat = ptpatCon}); 
                     SSet.empty
                     )
               )
           | PT.PTPATID (stringList, loc) => 
              (case TIC.lookupLongVar (currentContext, stringList) of
                 (_, SOME(T.CONID _)) => freeVarsInPat currentContext ptpat
               | (_, SOME _) => 
                   (E.enqueueError(loc, E.ConstructorPathNotFound stringList);
                    SSet.empty)
               | (_, NONE) => 
                   (E.enqueueError(loc, E.ConstructorPathNotFound stringList);
                    SSet.empty)
                   )
           | PT.PTPATTYPED (ptpatCon, _, _) => 
               freeVarsInPat currentContext (PT.PTPATCONSTRUCT (ptpatCon, ptpat, loc))
           | _ => 
              (
               E.enqueueError(PT.getLocPat ptpatCon, E.NonConstruct {pat = ptpatCon}); 
               SSet.empty
               )
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
           SOME(T.CONID _) =>
           raise Control.Bug "not id in layered pat in typeinf"
         | _ =>
           let val set1 = freeVarsInPat currentContext ptpat
           in
             if SSet.member(set1, string)
             then 
               (
                 E.enqueueError (loc,E.DuplicatePatternVar{vars = [string]});
                 set1
               )
             else SSet.add(set1, string)
           end)
      | PT.PTPATTYPED (ptpat, _, _) => freeVarsInPat currentContext ptpat
      | PT.PTPATORPAT (ptpat1, ptpat2, loc) => 
          let
            val set1 = freeVarsInPat currentContext ptpat1
            val set2 = freeVarsInPat currentContext ptpat2
            val diff1 = SSet.difference(set1, set2)
            val diff2 = SSet.difference(set2, set1)
            val diffs = SSet.union(diff1,diff2)
         in
            if SSet.isEmpty diffs 
              then set1
            else
              (
               E.enqueueError
               (
                loc,
                E.DIfferentOrPatternVars {vars = SSet.listItems diffs}
                );
               SSet.union(set1, set2)
               )
          end

  
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
                  funTy = T.FUNMty(domtyList, ranty), 
                  argExpList = argTpexpList, 
                  loc=termLoc}
          )
         )
        handle U.Unify =>
               ( 
                E.enqueueError (termLoc, E.TyConListMismatch {argTyList = argTyList, domTyList = domtyList});
                (T.ERRORty, TPERROR)
               ) 
      end
         handle TU.CoerceFun =>
                  (
                   E.enqueueError (funLoc, E.NonFunction {ty = funTy});
                   (T.ERRORty, TPERROR)
                   )

  fun transFunDecl loc (funPat as (PT.PTPATID ([funId], patLoc)), ruleList as ((patList, exp)::_)) =
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
        [(funPat, funBody)]
      end
    | transFunDecl _ _ = raise Control.Bug "illegal fun decl "

  fun coerceToDummyTy tyvarRef =
      case tyvarRef of
        ref (T.TVAR {recKind = T.UNIV, ...}) => 
        let
          val dummyty = TIU.nextDummyTy ()
          val _ = tyvarRef := (T.SUBSTITUTED dummyty)
        in
          dummyty
        end
      | (**** temporary fix of BUG 200 ***)
        ref (T.TVAR {recKind = T.REC tySEnvMap, ...}) =>
          T.RECORDty tySEnvMap                          
      | _ => (printType (T.TYVARty tyvarRef) ; raise Control.Bug "coerceToDummyTy")



  (* foreign function stub generation *)

  fun getRealTy ty =
      case TU.derefTy ty of
        T.ABSSPECty (_, ty) => getRealTy ty
      | ty => ty

  fun userTyvars ty =
      OTSet.filter (fn tvState as ref(T.TVAR{tyvarName=SOME _,...}) => true
                     | _ => false)
                   (TU.EFTV ty)

  fun isInteroperableType allowTyvar ty =
      case getRealTy ty of
        T.TYVARty _ => allowTyvar
      | T.RECORDty record =>
        SEnv.foldl (fn (ty, z) => z andalso isInteroperableType true ty) true record
      | ty as T.CONty {tyCon, args} =>
        let
          val boxed = case !(#boxedKind tyCon) of
                        T.BOXEDty => true | _ => false
        in
          if ID.eq (#id tyCon, PDT.unitTyConid)
          then false
          else if ID.eq (#id tyCon, PDT.pointerTyConid)
          then true
          else foldl (fn (ty, z) => z andalso isInteroperableType boxed ty) true args
        end
      | T.ERRORty => true
      | _ => false

  fun checkInteroperableType allowTyvar (rawty, ty) =
      if isInteroperableType allowTyvar ty
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
        else OTSet.app
                 (fn tvState =>
                     E.enqueueError (loc, E.FFIInvalidTyvar (T.TYVARty tvState)))
                 dif
      end
    | checkSafeStubType _ = ()

  local
    fun newVar ty =
        {name = Vars.newTPVarName(), strpath = T.NilPath, ty = ty}

    fun newTyvar () =
        T.newty {recKind = T.UNIV, eqKind = T.NONEQ, tyvarName = NONE}

    fun isUnitTy ty =
        case TU.derefTy ty of
          T.CONty {tyCon, ...} => ID.eq (#id tyCon, PDT.unitTyConid)
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
                       (rawty,
                        case SEnv.find (fieldTys, n) of
                          SOME ty => ty
                        | NONE => raise Control.Bug ("explodeTuple: " ^ n),
                        TPSELECT {label = n,
                                  exp = exp,
                                  expTy = expTy,
                                  loc = loc},
                        loc) :: z)
                   nil rawtys
      | explodeTuple (rawtys, expTy, exp, loc) =
        if isUnitTy expTy
        then []
        else raise Control.Bug "explodeTuple: not a record"

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
              raise Control.Bug "implodeRecord"
        in
          implode (SEnv.empty, SEnv.empty, names, exps)
        end

    fun explodeRecord (rawFieldTys, expTy as T.RECORDty fieldTys, exp, loc) =
        map (fn (name, rawty) =>
                (rawty,
                 case SEnv.find (fieldTys, name) of
                   SOME ty => ty
                 | NONE => raise Control.Bug ("explodeRecord: " ^ name),
                 TPSELECT {label = name,
                           exp = exp,
                           expTy = expTy,
                           loc = loc},
                 loc))
            rawFieldTys
      | explodeRecord (rawFieldTys, expTy, exp, loc) =
        if isUnitTy expTy
        then []
        else raise Control.Bug "explodeRecord: not a record"

    fun stubUnit (expTy, exp, loc) =
        (U.unify [(PDT.unitty, expTy)];
         (PDT.unitty, exp))
        handle U.Unify =>
               (E.enqueueError (loc, E.FFIStubMismatch (PDT.unitty, expTy));
                (T.ERRORty, TPERROR))

    fun stubTuple stub (rawtys, expTy, exp, loc) =
        let
          val rawFieldTys = foldrTuple (fn (n,ty,z) => (n,ty)::z) nil rawtys
          val fieldNames = map #1 rawFieldTys
          val fieldTys = map (fn (name,_) => (name, newTyvar ())) rawFieldTys
          val recordTy = implodeRecordTy fieldTys
          val fields = explodeRecord (rawFieldTys, recordTy, exp, loc)
          val rets = map (stub true) fields
        in
          (U.unify [(recordTy, expTy)];
           implodeRecord (fieldNames, rets, loc))
          handle U.Unify =>
                 (E.enqueueError (loc, E.FFIStubMismatch (recordTy, expTy));
                  (T.ERRORty, TPERROR))
        end

    fun stubDirect currentContext allowTyvar (rawty, expTy, exp, loc) =
        let
          val ty = evalRawty currentContext rawty
          val _ = checkInteroperableType allowTyvar (rawty, ty)
        in
          (U.unify [(ty, expTy)];
           (ty, exp))
          handle U.Unify =>
                 (E.enqueueError (loc, E.FFIStubMismatch (ty, expTy));
                  (T.ERRORty, TPERROR))
        end

  in

  fun stubImport currentContext allowTyvar (A.TYFFI (convention, rawArgTys, rawRetTy, _), expTy, exp, loc) =
      let
        val expTy = getRealTy expTy

        val argTys = map (fn _ => newTyvar ()) rawArgTys
        val argTy = implodeTupleTy argTys
        val argVar = newVar argTy
        val argVarExp = TPVAR (argVar, loc)
        val args = explodeTuple (rawArgTys, argTy, argVarExp, loc)
        val ffiArgs = map (stubExport currentContext false) args
        val ffiArgTys = map #1 ffiArgs
        val ffiArgExps = map #2 ffiArgs

        val ffiRetTy = newTyvar ()
        val ffiRetVar = newVar ffiRetTy
        val ffiRetVarExp = TPVAR (ffiRetVar, loc)
        val (retTy, retExp) =
            stubImportAllowingUnit currentContext false (rawRetTy, ffiRetTy, ffiRetVarExp, loc)

        val ffiFunty = T.FUNMty(ffiArgTys, ffiRetTy)
        val _ = checkSafeStubType (ffiFunty, loc)
        val ffiFunVar = newVar PDT.ptrty
      in
        (U.unify [(PDT.ptrty, expTy)];
         (*
          * fn x : domTy =>
          *   let f = M
          *       y = FFI (f:funty, Phi(#1 x), ..., Phi(#n x))
          *   in Psi(y)
          * : retTy
          *)
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
                      funExp = TPVAR (ffiFunVar, loc),  (* only VAR may be here *)
                      funTy = ffiFunty,
                      instTyList = nil,
                      argExpList = ffiArgExps,
                      argTyList = ffiArgTys,
                      convention = convention
                    })],
                bodyExp = retExp
              }
          }))
        handle U.Unify =>
               (E.enqueueError (loc, E.FFIStubMismatch (PDT.ptrty, expTy));
                (T.ERRORty, TPERROR))
      end

    | stubImport currentContext allowTyvar (A.TYRECORD (rawFieldTys, _), expTy, exp, loc) =
      let
        val fieldNames = map #1 rawFieldTys
        val rawTupleFieldTys = foldrTuple (fn (n,(_,ty),z) => (n,ty)::z) nil rawFieldTys
        val tupleFieldTys = map (fn (name,_) => (name, newTyvar ())) rawTupleFieldTys
        val tupleTy = implodeRecordTy tupleFieldTys
        val fields = explodeRecord (rawTupleFieldTys, tupleTy, exp, loc)
        val rets = map (stubImport currentContext true) fields
      in
        (U.unify [(tupleTy, expTy)];
         implodeRecord (fieldNames, rets, loc))
        handle U.Unify =>
               (E.enqueueError (loc, E.FFIStubMismatch (tupleTy, expTy));
                (T.ERRORty, TPERROR))
      end

    | stubImport currentContext allowTyvar (A.TYTUPLE (rawtys, _), expTy, exp, loc) =
      stubTuple (stubImport currentContext) (rawtys, expTy, exp, loc)

    | stubImport currentContext allowTyvar (rawty, expTy, exp, loc) =
      stubDirect currentContext allowTyvar (rawty, expTy, exp, loc)

  and stubImportAllowingUnit currentContext allowTyvar (ffirawty, expTy, exp, loc) =
      if isUnitTy (evalRawty currentContext ffirawty)
      then stubUnit (expTy, exp, loc)
      else stubImport currentContext false (ffirawty, expTy, exp, loc)

  and stubExport currentContext allowTyvar (A.TYFFI (convention, rawArgTys, rawRetTy, _), expTy, exp, loc) =
      let
        val ffiArgs = map (fn rawty =>
                              let val ty = newTyvar ()
                                  val var = newVar ty
                              in (rawty, ty, var, TPVAR (var, loc))
                              end)
                      rawArgTys
        val ffiArgTys = map #2 ffiArgs
        val ffiArgVars = map #3 ffiArgs
        val ffiArgExps = map #4 ffiArgs
        val args = map (fn (rawty, ty, var, exp) =>
                           stubImport currentContext false (rawty, ty, exp, loc))
                       ffiArgs
        val (argTy, argExp) = implodeTuple (args, loc)

        val retTy = newTyvar ()
        val retVar = newVar retTy
        val retVarExp = TPVAR (retVar, loc)
        val (ffiRetTy, ffiRetExp) =
            if isUnitTy (evalRawty currentContext rawRetTy)
            then stubUnit (retTy, retVarExp, loc)
            else stubExport currentContext false (rawRetTy, retTy, retVarExp, loc)

        val ffiFunty = T.FUNMty (ffiArgTys, ffiRetTy)
        val _ = checkSafeStubType (ffiFunty, loc)

        val ffiFunVar = newVar ffiFunty
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
            * let z = fn {x1,...,xn} : ffiArgTys =>
            *            let y = (f:funTy) (Psi(x1), ..., Psi(xn))
            *            in Phi(y)
            * in EXPORTCALLBACK(z)
            *)
           (PDT.ptrty,
            TPMONOLET
            {
              loc = loc,
              binds =
                [(ffiFunVar,
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
                      }
                  })],
              bodyExp =
                TPEXPORTCALLBACK
                {
                  loc = loc,
                  instTyList = nil,
                  argTyList = ffiArgTys,
                  resultTy = ffiRetTy,
                  funExp = TPVAR (ffiFunVar, loc)
                }
            }))
          handle U.Unify =>
                 (E.enqueueError (loc, E.FFIStubMismatch (funTy, monoExpTy));
                  (T.ERRORty, TPERROR))
        end
        handle TU.CoerceFun =>
               (E.enqueueError (loc, E.NonFunction {ty = expTy});
                (T.ERRORty, TPERROR))
      end

    | stubExport currentContext allowTyvar (A.TYRECORD (rawFieldTys, _), expTy, exp, loc) =
      let
        val fieldTys = map (fn (name, _) => (name, newTyvar ())) rawFieldTys
        val recordTy = implodeRecordTy fieldTys
        val fields = explodeRecord (rawFieldTys, recordTy, exp, loc)
        val rets = map (stubExport currentContext true) fields
        val recordFields = foldrTuple (fn (n,x,z) => (n,x)::z) nil rets
      in
        (U.unify [(recordTy, expTy)];
         implodeRecord (map #1 recordFields, map #2 recordFields, loc))
        handle U.Unify =>
               (E.enqueueError (loc, E.FFIStubMismatch (recordTy, expTy));
                (T.ERRORty, TPERROR))
      end

    | stubExport currentContext allowTyvar (A.TYTUPLE (rawtys, _), expTy, exp, loc) =
      stubTuple (stubExport currentContext) (rawtys, expTy, exp, loc)

    | stubExport currentContext allowTyvar (rawty, expTy, exp, loc) =
      stubDirect currentContext allowTyvar (rawty, expTy, exp, loc)

  fun generalizeStub (stubTy, stubExp, lambdaDepth, loc) =
      let
        val {boundEnv, ...} = generalizer (stubTy, lambdaDepth)
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

  fun makeMulInt (arg1, arg2, loc) =
      let
        val (argTy, argExp) = implodeTuple ([(PDT.intty, arg1), (PDT.intty, arg2)], loc)
      in
        (PDT.intty,
         TPPRIMAPPLY
         {
           primOp = Primitives.mulIntPrimInfo,
           instTyList = nil,
           argExpOpt = SOME argExp,
           loc = loc
         })
      end

  end




  (**
   *)
  fun typeinfConst absynConst =
    let
      fun staticEvalConst const =
        case const of
          PT.INT (int, _) => CT.INT int
        | PT.WORD (word, _) => CT.WORD word
        | PT.REAL (real, _) => CT.REAL real
        | PT.STRING (string, _) => CT.STRING string
        | PT.CHAR (char, _) => CT.CHAR char
        | PT.UNITCONST _ => CT.UNIT
      val const = staticEvalConst absynConst
      val (ty, _) = TIU.freshTopLevelInstTy (CT.constTy const)
    in
      (ty, const)
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
    lambdaDepth : outer lambda depth
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
      lambdaDepth
      (currentContext, ifGenTerm)
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
                   TPFNM {argVarList=argVarPathInfoList, bodyTy=ranTy, bodyExp=typedExp, loc=loc} =>
                     (
                      T.POLYty{boundtvars = boundEnv, body = T.FUNMty(map #ty argVarPathInfoList, ranTy)},
                      TPPOLYFNM {btvEnv=boundEnv, 
                                 argVarList=argVarPathInfoList, 
                                 bodyTy=ranTy, 
                                 bodyExp=typedExp, 
                                 loc=loc}
                      )
                 | TPPOLY{btvEnv=boundEnv1, expTyWithoutTAbs=ty1, exp=tpexp1, loc=loc1} =>
                     (
                      case ty of 
                        T.POLYty{boundtvars=boundEnv2, body= ty2} =>
                          (T.POLYty{boundtvars = mergeBoundEnvs (boundEnv, boundEnv2),
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
                        T.POLYty{boundtvars=boundEnv2, body= ty2} =>
                          (T.POLYty{boundtvars = mergeBoundEnvs (boundEnv, boundEnv2),
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
                         T.POLYty{boundtvars = boundEnv, body = ty},
                         TPPOLY{btvEnv=boundEnv, expTyWithoutTAbs=ty, exp=tpexp, loc=loc}
                         )
                )
            end

      fun isStrictValuePat currentContext ptpat =
          case ptpat of
            PT.PTPATWILD _ => true
          | PT.PTPATID (path, _) => 
            (case TIC.lookupLongVar (currentContext, path) of 
               (path, SOME(T.CONID _)) => false 
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
          | PT.PTPATORPAT _ => false
       (*
         This returns
           (localBinds, varBinds, extraBinds, tpexp, ty)
       *)
      fun decompose
          lambdaDepth
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
                       T.BIND,
                       loc
                       )
                    val (ty, tpexp) = typeinfExp lambdaDepth inf currentContext newPtexp
                    val varID = {name = Vars.newTPVarName(), ty = ty}
                    val varPathInfo = makeLocalVarPathInfo varID
                    val patid =
                      if ifGenTerm
                        then (T.VALIDVAR varID)
                      else T.VALIDWILD ty
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
                         T.BIND,
                         loc
                         )
                      val (ty, tpexp) = typeinfExp lambdaDepth inf currentContext newPtexp
                      val varID = {name = x, ty = ty}
                      val varPathInfo = makeLocalVarPathInfo varID
                    in
                      (
                        nil,
                        [(T.VALIDVAR varID, tpexp)],
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
                       T.BIND,
                       loc
                       )
                    val (tupleTy, tpexp) =
                        typeinfExp lambdaDepth inf currentContext newPtexp
                    val newVarId = Vars.newTPVarName ()
                    val varID = {name = newVarId, ty = tupleTy}
                    val varPathInfo = makeLocalVarPathInfo varID
                    val tyList = 
                      case tupleTy of 
                        T.RECORDty tyFields => SEnv.listItems tyFields
                      | T.ERRORty => map (fn x => T.ERRORty) resTuple
                      | _ => raise Control.Bug "decompose"
                    val (_, resBinds) = 
                      foldl
                      (fn ((varId, ty), (i, varIDTpexpList)) => 
                       (
                        i + 1,
                        (
                         T.VALIDVAR {name = varId, ty = ty}, 
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
                     [(T.VALIDVAR varID, tpexp)],
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
                    lambdaDepth
                    (typeinfExp lambdaDepth inf currentContext ptexp, ptexpLoc)
                  val varID = {name = Vars.newTPVarName(), ty = ty}
                  val varPathInfo = makeLocalVarPathInfo varID
                  val patid =
                    if ifGenTerm then T.VALIDVAR varID else T.VALIDWILD ty
                in
                  (nil, [(patid, tpexp)], nil, TPVAR (varPathInfo, loc), ty)
                end
            | PT.PTPATID (varId, loc) =>
                let
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    lambdaDepth
                    (typeinfExp lambdaDepth zero currentContext ptexp, ptexpLoc)
                  val varID  = {name = Absyn.longidToString(varId), ty = ty}
                  val varPathInfo = makeLocalVarPathInfo varID
                in
                  (
                   nil,
                   [(T.VALIDVAR varID, tpexp)],
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
                                lambdaDepth
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
                           T.RECORDty
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
                             lambdaDepth
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
                        typeinfExp lambdaDepth inf currentContext ptexp
                      val (_, tyPat, _ ) = typeinfPat lambdaDepth currentContext ptpat
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
                      val tpBodyVar = T.VALIDVAR tpVarID
                      val currentContext = TIC.bindVarInCurrentContext (lambdaDepth,
                                                                        currentContext, 
                                                                        bodyVar, 
                                                                        T.VARID tpVarPathInfo)
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
                             lambdaDepth
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
                    lambdaDepth
                    (currentContext, true)
                    (ptpat, ptexp)
                in
                  (
                   localBinds,
                   variableBinds,
                   extraBinds@[(T.VALIDVAR {name = id, ty = ty}, tpexp)],
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
                  (currentContext, ifGenTerm)
                  (ptpat, ptexp)
                end
            | _ => raise Control.Bug "non strictvalue pat in decompoes"
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
             decompose lambdaDepth (currentContext, ifGenTerm) (ptpat, ptexp)
         in
           (localBinds, variableBinds, extraBinds)
         end
       )
    end

  and tyinfApplyId
         lambdaDepth
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
              T.VARID
                  {
                   name = vid,
                   strpath = varStrPath,
                   ty = T.ERRORty
                  }
            ) 

(*
      val (tyList, tpexpList) = 
               foldr (fn (ptexp, (tyList, tpexpList)) =>
                      let 
                        val (ty, tpexp) = typeinfExp lambdaDepth inf currentContext ptexp
                        val (ty, tpexp) = TPU.freshInst(ty, tpexp)
                      in (ty::tyList, tpexp::tpexpList)
                      end
                      )
               (nil,nil)
               ptexpList
*)
   in
      case (idState, ptexpList) of 
        (T.CONID (conPathInfo as {name, strpath, ty = ty, tyCon, funtyCon, tag}),  [ptexp2]) =>
        let
          val lambdaDepth = incDepth ()
          val (ty2, tpexp2) = typeinfExp lambdaDepth inf currentContext ptexp2
          val (ty2, tpexp2) = TPU.freshInst(ty2, tpexp2)
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
               ([T.ERRORty], T.ERRORty, nil)
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
            if iszero applyDepth andalso not (expansive newTermBody) then
              let 
                val {boundEnv, ...} = generalizer (ranty, lambdaDepth)
              in
                 if IEnv.isEmpty boundEnv
                  then (ranty, newTermBody)
                else
                   (
                     T.POLYty{boundtvars = boundEnv, body = ranty},
                     TPPOLY{btvEnv=boundEnv, expTyWithoutTAbs=ranty, exp=newTermBody, loc=loc}
                   )
              end
            else (ranty, newTermBody))
          handle U.Unify =>
                 (
                   E.enqueueError
                       (loc, E.TyConMismatch {domTy = domty, argTy = ty2});
                   (T.ERRORty, TPERROR)
                 )
        end
      | (T.CONID (conPathInfo as {name, strpath, ty = ty, tyCon, funtyCon, tag}), _) =>
          raise Control.Bug "CONID in multiple apply"
      | (T.PRIM (primInfo as {ty = ty,...}),  [ptexp2]) =>
        let 
          val (ty2, tpexp2) = typeinfExp lambdaDepth inf currentContext ptexp2
          val (ty2, tpexp2) = TPU.freshInst(ty2, tpexp2)
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
               ([T.ERRORty], T.ERRORty, nil)
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
                   (T.ERRORty, TPERROR)
                 )
        end
      | (T.PRIM (primInfo as {ty = ty,...}), _) =>
          raise Control.Bug "PrimOp in multiple apply"
      | (T.OPRIM {name, ty = ty, instances}, [ptexp2]) =>
        let 
          val (ty2, tpexp2) = typeinfExp lambdaDepth inf currentContext ptexp2
          val (ty2, tpexp2) = TPU.freshInst(ty2, tpexp2)
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
               ([T.ERRORty], T.ERRORty, nil)
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
                   (T.ERRORty, TPERROR)
                 )
        end
      | (T.OPRIM {name, ty = ty, instances}, _) =>
          raise Control.Bug "PrimOp in multiple apply"
      | (T.VARID {name, strpath, ty}, _) => 
        (
	 let
           val (tyList, tpexpList) = 
               foldr (fn (ptexp, (tyList, tpexpList)) =>
                      let 
                        val (ty, tpexp) = typeinfExp lambdaDepth inf currentContext ptexp
                        val (ty, tpexp) = TPU.freshInst(ty, tpexp)
                      in (ty::tyList, tpexp::tpexpList)
                      end
                      )
               (nil,nil)
               ptexpList
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
                    (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
                    )
               val tpexp1 =
                   case instlist of
                     nil => tpexp1
                   | _ => TPTAPP {exp=tpexp1, expTy=instTy, instTyList=instlist, loc=loc}
             in 
               (
		U.unify (ListPair.zip(tyList, domtyList));
		(ranty, TPAPPM({funExp = tpexp1, 
                                funTy = T.FUNMty(domtyList, ranty), 
                                argExpList = tpexpList, 
                                loc = loc}))
		)
               handle U.Unify =>
                      (
                       E.enqueueError
                         (loc, E.TyConListMismatch {domTyList = domtyList, argTyList = tyList});
			 (T.ERRORty, TPERROR)
			 )
             end
	 end
       )
      | (T.RECFUNID ({name, strpath, ty}, arity), _) => 
        (
	 let
           val (tyList, tpexpList) = 
               foldr (fn (ptexp, (tyList, tpexpList)) =>
                      let 
                        val (ty, tpexp) = typeinfExp lambdaDepth inf currentContext ptexp
                        val (ty, tpexp) = TPU.freshInst(ty, tpexp)
                      in (ty::tyList, tpexp::tpexpList)
                      end
                      )
               (nil,nil)
               ptexpList
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
                    (map (fn x => T.ERRORty) tyList, T.ERRORty, nil)
                    )
               val tpexp1 =
                   case instlist of
                     nil => tpexp1
                   | _ => TPTAPP {exp=tpexp1, expTy=instTy, instTyList=instlist, loc=loc}
             in 
               (
		U.unify (ListPair.zip(tyList, domtyList));
		(ranty, TPAPPM({funExp = tpexp1, 
                                funTy = T.FUNMty(domtyList, ranty), 
                                argExpList = tpexpList, 
                                loc = loc}))
		)
               handle U.Unify =>
                      (
                       E.enqueueError
                         (loc, E.TyConListMismatch {domTyList = domtyList, argTyList = tyList});
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
          recKind : recKind, 
          eqKind : eqKind, 
          tyvarName : string option
       }
    When a binding {x:tau} is entered in the typeInferenceContext (currentContext),
    the lambdaDepth of each t in tau is set to the lambdaDepth of the context
    where x occurres.
    When two types are unified, their lambda depth is adjusted by taking the minimal.
   *)
  and typeinfExp lambdaDepth applyDepth (currentContext : TIC.currentContext) ptexp =
      (case ptexp of
         PT.PTCONSTANT (const, loc) => 
           let
             val (ty, staticConst) = typeinfConst const
           in
             (ty, TPCONSTANT (staticConst,ty,loc))
           end
       | PT.PTVAR (longvid, loc) => 
         (case TIC.lookupLongVar(currentContext,longvid) of 
            ((varStrPath,vid), NONE) => 
            (
              E.enqueueError (loc, E.VarNotFound {id = Absyn.longidToString(longvid)});
              (
                T.ERRORty,
                TPVAR
                    (
                      {
                        name = Absyn.getLastIdOfLongid longvid,
		        strpath = varStrPath,
		        ty = T.ERRORty
                      },
                      loc
                    )
              )
            )
          | ((varStrPath,vid), SOME (T.VARID ({name,strpath,ty}))) => 
	    (ty,
	     TPVAR ({name = name, strpath = varStrPath,ty = ty}, loc)
	     )
          | ((varStrPath,vid), SOME (T.RECFUNID ({name,strpath,ty},arity))) => 
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
           val (ty1, tpexp) = typeinfExp lambdaDepth inf currentContext ptexp
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
                   (T.ERRORty, TPERROR)
                 )
         end
       | PT.PTAPPM(PT.PTRECORD_SELECTOR(label, loc1), [ptexp], loc2) =>
         typeinfExp lambdaDepth applyDepth currentContext (PT.PTSELECT(label, ptexp, loc2))
       | PT.PTAPPM (ptexp, ptexpList, loc) =>
         if isVar ptexp
         then
           let 
             val (path, pathLoc, rawTyList) = stripRawty ptexp
           in
             tyinfApplyId
                 lambdaDepth
                 applyDepth
                 currentContext
                 (loc, path, pathLoc, rawTyList, ptexpList)
           end
         else
           let 
             val (ty1, tpexp) = typeinfExp lambdaDepth (inc applyDepth) currentContext ptexp
             val (tyList, tpexpList) = 
               foldr (fn (ptexp, (tyList, tpexpList)) =>
                      let val (ty, tpexp) = typeinfExp lambdaDepth inf currentContext ptexp
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
               typeinfPtdeclList lambdaDepth false currentContext ptdeclList 
           val newCurrentContext =
               TIC.extendCurrentContextWithContext (currentContext, context1)
           val (tyList, tpexpList) = 
               foldr
                   (fn (ptexp, (tyList, tpexpList)) =>
                       let 
                         val (ty, tpexp) = 
                             typeinfExp lambdaDepth applyDepth newCurrentContext ptexp
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
                       typeinfExp lambdaDepth applyDepth currentContext ptexp
                 in 
                   if expansive tpexp then
                     let
                       val tpvarPathInfo = 
                         {name = Vars.newTPVarName (), strpath = T.NilPath, ty = ty}
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
           val resultTy = T.RECORDty tySmap
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
               TPU.freshInst (typeinfExp lambdaDepth applyDepth currentContext ptexp)
           val (modifyTpexp, tySmap) =
               foldl
	       (fn ((label, ptexp), (modifyTpexp, tySmap)) =>
                    let
                      val (ty, tpexp) =
                          TPU.freshInst
                              (typeinfExp lambdaDepth applyDepth currentContext ptexp)
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
               T.newtyRaw {
                           lambdaDepth = lambdaDepth,
                           recKind = T.REC tySmap, 
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
                         typeinfExp lambdaDepth applyDepth currentContext ptexp
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
           val (ty1, tpexp) = typeinfExp lambdaDepth applyDepth currentContext ptexp
           val resultTy = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
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
               TPU.freshInst (typeinfExp lambdaDepth inf currentContext ptexp)
           val (ruleTy, tppatTpexpList) =
               monoTypeinfMatch lambdaDepth [PDT.exnty] currentContext (map (fn (pat,exp) => ([pat], exp)) ptpatPtexpList)
           val (domTy, ranTy) = 
               (* here we try maching the type of rules with exn -> ty1 
                * Also, the result type must be mono.
                *)
               case TU.derefTy ruleTy of
                 T.FUNMty([domTy], ranTy)=>(domTy, ranTy)
               | T.ERRORty => (T.ERRORty, T.ERRORty)
               | _ => raise Control.Bug "Case Type Inference"
           val newVarPathInfo = 
	       {name = Vars.newTPVarName (), strpath = T.NilPath, ty = domTy}
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
                           caseKind=T.HANDLE,
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
                  typeinfExp lambdaDepth applyDepth currentContext newPtexp
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
                               T.MATCH,
                               loc
                               ),
                              loc)
                in 
                  typeinfExp lambdaDepth applyDepth currentContext newPtexp
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
                               T.MATCH,
                               loc
                               ),
                              loc)
                in 
                  typeinfExp lambdaDepth applyDepth currentContext newPtexp
                end
              )
       | PT.PTFNM1(tvarNameSet, stringTyListOptionList, ptexp, loc) =>
         let 
           val lambdaDepth = incDepth ()
           val (newCurrentContext, _) =
               TIC.addUtvarIfNotthere(lambdaDepth, 
                                      currentContext, 
                                      tvarNameSet)
           val nameDomTyVarPathInfoList = 
             map (fn (name, tyListOption) => 
                  let 
                    val domTy = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
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
                    (name, domTy, {name = name, strpath = T.NilPath, ty = domTy})
                  end
                  )
             stringTyListOptionList
           val newCurrentContext =
               foldl 
               (fn ((name, domTy, varPathInfo),
                    newCurrentContext)
                =>
                TIC.bindVarInCurrentContext
                (lambdaDepth, newCurrentContext, name, T.VARID varPathInfo)
                )
               newCurrentContext
               nameDomTyVarPathInfoList
           val (ranTy, typedExp) =
               typeinfExp lambdaDepth (decl applyDepth) newCurrentContext ptexp
           val ty = T.FUNMty(map #2 nameDomTyVarPathInfoList, ranTy)
           val (ty, tpexp) = 
           if iszero applyDepth
           then
             let
               val {boundEnv, ...} = generalizer (ty, lambdaDepth)
             in
               if IEnv.isEmpty boundEnv
               then (ty, TPFNM {argVarList = map #3 nameDomTyVarPathInfoList, bodyTy = ranTy, 
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
                  val (ty, tpexp) = TPU.freshInst (typeinfExp lambdaDepth inf currentContext ptexp)


                in
                  (ty::tyList, tpexp::tpexpList)
                end
                )
               (nil,nil)
               ptexpList
           val (ruleTy, tpMatchM) =
               typeinfMatch lambdaDepth applyDepth tyList currentContext matchM
           val ranTy = 
               case TU.derefTy ruleTy of 
                 T.FUNMty(_, ranTy) => ranTy
               | T.ERRORty => T.ERRORty
               | _ => raise Control.Bug "Case Type Inference"
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
           val newName = Vars.newTPVarName()
         in
           typeinfExp
               lambdaDepth
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
           val (ty1, tpexp) = typeinfExp lambdaDepth applyDepth currentContext ptexp
           val ty1 = TU.derefTy ty1
         in
           case ty1 of
             T.RECORDty tyFields =>
             (* here we do not U.unify, since U.unify is restricted to monotype
              *)
             (case SEnv.find(tyFields, label) of
                SOME elemTy => (elemTy, TPSELECT{label=label, exp=tpexp, expTy=ty1, loc=loc})
              | _ => 
                (
                  E.enqueueError (loc, E.FieldNotInRecord {label = label});
                  (T.ERRORty, TPERROR)
                ))
           | T.TYVARty (ref (T.TVAR tvkind)) =>
             let
               val elemTy = T.newtyWithLambdaDepth(#lambdaDepth tvkind, T.univKind)
               val recordTy =
                   T.newtyRaw
                       {
                         lambdaDepth = lambdaDepth,
                         recKind = T.REC (SEnv.singleton(label, elemTy)),
                         eqKind = T.NONEQ,
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
                        (T.ERRORty, TPERROR)
                      )
             end
           | _ => (* this case may be empty *)
             let
               val elemTy = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
               val recordTy =
                   T.newtyRaw
                       {
                         lambdaDepth = lambdaDepth,
                         recKind = T.REC (SEnv.singleton(label, elemTy)),
                         eqKind = T.NONEQ,
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
                        (T.ERRORty, TPERROR)
                      )
             end
         end
       | PT.PTLIST (ptexpList, loc) =>
         let
           val lambdaDepth = incDepth ()
           val elemTy = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
           val tpexpList =
               foldr 
               (fn (ptexp, tpexpList) =>
                let
                  val (ty, tpexp) =
                    typeinfExp lambdaDepth applyDepth currentContext ptexp
                  val (ty, tpexp) = TPU.freshInst(ty, tpexp)
                  val _ = U.unify [(elemTy, ty)]
                    handle U.Unify =>
                      E.enqueueError (loc, E.InconsistentListElementType {prevTy=elemTy, nextTy=ty})
                in 
                  tpexp :: tpexpList
                end)
               nil
               ptexpList
           val resultTy = T.CONty{tyCon = PDT.listTyCon, args = [elemTy]}
           val newTermBody = TPLIST {expList=tpexpList, listTy=resultTy, loc=loc}
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
                     TPPOLY{btvEnv=boundEnv, expTyWithoutTAbs=resultTy, exp=newTermBody, loc=loc}
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
                             typeinfExp lambdaDepth applyDepth currentContext ptexp
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
           val (ty1, tpexp) = typeinfExp lambdaDepth inf currentContext ptexp
           val ty = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
         in
           (ty, TPCAST(tpexp, ty, loc))
         end
       | PT.PTFFIIMPORT (ptexp, ffirawty as A.TYFFI _, loc) =>
         let
           val (expTy, tpExp) = typeinfExp lambdaDepth inf currentContext ptexp
           val (expTy, tpExp) = TPU.freshInst (expTy, tpExp)

           val var = {name = Vars.newTPVarName(), strpath = T.NilPath, ty = expTy}
           val varExp = TPVAR (var, loc)
           val (stubTy, stubExp) =
               stubImport currentContext false (ffirawty, expTy, varExp, loc)

           val (stubTy, stubExp) =
               generalizeStub (stubTy, stubExp, lambdaDepth, loc)
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
         raise Control.Bug "PTFFIIMPORT: not a function type"
       | PT.PTFFIEXPORT (ptexp, ffirawty as A.TYFFI _, loc) =>
         let
           val (expTy, tpExp) = typeinfExp lambdaDepth inf currentContext ptexp

           val var = {name = Vars.newTPVarName(), strpath = T.NilPath, ty = expTy}
           val varExp = TPVAR (var, loc)
           val (stubTy, stubExp) =
               stubExport currentContext false (ffirawty, expTy, varExp, loc)
           (* stubTy never include any free type variables. No need to generalize here. *)
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
         raise Control.Bug "PTFFIEXPORT: not a function type"
       | PT.PTFFIAPPLY (convention, ptfunExp, ptargs, rawRetTy, loc) =>
         let
           val (funTy, funExp) =
               typeinfExp lambdaDepth applyDepth currentContext ptfunExp
           val (funTy, funExp) =
               TPU.freshInst (funTy, funExp)

           val funTy = getRealTy funTy
           val _ = U.unify [(PDT.ptrty, funTy)]
                   handle U.Unify =>
                          E.enqueueError (loc, E.FFIStubMismatch (PDT.ptrty, funTy))

           fun typeinfFFIArg arg =
               case arg of
                 PT.PTFFIARG (ptexp, ffirawty) =>
                 let
                   val (argTy, argExp) = typeinfExp lambdaDepth applyDepth currentContext ptexp
                   val (argTy, argExp) = TPU.freshInst (argTy, argExp)
                   val var = {name = Vars.newTPVarName(), strpath = T.NilPath, ty = argTy}
                   val varExp = TPVAR (var, loc)
                   val (stubTy, stubExp) =
                       stubExport currentContext false (ffirawty, argTy, varExp, loc)
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
               | PT.PTFFIARGSIZEOF (rawty, factorExpOpt) =>
                 let
                   val ty = evalRawty currentContext rawty
                   val tyvars = userTyvars ty
                 in
                   case factorExpOpt of
                     NONE =>
                     (PDT.intty, TPSIZEOF (ty, loc), tyvars)
                   | SOME ptfactorExp =>
                     let
                       val (factorTy, factorExp) =
                           typeinfExp lambdaDepth applyDepth currentContext ptfactorExp
                       val (factorTy, factorExp) =
                           TPU.freshInst (factorTy, factorExp)
                       val _ = U.unify [(PDT.intty, factorTy)]
                               handle U.Unify =>
                                      E.enqueueError (loc, E.FFIStubMismatch (PDT.intty, factorTy))
                       val (ty, exp) = makeMulInt (TPSIZEOF (ty, loc), factorExp, loc)
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

           val funVar = {name = Vars.newTPVarName(), strpath = T.NilPath, ty = funTy}
           val retTy = T.newty {recKind = T.UNIV, eqKind = T.NONEQ, tyvarName = NONE}

           val retVar =
               {name = Vars.newTPVarName(), strpath = T.NilPath, ty = retTy}
           val retVarExp = TPVAR (retVar, loc)
           val (stubTy, stubExp) =
               stubImportAllowingUnit currentContext false (rawRetTy, retTy, retVarExp, loc)

           val _ = checkSafeStubType (T.FUNMty (argTys, retTy), loc)

           (* For safety, user type variables appearing in _ffiapply must not be vacuous. *)
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
                 (retVar, TPFOREIGNAPPLY
                          {
                            loc = loc,
                            funExp = TPVAR (funVar, loc),
                            funTy = T.FUNMty (argTys, retTy),
                            instTyList = nil,
                            argExpList = argExps,
                            argTyList = argTys,
                            convention = convention
                          })],
              bodyExp = stubExp
            })
         end)

  (**
   * infer a possibly polytype for a match
   *)
  and typeinfMatch lambdaDepth applyDepth argtyList currentContext [rule] = 
      let 
        val (ty1, typedRule) = typeinfRule lambdaDepth applyDepth argtyList currentContext rule
      in (ty1, [typedRule]) end
    | typeinfMatch lambdaDepth _ argtyList currentContext (rule :: rules) =
      let 
        val (tyRule, typedRule) = monoTypeinfRule lambdaDepth argtyList currentContext rule
        val (tyRules, typedRules) = monoTypeinfMatch lambdaDepth argtyList currentContext rules
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
    | typeinfMatch _ _ argtyList currentContext nil = 
      raise Control.Bug "typeinfMatch, empty rule"

  (**
   * infer a mono type for a match
   * @params argTy currentContext match
   *)
  and monoTypeinfMatch lambdaDepth argtyList currentContext [rule] =
      let val (ty1, typedRule) = monoTypeinfRule lambdaDepth argtyList currentContext rule
      in (ty1, [typedRule]) end
    | monoTypeinfMatch lambdaDepth argtyList currentContext (rule :: rules) =
      let
        val (ruleTy, typedRule) = monoTypeinfRule lambdaDepth argtyList currentContext rule
        val (rulesTy, typedRules) = monoTypeinfMatch lambdaDepth argtyList currentContext rules
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
    | monoTypeinfMatch lambdaDepth argty currentContext nil =
      raise Control.Bug "monoTypeinfMatch, empty rule"


  (**
   * infer a possibly polytype for a rule
   * @params applyDepth argTy currentContext rule
   *)
  and typeinfRule lambdaDepth applyDepth argtyList currentContext (patList,exp) = 
      let 
        val (varEnv1, patTyList, typedPatList) = typeinfPatList lambdaDepth currentContext patList
        val (bodyTy, typedExp) = 
            typeinfExp
            lambdaDepth
            applyDepth
            (TIC.extendCurrentContextWithVarEnv(currentContext, varEnv1))
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
                     (ruleLoc, E.TyConListMismatch {argTyList = argtyList, domTyList = patTyList});
                 (T.ERRORty, (map (fn x => TPPATWILD(T.ERRORty, ruleLoc)) patList, TPERROR))
               end
      end

  (**
   * infer a monotype for a rule
   * @params argTy currentContext rule
   *)
  and monoTypeinfRule lambdaDepth argtyList currentContext (patList,exp) = 
      let 
        val (varEnv1, patTyList, typedPatList) = typeinfPatList lambdaDepth currentContext patList
        val (bodyTy, typedExp) = 
            TPU.freshInst
                (typeinfExp 
                 lambdaDepth
                 inf (TIC.extendCurrentContextWithVarEnv(currentContext, varEnv1)) exp)
      in
        (
          U.unify (ListPair.zip(patTyList, argtyList));
          (T.FUNMty(patTyList, bodyTy), (typedPatList, typedExp))
        )
        handle U.Unify =>
               let val ruleLoc = getRuleLocM [(patList, exp)]
               in
                 E.enqueueError
                     (ruleLoc, E.TyConListMismatch {argTyList = argtyList, domTyList = patTyList});
                 (T.ERRORty, ([TPPATWILD(T.ERRORty, ruleLoc)], TPERROR))
               end
      end

  and typeinfPatList lambdaDepth currentContext ptpatList =
        foldr
        (fn (ptpat, (varEnv1, tyPatList, tppatList)) =>
         let
           val (varEnv2, ty, tppat) = typeinfPat lambdaDepth currentContext ptpat
         in
           (
            SEnv.unionWith
              (fn (varId as (T.VARID{name, ...}), _) =>
               (E.enqueueError (PT.getLocPat ptpat, E.DuplicatePatternVar{vars = [name]});
                varId)
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
   * @params currentContext pattern
   * @return a varEnv of the pattern, pattern type, and a typed pattern
   *)
  and typeinfPat lambdaDepth currentContext ptpat =
      (case ptpat of
         PT.PTPATWILD loc => 
         let val ty1 = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
         in (T.emptyVarEnv, ty1, TPPATWILD (ty1, loc)) end
       | PT.PTPATID ([varId], loc) =>
         let 
	   val ((varStrPath,vid), idState) = TIC.lookupLongVar (currentContext, [varId])
         in
           (case idState of 
              SOME(T.CONID(con as {name, strpath, funtyCon, ty, tyCon, tag})) =>
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
                        (T.POLYty{boundtvars, body, ...}) =>
                        let val subst = TU.freshSubst boundtvars
                        in (TU.substBTvar subst body, IEnv.listItems subst) end
                      | _ => (ty, nil)
                in
                  (
                    T.emptyVarEnv,
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
                  T.emptyVarEnv,
                  T.ERRORty,
                  TPPATWILD (T.ERRORty, loc)
                  )
                 )
            | _ => 
              let
                val ty1 = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
                val varPathInfo = {name = varId, strpath = T.NilPath, ty = ty1}
                val varEnv1 =
                    SEnv.insert (T.emptyVarEnv, varId, T.VARID varPathInfo)
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
              SOME(T.CONID(con as {name,strpath,funtyCon, ty, tyCon, tag})) =>
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
                        (T.POLYty{boundtvars, body, ...}) =>
                        let val subst = TU.freshSubst boundtvars
                        in (TU.substBTvar subst body, IEnv.listItems subst) end
                      | _ => (ty, nil)
                in
                  (
                    T.emptyVarEnv,
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
                  T.emptyVarEnv,
                  T.ERRORty,
                  TPPATWILD (T.ERRORty, loc)
                  )
                 )
	    | SOME _ => 
              (
               E.enqueueError(loc, E.NonConstructorPathInPat longId);
               (T.emptyVarEnv, T.ERRORty, TPPATWILD (T.ERRORty, loc))
               )                
            | NONE => 
              (
                E.enqueueError(loc, E.ConstructorPathNotFound longId);
                (T.emptyVarEnv, T.ERRORty, TPPATWILD (T.ERRORty, loc))
              )                
            )
         end
       | PT.PTPATCONSTANT (const, loc) => 
         let
           val (ty, staticConst) = typeinfConst const
         in
           (T.emptyVarEnv, ty, TPPATCONSTANT(staticConst, ty, loc))
         end
       | PT.PTPATCONSTRUCT (ptpat1, ptpat2, loc) =>
         (case ptpat1 of
            PT.PTPATID(patId, _) =>
            (case TIC.lookupLongVar(currentContext, patId) of 
              ((patStrPath,vid), SOME (T.CONID (con as {name, strpath,funtyCon, ty, tyCon, tag})))
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
                           typeinfPat lambdaDepth currentContext ptpat2
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
                             typeinfPat lambdaDepth currentContext ptpat
                       in
                         (
                           SEnv.unionWith
                           (fn (varId as (T.VARID{name, ...}), _) =>
                            (E.enqueueError (loc, E.DuplicatePatternVar{vars = [name]});
                             varId)
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
                 T.newtyRaw
                     {
                      lambdaDepth = lambdaDepth,
                      recKind = T.REC tyFields, 
                      eqKind = T.NONEQ, 
                      tyvarName = NONE
                      }
               else T.RECORDty tyFields
         in
           (varEnv1, ty1, TPPATRECORD{fields=tppatFields, recordTy=ty1, loc=loc})
         end
       | PT.PTPATLAYERED (string, optTy, ptpat, loc) =>
         (case TIC.lookupVar(currentContext, string) of 
           SOME(T.CONID _) =>
            (
              E.enqueueError (loc, E.NonIDInLayered {id = string});
              (SEnv.empty, T.ERRORty, TPPATWILD (T.ERRORty, loc))
            )
          | _ => 
            let
              val (varEnv1, ty1, tpat) = typeinfPat lambdaDepth currentContext ptpat
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
              val varPathInfo = {name = string, strpath = T.NilPath, ty = ty1}
            in 
              (
                SEnv.insert (varEnv1, string, T.VARID varPathInfo),
                ty1,
                TPPATLAYERED{varPat=TPPATVAR (varPathInfo, loc), asPat=tpat, loc=loc}
              )
            end)
       | PT.PTPATTYPED (ptpat, rawTy, loc)  => 
         let
           val (varEnv1, ty1, tppat) = typeinfPat lambdaDepth currentContext ptpat
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
         end
       | PT.PTPATORPAT (ptpat1, ptpat2, loc)  => 
          let
            val set1 = freeVarsInPat currentContext ptpat1
            val set2 = freeVarsInPat currentContext ptpat2
            val diff1 = SSet.difference(set1, set2)
            val diff2 = SSet.difference(set2, set1)
            val diffs = SSet.union(diff1,diff2)
         in
            if SSet.isEmpty diffs 
              then
              let
                val (varEnv1, ty1, tppat1) = typeinfPat lambdaDepth currentContext ptpat1
                val (varEnv2, ty2, tppat2) = typeinfPat lambdaDepth currentContext ptpat2
                val _ =  
                  SEnv.appi 
                  (fn (varName, T.VARID {ty,...})
                   => (case SEnv.find(varEnv2, varName) of
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
                               {var = varName, tys = [ty1, ty2]}
                               )
                              )
                       | _ => ())
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
                E.DIfferentOrPatternVars {vars = SSet.listItems diffs}
                );
               (SEnv.empty, T.ERRORty, TPPATWILD (T.ERRORty, loc))
               )
            end)


  (**
   * infer a type for ptdecl
   * @params currentContext ptdeclList
   * @return  a new currentContext and tpdeclList
   *)
  and typeinfPtdeclList lambdaDepth isTop (currentContext:TIC.currentContext) nil = 
        (emptyContext, nil)
    | typeinfPtdeclList lambdaDepth isTop currentContext (PT.PTEMPTY :: ptdeclList) = 
        typeinfPtdeclList lambdaDepth isTop currentContext ptdeclList
    | typeinfPtdeclList lambdaDepth isTop currentContext (ptdecl :: ptdeclList) =  
        let 
          val (newContext1, tpdeclList1) =
              typeinfPtdecl lambdaDepth isTop currentContext ptdecl
          val (newContext2, tpdeclList) = 
               typeinfPtdeclList lambdaDepth isTop
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
  and typeinfConbind lambdaDepth
         (currentContext:TIC.currentContext) 
         (tyCon, (tyvars, tyConName, constructorList)) =
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
                                 T.newUtvar(lambdaDepth, if isEq then T.EQ else T.NONEQ, tid)
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
                  val resultTy = T.CONty {tyCon = tyCon, args = map T.TYVARty argTyvarStateRefs}
                  val (funtyCon, tyBody) =  
                    case argTyOption of
                        SOME ty => 
                        let
                          val argTy = evalRawty newCurrentContext ty
                        in
                          (true, T.FUNMty([argTy], resultTy))
                        end
                      | NONE => (false, resultTy)
                  val (_, btvs) =
                    (
                            foldl
                            (
                             fn (r as ref(T.TVAR (k as {id, ...})), (next, btvs)) =>
                                let
                                  val btvid = T.nextBTid()
                                in
                                 (
                                  r := T.SUBSTITUTED (T.BOUNDVARty btvid);
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
                    T.CONID
                    {
                     name = cid,
                     strpath = #strLevel currentContext,
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
            constructorList
      in 
        (tyCon, conbinds)
      end

  and makeTyFun lambdaDepth (currentContext : TIC.currentContext) (tyvarList, string, rawty) =
      let
          val (_, tvarSEnv, tvarIEnv) = 
              foldl
                  (fn ({name=tyvarName,ifeq}, (n, tvarSEnv, tvarIEnv)) =>
                      let 
                          val newTy =
			      case T.newtyRaw {
                                               lambdaDepth = lambdaDepth,
                                               recKind = T.UNIV, 
                                               eqKind = T.NONEQ (*if bool then EQ else T.NONEQ*),
                                               (* 
                                                * Ignore eq attribute in tyfun. 
                                                * This should be checked.
                                                * NONEQ 
                                                *) 
                                               tyvarName = NONE
                                               } of 
				T.TYVARty newTy => newTy
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
	  val eqKind = if TU.admitEqTy originTy then T.EQ else T.NONEQ
          val newTyCon = TU.newTyCon {name = string, 
                                      abstract = false,
                                      strpath = #strLevel currentContext,
                                      tyvars = map (fn {name,ifeq} => ifeq) tyvarList,
                                      eqKind = ref eqKind, 
                                      boxedKind = ref (TU.boxedKindOfType originTy),
                                      datacon = ref SEnv.empty}
          val aliasTy = T.CONty {tyCon = newTyCon, args = map T.TYVARty (IEnv.listItems tvarIEnv)}
          val ty = T.ALIASty(aliasTy,originTy)
          val btvEnv = 
              IEnv.foldli
                  (fn (i, tvar as ref(T.TVAR (k as {id, ...})), btvEnv) => 
                      let 
                          val btvid = T.nextBTid()
                      in
                          (
                           tvar := T.SUBSTITUTED (T.BOUNDVARty btvid);
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
           TC.bindTyConInEmptyContext (string,T.TYFUN tyFun),
           tyFun
           )
      end
  and typeinfDatatypeDecl lambdaDepth currentContext datbinds loc =	
    let 
      val (tyConEnv, tyCons, varEnv) = typeinfDatabinds lambdaDepth currentContext datbinds loc
      val newContext =
        TC.extendContextWithVarEnv
        (
         TC.injectTyConEnvToContext tyConEnv,
         varEnv
         )
    in
      (newContext, tyCons)
    end
  and typeinfDatabinds lambdaDepth currentContext datbinds loc =
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
                                   eqKind = ref T.EQ,
				   boxedKind = ref T.ATOMty,
                                   datacon = ref SEnv.empty
                                 }
                       in
                         (
                           tyCon :: tyCons,
                           SEnv.insert(tyConEnv1, tid, T.TYCON tyCon)
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
                (typeinfConbind lambdaDepth (TIC.extendCurrentContextWithTyConEnv (currentContext, tyConEnv1))) 
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
                        T.FUNMty _ => ID.Set.empty
                      | T.CONty {tyCon = {eqKind, id, ...}, args} =>
                        foldr
                            (fn (ty, depset) => ID.Set.union(dep ty, depset))
                            (if ID.Set.member(tyConSet, id)
                             then ID.Set.singleton id
                             else ID.Set.empty)
                            args
                      | T.TYVARty tid => ID.Set.empty
                      | T.BOUNDVARty _ => ID.Set.empty
                      | T.POLYty _ => raise Control.Bug "polyty in combind"
                      | T.RECORDty fl => 
                        SEnv.foldr
                            (fn (ty, depsep) => ID.Set.union (dep ty, depsep))
                            ID.Set.empty
                            fl
                      | T.ERRORty => ID.Set.empty
                      | T.ALIASty (_, ty) => dep ty
		      | T.ABSSPECty(specTy,_) => dep specTy
                      | T.SPECty ty => dep ty
                      | _ => raise Control.Bug "illegal type in combind")
               in 
                 if funtyCon
                 then
                   case ty of
                     T.FUNMty([ty1], ty2) => dep ty1
                   | T.POLYty{body, ...} =>
                     (case body of
                        T.FUNMty([ty1], ty2) => dep ty1
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
                                  if ID.eq(i,j)
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
                                     if ID.eq(j, i)
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
                              (fn (T.CONID conInfo, s) =>
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
                        T.FUNMty _ => false
                      | T.CONty {tyCon = {eqKind, id, ...}, args} =>
                        if (foldr (fn (x,b) => eqCon x andalso b) true args)
                        then 
                          (if ID.Set.member(tyConSet, id)
                           then true
                           else (case !eqKind of T.EQ => true | _ => false))
                        else false
                      | T.TYVARty (ref(T.SUBSTITUTED ty)) => eqCon ty
                      | T.TYVARty (ref(T.TVAR k)) =>
                        (case k of
                           {eqKind = T.EQ, ...} => true
                         | {eqKind = T.NONEQ, ...} => false)
                      | T.BOUNDVARty _ => true
                      | T.POLYty _ => raise Control.Bug "polyty in combind"
                      | T.RECORDty fl => 
                        SEnv.foldr (fn (ty, b) => (eqCon ty) andalso b) true fl
                      | T.ALIASty (_, ty) => eqCon ty
                      | T.ERRORty => true
		      | T.ABSSPECty(specTy,_) => eqCon specTy
                      | T.SPECty ty => eqCon ty
                      | _ => raise Control.Bug "illegal type in combind")
               in
                 if funtyCon
                 then
                   case ty of
                     T.FUNMty([ty1], ty2) => eqCon ty1
                   | T.POLYty{body, ...} =>
                     (case body of
                        T.FUNMty([ty1], ty2) => eqCon ty1
                      | _ => raise Control.Bug "depends")
                   | T.ERRORty => true
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
                                 (fn (T.CONID conInfo, b) =>
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
                      (if valOf(ID.Map.find(eqFlags, id)) then T.EQ else T.NONEQ)
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

  and typeinfExnbind lambdaDepth (currentContext:TIC.currentContext) exbind =
      case exbind of
        PT.PTEXBINDDEF(_, name, optRawty, loc) =>
        let 
          val optty =
              case optRawty of
                SOME rawty =>
                SOME(evalRawty currentContext rawty)
              | NONE => NONE
          val conPathInfo as { name,funtyCon,ty,tyCon,tag,...}
	    = PDT.makeExnConPath name (#strLevel currentContext) optty
          val idState = T.CONID conPathInfo
	  val termConPathInfo = 
	      { name = name, 
		strpath = T.NilPath,
		funtyCon = funtyCon, 
		ty = ty, 
		tyCon = tyCon,
		tag = tag}
        in
          (TC.bindVarInEmptyContext(lambdaDepth, name, idState), [TPEXNBINDDEF(termConPathInfo)])
        end
      | PT.PTEXBINDREP (_, string1, _, longid, loc) => 
        (case TIC.lookupLongVar(currentContext, longid)  of
           ((exnStrPath,exnid), SOME (idState as (T.CONID (conPathInfo as {tyCon = {id,...}, ...})))) => 
           if ID.eq(id, PDT.exnTyConid)
           then
	     let
	       val newIdState = T.CONID 
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
		TC.bindVarInEmptyContext(lambdaDepth, string1, newIdState),
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
  and typeinfPtdecl lambdaDepth isTop (currentContext:TIC.currentContext) ptdecl =
    let
      val lambdaDepth = lambdaDepth
    in
      (case ptdecl of
         PT.PTVAL (tvarNameSet1, tvarNameSet2, ptpatPtexpList, loc) => 
         let 
           val lambdaDepth = incDepth ()
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
             
           (* if the above error check fails then we change the pattern to wild pattern and continue compiling
            *)
           val ptpatPtexpList =
             if E.isError() then  
               map (fn (ptPat,ptExp) => (PT.PTPATWILD (PT.getLocPat ptPat),ptExp)) ptpatPtexpList
             else ptpatPtexpList

           val (localBinds, patternVarBinds, extraBinds) = 
               foldr
               (fn ((ptpat, ptexp), (localBinds, patternVarBinds, extraBinds)) =>
                   let
                     val (newCurrentContext, addedUtvars1) =
                       TIC.addUtvarOverride(lambdaDepth, currentContext, tvarNameSet1)
                     val (newCurrentContext, addedUtvars2) =
                       TIC.addUtvarIfNotthere(lambdaDepth, newCurrentContext, tvarNameSet2)
                     val (localBinds1, patternVarBinds1, extraBinds1) = 
                         (decomposeValbind
                             lambdaDepth
                             (
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
                       (fn ((T.VALIDVAR {name, ty}, _), tyvarSet) =>
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
                       (fn (tyname, (ifeq, ref (T.SUBSTITUTED (T.BOUNDVARty _)))) =>()
                         | (tyname, (ifeq, ref (T.SUBSTITUTED ty))) =>
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
           fun bindVarInVarEnv (lambdaDepth, varEnv, string, idstate) = 
               (TU.adjustDepthInIdstate lambdaDepth idstate;
                SEnv.insert(varEnv, string, idstate))
           val newVarEnv = 
               foldl 
                   (fn ((T.VALIDVAR {name, ty}, _), newVarEnv) =>
                       let
                         val path = #strLevel currentContext
                         val varPathInfo =
                             {name = name, strpath = path, ty = ty}
                       in
		         bindVarInVarEnv(lambdaDepth, newVarEnv, name, T.VARID varPathInfo)
                       end
                     | (_, newVarEnv) => newVarEnv)
                   T.emptyVarEnv
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
           val lambdaDepth = incDepth ()
           val (newCurrentContext, addedUtvars1) =
               TIC.addUtvarOverride(lambdaDepth, currentContext, tvarNameSet1)
           val (newCurrentContext, addedUtvars2) =
               TIC.addUtvarIfNotthere(lambdaDepth, newCurrentContext, tvarNameSet2)
           fun getFunIdFromPat (PT.PTPATID ([id], _)) = id
             | getFunIdFromPat (PT.PTPATTYPED(pat, _,_)) = getFunIdFromPat pat
             | getFunIdFromPat _ = raise Control.Bug "non id pat in fundecl"
           fun arityAndArgTyListOfMatch match =
             case match of
               nil => raise Control.Bug "empty match in fundecl"
             | (patList,exp)::_ => (List.length patList,
                                    map (fn _ => T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
                                         ) patList)
           val (newCurrentContext, funTyList) =
             foldr
             (fn ((funPat, ptmatch), (newCurrentContext, funTyList)) =>
              let
                val funId = getFunIdFromPat funPat
                val (arity, argTyList) = arityAndArgTyListOfMatch ptmatch
                val funTy = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
(*
                val strpath = T.NilPath
*)
                val strpath = #strLevel currentContext
                val funVarPathInfo = {name = funId, strpath = strpath, ty = funTy}
              in
                (
                  TIC.bindVarInCurrentContext
                  (lambdaDepth,
                   newCurrentContext, 
                   funId, 
                   T.RECFUNID (funVarPathInfo, length argTyList)
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
                val strpath = T.NilPath
                val funVarPathInfo = {name = funId, strpath = strpath, ty = funTy}
                val (tpmatchTy, tpmatch) =
                  monoTypeinfMatch lambdaDepth argTyList newCurrentContext ptmatch
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
                      id = funId,
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
                           | _ => raise Control.Bug "non fun type in fundecl",
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
                        (fn ({funVar={name, strpath, ty},...}, tyFields) =>
                            SEnv.insert(tyFields, name, ty))
                        SEnv.empty
                        funBindList)
           val {boundEnv, ...} =
               generalizer (TypesOfAllElements, lambdaDepth)
           val _ =
             SEnv.appi
               (fn (tyname, (ifeq, ref (T.SUBSTITUTED (T.BOUNDVARty _)))) =>()
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
                 lambdaDepth,
                 newContext, 
                 name,
                 if isTop then
                   T.VARID {
                          name = name, 
                          ty = ty, 
                          strpath = #strLevel currentContext (* !!!!!!!! *)
                          }
                 else
                   T.RECFUNID (
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
                 lambdaDepth,
                 newContext, 
                 name, 
                 if isTop then
                   T.VARID {
                          name = name,
                          ty = T.POLYty{boundtvars=boundEnv, body = ty},
                          strpath = #strLevel currentContext (* !!!!!!!! *)
                          }
                 else 
                   T.RECFUNID
                   (
                    {
                     name = name,
                     ty = T.POLYty{boundtvars=boundEnv, body = ty},
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
         let
           val lambdaDepth = lambdaDepth
           val ptdecls = 
             case ptpatPtpatListPtexp of
               (funPat as (PT.PTPATID ([funId], patLoc)), ruleList as (([pat], exp)::_)) =>
                 [(funPat, PT.PTFNM(SEnv.empty, ruleList, loc))]
               | (funPat as (PT.PTPATID ([funId], patLoc)), [(patList as (pat::_), exp)]) =>
                 (let
                   val (_, (firstLoc, patFields, lastLoc)) = 
                     foldl (fn (pat, (n, (firstLoc, patFields, lastLoc))) => 
                                (n+1, (firstLoc, (Int.toString n,pat)::patFields, PT.getLocPat pat)))
                     (1,(PT.getLocPat pat, nil, PT.getLocPat pat))
                     patList
                   val _ = freeVarsInPat currentContext (PT.PTPATRECORD (false, 
                                                                         patFields,
                                                                         Loc.mergeLocs(firstLoc, lastLoc)))
                  in
                    [(funPat,
                      foldr (fn (pat, funBody) => PT.PTFNM(SEnv.empty, [([pat], funBody)], loc)) exp patList)
                     ]
                  end
                )
              | _ => transFunDecl loc ptpatPtpatListPtexp
         in 
           typeinfPtdecl lambdaDepth isTop
           currentContext
           (PT.PTVAL
            (tvarNameSet1, 
             tvarNameSet2, 
             ptdecls, 
             loc)
            )
         end
       | PT.PTVALREC (tvarNameSet1, tvarNameSet2, ptpatPtexpList, loc) => 
         let
           val lambdaDepth = incDepth ()
           val (newCurrentContext, addedUtvars1) =
               TIC.addUtvarOverride(lambdaDepth, currentContext, tvarNameSet1)
           val (newCurrentContext, addedUtvars2) =
               TIC.addUtvarIfNotthere(lambdaDepth, newCurrentContext, tvarNameSet2)
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
                         val ty = T.newtyWithLambdaDepth(lambdaDepth, T.univKind)
                         val path = #strLevel currentContext
                         val varPathInfo =
                             {name = varId, strpath = path, ty = ty}
                       in
                         (
                           ty :: tys,
                           TIC.bindVarInCurrentContext
                           (lambdaDepth, newCurrentContext, varId, T.VARID varPathInfo)
                         )
                       end)
                   (nil, newCurrentContext)
                   funIds
           val varIDTyTpexpList = 
             let
               fun inferRule (string, ptexp) =
                   let 
                     val (ptexpTy, tpexp) =
                         typeinfExp lambdaDepth inf newCurrentContext ptexp
                     val stringTy =
                         case TIC.lookupVar(newCurrentContext, string) of
                           SOME (T.VARID{ty, ...}) => ty
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
             in
               map
               (fn (PT.PTPATID ([string], _), ptexp) => inferRule (string, ptexp)
                 | (PT.PTPATTYPED (PT.PTPATID([string], _), _, _), 
                    ptexp) => inferRule (string, ptexp)
                 | _ => raise Control.Bug "typeinfRecbind, not a variable"
                )
               ptpatPtexpList
             end
           val TypesOfAllElements =  
               T.RECORDty
                   (foldr
                        (fn ({var={name = funId, ...}, expTy, ...}, tyFields) =>
                            SEnv.insert(tyFields,funId, expTy))
                        SEnv.empty
                        varIDTyTpexpList)
           val {boundEnv, ...} =
               generalizer (TypesOfAllElements, lambdaDepth)
           val _ =
             SEnv.appi
               (fn (tyname, (ifeq, ref (T.SUBSTITUTED (T.BOUNDVARty _)))) =>()
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
                         lambdaDepth,
                         newContext, 
                         name, 
                         T.VARID 
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
                            lambdaDepth,
                             newContext, 
                             name, 
                             T.VARID
                             {
                               name = name,
			       strpath = #strLevel currentContext,
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
               typeinfPtdeclList lambdaDepth isTop currentContext ptdecls
         in
           (newContext, [TPVALRECGROUP(ids, tpdeclList, loc)])
         end

       | PT.PTDATATYPE (datbinds, loc) =>
	 let
	   val (newContext, tyCons) =
               typeinfDatatypeDecl lambdaDepth currentContext datbinds loc
	 in 
	   (newContext, [TPDATADEC(tyCons, loc)])
	 end
       | PT.PTABSTYPE (datbinds, ptdecls, loc) =>
	 let
	   val (tyConEnv, tyCons, varEnv) = typeinfDatabinds lambdaDepth currentContext datbinds loc
           val newContext =
             TC.extendContextWithVarEnv
             (
              TC.injectTyConEnvToContext tyConEnv,
              varEnv
              )
           val newCurrentContext = TIC.extendCurrentContextWithContext (currentContext, newContext)
           val (newContext, newDecls) = typeinfPtdeclList lambdaDepth isTop newCurrentContext ptdecls
           val (tyConSubst, newTyCons, newTyConEnv) =
               foldr (fn ({name, strpath, abstract, tyvars, id, eqKind, boxedKind, datacon}, 
			  (tyConSubst, newTyCons, newTyConEnv)) =>
			 let
                           val newtycon =
                               TU.newTyCon
				 {
				  name = name,
				  strpath = strpath,
				  abstract = true, 
                                  tyvars = tyvars,
				  eqKind = ref T.NONEQ,
				  boxedKind = boxedKind,
				  datacon = datacon
				  }
			 in
                           (ID.Map.insert(tyConSubst, id, T.TYCON newtycon),
                            newtycon::newTyCons,
                            SEnv.insert(newTyConEnv, name, T.TYCON newtycon))
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
               typeinfPtdeclList lambdaDepth false currentContext ptdecls1
             val (newContext2, tpdeclList2) =
               typeinfPtdeclList lambdaDepth isTop
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
			       val E = 
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
                              makeTyFun lambdaDepth currentContext tydecl
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
       | PT.PTREPLICATEDAT (string1, longid , loc) => 
         (case TIC.lookupLongTyCon(currentContext, longid) of
            ((tyConStrPath,tyConName), SOME tyBindInfo) =>
            (
             case tyBindInfo of
	       T.TYCON rightTyCon => 
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
		 val tyConSubst = ID.Map.singleton(id,T.TYCON leftTyCon)
		 val (visited,newDatacon) = 
		     TCU.substTyConInVarEnv ID.Set.empty tyConSubst (!datacon)
		 val _ = (#datacon leftTyCon):= newDatacon
		 val context1 =
                     TC.bindTyConInEmptyContext
                       (
                        string1,
			T.TYCON leftTyCon
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
                            typeinfExnbind lambdaDepth currentContext exnBind
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
      | PT.PTEMPTY => raise Control.Bug "try to infer type for the empty dec"
     )
   end
  
   fun typeinfTopPtdecl lambdaDepth (currentContext:TIC.currentContext) ptdecl =
     let
        val _ = maxDepth := T.toplevelDepth
        val _ = T.kindedTyvarList := nil
        val _ = ffiApplyTyvars := nil
        val (newContext, tpdeclList) = typeinfPtdecl lambdaDepth true currentContext ptdecl
     in
       if E.isError() then 
         (newContext, tpdeclList)
       else
         let
           val tyvars = TypeContextUtils.tyvarsContext newContext
           val dummyTyList =
             (foldr
              (fn (r as ref(T.TVAR {recKind = T.OVERLOADED (h :: tl), ...}),dummyTyList) => 
                  (r := T.SUBSTITUTED h; dummyTyList)
                | (r as ref (T.TVAR {recKind=T.UNIV, ...}), dummyTyList) =>
                  let
                    val dummyty = TIU.nextDummyTy ()
                    val _ = r := (T.SUBSTITUTED dummyty)
                  in
                    dummyty :: dummyTyList
                  end
                | (**** temporary fix of BUG 200 ***)
                  (r as ref (T.TVAR {recKind=T.REC tySEnvMap, ...}), dummyTyList) =>
                    let
                      val _ = r := (T.SUBSTITUTED (T.RECORDty tySEnvMap))
                    in
                      dummyTyList
                    end
                | (r as ref (T.SUBSTITUTED _), dummyTyList) => dummyTyList
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
                 (PT.getLocDec ptdecl, E.ValueRestriction {dummyTyList = dummyTyList})
           val _ = TU.eliminateVacuousTyvars()
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
