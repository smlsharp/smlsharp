structure TCAlphaRename =
struct
local
  structure TC = TypedCalc
  structure T = Types
  structure P = Printers
  fun bug s = Control.Bug ("AlphaRename: " ^ s)

  exception DuplicateVar
  exception DuplicateBtv

  type ty = T.ty
  type path = T.path
  type btvKind = {tvarKind : T.tvarKind, eqKind : T.eqKind}
  type btvEnv = btvKind BoundTypeVarID.Map.map

  type btvMap = BoundTypeVarID.id BoundTypeVarID.Map.map
  val emptyBtvMap = BoundTypeVarID.Map.empty
  type varMap = VarID.id VarID.Map.map
  val emptyVarMap = VarID.Map.empty
  type context = {varMap:varMap, btvMap:btvMap}
  val emptyContext = {varMap=emptyVarMap, btvMap=emptyBtvMap}

  fun copyTy (context:context) (ty:ty) = TyAlphaRename.copyTy (#btvMap context) ty
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
        TC.EXEXN exExnInfo => TC.EXEXN (copyExExnInfo context exExnInfo)
      | TC.EXN exnInfo => TC.EXN (copyExnInfo context exnInfo)
  fun copyFfiTy context ffiTy =
      case ffiTy of
        TC.FFIBASETY (ty, loc) =>
        TC.FFIBASETY (copyTy context ty, loc)
      | TC.FFIFUNTY (attribOpt (* Absyn.ffiAttributes option *),
                     ffiTyList1,
                     ffiTyList2,loc) =>
        TC.FFIFUNTY (attribOpt,
                     map (copyFfiTy context) ffiTyList1,
                     map (copyFfiTy context) ffiTyList2,
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
          val instTyList = map (copyTy context) instTyList
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
          {argPatOpt, exnPat:TC.exnCon, instTyList, loc, patTy} =>
        let
          val instTyList = map (copyTy context) instTyList
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
              instTyList = instTyList,
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
      | TC.TPPATRECORD {fields:TC.tppat LabelEnv.map, loc, recordTy} =>
        let
          val recordTy = copyTy context recordTy
          val (context, fields) =
              LabelEnv.foldli
              (fn (label, pat, (context, fields)) =>
                  let
                    val (context, pat) = copyPat context pat
                  in
                    (context, LabelEnv.insert(fields, label, pat))
                  end
              )
              (context, LabelEnv.empty)
              fields
        in
          (context, TC.TPPATRECORD {fields=fields, loc=loc, recordTy=recordTy})
        end
      | TC.TPPATVAR (varInfo, loc) =>
        let
          val (context, varInfo) = newVar context varInfo
        in
          (context, TC.TPPATVAR (varInfo, loc))
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
        | TC.TPCAST (tpexp, ty, loc) =>
          TC.TPCAST (copy tpexp, copyT ty, loc)
        | TC.TPCONSTANT {const, loc, ty} =>
          TC.TPCONSTANT {const=const, loc = loc, ty=copyT ty}
        | TC.TPDATACONSTRUCT {argExpOpt, argTyOpt, con:T.conInfo, instTyList, loc} =>
          TC.TPDATACONSTRUCT
            {argExpOpt = Option.map copy argExpOpt,
             argTyOpt = Option.map copyT argTyOpt,
             con = copyConInfo context con,
             instTyList = map copyT instTyList,
             loc = loc
            }
        | TC.TPERROR => exp
        | TC.TPEXNCONSTRUCT {argExpOpt, argTyOpt, exn:TC.exnCon, instTyList, loc} =>
          TC.TPEXNCONSTRUCT
            {argExpOpt = Option.map copy argExpOpt,
             argTyOpt = Option.map copyT argTyOpt,
             exn = copyExnCon context exn,
             instTyList = map copyT instTyList,
             loc = loc
            }
        | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} =>
          TC.TPEXN_CONSTRUCTOR {exnInfo=copyExnInfo context exnInfo , loc=loc}
        | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
          TC.TPEXEXN_CONSTRUCTOR
            {exExnInfo=copyExExnInfo context exExnInfo,
             loc= loc}
        | TC.TPEXVAR ({path, ty}, loc) =>
          TC.TPEXVAR ({path=path, ty=copyT ty}, loc)
        | TC.TPFFIIMPORT {ffiTy, loc, ptrExp, stubTy} =>
          TC.TPFFIIMPORT
            {ffiTy = copyFfiTy context ffiTy,
             loc = loc,
             ptrExp = copy ptrExp,
             stubTy = copyT stubTy
            }
        | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
          let
            val bodyTy = copyT bodyTy
            val (context, argVarList) = newVars context argVarList
            val bodyExp = copyExp context bodyExp
          in
            TC.TPFNM
              {argVarList = argVarList,
               bodyExp = bodyExp,
               bodyTy = bodyTy,
               loc = loc
              }
          end
        | TC.TPGLOBALSYMBOL {kind, loc, name, ty} =>
          TC.TPGLOBALSYMBOL {kind=kind, loc=loc, name=name, ty=copyT ty}
        | TC.TPHANDLE {exnVar, exp, handler, loc} =>
          let
            val (context, exnVar) = newVar context exnVar
          in
            TC.TPHANDLE 
              {exnVar=exnVar, 
               exp=copy exp, 
               handler=copyExp context handler, 
               loc=loc}
          end
        | TC.TPLET {body:TC.tpexp list, decls, loc, tys} =>
          let
            val (context, decls) = copyDeclList context decls
          in
            TC.TPLET {body=map (copyExp context) body,
                      decls=decls,
                      loc=loc,
                      tys=map copyT tys}
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
        | TC.TPOPRIMAPPLY {argExp, argTy, instTyList, loc, oprimOp:T.oprimInfo} =>
          TC.TPOPRIMAPPLY
            {argExp = copy argExp,
             argTy = copyT argTy,
             instTyList = map copyT instTyList,
             loc = loc,
             oprimOp = copyOprimInfo context oprimOp
            }
        | TC.TPPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
          (
          let
            val (context, btvEnv) = newBtvEnv context btvEnv
          in
            TC.TPPOLY
              {btvEnv=btvEnv,
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

        | TC.TPPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
          (
          let
            val (context, btvEnv) = newBtvEnv context btvEnv
            val (context, argVarList) = newVars context argVarList
          in
            TC.TPPOLYFNM
              {argVarList=argVarList,
               bodyExp=copyExp context bodyExp,
               bodyTy=copyTy context bodyTy,
               btvEnv=btvEnv,
               loc=loc
              }
          end
          handle DuplicateBtv =>
                 (P.print "DuplicateBtv in TPPOLYFNM\n";
                  P.printTpexp exp;
                  P.print "\n";
                raise DuplicateBtv)
          )
        | TC.TPPRIMAPPLY {argExp, argTy, instTyList, loc, primOp:T.primInfo} =>
          TC.TPPRIMAPPLY
            {argExp = copy argExp,
             argTy = copyT argTy,
             instTyList = map copyT instTyList,
             loc = loc,
             primOp = copyPrimInfo context primOp
            }
        | TC.TPRAISE {exp, loc, ty} =>
          TC.TPRAISE {exp= copy exp, loc=loc, ty = copyT ty}
        | TC.TPRECORD {fields:TC.tpexp LabelEnv.map, loc, recordTy} =>
          TC.TPRECORD
            {fields=LabelEnv.map copy fields,
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
        | TC.TPSEQ {expList, expTyList, loc} =>
          TC.TPSEQ
            {expList = map copy expList,
             expTyList = map copyT expTyList,
             loc = loc
            }
        | TC.TPSIZEOF (ty, loc) =>
          TC.TPSIZEOF (copyT ty, loc)
        | TC.TPSQLSERVER
            {loc,
             resultTy,
             schema:Types.ty LabelEnv.map LabelEnv.map,
             server:string
            } =>
            TC.TPSQLSERVER
              {loc=loc,
               resultTy=copyT resultTy,
               schema=
               LabelEnv.map
                 (LabelEnv.map copyT)
                 schema,
               server=server
              }
        | TC.TPTAPP {exp, expTy, instTyList, loc} =>
          TC.TPTAPP {exp=copy exp,
                     expTy = copyT expTy,
                     instTyList=map copyT instTyList,
                     loc = loc
                    }
        | TC.TPVAR (varInfo, loc) =>
          TC.TPVAR (evalVar context varInfo, loc)
        (* the following should have been eliminate *)
        | TC.TPRECFUNVAR {arity, loc, var} =>
          raise bug "TPRECFUNVAR in copy"
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
        TC.TPEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
        (context,
         TC.TPEXD
           (map (fn {exnInfo, loc} =>
                    {exnInfo=copyExnInfo context exnInfo, loc=loc})
                exbinds,
            loc)
        )
      | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        (context,
         TC.TPEXNTAGD ({exnInfo=copyExnInfo context exnInfo,
                        varInfo=evalVar context varInfo},
                       loc)
        )
      | TC.TPEXPORTEXN (exnInfo, loc) =>
        (context,
         TC.TPEXPORTEXN (copyExnInfo context exnInfo, loc)
        )
      | TC.TPEXPORTVAR {internalVar, externalVar, loc} =>
        (context,
         TC.TPEXPORTVAR {internalVar= evalVar context internalVar,
                         externalVar= copyExVarInfo context externalVar,
                         loc=loc}
        )
      | TC.TPEXPORTRECFUNVAR _ =>
        raise bug "TPEXPORTRECFUNVAR to AlphaRename"
      | TC.TPEXTERNEXN ({path, ty}, loc) =>
        (context,
         TC.TPEXTERNEXN ({path=path, ty=copyTy context ty}, loc)
        )
      | TC.TPEXTERNVAR ({path, ty}, loc) =>
        (context,
         TC.TPEXTERNVAR ({path=path, ty=copyTy context ty}, loc)
        )
      | TC.TPVAL (binds:(T.varInfo * TC.tpexp) list, loc) =>
        let
          val (context, binds) = copyBinds context binds
        in
          (context, TC.TPVAL (binds, loc))
        end
      | TC.TPVALPOLYREC
          (btvEnv,
           recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,
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
           TC.TPVALPOLYREC (btvEnv, recbinds, loc))
        end
          handle DuplicateBtv =>
                 (P.print "DuplicateBtv in TPVALPOLYREC\n";
                  P.printTpdecl tpdecl;
                  P.print "\n";
                raise bug "TPVALPOLYREC")
        )
      | TC.TPVALREC (recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,loc) =>
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
        val exp = copyExp emptyContext exp
      in
        (!varIdMapRef, exp)
      end
                   
end
end
