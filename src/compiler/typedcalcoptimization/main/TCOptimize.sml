structure TPOptimize =
struct
local
  structure TC = TypedCalc
  structure TCU = TypedCalcUtils
  structure T = Types
  structure TRed = TyReduce
  structure TU = TypesUtils
  structure P = Printers
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

  val countMapRef = ref VarID.Map.empty : (TCAnalyse.count VarID.Map.map) ref
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
  type rule = {args:TC.tppat list, body:TC.tpexp}
  type btv = BoundTypeVarID.id
  type varId = VarID.id

  (* context *)
  type btvMap = ty BoundTypeVarID.Map.map
  val emptyBtvMap = BoundTypeVarID.Map.empty : btvMap
  type varMap = TC.tpexp VarID.Map.map
  val emptyVarMap = VarID.Map.empty : varMap
  type context = {varMap:varMap, btvMap:btvMap}
  val emptyContext = {varMap=emptyVarMap, btvMap=emptyBtvMap}

  fun bindExp ({varMap, btvMap}:context, var:varInfo, exp:TC.tpexp) =
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

  (* 20 is abot the size of isOneUse below
   *)
  val limitSize = 20
  fun isSmallValue tpexp =
      not (TCU.expansive tpexp) andalso TCSize.isSmallerExp (tpexp, limitSize)

  fun isOneUse ({id, ty, path}:T.varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME (TCAnalyse.FIN 1) => true
      | _ => false

  fun isInfUse ({id, ty, path}:T.varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME TCAnalyse.INF => true
      | _ => false

  fun isInline (var:T.varInfo, exp:TC.tpexp) =
      TCU.isAtom exp
      orelse
      (not (isInfUse var)) andalso isSmallValue exp
      orelse
      (not (TCU.expansive exp) andalso isOneUse var)

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
  (* eval terms *)
  fun evalVar 
        (context as {varMap,btvMap}:context) 
        (var as {id,...}:varInfo, loc:Loc.loc)
      : TC.tpexp
    = 
    case VarID.Map.find(varMap, id) of
        SOME tpexp => 
        let
          val (idMap, tpexp) = TCAlphaRename.copyExp tpexp
          val _ = renameCountMapRef idMap
        in
          tpexp
        end
        (* substitution is simultaneous both in terms and types *)
      | NONE =>  TC.TPVAR (evalTyVar context var, loc)

  fun evalExp (context:context) (exp:TC.tpexp) : TC.tpexp =
      let
        fun eval exp = evalExp context exp
        fun evalT ty = evalTy context ty
      in
        case exp of
          TC.TPAPPM {argExpList, funExp, funTy, loc} =>
          let
            val funExp = eval funExp
            val argExpList = map eval argExpList
          in
            case funExp of
              TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
              applyTerms context (argVarList, argExpList, bodyExp, loc)
            | _ => 
              TC.TPAPPM {argExpList = argExpList,
                         funExp = funExp,
                         funTy = evalT funTy,
                         loc = loc}
          end
        | TC.TPCASEM {caseKind, expList, expTyList, loc, ruleBodyTy, ruleList} =>
          TC.TPCASEM
            {caseKind = caseKind,
             expList = map eval expList,
             expTyList = map evalT expTyList,
             loc = loc,
             ruleBodyTy = evalT ruleBodyTy,
             ruleList = map (evalRule context) ruleList
            }
        | TC.TPCAST (tpexp, ty, loc) =>
          TC.TPCAST (eval tpexp, evalT ty, loc)
        | TC.TPCONSTANT {const, loc, ty} =>
          TC.TPCONSTANT {const=const, loc = loc, ty=evalT ty}
        | TC.TPDATACONSTRUCT {argExpOpt, argTyOpt, con:T.conInfo, instTyList, loc} =>
          TC.TPDATACONSTRUCT
            {argExpOpt = Option.map eval argExpOpt,
             argTyOpt =  Option.map evalT argTyOpt,
             con = evalConInfo context con,
             instTyList = map evalT instTyList,
             loc = loc
            }
        | TC.TPERROR => 
          exp
        | TC.TPEXNCONSTRUCT {argExpOpt, argTyOpt, exn:TC.exnCon, instTyList, loc} =>
          TC.TPEXNCONSTRUCT
            {argExpOpt = Option.map eval argExpOpt,
             argTyOpt =  Option.map evalT argTyOpt,
             exn = evalExnCon context exn,
             instTyList = map evalT instTyList,
             loc = loc
            }
        | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} =>
          TC.TPEXN_CONSTRUCTOR {exnInfo=evalExnInfo context exnInfo, loc=loc}
        | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
          TC.TPEXEXN_CONSTRUCTOR
            {exExnInfo=evalExExnInfo context exExnInfo, loc= loc}
        | TC.TPEXVAR ({path, ty}, loc) =>
          TC.TPEXVAR ({path=path, ty=evalT ty}, loc)
        | TC.TPFFIIMPORT {ffiTy, loc, ptrExp, stubTy} =>
          TC.TPFFIIMPORT
            {ffiTy = evalFfiTy context ffiTy,
             loc = loc,
             ptrExp = eval ptrExp,
             stubTy = evalT stubTy
            }
        | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
          TC.TPFNM
            {argVarList = map (evalTyVar context) argVarList,
             bodyExp = eval bodyExp,
             bodyTy = evalT bodyTy,
             loc = loc
            }
        | TC.TPGLOBALSYMBOL {kind, loc, name, ty} =>
          TC.TPGLOBALSYMBOL {kind=kind, loc=loc, name=name, ty=evalT ty}
        | TC.TPHANDLE {exnVar, exp, handler, loc} =>
          TC.TPHANDLE {exnVar=evalTyVar context exnVar,
                       exp=eval exp,
                       handler= eval handler,
                       loc=loc}
        | TC.TPLET {body:TC.tpexp list, decls, loc, tys} =>
          let
            val tys = map evalT tys
            val (context, decls) = evalDeclList context decls
            val body = map (evalExp context) body
          in
            case decls of
              nil => TC.TPSEQ {expList=body, expTyList=tys, loc=loc}
            | _ => TC.TPLET {body=body, decls=decls, loc=loc, tys=tys}
          end
        | TC.TPMODIFY {elementExp, elementTy, label, loc, recordExp, recordTy} =>
          (case recordExp of
             TC.TPRECORD {fields, loc, recordTy} =>
             if not (TCU.expansive recordExp) then
               eval 
                 (TC.TPRECORD {fields=LabelEnv.insert(fields, label, elementExp), 
                               loc=loc, 
                               recordTy=recordTy}
                 )
             else raise bug "non value term in recordExp"
           | _ => 
             TC.TPMODIFY
               {elementExp = eval elementExp,
                elementTy = evalT elementTy,
                label = label,
                loc = loc,
                recordExp = eval recordExp,
                recordTy = evalT recordTy}
          )
        | TC.TPMONOLET {binds:(T.varInfo * TC.tpexp) list, bodyExp, loc} =>
          let
            val (context, binds) = evalBindsSeq context binds
            val bodyExp = evalExp context bodyExp
          in
            case binds of
              nil => bodyExp
            | _ => TC.TPMONOLET {binds=binds, bodyExp=bodyExp, loc=loc}
          end
        | TC.TPOPRIMAPPLY {argExp, argTy, instTyList, loc, oprimOp:T.oprimInfo} =>
          TC.TPOPRIMAPPLY
            {argExp = eval argExp,
             argTy = evalT argTy,
             instTyList = map evalT instTyList,
             loc = loc,
             oprimOp = evalOprimInfo context oprimOp
            }
        | TC.TPPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
          TC.TPPOLY
            {btvEnv=evalBtvEnv context btvEnv,
             exp = eval exp,
             expTyWithoutTAbs = evalT expTyWithoutTAbs,
             loc = loc
            }
        | TC.TPPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
          TC.TPPOLYFNM
            {argVarList=map (evalTyVar context) argVarList,
             bodyExp=eval bodyExp,
             bodyTy=evalT bodyTy,
             btvEnv=evalBtvEnv context btvEnv,
             loc=loc
            }
        | TC.TPPRIMAPPLY {argExp, argTy, instTyList, loc, primOp:T.primInfo} =>
          TC.TPPRIMAPPLY
            {argExp=eval argExp,
             argTy = evalT argTy,
             instTyList=map evalT instTyList,
             loc=loc,
             primOp=evalPrimInfo context primOp
            }
        | TC.TPRAISE {exp, loc, ty} =>
          TC.TPRAISE {exp=eval exp, loc=loc, ty = evalT ty}
        | TC.TPRECORD {fields:TC.tpexp LabelEnv.map, loc, recordTy} =>
          TC.TPRECORD
            {fields=LabelEnv.map eval fields,
             loc=loc,
             recordTy=evalT recordTy
            }
        | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
          let
            val exp = eval exp
          in
            case exp of
              TC.TPRECORD {fields, loc, recordTy} =>
              if not (TCU.expansive exp) then
                (case LabelEnv.find (fields, label)  of
                   SOME exp => exp
                 | NONE => raise bug "label not found")
              else raise bug "non value term in a record"
            | _ => 
              TC.TPSELECT
                {exp=exp,
                 expTy=evalT expTy,
                 label=label,
                 loc=loc,
                 resultTy=evalT resultTy
                }
          end
        | TC.TPSEQ {expList, expTyList, loc} =>
          TC.TPSEQ
            {expList = map eval expList,
             expTyList = map evalT expTyList,
             loc = loc
            }
        | TC.TPSIZEOF (ty, loc) =>
          TC.TPSIZEOF (evalT ty, loc)
        | TC.TPSQLSERVER
            {loc,
             resultTy,
             schema:Types.ty LabelEnv.map LabelEnv.map,
             server:string
            } =>
          let
            val resultTy = evalT resultTy
            val schema = LabelEnv.map (LabelEnv.map evalT) schema
          in
            TC.TPSQLSERVER
              {loc=loc,
               resultTy=resultTy,
               schema=schema,
               server=server
              }
          end
        | TC.TPTAPP {exp, expTy, instTyList, loc} =>
          let
            val exp = eval exp
            val expTy = evalT expTy
            val instTyList = map evalT instTyList
          in
            case exp of
              TC.TPPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
              let
                val newContext = applyTys context (btvEnv, instTyList)
              in
                evalExp newContext exp
              end
            | TC.TPPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
              let
                val newContext = applyTys context (btvEnv, instTyList)
                val bodyExp = evalExp newContext bodyExp
                val bodyTy = evalTy newContext bodyTy
                val argVarList = map (evalTyVar newContext) argVarList
              in
                TC.TPFNM
                  {argVarList=argVarList, 
                   bodyExp=bodyExp, 
                   bodyTy=bodyTy, 
                   loc=loc}
              end
            | _ => 
              TC.TPTAPP {exp=exp,
                         expTy = expTy,
                         instTyList= instTyList,
                         loc = loc
                        }
          end
        | TC.TPVAR (varInfo, loc) =>
          evalVar context (varInfo, loc)
        (* the following should have been eliminate *)
        | TC.TPRECFUNVAR {arity, loc, var} =>
          raise bug "TPRECFUNVAR in eval"
      end
  and applyTerms
        ({varMap, btvMap}:context)
        (argVarList:T.varInfo list, argExpList:TC.tpexp list, body:TC.tpexp, loc) =
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
        | _ => TC.TPMONOLET {binds=binds, bodyExp=newBody, loc=loc}
      end
  and evalPat (context:context) (pat:TC.tppat) =
      case pat of
        TC.TPPATCONSTANT _ => pat
      | TC.TPPATDATACONSTRUCT {argPatOpt, conPat, instTyList, loc, patTy} =>
        TC.TPPATDATACONSTRUCT
        {argPatOpt = Option.map (evalPat context) argPatOpt,
         conPat=evalConInfo context conPat,
         instTyList=map (evalTy context) instTyList,
         loc=loc,
         patTy=evalTy context patTy
        }
      | TC.TPPATERROR (ty,loc) => TC.TPPATERROR (evalTy context ty,loc)
      | TC.TPPATEXNCONSTRUCT {argPatOpt, exnPat, instTyList, loc, patTy} =>
        TC.TPPATEXNCONSTRUCT
          {argPatOpt = Option.map (evalPat context) argPatOpt,
           exnPat=evalExnCon context exnPat,
           instTyList=map (evalTy context) instTyList,
           loc=loc,
           patTy=evalTy context patTy
          }
      | TC.TPPATLAYERED {asPat, loc, varPat} =>
        TC.TPPATLAYERED
          {asPat=evalPat context asPat,
           loc=loc,
           varPat=evalPat context varPat
          }
      | TC.TPPATRECORD {fields, loc, recordTy} =>
        TC.TPPATRECORD
          {fields=LabelEnv.map (evalPat context) fields,
           loc=loc,
           recordTy=evalTy context recordTy
          }
      | TC.TPPATVAR (var,loc) =>
        TC.TPPATVAR (evalTyVar context var,loc)
      | TC.TPPATWILD (ty,loc) => TC.TPPATWILD (evalTy context ty,loc)

  and evalRule (context:context) ({args, body}:rule) =
      {args=map (evalPat context) args, body=evalExp context body}

  and evalDecl (tpdecl:TC.tpdecl, (context:context, declListRev:TC.tpdecl list)) =
      case tpdecl of
        TC.TPEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
        let 
        val res = 
        (context,
         TC.TPEXD
           (map (fn {exnInfo, loc} =>
                    {exnInfo=evalExnInfo context exnInfo, loc=loc})
                exbinds,
            loc)
         ::declListRev
        )
        in res
        end
      | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val varExp = evalVar context (varInfo, loc)
          val declListRev =
              case varExp of
                TC.TPVAR (newVar, _) =>
                 TC.TPEXNTAGD ({exnInfo=evalExnInfo context exnInfo,
                                varInfo=newVar},
                               loc)
                 ::declListRev
              | newExp => 
                let
                  val newVar = TCU.newTCVarInfo (#ty varInfo)
                  val bindDecl = TC.TPVAL ([(newVar, newExp)], loc)
                  val newTpexntag =
                      TC.TPEXNTAGD ({exnInfo=evalExnInfo context exnInfo,
                                     varInfo=newVar},
                                    loc)
                in
                  newTpexntag :: bindDecl :: declListRev
                end
          val res = (context, declListRev)
        in
          res
        end
      | TC.TPEXPORTEXN (exnInfo, loc) =>
        (context,
         TC.TPEXPORTEXN (evalExnInfo context exnInfo, loc)
         :: declListRev
        )
      | TC.TPEXPORTVAR {internalVar, externalVar, loc} =>
        let
          val tpexp = evalVar context (internalVar, loc)
          val (internalVar, declListRev) = 
              case tpexp of
                TC.TPVAR (var,loc) => (var, declListRev)
              | _ => 
                let
                  val internalVar = evalTyVar context internalVar
                in
                  (internalVar,
                   TC.TPVAL ([(internalVar, tpexp)],loc) :: declListRev)
                end
          val externalVar=evalExVarInfo context externalVar
        in
          (context,
           TC.TPEXPORTVAR {internalVar=internalVar,
                           externalVar=externalVar,
                           loc=loc}
           :: declListRev
          )
        end
      | TC.TPEXPORTRECFUNVAR _ =>
        raise bug "TPEXPORTRECFUNVAR to optimize"
      | TC.TPEXTERNEXN ({path, ty}, loc) =>
        (context,
         TC.TPEXTERNEXN ({path=path, ty=evalTy context ty}, loc)
         :: declListRev
        )
      | TC.TPEXTERNVAR ({path, ty}, loc) =>
        (context,
         TC.TPEXTERNVAR ({path=path, ty=evalTy context ty}, loc)
         :: declListRev
        )
      | TC.TPVAL (binds:(T.varInfo * TC.tpexp) list, loc) =>
        let
          val (context, binds) = evalBindsSeq context binds
          val declListRev =
              case binds of
                nil => declListRev
              | _ => TC.TPVAL (binds, loc) :: declListRev
        in
          (context, declListRev)
        end
      | TC.TPVALPOLYREC
          (btvEnv,
           recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,
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
           TC.TPVALPOLYREC (btvEnv, recbinds, loc)
           :: declListRev
          )
        end
      | TC.TPVALREC (recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,loc) =>
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
           TC.TPVALREC (recbinds, loc)
           :: declListRev
          )
        end
      (* the following should have been eliminate *)
      | TC.TPFUNDECL _ => raise bug "TPFUNDECL not eliminated"
      | TC.TPPOLYFUNDECL _  => raise bug "TPPOLYFUNDECL not eliminated"

  and evalBind context ((var, exp), (newContext, bindsRev))  =
      let
        val var = evalTyVar context var
        val exp = evalExp context exp
        val (newContext, bindsRev) = 
            if isInline (var, exp) then
              (bindExp (newContext, var, exp), bindsRev)
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
              (bindExp (context, var, exp), bindsRev)
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
        val declList = TCRevealTy.revealTyTpdeclList declList
        val _ = countMapRef := TCAnalyse.analyseDeclList declList
        val (context, declList) = evalDeclList emptyContext declList
      in
        declList
      end
end
end
