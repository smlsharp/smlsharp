_interface "TCAlphaRename.smi"
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
  type btvKind = {tvarKind : T.tvarKind, eqKind : T.eqKind}
  type btvEnv = btvKind BoundTypeVarID.Map.map
  type varInfo = T.varInfo

  type varMap = VarID.id VarID.Map.map
  val emptyVarMap = VarID.Map.empty
  val varIdMapRef = ref emptyVarMap : (VarID.id VarID.Map.map) ref

  fun addSubst (oldId, newId) = varIdMapRef := VarID.Map.insert(!varIdMapRef, oldId, newId)

  (* alpha-rename terms *)
  fun newId (varMap:varMap) id =
      let
        val newId = VarID.generate()
        val _ = addSubst (id, newId)
        val varMap =
            VarID.Map.insertWith
              (fn _ => raise DuplicateVar)
              (varMap, id, newId)
      in
        (varMap, newId)
      end
  fun newVar (varMap:varMap) ({longsymbol, id, ty}:varInfo) =
      let
        val (varMap, newId) = newId varMap id
            handle DuplicateVar =>
                   raise bug "duplicate id in IDCalcUtils"
      in
        (varMap, {longsymbol=longsymbol, id=newId, ty=ty})
      end
  fun newVars (varMap:varMap) (vars:varInfo list) =
      let
        val (varMap, varsRev) =
            foldl
            (fn (var, (varMap, varsRev)) =>
                let
                  val (varMap, var) = newVar varMap var
                in
                  (varMap, var::varsRev)
                end
            )
            (varMap, nil)
            vars
      in
        (varMap, List.rev varsRev)
      end

  fun copyPat (varMap:varMap) (tppat:TC.tppat) : varMap * TC.tppat =
      case tppat of
        TC.TPPATCONSTANT (constant, ty, loc) => (varMap, tppat)
      | TC.TPPATDATACONSTRUCT
          {argPatOpt,
           conPat:T.conInfo,
           instTyList,
           loc,
           patTy} =>
        let
          val (varMap, argPatOpt) =
              case argPatOpt of
                NONE => (varMap, NONE)
              | SOME argPat =>
                let
                  val (varMap, argPat) = copyPat varMap argPat
                in
                  (varMap, SOME argPat)
                end
        in
          (varMap,
           TC.TPPATDATACONSTRUCT
             {argPatOpt = argPatOpt,
              conPat = conPat,
              instTyList = instTyList,
              loc = loc,
              patTy = patTy
             }
          )
        end
      | TC.TPPATERROR (ty, loc) => (varMap, tppat)
      | TC.TPPATEXNCONSTRUCT
          {argPatOpt, exnPat:TC.exnCon, instTyList, loc, patTy} =>
        let
          val (varMap, argPatOpt) =
              case argPatOpt of
                NONE => (varMap, NONE)
              | SOME argPat =>
                let
                  val (varMap, argPat) = copyPat varMap argPat
                in
                  (varMap, SOME argPat)
                end
        in
          (varMap,
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
          val (varMap, varPat) = copyPat varMap varPat
          val (varMap, asPat) = copyPat varMap asPat
        in
          (varMap, TC.TPPATLAYERED {asPat=asPat, loc=loc, varPat=varPat})
        end
      | TC.TPPATRECORD {fields:TC.tppat LabelEnv.map, loc, recordTy} =>
        let
          val (varMap, fields) =
              LabelEnv.foldli
              (fn (label, pat, (varMap, fields)) =>
                  let
                    val (varMap, pat) = copyPat varMap pat
                  in
                    (varMap, LabelEnv.insert(fields, label, pat))
                  end
              )
              (varMap, LabelEnv.empty)
              fields
        in
          (varMap, TC.TPPATRECORD {fields=fields, loc=loc, recordTy=recordTy})
        end
      | TC.TPPATVAR varInfo =>
        let
          val (varMap, varInfo) = newVar varMap varInfo
        in
          (varMap, TC.TPPATVAR varInfo)
        end
      | TC.TPPATWILD (ty, loc) => (varMap, tppat)

  fun copyPats varMap pats =
      let
        val (varMap,patsRev) =
            foldl
            (fn (pat, (varMap,patsRev)) =>
                let
                  val (varMap, pat) = copyPat varMap pat
                in
                  (varMap, pat::patsRev)
                end
            )
            (varMap, nil)
            pats
      in
        (varMap, List.rev patsRev)
      end
  fun evalVar (varMap:varMap) ({longsymbol, id, ty}:varInfo) =
      let
        val id =
            case VarID.Map.find(varMap, id) of
              SOME id => id
            | NONE => id
      in
        {longsymbol=longsymbol, id=id, ty=ty}
      end

  fun copyExp (varMap:varMap) (exp:TC.tpexp) =
      let
        fun copy exp = copyExp varMap exp
      in
        (
        case exp of
          TC.TPAPPM {argExpList, funExp, funTy, loc} =>
          TC.TPAPPM {argExpList = map copy argExpList,
                     funExp = copy funExp,
                     funTy = funTy,
                     loc = loc}
        | TC.TPCASEM {caseKind, expList, expTyList, loc, ruleBodyTy, ruleList} =>
          TC.TPCASEM
            {caseKind = caseKind,
             expList = map copy expList,
             expTyList = expTyList,
             loc = loc,
             ruleBodyTy = ruleBodyTy,
             ruleList = map (copyRule varMap) ruleList
            }
        | TC.TPCAST ((tpexp, expTy), ty, loc) =>
          TC.TPCAST ((copy tpexp, expTy), ty, loc)
        | TC.TPCONSTANT {const, loc, ty} =>
          TC.TPCONSTANT {const=const, loc = loc, ty=ty}
        | TC.TPDATACONSTRUCT {argExpOpt, argTyOpt, con:T.conInfo, instTyList, loc} =>
          TC.TPDATACONSTRUCT
            {argExpOpt = Option.map copy argExpOpt,
             argTyOpt = argTyOpt,
             con = con,
             instTyList = instTyList,
             loc = loc
            }
        | TC.TPERROR => exp
        | TC.TPEXNCONSTRUCT {argExpOpt, argTyOpt, exn:TC.exnCon, instTyList, loc} =>
          TC.TPEXNCONSTRUCT
            {argExpOpt = Option.map copy argExpOpt,
             argTyOpt = argTyOpt,
             exn = exn,
             instTyList = instTyList,
             loc = loc
            }
        | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} =>
          TC.TPEXN_CONSTRUCTOR {exnInfo=exnInfo , loc=loc}
        | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
          TC.TPEXEXN_CONSTRUCTOR
            {exExnInfo= exExnInfo,
             loc= loc}
        | TC.TPEXVAR {longsymbol, ty} =>
          TC.TPEXVAR {longsymbol=longsymbol, ty=ty}
        | TC.TPFFIIMPORT {ffiTy, loc, ptrExp, stubTy} =>
          TC.TPFFIIMPORT
            {ffiTy = ffiTy,
             loc = loc,
             ptrExp = copy ptrExp,
             stubTy = stubTy
            }
        | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
          let
            val (varMap, argVarList) = newVars varMap argVarList
            val bodyExp = copyExp varMap bodyExp
          in
            TC.TPFNM
              {argVarList = argVarList,
               bodyExp = bodyExp,
               bodyTy = bodyTy,
               loc = loc
              }
          end
        | TC.TPGLOBALSYMBOL {kind, loc, name, ty} =>
          TC.TPGLOBALSYMBOL {kind=kind, loc=loc, name=name, ty=ty}
        | TC.TPHANDLE {exnVar, exp, handler, resultTy, loc} =>
          let
            val (varMap, exnVar) = newVar varMap exnVar
          in
            TC.TPHANDLE 
              {exnVar=exnVar, 
               exp=copy exp, 
               handler=copyExp varMap handler, 
               resultTy = resultTy,
               loc=loc}
          end
        | TC.TPLET {body:TC.tpexp list, decls, loc, tys} =>
          let
            val (varMap, decls) = copyDeclList varMap decls
          in
            TC.TPLET {body=map (copyExp varMap) body,
                      decls=decls,
                      loc=loc,
                      tys= tys}
          end
        | TC.TPMODIFY {elementExp, elementTy, label, loc, recordExp, recordTy} =>
          TC.TPMODIFY
            {elementExp = copy elementExp,
             elementTy = elementTy,
             label = label,
             loc = loc,
             recordExp = copy recordExp,
             recordTy = recordTy}
        | TC.TPMONOLET {binds:(T.varInfo * TC.tpexp) list, bodyExp, loc} =>
          let
            val (varMap, binds) = copyBinds varMap binds
(*
            val (vars, exps) = ListPair.unzip binds
            val exps = map copy exps
            val (varMap, vars) = newVars varMap vars
            val bodyExp = copyExp varMap bodyExp
            val binds = ListPair.zip(vars, exps)
*)
          in
            TC.TPMONOLET {binds=binds, bodyExp=copyExp varMap bodyExp, loc=loc}
          end
        | TC.TPOPRIMAPPLY {argExp, argTy, instTyList, loc, oprimOp:T.oprimInfo} =>
          TC.TPOPRIMAPPLY
            {argExp = copy argExp,
             argTy = argTy,
             instTyList = instTyList,
             loc = loc,
             oprimOp = oprimOp
            }
        | TC.TPPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
          TC.TPPOLY
            {btvEnv=btvEnv,
             exp = copyExp varMap exp,
             expTyWithoutTAbs = expTyWithoutTAbs,
             loc = loc
            }
        | TC.TPPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
          (
          let
            val (varMap, argVarList) = newVars varMap argVarList
          in
            TC.TPPOLYFNM
              {argVarList=argVarList,
               bodyExp=copyExp varMap bodyExp,
               bodyTy= bodyTy,
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
             argTy = argTy,
             instTyList = instTyList,
             loc = loc,
             primOp = primOp
            }
        | TC.TPRAISE {exp, loc, ty} =>
          TC.TPRAISE {exp= copy exp, loc=loc, ty = ty}
        | TC.TPRECORD {fields:TC.tpexp LabelEnv.map, loc, recordTy} =>
          TC.TPRECORD
            {fields=LabelEnv.map copy fields,
             loc=loc,
             recordTy=recordTy}
        | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
          TC.TPSELECT
            {exp=copy exp,
             expTy=expTy,
             label=label,
             loc=loc,
             resultTy=resultTy
            }
        | TC.TPSEQ {expList, expTyList, loc} =>
          TC.TPSEQ
            {expList = map copy expList,
             expTyList = expTyList,
             loc = loc
            }
        | TC.TPSIZEOF (ty, loc) =>
          TC.TPSIZEOF (ty, loc)
        | TC.TPSQLSERVER
            {loc,
             resultTy,
             schema:Types.ty LabelEnv.map LabelEnv.map,
             server
            } =>
            TC.TPSQLSERVER
              {loc=loc,
               resultTy=resultTy,
               schema= schema,
               server=copy server
              }
        | TC.TPTAPP {exp, expTy, instTyList, loc} =>
          TC.TPTAPP {exp=copy exp,
                     expTy = expTy,
                     instTyList= instTyList,
                     loc = loc
                    }
        | TC.TPVAR varInfo =>
          TC.TPVAR (evalVar varMap varInfo)
        (* the following should have been eliminate *)
        | TC.TPRECFUNVAR {arity, var} =>
          raise bug "TPRECFUNVAR in copy"
        )
          handle DuplicateBtv =>
                 (P.print "DuplicateBtv in copyExp\n";
                  P.printTpexp exp;
                  P.print "\n";
                raise bug "DuplicateBtv in copyExp copyExp")
    end
  and copyRule varMap {args, body} =
      let
        val (varMap, args) = copyPats varMap args
        val body = copyExp varMap body
      in
        {args=args, body=body}
      end
  and copyDecl varMap tpdecl =
      case tpdecl of
        TC.TPEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
        (varMap,
         TC.TPEXD
           (map (fn {exnInfo, loc} =>
                    {exnInfo=exnInfo, loc=loc})
                exbinds,
            loc)
        )
      | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        (varMap,
         TC.TPEXNTAGD ({exnInfo= exnInfo,
                        varInfo=evalVar varMap varInfo},
                       loc)
        )
      | TC.TPEXPORTEXN exnInfo =>
        (varMap, TC.TPEXPORTEXN exnInfo)
      | TC.TPEXPORTVAR varInfo =>
        (varMap,
         TC.TPEXPORTVAR (evalVar varMap varInfo)
        )
      | TC.TPEXPORTRECFUNVAR _ =>
        raise bug "TPEXPORTRECFUNVAR to AlphaRename"
      | TC.TPEXTERNEXN {longsymbol, ty} =>
        (varMap,
         TC.TPEXTERNEXN {longsymbol=longsymbol, ty= ty}
        )
      | TC.TPEXTERNVAR {longsymbol, ty} =>
        (varMap,
         TC.TPEXTERNVAR {longsymbol=longsymbol, ty= ty}
        )
      | TC.TPVAL (binds:(T.varInfo * TC.tpexp) list, loc) =>
        let
          val (varMap, binds) = copyBinds varMap binds
        in
          (varMap, TC.TPVAL (binds, loc))
        end
      | TC.TPVALPOLYREC
          (btvEnv,
           recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,
           loc) =>
        let
          val vars = map #var recbinds
          val (varMap, vars) = newVars varMap vars
          val varRecbindList = ListPair.zip (vars, recbinds)
          val recbinds =
              map
                (fn (var, {exp, expTy, var=_}) =>
                    {var=var,
                     expTy=expTy,
                     exp=copyExp varMap exp}
                )
                varRecbindList
        in
          (varMap, TC.TPVALPOLYREC (btvEnv, recbinds, loc))
        end
      | TC.TPVALREC (recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,loc) =>
        let
          val vars = map #var recbinds
          val (varMap, vars) = newVars varMap vars
          val varRecbindList = ListPair.zip (vars, recbinds)
          val recbinds =
              map
                (fn (var, {exp, expTy, var=_}) =>
                    {var=var,
                     expTy= expTy,
                     exp=copyExp varMap exp}
                )
                varRecbindList
        in
          (varMap, TC.TPVALREC (recbinds, loc))
        end
      (* the following should have been eliminate *)
      | TC.TPFUNDECL _ => raise bug "TPFUNDECL not eliminated"
      | TC.TPPOLYFUNDECL _  => raise bug "TPPOLYFUNDECL not eliminated"

  and copyBind (newVarMap, varMap) (var, exp) =
      let
        val (newVarMap, var) = newVar newVarMap var
        val exp = copyExp newVarMap exp
      in
        (newVarMap, (var, exp))
      end
  and copyBinds varMap binds =
      let
        val (newVarMap, bindsRev) =
            foldl
            (fn (bind, (newVarMap, bindsRev)) =>
                let
                  val (newVarMap, bind) = copyBind (newVarMap, varMap) bind
                in
                  (newVarMap, bind::bindsRev)
                end
            )
            (varMap, nil)
            binds
      in
        (newVarMap, List.rev bindsRev)
      end
  and copyDeclList varMap declList =
      let
        fun copy (decl, (varMap, declListRev)) =
            let
              val (varMap, newDecl) = copyDecl varMap decl
            in
              (varMap, newDecl::declListRev)
            end
        val (varMap, declListRev) = foldl copy (varMap, nil) declList
      in
        (varMap, List.rev declListRev)
      end
in
  val copyExp = 
   fn exp => 
      let
        val _ = varIdMapRef := emptyVarMap
        val exp = copyExp emptyVarMap exp
      in
        (!varIdMapRef, exp)
      end
                   
end
end
