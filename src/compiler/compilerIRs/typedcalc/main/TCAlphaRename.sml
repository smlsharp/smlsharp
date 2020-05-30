structure TCAlphaRename =
struct
local
  structure TC = TypedCalc
  structure T = Types
  structure P = Printers
  fun bug s = Bug.Bug ("AlphaRename: " ^ s)

  exception DuplicateVar
  exception DuplicateBtv

  type ty = T.ty
  type longsymbol = Symbol.longsymbol
  type btvEnv = T.kind BoundTypeVarID.Map.map
  type varInfo = T.varInfo

  type btvMap = BoundTypeVarID.id BoundTypeVarID.Map.map
  val emptyBtvMap = BoundTypeVarID.Map.empty
  type varMap = VarID.id VarID.Map.map
  val emptyVarMap = VarID.Map.empty
  type catchMap = FunLocalLabel.id FunLocalLabel.Map.map
  val emptyCatchMap = FunLocalLabel.Map.empty
  type context = {varMap:varMap, btvMap:btvMap, catchMap:catchMap}
  val emptyContext = {varMap=emptyVarMap, btvMap=emptyBtvMap,
                      catchMap=emptyCatchMap}

  fun copyTy (context:context) (ty:ty) = TyAlphaRename.copyTy (#btvMap context) ty
  fun copyConstraintList (context:context) constraints =
      map (TyAlphaRename.copyConstraint (#btvMap context)) constraints
  fun newBtvEnv ({varMap, btvMap, catchMap}:context) (btvEnv:btvEnv) =
      let
        val (btvMap, btvEnv) = 
            TyAlphaRename.newBtvEnv btvMap btvEnv
      in
        ({btvMap=btvMap, varMap=varMap, catchMap=catchMap}, btvEnv)
      end
  fun copyExVarInfo context {path:longsymbol, ty:ty} =
      {path=path, ty=copyTy context ty}
  fun copyPrimInfo context {primitive : BuiltinPrimitive.primitive, ty : ty} =
      {primitive=primitive, ty=copyTy context ty}
  fun copyOprimInfo context {ty : ty, path, id: OPrimID.id} =
      {ty=copyTy context ty, path=path,id=id}
  fun copyConInfo context {path, ty: ty, id: ConID.id} =
      {path=path, ty=copyTy context ty, id=id}
  fun copyExnInfo context {path, ty: ty, id: ExnID.id} =
      {path=path, ty=copyTy context ty, id=id}
  fun copyExExnInfo context {path, ty: ty} =
      {path=path, ty=copyTy context ty}
  fun copyExnCon context exnCon =
      case exnCon of
        TC.EXEXN exExnInfo => TC.EXEXN (copyExExnInfo context exExnInfo)
      | TC.EXN exnInfo => TC.EXN (copyExnInfo context exnInfo)
  fun copyFfiTy context ffiTy =
      case ffiTy of
        TC.FFIBASETY (ty, loc) =>
        TC.FFIBASETY (copyTy context ty, loc)
      | TC.FFIFUNTY (attribOpt (* Absyn.ffiAttributes option *),
                     ffiTyList1,
                     ffiTyList2,
                     ffiTyList3,loc) =>
        TC.FFIFUNTY (attribOpt,
                     map (copyFfiTy context) ffiTyList1,
                     Option.map (map (copyFfiTy context)) ffiTyList2,
                     map (copyFfiTy context) ffiTyList3,
                     loc)
      | TC.FFIRECORDTY (fields:(RecordLabel.label * TC.ffiTy) list,loc) =>
        TC.FFIRECORDTY
          (map (fn (l,ty)=>(l, copyFfiTy context ty)) fields,loc)

  val emptyVarIdMap = VarID.Map.empty : VarID.id VarID.Map.map
  val varIdMapRef = ref emptyVarIdMap : (VarID.id VarID.Map.map) ref
  val labelSetRef = ref FunLocalLabel.Set.empty
  fun newLabel ({varMap, btvMap, catchMap}:context) id =
      let
        val newId =
            if FunLocalLabel.Set.member (!labelSetRef, id)
            then FunLocalLabel.generate nil
            else (labelSetRef := FunLocalLabel.Set.add (!labelSetRef, id); id)
      in
        ({varMap = varMap, btvMap = btvMap,
          catchMap = FunLocalLabel.Map.insert (catchMap, id, newId)},
         newId)
      end
  fun addSubst (oldId, newId) = varIdMapRef := VarID.Map.insert(!varIdMapRef, oldId, newId)
  (* alpha-rename terms *)
  fun newId ({varMap, btvMap, catchMap}:context) id =
      let
        val newId = VarID.generate()
        val _ = addSubst (id, newId)
        val varMap =
            VarID.Map.insertWith
              (fn _ => raise DuplicateVar)
              (varMap, id, newId)
      in
        ({varMap=varMap, btvMap=btvMap, catchMap=catchMap}, newId)
      end
  fun newVar (context:context) ({path, id, ty, opaque}:varInfo) =
      let
        val ty = copyTy context ty
        val (context, newId) = newId context id
            handle DuplicateVar =>
                   raise bug "duplicate id in IDCalcUtils"
      in
        (context, {path=path, id=newId, ty=ty, opaque=opaque})
      end
  fun newVars (context:context) (vars:varInfo list) =
      let
        val (context, varsRev) =
            foldl
            (fn (var, (context, varsRev)) =>
                let
                  val (context, var) = newVar context var
                in
                  (context, var::varsRev)
                end
            )
            (context, nil)
            vars
      in
        (context, List.rev varsRev)
      end
  fun copyPat (context:context) (tppat:TC.tppat) : context * TC.tppat =
      case tppat of
        TC.TPPATCONSTANT (constant, ty, loc) =>
        (context, TC.TPPATCONSTANT (constant, copyTy context ty, loc))
      | TC.TPPATDATACONSTRUCT
          {argPatOpt,
           conPat:T.conInfo,
           instTyList,
           loc,
           patTy} =>
        let
          val conPat = copyConInfo context conPat
          val instTyList = Option.map (map (copyTy context)) instTyList
          val patTy = copyTy context patTy
          val (context, argPatOpt) =
              case argPatOpt of
                NONE => (context, NONE)
              | SOME argPat =>
                let
                  val (context, argPat) = copyPat context argPat
                in
                  (context, SOME argPat)
                end
        in
          (context,
           TC.TPPATDATACONSTRUCT
             {argPatOpt = argPatOpt,
              conPat = conPat,
              instTyList = instTyList,
              loc = loc,
              patTy = patTy
             }
          )
        end
      | TC.TPPATERROR (ty, loc) =>
        (context, TC.TPPATERROR (copyTy context ty, loc))
      | TC.TPPATEXNCONSTRUCT
          {argPatOpt, exnPat:TC.exnCon, loc, patTy} =>
        let
          val patTy = copyTy context patTy
          val exnPat = copyExnCon context exnPat
          val (context, argPatOpt) =
              case argPatOpt of
                NONE => (context, NONE)
              | SOME argPat =>
                let
                  val (context, argPat) = copyPat context argPat
                in
                  (context, SOME argPat)
                end
        in
          (context,
           TC.TPPATEXNCONSTRUCT
             {argPatOpt = argPatOpt,
              exnPat = exnPat,
              loc = loc,
              patTy = patTy
             }
          )
        end
      | TC.TPPATLAYERED {asPat, loc, varPat} =>
        let
          val (context, varPat) = copyPat context varPat
          val (context, asPat) = copyPat context asPat
        in
          (context, TC.TPPATLAYERED {asPat=asPat, loc=loc, varPat=varPat})
        end
      | TC.TPPATRECORD {fields:TC.tppat RecordLabel.Map.map, loc, recordTy} =>
        let
          val recordTy = copyTy context recordTy
          val (context, fields) =
              RecordLabel.Map.foldli
              (fn (label, pat, (context, fields)) =>
                  let
                    val (context, pat) = copyPat context pat
                  in
                    (context, RecordLabel.Map.insert(fields, label, pat))
                  end
              )
              (context, RecordLabel.Map.empty)
              fields
        in
          (context, TC.TPPATRECORD {fields=fields, loc=loc, recordTy=recordTy})
        end
      | TC.TPPATVAR varInfo =>
        let
          val (context, varInfo) = newVar context varInfo
        in
          (context, TC.TPPATVAR varInfo)
        end
      | TC.TPPATWILD (ty, loc) => 
        (context, TC.TPPATWILD (copyTy context ty, loc))

  fun copyPats context pats =
      let
        val (context,patsRev) =
            foldl
            (fn (pat, (context,patsRev)) =>
                let
                  val (context, pat) = copyPat context pat
                in
                  (context, pat::patsRev)
                end
            )
            (context, nil)
            pats
      in
        (context, List.rev patsRev)
      end
  fun evalVar (context as {varMap, btvMap, catchMap}:context)
              ({path, id, ty, opaque}:varInfo) =
      let
        val ty = copyTy context ty
        val id =
            case VarID.Map.find(varMap, id) of
              SOME id => id
            | NONE => id
      in
        {path=path, id=id, ty=ty, opaque=opaque}
      end
      handle DuplicateBtv =>
             (P.print "DuplicateBtv in evalVar\n";
              (* P.printPath path; *)
              P.print "\n";
              P.printTy ty;
              P.print "\n";
              raise bug "DuplicateBtv in evalVar")
  fun copyExp (context:context) (exp:TC.tpexp) =
      let
        fun copy exp = copyExp context exp
        fun copyT ty = copyTy context ty
      in
        (
        case exp of
          TC.TPAPPM {argExpList, funExp, funTy, loc} =>
          TC.TPAPPM {argExpList = map copy argExpList,
                     funExp = copy funExp,
                     funTy = copyT funTy,
                     loc = loc}
        | TC.TPCASEM {caseKind, expList, expTyList, loc, ruleBodyTy, ruleList} =>
          TC.TPCASEM
            {caseKind = caseKind,
             expList = map copy expList,
             expTyList = map copyT expTyList,
             loc = loc,
             ruleBodyTy = copyT ruleBodyTy,
             ruleList = map (copyRule context) ruleList
            }
        | TC.TPSWITCH {exp, expTy, ruleList, ruleBodyTy, defaultExp, loc} =>
          let
            fun newVarOpt context NONE = (context, NONE)
              | newVarOpt context (SOME var) =
                let
                  val (context, var) = newVar context var
                in
                  (context, SOME var)
                end
            fun copyConst context {const, ty, body} =
                {const = const,
                 ty = copyTy context ty,
                 body = copyExp context body}
            fun copyCon context {con, instTyList, argVarOpt, body} =
                let
                  val (context', argVarOpt) = newVarOpt context argVarOpt
                in
                  {con = copyConInfo context con,
                   instTyList = Option.map (map (copyTy context)) instTyList,
                   argVarOpt = argVarOpt,
                   body = copyExp context' body}
                end
            fun copyExn context {exn, argVarOpt, body} =
                let
                  val (context', argVarOpt) = newVarOpt context argVarOpt
                in
                  {exn = copyExnCon context exn,
                   argVarOpt = argVarOpt,
                   body = copyExp context' body}
                end
            fun copyRules context (TC.CONSTCASE rules) =
                TC.CONSTCASE (map (copyConst context) rules)
              | copyRules context (TC.CONCASE rules) =
                TC.CONCASE (map (copyCon context) rules)
              | copyRules context (TC.EXNCASE rules) =
                TC.EXNCASE (map (copyExn context) rules)
          in
            TC.TPSWITCH
              {exp = copy exp,
               expTy = copyT expTy,
               ruleList = copyRules context ruleList,
               ruleBodyTy = copyT ruleBodyTy,
               defaultExp = copy defaultExp,
               loc = loc}
          end
        | TC.TPCATCH {catchLabel, argVarList, catchExp, tryExp, resultTy, loc} =>
          let
            val (context1, catchLabel) = newLabel context catchLabel
            val (context2, argVarList) = newVars context argVarList
          in
            TC.TPCATCH
              {catchLabel = catchLabel,
               tryExp = copyExp context1 tryExp,
               argVarList = argVarList,
               catchExp = copyExp context2 catchExp,
               resultTy = copyT resultTy,
               loc = loc}
          end
        | TC.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
          TC.TPTHROW
            {catchLabel =
               case FunLocalLabel.Map.find (#catchMap context, catchLabel) of
                 SOME id => id
               | NONE => raise Bug.Bug "TPTHROW",
             argExpList = map copy argExpList,
             resultTy = copyT resultTy,
             loc = loc}
        | TC.TPCAST ((tpexp, expTy), ty, loc) =>
          TC.TPCAST ((copy tpexp, copyT expTy), copyT ty, loc)
        | TC.TPCONSTANT {const, loc, ty} =>
          TC.TPCONSTANT {const=const, loc = loc, ty=copyT ty}
        | TC.TPDATACONSTRUCT {argExpOpt, con:T.conInfo, instTyList, loc} =>
          TC.TPDATACONSTRUCT
            {argExpOpt = Option.map copy argExpOpt,
             con = copyConInfo context con,
             instTyList = Option.map (map copyT) instTyList,
             loc = loc
            }
        | TC.TPDYNAMICCASE {groupListTerm, groupListTy, dynamicTerm, dynamicTy, elemTy, ruleBodyTy, loc} =>
          TC.TPDYNAMICCASE 
            {groupListTerm = copy groupListTerm,
             groupListTy = copyT groupListTy,
             dynamicTerm = copy dynamicTerm,
             dynamicTy = copyT dynamicTy,
             elemTy = copyT elemTy,
             ruleBodyTy = copyT ruleBodyTy,
             loc = loc
            }
        | TC.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
          TC.TPDYNAMICEXISTTAPP
            {existInstMap = copy exp,
             exp = copy exp,
             expTy = copyT expTy,
             instTyList = map copyT instTyList,
             loc = loc}
        | TC.TPERROR => exp
        | TC.TPEXNCONSTRUCT {argExpOpt, exn:TC.exnCon, loc} =>
          TC.TPEXNCONSTRUCT
            {argExpOpt = Option.map copy argExpOpt,
             exn = copyExnCon context exn,
             loc = loc
            }
        | TC.TPEXNTAG {exnInfo, loc} =>
          TC.TPEXNTAG {exnInfo=copyExnInfo context exnInfo , loc=loc}
        | TC.TPEXEXNTAG {exExnInfo, loc} =>
          TC.TPEXEXNTAG
            {exExnInfo=copyExExnInfo context exExnInfo,
             loc= loc}
        | TC.TPEXVAR {path, ty} =>
          TC.TPEXVAR {path=path, ty=copyT ty}
        | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIFUN (ptrExp, ty), stubTy} =>
          TC.TPFFIIMPORT
            {ffiTy = copyFfiTy context ffiTy,
             loc = loc,
             funExp = TC.TPFFIFUN (copy ptrExp, copyT ty),
             stubTy = copyT stubTy
            }
        | TC.TPFFIIMPORT {ffiTy, loc, funExp as TC.TPFFIEXTERN _, stubTy} =>
          TC.TPFFIIMPORT
            {ffiTy = copyFfiTy context ffiTy,
             loc = loc,
             funExp = funExp,
             stubTy = copyT stubTy
            }
        | TC.TPFOREIGNSYMBOL {name, ty, loc} =>
          TC.TPFOREIGNSYMBOL {name = name, ty = copyT ty, loc = loc}
        | TC.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
          TC.TPFOREIGNAPPLY
            {funExp = copy funExp,
             argExpList = map copy argExpList,
             attributes = attributes,
             resultTy = Option.map copyT resultTy,
             loc = loc}
        | TC.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
          let
            val resultTy = Option.map copyT resultTy
            val (context, argVarList) = newVars context argVarList
            val bodyExp = copyExp context bodyExp
          in
            TC.TPCALLBACKFN
              {attributes = attributes,
               argVarList = argVarList,
               bodyExp = bodyExp,
               resultTy = resultTy,
               loc = loc}
          end
        | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
          let
            val bodyTy = copyT bodyTy
            val (context, argVarList) = newVars context argVarList
            val context = context # {catchMap = FunLocalLabel.Map.empty}
            val bodyExp = copyExp context bodyExp
          in
            TC.TPFNM
              {argVarList = argVarList,
               bodyExp = bodyExp,
               bodyTy = bodyTy,
               loc = loc
              }
          end
        | TC.TPHANDLE {exnVar, exp, handler, resultTy, loc} =>
          let
            val (context, exnVar) = newVar context exnVar
          in
            TC.TPHANDLE 
              {exnVar=exnVar, 
               exp=copy exp, 
               handler=copyExp context handler, 
               resultTy = copyT resultTy,
               loc=loc}
          end
        | TC.TPLET {body, decls, loc} =>
          let
            val (context, decls) = copyDeclList context decls
          in
            TC.TPLET {body=copyExp context body,
                      decls=decls,
                      loc=loc}
          end
        | TC.TPMODIFY {elementExp, elementTy, label, loc, recordExp, recordTy} =>
          TC.TPMODIFY
            {elementExp = copy elementExp,
             elementTy = copyT elementTy,
             label = label,
             loc = loc,
             recordExp = copy recordExp,
             recordTy = copyT recordTy}
        | TC.TPMONOLET {binds:(T.varInfo * TC.tpexp) list, bodyExp, loc} =>
          let
            val (context, binds) = copyBinds context binds
(*
            val (vars, exps) = ListPair.unzip binds
            val exps = map copy exps
            val (context, vars) = newVars context vars
            val bodyExp = copyExp context bodyExp
            val binds = ListPair.zip(vars, exps)
*)
          in
            TC.TPMONOLET {binds=binds, bodyExp=copyExp context bodyExp, loc=loc}
          end
        | TC.TPOPRIMAPPLY {argExp, instTyList, loc, oprimOp:T.oprimInfo} =>
          TC.TPOPRIMAPPLY
            {argExp = copy argExp,
             instTyList = map copyT instTyList,
             loc = loc,
             oprimOp = copyOprimInfo context oprimOp
            }
        | TC.TPPOLY {btvEnv, constraints, exp, expTyWithoutTAbs, loc} =>
          (
          let
            val (context, btvEnv) = newBtvEnv context btvEnv
          in
            TC.TPPOLY
              {btvEnv=btvEnv,
               constraints = copyConstraintList context constraints,
               exp = copyExp context exp,
               expTyWithoutTAbs = copyTy context expTyWithoutTAbs,
               loc = loc
              }
          end
          handle DuplicateBtv =>
                 (P.print "DuplicateBtv in TPPOLYty\n";
                  P.printTpexp exp;
                  P.print "\n";
                raise DuplicateBtv)
          )

        | TC.TPPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
          TC.TPPRIMAPPLY
            {argExp = copy argExp,
             instTyList = Option.map (map copyT) instTyList,
             loc = loc,
             primOp = copyPrimInfo context primOp
            }
        | TC.TPRAISE {exp, loc, ty} =>
          TC.TPRAISE {exp= copy exp, loc=loc, ty = copyT ty}
        | TC.TPRECORD {fields:TC.tpexp RecordLabel.Map.map, loc, recordTy} =>
          TC.TPRECORD
            {fields=RecordLabel.Map.map copy fields,
             loc=loc,
             recordTy=copyT recordTy}
        | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
          TC.TPSELECT
            {exp=copy exp,
             expTy=copyT expTy,
             label=label,
             loc=loc,
             resultTy=copyT resultTy
            }
        | TC.TPSIZEOF (ty, loc) =>
          TC.TPSIZEOF (copyT ty, loc)
        | TC.TPTAPP {exp, expTy, instTyList, loc} =>
          TC.TPTAPP {exp=copy exp,
                     expTy = copyT expTy,
                     instTyList=map copyT instTyList,
                     loc = loc
                    }
        | TC.TPVAR varInfo =>
          TC.TPVAR (evalVar context varInfo)
        (* the following should have been eliminate *)
        | TC.TPRECFUNVAR {arity, var} =>
          raise bug "TPRECFUNVAR in copy"
        | TC.TPJOIN {isJoin, ty, args = (arg1, arg2), argtys = (argty1, argty2), loc} =>
          TC.TPJOIN
            {ty = copyT ty,
             args = (copy arg1, copy arg2),
             argtys = (copyT argty1, copyT argty2),
             isJoin = isJoin,
             loc = loc}
        | TC.TPDYNAMIC {exp,ty,elemTy, coerceTy,loc} =>
          TC.TPDYNAMIC {exp=copy exp,
                        ty=copyT ty,
                        elemTy = copyT elemTy,
                        coerceTy=copyT coerceTy,
                        loc=loc}
        | TC.TPDYNAMICIS {exp,ty,elemTy, coerceTy,loc} =>
          TC.TPDYNAMICIS {exp=copy exp,
                          ty=copyT ty,
                          elemTy = copyT elemTy,
                          coerceTy=copyT coerceTy,
                          loc=loc}
        | TC.TPDYNAMICVIEW {exp,ty,elemTy, coerceTy,loc} =>
          TC.TPDYNAMICVIEW {exp=copy exp,
                            ty=copyT ty,
                            elemTy = copyT elemTy,
                            coerceTy=copyT coerceTy,
                            loc=loc}
        | TC.TPDYNAMICNULL {ty, coerceTy, loc} =>
          TC.TPDYNAMICNULL {ty = copyT ty,
                            coerceTy=copyT coerceTy,
                            loc=loc}
        | TC.TPDYNAMICTOP {ty, coerceTy, loc} =>
          TC.TPDYNAMICTOP {ty = copyT ty,
                           coerceTy=copyT coerceTy,
                           loc=loc}
        | TC.TPREIFYTY (ty,loc) =>
          TC.TPREIFYTY (copyT ty,loc)
        )
          handle DuplicateBtv =>
                 (P.print "DuplicateBtv in copyExp\n";
                  P.printTpexp exp;
                  P.print "\n";
                raise bug "DuplicateBtv in copyExp copyExp")
    end
  and copyRule context {args, body} =
      let
        val (context, args) = copyPats context args
        val body = copyExp context body
      in
        {args=args, body=body}
      end
  and copyDecl context tpdecl =
      case tpdecl of
        TC.TPEXD (exnInfo, loc) =>
        (context,
         TC.TPEXD
           (copyExnInfo context exnInfo,
            loc)
        )
      | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        (context,
         TC.TPEXNTAGD ({exnInfo=copyExnInfo context exnInfo,
                        varInfo=evalVar context varInfo},
                       loc)
        )
      | TC.TPEXPORTEXN exnInfo =>
        (context,
         TC.TPEXPORTEXN (copyExnInfo context exnInfo)
        )
      | TC.TPEXPORTVAR {var={path, ty}, exp} =>
        (context,
         TC.TPEXPORTVAR {var = {path = path, ty = copyTy context ty},
                         exp = copyExp context exp}
        )
      | TC.TPEXTERNEXN ({path, ty}, provider) =>
        (context,
         TC.TPEXTERNEXN ({path=path, ty=copyTy context ty}, provider)
        )
      | TC.TPBUILTINEXN {path, ty} =>
        (context,
         TC.TPBUILTINEXN {path=path, ty=copyTy context ty}
        )
      | TC.TPEXTERNVAR ({path, ty}, provider) =>
        (context,
         TC.TPEXTERNVAR ({path=path, ty=copyTy context ty}, provider)
        )
      | TC.TPVAL (bind:(T.varInfo * TC.tpexp), loc) =>
        let
          val (context, bind) = copyBind (context, context) bind
        in
          (context, TC.TPVAL (bind, loc))
        end
      | TC.TPVALPOLYREC
          {btvEnv,
           constraints,
           recbinds:{exp:TC.tpexp, var:T.varInfo} list,
           loc} =>
        (
        let
          val (newContext, btvEnv) = newBtvEnv context btvEnv
          val vars = map #var recbinds
          val (newContext as {varMap, btvMap, catchMap}, vars) = newVars newContext vars
          val varRecbindList = ListPair.zip (vars, recbinds)
          val recbinds =
              map
                (fn (var, {exp, var=_}) =>
                    {var=var, exp=copyExp newContext exp}
                )
                varRecbindList
        in
          ({varMap=varMap, btvMap = #btvMap context, catchMap = catchMap},
           TC.TPVALPOLYREC
             {btvEnv = btvEnv,
              constraints = copyConstraintList context constraints,
              recbinds = recbinds,
              loc = loc})
        end
          handle DuplicateBtv =>
                 (P.print "DuplicateBtv in TPVALPOLYREC\n";
                  P.printTpdecl tpdecl;
                  P.print "\n";
                raise bug "TPVALPOLYREC")
        )
      | TC.TPVALREC (recbinds:{exp:TC.tpexp, var:T.varInfo} list,loc) =>
        let
          val vars = map #var recbinds
          val (context, vars) = newVars context vars
          val varRecbindList = ListPair.zip (vars, recbinds)
          val recbinds =
              map
                (fn (var, {exp, var=_}) =>
                    {var=var, exp=copyExp context exp}
                )
                varRecbindList
        in
          (context, TC.TPVALREC (recbinds, loc))
        end
      (* the following should have been eliminate *)
      | TC.TPFUNDECL _ => raise bug "TPFUNDECL not eliminated"
      | TC.TPPOLYFUNDECL _  => raise bug "TPPOLYFUNDECL not eliminated"
  and copyBind (newContext, context) (var, exp) =
      let
        val (newContext, var) = newVar newContext var
        val exp = copyExp newContext exp
      in
        (newContext, (var, exp))
      end
  and copyBinds context binds =
      let
        val (newContext, bindsRev) =
            foldl
            (fn (bind, (newContext, bindsRev)) =>
                let
                  val (newContext, bind) = copyBind (newContext, context) bind
                in
                  (newContext, bind::bindsRev)
                end
            )
            (context, nil)
            binds
      in
        (newContext, List.rev bindsRev)
      end
  and copyDeclList context declList =
      let
        fun copy (decl, (context, declListRev)) =
            let
              val (context, newDecl) = copyDecl context decl
            in
              (context, newDecl::declListRev)
            end
        val (context, declListRev) = foldl copy (context, nil) declList
      in
        (context, List.rev declListRev)
      end
in
  val copyExp = 
   fn exp => 
      let
        val _ = varIdMapRef := emptyVarIdMap
        val _ = labelSetRef := FunLocalLabel.Set.empty
        val exp = copyExp emptyContext exp
      in
        (!varIdMapRef, exp)
      end
                   
end
end
