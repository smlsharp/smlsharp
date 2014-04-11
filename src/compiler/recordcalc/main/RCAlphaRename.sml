structure RCAlphaRename =
struct
local
 
  structure RC = RecordCalc
  structure TC = TypedCalc
  structure T = Types
  structure P = Printers
  fun bug s = Bug.Bug ("RCAlphaRename: " ^ s)

  val print = fn s => if !Bug.printInfo then print s else ()
  fun printRcexp rcexp = 
      print (Bug.prettyPrint (RC.format_rcexp nil rcexp))

  exception DuplicateVar
  exception DuplicateBtv


  type ty = T.ty
  type varInfo = RC.varInfo

  type path = RC.path
  type longsymbol = Symbol.longsymbol
  type btvKind = {tvarKind : T.tvarKind, eqKind : T.eqKind}
  type btvEnv = btvKind BoundTypeVarID.Map.map
  type rcexp = RC.rcexp

  type btvMap = BoundTypeVarID.id BoundTypeVarID.Map.map
  val emptyBtvMap = BoundTypeVarID.Map.empty
  type varMap = VarID.id VarID.Map.map
  val emptyVarMap = VarID.Map.empty
  type context = {varMap:varMap, btvMap:btvMap}
  val emptyContext = {varMap=emptyVarMap, btvMap=emptyBtvMap}

  fun copyTy (context:context) (ty:ty) = 
      TyAlphaRename.copyTy (#btvMap context) ty
      handle exn =>
             (P.print "TyAlphaRename exception";
              P.printTy ty;
              P.print "\n";
              raise exn
             )
  fun newBtvEnv ({varMap, btvMap}:context) (btvEnv:btvEnv) =
      let
        val (btvMap, btvEnv) = 
            TyAlphaRename.newBtvEnv btvMap btvEnv
      in
        ({btvMap=btvMap, varMap=varMap}, btvEnv)
      end
  fun copyExVarInfo context {path:path, ty:ty} =
      {path=path, ty=copyTy context ty}
  fun copyPrimInfo context {primitive : BuiltinPrimitive.primitive, ty : ty} =
      {primitive=primitive, ty=copyTy context ty}
  fun copyOprimInfo context {ty : ty, path : path, id: OPrimID.id} =
      {ty=copyTy context ty, path=path,id=id}
  fun copyConInfo context {path: path, ty: ty, id: ConID.id} =
      {path=path, ty=copyTy context ty, id=id}
  fun copyExnInfo context {path: path, ty: ty, id: ExnID.id} =
      {path=path, ty=copyTy context ty, id=id}
  fun copyExExnInfo context {path: path, ty: ty} =
      {path=path, ty=copyTy context ty}
  fun copyExnCon context exnCon =
      case exnCon of
        RC.EXEXN exExnInfo => RC.EXEXN (copyExExnInfo context exExnInfo)
      | RC.EXN exnInfo => RC.EXN (copyExnInfo context exnInfo)
  fun copyFfiTy context ffiTy =
      case ffiTy of
        TC.FFIBASETY (ty, loc) =>
        TC.FFIBASETY (copyTy context ty, loc)
      | TC.FFIFUNTY (attribOpt (* FFIAttributes.attributes option *),
                     ffiTyList1,
                     ffiTyList2,
                     ffiTyList3,loc) =>
        TC.FFIFUNTY (attribOpt,
                     map (copyFfiTy context) ffiTyList1,
                     Option.map (map (copyFfiTy context)) ffiTyList2,
                     map (copyFfiTy context) ffiTyList3,
                     loc)
      | TC.FFIRECORDTY (fields:(string * TC.ffiTy) list,loc) =>
        TC.FFIRECORDTY
          (map (fn (l,ty)=>(l, copyFfiTy context ty)) fields,loc)

  val emptyVarIdMap = VarID.Map.empty : VarID.id VarID.Map.map
  val varIdMapRef = ref emptyVarIdMap : (VarID.id VarID.Map.map) ref
  fun addSubst (oldId, newId) = varIdMapRef := VarID.Map.insert(!varIdMapRef, oldId, newId)

  type varInfo = {path:path, id:VarID.id, ty:ty}
  (* alpha-rename terms *)
  fun newId ({varMap, btvMap}:context) id =
      let
        val newId = VarID.generate()
        val _ = addSubst (id, newId)
        val varMap =
            VarID.Map.insertWith
              (fn _ => raise DuplicateVar)
              (varMap, id, newId)
      in
        ({varMap=varMap, btvMap=btvMap}, newId)
      end
  fun newVar (context:context) ({path, id, ty}:varInfo) =
      let
        val ty = copyTy context ty
        val (context, newId) =
            newId context id
            handle DuplicateVar =>
                   (P.printPath path;
                    P.print "\n";
                    raise bug "duplicate id in IDCalcUtils"
                   )
      in
        (context, {path=path, id=newId, ty=ty})
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

  fun evalVar (context as {varMap, btvMap}:context) ({path, id, ty}:varInfo) =
      let
        val ty = copyTy context ty
        val id =
            case VarID.Map.find(varMap, id) of
              SOME id => id
            | NONE => id
      in
        {path=path, id=id, ty=ty}
      end
      handle DuplicateBtv =>
             (P.print "DuplicateBtv in evalVar\n";
              P.printPath path;
              P.print "\n";
              P.printTy ty;
              P.print "\n";
              raise bug "DuplicateBtv in evalVar")
  fun copyExp (context:context) (exp:RC.rcexp) =
      let
        fun copy exp = copyExp context exp
        fun copyT ty = copyTy context ty
      in
        (
        case exp of
          RC.RCAPPM {argExpList, funExp, funTy, loc} =>
          RC.RCAPPM {argExpList = map copy argExpList,
                     funExp = copy funExp,
                     funTy = copyT funTy,
                     loc = loc}
        | RC.RCCASE  {defaultExp:rcexp, exp:rcexp, expTy:Types.ty, loc:Loc.loc,
                      ruleList:(RC.conInfo * varInfo option * rcexp) list,
                      resultTy} =>
          RC.RCCASE  {defaultExp=copy defaultExp, 
                      exp=copy exp, 
                      expTy=copyT expTy, 
                      loc=loc,
                      ruleList = 
                      map (fn (con, varOpt, exp) =>
                              let
                                val (newContext, varOpt) =
                                    case varOpt of
                                      NONE => (context, NONE)
                                    | SOME var => 
                                      let
                                        val (newContext, var) = 
                                            newVar context var
                                      in
                                        (newContext, SOME var)
                                      end
                              in
                                (copyConInfo context con,
                                 varOpt,
                                 copyExp newContext exp)
                              end
                          ) ruleList,
                      resultTy=resultTy
                     }
        | RC.RCCAST ((tpexp, expTy), ty, loc) =>
          RC.RCCAST ((copy tpexp, copyT expTy), copyT ty, loc)
        | RC.RCCONSTANT {const, loc, ty} =>
          RC.RCCONSTANT {const=const, loc = loc, ty=copyT ty}
        | RC.RCDATACONSTRUCT {argExpOpt, argTyOpt, con:RC.conInfo, instTyList, loc} =>
          RC.RCDATACONSTRUCT
            {argExpOpt = Option.map copy argExpOpt,
             argTyOpt = Option.map copyT argTyOpt, 
             con = copyConInfo context con,
             instTyList = map copyT instTyList,
             loc = loc
            }
        | RC.RCEXNCASE {defaultExp:rcexp, exp:rcexp, expTy:ty, loc:Loc.loc,
                        ruleList:(RC.exnCon * varInfo option * rcexp) list,
                        resultTy} =>
          RC.RCEXNCASE {defaultExp=copy defaultExp, 
                        exp=copy exp,
                        expTy=copyT expTy, 
                        loc=loc,
                        ruleList = 
                        map (fn (con, varOpt, exp) =>
                                (copyExnCon context con,
                                 Option.map (evalVar context) varOpt,
                                 copy exp)
                            ) ruleList,
                        resultTy=resultTy
                       }
        | RC.RCEXNCONSTRUCT {argExpOpt, exn:RC.exnCon, instTyList, loc} =>
          RC.RCEXNCONSTRUCT
            {argExpOpt = Option.map copy argExpOpt,
             exn = copyExnCon context exn,
             instTyList = map copyT instTyList,
             loc = loc
            }
        | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} =>
          RC.RCEXN_CONSTRUCTOR {exnInfo=copyExnInfo context exnInfo , loc=loc}
        | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
          RC.RCEXEXN_CONSTRUCTOR
            {exExnInfo=copyExExnInfo context exExnInfo,
             loc= loc}
        | RC.RCCALLBACKFN {attributes, resultTy, argVarList, bodyExp:rcexp,
                           loc:Loc.loc} =>
          let
            val resultTy = Option.map (copyTy context) resultTy
            val (context, argVarList) = newVars context argVarList
            val bodyExp = copyExp context bodyExp
          in
            RC.RCCALLBACKFN
              {attributes = attributes,
               resultTy = resultTy,
               argVarList = argVarList,
               bodyExp = bodyExp,
               loc = loc}
          end
        | RC.RCEXVAR exVar =>
          RC.RCEXVAR (copyExVarInfo context exVar)
        | RC.RCFFI (rcffiexp, ty, loc) =>
          RC.RCFFI (copyRcffiexp context rcffiexp, 
                    copyT ty, 
                    loc)
        | RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
          let
            val bodyTy = copyT bodyTy
            val (context, argVarList) = newVars context argVarList
            val bodyExp = copyExp context bodyExp
          in
            RC.RCFNM
              {argVarList = argVarList,
               bodyExp = bodyExp,
               bodyTy = bodyTy,
               loc = loc}
          end
        | RC.RCFOREIGNAPPLY {argExpList:rcexp list,
                             attributes, resultTy, funExp:rcexp,
                             loc:Loc.loc} =>
          RC.RCFOREIGNAPPLY
            {argExpList = map copy argExpList,
             attributes = attributes,
             funExp=copy funExp,
             resultTy = resultTy,
             loc=loc}
        | RC.RCFOREIGNSYMBOL {loc, name, ty} =>
          RC.RCFOREIGNSYMBOL {loc=loc, name=name, ty=copyT ty}
        | RC.RCHANDLE {exnVar, exp, handler, resultTy, loc} =>
          let
            val (context, exnVar) = newVar context exnVar
          in
            RC.RCHANDLE 
              {exnVar=exnVar, 
               exp=copy exp, 
               handler=copyExp context handler, 
               resultTy= copyT resultTy,
               loc=loc}
          end
        | RC.RCINDEXOF (string, ty, loc) =>
          RC.RCINDEXOF (string, copyT ty, loc)
        | RC.RCLET {body:rcexp list, decls, loc, tys} =>
          let
            val (context, decls) = copyDeclList context decls
          in
            RC.RCLET {body=map (copyExp context) body,
                      decls=decls,
                      loc=loc,
                      tys=map copyT tys}
          end
        | RC.RCMODIFY {elementExp, elementTy, indexExp, label, loc, recordExp, recordTy} =>
          RC.RCMODIFY
            {elementExp = copy elementExp,
             elementTy = copyT elementTy,
             indexExp = copy indexExp,
             label = label,
             loc = loc,
             recordExp = copy recordExp,
             recordTy = copyT recordTy}
        | RC.RCMONOLET {binds:(varInfo * rcexp) list, bodyExp, loc} =>
          let
            val (context, binds) = copyBinds context binds
          in
            RC.RCMONOLET {binds=binds, bodyExp=copyExp context bodyExp, loc=loc}
          end
        | RC.RCOPRIMAPPLY {argExp, instTyList, loc, oprimOp:RC.oprimInfo} =>
          RC.RCOPRIMAPPLY
            {argExp = copy argExp,
             instTyList = map copyT instTyList,
             loc = loc,
             oprimOp = copyOprimInfo context oprimOp
            }
        | RC.RCPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
          (
          let
            val (context, btvEnv) = newBtvEnv context btvEnv
          in
            RC.RCPOLY
              {btvEnv=btvEnv,
               exp = copyExp context exp,
               expTyWithoutTAbs = copyTy context expTyWithoutTAbs,
               loc = loc
              }
          end
          handle DuplicateBtv =>
                raise DuplicateBtv
          )

        | RC.RCPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
          (
          let
            val (context, btvEnv) = newBtvEnv context btvEnv
            val (context, argVarList) = newVars context argVarList
          in
            RC.RCPOLYFNM
              {argVarList=argVarList,
               bodyExp=copyExp context bodyExp,
               bodyTy=copyTy context bodyTy,
               btvEnv=btvEnv,
               loc=loc
              }
          end
          handle DuplicateBtv =>
                raise DuplicateBtv
          )
        | RC.RCPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
          RC.RCPRIMAPPLY
            {argExp = copy argExp,
             instTyList = map copyT instTyList,
             loc = loc,
             primOp = copyPrimInfo context primOp
            }
        | RC.RCRAISE {exp, loc, ty} =>
          RC.RCRAISE {exp= copy exp, loc=loc, ty = copyT ty}
        | RC.RCRECORD {fields:rcexp LabelEnv.map, loc, recordTy} =>
          RC.RCRECORD
            {fields=LabelEnv.map copy fields,
             loc=loc,
             recordTy=copyT recordTy}
        | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} =>
          RC.RCSELECT
            {exp=copy exp,
             expTy=copyT expTy,
             indexExp=copy indexExp, 
             label=label,
             loc=loc,
             resultTy=copyT resultTy
            }
        | RC.RCSEQ {expList, expTyList, loc} =>
          RC.RCSEQ
            {expList = map copy expList,
             expTyList = map copyT expTyList,
             loc = loc
            }
        | RC.RCSIZEOF (ty, loc) =>
          RC.RCSIZEOF (copyT ty, loc)
        | RC.RCSWITCH {branches:(Absyn.constant * rcexp) list, defaultExp:rcexp,
                       expTy:Types.ty, loc:Loc.loc, switchExp:rcexp,
                       resultTy} =>
          RC.RCSWITCH
            {branches = 
             map (fn (const, exp) => (const, copy exp)) branches, 
             defaultExp=copy defaultExp,
             expTy=copyT expTy, 
             loc=loc, 
             switchExp= copy switchExp,
             resultTy=resultTy}
        | RC.RCTAGOF (ty, loc) => RC.RCTAGOF (copyT ty, loc)
        | RC.RCTAPP {exp, expTy, instTyList, loc} =>
          RC.RCTAPP {exp=copy exp,
                     expTy = copyT expTy,
                     instTyList=map copyT instTyList,
                     loc = loc
                    }
        | RC.RCVAR varInfo =>
          RC.RCVAR (evalVar context varInfo)
        )
          handle DuplicateBtv =>
                 raise bug "DuplicateBtv in copyExp copyExp"
    end
  and copyBranch context (constant,rcexp) =
      (constant, copyExp context rcexp)
   
  and copyRcffiexp context (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, funExp}) =
      RC.RCFFIIMPORT
        {ffiTy = copyFfiTy context ffiTy,
         funExp= case funExp of
                   RC.RCFFIFUN exp => RC.RCFFIFUN (copyExp context exp)
                 | RC.RCFFIEXTERN _ => funExp}
  and copyDecl context tpdecl =
      case tpdecl of
        RC.RCEXD (exbinds:{exnInfo:RC.exnInfo, loc:Loc.loc} list, loc) =>
        (context,
         RC.RCEXD
           (map (fn {exnInfo, loc} =>
                    {exnInfo=copyExnInfo context exnInfo, loc=loc})
                exbinds,
            loc)
        )
      | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
        (context,
         RC.RCEXNTAGD ({exnInfo=copyExnInfo context exnInfo,
                        varInfo=evalVar context varInfo},
                       loc)
        )
      | RC.RCEXPORTEXN exnInfo =>
        (context,
         RC.RCEXPORTEXN (copyExnInfo context exnInfo)
        )
      | RC.RCEXPORTVAR varInfo =>
        (context,
         RC.RCEXPORTVAR (evalVar context varInfo)
        )
      | RC.RCEXTERNEXN {path, ty} =>
        (context,
         RC.RCEXTERNEXN {path=path, ty=copyTy context ty}
        )
      | RC.RCEXTERNVAR {path, ty} =>
        (context,
         RC.RCEXTERNVAR {path=path, ty=copyTy context ty}
        )
      | RC.RCVAL (binds:(varInfo * rcexp) list, loc) =>
        let
          val (context, binds) = copyBinds context binds
        in
          (context, RC.RCVAL (binds, loc))
        end
      | RC.RCVALPOLYREC
          (btvEnv,
           recbinds:{exp:rcexp, expTy:ty, var:varInfo} list,
           loc) =>
        (
        let
          val (newContext as {varMap, btvMap}, btvEnv) = newBtvEnv context btvEnv
          val vars = map #var recbinds
          val (newContext as {varMap, btvMap}, vars) = newVars newContext vars
          val varRecbindList = ListPair.zip (vars, recbinds)
          val recbinds =
              map
                (fn (var, {exp, expTy, var=_}) =>
                    {var=var,
                     expTy=copyTy newContext expTy,
                     exp=copyExp newContext exp}
                )
                varRecbindList
        in
          ({varMap=varMap, btvMap = #btvMap context},
           RC.RCVALPOLYREC (btvEnv, recbinds, loc))
        end
          handle DuplicateBtv =>
                raise bug "TPVALPOLYREC"
        )
      | RC.RCVALREC (recbinds:{exp:rcexp, expTy:ty, var:varInfo} list,loc) =>
        let
          val vars = map #var recbinds
          val (context, vars) = newVars context vars
          val varRecbindList = ListPair.zip (vars, recbinds)
          val recbinds =
              map
                (fn (var, {exp, expTy, var=_}) =>
                    {var=var,
                     expTy=copyTy context expTy,
                     exp=copyExp context exp}
                )
                varRecbindList
        in
          (context, RC.RCVALREC (recbinds, loc))
        end
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
        val exp = copyExp emptyContext exp
      in
        (!varIdMapRef, exp)
      end
      handle exn => 
             (P.print "RCAlphaRename; exception\n";
              printRcexp exp;
              P.print "\n";
              raise exn)
end
end
