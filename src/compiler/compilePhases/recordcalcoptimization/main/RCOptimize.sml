structure RCOptimize =
struct
local
  structure RC = RecordCalc
  structure TC = TypedCalc
  structure RCU = RecordCalcUtils
  structure T = Types
  structure TRed = TyReduce
  structure P = Printers
  type rcexp = RC.rcexp
  type ty = T.ty
  fun bug s = Bug.Bug ("TPOptimize: " ^ s)
  fun printVarMap varMap =
      let
        fun pr (id, exp) = 
            (P.print "(";
             P.print (VarID.toString id);
             P.print ",";
             P.printTpexp exp;
             P.print ")\n"
            )
      in
        VarID.Map.appi pr varMap
      end
  fun printBtvMap btvMap =
      let
        fun pr (id, ty) = 
            (P.print "(";
             P.print (BoundTypeVarID.toString id);
             P.print ",";
             P.printTy ty;
             P.print ")\n"
            )
      in
        BoundTypeVarID.Map.appi pr btvMap
      end
  fun printContext {varMap, btvMap} =
      (P.print "varMap:\n";
       printVarMap varMap;
       P.print "btvMap:\n";
       printBtvMap btvMap;
       P.print "\n"
      )

  val countMapRef = ref VarID.Map.empty : (RCAnalyse.count VarID.Map.map) ref
  fun renameCountMapRef idMap =
      let
        val newCountMap = 
            VarID.Map.foldli
            (fn (id, count, newCountMap) =>
                case VarID.Map.find (idMap, id) of
                  SOME newId => VarID.Map.insert(newCountMap, newId, count)
                | NONE => VarID.Map.insert(newCountMap, id, count)
            )
            VarID.Map.empty
            (!countMapRef)
      in
        countMapRef := newCountMap
      end

  (* declaration for type constraints *)
  type ty = T.ty
  type path = RC.path
  type varInfo = RC.varInfo
  type btv = BoundTypeVarID.id
  type varId = VarID.id

  (* context *)
  type btvMap = ty BoundTypeVarID.Map.map
  val emptyBtvMap = BoundTypeVarID.Map.empty : btvMap
  type varMap = RC.rcexp VarID.Map.map
  val emptyVarMap = VarID.Map.empty : varMap
  type context = {varMap:varMap, btvMap:btvMap}
  val emptyContext = {varMap=emptyVarMap, btvMap=emptyBtvMap}

  fun bindExp ({varMap, btvMap}:context, var:varInfo, exp:RC.rcexp) =
      let
        val varMap = VarID.Map.insert(varMap, #id var, exp)
      in
        {varMap=varMap, btvMap=btvMap}
      end
  fun bindTy ({varMap, btvMap}:context, btv:btv, ty:ty) =
      let
        val btvMap = BoundTypeVarID.Map.insert(btvMap, btv, ty)
      in
        {varMap=varMap, btvMap=btvMap}
      end
      
  fun applyTys ({varMap, btvMap}:context) (btvEnv:T.btvEnv, instTyList:ty list) =
      let
        val btvList = BoundTypeVarID.Map.listKeys btvEnv
        val btvBinds = ListPair.zip (btvList, instTyList)
        val btvMap = 
            foldl
              (fn ((btv,ty), btvMap) =>
                  BoundTypeVarID.Map.insert(btvMap, btv, ty))
              btvMap
              btvBinds
      in
        {varMap=varMap, btvMap=btvMap}
      end

  val limitSize = 20 (* ?? *)
  fun isSmallValue tpexp =
      not (RCU.expansive tpexp) andalso RCSize.isSmallerExp (tpexp, limitSize)

  fun isOneUse ({id, ty, path}:varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME (RCAnalyse.FIN 1) => true
      | SOME _ => false
      | NONE =>  false

  fun isZeroUse ({id, ty, path}:varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME _ => false
      | NONE => true

  fun isInfUse ({id, ty, path}:varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME RCAnalyse.INF => true
      | _ => false

  fun isInline (var:varInfo, exp:RC.rcexp) =
      RCU.isAtom exp
      orelse
      (not (isInfUse var)) andalso isSmallValue exp
      orelse
      (not (RCU.expansive exp) andalso isOneUse var)

  fun evalPrimInfo ({varMap, btvMap}:context) (primInfo:T.primInfo) : T.primInfo =
      TRed.evalPrimInfo btvMap primInfo

  fun evalTy ({varMap, btvMap}:context) (ty:ty) : ty =
      TRed.evalTy btvMap ty

  fun evalExVarInfo ({varMap, btvMap}:context) {path:path,ty:ty} : RC.exVarInfo =
      {path=path, ty=TRed.evalTy btvMap ty}
  fun evalOprimInfo ({varMap, btvMap}:context) ({ty, path, id}:RC.oprimInfo) : RC.oprimInfo =
      {ty=TRed.evalTy btvMap ty, path=path, id=id}
  fun evalConInfo ({varMap, btvMap}:context) ({path, ty, id}:RC.conInfo) : RC.conInfo =
      {path=path, ty=TRed.evalTy btvMap ty, id=id}
  fun evalExnInfo ({varMap, btvMap}:context) ({path, ty, id}:RC.exnInfo) : RC.exnInfo =
      {path=path, ty=TRed.evalTy btvMap ty, id=id}
  fun evalExExnInfo ({varMap, btvMap}:context) ({path, ty}:RC.exExnInfo) : RC.exExnInfo =
      {path=path, ty=TRed.evalTy btvMap ty}

  fun evalBtvEnv ({varMap, btvMap}:context) (btvEnv:T.btvEnv) =
      TRed.evalBtvEnv btvMap btvEnv

  fun evalTyVar ({varMap, btvMap}:context) ({id, ty, path}:RC.varInfo) =
      {id=id, path=path, ty=TRed.evalTy btvMap ty}

  fun evalExnCon (context:context) (exnCon:RC.exnCon) : RC.exnCon =
      case exnCon of
        RC.EXEXN exExnInfo => RC.EXEXN (evalExExnInfo context exExnInfo)
      | RC.EXN exnInfo => RC.EXN (evalExnInfo context exnInfo)
  fun evalFfiTy context ffiTy =
      case ffiTy of
        TC.FFIBASETY (ty, loc) =>
        TC.FFIBASETY (evalTy context ty, loc)
      | TC.FFIFUNTY (attribOpt (* FFIAttributes.attributes option *),
                     ffiTyList1,
                     ffiTyList2,
                     ffiTyList3,loc) =>
        TC.FFIFUNTY (attribOpt,
                     map (evalFfiTy context) ffiTyList1,
                     Option.map (map (evalFfiTy context)) ffiTyList2,
                     map (evalFfiTy context) ffiTyList3,
                     loc)
      | TC.FFIRECORDTY (fields:(RecordLabel.label * TC.ffiTy) list,loc) =>
        TC.FFIRECORDTY
          (map (fn (l,ty)=>(l, evalFfiTy context ty)) fields,loc)
  (* eval terms *)
  fun evalVar 
        (context as {varMap,btvMap}:context) 
        (var as {id,...}:varInfo)
      : RC.rcexp
    = 
    case VarID.Map.find(varMap, id) of
        SOME rcexp => 
        let
          val (idMap, tpexp) =  RCAlphaRename.copyExp rcexp
          val _ = renameCountMapRef idMap
        in
          tpexp
        end
        (* substitution is simultaneous both in terms and types *)
      | NONE =>  RC.RCVAR (evalTyVar context var)

  fun evalExp (context:context) (exp:RC.rcexp) : RC.rcexp =
      let
        fun eval exp = evalExp context exp
        fun evalT ty = evalTy context ty
      in
        case exp of
          RC.RCAPPM {argExpList, funExp, funTy, loc} =>
          let
            val funExp = eval funExp
            val argExpList = map eval argExpList
          in
            case funExp of
              RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
              applyTerms context (argVarList, argExpList, bodyExp, loc)
            | _ => 
              RC.RCAPPM {argExpList = argExpList,
                         funExp = funExp,
                         funTy = evalT funTy,
                         loc = loc}
          end
        | RC.RCCASE 
            {defaultExp:rcexp, 
             exp:rcexp, 
             expTy:Types.ty, 
             loc:Loc.loc,
             ruleList:(RC.conInfo * varInfo option * rcexp) list,
             resultTy} =>
          let
            val exp = eval exp
          in
           case exp of
             RC.RCDATACONSTRUCT {argExpOpt, con:RC.conInfo, instTyList, loc} =>
             let
               val ruleOpt =
                   List.find 
                     (fn (argCon, varOpt, bodExp) => ConID.eq(#id argCon, #id con))
                     ruleList
               val (bindOpt, bodyExp) =
                   case (ruleOpt, argExpOpt) of
                     (NONE, NONE) => (NONE, eval defaultExp)
                   | (NONE, SOME argExp) =>
                     let
                       val argTy =
                           case (case instTyList of
                                   NONE => TypesBasics.derefTy (#ty con)
                                 | SOME tys => TypesBasics.tpappTy (#ty con, tys)) of
                             T.FUNMty ([argTy], _) => evalT argTy
                           | _ => raise bug "none of argTyOpt"
                       val dummyVar = RCU.newRCVarInfo argTy
                       val argExp = eval argExp
                       val bodyExp = eval defaultExp
                     in
                       (SOME (dummyVar, argExp), bodyExp)
                     end
                   | (SOME (_, NONE, bodyExp), NONE) => (NONE, eval bodyExp)
                   | (SOME (_, SOME var, bodyExp), SOME argExp) =>
                     let
                       val var = evalTyVar context var
                       val argExp = eval argExp
                       val bodyExp = eval bodyExp
                     in
                       (SOME (var, argExp), bodyExp)
                     end
                   | _ => raise bug "case and argument do not agree"
             in
               case bindOpt of
                 NONE => bodyExp
               | SOME bind => RC.RCLET {decls=[RC.RCVAL(bind, loc)],
                                        body=bodyExp,
                                        loc=loc}
             end
           | exp => 
             RC.RCCASE 
               {defaultExp = eval defaultExp,
                exp = exp,
                expTy = evalT expTy,
                loc = loc,
                ruleList = 
                map 
                  (fn (con, varOpt, exp) =>
                      (evalConInfo context con,
                       Option.map (evalTyVar context) varOpt,
                       eval exp)
                  )
                  ruleList,
                resultTy = evalT resultTy
               }
          end
        | RC.RCCAST ((rcexp, expTy), ty, loc) =>
          RC.RCCAST ((eval rcexp, evalT expTy), evalT ty, loc)
        | RC.RCCONSTANT {const, loc, ty} =>
          RC.RCCONSTANT {const=const, loc = loc, ty=evalT ty}
        | RC.RCDATACONSTRUCT {argExpOpt, con:RC.conInfo, instTyList, loc} =>
          RC.RCDATACONSTRUCT
            {argExpOpt = Option.map eval argExpOpt,
             con = evalConInfo context con,
             instTyList = Option.map (map evalT) instTyList,
             loc = loc
            }
        | RC.RCEXNCASE {defaultExp:rcexp, exp:rcexp, expTy:ty, loc:Loc.loc,
                        ruleList:(RC.exnCon * varInfo option * rcexp) list,
                        resultTy} =>
          RC.RCEXNCASE
            {defaultExp = eval defaultExp,
             exp = eval exp,
             expTy = evalT expTy,
             loc = loc,
             ruleList =
             map 
               (fn (con, varOpt, exp) =>
                   (evalExnCon context con,
                    Option.map (evalTyVar context) varOpt,
                    eval exp)
               )
               ruleList,
             resultTy = evalT resultTy
            }
        | RC.RCEXNCONSTRUCT {argExpOpt, exn:RC.exnCon, loc} =>
          RC.RCEXNCONSTRUCT
            {argExpOpt = Option.map eval argExpOpt,
             exn = evalExnCon context exn,
             loc = loc
            }
        | RC.RCEXNTAG {exnInfo, loc} => 
          RC.RCEXNTAG {exnInfo=evalExnInfo context exnInfo, loc=loc}
        | RC.RCEXEXNTAG {exExnInfo, loc} =>
          RC.RCEXEXNTAG
            {exExnInfo=evalExExnInfo context exExnInfo, loc= loc}
        | RC.RCEXVAR {path, ty} =>
          RC.RCEXVAR {path=path, ty=evalT ty}
        | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, funExp}, ty, loc) =>
          RC.RCFFI (RC.RCFFIIMPORT
                      {ffiTy = evalFfiTy context ffiTy,
                       funExp = case funExp of
                                  RC.RCFFIFUN (ptrExp, ty) => RC.RCFFIFUN (eval ptrExp, evalT ty)
                                | RC.RCFFIEXTERN _ => funExp},
                    evalT ty,
                    loc)
        | RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
          RC.RCFNM
            {argVarList = map (evalTyVar context) argVarList,
             bodyExp = eval bodyExp,
             bodyTy = evalT bodyTy,
             loc = loc
            }
        | RC.RCFOREIGNSYMBOL {loc, name, ty} =>
          RC.RCFOREIGNSYMBOL {loc=loc, name=name, ty=evalT ty}
        | RC.RCHANDLE {exnVar, exp, handler, resultTy, loc} =>
          RC.RCHANDLE {exnVar=evalTyVar context exnVar,
                       exp=eval exp,
                       handler= eval handler,
                       resultTy = evalT resultTy,
                       loc=loc}
        | RC.RCCATCH {catchLabel, argVarList, catchExp, tryExp, resultTy,
                      loc} =>
          RC.RCCATCH {catchLabel = catchLabel,
                      argVarList = map (evalTyVar context) argVarList,
                      catchExp = eval catchExp,
                      tryExp = eval tryExp,
                      resultTy = evalT resultTy,
                      loc = loc}
        | RC.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
          RC.RCTHROW {catchLabel = catchLabel,
                      argExpList = map (evalExp context) argExpList,
                      resultTy = evalT resultTy,
                      loc = loc}
        | RC.RCLET {body, decls, loc} =>
          let
            val (context, decls) = evalDeclList context decls
            val body = evalExp context body
          in
            case decls of
              nil => body
            | _ => RC.RCLET {body=body, decls=decls, loc=loc}
          end
        | RC.RCMODIFY {elementExp, elementTy, indexExp, label, loc, recordExp, recordTy} =>
          (case recordExp of
             RC.RCRECORD {fields, loc, recordTy} =>
             if not (RCU.expansive recordExp) then
               eval 
                 (RC.RCRECORD {fields=RecordLabel.Map.insert(fields, label, elementExp), 
                               loc=loc, 
                               recordTy=recordTy}
                 )
             else raise bug "non value term in recordExp"
           | _ => 
             RC.RCMODIFY
               {elementExp = eval elementExp,
                elementTy = evalT elementTy,
                indexExp = eval indexExp,
                label = label,
                loc = loc,
                recordExp = eval recordExp,
                recordTy = evalT recordTy}
          )
        | RC.RCOPRIMAPPLY {argExp, instTyList, loc, oprimOp:RC.oprimInfo} =>
          RC.RCOPRIMAPPLY
            {argExp = eval argExp,
             instTyList = map evalT instTyList,
             loc = loc,
             oprimOp = evalOprimInfo context oprimOp
            }
        | RC.RCPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
          RC.RCPOLY
            {btvEnv=evalBtvEnv context btvEnv,
             exp = eval exp,
             expTyWithoutTAbs = evalT expTyWithoutTAbs,
             loc = loc
            }
        | RC.RCPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
          RC.RCPRIMAPPLY
            {argExp=eval argExp,
             instTyList=Option.map (map evalT) instTyList,
             loc=loc,
             primOp=evalPrimInfo context primOp
            }
        | RC.RCRAISE {exp, loc, ty} =>
          RC.RCRAISE {exp=eval exp, loc=loc, ty = evalT ty}
        | RC.RCRECORD {fields:rcexp RecordLabel.Map.map, loc, recordTy} =>
          RC.RCRECORD
            {fields=RecordLabel.Map.map eval fields,
             loc=loc,
             recordTy=evalT recordTy
            }
        | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} =>
          let
            val exp = eval exp
          in
            case exp of
              RC.RCRECORD {fields, loc, recordTy} =>
              if not (RCU.expansive exp) then
                (case RecordLabel.Map.find (fields, label)  of
                   SOME exp => exp
                 | NONE => raise bug "label not found")
              else raise bug "non value term in a record"
            | _ => 
              RC.RCSELECT
                {exp=exp,
                 expTy=evalT expTy,
                 indexExp = eval indexExp,
                 label=label,
                 loc=loc,
                 resultTy=evalT resultTy
                }
          end
        | RC.RCSIZEOF (ty, loc) =>
          RC.RCSIZEOF (evalT ty, loc)
        | RC.RCREIFYTY (ty, loc) =>
          RC.RCREIFYTY (evalT ty, loc)
        | RC.RCTAPP {exp, expTy, instTyList, loc} =>
          let
            val exp = eval exp
            val expTy = evalT expTy
            val instTyList = map evalT instTyList
          in
            case exp of
              RC.RCPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
              let
                val newContext = applyTys context (btvEnv, instTyList)
              in
                evalExp newContext exp
              end
            | _ => 
              RC.RCTAPP {exp=exp,
                         expTy = expTy,
                         instTyList= instTyList,
                         loc = loc
                        }
          end
        | RC.RCVAR varInfo =>
          evalVar context varInfo
        | RC.RCCALLBACKFN {attributes, resultTy, argVarList, bodyExp:rcexp,
                           loc:Loc.loc} =>
          RC.RCCALLBACKFN
            {attributes = attributes,
             resultTy = Option.map evalT resultTy,
             argVarList = map (evalTyVar context) argVarList,
             bodyExp = eval bodyExp,
             loc=loc
            }
        | RC.RCFOREIGNAPPLY {argExpList:rcexp list,
                             attributes, resultTy,
                             funExp:rcexp,
                             loc:Loc.loc} =>
          RC.RCFOREIGNAPPLY 
            {argExpList= map eval argExpList,
             attributes = attributes,
             resultTy = Option.map evalT resultTy,
             funExp = eval funExp,
             loc = loc}
        | RC.RCINDEXOF (string, ty, loc) => 
          RC.RCINDEXOF (string, evalT ty, loc)
        | RC.RCSWITCH {branches:(RC.constant * rcexp) list, defaultExp:rcexp,
                       expTy:Types.ty, loc:Loc.loc, switchExp:rcexp,
                       resultTy} =>
          RC.RCSWITCH
            {branches =
             map (fn (const, exp) => 
                     (const, eval exp)
                 )
                 branches,
             defaultExp = eval defaultExp,
             expTy = evalT expTy, 
             loc = loc,
             switchExp=eval switchExp,
             resultTy = evalT resultTy
            }
        | RC.RCTAGOF (ty, loc) =>
          RC.RCTAGOF (evalT ty, loc)
        | RC.RCJOIN {isJoin, ty,args=(arg1,arg2), argTys=(argTy1,argTy2),loc} =>
          RC.RCJOIN
            {
             ty= evalT ty,
             args = (eval arg1, eval arg2),
             argTys = (evalT argTy1, evalT argTy2),
             isJoin = isJoin,
             loc = loc
            }
        | RC.RCDYNAMIC _ => raise bug "RCDYNAMIC to RCOptimize"
        | RC.RCDYNAMICIS _ => raise bug "RCDYNAMICIS to RCOptimize"
        | RC.RCDYNAMICNULL _ => raise bug "RCDYNAMICNULL to RCOptimize"
        | RC.RCDYNAMICTOP _ => raise bug "RCDYNAMICTOP to RCOptimize"
        | RC.RCDYNAMICVIEW _ => raise bug "RCDYNAMICVIEW to RCOptimize"
        | RC.RCDYNAMICCASE _ => raise bug "RCDYNAMICCASE to RCOptimize"
        | RC.RCDYNAMICEXISTTAPP _ => raise bug "RCDYNAMICEXISTTAPP to RCOptimize"

      end
  and applyTerms
        ({varMap, btvMap}:context)
        (argVarList:varInfo list, argExpList:RC.rcexp list, body:RC.rcexp, loc) =
      let
        val termBinds = ListPair.zip (argVarList, argExpList)
        val (bindsRev, varMap) = 
            foldl
            (fn ((var,exp), (bindsRev, varMap)) =>
                if isInline (var,exp) then 
                  (bindsRev, VarID.Map.insert(varMap, #id var, exp))
                else
                  ((var,exp)::bindsRev, varMap)
            )
            (nil, varMap)
            termBinds
        val binds = List.rev bindsRev
        val newContext = {varMap=varMap, btvMap=btvMap}
        val newBody = evalExp newContext body
      in
        case binds of
          nil => newBody
        | _ => RC.RCLET {decls = map (fn x => RC.RCVAL(x, loc)) binds,
                         body = newBody, loc = loc}
      end
  and evalDecl (tpdecl:RC.rcdecl, (context:context, declListRev:RC.rcdecl list)) =
      case tpdecl of
        RC.RCEXD (exnInfo, loc) =>
        let 
        val res = 
        (context,
         RC.RCEXD
           (evalExnInfo context exnInfo,
            loc)
         ::declListRev
        )
        in res
        end
      | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val varExp = evalVar context varInfo
          val declListRev =
              case varExp of
                RC.RCVAR newVar =>
                RC.RCEXNTAGD ({exnInfo=evalExnInfo context exnInfo,
                               varInfo=newVar},
                              loc)
                 ::declListRev
              | newExp => 
                let
                  val newVar = RCU.newRCVarInfo (#ty varInfo)
                  val bindDecl = RC.RCVAL ((newVar, newExp), loc)
                  val newTpexntag =
                      RC.RCEXNTAGD ({exnInfo=evalExnInfo context exnInfo,
                                     varInfo=newVar},
                                    loc)
                in
                  newTpexntag :: bindDecl :: declListRev
                end
          val res = (context, declListRev)
        in
          res
        end
      | RC.RCEXPORTEXN exnInfo =>
        (context,
         RC.RCEXPORTEXN (evalExnInfo context exnInfo)
         :: declListRev
        )
      | RC.RCEXPORTVAR {var, exp} =>
        (context,
         RC.RCEXPORTVAR {var = var, exp = evalExp context exp}
         :: declListRev
        )
      | RC.RCEXTERNEXN ({path, ty}, provider) =>
        (context,
         RC.RCEXTERNEXN ({path=path, ty=evalTy context ty}, provider)
         :: declListRev
        )
      | RC.RCBUILTINEXN {path, ty} =>
        (context,
         RC.RCBUILTINEXN {path=path, ty=evalTy context ty}
         :: declListRev
        )
      | RC.RCEXTERNVAR ({path, ty}, provider) =>
        (context,
         RC.RCEXTERNVAR ({path=path, ty=evalTy context ty}, provider)
         :: declListRev
        )
      | RC.RCVAL (bind:(varInfo * rcexp), loc) =>
        let
          val (context, binds) = evalBindSeq (bind, (context, nil))
          val declListRev =
              map (fn x => RC.RCVAL (x, loc)) binds @ declListRev
        in
          (context, declListRev)
        end
      | RC.RCVALPOLYREC
          (btvEnv,
           recbinds:{exp:rcexp, var:varInfo} list,
           loc) =>
        let
          val btvEnv = evalBtvEnv context btvEnv
          val recbinds =
              map
                (fn {exp, var} =>
                    {var=evalTyVar context var,
                     exp=evalExp context exp}
                )
                recbinds
        in
          (context,
           RC.RCVALPOLYREC (btvEnv, recbinds, loc)
           :: declListRev
          )
        end
      | RC.RCVALREC (recbinds:{exp:rcexp, var:varInfo} list,loc) =>
        let
          val recbinds =
              map
                (fn {exp, var} =>
                    {var=evalTyVar context var,
                     exp=evalExp context exp}
                )
                recbinds
        in
          (context,
           RC.RCVALREC (recbinds, loc)
           :: declListRev
          )
        end

  and evalBind context ((var, exp), (newContext, bindsRev))  =
      let
        val var = evalTyVar context var
        val exp = evalExp context exp
        val (newContext, bindsRev) = 
            if isZeroUse var andalso not (RCU.expansive exp) then
              (newContext, bindsRev)
            else if isInline (var, exp) then
              (P.print "inlining :";
               P.printPath (#path var);
               P.print "\n";
               (bindExp (newContext, var, exp), bindsRev)
              )
            else (newContext, (var,exp)::bindsRev)
      in
        (newContext, bindsRev)
      end
  and evalBinds context binds =
      let
        val (newContext, bindsRev) =
            foldl (evalBind context) (context, nil) binds
      in
        (newContext, List.rev bindsRev)
      end
  and evalBindSeq ((var, exp), (context, bindsRev))  =
      let
        val var = evalTyVar context var
        val exp = evalExp context exp
        val (context, bindsRev) = 
            if isInline (var, exp) then
              (P.print "inlining :";
               P.printPath (#path var);
               P.print "\n";
               (bindExp (context, var, exp), bindsRev)
              )
            else (context, (var,exp)::bindsRev)
      in
        (context, bindsRev)
      end
  and evalBindsSeq context binds =
      let
        val (context, bindsRev) =
            foldl evalBindSeq (context, nil) binds
      in
        (context, List.rev bindsRev)
      end
  and evalDeclList context declList =
      let
        val (context, declListRev) = foldl evalDecl (context, nil) declList
      in
        (context, List.rev declListRev)
      end
in
  fun optimize declList =
      let
        val declList = RCRevealTy.revealTyRcdeclList declList
        val _ = countMapRef := RCAnalyse.analyseDeclList declList
        val (context, declList) = evalDeclList emptyContext declList
      in
        declList
      end
end
end
