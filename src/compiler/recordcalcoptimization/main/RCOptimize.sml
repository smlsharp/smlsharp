structure RCOptimize =
struct
local
  structure RC = RecordCalc
  structure TC = TypedCalc
  structure RCU = RecordCalcUtils
  structure T = Types
  structure TRed = TyReduce
  structure TU = TypesUtils
  structure P = Printers
  type rcexp = RC.rcexp
  type ty = T.ty
  fun bug s = Control.Bug ("TPOptimize: " ^ s)
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
  type path = T.path
  type varInfo = {path:path, id:VarID.id, ty:ty}
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

  fun isOneUse ({id, ty, path}:T.varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME (RCAnalyse.FIN 1) => true
      | SOME _ => false
      | NONE =>  false

  fun isZeroUse ({id, ty, path}:T.varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME _ => false
      | NONE => true

  fun isInfUse ({id, ty, path}:T.varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME RCAnalyse.INF => true
      | _ => false

  fun isInline (var:T.varInfo, exp:RC.rcexp) =
      RCU.isAtom exp
      orelse
      (not (isInfUse var)) andalso isSmallValue exp
      orelse
      (not (RCU.expansive exp) andalso isOneUse var)

  fun evalExVarInfo ({varMap, btvMap}:context) (exVarInfo : T.exVarInfo) : T.exVarInfo =
      TRed.evalExVarInfo btvMap exVarInfo
  fun evalPrimInfo ({varMap, btvMap}:context) (primInfo:T.primInfo) : T.primInfo =
      TRed.evalPrimInfo btvMap primInfo
  fun evalOprimInfo ({varMap, btvMap}:context) (oprimInfo:T.oprimInfo) : T.oprimInfo =
      TRed.evalOprimInfo btvMap oprimInfo
  fun evalConInfo ({varMap, btvMap}:context) (conInfo:T.conInfo) : T.conInfo =
      TRed.evalConInfo btvMap conInfo
  fun evalExnInfo ({varMap, btvMap}:context) (exnInfo:T.exnInfo) : T.exnInfo =
      TRed.evalExnInfo btvMap exnInfo
  fun evalExExnInfo ({varMap, btvMap}:context) (exExnInfo:T.exExnInfo) : T.exExnInfo =
      TRed.evalExExnInfo btvMap exExnInfo
  fun evalTy ({varMap, btvMap}:context) (ty:ty) : ty =
      TRed.evalTy btvMap ty
  fun evalBtvEnv ({varMap, btvMap}:context) (btvEnv:T.btvEnv) =
      TRed.evalBtvEnv btvMap btvEnv
  fun evalTyVar  ({varMap, btvMap}:context) (var:varInfo) =
      TRed.evalTyVar btvMap var
  fun evalExnCon (context:context) (exnCon:TC.exnCon) : TC.exnCon =
      case exnCon of
        TC.EXEXN exExnInfo => TC.EXEXN (evalExExnInfo context exExnInfo)
      | TC.EXN exnInfo => TC.EXN (evalExnInfo context exnInfo)
  fun evalFfiTy context ffiTy =
      case ffiTy of
        TC.FFIBASETY (ty, loc) =>
        TC.FFIBASETY (evalTy context ty, loc)
      | TC.FFIFUNTY (attribOpt (* Absyn.ffiAttributes option *),
                     ffiTyList1,
                     ffiTyList2,loc) =>
        TC.FFIFUNTY (attribOpt,
                     map (evalFfiTy context) ffiTyList1,
                     map (evalFfiTy context) ffiTyList2,
                     loc)
      | TC.FFIRECORDTY (fields:(string * TC.ffiTy) list,loc) =>
        TC.FFIRECORDTY
          (map (fn (l,ty)=>(l, evalFfiTy context ty)) fields,loc)
  fun evalForeignFunTy context
        {
         argTyList : ty list,
         resultTy : ty,
         attributes : Absyn.ffiAttributes
        } =
        {
         argTyList = map (evalTy context) argTyList,
         resultTy = evalTy context resultTy,
         attributes = attributes
        }
  (* eval terms *)
  fun evalVar 
        (context as {varMap,btvMap}:context) 
        (var as {id,...}:varInfo, loc:Loc.loc)
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
      | NONE =>  RC.RCVAR (evalTyVar context var, loc)

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
             ruleList:(T.conInfo * varInfo option * rcexp) list} =>
          let
            val exp = eval exp
          in
           case exp of
             RC.RCDATACONSTRUCT {argExpOpt, argTyOpt, con:T.conInfo, instTyList, loc} =>
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
                       val argTy = case argTyOpt 
                                    of SOME ty => evalT ty
                                     | NONE => raise bug "none of argTyOpt"
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
               | SOME bind => RC.RCMONOLET {binds=[bind], bodyExp=bodyExp, loc=loc}
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
                  ruleList
               }
          end
        | RC.RCCAST (rcexp, ty, loc) =>
          RC.RCCAST (eval rcexp, evalT ty, loc)
        | RC.RCCONSTANT {const, loc, ty} =>
          RC.RCCONSTANT {const=const, loc = loc, ty=evalT ty}
        | RC.RCDATACONSTRUCT {argExpOpt, argTyOpt, con:T.conInfo, instTyList, loc} => 
          RC.RCDATACONSTRUCT
            {argExpOpt = Option.map eval argExpOpt,
             con = evalConInfo context con,
             instTyList = map evalT instTyList,
             argTyOpt = Option.map evalT argTyOpt,
             loc = loc
            }
        | RC.RCEXNCASE {defaultExp:rcexp, exp:rcexp, expTy:ty, loc:Loc.loc,
                        ruleList:(TC.exnCon * varInfo option * rcexp) list} =>
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
               ruleList
            }
        | RC.RCEXNCONSTRUCT {argExpOpt, exn:TC.exnCon, instTyList, loc} =>
          RC.RCEXNCONSTRUCT
            {argExpOpt = Option.map eval argExpOpt,
             exn = evalExnCon context exn,
             instTyList = map evalT instTyList,
             loc = loc
            }
        | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} => 
          RC.RCEXN_CONSTRUCTOR {exnInfo=evalExnInfo context exnInfo, loc=loc}
        | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
          RC.RCEXEXN_CONSTRUCTOR
            {exExnInfo=evalExExnInfo context exExnInfo, loc= loc}
        | RC.RCEXVAR ({path, ty}, loc) =>
          RC.RCEXVAR ({path=path, ty=evalT ty}, loc)
        | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, ptrExp:rcexp}, ty, loc) =>
          RC.RCFFI (RC.RCFFIIMPORT
                      {ffiTy = evalFfiTy context ffiTy,
                       ptrExp = eval ptrExp},
                    evalT ty,
                    loc)
        | RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
          RC.RCFNM
            {argVarList = map (evalTyVar context) argVarList,
             bodyExp = eval bodyExp,
             bodyTy = evalT bodyTy,
             loc = loc
            }
        | RC.RCGLOBALSYMBOL {kind, loc, name, ty} =>
          RC.RCGLOBALSYMBOL {kind=kind, loc=loc, name=name, ty=evalT ty}
        | RC.RCHANDLE {exnVar, exp, handler, loc} =>
          RC.RCHANDLE {exnVar=evalTyVar context exnVar,
                       exp=eval exp,
                       handler= eval handler,
                       loc=loc}
        | RC.RCLET {body:rcexp list, decls, loc, tys} =>
          let
            val tys = map evalT tys
            val (context, decls) = evalDeclList context decls
            val body = map (evalExp context) body
          in
            case decls of
              nil => RC.RCSEQ {expList=body, expTyList=tys, loc=loc}
            | _ => RC.RCLET {body=body, decls=decls, loc=loc, tys=tys}
          end
        | RC.RCMODIFY {elementExp, elementTy, indexExp, label, loc, recordExp, recordTy} =>
          (case recordExp of
             RC.RCRECORD {fields, loc, recordTy} =>
             if not (RCU.expansive recordExp) then
               eval 
                 (RC.RCRECORD {fields=LabelEnv.insert(fields, label, elementExp), 
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
        | RC.RCMONOLET {binds:(T.varInfo * rcexp) list, bodyExp, loc} =>
          let
            val (context, binds) = evalBindsSeq context binds
            val bodyExp = evalExp context bodyExp
          in
            case binds of
              nil => bodyExp
            | _ => RC.RCMONOLET {binds=binds, bodyExp=bodyExp, loc=loc}
          end
        | RC.RCOPRIMAPPLY {argExp, instTyList, loc, oprimOp:T.oprimInfo} =>
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
        | RC.RCPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
          RC.RCPOLYFNM
            {argVarList=map (evalTyVar context) argVarList,
             bodyExp=eval bodyExp,
             bodyTy=evalT bodyTy,
             btvEnv=evalBtvEnv context btvEnv,
             loc=loc
            }
        | RC.RCPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
          RC.RCPRIMAPPLY
            {argExp=eval argExp,
             instTyList=map evalT instTyList,
             loc=loc,
             primOp=evalPrimInfo context primOp
            }
        | RC.RCRAISE {exp, loc, ty} =>
          RC.RCRAISE {exp=eval exp, loc=loc, ty = evalT ty}
        | RC.RCRECORD {fields:rcexp LabelEnv.map, loc, recordTy} =>
          RC.RCRECORD
            {fields=LabelEnv.map eval fields,
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
                (case LabelEnv.find (fields, label)  of
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
        | RC.RCSEQ {expList, expTyList, loc} =>
          RC.RCSEQ
            {expList = map eval expList,
             expTyList = map evalT expTyList,
             loc = loc
            }
        | RC.RCSIZEOF (ty, loc) =>
          RC.RCSIZEOF (evalT ty, loc)
        | RC.RCSQL (RC.RCSQLSERVER 
                      {schema:Types.ty LabelEnv.map LabelEnv.map,
                       server:string}, 
                    ty, 
                    loc) =>
          let
            val ty = evalT ty
            val schema = LabelEnv.map (LabelEnv.map evalT) schema
          in
            RC.RCSQL (RC.RCSQLSERVER 
                        {schema=schema,
                         server=server
                        },
                      ty,
                      loc
                     )
          end
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
            | RC.RCPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
              let
                val newContext = applyTys context (btvEnv, instTyList)
                val bodyExp = evalExp newContext bodyExp
                val bodyTy = evalTy newContext bodyTy
                val argVarList = map (evalTyVar newContext) argVarList
              in
                RC.RCFNM
                  {argVarList=argVarList, 
                   bodyExp=bodyExp, 
                   bodyTy=bodyTy, 
                   loc=loc}
              end
            | _ => 
              RC.RCTAPP {exp=exp,
                         expTy = expTy,
                         instTyList= instTyList,
                         loc = loc
                        }
          end
        | RC.RCVAR (varInfo, loc) =>
          evalVar context (varInfo, loc)
        | RC.RCEXPORTCALLBACK {foreignFunTy:Types.foreignFunTy, funExp:rcexp,
                               loc:Loc.loc} =>
          RC.RCEXPORTCALLBACK 
            {foreignFunTy = evalForeignFunTy context foreignFunTy,
             funExp= eval funExp,
             loc=loc
            }
        | RC.RCFOREIGNAPPLY {argExpList:rcexp list,
                             foreignFunTy:Types.foreignFunTy, 
                             funExp:rcexp,
                             loc:Loc.loc} =>
          RC.RCFOREIGNAPPLY 
            {argExpList= map eval argExpList,
             foreignFunTy = evalForeignFunTy context foreignFunTy,
             funExp = eval funExp,
             loc = loc}
        | RC.RCINDEXOF (string, ty, loc) => 
          RC.RCINDEXOF (string, evalT ty, loc)
        | RC.RCSWITCH {branches:(Absyn.constant * rcexp) list, defaultExp:rcexp,
                       expTy:Types.ty, loc:Loc.loc, switchExp:rcexp} =>
          RC.RCSWITCH
            {branches =
             map (fn (const, exp) => 
                     (const, eval exp)
                 )
                 branches,
             defaultExp = eval defaultExp,
             expTy = evalT expTy, 
             loc = loc,
             switchExp=eval switchExp
            }
        | RC.RCTAGOF (ty, loc) =>
          RC.RCTAGOF (evalT ty, loc)
      end
  and applyTerms
        ({varMap, btvMap}:context)
        (argVarList:T.varInfo list, argExpList:RC.rcexp list, body:RC.rcexp, loc) =
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
        | _ => RC.RCMONOLET {binds=binds, bodyExp=newBody, loc=loc}
      end
  and evalDecl (tpdecl:RC.rcdecl, (context:context, declListRev:RC.rcdecl list)) =
      case tpdecl of
        RC.RCEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
        let 
        val res = 
        (context,
         RC.RCEXD
           (map (fn {exnInfo, loc} =>
                    {exnInfo=evalExnInfo context exnInfo, loc=loc})
                exbinds,
            loc)
         ::declListRev
        )
        in res
        end
      | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val varExp = evalVar context (varInfo, loc)
          val declListRev =
              case varExp of
                RC.RCVAR (newVar, _) =>
                 RC.RCEXNTAGD ({exnInfo=evalExnInfo context exnInfo,
                                varInfo=newVar},
                               loc)
                 ::declListRev
              | newExp => 
                let
                  val newVar = RCU.newRCVarInfo (#ty varInfo)
                  val bindDecl = RC.RCVAL ([(newVar, newExp)], loc)
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
      | RC.RCEXPORTEXN (exnInfo, loc) =>
        (context,
         RC.RCEXPORTEXN (evalExnInfo context exnInfo, loc)
         :: declListRev
        )
      | RC.RCEXPORTVAR {internalVar, externalVar, loc} =>
        let
          val tpexp = evalVar context (internalVar, loc)
          val (internalVar, declListRev) = 
              case tpexp of
                RC.RCVAR (var,loc) => (var, declListRev)
              | _ => 
                let
                  val internalVar = evalTyVar context internalVar
                in
                  (internalVar,
                   RC.RCVAL ([(internalVar, tpexp)],loc) :: declListRev)
                end
          val externalVar=evalExVarInfo context externalVar
        in
          (context,
           RC.RCEXPORTVAR {internalVar=internalVar,
                           externalVar=externalVar,
                           loc=loc}
           :: declListRev
          )
        end
      | RC.RCEXTERNEXN ({path, ty}, loc) =>
        (context,
         RC.RCEXTERNEXN ({path=path, ty=evalTy context ty}, loc)
         :: declListRev
        )
      | RC.RCEXTERNVAR ({path, ty}, loc) =>
        (context,
         RC.RCEXTERNVAR ({path=path, ty=evalTy context ty}, loc)
         :: declListRev
        )
      | RC.RCVAL (binds:(T.varInfo * rcexp) list, loc) =>
        let
          val (context, binds) = evalBindsSeq context binds
          val declListRev =
              case binds of
                nil => declListRev
              | _ => RC.RCVAL (binds, loc) :: declListRev
        in
          (context, declListRev)
        end
      | RC.RCVALPOLYREC
          (btvEnv,
           recbinds:{exp:rcexp, expTy:ty, var:T.varInfo} list,
           loc) =>
        let
          val btvEnv = evalBtvEnv context btvEnv
          val recbinds =
              map
                (fn {exp, expTy, var} =>
                    {var=evalTyVar context var,
                     expTy=evalTy context expTy,
                     exp=evalExp context exp}
                )
                recbinds
        in
          (context,
           RC.RCVALPOLYREC (btvEnv, recbinds, loc)
           :: declListRev
          )
        end
      | RC.RCVALREC (recbinds:{exp:rcexp, expTy:ty, var:T.varInfo} list,loc) =>
        let
          val recbinds =
              map
                (fn {exp, expTy, var} =>
                    {var=evalTyVar context var,
                     expTy=evalTy context expTy,
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
