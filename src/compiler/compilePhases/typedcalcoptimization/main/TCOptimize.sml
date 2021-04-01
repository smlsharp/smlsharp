(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure TPOptimize =
struct
local
  structure TC = TypedCalc
  structure TCU = TypedCalcUtils
  structure T = Types
  (* structure TU = TypesBasics *)
  structure P = Printers
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

  val countMapRef = ref VarID.Map.empty : (TCAnalyse.count VarID.Map.map) ref
  fun renameCountMapRef idMap =
      let
        val newCountMap =
            VarID.Map.foldli
              (fn (id, newId, newCountMap) =>
                  case VarID.Map.find (newCountMap, id) of
                    SOME count =>
                    VarID.Map.insert (#1 (VarID.Map.remove (newCountMap, id)),
                                      newId, count)
                  | NONE => newCountMap)
              (!countMapRef)
              idMap
      in
        countMapRef := newCountMap
      end

  (* declaration for type constraints *)
  type ty = T.ty
  type varInfo = T.varInfo
  type rule = {args:TC.tppat list, body:TC.tpexp}
  type btv = BoundTypeVarID.id
  type varId = VarID.id

  (* context *)
  type btvMap = ty BoundTypeVarID.Map.map
  val emptyBtvMap = BoundTypeVarID.Map.empty : btvMap
  type varMap = TC.tpexp VarID.Map.map
  val emptyVarMap = VarID.Map.empty : varMap

  fun bindExp (varMap:varMap, var:varInfo, exp:TC.tpexp) =
      VarID.Map.insert(varMap, #id var, exp)
      
  fun applyTys (btvEnv:T.btvEnv, instTyList:ty list) =
      let
        val btvList = BoundTypeVarID.Map.listKeys btvEnv
        val btvBinds = ListPair.zip (btvList, instTyList)
      in
        foldl
          (fn ((btv,ty), btvMap) =>
              BoundTypeVarID.Map.insert(btvMap, btv, ty))
          emptyBtvMap
          btvBinds
      end

  (* 20 is abot the size of isOneUse below  *)
  val limitSize = 20
  fun isSmallValue tpexp =
      not (TCU.expansive tpexp) andalso TCSize.isSmallerExp (tpexp, limitSize)

  fun isOneUse ({id, ty, path, opaque}:T.varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME (TCAnalyse.FIN 1) => true
      | _ => false

  fun isInfUse ({id, ty, path, opaque}:T.varInfo) =
      case VarID.Map.find(!countMapRef, id) of
        SOME TCAnalyse.INF => true
      | _ => false

  fun isInline (var as {opaque,...}:T.varInfo, exp:TC.tpexp) =
      not opaque andalso
      (
(*
       TCU.isAtom exp andalso isSmallValue exp
       orelse
*)
       (not (isInfUse var)) andalso isSmallValue exp
(*
       orelse
       (not (TCU.expansive exp) andalso isOneUse var)
*)
      )

  (* eval terms *)
  fun evalVar  (varMap:varMap) (var as {id,...}:varInfo) : TC.tpexp
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
      | NONE =>  TC.TPVAR var

  fun evalExp (varMap:varMap) (exp:TC.tpexp) : TC.tpexp =
      let
        fun eval exp = evalExp varMap exp
      in
        case exp of
          TC.TPAPPM {argExpList, funExp, funTy, loc} =>
          let
            val argExpList = map eval argExpList
          in
            case eval funExp of
              TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
              applyTerms varMap (argVarList, argExpList, bodyExp, loc)
            | funExp => 
              TC.TPAPPM {argExpList = argExpList,
                         funExp = funExp,
                         funTy = funTy,
                         loc = loc}
          end
        | TC.TPCASEM {caseKind, expList, expTyList, loc, ruleBodyTy, ruleList} =>
          TC.TPCASEM
            {caseKind = caseKind,
             expList = map eval expList,
             expTyList = expTyList,
             loc = loc,
             ruleBodyTy = ruleBodyTy,
             ruleList = evalRuleList varMap ruleList nil
            }
        | TC.TPSWITCH {exp, expTy, ruleList, defaultExp, ruleBodyTy, loc} =>
          let
            fun evalRule (r as {body, ...}) = r # {body = eval body}
          in
            TC.TPSWITCH
              {exp = eval exp,
               expTy = expTy,
               ruleList =
                 case ruleList of
                   TC.CONSTCASE rules => TC.CONSTCASE (map evalRule rules)
                 | TC.CONCASE rules => TC.CONCASE (map evalRule rules)
                 | TC.EXNCASE rules => TC.EXNCASE (map evalRule rules),
               defaultExp = eval defaultExp,
               ruleBodyTy = ruleBodyTy,
               loc = loc}
          end
        | TC.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
          TC.TPCATCH
            {catchLabel = catchLabel,
             tryExp = eval tryExp,
             argVarList = argVarList,
             catchExp = eval catchExp,
             resultTy = resultTy,
             loc = loc}
        | TC.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
          TC.TPTHROW
            {catchLabel = catchLabel,
             argExpList = map eval argExpList,
             resultTy = resultTy,
             loc = loc}
        | TC.TPCAST ((tpexp, expTy), ty, loc) =>
          TC.TPCAST ((eval tpexp, expTy), ty, loc)
        | TC.TPCONSTANT {const, loc, ty} => exp
        | TC.TPDATACONSTRUCT {argExpOpt=NONE, con:T.conInfo, instTyList, loc} => exp
        | TC.TPDATACONSTRUCT {argExpOpt=SOME argExp, con:T.conInfo, instTyList, loc} =>
          TC.TPDATACONSTRUCT
            {argExpOpt = SOME (eval argExp),
             con = con,
             instTyList =  instTyList,
             loc = loc
            }
        | TC.TPDYNAMICCASE {groupListTerm, groupListTy, dynamicTerm, dynamicTy, elemTy, ruleBodyTy, loc} => 
          TC.TPDYNAMICCASE {groupListTerm = eval groupListTerm,
                            groupListTy = groupListTy,
                            dynamicTerm = eval dynamicTerm,
                            dynamicTy = dynamicTy,
                            elemTy = elemTy,
                            ruleBodyTy = ruleBodyTy,
                            loc = loc}
        | TC.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
          TC.TPDYNAMICEXISTTAPP
            {existInstMap = eval existInstMap,
             exp = eval exp,
             expTy = expTy,
             instTyList = instTyList,
             loc = loc}
        | TC.TPERROR => exp
        | TC.TPEXNCONSTRUCT {argExpOpt, exn:TC.exnCon, loc} =>
          TC.TPEXNCONSTRUCT
            {argExpOpt = Option.map eval argExpOpt,
             exn = exn,
             loc = loc
            }
        | TC.TPEXNTAG {exnInfo, loc} =>
          TC.TPEXNTAG {exnInfo= exnInfo, loc=loc}
        | TC.TPEXEXNTAG {exExnInfo, loc} =>
          TC.TPEXEXNTAG
            {exExnInfo= exExnInfo, loc= loc}
        | TC.TPEXVAR ({path, ty},loc) => exp
        | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIFUN (ptrExp, ty), stubTy} =>
          TC.TPFFIIMPORT
            {ffiTy = ffiTy,
             loc = loc,
             funExp = TC.TPFFIFUN (eval ptrExp, ty),
             stubTy = stubTy
            }
        | TC.TPFFIIMPORT {ffiTy, loc, funExp as TC.TPFFIEXTERN _, stubTy} =>
          TC.TPFFIIMPORT
            {ffiTy = ffiTy,
             loc = loc,
             funExp = funExp,
             stubTy = stubTy
            }
        | TC.TPFOREIGNSYMBOL {name, ty, loc} => exp
        | TC.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
          TC.TPFOREIGNAPPLY
            {funExp = eval funExp,
             argExpList = map eval argExpList,
             attributes = attributes,
             resultTy = resultTy,
             loc = loc}
        | TC.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
          TC.TPCALLBACKFN
            {attributes = attributes,
             argVarList = argVarList,
             bodyExp = eval bodyExp,
             resultTy = resultTy,
             loc = loc}
        | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
          TC.TPFNM
            {argVarList = argVarList,
             bodyExp = eval bodyExp,
             bodyTy = bodyTy,
             loc = loc
            }
        | TC.TPHANDLE {exnVar, exp, handler, resultTy, loc} =>
          TC.TPHANDLE {exnVar= exnVar,
                       exp=eval exp,
                       handler= eval handler,
                       resultTy = resultTy,
                       loc=loc}
        | TC.TPLET {body, decls, loc} =>
          let
            val (varMap, decls) = evalDeclList decls (varMap, nil)
            val body = evalExp varMap body
          in
            case decls of
              nil => body
            | _ => TC.TPLET {body=body, decls=decls, loc=loc}
          end
        | TC.TPMODIFY {elementExp, elementTy, label, loc, recordExp, recordTy} =>
          (case recordExp of
             TC.TPRECORD {fields, loc, recordTy} =>
             if not (TCU.expansive recordExp) then
               eval 
                 (TC.TPRECORD {fields=RecordLabel.Map.insert(fields, label, elementExp), 
                               loc=loc, 
                               recordTy=recordTy}
                 )
             else raise bug "non value term in recordExp"
           | _ => 
             TC.TPMODIFY
               {elementExp = eval elementExp,
                elementTy = elementTy,
                label = label,
                loc = loc,
                recordExp = eval recordExp,
                recordTy = recordTy}
          )
        | TC.TPMONOLET {binds:(T.varInfo * TC.tpexp) list, bodyExp, loc} =>
          let
            val (varMap, binds) = evalBindsSeq binds (varMap, nil)
            val bodyExp = evalExp varMap bodyExp
          in
            case binds of
              nil => bodyExp
            | _ => TC.TPMONOLET {binds=binds, bodyExp=bodyExp, loc=loc}
          end
        | TC.TPOPRIMAPPLY {argExp, instTyList, loc, oprimOp:T.oprimInfo} =>
          TC.TPOPRIMAPPLY
            {argExp = eval argExp,
             instTyList = instTyList,
             loc = loc,
             oprimOp = oprimOp
            }
        | TC.TPPOLY {btvEnv, constraints, exp, expTyWithoutTAbs, loc} =>
          TC.TPPOLY
            {btvEnv= btvEnv,
             constraints = constraints,
             exp = eval exp,
             expTyWithoutTAbs = expTyWithoutTAbs,
             loc = loc
            }
        | TC.TPPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
          TC.TPPRIMAPPLY
            {argExp=eval argExp,
             instTyList=instTyList,
             loc=loc,
             primOp= primOp
            }
        | TC.TPRAISE {exp, loc, ty} =>
          TC.TPRAISE {exp=eval exp, loc=loc, ty = ty}
        | TC.TPRECORD {fields:TC.tpexp RecordLabel.Map.map, loc, recordTy} =>
          TC.TPRECORD
            {fields=RecordLabel.Map.map eval fields,
             loc=loc,
             recordTy=recordTy
            }
        | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
          let
            val exp = eval exp
          in
            case exp of
              TC.TPRECORD {fields, loc, recordTy} =>
              if not (TCU.expansive exp) then
                (case RecordLabel.Map.find (fields, label)  of
                   SOME exp => exp
                 | NONE => raise bug "label not found")
              else raise bug "non value term in a record"
            | _ => 
              TC.TPSELECT
                {exp=exp,
                 expTy=expTy,
                 label=label,
                 loc=loc,
                 resultTy=resultTy
                }
          end
        | TC.TPSIZEOF (ty, loc) => TC.TPSIZEOF (ty, loc)
        | TC.TPREIFYTY (ty, loc) => TC.TPREIFYTY (ty, loc)
        | TC.TPTAPP {exp, expTy, instTyList, loc} =>
          (case eval exp of
             TC.TPPOLY {btvEnv, constraints, exp, expTyWithoutTAbs, loc} =>
             let
               val btvMap = applyTys (btvEnv, instTyList)
               val exp = TCEvalTy.evalExp btvMap exp
             in
               eval exp
             end
           | exp =>
             TC.TPTAPP {exp=exp,
                        expTy = expTy,
                        instTyList= instTyList,
                        loc = loc
                       }
          )
        | TC.TPVAR varInfo =>
          evalVar varMap varInfo
        | TC.TPJOIN {isJoin, ty, args = (arg1, arg2), argtys, loc} =>
          TC.TPJOIN {ty = ty,
                     args = (eval arg1, eval arg2),
                     argtys = argtys,
                     isJoin = isJoin,
                     loc = loc}
        (* the following should have been eliminate *)
        | TC.TPRECFUNVAR {arity, var} =>
          raise bug "TPRECFUNVAR in eval"
        | TC.TPDYNAMIC {exp,ty,elemTy, coerceTy,loc} =>
          TC.TPDYNAMIC {exp=eval exp,
                        ty=ty,
                        elemTy = elemTy,
                        coerceTy=coerceTy,
                        loc = loc}
        | TC.TPDYNAMICIS {exp,ty,elemTy, coerceTy,loc} =>
          TC.TPDYNAMICIS {exp=eval exp,
                          ty=ty,
                          elemTy = elemTy,
                          coerceTy=coerceTy,
                          loc = loc}
        | TC.TPDYNAMICVIEW {exp,ty,elemTy, coerceTy,loc} =>
          TC.TPDYNAMICVIEW {exp=eval exp,
                            ty=ty,
                            elemTy = elemTy,
                            coerceTy=coerceTy,
                            loc = loc}
        | TC.TPDYNAMICNULL {ty, coerceTy,loc} =>
          TC.TPDYNAMICNULL {ty=ty,
                            coerceTy=coerceTy,
                            loc = loc}
        | TC.TPDYNAMICTOP {ty, coerceTy,loc} =>
          TC.TPDYNAMICTOP {ty=ty,
                           coerceTy=coerceTy,
                           loc = loc}
      end
  and applyTerms
        (varMap:varMap)
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
        val newBody = evalExp varMap body
      in
        case binds of
          nil => newBody
        | _ => TC.TPMONOLET {binds=binds, bodyExp=newBody, loc=loc}
      end

  and evalRule (varMap:varMap) ({args, body}:rule) =
      {args=args, body=evalExp varMap body}

  and evalRuleList (varMap:varMap) (nil: rule list) (ruleListRev:rule list) =
        List.rev ruleListRev
    | evalRuleList varMap (rule::rules) ruleListRev = 
      evalRuleList varMap rules ((evalRule varMap rule)::ruleListRev)
  
  and evalBindSeq ((var:T.varInfo, exp:TC.tpexp), 
                   (varMap:varMap, bindsRev:(T.varInfo * TC.tpexp) list)) =
      let
        val exp = evalExp varMap exp
        val (varMap, bindsRev) = 
            if isInline (var, exp) then
              (bindExp (varMap, var, exp), bindsRev)
            else (varMap, (var,exp)::bindsRev)
      in
        (varMap, bindsRev)
      end
  and evalBindsSeq (nil:(T.varInfo * TC.tpexp) list) 
                   (varMap:varMap, bindsRev:(T.varInfo * TC.tpexp) list) =
      (varMap, List.rev bindsRev)
    | evalBindsSeq (bind::binds) (varMap, bindsRev) =
      let
        val (varMap, bindsRev) = evalBindSeq (bind, (varMap, bindsRev))
      in
        evalBindsSeq binds (varMap, bindsRev)
      end

  and evalDecl (tpdecl:TC.tpdecl, (varMap:varMap, declListRev:TC.tpdecl list)) =
      case tpdecl of
        TC.TPEXD (exnInfo, loc) =>
        (varMap,
         TC.TPEXD
           (exnInfo,
            loc)
         ::declListRev
        )
      | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val varExp = evalVar varMap varInfo
          val declListRev =
              case varExp of
                TC.TPVAR newVar =>
                TC.TPEXNTAGD ({exnInfo=exnInfo,
                               varInfo=newVar},
                               loc)
                 ::declListRev
              | newExp => 
                let
                  val newVar = TCU.newTCVarInfo loc (#ty varInfo)
                  val bindDecl = TC.TPVAL ((newVar, newExp), loc)
                  val newTpexntag =
                      TC.TPEXNTAGD ({exnInfo=exnInfo,
                                     varInfo=newVar},
                                    loc)
                in
                  newTpexntag :: bindDecl :: declListRev
                end
        in
          (varMap, declListRev)
        end
      | TC.TPEXPORTEXN exnInfo =>
        (varMap, TC.TPEXPORTEXN exnInfo :: declListRev)
      | TC.TPEXPORTVAR {var, exp} =>
        (varMap,
         TC.TPEXPORTVAR {var = var, exp = evalExp varMap exp} :: declListRev)
      | TC.TPEXTERNEXN ({path, ty}, provider) => (varMap,  tpdecl :: declListRev)
      | TC.TPBUILTINEXN {path, ty} => (varMap,  tpdecl :: declListRev)
      | TC.TPEXTERNVAR ({path, ty}, provider) => (varMap, tpdecl :: declListRev)
      | TC.TPVAL (bind:(T.varInfo * TC.tpexp), loc) =>
        let
          val (varMap, binds) = evalBindSeq (bind, (varMap, nil))
          val declListRev =
              map (fn x => TC.TPVAL (x, loc)) binds @ declListRev
        in
          (varMap, declListRev)
        end
      | TC.TPVALPOLYREC
          {btvEnv,
           constraints,
           recbinds:{exp:TC.tpexp, var:T.varInfo} list,
           loc} =>
        let
          val recbinds =
              map
                (fn {exp, var} =>
                    {var= var, exp=evalExp varMap exp}
                )
                recbinds
        in
          (varMap,
           TC.TPVALPOLYREC {btvEnv=btvEnv, constraints=constraints, recbinds=recbinds, loc=loc}
           :: declListRev
          )
        end
      | TC.TPVALREC (recbinds:{exp:TC.tpexp, var:T.varInfo} list,loc) =>
        let
          val recbinds =
              map
                (fn {exp, var} =>
                    {var= var, exp=evalExp varMap exp}
                )
                recbinds
        in
          (varMap,
           TC.TPVALREC (recbinds, loc)
           :: declListRev
          )
        end
      (* the following should have been eliminate *)
      | TC.TPFUNDECL _ => raise bug "TPFUNDECL not eliminated"
      | TC.TPPOLYFUNDECL _  => raise bug "TPPOLYFUNDECL not eliminated"

  and evalDeclList (nil:TC.tpdecl list) (varMap:varMap, declListRev:TC.tpdecl list) =
      (varMap, List.rev declListRev)
    | evalDeclList (decl::decls) (varMap, declListRev) =
      let
        val (varMap, declListRev) = evalDecl (decl, (varMap, declListRev))
      in
        evalDeclList decls (varMap, declListRev)
      end

in
  fun optimize declList =
      let
        val _ = countMapRef := TCAnalyse.analyseDeclList declList
        val (_, decls) = evalDeclList declList (emptyVarMap, nil)
      in
        decls
      end
end
end
