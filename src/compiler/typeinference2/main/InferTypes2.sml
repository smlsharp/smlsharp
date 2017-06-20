(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 * @author Tomohiro Sasaki (JOIN constraint handling)
 *)
structure InferTypes =
struct
local
  structure T = Types
  structure IC = IDCalc
  structure NEU = NameEvalUtils
  structure ITy = EvalIty
  structure BT = BuiltinTypes
  structure BP = BuiltinPrimitive
  structure A = AbsynConst
  structure TC = TypedCalc
  structure TCU = TypedCalcUtils
  structure E = TypeInferenceError
  structure TIC = TypeInferenceContext
  structure TIU = TypeInferenceUtils
  structure CT = ConstantTerm
  structure TB = TypesBasics
  structure UE = UserError
  structure U = Unify
  structure P = Printers
  structure UP = UserLevelPrimitive
  structure RyU = ReifyUtils


  exception Fail

  fun TCVarToICVar {path, id, ty, opaque} =
      {longsymbol=path, id=id}
  fun ICVarToTCVar {longsymbol, id} ty =
      {path = longsymbol, id = id, ty = ty, opaque=false}
  fun newJoinAtomicTvarTy () = T.newty T.joinAtomicKind
  fun newJoinTvarTy () = T.newty T.reifyKind
  fun newJoinTvarTyWithLambdaDepth depth = T.newtyWithLambdaDepth (depth, T.reifyKind)
  fun newJsonTvarTy () = T.newty T.jsonKind
  fun newRecTvarTy () = T.newty T.emptyRecordKind
  fun newReifyTvarTy () = T.newty T.reifyKind
  fun newUnivTvarTy () = T.newty T.univKind
  fun arrayTy elemTy = T.CONSTRUCTty {tyCon=BT.arrayTyCon, args = [elemTy]}
  fun listTy elemTy = T.CONSTRUCTty {tyCon=BT.listTyCon, args = [elemTy]}
  val intTy = T.CONSTRUCTty {tyCon=BT.intTyCon, args = nil}
  val indexTy = T.CONSTRUCTty {tyCon=BT.indexTyCon, args = nil}
  val boolTy = T.CONSTRUCTty {tyCon=BT.boolTyCon, args = nil}

  val --> = RyU.-->
  val ** = RyU.**
  infixr 4 -->
  infix 5 **

  val maxDepth = ref 0
  fun incDepth () = (maxDepth := !maxDepth + 1; !maxDepth)
  val ffiApplyTyvars = ref nil : (T.ty * Loc.loc) list ref
  fun bug s = Bug.Bug ("InferType: " ^ s)

  val constraints = ref nil : T.constraint list ref
  fun addConstraint c = 
      constraints := c :: !constraints
  fun addConstraints cl =
      List.app (fn c => addConstraint c) cl

  val emptyScopedTvars = nil : IC.scopedTvars

  fun exInfoToLongsymbol {used, longsymbol, version, ty} =
      Symbol.setVersion(longsymbol, version)

  fun makeTPRecord labelTyTpexpList loc =
      let
        val (tpexpSmap, tySmap, tpbindsRev) =
            foldl
              (fn ((label, (ty, tpexp)), (tpexpSmap, tySmap, tpbindsRev)) =>
                  if not (TCU.expansive tpexp) then
(*
                  if TCU.isAtom tpexp then
*)
                    (
                     RecordLabel.Map.insert (tpexpSmap, label, tpexp),
                     RecordLabel.Map.insert (tySmap, label, ty),
                     tpbindsRev
                    )
                  else
                    let
                      val newVarInfo = TCU.newTCVarInfo loc ty
                    in
                      (
                       RecordLabel.Map.insert
                         (tpexpSmap, label, TC.TPVAR newVarInfo),
                       RecordLabel.Map.insert(tySmap, label, ty),
                       (newVarInfo, tpexp) :: tpbindsRev
                      )
                    end
              )
              (RecordLabel.Map.empty, RecordLabel.Map.empty, nil)
              labelTyTpexpList
        val tpbinds = List.rev tpbindsRev
        val resultTy = T.RECORDty tySmap
        val recordExp = 
            case tpbinds of
              nil => TC.TPRECORD {fields=tpexpSmap,recordTy=resultTy,loc=loc}
            | _ =>
              TC.TPMONOLET
                {binds=tpbinds,
                 bodyExp=
                 TC.TPRECORD {fields=tpexpSmap,recordTy=resultTy,loc=loc},
                 loc=loc}
      in
        (resultTy, recordExp)
      end

  fun labelEnvFromList list =
      List.foldl (fn ((key, item), m) => RecordLabel.Map.insert (m, key, item)) RecordLabel.Map.empty list

  fun makeTupleTy nil = BT.unitTy
    | makeTupleTy [ty] = ty
    | makeTupleTy tys = T.RECORDty (RecordLabel.tupleMap tys)

  fun makeTupleExp (nil, loc) =
      TC.TPCONSTANT {const=A.UNITCONST loc, ty=BT.unitTy, loc=loc}
    | makeTupleExp ([(ty, exp)], loc) = exp
    | makeTupleExp (fields, loc) =
      let
        val (_, recordExp) = 
            makeTPRecord (RecordLabel.tupleList fields) loc
      in
        recordExp
      end

  fun LabelEnv_all f env =
      RecordLabel.Map.foldl (fn (x,z) => z andalso f x) true env

  datatype dir = IMPORT | EXPORT
  datatype safe = SAFE | UNSAFE

  fun exportOnly (IMPORT, SAFE) = false
    | exportOnly (IMPORT, UNSAFE) = true
    | exportOnly (EXPORT, _) = true

  fun isUnsafe (_, SAFE) = false
    | isUnsafe (_, UNSAFE) = true

  fun getRuleLocM nil = raise bug "empty rule in getRuleLocM"
    | getRuleLocM [{args=pat::_, body}] =
        Loc.mergeLocs (IC.getLocPat pat, IC.getLocExp body)
    | getRuleLocM rules =
        let
          val pat1 =
            case rules of
              {args=pat1::_, body}:: _ => pat1
            | _ =>
                raise
                  bug
                  "empty pattern in rules\
                  \ (typeinference/main/TypeInferCore.sml)"
          val {args=_, body} = List.last rules
        in
          Loc.mergeLocs (IC.getLocPat pat1, IC.getLocExp body)
        end

  fun tyConSubstTy typIdMap ty =
      let
        fun expSubst exp = tyConSubstExp typIdMap exp
        fun tySubst ty =
            case TB.derefTy ty of
              T.SINGLETONty (T.INSTCODEty operator) =>
              T.SINGLETONty
                (T.INSTCODEty(oprimSelectorSubst typIdMap operator))
            | T.SINGLETONty (T.INDEXty (string, ty)) =>
              T.SINGLETONty (T.INDEXty (string, tySubst ty))
            | T.SINGLETONty (T.TAGty ty) =>
              T.SINGLETONty (T.TAGty (tySubst ty))
            | T.SINGLETONty (T.SIZEty ty) =>
              T.SINGLETONty (T.SIZEty (tySubst ty))
            | T.SINGLETONty (T.TYPEty ty) =>
              T.SINGLETONty (T.TYPEty (tySubst ty))
            | T.SINGLETONty (T.REIFYty ty) =>
              T.SINGLETONty (T.REIFYty (tySubst ty))
            | T.BACKENDty _ => raise bug "tyConSubstTy: BACKENDty"
            | T.ERRORty => ty
            | T.DUMMYty (id, kind) =>
              T.DUMMYty (id, kindSubst kind)
            | T.TYVARty tvStateRef => ty
            | T.BOUNDVARty boundTypeVarID => ty
            | T.FUNMty (tyList, ty) =>
              T.FUNMty (map tySubst tyList, tySubst ty)
            | T.RECORDty tySenvMap =>
              T.RECORDty (RecordLabel.Map.map tySubst tySenvMap)
            | T.CONSTRUCTty {tyCon, args} =>
              (case TypID.Map.find(typIdMap, #id tyCon) of
                 NONE => 
                 T.CONSTRUCTty{tyCon=tyCon, args= map tySubst args}
               | SOME tyCon =>
                 T.CONSTRUCTty{tyCon=tyCon,args = map tySubst args}
              )
            | T.POLYty {boundtvars, constraints, body} =>
              T.POLYty {boundtvars =
                        BoundTypeVarID.Map.map
                          kindSubst
                          boundtvars,
                        constraints =
                        List.map
                            (fn c =>
                                case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                                  T.JOIN
                                      {res = tySubst res,
                                       args = (tySubst arg1, tySubst arg2), loc = loc})
                            constraints,
                        body = tySubst body
                       }
        and kindSubst (T.KIND {tvarKind, subkind, eqKind, reifyKind, dynKind}) =
            T.KIND {tvarKind = tvarKindSubst tvarKind,
                    subkind = subkind,
                    eqKind = eqKind,
                    reifyKind = reifyKind,
                    dynKind = dynKind}
        and tvarKindSubst tvarKind =
            case tvarKind of
              T.OCONSTkind tyList =>
              T.OCONSTkind (map tySubst tyList)
            | T.OPRIMkind {instances, operators} =>
              T.OPRIMkind
                {instances = map tySubst instances,
                 operators = map (oprimSelectorSubst typIdMap) operators
                }
            | T.UNIV => T.UNIV
            | T.BOXED => T.BOXED
            | T.REC tySenvMap =>
              T.REC (RecordLabel.Map.map tySubst tySenvMap)
      in
        tySubst ty
      end
  and overloadMatchSubst typIdMap overloadMatch =
      case overloadMatch of
        T.OVERLOAD_EXVAR
          {
           exVarInfo={path, ty},
           instTyList
          } =>
        T.OVERLOAD_EXVAR
          {
           exVarInfo={path=path, ty=tyConSubstTy typIdMap ty},
           instTyList = map (tyConSubstTy typIdMap) instTyList
          }
      | T.OVERLOAD_PRIM
          {
           primInfo= {primitive, ty},
           instTyList
          } =>
        T.OVERLOAD_PRIM
          {
           primInfo= {primitive=primitive, ty=tyConSubstTy typIdMap ty},
           instTyList = map (tyConSubstTy typIdMap) instTyList
          }
      | T.OVERLOAD_CASE (ty, overloadMatchDMap) =>
        T.OVERLOAD_CASE
          (tyConSubstTy typIdMap ty,
           TypID.Map.map (overloadMatchSubst typIdMap) overloadMatchDMap
          )
  and oprimSelectorSubst typIdMap {oprimId,longsymbol,keyTyList,match,instMap} =
      {oprimId=oprimId,
       longsymbol = longsymbol,
       keyTyList = map (tyConSubstTy typIdMap) keyTyList,
       match = overloadMatchSubst typIdMap match,
       instMap = OPrimInstMap.map (overloadMatchSubst typIdMap) instMap
      }
  and tyConSubstExp typIdMap tpexp =
      let
        fun tySubst ty = tyConSubstTy typIdMap ty
        fun varSubst {id,path,ty, opaque} =
            {id=id,path=path,ty=tySubst ty, opaque=opaque}
        fun expSubst tpexp =
            case tpexp of
              TC.TPERROR => tpexp
            | TC.TPCONSTANT {const, ty, loc} => tpexp
            | TC.TPVAR var =>
              TC.TPVAR (varSubst var) 
            | TC.TPEXVAR {path,ty} =>
              TC.TPEXVAR {path=path, ty=tySubst ty}
            | TC.TPRECFUNVAR {var={path,id,ty,opaque}, arity} =>
              TC.TPRECFUNVAR
                {
                 var={path=path, id=id, ty=tySubst ty, opaque=opaque},
                 arity=arity
                }
            | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} =>
              TC.TPFNM
                {argVarList =
                 map
                   (fn {id, path, ty, opaque} =>
                       {id=id,path=path,ty=tySubst ty, opaque=opaque}
                   )
                   argVarList,
                 bodyTy = tySubst bodyTy,
                 bodyExp = expSubst bodyExp,
                 loc = loc
                }
            | TC.TPAPPM {funExp, funTy, argExpList, loc} =>
              TC.TPAPPM
                {funExp = expSubst funExp,
                 funTy = tySubst funTy,
                 argExpList = map expSubst argExpList,
                 loc =loc
                }
            | TC.TPDATACONSTRUCT {con={path,id,ty},instTyList,argExpOpt,argTyOpt, loc} =>
              TC.TPDATACONSTRUCT
                {con={path=path, id=id, ty=tySubst ty},
                 instTyList = map tySubst instTyList,
                 argExpOpt=Option.map expSubst argExpOpt,
                 argTyOpt=Option.map tySubst argTyOpt,
                 loc=loc
                }
            | TC.TPEXNCONSTRUCT {exn,instTyList,argExpOpt,argTyOpt,loc} =>
              TC.TPEXNCONSTRUCT
                {exn =
                   case exn of
                     TC.EXN {id, ty, path} =>
                     TC.EXN {id=id, ty=tySubst ty, path=path}
                   | TC.EXEXN {path, ty} =>
                     TC.EXEXN {path=path, ty=tySubst ty},
                 instTyList = map tySubst instTyList,
                 argExpOpt = Option.map expSubst argExpOpt,
                 argTyOpt=Option.map tySubst argTyOpt,
                 loc = loc
                }
            | TC.TPEXN_CONSTRUCTOR {exnInfo={id,ty,path},loc} =>
              TC.TPEXN_CONSTRUCTOR
                {exnInfo={id=id,ty=tySubst ty,path=path},loc=loc}
            | TC.TPEXEXN_CONSTRUCTOR {exExnInfo={ty,path},loc} =>
              TC.TPEXEXN_CONSTRUCTOR
                {exExnInfo={ty=tySubst ty,path=path},loc=loc}
            | TC.TPCASEM{expList,expTyList,ruleList,ruleBodyTy,caseKind,loc} =>
              TC.TPCASEM
                {expList = map expSubst expList,
                 expTyList = map tySubst expTyList,
                 ruleList =
                 map
                   (fn {args,body} =>
                       {args=map patSubst args, body=expSubst body})
                   ruleList,
                 ruleBodyTy = tySubst ruleBodyTy,
                 caseKind = caseKind,
                 loc = loc
                }
            | TC.TPPRIMAPPLY {primOp, instTyList, argExp, argTy, loc} =>
              TC.TPPRIMAPPLY
                {primOp = primOp,
                 instTyList = map tySubst instTyList,
                 argExp = expSubst argExp,
                 argTy = tySubst argTy,
                 loc = loc
                }
            | TC.TPOPRIMAPPLY {oprimOp, instTyList, argExp, argTy, loc} =>
              TC.TPOPRIMAPPLY
                {oprimOp=oprimOp,
                 instTyList=map tySubst instTyList,
                 argExp = expSubst argExp,
                 argTy = tySubst argTy,
                 loc=loc}
            | TC.TPRECORD {fields, recordTy, loc} =>
              TC.TPRECORD
                {fields = RecordLabel.Map.map expSubst fields,
                 recordTy = tySubst recordTy,
                 loc = loc
                }
            | TC.TPSELECT {label, exp, expTy, resultTy, loc} =>
              TC.TPSELECT
                {label = label,
                 exp = expSubst exp,
                 expTy = tySubst expTy,
                 resultTy = tySubst resultTy,
                 loc = loc}
            | TC.TPMODIFY{label,recordExp,recordTy,elementExp,elementTy,loc} =>
              TC.TPMODIFY
                {label=label,
                 recordExp=expSubst recordExp,
                 recordTy=tySubst recordTy,
                 elementExp=expSubst elementExp,
                 elementTy=tySubst elementTy,
                 loc=loc}
            | TC.TPSEQ {expList, expTyList, loc} =>
              TC.TPSEQ
                {expList = map expSubst expList,
                 expTyList = map tySubst expTyList,
                 loc=loc
                }
            | TC.TPFOREACH {data, dataTy, iterator, iteratorTy, pred, predTy, loc} =>
              TC.TPFOREACH {data = expSubst data, 
                            dataTy = tySubst dataTy,
                            iterator = expSubst iterator, 
                            iteratorTy = tySubst iteratorTy,
                            pred = expSubst pred, 
                            predTy = tySubst predTy,
                            loc = loc}
            | TC.TPFOREACHDATA {data, dataTy, whereParam, whereParamTy, iterator, iteratorTy, pred, predTy, loc} =>
              TC.TPFOREACHDATA {data = expSubst data, 
                                dataTy = tySubst dataTy,
                                whereParam = expSubst whereParam, 
                                whereParamTy = tySubst whereParamTy,
                                iterator = expSubst iterator, 
                                iteratorTy = tySubst iteratorTy,
                                pred = expSubst pred, 
                                predTy = tySubst predTy,
                                loc = loc}
            | TC.TPMONOLET {binds, bodyExp, loc} =>
              TC.TPMONOLET
                {binds =
                 map
                   (fn ({id,path,ty,opaque},exp) =>
                       ({id=id,path=path,ty=tySubst ty,opaque=opaque},
                        expSubst exp))
                   binds,
                 bodyExp=expSubst bodyExp,
                 loc=loc}
            | TC.TPLET {decls, body, tys, loc} =>
              TC.TPLET
                {decls =map declSubst decls,
                 body = map expSubst body,
                 tys = map tySubst tys,
                 loc=loc}
            | TC.TPRAISE {exp, ty, loc} =>
              TC.TPRAISE {exp=expSubst exp, ty=tySubst ty, loc=loc}
            | TC.TPHANDLE {exp, exnVar={path,id,ty,opaque}, handler, resultTy, loc} =>
              TC.TPHANDLE
                {exp = expSubst exp,
                 exnVar = {path=path, id=id, ty=tySubst ty, opaque=opaque},
                 handler = expSubst exp,
                 resultTy = tySubst resultTy,
                 loc = loc}
            | TC.TPPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
              TC.TPPOLYFNM
                {btvEnv = BoundTypeVarID.Map.map kindSubst btvEnv,
                 argVarList = map varSubst argVarList,
                 bodyTy = tySubst bodyTy,
                 bodyExp = expSubst bodyExp,
                 loc = loc}
            | TC.TPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
              TC.TPPOLY
                {btvEnv = BoundTypeVarID.Map.map kindSubst btvEnv,
                 expTyWithoutTAbs = tySubst expTyWithoutTAbs,
                 exp = expSubst exp,
                 loc = loc}
            | TC.TPTAPP {exp, expTy, instTyList, loc} =>
              TC.TPTAPP
                {exp = expSubst exp,
                 expTy = tySubst expTy,
                 instTyList = map tySubst instTyList,
                 loc = loc
                }
            | TC.TPFFIIMPORT {funExp, ffiTy, stubTy, loc} =>
              TC.TPFFIIMPORT
                {funExp = case funExp of
                            TC.TPFFIFUN ptrExp => TC.TPFFIFUN (expSubst ptrExp)
                          | TC.TPFFIEXTERN _ => funExp,
                 ffiTy = ffiTySubst ffiTy,
                 stubTy = tySubst stubTy,
                 loc=loc}
            | TC.TPCAST ((tpexp, expTy), ty, loc) =>
              TC.TPCAST ((expSubst tpexp, tySubst expTy), tySubst ty, loc)
            | TC.TPSIZEOF (ty, loc) =>
              TC.TPSIZEOF (tySubst ty, loc)
            | TC.TPJOIN {ty, args = (arg1, arg2), argtys = (argty1, argty2), loc} =>
              TC.TPJOIN {ty = tySubst ty,
                         args = (expSubst arg1, expSubst arg2),
                         argtys = (tySubst argty1, tySubst argty2),
                         loc = loc}
            | TC.TPTYPEOF (ty, loc) =>
              TC.TPTYPEOF (tySubst ty, loc)
            | TC.TPREIFYTY (ty, loc) =>
              TC.TPREIFYTY (tySubst ty, loc)
            | TC.TPJSON {exp,ty,coerceTy,loc} =>
              TC.TPJSON {exp=expSubst exp,
                         ty=tySubst ty,
                         coerceTy=tySubst coerceTy,
                         loc=loc}
        and kindSubst (T.KIND {eqKind, dynKind, reifyKind, subkind, tvarKind}) =
            T.KIND
            {eqKind=eqKind,
             dynKind = dynKind,
             reifyKind = reifyKind,
             subkind = subkind,
             tvarKind =
             case tvarKind of
               T.OCONSTkind tyList =>
               T.OCONSTkind (map tySubst tyList)
             | T.OPRIMkind {instances, operators} =>
               T.OPRIMkind
                 {instances = map tySubst instances,
                  operators = map (oprimSelectorSubst typIdMap) operators
                 }
             | T.UNIV => T.UNIV
             | T.BOXED => T.BOXED
             | T.REC tyMap => T.REC (RecordLabel.Map.map tySubst tyMap)
            }
        and patSubst pat =
            case pat of
              TC.TPPATERROR (ty, loc) =>
              TC.TPPATERROR (tySubst ty, loc)
            | TC.TPPATWILD (ty, loc) =>
              TC.TPPATWILD (tySubst ty, loc)
            | TC.TPPATVAR var =>
              TC.TPPATVAR (varSubst var)
            | TC.TPPATCONSTANT (constant, ty, loc) =>
              TC.TPPATCONSTANT (constant, tySubst ty, loc)
            | TC.TPPATDATACONSTRUCT
                {
                 conPat={id, ty, path},
                 instTyList,
                 argPatOpt,
                 patTy,
                 loc
                } =>
              TC.TPPATDATACONSTRUCT
                {
                 conPat = {id=id, path=path, ty=tySubst ty},
                 instTyList = map tySubst instTyList,
                 argPatOpt = Option.map patSubst argPatOpt,
                 patTy = tySubst patTy,
                 loc=loc
                }
            | TC.TPPATEXNCONSTRUCT
                {
                 exnPat,
                 instTyList,
                 argPatOpt,
                 patTy,
                 loc
                } =>
              TC.TPPATEXNCONSTRUCT
                {
                 exnPat =
                   case exnPat of
                     TC.EXN {id,path,ty} =>
                     TC.EXN {id=id, path=path, ty=tySubst ty}
                   | TC.EXEXN {path,ty} =>
                     TC.EXEXN {path=path, ty=tySubst ty},
                 instTyList = map tySubst instTyList,
                 argPatOpt = Option.map patSubst argPatOpt,
                 patTy = tySubst patTy,
                 loc=loc
                }

            | TC.TPPATRECORD {fields, recordTy, loc} =>
              TC.TPPATRECORD
                {fields = RecordLabel.Map.map patSubst fields,
                 recordTy = tySubst recordTy,
                 loc = loc
                }
            | TC.TPPATLAYERED {varPat, asPat, loc} =>
              TC.TPPATLAYERED
                {varPat=patSubst varPat, asPat=patSubst asPat, loc=loc}

        and declSubst decl =
            case decl of
            TC.TPVAL (valIdTpexpList, loc) =>
            TC.TPVAL
              (map (fn(var,exp) =>(varSubst var,expSubst exp)) valIdTpexpList,
               loc)
          | TC.TPFUNDECL (funBindlist, loc) =>
            TC.TPFUNDECL
              (
               map
                 (fn {funVarInfo, argTyList,bodyTy,ruleList}=>
                     {funVarInfo =varSubst funVarInfo,
                      argTyList = map tySubst argTyList,
                      bodyTy = tySubst bodyTy,
                      ruleList =
                      map (fn {args, body} =>
                              {args = map patSubst args,
                               body = expSubst body}
                          )
                          ruleList
                     }
                 )
                 funBindlist,
               loc
              )
          | TC.TPPOLYFUNDECL (btvEnv, funBindList, loc) =>
            TC.TPPOLYFUNDECL
              (BoundTypeVarID.Map.map kindSubst btvEnv,
               map
                 (fn {funVarInfo, argTyList,bodyTy,ruleList}=>
                     {funVarInfo =varSubst funVarInfo,
                      argTyList = map tySubst argTyList,
                      bodyTy = tySubst bodyTy,
                      ruleList =
                      map (fn {args, body} =>
                              {args = map patSubst args,
                               body = expSubst body}
                          )
                          ruleList
                     }
                 )
                 funBindList,
               loc)
          | TC.TPVALREC (varExpTyEexpList, loc) =>
            TC.TPVALREC
              (map
                 (fn {var, expTy, exp} =>
                     {var=varSubst var, expTy=tySubst expTy, exp=expSubst exp}
                 )
                 varExpTyEexpList,
               loc)

          | TC.TPVALPOLYREC (btvEnv, varExpTyEexpList, loc) =>
            TC.TPVALPOLYREC
              (BoundTypeVarID.Map.map kindSubst btvEnv,
               map
                 (fn {var, expTy, exp} =>
                     {var=varSubst var, expTy=tySubst expTy, exp=expSubst exp}
                 )
                 varExpTyEexpList,
               loc)
          | TC.TPEXD (exnconLocList, loc) =>
            TC.TPEXD
              (
               exnconLocList,
               loc
              )
          | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
            (* there should be tyCon to be substituted but just in case *)
            TC.TPEXNTAGD ({exnInfo=exnInfo, varInfo=varSubst varInfo},loc)
          | TC.TPEXPORTVAR varInfo =>
            TC.TPEXPORTVAR (varSubst varInfo)
          | TC.TPEXPORTRECFUNVAR {var, arity} =>
            TC.TPEXPORTRECFUNVAR {var=varSubst var, arity=arity}
          | TC.TPEXPORTEXN {id, path, ty} =>
            TC.TPEXPORTEXN {id=id, path=path, ty=tySubst ty}
          | TC.TPEXTERNVAR {path, ty} =>
            TC.TPEXTERNVAR {path=path, ty=tySubst ty}
          | TC.TPEXTERNEXN {path, ty} =>
            TC.TPEXTERNEXN {path=path, ty=tySubst ty}
          | TC.TPBUILTINEXN {path, ty} =>
            TC.TPBUILTINEXN {path=path, ty=tySubst ty}
        and ffiTySubst ffiTy =
            case ffiTy of
              TC.FFIFUNTY (ffiAttribOpt, ffiTyList1, ffiTyList2, ffiTyList3, loc) =>
              TC.FFIFUNTY
                (ffiAttribOpt,
                 map ffiTySubst ffiTyList1,
                 Option.map (map ffiTySubst) ffiTyList2,
                 map ffiTySubst ffiTyList3,
                 loc)
            | TC.FFIRECORDTY (stringFfityList, loc) =>
              TC.FFIRECORDTY
                (map (fn (string, ffiTy) =>
                         (string, ffiTySubst ffiTy)
                     )
                     stringFfityList,
                 loc)
            | TC.FFIBASETY (ty, loc) => TC.FFIBASETY (tySubst ty, loc)

        and varSubst {id, path, ty, opaque} =
            {id=id, path=path, ty=tyConSubstTy typIdMap ty, opaque=opaque}
        and exVarSubst {path,ty} =
            {path=path, ty=tyConSubstTy typIdMap ty}
      in
        expSubst tpexp
      end

  fun tyConSubstVarInfo typIdMap {path, id, ty, opaque} =
      {path=path, id=id, ty = tyConSubstTy typIdMap ty, opaque=opaque}
  fun tyConSubstIdstatus typIdMap idstatus =
      case idstatus of
        TC.RECFUNID (varInfo, int) =>
        TC.RECFUNID (tyConSubstVarInfo typIdMap varInfo, int)
      | TC.VARID varInfo => TC.VARID (tyConSubstVarInfo typIdMap varInfo)
  fun tyConSubstContext typIdMap {tvarEnv, varEnv, oprimEnv} =
      let
        val tvarEnv = TvarMap.map (tyConSubstTy typIdMap) tvarEnv
        val varEnv = VarMap.map (tyConSubstIdstatus typIdMap) varEnv
      in
        {tvarEnv=tvarEnv, varEnv=varEnv, oprimEnv = oprimEnv}
      end

in

  local
    val empty = {import = OTSet.empty, export = OTSet.empty}
    fun union ({import=i1,export=e1},{import=i2, export=e2}) =
        {import = OTSet.union (i1, i2), export = OTSet.union (e1, e2)}
    fun opposite IMPORT = EXPORT
      | opposite EXPORT = IMPORT
  in
  fun ffiFTV dir ffity =
      case ffity of
        TC.FFIBASETY (ty, loc) =>
        let
          val s = #2 (TB.EFTV (ty, !constraints))
        in
          case dir of
            IMPORT => {import = s, export = OTSet.empty}
          | EXPORT => {import = OTSet.empty, export = s}
        end
      | TC.FFIRECORDTY (fields, loc) =>
        ffiFTVList dir (map #2 fields)
      | TC.FFIFUNTY (attr as SOME {unsafe=true,...}, argTys, varTys, retTys,
                     loc) =>
        let
          val tvs as {import, export} =
              ffiFTV dir (TC.FFIFUNTY (NONE, argTys, varTys, retTys, loc))
        in
          (* unsafe function can import an unexported tyvar by assuming
           * that such tyvars are somehow exported.
           * FIXME: is this rule consistent?  *)
          {import = import, export = OTSet.union (import, export)}
        end
      | TC.FFIFUNTY (_, argTys, varTys, retTys, loc) =>
        union (ffiFTVList (opposite dir)
                          (argTys @ (case varTys of SOME l => l | NONE => [])),
               ffiFTVList dir retTys)

  and ffiFTVList dir l =
      foldl (fn (x,z) => union (ffiFTV dir x, z)) empty l
  end (* local *)

  fun isInteroperableBuiltinTy dir (ty, args) =
      case ty of
        BuiltinTypeNames.INT8ty => true
      | BuiltinTypeNames.INDEXty => true
      | BuiltinTypeNames.INT16ty => true
      | BuiltinTypeNames.INT32ty => true
      | BuiltinTypeNames.INT64ty => true
      | BuiltinTypeNames.INTINFty => exportOnly dir
      | BuiltinTypeNames.WORD8ty => true
      | BuiltinTypeNames.WORD16ty => true
      | BuiltinTypeNames.WORD32ty => true
      | BuiltinTypeNames.WORD64ty => true
      | BuiltinTypeNames.CHARty => true
      | BuiltinTypeNames.STRINGty => exportOnly dir
      | BuiltinTypeNames.REAL64ty => true
      | BuiltinTypeNames.REAL32ty => true
      | BuiltinTypeNames.UNITty => false
      | BuiltinTypeNames.PTRty =>
        List.all (isInteroperableArgTy dir) args orelse
        (
          (* additionally allow unit ptr *)
          case args of
            [ty] => (case TB.derefTy ty of
                       T.CONSTRUCTty {tyCon, args=[]} =>
                       TypID.eq (#id tyCon, #id BT.unitTyCon)
                     | _ => false)
          | _ => raise bug "non singleton arg in PTRty"
        )
      | BuiltinTypeNames.CODEPTRty => true
      | BuiltinTypeNames.REFty =>
        exportOnly dir
        andalso List.all (isInteroperableArgTy (IMPORT, #2 dir)) args
      | BuiltinTypeNames.ARRAYty =>
        exportOnly dir
        andalso List.all (isInteroperableArgTy (IMPORT, #2 dir)) args
      | BuiltinTypeNames.VECTORty =>
        exportOnly dir andalso List.all (isInteroperableArgTy dir) args
      | BuiltinTypeNames.EXNty => isUnsafe dir
      | BuiltinTypeNames.BOXEDty => isUnsafe dir
      | BuiltinTypeNames.EXNTAGty => isUnsafe dir
      | BuiltinTypeNames.CONTAGty => isUnsafe dir


  and isInteroperableTycon dir ({id, dtyKind, runtimeTy, ...}:T.tyCon, args) =
      case dtyKind of
        T.DTY =>
        isUnsafe dir
      | T.OPAQUE {opaqueRep = T.TYCON tycon, revealKey} =>
        isInteroperableTycon dir (tycon, args)
      | T.OPAQUE {opaqueRep = T.TFUNDEF _, revealKey} => false
      | T.BUILTIN runtimeTy =>
        isInteroperableBuiltinTy dir (runtimeTy, args)

  and isInteroperableTy dir ty =
      case TB.derefTy ty of
        T.CONSTRUCTty {tyCon, args} =>
        isInteroperableTycon dir (tyCon, args)
      | T.RECORDty fields =>
	exportOnly dir
        andalso (isUnsafe dir orelse RecordLabel.isOrderedMap fields)
        andalso LabelEnv_all (isInteroperableTy dir) fields
      | T.TYVARty (ref (T.TVAR {kind = T.KIND {tvarKind, subkind, ...}, ...})) =>
        (case tvarKind of
           T.UNIV => false
         | T.BOXED => true
         | T.REC _ => isUnsafe dir
         | T.OPRIMkind _ => false
         | T.OCONSTkind _ => false)
      | _ => false

  and isInteroperableArgTy dir ty =
      case TB.derefTy ty of
        T.TYVARty (ref (T.TVAR {kind = T.KIND {tvarKind, subkind,...},...})) =>
        (case tvarKind of
           T.UNIV => false
         | T.BOXED => true
         | T.REC _ => false
         | T.OPRIMkind _ => false
         | T.OCONSTkind _ => false)
        orelse
        (* allow int array, int vector, etc. *)
        (case subkind of
           T.ANY => false
         | T.JSON => false
         | T.JSON_ATOMIC => true
         | T.UNBOXED => true)
        orelse
        isUnsafe dir
      | _ => isInteroperableTy dir ty

  fun evalForceImportFFIty (context:TIC.context) dir ffity =
      case ffity of
        IC.FFIBASETY (ty, loc) =>
        let
          val ty = ITy.evalIty context ty
        in
          if isInteroperableTy dir ty
          then ty
          else (E.enqueueError "Typeinf 001"
                               (loc, E.NonInteroperableType ("006",ffity));
                T.ERRORty)
        end
      | IC.FFIFUNTY (_, _, _, _, loc) =>
        (E.enqueueError "Typeinf 002"
                        (loc, E.ForceImportForeignFunction("001", ffity));
         T.ERRORty)
      | IC.FFIRECORDTY (fields, loc) =>
        T.RECORDty
          (labelEnvFromList
             (map (fn (k,v) => (k, evalForceImportFFIty context dir v)) fields))

  and evalFFIty (context:TIC.context) dir ffity =
      case ffity of
        IC.FFIFUNTY (attributes, argTys, varTys, retTys, loc) =>
        let
          val dir =
              case attributes of
                SOME {unsafe, ...} => if unsafe then (#1 dir, UNSAFE) else dir
              | NONE => dir
          val (argDir, retDir) =
              case dir of
                (IMPORT, s) => ((EXPORT, s), (IMPORT, s))
              | (EXPORT, s) => ((IMPORT, s), (EXPORT, s))
          val argTys = map (evalFFIty context argDir) argTys
          val varTys = Option.map (map (evalFFIty context argDir)) varTys
          val retTys = map (evalFFIty context retDir) retTys
        in
          case (dir, varTys) of
            ((EXPORT, _), SOME _) =>
            (* ML function cannot have any variable-length argument list *)
            E.enqueueError "Typeinf 002"
                           (loc, E.NonInteroperableType ("002", ffity))
          | _ => ();
          case retTys of
            nil => ()
          | [ty] => ()
          | _ =>
            (* multiple return values is not allowed *)
            E.enqueueError "Typeinf 003"
                           (loc, E.NonInteroperableType ("003", ffity));
          TC.FFIFUNTY (attributes, argTys, varTys, retTys, loc)
        end
      | IC.FFIRECORDTY (fields, loc) =>
        (
          case dir of
            (EXPORT, _) =>
            if isUnsafe dir
               orelse RecordLabel.isOrderedList fields
            then TC.FFIRECORDTY
                   (map (fn (k,v) => (k, evalFFIty context dir v)) fields, loc)
            else (E.enqueueError "Typeinf 004"
                                 (loc, E.NonInteroperableType ("004", ffity));
                  TC.FFIBASETY (T.ERRORty, loc))
          | (IMPORT, _) =>
            if isUnsafe dir
            then TC.FFIBASETY (evalForceImportFFIty context dir ffity, loc)
            else (E.enqueueError "Typeinf 005"
                                 (loc, E.NonInteroperableType ("005", ffity));
                  TC.FFIBASETY (T.ERRORty, loc))
        )
      | IC.FFIBASETY (ty, loc) =>
        let
          val ty = ITy.evalIty context ty
        in
          if isInteroperableTy dir ty
          then TC.FFIBASETY (ty, loc)
          else (E.enqueueError "Typeinf 006"
                               (loc, E.NonInteroperableType ("006",ffity));
                TC.FFIBASETY (T.ERRORty, loc))
        end

  fun evalForeignFunTy (context:TIC.context) ffity =
      let
        val newFFIty = evalFFIty context (IMPORT, SAFE) ffity
      in
        if (case newFFIty of
              TC.FFIFUNTY _ =>
              let
                val {import, export} = ffiFTV IMPORT newFFIty
              in
                OTSet.isSubset (import, export)
              end
            | TC.FFIRECORDTY _ => false
            | TC.FFIBASETY _ => false)
        then ()
        else E.enqueueError "Typeinf 007"
                            (case newFFIty of
                               TC.FFIFUNTY (_,_,_,_,loc) => loc
                             | TC.FFIRECORDTY (_, loc) => loc
                             | TC.FFIBASETY (_, loc) => loc,
                             E.NonInteroperableType ("007",ffity));
        newFFIty
      end

  fun ffiStubTy ffity =
      case ffity of
        TC.FFIBASETY (ty, loc) => ty
      | TC.FFIFUNTY (attributes, argTys, varTys, retTys, loc) =>
        let
          val argTys = map ffiStubTy argTys
          val varTys = case varTys of NONE => nil | SOME l => map ffiStubTy l
          val retTys = map ffiStubTy retTys
        in
          T.FUNMty ([makeTupleTy (argTys @ varTys)], makeTupleTy retTys)
        end
      | TC.FFIRECORDTY (fields, loc) =>
        T.RECORDty
          (labelEnvFromList (map (fn (k,v) => (k, ffiStubTy v)) fields))

  fun evalTvarKind (context:TIC.context) tvarKind 
      : {tvarKind:T.tvarKind, dynKind:bool, reifyKind:bool, subkind:T.subkind}=
    case tvarKind of
      IC.UNIV => {tvarKind = T.UNIV, dynKind =false, reifyKind = false, subkind = T.ANY}
    | IC.JSON {dynKind} => {tvarKind = T.UNIV, dynKind = dynKind, reifyKind = false, subkind = T.JSON}
    | IC.REC fields =>
      {tvarKind = T.REC
                    (RecordLabel.Map.map
                       (ITy.evalIty context handle e => (P.print "ity3\n"; raise e))
                       fields) handle e => raise e,
       dynKind = false,
       reifyKind = false,
       subkind = T.ANY}
    | IC.BOXED => {tvarKind = T.BOXED, dynKind = false, reifyKind = false, subkind = T.ANY}
    | IC.UNBOXED => {tvarKind = T.UNIV, dynKind = false, reifyKind = false, subkind = T.UNBOXED}
    | IC.REIFY => {tvarKind = T.UNIV, dynKind =false, reifyKind = true, subkind = T.ANY}

  fun evalScopedTvars lambdaDepth (context:TIC.context) kindedTvarList loc =
    let
      fun occurresTvarInTvarKind (tvstateRef, T.UNIV) = false
        | occurresTvarInTvarKind (tvstateRef, T.BOXED) = false
        | occurresTvarInTvarKind (tvstateRef, T.OCONSTkind tyList) =
          U.occurresTyList tvstateRef tyList
        | occurresTvarInTvarKind (tvstateRef, T.OPRIMkind {instances,...}) =
          U.occurresTyList tvstateRef instances
        | occurresTvarInTvarKind (tvstateRef, T.REC fields) =
          U.occurres tvstateRef (T.RECORDty fields)

      fun setTvarkind
            (
             tvstateRef as (ref (T.TVAR{lambdaDepth, id, kind = T.KIND {eqKind, ...}, utvarOpt,...})),
             {tvarKind, dynKind, reifyKind, subkind}
            )
        = (if occurresTvarInTvarKind (tvstateRef, tvarKind) then
             E.enqueueError 
               "Typeinf 008"
               (
                loc,
                E.CyclicTvarkindSpec 
                  ("008",
                   {eq = eqKind,
                    symbol = case utvarOpt of
                               SOME {symbol,...} => symbol
                             | NONE => Symbol.mkSymbol "" Loc.noloc}
                  )
               )
           else ();
           tvstateRef := T.TVAR{lambdaDepth = lambdaDepth,
                                id = id,
                                kind = T.KIND {tvarKind = tvarKind,
                                               eqKind = eqKind,
                                               dynKind = dynKind,
                                               reifyKind = reifyKind, 
                                               subkind = subkind},
                                utvarOpt = utvarOpt
                               }
          )
        | setTvarkind _ = raise bug "tvsteteRef must be TVAR in setTvarkind"
      val (newContext, addedUtvars) =
        TIC.addUtvar lambdaDepth context kindedTvarList loc
      val addedUtvars =
        TvarMap.map
        (fn (newTvstateRef, tvarkind)
           => (newTvstateRef, evalTvarKind newContext tvarkind))
        addedUtvars
      val addedUtvars =
          TvarMap.map
            (fn (newTvstateRef, kindInfo) =>
                (setTvarkind (newTvstateRef, kindInfo); newTvstateRef))
            addedUtvars
    in
      (newContext, addedUtvars)
    end

  fun typeinfConst const =
    let
      val (ty, _, constraints) = TIU.freshTopLevelInstTy (CT.constTy const)
    in
      (ty, const, constraints)
    end

  fun isVar icexp =
      case icexp of
        IC.ICVAR _ => true
      | IC.ICEXVAR _ => true
      | IC.ICBUILTINVAR _ => true
      | IC.ICCON _ => true
      | IC.ICEXN _ => true
      | IC.ICEXN_CONSTRUCTOR _ => true
      | IC.ICEXEXN_CONSTRUCTOR _ => true
      | IC.ICEXEXN _ => true
      | IC.ICOPRIM _ => true
      | IC.ICTYPED  (icexp, ty, loc) => isVar icexp
      | IC.ICSIGTYPED  {icexp, ty, loc, revealKey} => isVar icexp
      | _ => false

  fun stripIty icexp =
      let
        fun strip icexp ityList =
          case icexp of
            IC.ICTYPED (icexp, ity, _) => strip icexp (ity :: ityList)
(* we cannot strip ICSIGTYPED
          | IC.ICSIGTYPED {icexp, implTy, absTy, ...} => strip icexp (ty :: ityList)
*)
          | _ => (icexp, ityList)
      in
        strip icexp nil
      end


  datatype abscontext = FINITE of int | INFINITE

  val inf = INFINITE
  val zero = FINITE 0
  fun inc INFINITE = INFINITE
    | inc (FINITE n) = FINITE (n + 1)
  fun decl INFINITE = INFINITE
    | decl (FINITE n) = FINITE (if n = 0 then 0 else (n - 1))
  fun iszero (FINITE 0) = true
    | iszero _ = false

  fun freeVarsInPat icpat =
      case icpat of
        IC.ICPATERROR => VarSet.empty
      | IC.ICPATWILD loc => VarSet.empty
      | IC.ICPATVAR_TRANS varInfo => VarSet.singleton varInfo
      | IC.ICPATVAR_OPAQUE varInfo => VarSet.singleton varInfo
      | IC.ICPATCON conInfo => VarSet.empty
      | IC.ICPATEXN exnInfo => VarSet.empty
      | IC.ICPATEXEXN _ => VarSet.empty
      | IC.ICPATCONSTANT constant => VarSet.empty
      | IC.ICPATCONSTRUCT {con=icpat1, arg=icpat2, loc} => freeVarsInPat icpat2
      | IC.ICPATRECORD {flex, fields, loc} =>
          foldl
          (fn ((_, icpat), set2) => VarSet.union(freeVarsInPat icpat, set2))
          VarSet.empty
          fields
      | IC.ICPATLAYERED {patVar, tyOpt, pat, loc} =>
        VarSet.add(freeVarsInPat pat, patVar)
      | IC.ICPATTYPED (icpat, ty, loc) => freeVarsInPat icpat

  fun transFunDecl
        context
        loc
        (funVarInfo, ruleList as ({args=patList, body=exp}::_)) =
      let
        val funBody =
          let
            val newVars = map (fn _ => IC.newICVar ()) patList
            val newVarExps = map (fn var => IC.ICVAR var) newVars
            val newVarPats = map (fn var => IC.ICPATVAR_TRANS var) newVars
            val argRecord = IC.ICRECORD (RecordLabel.tupleList newVarExps, loc)
            val funRules =
              map
              (fn {args, body} =>
               {args=[IC.ICPATRECORD{flex=false,
                               fields=RecordLabel.tupleList args,
                               loc=loc}],
                body=body}
               )
              ruleList
          in
            foldr
            (fn (x, y) => IC.ICFNM([{args=[x], body=y}], loc))
            (IC.ICAPPM
             (
              IC.ICFNM(funRules, loc),
              [argRecord],
              loc
              ))
            newVarPats
          end
      in
        [(IC.ICPATVAR_TRANS funVarInfo, funBody)]
      end
    | transFunDecl _ _ _ = raise bug "illegal fun decl "

  (* 2016-06-01 sasaki: resolveJoinConstraints 関数を追加 *)
  fun resolveJoinConstraints constraints =
     let
       exception JoinFailed
       exception CoerceRecord
       val changed = ref false
       fun adjustDepth (T.JOIN {res, args=(ty1,ty2), loc}) =
           case (TB.derefTy res, TB.derefTy ty1, TB.derefTy ty2) of
             (T.TYVARty (tvState1 as (ref(T.TVAR tvKind1))), 
              T.TYVARty (tvState2 as (ref(T.TVAR tvKind2))), 
              T.TYVARty (tvState3 as (ref(T.TVAR tvKind3))))
             =>
             let
               val depth = Int.min(Int.min(#lambdaDepth tvKind1, #lambdaDepth tvKind2), #lambdaDepth tvKind3)
             in
               (TB.adjustDepthInTy changed depth res;
                TB.adjustDepthInTy changed depth ty1;
                TB.adjustDepthInTy changed depth ty2)
             end
           | (_, 
              T.TYVARty (tvState2 as (ref(T.TVAR tvKind2))), 
              T.TYVARty (tvState3 as (ref(T.TVAR tvKind3))))
             =>
             let
               val depth = Int.min(#lambdaDepth tvKind2, #lambdaDepth tvKind3)
             in
               (TB.adjustDepthInTy changed depth res;
                TB.adjustDepthInTy changed depth ty1;
                TB.adjustDepthInTy changed depth ty2)
             end
           | (T.TYVARty (tvState1 as (ref(T.TVAR tvKind1))), 
              _,
              T.TYVARty (tvState3 as (ref(T.TVAR tvKind3))))
             =>
             let
               val depth = Int.min(#lambdaDepth tvKind1, #lambdaDepth tvKind3)
             in
               (TB.adjustDepthInTy changed depth res;
                TB.adjustDepthInTy changed depth ty1;
                TB.adjustDepthInTy changed depth ty2)
             end
           | (T.TYVARty (tvState1 as (ref(T.TVAR tvKind1))), 
              T.TYVARty (tvState2 as (ref(T.TVAR tvKind2))),
              _)
             =>
             let
               val depth = Int.min(#lambdaDepth tvKind1, #lambdaDepth tvKind2)
             in
               (TB.adjustDepthInTy changed depth res;
                TB.adjustDepthInTy changed depth ty1;
                TB.adjustDepthInTy changed depth ty2)
             end
           | _ => ()

       datatype TyConKind 
         = DATACon of T.tyCon
         | UNIV 
         | FLEXIBLERECORD
         | JOINRECORD of T.ty RecordLabel.Map.map * T.ty  RecordLabel.Map.map
         | ALLRECORD of T.ty RecordLabel.Map.map * T.ty  RecordLabel.Map.map * T.ty  RecordLabel.Map.map
       fun isTvarKind ty =
           case TB.derefTy ty of
             T.RECORDty _ => true
           | T.TYVARty (ref (T.TVAR {kind = T.KIND {tvarKind = T.REC _,...},...})) => true
           | _ => false
       fun isRigid ty =
           case TB.derefTy ty of
             T.TYVARty (ref(T.TVAR {kind = T.KIND {tvarKind=T.OCONSTkind _,...},...})) => true
           | T.CONSTRUCTty {tyCon = {id, dtyKind=T.BUILTIN _, ...}, args=[]} =>
             if TypID.eq (id, #id BT.unitTyCon) then false else true
           | T.CONSTRUCTty {tyCon, args} =>  
             List.all isRigid args
           | T.FUNMty (args, body) =>
             List.all isRigid args andalso isRigid body
           | _ => false
       fun isOption ty =
           case TB.derefTy ty of
             T.CONSTRUCTty {tyCon = {id, ...}, args=[argTy]} =>
             if TypID.eq (id, #id BT.optionTyCon) then true else false
           | _ => false
       fun coerceRecord ty = 
           case TB.derefTy ty of
             T.RECORDty tyMap => ty
           | T.TYVARty (ref (T.TVAR {kind = T.KIND {tvarKind = T.REC tyMap,...},...})) => ty
           | _ => 
             let
               val newRecTvarTy  = newRecTvarTy ()
             in
               (U.unify [(ty,newRecTvarTy)]
                handle U.Unify => raise CoerceRecord;
                newRecTvarTy)
             end
       fun getRecordMap ty =
           case TB.derefTy ty of
             T.RECORDty tyMap => SOME tyMap
           | T.CONSTRUCTty {tyCon, args = nil} =>
             if TypID.eq (#id tyCon, #id BT.unitTyCon) then 
               SOME (RecordLabel.Map.empty)
             else NONE
           | _ => NONE
       fun factorTyCon (res, ty1, ty2) = 
           (
           case (TB.derefTy res, TB.derefTy ty1, TB.derefTy ty2) of
             (T.CONSTRUCTty {tyCon, args = [arg]}, _, _) => 
             DATACon tyCon
           | (_, T.CONSTRUCTty {tyCon, args = [arg]}, _) => 
             DATACon tyCon
           | (_, _, T.CONSTRUCTty {tyCon, args = [arg]}) => 
             DATACon tyCon
           | (res, ty1, ty2) =>
             (case (getRecordMap res, getRecordMap ty1, getRecordMap ty2) of
                (SOME resMap, SOME ty1Map, SOME ty2Map) =>
                ALLRECORD (resMap, ty1Map, ty2Map)
              | (NONE, SOME ty1Map, SOME ty2Map) => 
                JOINRECORD (ty1Map, ty2Map)
              | _ => 
                if isTvarKind res orelse isTvarKind ty1 orelse isTvarKind ty2
                then FLEXIBLERECORD
                else UNIV
             )
           )
       fun reduceConstraints nil = nil
         | reduceConstraints ((c as T.JOIN {res, args=(ty1,ty2), loc}) :: constraints) = 
           if isRigid res orelse isRigid ty1 orelse isRigid ty2 then
             (U.unify [(res, ty1), (ty1, ty2)]
              handle U.Unify =>
                     (E.enqueueError 
                        "Typeinf 009"
                        (loc, E.JoinFailed ("009", {res = res, ty1=ty1, ty2=ty2}));
                      raise JoinFailed);
              changed := true;
              reduceConstraints constraints)
           else 
             (case factorTyCon (res, ty1, ty2) of
                UNIV => c :: reduceConstraints constraints
              | DATACon tyCon =>
                let
                  val elementRes = newJoinTvarTy()
                  val newRes = T.CONSTRUCTty {tyCon=tyCon, args = [elementRes]}
                  val elementTy1 = newJoinTvarTy()
                  val newTy1 = T.CONSTRUCTty {tyCon=tyCon, args = [elementTy1]}
                  val elementTy2 = newJoinTvarTy()
                  val newTy2 = T.CONSTRUCTty {tyCon=tyCon, args = [elementTy2]}
                in
                  (U.unify [(res, newRes), (ty1, newTy1), (ty2, newTy2)]
                   handle U.Unify => 
                          (E.enqueueError 
                             "Typeinf 010"
                             (loc, E.JoinFailed ("010", {res = res, ty1=ty1, ty2=ty2}));
                           raise JoinFailed);
                   changed := true;
                   reduceConstraints (T.JOIN {res = elementRes, args = (elementTy1, elementTy2), loc=loc} 
                                      :: constraints)
                  )
                end
              | ALLRECORD (resMap, ty1Map, ty2Map) => 
                let
                  val ty1Ty2Map = RecordLabel.Map.mergeWith (fn x => SOME x) (ty1Map, ty2Map) 
                  val _ = RecordLabel.Map.mergeWith 
                            (fn (NONE, _) => 
                                (E.enqueueError 
                                   "Typeinf 011"
                                   (loc, E.JoinFailed ("011", {res = res, ty1=ty1, ty2=ty2}));
                                 raise JoinFailed)
                              | (_, NONE) => 
                                (E.enqueueError 
                                   "Typeinf 012"
                                   (loc, E.JoinFailed ("012", {res = res, ty1=ty1, ty2=ty2}));
                                 raise JoinFailed)
                              | _ => NONE)
                            (resMap, ty1Ty2Map)
                  fun getTy (resMap, label) = 
                      case RecordLabel.Map.find(resMap, label) of
                        NONE => raise Bug.Bug "reduceConstraints getTy"
                      | SOME x => x
                  val (equalPairs, newConstraints) =
                      RecordLabel.Map.foldli
                        (fn (label, (SOME ty1, SOME ty2), (equalPairs, newConstraints)) =>
                            let
                              val elemRes = getTy (resMap, label)
                            in
                              (equalPairs, T.JOIN {res=elemRes, args=(ty1, ty2), loc=loc}::newConstraints)
                            end
                          | (label, (SOME ty1, NONE), (equalPairs, newConstraints)) =>
                            let
                              val elemRes = getTy (resMap, label)
                            in
                              ((elemRes, ty1)::equalPairs, newConstraints)
                            end
                          | (label, (NONE, SOME ty2), (equalPairs, newConstraints)) =>
                            let
                              val elemRes = getTy (resMap, label)
                            in
                              ((elemRes, ty2)::equalPairs, newConstraints)
                            end
                          | (label, _,_) => raise Bug.Bug "reduceConstraint RECORD"
                        )
                        (nil, nil)
                        ty1Ty2Map
                in
                  (U.unify equalPairs
                   handle U.Unify =>
                          (E.enqueueError 
                             "Typeinf 013"
                             (loc, E.JoinFailed ("013", {res = res, ty1=ty1, ty2=ty2}));
                           raise JoinFailed);
                   changed := true;
                   reduceConstraints (newConstraints @ constraints)
                  )
                end
              | JOINRECORD (ty1Map, ty2Map) => 
                let
                  val ty1Ty2Map = RecordLabel.Map.mergeWith (fn x => SOME x) (ty1Map, ty2Map) 
                  val (resMap, newConstraints) =
                      RecordLabel.Map.foldli
                        (fn (label, (SOME ty1, SOME ty2), (resMap, newConstraints)) =>
                            let
                              val newJoinTvarTy = newJoinTvarTy ()
                              val resMap = RecordLabel.Map.insert(resMap, label, newJoinTvarTy)
                            in
                              (resMap, T.JOIN {res=newJoinTvarTy, args=(ty1, ty2), loc=loc}::newConstraints)
                            end
                          | (label, (SOME ty1, NONE), (resMap, newConstraints)) =>
                            let
                              val resMap = RecordLabel.Map.insert(resMap, label, ty1)
                            in
                              (resMap, newConstraints)
                            end
                          | (label, (NONE, SOME ty2), (resMap, newConstraints)) =>
                            let
                              val resMap = RecordLabel.Map.insert(resMap, label, ty2)
                            in
                              (resMap, newConstraints)
                            end
                          | (label, _,_) => raise Bug.Bug "reduceConstraint RECORD"
                        )
                        (RecordLabel.Map.empty, nil)
                        ty1Ty2Map
                in
                  (U.unify [(res, T.RECORDty resMap)]
                   handle U.Unify =>
                          (E.enqueueError 
                             "Typeinf 014"
                             (loc, E.JoinFailed ("014", {res = res, ty1=ty1, ty2=ty2}));
                           raise JoinFailed);
                   changed:=true;
                   reduceConstraints (newConstraints @ constraints)
                  )
                end
              | FLEXIBLERECORD => 
                (let
                   val newRes = coerceRecord res
                   val newTy1 = coerceRecord ty1
                   val newTy2 = coerceRecord ty2
                 in
                   T.JOIN {res=newRes, args=(newTy1, newTy2), loc=loc} 
                   :: reduceConstraints constraints
                 end
                 handle CoerceRecord =>
                        (E.enqueueError 
                           "Typeinf 015"
                           (loc, E.JoinFailed ("015", {res = res, ty1=ty1, ty2=ty2}));
                         raise JoinFailed)
                )
             )
       fun doReduce constraints =
           let
             val _ = changed := false
             val constraints = reduceConstraints constraints
           in
             if !changed then doReduce constraints
             else constraints
           end
       fun doAdjust constraints =
           let
             val _ = changed := false
             val _ = map adjustDepth constraints
           in
             if !changed then doAdjust constraints
             else ()
           end
       val constraints = doReduce constraints
           handle JoinFailed => constraints
       val _ = doAdjust constraints
     in
       constraints
     end

  fun removeBoundConstraints constraints =
      let
        fun includingBTyvar ty =
            case TB.derefTy ty of
              T.BOUNDVARty _ => true
            | T.POLYty {boundtvars, constraints, body} => true
            | T.RECORDty fields =>
              not (RecordLabel.Map.isEmpty 
                     (RecordLabel.Map.filter 
                        (fn ty => includingBTyvar ty) 
                        fields))
            | T.CONSTRUCTty {tyCon, args} =>
              List.exists (fn ty => includingBTyvar ty) args
            | T.FUNMty (args, body) =>
              List.exists (fn ty => includingBTyvar ty) args orelse
              includingBTyvar body
            | _ => false
        fun isBound (T.JOIN {res, args = (ty1, ty2), loc}) = 
            includingBTyvar res orelse includingBTyvar ty1 orelse includingBTyvar ty2
      in
        List.filter (fn x => not (isBound x)) constraints
      end
  
 (* type generalization *)
  fun generalizer (ty, lambdaDepth) =
    if E.isError()
      then {boundEnv = BoundTypeVarID.Map.empty, removedTyIds = OTSet.empty, boundConstraints = nil}
    else
      let
        (* 2016-06-16 sasaki: generalize前に解消可能な制約を解消 *)
        val _ = constraints := resolveJoinConstraints (!constraints)
        val newTy = TB.generalizer (ty, !constraints, lambdaDepth)
        val _ = constraints := removeBoundConstraints (!constraints)
      in
        newTy
      end

  fun mergeBoundEnvs (boundEnv1, boundEnv2) =
      BoundTypeVarID.Map.unionWith
      (fn _ => raise bug "duplicate boundtvars in mergeBoundEnvs")
      (boundEnv2, boundEnv1)

  (**  Preform monomorphic modus ponens.  *)
  fun monoApplyM basis {termLoc,
                        funTy,
                        argTyList,
                        funTpexp,
                        funLoc,
                        argTpexpList} =
      let
        val (domtyList, ranty, instlist, constraints) = TB.coerceFunM (funTy, argTyList)
        val _ = addConstraints constraints
        val newFunTpexp =
          case instlist of
            nil => funTpexp
          | _ =>
              TC.TPTAPP
                {exp=funTpexp,
                 expTy=funTy,
                 instTyList=instlist,
                 loc=termLoc}
        val tyPairs = ListPair.zip (argTyList, domtyList)

(* 
        (* subst to constraints if funTy is polyTy *)
        val _ = case instlist of nil => ()
                | _ => 
                  let 
                    (* FIXME: This code uses an assumption of BoundTypeVarID functions
                     *        returns list in same order.
                     *)
                    val btvKeys = case funTy of 
                                    T.POLYty {boundtvars, ...} => 
                                    BoundTypeVarID.Map.listKeys boundtvars
                                  | _ => nil
                    val subst =
                        ListPair.foldl
                            (fn (key, ty, map) => BoundTypeVarID.Map.insert (map, key, ty))
                            BoundTypeVarID.Map.empty
                            (btvKeys, instlist)
                    fun substConstraints nil = nil
                      | substConstraints (({ret, args = (arg1, arg2)}, loc)::t) =
                        ({ret = TB.substBTvar subst ret,
                          args = (TB.substBTvar subst arg1,
                                  TB.substBTvar subst arg2)},
                         loc)::
                        substConstraints t
                  in
                    constraints := substConstraints (!constraints)
                  end    
*)
      in
        (U.unify tyPairs;
         (
          ranty,
          TC.TPAPPM {funExp = newFunTpexp,
                     funTy = T.FUNMty(domtyList, ranty),
                     argExpList = argTpexpList,
                     loc=termLoc}
         )
        )
        handle
        U.Unify =>
        (
         E.enqueueError "Typeinf 016"
           (termLoc,
            E.TyConListMismatch
              ("016",{argTyList = argTyList, domTyList = domtyList}));
         (T.ERRORty, TC.TPERROR)
        )
      end
    handle TB.CoerceFun =>
      (
       E.enqueueError "Typeinf 017" (funLoc, E.NonFunction ("017",{ty = funTy}));
       (T.ERRORty, TC.TPERROR)
       )

  fun revealTy key ty =
      case TB.derefTy ty of
        T.SINGLETONty _ => raise bug "SINGLETONty in revealTy"
      | T.BACKENDty _ => raise bug "BACKENDty in revealTy"
      | T.ERRORty => ty
      | T.DUMMYty _ => ty
      | T.TYVARty _ => ty
      | T.BOUNDVARty _ => ty
      | T.FUNMty (tyList,ty) =>
        T.FUNMty (map (revealTy key) tyList, revealTy key ty)
      | T.RECORDty tyMap => T.RECORDty (RecordLabel.Map.map (revealTy key) tyMap)
      | T.CONSTRUCTty
          {tyCon= tyCon as {dtyKind=T.OPAQUE{opaqueRep,revealKey},...},args} =>
        let
          val args = map  (revealTy key) args
        in
          if RevealID.eq(key, revealKey) then
            case opaqueRep of
              T.TYCON tyCon =>
              T.CONSTRUCTty{tyCon=tyCon, args= args}
            | T.TFUNDEF {iseq, arity, polyTy} =>
              (* here we do type beta reduction *)
              U.instOfPolyTy(polyTy, args)
         (* 2012-8-10 bug 234_opaqueArg.sml
          else ty
         *)
          else T.CONSTRUCTty{tyCon=tyCon, args=args}
        end
      | T.CONSTRUCTty{tyCon,args} =>
        T.CONSTRUCTty{tyCon=tyCon, args= map (revealTy key) args}
      | T.POLYty polyTy => ty (* polyty will not be unified *)

  fun decomposeValbind
        lambdaDepth
        (context:TIC.context)
        (icpat, icexp) =
    let
      fun generalizeIfNotExpansive lambdaDepth ((ty, tpexp), loc) =
        if E.isError() orelse TCU.expansive tpexp then
          (ty, tpexp)
        else
          let
            val {boundEnv,boundConstraints,...} = generalizer (ty, lambdaDepth)
          in
            if BoundTypeVarID.Map.isEmpty boundEnv then (ty, tpexp)
            else
              (case tpexp of
                 TC.TPFNM {argVarList=argVarPathInfoList,
                           bodyTy=ranTy,
                           bodyExp=typedExp,
                           loc=loc} =>
                 (
                  T.POLYty
                    {boundtvars = boundEnv,
                     constraints = boundConstraints,
                     body = ty},
(*
  2011-09-02 ohori:
  this causes the bug 099_provide.sml
  Since the type may be opaque, we cannot use the actual type
  here.
                     body = T.FUNMty(map #ty argVarPathInfoList, ranTy)},
*)
                  TC.TPPOLYFNM {btvEnv=boundEnv,
                                argVarList=argVarPathInfoList,
                                bodyTy=ranTy,
                                bodyExp=typedExp,
                                loc=loc}
                 )
               | TC.TPPOLY{btvEnv=boundEnv1,
                           expTyWithoutTAbs=ty1,
                           exp=tpexp1,
                           loc=loc1} =>
                 (
                  case ty of
                    T.POLYty{boundtvars=boundEnv2, constraints=boundConstraints2, body= ty2} =>
                    (T.POLYty
                       {boundtvars = mergeBoundEnvs(boundEnv,boundEnv2),
                        constraints = boundConstraints @ boundConstraints2,
                        body = ty2},
                     TC.TPPOLY{btvEnv=mergeBoundEnvs(boundEnv,boundEnv1),
                               expTyWithoutTAbs=ty1,
                               exp=tpexp1,
                               loc=loc1}
                    )
                  | _ => raise bug "non polyty for TPPOLY (1)"
                 )
               | TC.TPPOLYFNM {btvEnv=boundEnv1,
                               argVarList=argVarPathInfo,
                               bodyTy=ranTy,
                               bodyExp=tpexp1,
                               loc=loc1} =>
                 (
                  case ty of
                    T.POLYty{boundtvars=boundEnv2, constraints=boundConstraints2, body= ty2} =>
                    (T.POLYty
                       {boundtvars = mergeBoundEnvs (boundEnv, boundEnv2),
                        constraints = boundConstraints @ boundConstraints2,
                        body = ty2},
                     TC.TPPOLYFNM
                       {btvEnv=mergeBoundEnvs (boundEnv, boundEnv1),
                        argVarList=argVarPathInfo,
                        bodyTy=ranTy,
                        bodyExp=tpexp1,
                        loc=loc1}
                    )
                  | _ => raise bug "non polyty for TPPOLY (2)"
                 )
               | _ => (T.POLYty {boundtvars = boundEnv, constraints = boundConstraints, body = ty},
                       TC.TPPOLY {btvEnv=boundEnv,
                                  expTyWithoutTAbs=ty,
                                  exp=tpexp,
                                  loc=loc}
                      )
              )
          end

      fun isStrictValuePat icpat =
          case icpat of
            IC.ICPATERROR => false
          | IC.ICPATWILD _ => true
          | IC.ICPATVAR_TRANS _ => true
          | IC.ICPATVAR_OPAQUE _ => true
          | IC.ICPATCON _ => false
          | IC.ICPATEXN _ => false
          | IC.ICPATEXEXN _ => false
          | IC.ICPATCONSTANT _ => false
          | IC.ICPATCONSTRUCT _ => false
          | IC.ICPATRECORD {flex, fields, loc} =>
            foldl
              (fn ((_, icpat), bool) =>
                  bool andalso isStrictValuePat icpat)
              true
              fields
          | IC.ICPATLAYERED {patVar, tyOpt, pat, loc} =>
            isStrictValuePat pat
          | IC.ICPATTYPED (icpat, ty, loc) => isStrictValuePat icpat

      (* This returns (localBinds, varBinds, extraBinds, tpexp, ty) *)
      fun decompose
            lambdaDepth
            (context:TIC.context)
            (icpat, icexp) =
        let
          val icpatLoc = IC.getLocPat icpat
          val icexpLoc = IC.getLocExp icexp
          fun makeCase (icpat, icexp) =
            let
              val resVarSet = freeVarsInPat icpat
              val icpat = IDCalcUtils.copyPat icpat
              val varSet = freeVarsInPat icpat
              val icpatLoc = IC.getLocPat icpat
              val icexpLoc = IC.getLocExp icexp
              val loc = Loc.mergeLocs (icpatLoc, icexpLoc)
            in
              if VarSet.isEmpty varSet
                then
                  let
                    val newIcexp =
                      IC.ICCASEM
                      (
                       [icexp],
                       [{args=[icpat], body=IC.ICRECORD(nil, icpatLoc)}],
                       PatternCalc.BIND,
                       loc
                       )
                    val (ty, tpexp) =
                        typeinfExp lambdaDepth inf context newIcexp
                    val varInfo = TCU.newTCVarInfo loc ty
                  in
                    (nil, [(varInfo, tpexp)], nil, TC.TPVAR varInfo, ty)
                  end
              else
                case VarSet.listItems varSet of
                  [x] =>
                    let
                      val newIcexp =
                        IC.ICCASEM
                        (
                         [icexp],
                         [{args=[icpat], body=IC.ICVAR x}],
                         PatternCalc.BIND,
                         loc
                         )
                      val (ty, tpexp) =
                          typeinfExp lambdaDepth inf context newIcexp
                      val (longsymbol, id) =
                          case VarSet.listItems resVarSet of
                            [{longsymbol, id}] => (longsymbol, id)
                          | _ => raise bug "non singleton resVarSet"
                      val varInfo = {path = longsymbol, id = id, ty = ty, opaque=false}
                    in
                      (
                        nil,
                        [(varInfo, tpexp)],
                        nil,
                        TC.TPVAR varInfo,
                        ty
                      )
                    end
                | _ =>
                  let
                    val resTuple =
                      RecordLabel.tupleList
                        (map (fn x => IC.ICVAR x)
                             (VarSet.listItems varSet))
                    val newIcexp =
                      IC.ICCASEM
                      (
                       [icexp],
                       [{args=[icpat], body=IC.ICRECORD (resTuple, icpatLoc)}],
                       PatternCalc.BIND,
                       loc
                       )
                    val (tupleTy, tpexp) =
                        typeinfExp lambdaDepth inf context newIcexp
                    val newVarInfo = TCU.newTCVarInfo loc tupleTy
                    val tyList =
                      case tupleTy of
                        T.RECORDty tyFields => RecordLabel.Map.listItems tyFields
                      | T.ERRORty => map (fn x => T.ERRORty) resTuple
                      | _ => raise bug "decompose"
                    val resBinds =
                      map
                      (fn (label, ({longsymbol, id}, ty)) =>
                        (
                         {path = longsymbol, id = id, ty = ty, opaque=false},
                         TC.TPSELECT
                         {
                          label=label,
                          exp=TC.TPVAR newVarInfo,
                          expTy=tupleTy,
                          resultTy = ty,
                          loc=loc
                          }
                         ))
                      (RecordLabel.tupleList
                         (ListPair.zip (VarSet.listItems resVarSet, tyList)))
                  in
                    (
                     [(newVarInfo, tpexp)],
                     resBinds,
                     nil,
                     TC.TPVAR newVarInfo,
                     tupleTy
                     )
                  end
            end
        in (* decompose body *)
          if not (isStrictValuePat icpat) then makeCase (icpat, icexp)
          else
            case icpat of
              IC.ICPATERROR => raise bug "expansive pat"
            | IC.ICPATWILD loc =>
                let
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    lambdaDepth
                    (typeinfExp lambdaDepth zero context icexp, icexpLoc)
                  val newVarInfo = TCU.newTCVarInfo loc ty
                in
                  (nil,[(newVarInfo,tpexp)], nil, TC.TPVAR newVarInfo, ty)
                end
            | IC.ICPATVAR_TRANS {longsymbol,id} =>
                let
                  val loc = Symbol.longsymbolToLoc longsymbol
                  val (ty, tpexp) =
                      typeinfExp lambdaDepth zero context icexp
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    lambdaDepth
                    ((ty, tpexp), icexpLoc)
                  val varInfo  = {path = longsymbol, id=id, ty = ty, opaque=false}
                in
                  (
                   nil,
                   [(varInfo, tpexp)],
                   nil,
                   TC.TPVAR varInfo,
                   ty
                   )
                end
            | IC.ICPATVAR_OPAQUE {longsymbol,id} =>
                let
                  val loc = Symbol.longsymbolToLoc longsymbol
                  val (ty, tpexp) =
                      typeinfExp lambdaDepth zero context icexp
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    lambdaDepth
                    ((ty, tpexp), icexpLoc)
                  val varInfo  = {path = longsymbol, id=id, ty = ty, opaque=true}
                in
                  (
                   nil,
                   [(varInfo, tpexp)],
                   nil,
                   TC.TPVAR varInfo,
                   ty
                   )
                end
            | IC.ICPATCON _ => raise bug "expansive pat"
            | IC.ICPATEXN _ => raise bug "expansive pat"
            | IC.ICPATEXEXN _ => raise bug "expansive pat"
            | IC.ICPATCONSTANT _ => raise bug "expansive pat"
            | IC.ICPATCONSTRUCT _ => raise bug "expansive pat"
            | IC.ICPATRECORD {flex, fields=stringIcpatList, loc=loc1} =>
              (case icexp of
                 IC.ICRECORD(stringIcexpList, loc2) =>
                 let
                   val icpatSEnvMap =
                       foldl
                         (fn ((l, icpat), icpatSEnvMap) =>
                             RecordLabel.Map.insert(icpatSEnvMap, l, icpat))
                         RecordLabel.Map.empty
                         stringIcpatList
                   val expLabelSet =
                       foldl
                         (fn ((l, _), lset) => RecordLabel.Set.add(lset, l))
                         RecordLabel.Set.empty
                         stringIcexpList
                   val _ =
                   (* check that the labels of patterns is
                    * included in the labels of expressions
                    *)
                       RecordLabel.Map.appi
                       (fn (l, _) =>
                           if RecordLabel.Set.member(expLabelSet, l)
                           then ()
                           else raise E.RecordLabelSetMismatch "009")
                       icpatSEnvMap
                   val labelIcpatIcexpList =
                       map
                         (fn (label, icexp) =>
                             let
                               val icpat =
                                   case RecordLabel.Map.find(icpatSEnvMap, label) of
                                     SOME icpat => icpat
                                   | NONE =>
                                     if flex
                                     then IC.ICPATWILD loc1
                                     else raise E.RecordLabelSetMismatch "010"
                             in
                               (label, icpat, icexp)
                             end)
                         stringIcexpList
                   val (localBinds,
                        patternVarBinds,
                        extraBinds,
                        labelTyTpexpListRev
                       ) =
                       foldl
                        (fn (
                             (label, icpat, icexp),
                             (
                              localBinds,
                              patternVarBinds,
                              extraBinds,
                              labelTyTpexpListRev
                              )
                             ) =>
                         let
                           val (localBinds1,
                                patternVarBinds1,
                                extraBinds1,
                                tpexp,
                                ty) =
                             decompose
                             lambdaDepth
                             context
                             (icpat, icexp)
                         in
                           (
                            localBinds @ localBinds1,
                            patternVarBinds @ patternVarBinds1,
                            extraBinds @ extraBinds1,
                            (label, (ty, tpexp)) :: labelTyTpexpListRev
                            )
                         end)
                        (nil, nil, nil, nil)
                        labelIcpatIcexpList
                   val labelTyTpexpList = List.rev labelTyTpexpListRev
                   val (resultTy, recordExp) =
                       makeTPRecord labelTyTpexpList loc2
                 in
                   (
                    localBinds,
                    patternVarBinds,
                    extraBinds,
                    recordExp,
                    resultTy
                   )
                 end
               | _ =>
                 let
                   val (tyBody, tpexpBody) =
                       typeinfExp lambdaDepth zero context icexp
                   val (_, tyPat, _ ) = typeinfPat lambdaDepth context icpat
                   val _ =
                       (U.unify [(tyBody, tyPat)])
                       handle U.Unify =>
                              raise
                                E.PatternExpMismatch
                                  ("011",{patTy = tyPat, expTy= tyBody})
(* this results in incorrect typing for
    fn x => let val {a,b,c} = x in a end
                   val (_, tyPat, _ ) = typeinfPat lambdaDepth context icpat
                   val _ =
                       (U.unify [(tyBody, tyPat)])
                       handle U.Unify =>
                              raise
                                E.PatternExpMismatch
                                  ("011",{patTy = tyPat, expTy= tyBody})
*)
                   val (bodyVar as {longsymbol, id}) = IC.newICVar()
                   val icBodyVar = IC.ICVAR bodyVar
                   val tpVarInfo = {path=longsymbol, id=id, ty=tyBody, opaque=false}
                   val context =
                       TIC.bindVar(lambdaDepth,
                                   context,
                                   bodyVar,
                                   TC.VARID tpVarInfo)
                   (* bug 153; check this;
                      Since we introduce a binding context, the subexpression (icexp below)
                      must be typed with an incremented lambdaDepth.
                   *)
                   val lambdaDepth = incDepth ()

                   val labelIcpatIcexpList =
                       map
                         (fn (label, icpat) =>
                             (
                              label,
                              icpat,
                              IC.ICSELECT(label, icBodyVar, loc1)
                             ))
                         stringIcpatList
                   val (localBinds,variableBinds,extraBinds)
                     =
                     foldl
                       (fn ((label, icpat, icexp),
                            (localBinds,variableBinds,extraBinds)
                           )
                           =>
                           let
                             val (localBinds1,
                                  variableBinds1,
                                  extraBinds1,
                                  tpexp,
                                  ty) =
                                 decompose
                                   lambdaDepth
                                   context
                                   (icpat, icexp)
                           in
                             (
                              localBinds @ localBinds1,
                              variableBinds @ variableBinds1,
                              extraBinds @ extraBinds1
                             )
                           end)
                       (nil, nil, nil)
                       labelIcpatIcexpList
                 in
                   (
                    [(tpVarInfo,tpexpBody)]@localBinds,
                    variableBinds,
                    extraBinds,
                    TC.TPVAR tpVarInfo,
                    tyBody
                   )
                 end
              )
            | IC.ICPATLAYERED {patVar={longsymbol, id}, tyOpt, pat, loc} =>
              let
                val icexp =
                    case tyOpt of
                      SOME rawty => IC.ICTYPED (icexp, rawty, icexpLoc)
                    | NONE => icexp
                val (localBinds, variableBinds, extraBinds, tpexp, ty) =
                    decompose
                      lambdaDepth
                      context
                      (pat, icexp)
              in
                (
                 localBinds,
                 variableBinds,
                 extraBinds
                 @ [({path=longsymbol, id=id, ty=ty, opaque=false},
                     tpexp)],
                 tpexp,
                 ty
                )
              end
            | IC.ICPATTYPED (icpat, ity, loc) =>
              let
                val icexp = IC.ICTYPED (icexp, ity, icexpLoc)
              in
                decompose lambdaDepth context (icpat, icexp)
              end
        end (* end of decpomose *)
    (* decomposeValbind body *)
    in
      let
        val (localBinds, variableBinds, extraBinds, tpexp, ty) =
            decompose lambdaDepth context (icpat, icexp)
      in
        (localBinds, variableBinds, extraBinds)
      end
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
          tvarKind : tvarKind,
          eqKind : eqKind,
          utvarOpt : string option
       }
    When a binding {x:tau} is entered in the typeInferenceContext (context),
    the lambdaDepth of each t in tau is set to the lambdaDepth of the context
    where x occurres.
    When two types are unified, their lambda depth is adjusted by taking
    the minimal.
   *)

  and typeinfForeach lambdaDepth applyDepth (context : TIC.context)  {data, pred, iterator, loc} =
      let
        exception ForeachError
        fun arrayPatTy elemTy =
            RyU.TupleTy
            [intTy,
             RyU.RecordTy
               [("value", intTy --> elemTy), 
                ("newValue", intTy --> elemTy), 
                ("size", intTy)
               ]
            ]
        val (dataTy, dataTpexp) = typeinfExp lambdaDepth inf context data  
        val (dataTy, constraints1, dataTpexp) = TCU.freshInst (dataTy, dataTpexp)
        val _ = addConstraints constraints1
        val (iteratorTy, iteratorTpexp) = typeinfExp lambdaDepth inf context iterator 
        val (iteratorTy, constraints2, iteratorTpexp) = TCU.freshInst (iteratorTy, iteratorTpexp)
        val _ = addConstraints constraints2
        val (predTy, predTpexp) = typeinfExp lambdaDepth inf context pred  
        val (predTy, constraints3, predTpexp) = TCU.freshInst (predTy, predTpexp)
        val _ = addConstraints constraints3
        val argTy = newReifyTvarTy ()
        val elemTy = newReifyTvarTy ()
        val _ = 
            U.unify
              [
               (iteratorTy, argTy --> elemTy),
               (predTy, argTy --> boolTy),
               (dataTy, arrayTy elemTy),
               (argTy, arrayPatTy elemTy)
              ]
            handle U.Unify =>
                   (E.enqueueError "Typeinf 0174" (loc, E.ForEachTypeError "0174");
                    raise ForeachError)
        val resultTpexp = 
            TC.TPFOREACH
              {data = dataTpexp, 
               dataTy = dataTy, 
               iterator = iteratorTpexp, 
               iteratorTy = iteratorTy, 
               pred = predTpexp, 
               predTy = predTy, 
               loc = loc}
      in
        (dataTy, resultTpexp)
      end
      handle ForeachError => (T.ERRORty, TC.TPERROR)

  and typeinfForeachData lambdaDepth applyDepth (context : TIC.context)  
                         {data, whereParam, pred, iterator, loc} =
      let
(*
  type ('para, 'seq) whereParam = 
       {
        default:'para,
        finalize : {value: int -> 'para} -> 'seq,
        size: 'seq -> int,
        traverse:(('para -> int) -> 'seq -> int)
       }

       {size: 'seq -> int,
        traverse:(('para -> int) -> 'seq -> int), 
        default:'para,
        finalize : {value: int -> 'para} -> 'seq}
*)
             
        exception ForeachError
      in
      let
        val (dataTy, dataTpexp) = typeinfExp lambdaDepth inf context data  
        val (iteratorTy, iteratorTpexp) = typeinfExp lambdaDepth inf context iterator 
        val (predTy, predTpexp) = typeinfExp lambdaDepth inf context pred  



        val (dataTy, dataTpexp) = typeinfExp lambdaDepth inf context data  
        val (dataTy, constraints1, dataTpexp) = TCU.freshInst (dataTy, dataTpexp)
        val _ = addConstraints constraints1
        val (whereParamTy, whereParamTpexp) = typeinfExp lambdaDepth inf context whereParam  
        val (whereParamTy, constraints2, whereParamTpexp) = TCU.freshInst (whereParamTy, whereParamTpexp)
        val _ = addConstraints constraints2
        val (iteratorTy, iteratorTpexp) = typeinfExp lambdaDepth inf context iterator 
        val (iteratorTy, constraints3, iteratorTpexp) = TCU.freshInst (iteratorTy, iteratorTpexp)
        val _ = addConstraints constraints3
        val (predTy, predTpexp) = typeinfExp lambdaDepth inf context pred  
        val (predTy, constraints4, predTpexp) = TCU.freshInst (predTy, predTpexp)
        val _ = addConstraints constraints4

        val seqTy = newUnivTvarTy ()
        val paraTy = newUnivTvarTy ()
        val argTy = newUnivTvarTy ()
        val indexTy = T.CONSTRUCTty {tyCon=UP.FOREACH_index_tyCon (), args=nil}
        val argPatTy =
            RyU.TupleTy
            [indexTy,
             RyU.RecordTy
               [("value", indexTy --> paraTy), 
                ("newValue", indexTy --> paraTy), 
                ("size", intTy)
               ]
            ]
        val wahreParamPatTy =
            RyU.RecordTy
            [
             ("initialize", (seqTy --> indexTy) --> (seqTy --> paraTy)),
             ("finalize", (indexTy --> seqTy) --> (paraTy --> seqTy))
(*
             ("size", seqTy --> intTy),
             ("default", paraTy),
*)
            ]
val _ = P.print "\nwhereParamTy\n"
val _ = P.printTy whereParamTy
val _ = P.print "\nwahreParamPatTy\n"
val _ = P.printTy wahreParamPatTy
val _ = P.print "\n"
        val _ = 
            U.unify
              [
               (iteratorTy, argTy --> paraTy),
               (whereParamTy, wahreParamPatTy), 
               (predTy, argTy --> boolTy),
               (dataTy, seqTy),
               (argTy, argPatTy)
              ]
            handle U.Unify =>
                   (E.enqueueError "Typeinf 0174" (loc, E.ForEachTypeError "0174");
P.print "\nargTy --> paraTy\n";
P.printTy (argTy --> paraTy);
P.print "\niteratorTy\n";
P.printTy iteratorTy;
P.print "\nwhereParamTy\n";
P.printTy whereParamTy;
P.print "\nwahreParamPatTy\n";
P.printTy wahreParamPatTy;
P.print "\npredTy\n";
P.printTy predTy;
P.print "\nargTy --> boolTy\n";
P.printTy (argTy --> boolTy);
P.print "\ndataTy\n";
P.printTy dataTy;
P.print "\nseqTy\n";
P.printTy seqTy;
P.print "\nargTy\n";
P.printTy argTy;
P.print "\nargPatTy\n";
P.printTy argPatTy;
                    raise ForeachError)
        val resultTpexp = 
            TC.TPFOREACHDATA
              {data = dataTpexp, 
               dataTy = dataTy, 
               whereParam = whereParamTpexp,
               whereParamTy = whereParamTy,
               iterator = iteratorTpexp, 
               iteratorTy = iteratorTy, 
               pred = predTpexp, 
               predTy = predTy, 
               loc = loc}
      in
        (dataTy, resultTpexp)
      end
      handle ForeachError => (T.ERRORty, TC.TPERROR)
      end

  and typeinfExp lambdaDepth applyDepth (context : TIC.context) icexp =
(*  (printicexptype icexp; *)
     case icexp of
        IC.ICERROR =>
        let
          val resultTy = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
        in
          (resultTy, TC.TPERROR)
        end
      | IC.ICFOREACH arg =>
        typeinfForeach lambdaDepth applyDepth context arg
      | IC.ICFOREACHDATA arg =>
        typeinfForeachData lambdaDepth applyDepth context arg
      | IC.ICCONSTANT constant =>
        let
          val loc = AbsynConst.getLocConstant constant
          val (ty, staticConst, staticConstraints) = typeinfConst constant
          val _ = addConstraints staticConstraints
        in
          (ty, TC.TPCONSTANT {const=staticConst,ty=ty,loc=loc})
        end
      | IC.ICVAR (var as {longsymbol, id}) =>
        let
          val loc  = Symbol.longsymbolToLoc longsymbol
        in
          (
           case VarMap.find(#varEnv context, var)  of
             SOME (TC.VARID varInfo) => (#ty varInfo, TC.TPVAR varInfo)
           | SOME (TC.RECFUNID (varInfo as {ty,...}, arity)) =>
	     (ty, TC.TPRECFUNVAR {var=varInfo, arity=arity})
           | NONE =>
             if E.isError() then raise Fail
             else raise bug "var not found (1)"
          (* bug 076: This must be due to some user error.
             raise bug "var not found"
           *)
	  )
        end
      | IC.ICEXVAR {longsymbol=refLongsymbol,
                    exInfo= exInfo as {used, longsymbol, version, ty}} =>
        let
          val loc = Symbol.longsymbolToLoc refLongsymbol
          val externalLongsymbol = exInfoToLongsymbol exInfo
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity4\n"; raise e)
        in
          (ty, TC.TPEXVAR {path=externalLongsymbol, ty=ty})
        end
      | IC.ICEXVAR_TOBETYPED _ => raise bug "ICEXVAR_TOBETYPED"
      | IC.ICBUILTINVAR {primitive, ty, loc} =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity5\n";raise e)
          val primInfo = {primitive=primitive, ty=ty}
        in
          case ty of
            T.POLYty{boundtvars, constraints, body = T.FUNMty([argTy], resultTy)} =>
            let
              val (subst, newBoundEnv) = TB.copyBoundEnv boundtvars
              val newArgTy = TB.substBTvar subst argTy
              val newResultTy = TB.substBTvar subst resultTy
              val argVarInfo = TCU.newTCVarInfo loc newArgTy
              val newTy =
                  T.POLYty {boundtvars=newBoundEnv,
                            constraints = constraints,
                            body = T.FUNMty([newArgTy], newResultTy)}
            in
              (
               newTy,
               TC.TPPOLYFNM
                 {
                  btvEnv=newBoundEnv,
                  argVarList=[argVarInfo],
                  bodyTy=newResultTy,
                  bodyExp=
                    TC.TPPRIMAPPLY
                    {
                     primOp=primInfo,
                     instTyList=map T.BOUNDVARty
                                    (BoundTypeVarID.Map.listKeys newBoundEnv),
                     argExp=TC.TPVAR argVarInfo,
                     argTy=newArgTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.POLYty{boundtvars, constraints, body = T.FUNMty(_, ty)} =>
            raise bug "Uncurried fun type in OPRIM"
          | T.FUNMty([argTy], resultTy) =>
            let
              val argVarInfo = TCU.newTCVarInfo loc argTy
            in
              (
               ty,
               TC.TPFNM
                 {
                  argVarList=[argVarInfo],
                  bodyTy=resultTy,
                  bodyExp=
                    TC.TPPRIMAPPLY
                    {
                     primOp=primInfo,
                     instTyList=nil,
                     argExp=TC.TPVAR argVarInfo,
                     argTy=argTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.FUNMty(_, ty) => raise bug "Uncurried fun type in PRIM"
          | _ =>raise bug "primitive type"
        end
      | IC.ICCON (con as {longsymbol, id, ty}) =>
        let
          val loc = Symbol.longsymbolToLoc longsymbol
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity6\n";raise e)
          val conInfo = {path=longsymbol, ty=ty, id=id}
        in
          case ty of
            T.POLYty{boundtvars, constraints, body = T.FUNMty([argTy], resultTy)} =>
            let
              val (subst, newBoundEnv) = TB.copyBoundEnv boundtvars
              val newArgTy = TB.substBTvar subst argTy
              val newResultTy = TB.substBTvar subst resultTy
              val argVarInfo = TCU.newTCVarInfo loc newArgTy
              val newTy =
                  T.POLYty {boundtvars=newBoundEnv,
                            constraints = constraints,
                            body = T.FUNMty([newArgTy], newResultTy)}
            in
              (
               newTy,
               TC.TPPOLYFNM
                 {
                  btvEnv=newBoundEnv,
                  argVarList=[argVarInfo],
                  bodyTy=newResultTy,
                  bodyExp=
                    TC.TPDATACONSTRUCT
                    {
                     con=conInfo,
                     instTyList=map T.BOUNDVARty
                                    (BoundTypeVarID.Map.listKeys newBoundEnv),
                     argExpOpt= SOME (TC.TPVAR argVarInfo),
                     argTyOpt = SOME newArgTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.POLYty{boundtvars, constraints, body = T.FUNMty(_, ty)} =>
            raise bug "Uncurried fun type in OPRIM"
          | T.FUNMty([argTy], resultTy) =>
            let
              val argVarInfo = TCU.newTCVarInfo loc argTy
            in
              (ty,
               TC.TPFNM
                 {
                  argVarList=[argVarInfo],
                  bodyTy=resultTy,
                  bodyExp=
                    TC.TPDATACONSTRUCT
                    {
                     con=conInfo,
                     instTyList=nil,
                     argExpOpt=SOME (TC.TPVAR argVarInfo),
                     argTyOpt=SOME argTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | _ =>
            (ty,
             TC.TPDATACONSTRUCT{con=conInfo,
                                instTyList=nil,
                                argExpOpt=NONE,
                                argTyOpt=NONE,
                                loc=loc}
            )
        end
      | IC.ICEXN (exn as {longsymbol, id, ty}) =>
        let
          val loc = Symbol.longsymbolToLoc longsymbol
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity7\n";raise e)
          val exnInfo = {path=longsymbol, ty=ty, id=id}
        in
          case ty of
            T.FUNMty([argTy], resultTy) =>
            let
              val argVarInfo = TCU.newTCVarInfo loc argTy
            in
              (ty,
               TC.TPFNM
                 {
                  argVarList=[argVarInfo],
                  bodyTy=resultTy,
                  bodyExp=
                    TC.TPEXNCONSTRUCT
                    {
                     exn=TC.EXN exnInfo,
                     instTyList=nil,
                     argExpOpt=SOME (TC.TPVAR argVarInfo),
                     argTyOpt=SOME argTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | _ =>
            (ty,
             TC.TPEXNCONSTRUCT{exn=TC.EXN exnInfo,
                               instTyList=nil,
                               argExpOpt=NONE,
                               argTyOpt=NONE,
                               loc=loc}
            )
        end
      | IC.ICEXN_CONSTRUCTOR (exn as {longsymbol, id, ty}) =>
        let
          val loc = Symbol.longsymbolToLoc longsymbol
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity8\n";raise e)
          val exnInfo = {path=longsymbol, ty=ty, id=id}
        in
          (BT.exntagTy,
           TC.TPEXN_CONSTRUCTOR{exnInfo = exnInfo, loc=loc}
          )
        end
      | IC.ICEXEXN_CONSTRUCTOR {longsymbol=refLongsymbol, exInfo=exInfo as {longsymbol, ty,...}} =>
        let
          val loc = Symbol.longsymbolToLoc refLongsymbol 
          val externalLongsymbol = exInfoToLongsymbol exInfo
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity9\n";raise e)
          val exExnInfo = {path=externalLongsymbol, ty=ty}
        in
          (BT.exntagTy,
           TC.TPEXEXN_CONSTRUCTOR{exExnInfo = exExnInfo, loc=loc}
          )
        end
      | IC.ICEXEXN {longsymbol=refLongsymbol, 
                    exInfo = exInfo as {longsymbol,ty,...}} =>
        let
          val loc = Symbol.longsymbolToLoc refLongsymbol
          val externalLongsymbol = exInfoToLongsymbol exInfo
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity10\n"; raise e)
          val exExnInfo = {path=externalLongsymbol, ty=ty}
        in
          case ty of
            T.FUNMty([argTy], resultTy) =>
            let
              val argVarInfo = TCU.newTCVarInfo loc argTy
            in
              (ty,
               TC.TPFNM
                 {
                  argVarList=[argVarInfo],
                  bodyTy=resultTy,
                  bodyExp=
                    TC.TPEXNCONSTRUCT
                    {
                     exn=TC.EXEXN exExnInfo,
                     instTyList=nil,
                     argExpOpt=SOME (TC.TPVAR argVarInfo),
                     argTyOpt=SOME argTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | _ =>
            (ty,
             TC.TPEXNCONSTRUCT{exn=TC.EXEXN exExnInfo,
                               instTyList=nil,
                               argExpOpt=NONE,
                               argTyOpt=NONE,
                               loc=loc}
            )
        end
      | IC.ICOPRIM oprimInfo =>
        let
          val loc = Symbol.longsymbolToLoc (#longsymbol oprimInfo)
          val oprimInfo as {id, path, ty} =
              case OPrimMap.find(#oprimEnv context, oprimInfo) of
                SOME oprimInfo => oprimInfo
              | NONE => raise bug "OPrim not found"
        in
          case ty of
            T.POLYty{boundtvars, constraints, body = T.FUNMty([argTy], resultTy)} =>
            let
              val (subst, newBoundEnv) = TB.copyBoundEnv boundtvars
              val newArgTy = TB.substBTvar subst argTy
              val newResultTy = TB.substBTvar subst resultTy
              val argVarInfo = TCU.newTCVarInfo loc newArgTy
              val newTy =
                  T.POLYty {boundtvars=newBoundEnv,
                            constraints = constraints,
                            body = T.FUNMty([newArgTy], newResultTy)}
              val instTyList =
                  map T.BOUNDVARty (BoundTypeVarID.Map.listKeys newBoundEnv)
            in
              (
               newTy,
               TC.TPPOLYFNM
                 {
                  btvEnv=newBoundEnv,
                  argVarList=[argVarInfo],
                  bodyTy=newResultTy,
                  bodyExp=
                    TC.TPOPRIMAPPLY
                    {
                     oprimOp=oprimInfo,
                     instTyList=instTyList,
                     argExp=TC.TPVAR argVarInfo,
                     argTy=newArgTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.POLYty{boundtvars, constraints, body = T.FUNMty(_, ty)} =>
            raise bug "Uncurried fun type in OPRIM"
          | _ => 
            (P.print "bug non poly oprim ty (3)\n";
             P.printTy ty;
             P.print "\n";
            raise bug "non poly oprim ty (3)"
            )
        end
      | IC.ICTYPED (icexp, ty, loc) =>
         let
           val (ty1, tpexp) = typeinfExp lambdaDepth inf context icexp
           val ty2 = ITy.evalIty context ty handle e => (P.print "ity11\n"; raise e)
         in
           if U.eqTy BoundTypeVarID.Map.empty (ty1, ty2) then
             (ty1, tpexp)
           else
             let
               val (instTy, instConstraints, tpexp) = TCU.freshInst (ty1, tpexp)
               val _ = addConstraints instConstraints
               val (ty2, constraints2) = TB.freshRigidInstTy ty2
               val _ = addConstraints constraints2
             in
               (
                U.unify [(instTy, ty2)];
                (ty2, tpexp)
               )
               handle
               U.Unify =>
               (
                E.enqueueError
                  "Typeinf 018"
                  (
                   loc,
                   E.TypeAnnotationNotAgree ("018",{ty=instTy,annotatedTy=ty2})
                  );
                (T.ERRORty, TC.TPERROR)
               )
             end
         end
(*
      | IC.ICTYPED (icexp, ty, loc) =>
         let
           val (ty1, tpexp) = typeinfExp lambdaDepth inf context icexp
           val (instTy, tpexp) = TCU.freshInst (ty1, tpexp)
           val ty2 = ITy.evalIty context ty handle e => (P.print "ity11\n"; raise e)
           val ty2 = TB.freshRigidInstTy ty2
         in
           (
             U.unify [(instTy, ty2)];
             (ty2, tpexp)
           )
           handle
             U.Unify =>
               (
                E.enqueueError "Typeinf 009"
                (
                 loc,
                 E.TypeAnnotationNotAgree ("012",{ty=instTy,annotatedTy=ty2})
                 );
                (T.ERRORty, TC.TPERROR)
                )
         end
*)
      | IC.ICSIGTYPED {icexp=exp, ty, revealKey, loc} =>
         let
           val (ty1, tpexp) = typeinfExp lambdaDepth inf context exp
           val ty2 = ITy.evalIty context ty handle e => (P.print "ity12\n"; raise e)
         in
           if U.eqTy BoundTypeVarID.Map.empty (ty1, ty2) then
             (ty1, tpexp)
           else
             let
               val _ =
                   case revealKey of
                     NONE =>
                       (P.print "ICSIGTYPED: noneq:";
                        P.print "\n";
                        P.print "ty1:";
                        P.printTy ty1;
                        P.print "\n";
                        P.print "ty2:";
                        P.printTy ty2;
                        P.print "\n")
                   | SOME _ => ()
               val (instTy, instConstraints, tpexp) = TCU.freshInst (ty1, tpexp)
               val _ = addConstraints instConstraints
               val (ty22, constraints22) = TB.freshRigidInstTy ty2
               val _ = addConstraints constraints22
               val revealedTy2 =
                   case revealKey of
                     NONE => ty22
                   | SOME key => revealTy key ty22
val _ = P.print "SIGTYPED*************:\n"
val _ = P.print "icexp:\n"
val _ = P.printIcexp exp
val _ = P.print "\ntpexp:\n"
val _ = P.printTpexp 
val _ = P.print "\n"
val _ = P.print "t22\n"
val _ = P.printTy ty22
val _ = P.print "\n"
val _ = P.print "instTy\n"
val _ = P.printTy instTy
val _ = P.print "\n"
               val (ty22, tpexp) = 
                   (U.unify [(instTy, revealedTy2)];
                    (ty22, tpexp)
                   )
               handle
               U.Unify =>
               (
                E.enqueueError
                  "Typeinf 019"
                  (
                   loc,
                   E.SignatureMismatch ("019",{path=[], ty=instTy,
                                               annotatedTy=ty22})
                  );
                (T.ERRORty, TC.TPERROR)
               )
val _ = P.print "t22 after unify*************:\n"
val _ = P.printTy ty22
val _ = P.print "\n"
val _ = P.print "instTy\n"
val _ = P.printTy instTy
val _ = P.print "\n"
             in
               (ty22, tpexp)
             end
         end
      | IC.ICAPPM(IC.ICRECORD_SELECTOR(l, loc1), [icexp], loc2) =>
         typeinfExp lambdaDepth applyDepth context (IC.ICSELECT(l,icexp,loc2))

      | IC.ICAPPM (icexp, icexpList, loc) =>
        let
          val (funExp, funItyList) = stripIty icexp
          fun evalArgs lambdaDepth icexpList =
              foldr
                (fn (icexp, (argTyList,agrExpList)) =>
                    let
                      val (ty, tpexp) =
                          typeinfExp lambdaDepth inf context icexp
                      val (ty, instConstraints, tpexp) = TCU.freshInst (ty, tpexp)
                      val _ = addConstraints instConstraints
                    in (ty::argTyList, tpexp::agrExpList)
                    end
                )
                (nil,nil)
                icexpList
          fun evalArgsVar lambdaDepth icexpList =
              foldr
                (fn (icexp, (argTyList,agrExpList)) =>
                    let
                      val (ty,tpexp) =
                          typeinfExp lambdaDepth inf context icexp
                      val (ty, instConstraints, tpexp) = TCU.freshInst (ty, tpexp)
                      val _ = addConstraints instConstraints
                    in (ty::argTyList, tpexp::agrExpList)
                    end
                )
                (nil,nil)
                icexpList
          fun processVar (funTy, funExp, funLoc) =
              let
                val (argTyList,argExpList) = evalArgsVar lambdaDepth icexpList
                val _ =
                   case funItyList of
                     nil => ()
                   | _ =>
                     let
                       val (funTy, _, funConstraints) = TIU.freshTopLevelInstTy funTy
                       val _ = addConstraints funConstraints
                     in
                       app
                         (fn ity =>
                             let
                               val annotatedTy = ITy.evalIty context ity
                                   handle e => (P.print "ity13\n"; raise e)
                             in
                               (U.unify [(funTy, annotatedTy)])
                               handle
                               U.Unify =>
                               E.enqueueError "Typeinf 020"
                                              (
                                               funLoc,
                                               E.TypeAnnotationNotAgree
                                                 ("020",{ty=funTy, annotatedTy=annotatedTy})
                                              )
                             end)
                         funItyList
                     end
	      in
                monoApplyM
                  context
                  {termLoc=loc,
                   funTy=funTy,
                   argTyList=argTyList,
                   funTpexp=funExp,
                   funLoc=funLoc,
                   argTpexpList=argExpList
                  }
              end
          fun processCon (lambdaDepth,makeNewTermBody,funITy,funLoc) =
              case evalArgs lambdaDepth icexpList of
                ([argTy], [argExp]) =>
                let
                  val (argTy, argConstraints, argExp) = TCU.freshInst (argTy, argExp)
                  val _ = addConstraints argConstraints
                  val polyFunTy = ITy.evalIty context funITy
                      handle e => (P.print "ity14\n"; raise e)
                  (*  a con type must be rank zero *)
                  val (funTy, instTyList, funConstraints) = TIU.freshTopLevelInstTy polyFunTy
                  val _ = addConstraints funConstraints
                  val _ =
                      app
                        (fn ity =>
                            let val annotatedTy1 = ITy.evalIty context ity
                                    handle e => (P.print "ity15\n"; raise e)
                            in
                              U.unify [(funTy, annotatedTy1)]
                              handle U.Unify =>
                                     E.enqueueError "Typeinf 021"
                                       (
                                        loc,
                                        E.TypeAnnotationNotAgree
                                          ("021",
                                           {ty=funTy,annotatedTy=annotatedTy1})
                                       )
                            end)
                        funItyList
                 val (domtyList,ranty,instlist,constraints) = TB.coerceFunM (funTy,[argTy])
                     handle TB.CoerceFun =>
                            (
                             E.enqueueError "Typeinf 022"
                               (funLoc,E.NonFunction("022",{ty=funTy}));
                             ([T.ERRORty], T.ERRORty, nil, nil)
                            )
                 val _ = addConstraints constraints
                 val domty =
                     case domtyList of
                       [ty] => ty
                     | _ => raise bug "arity mismatch"
                 val newTermBody =
                     makeNewTermBody (argExp, argTy, polyFunTy, instTyList)
                in
                  (
                   U.unify [(argTy, domty)];
                   if iszero applyDepth andalso not (TCU.expansive newTermBody)
                   then
                     let
                       val {boundEnv, boundConstraints, ...} = generalizer (ranty, lambdaDepth)
                     in
                       if BoundTypeVarID.Map.isEmpty boundEnv
                       then (ranty, newTermBody)
                       else
                         (
                          T.POLYty{boundtvars = boundEnv, constraints = boundConstraints, body = ranty},
                          TC.TPPOLY
                            {btvEnv=boundEnv,
                             expTyWithoutTAbs=ranty,
                             exp=newTermBody,
                             loc=loc}
                         )
                     end
                   else (ranty, newTermBody))
                  handle
                  U.Unify =>
                  (
                   E.enqueueError "Typeinf 023"
                     (loc, E.TyConMismatch ("023",{domTy=domty,argTy=argTy}));
                   (T.ERRORty, TC.TPERROR)
                  )
                end
              | _ => raise bug "con in multiple apply"
          fun processPrim (lambdaDepth, makeNewTermBody, polyFunTy, funLoc) =
              case evalArgs lambdaDepth icexpList of
               ([argTy], [tpexp2]) =>
               let
                 (*  a primitive type must be rank zero *)
                 val (funTy,instTyList, funConstraints) = TIU.freshTopLevelInstTy polyFunTy
                 val _ = addConstraints funConstraints
                 val _ =
                     app
                       (fn ity =>
                           let
                             val annotatedTy1 = ITy.evalIty context ity
                                 handle e => (P.print "ity16\n"; raise e)
                           in
                             U.unify [(funTy, annotatedTy1)]
                             handle U.Unify =>
                                    E.enqueueError "Typeinf 024"
                                      (
                                       loc,
                                       E.TypeAnnotationNotAgree
                                         ("024",
                                          {ty=funTy,annotatedTy=annotatedTy1})
                                      )
                           end)
                       funItyList
                 val (domtyList,ranty,instlist,constraints) = TB.coerceFunM (funTy,[argTy])
                     handle TB.CoerceFun =>
                            (
                             E.enqueueError "Typeinf 025"
                               (loc,E.NonFunction("025",{ty=funTy}));
                             ([T.ERRORty], T.ERRORty, nil, nil)
                            )
                 val _ = addConstraints constraints
                 val domty =
                     case domtyList of
                       [ty] => ty
                     | _ => raise bug "arity mismatch"
                 val newTermBody =
                     makeNewTermBody(tpexp2, argTy, polyFunTy, instTyList)
               in
                 (
                  U.unify [(argTy, domty)];
                  (ranty, newTermBody)
                 )
                 handle U.Unify =>
                        (
                         E.enqueueError "Typeinf 026"
                           (loc, E.TyConMismatch
                                   ("026",{domTy=domty,argTy=argTy}));
                         (T.ERRORty, TC.TPERROR)
                        )
               end
             | _ => raise bug "PrimOp in multiple apply"
        in
          case funExp of
            IC.ICVAR var =>
	    (let
              val funVarLoc = Symbol.longsymbolToLoc (#longsymbol var)
              val (funExp, funTy) =
                  case VarMap.find(#varEnv context, var) of
                    SOME (TC.VARID (var as {ty,...})) =>
                    (TC.TPVAR var, ty)
                  | SOME (TC.RECFUNID(var as {ty,...},arity)) =>
                    (TC.TPRECFUNVAR{var=var,arity=arity}, ty)
                  | NONE => 
                    if E.isError() then raise Fail
                    else raise bug "var not found (2)"
              val (funTy, funConstraints, funExp) =
                  case funItyList of
                    nil => (funTy, nil, funExp)
                  | _ => TCU.freshInst (funTy, funExp)
              val _ = addConstraints funConstraints
            in
              processVar (funTy, funExp, funVarLoc)
            end
            handle Fail => (T.ERRORty, TC.TPERROR)
            )
          | IC.ICEXVAR {longsymbol=refLongsymbol, 
                        exInfo=exInfo as {used, ty, longsymbol, version}} =>
	    let
              val loc = Symbol.longsymbolToLoc refLongsymbol
              val externalLongsymbol = exInfoToLongsymbol exInfo
              val ty = ITy.evalIty context ty
                  handle e => (P.print "ity17\n"; raise e)
	      val funExp = TC.TPEXVAR {path=externalLongsymbol, ty=ty}
            in
              processVar (ty, funExp, loc)
            end
          | IC.ICBUILTINVAR {primitive, ty, loc} =>
            let
              val ty = ITy.evalIty context ty
                  handle e => (P.print "ity18\n"; raise e)
              fun makeNewTermBody (argExp, argTy, funTy, instTyList) =
                  TC.TPPRIMAPPLY
                    {primOp={primitive=primitive, ty=funTy},
                     instTyList=instTyList,
                     argExp=argExp,
                     argTy= argTy,
                     loc=loc}
            in
              processPrim (lambdaDepth, makeNewTermBody, ty, loc)
            end
(*
          | IC.ICBUILTINVAR {primitive, ty, loc} =>
            (case evalArgs lambdaDepth icexpList of
               ([argTy], [tpexp2]) =>
               let
                 val funTy = ITy.evalIty context ty
                 (*  a primitive type must be rank zero *)
                 val (funTy,instTyList) = TIU.freshTopLevelInstTy funTy
                 val _ =
                     app
                       (fn ity =>
                           let
                             val annotatedTy1 = ITy.evalIty context ity
                                 handle e => raise e
                           in
                             U.unify [(funTy, annotatedTy1)]
                             handle U.Unify =>
                                    E.enqueueError "Typeinf 019"
                                      (
                                       loc,
                                       E.TypeAnnotationNotAgree
                                         ("020",
                                          {ty=funTy,annotatedTy=annotatedTy1})
                                      )
                           end)
                       funItyList
                 val (domtyList,ranty,instlist) = TB.coerceFunM (funTy,[argTy])
                     handle TB.CoerceFun =>
                            (
                             E.enqueueError "Typeinf 020"
                               (loc,E.NonFunction("021",{ty = funTy}));
                             ([T.ERRORty], T.ERRORty, nil)
                            )
                 val domty =
                     case domtyList of
                       [ty] => ty
                     | _ => raise bug "arity mismatch"
                 val newTermBody =
                     TC.TPPRIMAPPLY
                       {primOp={primitive=primitive, ty=funTy},
                        instTyList=instTyList,
                        argExpOpt=SOME tpexp2,
                        loc=loc}
               in
                 (
                  U.unify [(argTy, domty)];
                  (ranty, newTermBody)
                 )
                 handle U.Unify =>
                        (
                         E.enqueueError "Typeinf 021"
                           (loc,
                            E.TyConMismatch("022",{domTy=domty, argTy=argTy}));
                         (T.ERRORty, TC.TPERROR)
                        )
               end
             | _ => raise bug "PrimOp in multiple apply"
            )
*)
          | IC.ICCON {longsymbol, id, ty=funIty} =>
            let
              val funLoc = Symbol.longsymbolToLoc longsymbol
              val lambdaDepth = incDepth ()
              fun makeNewTermBody (argExp, argTy, funTy, instTyList) =
                  TC.TPDATACONSTRUCT
                    {
                     con={path=longsymbol,id=id,ty=funTy},
                     instTyList=instTyList,
                     argExpOpt=SOME argExp,
                     argTyOpt=SOME argTy,
                     loc=loc
                    }
            in
              processCon(lambdaDepth,makeNewTermBody,funIty,funLoc)
            end
          | IC.ICEXN {longsymbol, id, ty} =>
            let
              val loc = Symbol.longsymbolToLoc longsymbol
              val lambdaDepth = incDepth ()
              fun makeNewTermBody (argExp, argTy, funTy, instTyList) =
                  TC.TPEXNCONSTRUCT
                    {
                     exn=TC.EXN {path=longsymbol,id=id,ty=funTy},
                     instTyList=instTyList,
                     argExpOpt=SOME argExp,
                     argTyOpt=SOME argTy,
                     loc=loc
                    }
            in
              processCon (lambdaDepth, makeNewTermBody, ty, loc)
            end
          | IC.ICEXEXN {longsymbol=refLongsymbol, 
                        exInfo=exInfo as {longsymbol, ty,...}} =>
            let
              val loc = Symbol.longsymbolToLoc refLongsymbol
              val externalLongsymbol = exInfoToLongsymbol exInfo
              val lambdaDepth = incDepth ()
              fun makeNewTermBody (argExp, argTy, funTy, instTyList) =
                  TC.TPEXNCONSTRUCT
                    {
                     exn=TC.EXEXN {path=externalLongsymbol,ty=funTy},
                     instTyList=instTyList,
                     argExpOpt=SOME argExp,
                     argTyOpt=SOME argTy,
                     loc=loc
                    }

            in
              processCon (lambdaDepth, makeNewTermBody, ty, loc)
            end
          | IC.ICOPRIM oprimInfo =>
            let
              val loc = Symbol.longsymbolToLoc (#longsymbol oprimInfo)
              val oprimInfo as {ty,...} =
                  case OPrimMap.find(#oprimEnv context, oprimInfo) of
                    SOME oprimInfo => oprimInfo
                  | NONE => raise bug "OPrim not found"
              fun makeNewTermBody (argExp, argTy, funTy, instTyList) =
                  TC.TPOPRIMAPPLY
                    {oprimOp=oprimInfo,
                     instTyList=instTyList,
                     argExp=argExp,
                     argTy=argTy,
                     loc=loc}
            in
              processPrim (lambdaDepth, makeNewTermBody, ty, loc)
            end
          | _ =>
            let
              val (funTy, funExp) =
                  typeinfExp lambdaDepth (inc applyDepth) context icexp
              val (argTyList, argExpList) = evalArgs lambdaDepth icexpList
            in
              monoApplyM
                context
                {termLoc=loc,
                 funTy=funTy,
                 argTyList=argTyList,
                 funTpexp=funExp,
                 funLoc=loc,
                 argTpexpList=argExpList}
            end
        end
      | IC.ICAPPM_NOUNIFY (icexp, icexpList, loc) =>
        let
          fun eqList (tyList1, tyList2) =
              U.eqTyList BoundTypeVarID.Map.empty (tyList1, tyList2)
        in
          let
            val (funTy, funExp) =
                typeinfExp lambdaDepth (inc applyDepth) context icexp
            val (argTyList, argExpList) =
                foldr
                  (fn (icexp, (argTyList,agrExpList)) =>
                      let
                        val (ty,tpexp) =
                            typeinfExp lambdaDepth inf context icexp
                      in (ty::argTyList, tpexp::agrExpList)
                      end
                  )
                  (nil,nil)
                  icexpList
            val (domTyList, ranTy) =
                case funTy of
                  T.FUNMty(tyList, ty) => (tyList, ty)
                | T.ERRORty => raise Fail
                | _ =>
                  (P.print "APPM_NOUNIFY\n";
                   P.printTy funTy;
                   P.print "\n";
                   raise bug "APPM_NOUNIFY"
                  )
            val _ = if length argTyList = length domTyList then ()
                    else
                      (E.enqueueError "Typeinf 027"
                         (loc, E.TyConListMismatch
                                 ("027",{argTyList=argTyList,
                                         domTyList=domTyList}));
                       raise Fail
                      )
            val _ =
                if eqList (argTyList, domTyList) then ()
                else
                  (
                   E.enqueueError "Typeinf 028"
                     (loc,
                      E.TyConListMismatch
                        ("028",{argTyList = argTyList,
                                domTyList = domTyList}));
                   raise Fail
                  )

          in
            (ranTy,
             TC.TPAPPM {funExp = funExp,
                        funTy = T.FUNMty(domTyList, ranTy),
                        argExpList = argExpList,
                        loc=loc}
            )
          end
        end
      | IC.ICLET (icdeclList, icexpList, loc) =>
        let
          val (context1, tpdeclList) =
              typeinfDeclList lambdaDepth context icdeclList
          val newContext =
              TIC.extendContextWithContext (context, context1)
          val (tyListRev, tpexpListRev) =
              foldl
                (fn (tpexp, (tyListRev, tpexpListRev)) =>
                    let
                      val (ty, tpexp) =
                          typeinfExp lambdaDepth applyDepth newContext tpexp
                    in
                      (ty::tyListRev, tpexp :: tpexpListRev)
                    end)
                (nil, nil)
                icexpList
        in
          (List.hd tyListRev,
           TC.TPLET{decls = tpdeclList,
                    body = List.rev tpexpListRev,
                    tys = List.rev tyListRev,
                    loc = loc})
        end
      | IC.ICTYCAST (tycastList, icexp, loc) =>
        let
          val {varEnv, tvarEnv, oprimEnv} = context
          val typIdMap =
              foldl
              (fn ({from, to}, typIdMap) =>
                  let
                    val fromId = IC.tfunId from
                    val to = ITy.evalTfun context to
                             handle e => (P.print "ity19\n"; raise e)
                  in
                    TypID.Map.insert(typIdMap, fromId, to)
                  end
              )
              TypID.Map.empty
              tycastList
          val  (expTy, tpexp) =
               typeinfExp lambdaDepth applyDepth context icexp
          val ty = tyConSubstTy typIdMap expTy
(*
          val tpexp = tyConSubstExp typIdMap tpexp
*)
        in
          (ty, TC.TPCAST((tpexp, expTy), ty, loc)) (* bug 118 *)
        end
      | IC.ICRECORD (stringIcexpList, loc) =>
        let
          val labelTyTpexpListRev =
              foldl
                (fn ((label, icexp), labelTyTpexpListRev) =>
                    let
                      val (ty, tpexp) =
                          typeinfExp lambdaDepth applyDepth context icexp
                    in
                      (label, (ty, tpexp))::labelTyTpexpListRev

                    end)
               nil
               stringIcexpList
          val labelTyTpexpList = List.rev labelTyTpexpListRev
        in
          makeTPRecord labelTyTpexpList loc
        end
      | IC.ICRAISE (icexp, loc) =>
        let
          val (ty1, tpexp) = typeinfExp lambdaDepth applyDepth context icexp
          val resultTy = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
        in
          (
           U.unify [(ty1, BT.exnTy)];
           (resultTy, TC.TPRAISE {exp=tpexp, ty=resultTy, loc=loc})
          )
          handle U.Unify =>
                 (
                  E.enqueueError "Typeinf 029"
                    (loc, E.RaiseArgNonExn("029",{ty = ty1}));
                  (T.ERRORty, TC.TPERROR)
                 )
        end
      | IC.ICHANDLE (icexp, icpatIcexpList, loc) =>
        let
          val (ty1, instConstraints, tpexp) =
              TCU.freshInst (typeinfExp lambdaDepth inf context icexp)
          val _ = addConstraints instConstraints
          val (ruleTy, tppatTpexpList) =
              monoTypeinfMatch
                lambdaDepth
                [BT.exnTy]
                context
                (map (fn (pat,exp) => {args=[pat], body=exp}) icpatIcexpList)
          val (domTy, ranTy) =
               (* here we try maching the type of rules with exn -> ty1
                * Also, the result type must be mono.
                *)
              case TB.derefTy ruleTy of
                T.FUNMty([domTy], ranTy)=>(domTy, ranTy)
              | T.ERRORty => (T.ERRORty, T.ERRORty)
              | _ => raise bug "Case Type Inference"
          val newVarInfo = TCU.newTCVarInfo loc domTy
        in
          (
           U.unify [(ty1, ranTy)];
           (
            ty1,
            TC.TPHANDLE
              {
               exp=tpexp,
               exnVar=newVarInfo,
               handler=
                 TC.TPCASEM
                 {
                  expList=[TC.TPVAR newVarInfo],
                  expTyList=[domTy],
                  ruleList=tppatTpexpList,
                  ruleBodyTy=ranTy,
                  caseKind= PatternCalc.HANDLE,
                  loc=loc
                 },
               resultTy=ranTy,
               loc=loc
              }
           )
          )
          handle U.Unify =>
                 (
                  E.enqueueError "Typeinf 030"
                    (loc, E.HandlerTy("030",{expTy=ty1, handlerTy=ranTy}));
                  (T.ERRORty, TC.TPERROR)
                 )
         end
      | IC.ICFNM (argsBodyList, loc) =>
        (case argsBodyList of
           nil =>
           raise
             bug
               "empty rule in PTFNM (typeinference/main/TypeInferCore.sml)"
         | [{args=patList, body=exp}] =>
           let
             exception NonVar
           in
             (* This naive optimization does not work
                since D in fn D => exp may be CON. *)
             (* After name evaluation, this works. *)
             let
               fun getId icexp =
                   let
                     fun strip icexp ityList =
                         case icexp of
                           IC.ICPATVAR_TRANS var => (var, ityList)
                         | IC.ICPATVAR_OPAQUE var => (var, ityList)
                         | IC.ICPATWILD _ => (IC.newICVar(), ityList)
                         | IC.ICPATTYPED (icexp, ity, _) =>
                           strip icexp (ity::ityList)
                         | _ => raise NonVar
                   in
                     strip icexp nil
                   end
               val varList = map getId patList
               val newPtexp = IC.ICFNM1(varList, exp, loc)
             in
               typeinfExp lambdaDepth applyDepth context newPtexp
             end
             handle
               NonVar =>
               let
                 val varList =
                     map (fn pat => IC.newICVar ()) patList
                 val newPtexp =
                     IC.ICFNM1
                       (
                        map (fn var => (var, nil)) varList,
                        IC.ICCASEM
                          (
                           map (fn var => IC.ICVAR var) varList,
                           argsBodyList,
                           PatternCalc.MATCH,
                           loc
                          ),
                        loc
                       )
               in
                 typeinfExp lambdaDepth applyDepth context newPtexp
               end
           end
         | ({args=patList, body=exp} :: rest) =>
           let
             val varList =
                 map (fn pat => IC.newICVar ()) patList
             val newPtexp =
                 IC.ICFNM1
                   (
                    map (fn var => (var, nil)) varList,
                    IC.ICCASEM
                      (
                       map (fn var => IC.ICVAR var) varList,
                       argsBodyList,
                       PatternCalc.MATCH,
                       loc
                      ),
                    loc)
           in
             typeinfExp lambdaDepth applyDepth context newPtexp
           end
        )
      | IC.ICFNM1(varTyListList, icexp, loc) =>
         let
           val lambdaDepth = incDepth ()
           val (newContext, tyVarInfoList) =
               foldr
                 (fn ((var as {longsymbol, id}, ityList),
                      (newContext, tyVarInfoList)) =>
                  let
                    val domTy =
                        T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                    val _ =
                        app
                          (fn ity =>
                              let val annotatedTy1 = ITy.evalIty newContext ity
                                      handle e => (P.print "ity20\n"; raise e)
                              in
                                U.unify [(domTy, annotatedTy1)]
                                handle
                                U.Unify =>
                                E.enqueueError "Typeinf 031"
                                  (
                                   loc,
                                   E.TypeAnnotationNotAgree
                                     ("031",
                                      {ty=domTy, annotatedTy=annotatedTy1})
                                  )
                              end)
                          ityList
                    val varInfo = {path=longsymbol, id=id, ty=domTy, opaque=false}
                    val newContext =
                        TIC.bindVar(lambdaDepth,
                                    newContext,
                                    var,
                                    TC.VARID varInfo)
                  in
                    (newContext, (domTy, varInfo)::tyVarInfoList)
                  end
                 )
                 (context, nil)
                 varTyListList
           val (ranTy, typedExp) =
               typeinfExp lambdaDepth (decl applyDepth) newContext icexp
           val ty = T.FUNMty(map #1 tyVarInfoList, ranTy)
           val (ty, tpexp) =
               if iszero applyDepth then
                 let
                   val {boundEnv, boundConstraints, ...} = generalizer (ty, lambdaDepth)
                 in
                   if BoundTypeVarID.Map.isEmpty boundEnv then
                     (ty,
                      TC.TPFNM
                        {argVarList = map #2 tyVarInfoList,
                         bodyTy = ranTy,
                         bodyExp = typedExp,
                         loc = loc})
                   else
                     (
                      T.POLYty{boundtvars = boundEnv, constraints = boundConstraints, body = ty},
                      TC.TPPOLYFNM
                        {
                         btvEnv=boundEnv,
                         argVarList=map #2 tyVarInfoList,
                         bodyTy=ranTy,
                         bodyExp=typedExp,
                         loc=loc
                        }
                     )
                 end
               else
                 (ty, TC.TPFNM {argVarList = map #2 tyVarInfoList,
                                bodyTy = ranTy,
                                bodyExp = typedExp,
                                loc = loc})
         in
           (ty, tpexp)
         end
      | IC.ICFNM1_POLY(varTyList, icexp, loc) =>
         let
           val lambdaDepth = incDepth ()
           val (newContext, tyVarInfoList) =
               foldr
                 (fn ((var as {longsymbol, id}, ity),
                      (newContext, tyVarInfoList)) =>
                  let
                    val domTy = ITy.evalIty newContext ity
                                handle e => (P.print "ity21\n"; raise e)
                    val varInfo = {path=longsymbol, id=id, ty=domTy, opaque=false}
                    val newContext =
                        TIC.bindVar(lambdaDepth,
                                    newContext,
                                    var,
                                    TC.VARID varInfo)
                  in
                    (newContext, (domTy, varInfo)::tyVarInfoList)
                  end
                 )
                 (context, nil)
                 varTyList
           val (ranTy, typedExp) =
               typeinfExp lambdaDepth (decl applyDepth) newContext icexp
           val ty = T.FUNMty(map #1 tyVarInfoList, ranTy)
           val (ty, tpexp) =
               (ty,
                TC.TPFNM
                  {argVarList = map #2 tyVarInfoList,
                   bodyTy = ranTy,
                   bodyExp = typedExp,
                   loc = loc}
               )
(* This is a functor definition, so type generalization should not
   be necessary and
           val (ty, tpexp) =
               if iszero applyDepth then
                 let
                   val {boundEnv, ...} = generalizer (ty, lambdaDepth)
                 in
                   if BoundTypeVarID.Map.isEmpty boundEnv then
                     (ty,
                      TC.TPFNM
                        {argVarList = map #2 tyVarInfoList,
                         bodyTy = ranTy,
                         bodyExp = typedExp,
                         loc = loc})
                   else
                     (
                      T.POLYty{boundtvars = boundEnv, body = ty},
                      TC.TPPOLYFNM
                        {
                         btvEnv=boundEnv,
                         argVarList=map #2 tyVarInfoList,
                         bodyTy=ranTy,
                         bodyExp=typedExp,
                         loc=loc
                        }
                     )
                 end
               else
                 (ty, TC.TPFNM {argVarList = map #2 tyVarInfoList,
                                bodyTy = ranTy,
                                bodyExp = typedExp,
                                loc = loc})
*)
         in
           (ty, tpexp)
         end
      | IC.ICCASEM (icexpList, argsBodyList, caseKind, loc) =>
        let
          val (tyListRev, constraintsList, tpexpListRev) =
              foldl
                (fn (ptexp, (tyListRev, constraintsList, tpexpListRev)) =>
                    let
                      val (ty,tpexp) = typeinfExp lambdaDepth inf context ptexp
                      val (ty,constraints,tpexp) = TCU.freshInst (ty,tpexp)
                    in
                      (ty::tyListRev, constraints @ constraintsList, tpexp::tpexpListRev)
                    end
                )
                (nil,nil,nil)
                icexpList
          val _ = addConstraints constraintsList
          val (tyList, tpexpList) = (List.rev tyListRev, List.rev tpexpListRev)
          val (ruleTy, tpMatchM) =
              typeinfMatch lambdaDepth applyDepth tyList context argsBodyList
          val ranTy =
              case TB.derefTy ruleTy of
                T.FUNMty(_, ranTy) => ranTy
              | T.ERRORty => T.ERRORty
              | _ => raise bug "Case Type Inference"
        in
          (ranTy, TC.TPCASEM
                    {
                     expList=tpexpList,
                     expTyList=tyList,
                     ruleList=tpMatchM,
                     ruleBodyTy=ranTy,
                     caseKind=caseKind,
                     loc=loc
                    }
          )
        end
      | IC.ICRECORD_UPDATE (icexp, stringIcexpList, loc) =>
        let
          val (ty1, instConstraints, tpexp1) =
              TCU.freshInst (typeinfExp lambdaDepth applyDepth context icexp)
          val _ = addConstraints instConstraints
          val (modifyTpexp, modifyConstraints, tySmap) =
              (* this inside-out term is correct under the call-by-value
                 semantics *)
              foldl
	        (fn ((label, icexp), (modifyTpexp, modifyConstraints, tySmap)) =>
                    let
                      val (ty, constraints, tpexp) =
                          TCU.freshInst
                            (typeinfExp lambdaDepth applyDepth context icexp)
                    in
                      (TC.TPMODIFY {label=label,
                                    recordExp=modifyTpexp,
                                    recordTy=ty1,
                                    elementExp=tpexp,
                                    elementTy=ty,
                                    loc=loc},
                       constraints @ modifyConstraints,
                       RecordLabel.Map.insert (tySmap, label, ty))
                    end)
                (tpexp1, nil, RecordLabel.Map.empty)
                stringIcexpList
          val _ = addConstraints modifyConstraints
          val modifierTy =
              T.newtyRaw
                {
                 lambdaDepth = lambdaDepth,
                 kind = T.KIND {tvarKind = T.REC tySmap,
                                eqKind = T.NONEQ,
                                dynKind = false,
                                reifyKind = false,
                                subkind = T.ANY},
                 utvarOpt = NONE
                }
        in
          (
           U.unify [(ty1, modifierTy)];
           (ty1, modifyTpexp)
          )
          handle U.Unify =>
                 (
                  E.enqueueError "Typeinf 032"
	            (
		     loc,
		     E.TyConMismatch("032",{argTy = ty1, domTy = modifierTy})
		    );
		  (T.ERRORty, TC.TPERROR)
		 )
        end
      | IC.ICRECORD_SELECTOR (label, loc) =>
        let
          val newVar = IC.newICVar()
        in
          typeinfExp
            lambdaDepth
            applyDepth
            context
            (IC.ICFNM1
               (
                [(newVar, nil)],
                IC.ICSELECT
                  (
                   label,
                   IC.ICVAR newVar,
                   loc
                  ),
                loc
               )
            )
        end
      | IC.ICSELECT (label, icexp, loc) =>
        let
          val (ty1, tpexp) = typeinfExp lambdaDepth applyDepth context icexp
          val ty1 = TB.derefTy ty1
        in
          case ty1 of
            T.RECORDty tyFields =>
            (* here we cannot use U.unify, which is for monotype only. *)
              (case RecordLabel.Map.find(tyFields, label) of
                 SOME elemTy => (elemTy,
                                 TC.TPSELECT
                                   {
                                    label=label,
                                    exp=tpexp,
                                    expTy=ty1,
                                    resultTy = elemTy,
                                    loc=loc
                                   }
                                )
               | _ =>
                 (E.enqueueError "Typeinf 033"
                    (loc, E.FieldNotInRecord("033",{label = label}));
                  (T.ERRORty, TC.TPERROR))
              )
           | T.TYVARty (ref (T.TVAR tvkind)) =>
             let
               val elemTy =
                 T.newtyWithLambdaDepth (#lambdaDepth tvkind, T.univKind)
               val recordTy =
                   T.newtyRaw
                   {
                    lambdaDepth = lambdaDepth,
                    kind = T.KIND {tvarKind = T.REC (RecordLabel.Map.singleton(label, elemTy)),
                                   eqKind = T.NONEQ,
                                   dynKind = false,
                                   reifyKind = false,
                                   subkind = T.ANY},
                    utvarOpt = NONE
                   }
             in
               (
                U.unify [(ty1, recordTy)];
                 (elemTy, TC.TPSELECT{label=label,
                                      exp=tpexp,
                                      expTy=recordTy,
                                      resultTy = elemTy,
                                      loc=loc})
               )
               handle U.Unify =>
                      (
                       E.enqueueError "Typeinf 034"
                         (loc,E.TyConMismatch
                                ("034",{domTy=recordTy, argTy=ty1}));
                       (T.ERRORty, TC.TPERROR)
                      )
             end
           | _ => (* this case may be empty *)
             let
               val elemTy = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
               val recordTy =
                   T.newtyRaw
                    {
                     lambdaDepth = lambdaDepth,
                     kind = T.KIND {tvarKind = T.REC (RecordLabel.Map.singleton(label, elemTy)),
                                    eqKind = T.NONEQ,
                                    dynKind=false,
                                    reifyKind = false,
                                    subkind = T.ANY},
                     utvarOpt = NONE
                    }
             in
               (
                 U.unify [(ty1, recordTy)];
                 (elemTy, TC.TPSELECT{label=label,
                                      exp=tpexp,
                                      expTy=recordTy,
                                      resultTy = elemTy,
                                      loc=loc})
               )
               handle U.Unify =>
                      (
                        E.enqueueError "Typeinf 035"
                        (loc,
                         E.TyConMismatch("035",{domTy=recordTy,argTy=ty1}));
                        (T.ERRORty, TC.TPERROR)
                      )
             end
         end
      | IC.ICSEQ (icexpList, loc) =>
        let
          val (tyListRev, tpexpListRev) =
              foldl
                (fn (icexp, (tyListRev, tpexpListRev)) =>
                    let
                      val (ty, tpexp) =
                          typeinfExp lambdaDepth applyDepth context icexp
                    in
                      (ty :: tyListRev, tpexp :: tpexpListRev)
                    end)
                (nil, nil)
                icexpList
        in
          (List.hd tyListRev,
           TC.TPSEQ {expList=List.rev tpexpListRev,
                     expTyList=List.rev tyListRev,
                     loc=loc}
          )
        end
      | IC.ICFFIIMPORT (ffifun, ffity, loc) =>
        let
          val funExp = typeinfFFIFun lambdaDepth inf context ffifun loc
          val ffity = evalForeignFunTy context ffity
          val stubTy = ffiStubTy ffity
        in
          (stubTy,
           TC.TPFFIIMPORT {funExp = funExp,
                           ffiTy = ffity,
                           stubTy = stubTy,
                           loc = loc})
        end
      | IC.ICFFIAPPLY (attributes, ffifun, ffiArgList, ffiRetTy, loc) =>
        let
          val retDir =
              (IMPORT, case attributes of
                         SOME {unsafe, ...} => if unsafe then UNSAFE else SAFE
                       | NONE => SAFE)
          val funExp = typeinfFFIFun lambdaDepth applyDepth context ffifun loc
          val (argFFItys, args) =
              ListPair.unzip
                (map (typeinfFFIArg lambdaDepth applyDepth context) ffiArgList)
          val argTupleExp = makeTupleExp (args, loc)
          val retFFItys = map (evalFFIty context retDir) ffiRetTy
          val _ =
              case retFFItys of
                nil => ()
              | [ty] => ()
              | _ =>
                E.enqueueError
                  "Typeinf 036"
                  (loc, E.NonInteroperableType
                          ("036",
                           IC.FFIFUNTY (attributes,nil,NONE,ffiRetTy,loc)));
          val ffity = TC.FFIFUNTY (attributes, argFFItys, NONE, retFFItys, loc)
          val stubTy = ffiStubTy ffity
          val retTy = case stubTy of T.FUNMty (_,retTy) => retTy
                                   | _ => raise bug "ICFFIAPPLY"
        in
          (retTy,
           TC.TPAPPM {funExp = TC.TPFFIIMPORT {funExp = funExp,
                                               ffiTy = ffity,
                                               stubTy = stubTy,
                                               loc = loc},
                      funTy = stubTy,
                      argExpList = [argTupleExp],
                      loc = loc})
        end
      | IC.ICSQLSCHEMA {tyFnExp, ty, loc} =>
        raise bug "typeinfExp: ICSQLSCHEMA"
      | IC.ICJSON (exp, ty, loc) => 
        (let
           val (ty1, tpexp) = typeinfExp lambdaDepth applyDepth context exp
           val ty2 = ITy.evalIty context ty handle e => (P.print "ity43\n"; raise e)
           val jsondynty = 
               T.CONSTRUCTty 
                 {tyCon = UP.JSON_dyn_tyCon (),
                  args = [T.newty T.univKind]}
           val _ = U.unify [(ty1, jsondynty)]
               handle U.Unify =>
                      (
                       E.enqueueError "Typeinf 037"
                                      (loc,
                                       E.TyConListMismatch
                                         ("037",{argTyList = [ty1], domTyList = [jsondynty]}));
                       ()
                      )
           (* 2016-11-21 sasaki: 
            * ty2がJSONカインドを有する型であることを確認するコード，
            * ICTYPEOFのケースからコピー
            *)
           val tyWithJsonKind = T.newtyWithLambdaDepth (lambdaDepth, T.dynamicKind)
           val _ = U.unify [(ty2, tyWithJsonKind)]
               handle U.Unify =>
                      (
                       E.enqueueError "Typeinf 038"
                                      (loc, E.JoinTypeExpected ("038",ty2));
                       ()
                      )
         in
           (ty2, TC.TPJSON {exp = tpexp, ty = ty1, coerceTy = ty2, loc = loc})
         end
         handle UP.IDNotFound name =>
                (E.enqueueError "Typeinf 039"
                                (loc, E.UserLevelPrimForJsonNotFound name);
                 (T.ERRORty, TC.TPERROR)
                 )
        )
                
      | IC.ICTYPEOF(ty, loc) => 
        (let
           val ty = ITy.evalIty context ty 
           val tyWithJsonKind = T.newtyWithLambdaDepth (lambdaDepth, T.dynamicKind)
           val _ = U.unify [(ty, tyWithJsonKind)]
               handle U.Unify =>
                      (
                       E.enqueueError "Typeinf 040"
                                      (loc, E.JoinTypeExpected ("040",ty));
                       ()
                      )
        in
          (T.CONSTRUCTty {tyCon = UP.JSON_jsonTy_tyCon (), args=nil}, TC.TPTYPEOF(ty, loc))
        end
         handle UP.IDNotFound name =>
                (E.enqueueError "Typeinf 041"
                                (loc, E.UserLevelPrimForJsonNotFound name);
                 (T.ERRORty, TC.TPERROR)
                 )
        )
      | IC.ICREIFYTY(ty, loc) => 
        (let
           val ty = ITy.evalIty context ty 
           val tyWithReifyKind = T.newtyWithLambdaDepth (lambdaDepth, T.reifyKind)
           val _ = U.unify [(ty, tyWithReifyKind)]
               handle U.Unify =>
                      (
                       E.enqueueError "Typeinf 040"
                                      (loc, E.JoinTypeExpected ("040",ty));
                       ()
                      )
        in
          (ReifiedTyData.TyRepTy(), TC.TPREIFYTY(ty, loc))
        end
         handle UP.IDNotFound name =>
                (E.enqueueError "Typeinf 041"
                                (loc, E.UserLevelPrimForJsonNotFound name);
                 (T.ERRORty, TC.TPERROR)
                 )
        )
      | IC.ICJOIN(exp1, exp2, loc) =>
        (let
          val (ty1, tpexp1) = typeinfExp lambdaDepth applyDepth context exp1
          val (ty1, constraints, tpexp1) = TCU.freshInst (ty1, tpexp1)
          val _ = addConstraints constraints
          val (ty2, tpexp2) = typeinfExp lambdaDepth applyDepth context exp2
          val (ty2, constraints, tpexp2) = TCU.freshInst (ty2, tpexp2)
          val _ = addConstraints constraints
          val ty1 = TB.derefTy ty1
          val ty2 = TB.derefTy ty2
          val recordTy1 = newJoinTvarTyWithLambdaDepth lambdaDepth
          val recordTy2 = newJoinTvarTyWithLambdaDepth lambdaDepth
          val recordTy3 = newJoinTvarTyWithLambdaDepth lambdaDepth
          val _ = U.unify [(ty1, recordTy1)]
              handle U.Unify =>
                     (E.enqueueError 
                        "Typeinf 042"
                        (loc,E.JoinNonRecord ("042",ty1, recordTy1));
                      ())
          val _ = U.unify [(ty2, recordTy2)]
              handle U.Unify =>
                     (E.enqueueError 
                        "Typeinf 043"
                        (loc,E.JoinNonRecord ("043",ty2, recordTy2));
                      ())
          val _ = addConstraint (T.JOIN {res = recordTy3, args = (recordTy1, recordTy2), loc = loc})
          val tpexp = TC.TPJOIN {ty = recordTy3, args = (tpexp1, tpexp2), argtys = (recordTy1, recordTy2), loc = loc}
         in
            if E.isError() then (T.ERRORty, TC.TPERROR)
            else  (recordTy3, tpexp)
         end
         handle Fail => (T.ERRORty, TC.TPERROR)
          | UP.IDNotFound name =>
            (E.enqueueError "Typeinf 044"
                            (loc, E.UserLevelPrimForJsonNotFound name);
             (T.ERRORty, TC.TPERROR)
            )
     )

  and typeinfFFIFun lambdaDepth applyDepth context ffifun loc =
      case ffifun of
        IC.ICFFIEXTERN s => TC.TPFFIEXTERN s
      | IC.ICFFIFUN icexp =>
        let
          val (ty, instConstraints, tpexp) =
              TCU.freshInst (typeinfExp lambdaDepth applyDepth context icexp)
          val _ = addConstraints instConstraints
        in
          U.unify [(BT.codeptrTy, ty)]
          handle U.Unify =>
                 E.enqueueError "Typeinf 045"
                   (loc, E.FFIStubMismatch("045",BT.codeptrTy, ty));
          TC.TPFFIFUN tpexp
        end

  and typeinfPat
        lambdaDepth
        (context as {tvarEnv, varEnv,...} :TIC.context)
        icpat =
      case icpat of
        IC.ICPATERROR =>
        let val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
        in (VarMap.empty, ty1, TC.TPPATERROR (ty1, Loc.noloc)) end
      | IC.ICPATWILD loc =>
         let val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
         in (VarMap.empty, ty1, TC.TPPATWILD (ty1, loc)) end
      | IC.ICPATVAR_TRANS (var as {longsymbol, id}) =>
        let
          val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
          val varInfo = {path=longsymbol, id=id, ty=ty1, opaque=false}
          val varEnv1 = VarMap.insert (VarMap.empty, var, TC.VARID varInfo)
        in
          (varEnv1, ty1, TC.TPPATVAR varInfo)
        end
      | IC.ICPATVAR_OPAQUE (var as {longsymbol, id}) =>
        let
          val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
          val varInfo = {path=longsymbol, id=id, ty=ty1, opaque=true}
          val varEnv1 = VarMap.insert (VarMap.empty, var, TC.VARID varInfo)
        in
          (varEnv1, ty1, TC.TPPATVAR varInfo)
        end
      | IC.ICPATCON {longsymbol, id, ty=ity} =>
        let
          val loc = Symbol.longsymbolToLoc longsymbol
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity23\n"; raise e)
          val conInfo = {path=longsymbol, id=id, ty=ty}
          val (ty1, tylist) =
              case ty of
                (T.POLYty{boundtvars, body, ...}) =>
                let val subst = TB.freshSubst boundtvars
                in
                  (TB.substBTvar subst body, BoundTypeVarID.Map.listItems subst)
                end
              | _ => (ty, nil)
        in
          case TB.derefTy ty1 of
            T.FUNMty _ =>
                (
                 E.enqueueError "Typeinf 046"
                   (loc,
                    E.ConRequireArg("046",{longsymbol = longsymbol}));
                 (
                  VarMap.empty,
                  T.ERRORty,
                  TC.TPPATWILD (T.ERRORty, loc)
                  )
                 )
          | _ =>
            (
             VarMap.empty,
             ty1,
             TC.TPPATDATACONSTRUCT{conPat=conInfo,
                                   instTyList=tylist,
                                   argPatOpt=NONE,
                                   patTy=ty1,
                                   loc=loc}
            )
        end

      | IC.ICPATEXN {longsymbol, id, ty=ity} =>
        let
          val loc = Symbol.longsymbolToLoc longsymbol
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity24\n"; raise e)
          val exnInfo = {path=longsymbol, id=id, ty=ty}
        in
          case TB.derefTy ty of
            T.FUNMty _ =>
            (
             E.enqueueError "Typeinf 047"
               (loc,
                E.ConRequireArg("047",{longsymbol = longsymbol}));
             (
              VarMap.empty,
              T.ERRORty,
              TC.TPPATWILD (T.ERRORty, loc)
             )
            )
          | _ =>
            (
             VarMap.empty,
             ty,
             TC.TPPATEXNCONSTRUCT{exnPat=TC.EXN exnInfo,
                                  instTyList=nil,
                                  argPatOpt=NONE,
                                  patTy=ty,
                                  loc=loc}
            )
        end
      | IC.ICPATEXEXN {longsymbol=refLongsymbol,
                       exInfo= exInfo as {used, ty=ity, longsymbol=longsymbol, version}} =>
        let
          val externalLongsymbol = exInfoToLongsymbol exInfo
          val longsymbol = Symbol.setVersion(longsymbol, version)
          val loc = Symbol.longsymbolToLoc refLongsymbol
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity25\n"; raise e)
          val exExnInfo = {path=externalLongsymbol, ty=ty}
        in
          case TB.derefTy ty of
            T.FUNMty _ =>
            (
             E.enqueueError "Typeinf 048"
               (loc,
                E.ConRequireArg("048",{longsymbol = longsymbol}));
             (
              VarMap.empty,
              T.ERRORty,
              TC.TPPATWILD (T.ERRORty, loc)
             )
            )
          | _ =>
            (
             VarMap.empty,
             ty,
             TC.TPPATEXNCONSTRUCT{exnPat=TC.EXEXN exExnInfo,
                                  instTyList=nil,
                                  argPatOpt=NONE,
                                  patTy=ty,
                                  loc=loc}
            )
        end
      | IC.ICPATCONSTANT constant =>
        let
          val loc = AbsynConst.getLocConstant constant
          val (ty, staticConst, staticConstraints) = typeinfConst constant
          val _ = addConstraints staticConstraints
        in
          (VarMap.empty, ty, TC.TPPATCONSTANT(staticConst, ty, loc))
        end
      | IC.ICPATCONSTRUCT {con=icpat1, arg=icpat2, loc} =>
        (case icpat1 of
           IC.ICPATCON {longsymbol, id, ty=ity} =>
           let
             val loc = Symbol.longsymbolToLoc longsymbol
             val ty = ITy.evalIty context ity
                 handle e => (P.print "ity26\n"; raise e)
             val conInfo = {path=longsymbol, id=id, ty=ty}
             val (ty1, tylist) =
                 case ty of
                   (T.POLYty{boundtvars, body, ...}) =>
                   let val subst = TB.freshSubst boundtvars
                   in
                     (TB.substBTvar subst body,
                      BoundTypeVarID.Map.listItems subst)
                   end
                 | _ => (ty, nil)
             val (varEnv1, patTy2, tppat2) =
                 typeinfPat lambdaDepth context icpat2
             val (domtyList, ranty, instTyList, constraints) =
                 TB.coerceFunM (ty, [patTy2])
                 handle TB.CoerceFun =>
                        (
                         E.enqueueError "Typeinf 049"
                           (loc,E.NonFunction("049",{ty = ty}));
                         ([T.ERRORty], T.ERRORty, nil, nil)
                        )
             val _ = addConstraints constraints
             val domty =
                 case domtyList of
                   [ty] => ty
                 | _ => raise bug "arity mismatch"
             val _ =
                 U.unify [(patTy2, domty)]
                 handle U.Unify =>
                        E.enqueueError "Typeinf 050"
                          (
                           loc,
                           E.TyConMismatch
                             ("050",{argTy = patTy2, domTy = domty})
                          )
           in
             (
              varEnv1,
              ranty,
              TC.TPPATDATACONSTRUCT
                {conPat=conInfo,
                 instTyList=instTyList,
                 argPatOpt=SOME tppat2,
                 patTy=ranty,
                 loc=loc}
             )
           end
         | IC.ICPATEXN {longsymbol, id, ty=ity} =>
           let
             val loc = Symbol.longsymbolToLoc longsymbol
             val ty = ITy.evalIty context ity
                 handle e => (P.print "ity27\n"; raise e)
             val exnInfo = {path=longsymbol, id=id, ty=ty}
             val (varEnv1, patTy2, tppat2) =
                 typeinfPat lambdaDepth context icpat2
             val (domtyList, ranty, instTyList, constraints) =
                 TB.coerceFunM (ty, [patTy2])
                 handle TB.CoerceFun =>
                        (
                         E.enqueueError "Typeinf 051"
                           (loc,E.NonFunction("051",{ty = ty}));
                         ([T.ERRORty], T.ERRORty, nil, nil)
                        )
             val _ = addConstraints constraints
             val domty =
                 case domtyList of
                   [ty] => ty
                 | _ => raise bug "arity mismatch"
             val _ =
                 U.unify [(patTy2, domty)]
                 handle U.Unify =>
                        E.enqueueError "Typeinf 052"
                          (
                           loc,
                           E.TyConMismatch
                             ("052",{argTy = patTy2, domTy = domty})
                          )
           in
             (
              varEnv1,
              ranty,
              TC.TPPATEXNCONSTRUCT{exnPat=TC.EXN exnInfo,
                                   instTyList=nil,
                                   argPatOpt=SOME tppat2,
                                   patTy=ranty,
(*
                                   patTy=ty,
*)
                                   loc=loc}
             )
           end
         | IC.ICPATEXEXN {longsymbol=refLongsymbol, 
                          exInfo= exInfo as {used, longsymbol, version, ty=ity}} =>
           let
             val loc = Symbol.longsymbolToLoc refLongsymbol
             val externalLongsymbol = exInfoToLongsymbol exInfo
             val ty = ITy.evalIty context ity
                 handle e => (P.print "ity28\n"; raise e)
             val exExnInfo = {path=externalLongsymbol, ty=ty}
             val (varEnv1, patTy2, tppat2) =
                 typeinfPat lambdaDepth context icpat2
             val (domtyList, ranty, instTyList, constraints) =
                 TB.coerceFunM (ty, [patTy2])
                 handle TB.CoerceFun =>
                        (
                         E.enqueueError "Typeinf 053"
                           (loc,E.NonFunction("053",{ty = ty}));
                         ([T.ERRORty], T.ERRORty, nil, nil)
                        )
             val _ = addConstraints constraints
             val domty =
                 case domtyList of
                   [ty] => ty
                 | _ => raise bug "arity mismatch"
             val _ =
                 U.unify [(patTy2, domty)]
                 handle U.Unify =>
                        E.enqueueError "Typeinf 054"
                          (
                           loc,
                           E.TyConMismatch
                             ("054",{argTy = patTy2, domTy = domty})
                          )
           in
             (
              varEnv1,
              ranty,
              TC.TPPATEXNCONSTRUCT{exnPat=TC.EXEXN exExnInfo,
                                   instTyList=nil,
                                   argPatOpt=SOME tppat2,
                                   patTy=ranty,
(*
                                   patTy=ty,
*)
                                   loc=loc}
             )
           end
         | _ =>
           (
            E.enqueueError "Typeinf 055"(loc, E.NonConstruct("055",{pat = icpat1}));
            (VarMap.empty, T.ERRORty, TC.TPPATWILD (T.ERRORty, loc))
           )
        )
      | IC.ICPATRECORD {flex, fields, loc} =>
        let
          val (varEnv1, tyFields, tppatFields) =
              foldl
                (fn ((label, icpat), (varEnv1, tyFields, tppatFields)) =>
                    let
                      val (varEnv2, ty, tppat) =
                          typeinfPat lambdaDepth context icpat
                    in
                      (
                       VarMap.unionWith
                         (fn _ => raise bug "duplicate id in idcalc")
                         (varEnv2, varEnv1),
                       RecordLabel.Map.insert(tyFields, label, ty),
                       RecordLabel.Map.insert(tppatFields, label, tppat)
                      )
                    end)
                (VarMap.empty, RecordLabel.Map.empty, RecordLabel.Map.empty)
                fields
          val ty1 =
              if flex
              then
                T.newtyRaw
                  {
                   lambdaDepth = lambdaDepth,
                   kind = T.KIND {tvarKind = T.REC tyFields,
                                  eqKind = T.NONEQ,
                                  dynKind = false,
                                  reifyKind = false,
                                  subkind = T.ANY},
                   utvarOpt = NONE
                  }
              else T.RECORDty tyFields
        in
          (varEnv1,
           ty1,
           TC.TPPATRECORD{fields=tppatFields, recordTy=ty1, loc=loc}
          )
        end
      | IC.ICPATLAYERED {patVar as {longsymbol,id}, tyOpt, pat, loc} =>
        let
          val (varEnv1, ty1, tpat) = typeinfPat lambdaDepth context pat
          val _ =
              case tyOpt of
                NONE => ()
              | SOME ity =>
                let val ty2 = ITy.evalIty context ity
                        handle e => (P.print "ity29\n"; raise e)
                in
                  U.unify [(ty1, ty2)]
                  handle U.Unify =>
                         E.enqueueError "Typeinf 056"
                           (
                            loc,
                            E.TypeAnnotationNotAgree
                              ("056",{ty = ty1, annotatedTy = ty2})
                           )
                end
          val varInfo = TCU.newTCVarInfoWithLongsymbol (longsymbol, ty1)
        in
          (
           VarMap.insert (varEnv1, patVar, TC.VARID varInfo),
           ty1,
           TC.TPPATLAYERED
             {varPat=TC.TPPATVAR varInfo, asPat=tpat, loc=loc}
          )
        end
      | IC.ICPATTYPED (icpat, ty, loc) =>
        let
          val (varEnv1, ty1, tppat) = typeinfPat lambdaDepth context icpat
          val ty2 = ITy.evalIty context ty
              handle e => (P.print "ity30\n"; raise e)
          val _ = U.unify [(ty1, ty2)]
              handle U.Unify =>
                     E.enqueueError "Typeinf 057"
                       (
                        loc,
                        E.TypeAnnotationNotAgree
                          ("057",{ty = ty1, annotatedTy = ty2})
                       )
        in
          (varEnv1, ty2, tppat)
        end

  and typeinfFFIArg lambdaDepth applyDepth context ffiarg =
      case ffiarg of
        IC.ICFFIARG (icexp, ffity, loc) =>
        let
          val (argTy, instConstraints, argExp) =
              TCU.freshInst (typeinfExp lambdaDepth applyDepth context icexp)
          val _ = addConstraints instConstraints
          val ffity = evalFFIty context (EXPORT, SAFE) ffity
          val stubTy = ffiStubTy ffity
          val _ =
              U.unify [(argTy, stubTy)]
              handle U.Unify =>
                     E.enqueueError "Typeinf 058"
                       (loc, E.TypeAnnotationNotAgree
                               ("058",{ty = argTy, annotatedTy = stubTy}))
        in
          (ffity, (argTy, argExp))
        end
      | IC.ICFFIARGSIZEOF (ty, factorExpOpt, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity31\n"; raise e)
          val sizeofExp =
              TC.TPCAST ((TC.TPSIZEOF (ty, loc), T.SINGLETONty (T.SIZEty ty)),
                         BT.wordTy, loc)
          val argExp =
              case factorExpOpt of
                NONE => sizeofExp
              | SOME ptfactorExp =>
                let
                  val (factorTy, factorConstraints, factorExp) =
                      TCU.freshInst (typeinfExp lambdaDepth applyDepth context
                                                ptfactorExp)
                  val _ = addConstraints factorConstraints
                  val _ =
                      U.unify [(BT.wordTy, factorTy)]
                      handle U.Unify =>
                             (E.enqueueError "Typeinf 059"
                                (loc, E.FFIStubMismatch
                                        ("059",BT.wordTy, factorTy)))
                  val argPair =
                      makeTupleExp ([(BT.wordTy, sizeofExp),
                                     (BT.wordTy, factorExp)], loc)
                  val argTy = makeTupleTy [BT.wordTy, BT.wordTy]
                in
                  TC.TPPRIMAPPLY
                    {primOp =
                       {primitive = BP.L (BP.R (BP.M BP.Word32_mul)),
                        ty = T.FUNMty ([argTy],
                                       BT.wordTy)},
                     instTyList = nil,
                     argExp = argPair,
                     argTy = argTy,
                     loc = loc}
                end
        in
          (TC.FFIBASETY (BT.wordTy, loc), (BT.wordTy, argExp))
        end
  (**
   * infer a possibly polytype for a match
   *)
  and typeinfMatch lambdaDepth applyDepth argtyList context [rule] =
      let
        val (ty1, typedRule) =
          typeinfRule lambdaDepth applyDepth argtyList context rule
      in
        (ty1, [typedRule])
      end
    | typeinfMatch lambdaDepth _ argtyList context (rule :: rules) =
      let
        val (tyRule, typedRule) =
          monoTypeinfRule lambdaDepth argtyList context rule
        val (tyRules, typedRules) =
          monoTypeinfMatch lambdaDepth argtyList context rules
      in
        (
          U.unify [(tyRule, tyRules)];
          (tyRules, typedRule::typedRules)
        )
        handle U.Unify =>
               (
                 E.enqueueError "Typeinf 060"
                     (
                       IC.getRuleLocM [rule],
                       E.RuleTypeMismatch
                         ("060",{thisRule = tyRule, otherRules = tyRules})
                     );
                 (T.ERRORty, nil)
               )
      end
    | typeinfMatch _ _ argtyList context nil =
      raise bug "typeinfMatch, empty rule"

  (**
   * infer a mono type for a match
   * @params argTy context match
   *)
  and monoTypeinfMatch lambdaDepth argtyList context [rule] =
      let
        val (ty1, typedRule) =
          monoTypeinfRule lambdaDepth argtyList context rule
      in
        (ty1, [typedRule])
      end
    | monoTypeinfMatch lambdaDepth argtyList context (rule :: rules) =
      let
        val (ruleTy, typedRule) =
          monoTypeinfRule lambdaDepth argtyList context rule
        val (rulesTy, typedRules) =
          monoTypeinfMatch lambdaDepth argtyList context rules
      in
        (
          U.unify [(ruleTy, rulesTy)];
          (rulesTy, typedRule :: typedRules)
        )
        handle U.Unify =>
               (
                 E.enqueueError "Typeinf 061"
                     (
                       getRuleLocM [rule],
                       E.RuleTypeMismatch
                         ("061",{thisRule = ruleTy, otherRules = rulesTy})
                     );
                 (T.ERRORty, nil)
               )
      end
    | monoTypeinfMatch lambdaDepth argty context nil =
      raise bug "monoTypeinfMatch, empty rule"
  (**
   * infer a monotype for a rule
   * @params argTy basis rule
   *)
  and monoTypeinfRule lambdaDepth argtyList context {args=patList,body=exp} =
      let
        val (varEnv1, patTyList, typedPatList) =
          typeinfPatList lambdaDepth context patList
        val (bodyTy, bodyConstraints, typedExp) =
          TCU.freshInst (typeinfExp
                         lambdaDepth
                         inf
                         (TIC.extendContextWithVarEnv(context, varEnv1))
                         exp)
        val _ = addConstraints bodyConstraints
      in
        (
          U.unify (ListPair.zip(patTyList, argtyList));
          (T.FUNMty(patTyList, bodyTy), {args=typedPatList, body=typedExp})
        )
        handle U.Unify =>
               let val ruleLoc = IC.getRuleLocM [{args=patList, body=exp}]
               in
                 E.enqueueError "Typeinf 062"
                 (ruleLoc,
                  E.TyConListMismatch
                    ("062",{argTyList = argtyList, domTyList = patTyList}));
                 (T.ERRORty,
                  {args=[TC.TPPATWILD(T.ERRORty, ruleLoc)],body=TC.TPERROR})
               end
      end

  (**
   * infer a possibly polytype for a rule
   * @params applyDepth argTy context rule
   *)
  and typeinfRule lambdaDepth applyDepth argtyList context
                  {args=patList,body=exp} =
      let
        val (varEnv1, patTyList, typedPatList) =
          typeinfPatList lambdaDepth context patList
        val (bodyTy, typedExp) =
            typeinfExp
            lambdaDepth
            applyDepth
            (TIC.extendContextWithVarEnv(context, varEnv1))
            exp
      in
        (
          U.unify (ListPair.zip(patTyList, argtyList));
          (T.FUNMty(patTyList, bodyTy),
           {args=typedPatList, body=typedExp})
        )
        handle U.Unify =>
               let val ruleLoc = IC.getRuleLocM [{args=patList, body=exp}]
               in
                 E.enqueueError "Typeinf 063"
                 (ruleLoc,
                  E.TyConListMismatch
                    ("063",{argTyList = argtyList, domTyList = patTyList}));
                 (T.ERRORty,
                  {args=map (fn x => TC.TPPATWILD(T.ERRORty, ruleLoc)) patList,
                   body=TC.TPERROR}
                 )
               end
      end

  and typeinfPatList lambdaDepth context icpatList =
      let
        val (varEnv1, tyPatListRev, tppatListRev) =
            foldl
              (fn (icpat, (varEnv1, tyPatListRev, tppatListRev)) =>
                  let
                    val (varEnv2, ty, tppat) = typeinfPat lambdaDepth context icpat
                  in
                    (
                     VarMap.unionWith
                       (fn (varId as (TC.VARID{path, ...}), _) =>
                           (E.enqueueError
                              "Typeinf 064"
                              (
                               Symbol.longsymbolToLoc path,
                               E.DuplicatePatternVar
                                 ("064", {longsymbol = path}));
                            varId)
                         | _ =>
                           raise
                             bug
                               "non VARID in varEnv1 or 2\
                               \ (typeinference/main/TypeInferCore.sml)"
                       )
                       (varEnv2, varEnv1),
                     ty::tyPatListRev,
                     tppat::tppatListRev
                    )
                  end)
              (VarMap.empty, nil, nil)
              icpatList
      in
        (varEnv1, List.rev tyPatListRev, List.rev tppatListRev)
      end

  (**
   * infer a type for ptdecl
   * @params context ptdeclList
   * @return  a new context and tpdeclList
   *)
  and typeinfDeclList lambdaDepth context nil =
        (TIC.emptyContext, nil)
    | typeinfDeclList lambdaDepth context (icdecl :: icdeclList) =
      let
        val (newContext1:TIC.context, tpdeclList1) =
            typeinfDecl lambdaDepth context icdecl
        val (newContext2:TIC.context, tpdeclList) =
            typeinfDeclList
              lambdaDepth
              (TIC.extendContextWithContext (context, newContext1))
              icdeclList
      in
        (
         TIC.extendContextWithContext (newContext1, newContext2),
         tpdeclList1 @ tpdeclList
        )
      end

  (**
     exceptions
      E.RecValNotID
      E.DuplicateTargsInTypeDef
   *)
  and typeinfDecl lambdaDepth (context:TIC.context) icdecl =
    let
      val lambdaDepth = lambdaDepth
    in
      case icdecl of
        IC.ICVAL (scopedTvars, icpatIcexpList, loc) =>
        (
        let
          val lambdaDepth = incDepth ()
          (* 2012-7-25 ohori: bug val003.sml.
              scopedTvars must be evaluated for each icexp
          val (newContext, addedUtvars) =
              evalScopedTvars lambdaDepth context scopedTvars loc
          *)

          val (localBinds, patternVarBinds, extraBinds) =
              foldl
                (fn ((icpat,icexp),(localBinds,patternVarBinds,extraBinds)) =>
                    let
                      val (newContext, addedUtvars) =
                          evalScopedTvars lambdaDepth context scopedTvars loc
                      val (localBinds1, patternVarBinds1, extraBinds1) =
                          (decomposeValbind
                             lambdaDepth
                             newContext
                             (icpat, icexp))
                          handle
                          exn as E.RecordLabelSetMismatch _ =>
                          (
                           E.enqueueError "Typeinf 065"
                             (Loc.mergeLocs
                                (IC.getLocPat icpat, IC.getLocExp icexp),
                              exn);
                           (nil, nil, nil)
                          )
                        | exn as E.PatternExpMismatch _ =>
                          (
                           E.enqueueError "Typeinf 066"
                             (Loc.mergeLocs
                                (IC.getLocPat icpat, IC.getLocExp icexp),
                              exn);
                           (nil, nil, nil)
                          )
                     (* The following is added to fix the bug 68. *)
                      val tyvarSet =
                          (
                           foldl
                             (fn (({ty,...}, _), tyvarSet) =>
                                 OTSet.union(#2 (TB.EFTV (ty, !constraints)), tyvarSet)
                             )
                             OTSet.empty
                             (patternVarBinds1@extraBinds1)
                          )
                          handle x => raise x
                      val _ =
                          (
                           TvarMap.appi
                             (fn (utvar, ref (T.SUBSTITUTED ty)) =>
                                 (case TB.derefTy ty of
                                    T.BOUNDVARty _ => ()
                                  | T.TYVARty (tvstateRef
                                                 as ref (T.TVAR {kind = T.KIND {eqKind,...},...}))
                                    =>
                                    if OTSet.member(tyvarSet, tvstateRef) then
                                      E.enqueueError "Typeinf 067"
                                        (loc,
                                         E.UserTvarNotGeneralized
                                           ("067",
                                            {eq = eqKind,
                                             symbol = #symbol utvar}))
                                    else ()
                                  | _ =>
                                    (
                                     T.printTy ty;
                                     raise bug "SUBSTITUTED to Non BoundVarTy"
                                    )
                                 )
                               | (utvar,
                                  tvstateRef as (ref (T.TVAR{kind = T.KIND {eqKind,...},...}))) =>
                                 if OTSet.member(tyvarSet, tvstateRef) then
                                   E.enqueueError "Typeinf 068"
                                     (loc,
                                      E.UserTvarNotGeneralized
                                        ("068",
                                         {eq = eqKind,
                                          symbol = #symbol utvar})
                                     )
                                 else ()
                             )
                             addedUtvars
                          )
                          handle x => raise x
                    in
                      (
                       localBinds @ localBinds1,
                       patternVarBinds @ patternVarBinds1,
                       extraBinds @ extraBinds1
                      )
                    end)
                (nil, nil, nil)
                icpatIcexpList
          fun bindVar (lambdaDepth, varEnv, var, varInfo as {ty,...}) =
              (TB.adjustDepthInTy (ref false) lambdaDepth ty;
               VarMap.insert(varEnv, var, TC.VARID varInfo))
          val newVarEnv =
              foldl
                (fn ((varInfo as {path, id,...}, _), newVarEnv) =>
                    let
                      val var = {longsymbol = path, id = id}
                    in
                      bindVar (lambdaDepth, newVarEnv, var, varInfo)
                    end
                )
                VarMap.empty
                (patternVarBinds@extraBinds)
        in
          (
           {
            varEnv = newVarEnv,
            tvarEnv = TvarMap.empty,
            oprimEnv = OPrimMap.empty
           },
           let
             val exportDecls =
                 (if null patternVarBinds then nil
                  else [TC.TPVAL (patternVarBinds, loc)])
                 @
                 (if null extraBinds then nil
                  else [TC.TPVAL (extraBinds, loc)])
             val decls =
             case localBinds of
               nil => exportDecls
             | _ =>
               map (fn x => TC.TPVAL ([x], loc)) localBinds
               @
               exportDecls
           in
             decls
           end
          )
        end
        handle Fail => (TIC.emptyContext,nil)
        )
      | IC.ICDECFUN {guard,funbinds,loc} =>
        let
          val lambdaDepth = incDepth ()
          val (newContext, addedUtvars) =
              evalScopedTvars lambdaDepth context guard loc
          fun arityOfMatch match =
              case match of
                nil => raise bug "empty match in fundecl"
              | {args,body}::_ => List.length args
          fun argTyListOfMatch match =
              case match of
                nil => raise bug "empty match in fundecl"
              | {args,body}::_ =>
                 map
                   (fn _ => T.newtyWithLambdaDepth (lambdaDepth, T.univKind))
                   args
          val (newContext, funTyList) =
              foldr
                (* tyList in funbinds should not be there *)
                (fn ({funVarInfo=funVar as {longsymbol, id},
                      tyList,
                      rules=icmatch},
                     (newContext,funTyList)) =>
                    let
                      val arity = arityOfMatch icmatch
                      val funTy =
                          T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                      val funVarInfo = {path=longsymbol, id=id, ty=funTy, opaque=false}
                      val tyList = map (ITy.evalIty context) tyList
                      (* ty should be all mono,
                         so the following should not be needed *)
                      val tyConstraintList = map TB.freshRigidInstTy tyList
                      val (tyList, constraintsList) = ListPair.unzip tyConstraintList
                      val _ = List.app (fn cl => addConstraints cl) constraintsList
                    in
                      (
                       TIC.bindVar
                         (lambdaDepth,
                          newContext,
                          TCVarToICVar funVarInfo,
                          TC.RECFUNID (funVarInfo, arity)
                         ),
                       (funTy, tyList)::funTyList)
                    end
                )
                (newContext, nil)
                funbinds
          val icpatRuleFunTyList = ListPair.zip (funbinds,funTyList)
          val funBindListRev =
              foldl
                (fn (({funVarInfo={longsymbol,id},tyList=_, rules=icmatch},(funTy, tyList)),
                     funBindListRev) =>
                    let
                      val argTyList = argTyListOfMatch icmatch
                      val funVarInfo = {path=longsymbol, id=id, ty=funTy, opaque=false}
                      val (tpmatchTy, tpmatch) =
                          monoTypeinfMatch
                            lambdaDepth argTyList newContext icmatch
                      fun curryTy (T.FUNMty(argTyList, ty)) =
                          foldr
                            (fn (ty, body) => T.FUNMty([ty], body))
                            ty
                            argTyList
                        | curryTy ty = ty
                      val funType = curryTy (TB.derefTy tpmatchTy)
                      val tyEquations = map (fn x => (funTy, x)) (funType::tyList)
                      val _ =
                          U.unify tyEquations
                          handle U.Unify =>
                                 E.enqueueError "Typeinf 069"
                                   (
                                    loc,
                                    E.RecDefinitionAndOccurrenceNotAgree
                                      ("069",
                                       {
                                        longsymbol = longsymbol,
                                        definition = funType,
                                        occurrence = funTy
                                       }
                                      )
                                   )
                    in
                      {
                       funVarInfo = funVarInfo,
                       bodyTy = case TB.derefTy tpmatchTy of
                                  T.FUNMty (_, bodyTy) => bodyTy
                                | T.ERRORty =>  T.ERRORty
                                | _ => raise bug "non fun type in fundecl",
                       argTyList = argTyList,
                       ruleList = tpmatch
                      } ::funBindListRev
                    end
                )
                nil
                icpatRuleFunTyList

          val funBindList = List.rev funBindListRev
          val TypesOfAllElements =
              T.RECORDty
                (foldl
                   (fn ({funVarInfo={path, id, ty, opaque},...}, tyFields) =>
                       RecordLabel.Map.insert(tyFields, RecordLabel.fromLongsymbol path, ty))
                   RecordLabel.Map.empty
                   funBindList)

          val {boundEnv, boundConstraints, ...} = generalizer (TypesOfAllElements, lambdaDepth)

          val _ =
              TvarMap.appi
                (fn ({symbol, id, eq, lifted}, ref (T.SUBSTITUTED ty)) =>
                    (case TB.derefTy ty of
                       T.BOUNDVARty _ => ()
                     | T.TYVARty (tvstateRef as ref (T.TVAR {kind = T.KIND {eqKind,...},...}))
                       =>
                       E.enqueueError "Typeinf 070"
                         (loc,
                          E.UserTvarNotGeneralized
                            ("070", {eq = eqKind, symbol = symbol}))
                     | _ =>
                       (
                        print "illeagal utvar instance in\n";
                        T.printTy ty;
                        print "\n ty printed \n";
                        raise
                          bug
                            "illeagal utvar instance in\
                            \ UserTvarNotGeneralized check"
                       )
                    )
                  | ({symbol, id, eq, lifted}, ref (T.TVAR {kind = T.KIND {eqKind,...},...}))  =>
                    E.enqueueError "Typeinf 071"
                      (loc,
                       E.UserTvarNotGeneralized
                         ("071", {eq = eqKind, symbol = symbol})
                      )
                )
                addedUtvars
        in
          if BoundTypeVarID.Map.isEmpty boundEnv
          then
            (
             foldl
               (fn
                (
                 {
                  funVarInfo,
                  argTyList,
                  bodyTy,
                  ruleList
                 },
                 newContext) =>
                   TIC.bindVar
                     (
                      lambdaDepth,
                      newContext,
                      TCVarToICVar funVarInfo,
                      TC.RECFUNID (funVarInfo, length argTyList)
                     )
               )
               TIC.emptyContext
               funBindList,
             [TC.TPFUNDECL (funBindList, loc)]
            )
          else
            (
             foldl
               (fn ({funVarInfo= funVar as {path, id, ty, opaque}, argTyList,...},
                    newContext) =>
                   TIC.bindVar
                     (
                      lambdaDepth,
                      newContext,
                      TCVarToICVar funVar,
                        TC.RECFUNID
                          (
                           {path=path,
                            id=id,
                            opaque=opaque,
                            ty=T.POLYty{boundtvars=boundEnv, constraints = boundConstraints, body = ty}},
                           length argTyList
                          )
                     )
               )
               TIC.emptyContext
               funBindList,
             [TC.TPPOLYFUNDECL (boundEnv, funBindList, loc)]
            )
        end
      | IC.ICNONRECFUN{guard, funVarInfo, tyList, rules, loc} =>
         let
           val lambdaDepth = lambdaDepth
           val funPat =
               foldl
               (fn (ty, pat) => IC.ICPATTYPED(pat, ty, loc))
               (IC.ICPATVAR_TRANS funVarInfo)
               tyList
           val icdecls =
             case rules of
               {args = [pat], body} :: _ =>
               [(funPat, IC.ICFNM(rules, loc))]
             | [{args=patList as (pat::_), body}] =>
               let
                 val firstLoc = IC.getLocPat pat
                 val lastLoc = IC.getLocPat (List.last patList)
                 val patFields = RecordLabel.tupleList patList
                   val _ =
                     freeVarsInPat
                     (IC.ICPATRECORD
                       {flex=false,
                        fields=patFields,
                        loc = Loc.mergeLocs(firstLoc, lastLoc)})
               in
                 [(funPat,
                   foldr
                     (fn (pat, funBody) =>
                         IC.ICFNM([{args=[pat], body=funBody}],
                                 loc))
                     body
                     patList)
                 ]
               end
             | _ => transFunDecl context loc (funVarInfo, rules)
         in
           typeinfDecl lambdaDepth
                       context
                       (IC.ICVAL(guard, icdecls, loc))
         end
      | IC.ICVALREC {guard, recbinds, loc} =>
        let
          val lambdaDepth = incDepth ()
          val (newContext, addedUtvars) =
              evalScopedTvars lambdaDepth context guard loc
          val (recbinds, newContext) =
              foldr
                (fn ({varInfo = var as {longsymbol, id}, tyList, body},
                     (recbinds, newContext)) =>
                    let
                      val ty = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                      val varInfo = {path=longsymbol, id=id, ty=ty, opaque=false}
                      val tyList = map (ITy.evalIty context) tyList
                      (* ty should be all mono,
                         so the following should not be needed *)
                      val tyConstraintsList = map TB.freshRigidInstTy tyList
                      val (tyList, constraintsList) = ListPair.unzip tyConstraintsList
                      val _ = List.app (fn cl => addConstraints cl) constraintsList
                    in
                      (
                       (varInfo, tyList, body) :: recbinds,
                       TIC.bindVar
                         (lambdaDepth, newContext, var, TC.VARID varInfo)
                      )
                    end)
                (nil, newContext)
                recbinds
          val varInfoTyTpexpList =
              let
                fun inferRule (varInfo as {path, ty, id, opaque}, tyList, icexp) =
                    let
                      val (icexpTy, tpexp) =
                          typeinfExp lambdaDepth inf newContext icexp
                      val tyEquations = map (fn x => (ty, x)) (icexpTy::tyList)
                      val _ =
                          U.unify tyEquations
                          handle
                          U.Unify =>
                          E.enqueueError "Typeinf 072"
                            (
                             loc,
                             E.RecDefinitionAndOccurrenceNotAgree
                               ("072",
                                {
                                 longsymbol = path,
                                 definition = icexpTy,
                                 occurrence = ty
                                }
                               )
                            )
                    in
                      {var=varInfo, expTy=icexpTy, exp=tpexp}
                    end
              in
                map inferRule recbinds
              end
          val TypesOfAllElements =
              T.RECORDty
                (foldl
                   (fn ({var={path,ty,id, opaque},...}, tyFields) =>
                       RecordLabel.Map.insert(tyFields, RecordLabel.fromLongsymbol path, ty))
                   RecordLabel.Map.empty
                   varInfoTyTpexpList)
          val {boundEnv, boundConstraints, ...} =
              generalizer (TypesOfAllElements, lambdaDepth)
          val _ =
              TvarMap.appi
                (fn ({symbol,...}, ref (T.SUBSTITUTED ty)) =>
                    (case TB.derefTy ty of
                       T.BOUNDVARty _ => ()
                     | T.TYVARty (tvstateRef as ref (T.TVAR {kind = T.KIND {eqKind,...},...}))
                       =>
                       E.enqueueError "Typeinf 073"
                         (loc,
                          E.UserTvarNotGeneralized
                            ("073", {eq = eqKind, symbol = symbol}))
                     | _ =>
                       (
                        T.printTy ty;
                        raise
                          bug
                            "illeagal utvar instance in\
                            \ UserTvarNotGeneralized check"
                       )
                    )
                  | ({symbol,...}, ref (T.TVAR{kind = T.KIND {eqKind,...},...}))  =>
                    E.enqueueError "Typeinf 074"
                      (loc,
                       E.UserTvarNotGeneralized
                         ("074",
                          {eq = eqKind, symbol = symbol}
                         )
                      )
                )
                addedUtvars
        in
          if BoundTypeVarID.Map.isEmpty boundEnv
          then
            (
             foldl
               (fn ({var=varInfo,...}, newContext) =>
                   TIC.bindVar
                     (
                      lambdaDepth,
                      newContext,
                      TCVarToICVar varInfo,
                      TC.VARID varInfo
                     )
               )
               (TIC.emptyContext)
               varInfoTyTpexpList,
             [TC.TPVALREC (varInfoTyTpexpList, loc)]
            )
          else
            (
             foldl
               (fn ({var= var as {path, id, ty, opaque},...}, newContext) =>
                   TIC.bindVar
                     (
                      lambdaDepth,
                      newContext,
                      TCVarToICVar var,
                      TC.VARID {path=path,
                                id=id,
                                opaque=opaque,
                                ty= T.POLYty{boundtvars = boundEnv, constraints = boundConstraints, body = ty}
                               }
                     )
               )
               TIC.emptyContext
               varInfoTyTpexpList,
             [TC.TPVALPOLYREC (boundEnv, varInfoTyTpexpList, loc)]
            )
        end
      | IC.ICVALPOLYREC (recbinds, loc) =>
        let
          val lambdaDepth = incDepth ()
          val (recbinds, newContext) =
              foldr
                (fn ({varInfo = var as {longsymbol,id}, ty=ity, body},
                     (recbinds, newContext)) =>
                    let
                      val ty = ITy.evalIty context ity handle e => (P.print "ity polyrec\n"; raise e)
                      val varInfo = {path=longsymbol, id=id, ty=ty, opaque=false}
                    in
                      (
                       (varInfo, ity, body) :: recbinds,
                       TIC.bindVar
                         (lambdaDepth, newContext, var, TC.VARID varInfo)
                      )
                    end)
                (nil, context)
                recbinds
          val varInfoTyTpexpList =
              let
                fun inferRule (varInfo as {path, ty, id, opaque}, ity, icexp) =
                    let
                      val (scopedTvars, bodyTyExp) =
                          case ity of
                            IC.TYPOLY(tvarList, bodyTy) => (tvarList, bodyTy)
                          | ty => (nil, ty)
                      val icexp = IC.ICTYPED(icexp, bodyTyExp, loc)
                      val (newContext, addedUtvars) =
                          evalScopedTvars lambdaDepth newContext scopedTvars loc
                      val (icexpTy, tpexp) =
                          typeinfExp lambdaDepth inf newContext icexp
                      val {boundEnv, boundConstraints, ...} =
                          generalizer (icexpTy, lambdaDepth)
                      val _ =
                          TvarMap.appi
                            (fn ({symbol, id, eq, lifted}, ref (T.SUBSTITUTED ty)) =>
                                (case TB.derefTy ty of
                                   T.BOUNDVARty _ => ()
                                 | T.TYVARty (tvstateRef as ref (T.TVAR {kind = T.KIND {eqKind,...},...}))
                                   =>
                                   E.enqueueError "Typeinf 075"
                                                  (loc,
                                                   E.UserTvarNotGeneralized
                                                     ("075",{eq = eqKind,
                                                             symbol = symbol}))
                                 | _ =>
                                   (
                                    T.printTy ty;
                                    raise
                                      bug
                                        "illeagal utvar instance in\
                                        \ UserTvarNotGeneralized  check"
                                   )
                                )
                              | ({symbol, id, eq, lifted}, ref (T.TVAR {kind = T.KIND {eqKind,...},...}))  =>
                                E.enqueueError "Typeinf 076"
                                               (loc,
                                                E.UserTvarNotGeneralized
                                                  ("076",
                                                   {eq = eqKind,
                                                    symbol = symbol}
                                                  )
                                               )
                            )
                            addedUtvars
                      val icexpPolyTy = 
                          if BoundTypeVarID.Map.isEmpty boundEnv then
                            icexpTy
                          else T.POLYty {boundtvars=boundEnv, constraints = boundConstraints, body=icexpTy}
                      val tpexpPoly =
                          if BoundTypeVarID.Map.isEmpty boundEnv then
                            tpexp
                          else TC.TPPOLY {btvEnv=boundEnv, expTyWithoutTAbs=icexpTy, exp=tpexp, loc=loc}
                      val _ =
                          if U.eqTy BoundTypeVarID.Map.empty (icexpPolyTy, ty) then ()
                          else
                            E.enqueueError
                              "Typeinf 077"
                              (loc, 
                               E.TypeAnnotationNotAgree
                                 ("077", {ty=icexpTy, annotatedTy=ty}))
                    in
                      {var=varInfo, expTy=icexpTy, exp=tpexpPoly}
                    end
              in
                map inferRule recbinds
              end
        in
          (
           foldl
             (fn ({var=varInfo,...}, newContext) =>
                 TIC.bindVar
                   (
                    lambdaDepth,
                    newContext,
                    TCVarToICVar varInfo,
                    TC.VARID varInfo
                   )
             )
             TIC.emptyContext
             varInfoTyTpexpList,
           [TC.TPVALREC (varInfoTyTpexpList, loc)]
          )
        end

      | IC.ICEXND (exnconLocList, loc) =>
        (TIC.emptyContext,
         [TC.TPEXD
            (map
               (fn {exnInfo = {longsymbol, id, ty=ity}, loc} =>
                   {exnInfo={path= longsymbol,
                             id=id,
                             ty=ITy.evalIty context ity
                             handle e => (P.print "ity32\n"; raise e)
                            },
                    loc=loc})
               exnconLocList,
             loc
           )
         ]
        )
      | IC.ICEXNTAGD ({exnInfo={longsymbol, id, ty=ity}, varInfo},loc) =>
        let
          val varInfo =
              case VarMap.find(#varEnv context, varInfo)  of
                SOME (TC.VARID varInfo) => varInfo
              | SOME (TC.RECFUNID _) =>
                raise bug "recfunvar in ICEXNTAGD"
              | NONE =>
                if E.isError() then raise Fail
                else raise bug "var not found (3)"
        in
          (TIC.emptyContext,
           [TC.TPEXNTAGD
              (
               {exnInfo = {path=longsymbol,id=id,
                           ty=ITy.evalIty context ity
                              handle e => (P.print "ity33\n"; raise e)
                          },
                varInfo = varInfo},
               loc
              )
           ]
           )
        end
      | IC.ICEXPORTFUNCTOR {exInfo = exInfo as {used, longsymbol, version, ty=ity}, id} =>
        (* 2013-7-27 ohori. 
           Although we process version here, this is only generated in the 
           separate compilation mode, so version is NONE. 
         *)
        (* four possibilities in functorTy
           1. TYPOLY(btvs, TYFUNM([first], TYFUNM(polyList, body)))
              ICFNM1([first], ICFNM1_POLY(polyPats, BODY))
           2. TYPOLY(btvs, TYFUNM([first], body))
              ICFNM1([first], BODY)
           3. TYFUNM(polyList, body)
              ICFNM1_POLY(polyPats, BODY)
           4. TYFUNM([unit], body)
              ICFNM1(UNIT, BODY)
          where body is either
            unit (TYCONSTRUCT ..)
           or
            record (TYRECORD ..)
          BODY is ICLET(..., ICCONSTANT or ICRECORD)
         *)
        let
          val loc = Symbol.longsymbolToLoc longsymbol
          val externalLongsymbol = exInfoToLongsymbol exInfo
          val ty1 = ITy.evalIty context ity handle e => (P.print "ity34\n"; raise e)
          val (ty2, tpdecl) =
              case VarMap.find(#varEnv context, {longsymbol=longsymbol, id=id}) of
                     SOME (idstatus as TC.VARID {ty,...}) =>
                     (ty, TC.TPEXPORTVAR {ty=ty, id=id, path=externalLongsymbol, opaque=false})
                   | SOME (TC.RECFUNID({ty,...},_)) =>
                     raise bug "RECFUNID for functor"
                   | NONE =>
                     if E.isError() then raise Fail
                     else raise bug "var not found (4)"
        in
          if U.eqTy  BoundTypeVarID.Map.empty (ty1, ty2) then
            (TIC.emptyContext, [tpdecl])
          else
            let
              val _ = P.print "ICEXPORTFUNCTOR: noneq:"
              val tpexp = TC.TPVAR {path=longsymbol,id=id,ty=ty2, opaque=false}
              fun checkPoly (polyList, actualPolyList) =
                  if U.eqTyList
                       BoundTypeVarID.Map.empty (polyList,actualPolyList) then ()
                  else
                    (E.enqueueError
                       "Typeinf 078"
                       (loc, E.TypeAnnotationNotAgree
                               ("078",{ty=ty2,annotatedTy=ty1}));
                     raise Fail
                    )
              val (context, decls) =
                  case ty1 of
                    (* 1. TYPOLY(btvs,TYFUNM([firstArgty],TYFUNM(polyList,body)))*)
                    T.POLYty{boundtvars,
                             constraints,
                             body=
                             toBodyTy
                               as T.FUNMty([first],T.FUNMty(polyTys,bodyTy))} =>
                    let
                      val (ty22, instConstraints, tpexp) = TCU.freshToplevelInst(ty2,tpexp)
                      val _ = addConstraints instConstraints
                    in
                      (case ty22 of
                         T.FUNMty([actualFirst],
                                  T.FUNMty(actualPolyTys,actualBodyTy))=>
                         (let
                            val _ = U.unify[(actualFirst, first)]
                                handle
                                U.Unify =>
                                (E.enqueueError
                                   "Typeinf 079"
                                   (loc, E.TypeAnnotationNotAgree
                                           ("079",{ty=ty2,annotatedTy=ty1}));
                                 raise Fail
                                )
                            val _ = checkPoly (actualPolyTys, polyTys)
                            val firstVar = TCU.newTCVarInfo loc first
                            val firstExp = TC.TPVAR firstVar
                            val polyVars = map (TCU.newTCVarInfo loc) polyTys
                            val polyExps = map TC.TPVAR polyVars
                            val bodyExp1 =
                                TC.TPAPPM{funExp=tpexp,
                                          funTy=ty22,
                                          argExpList=[firstExp],
                                          loc=loc}
                            val bodyExp =
                                TC.TPAPPM{funExp=bodyExp1,
                                          funTy=T.FUNMty(polyTys,actualBodyTy),
                                          argExpList=polyExps,
                                          loc=loc}
                            val {tpexp=newBodyExp, constraints=newConstraints} =
                                TIU.coerceTy(bodyExp,actualBodyTy,bodyTy,loc)
                                handle
                                TIU.CoerceTy =>
                                (E.enqueueError
                                   "Typeinf 081"
                                   (loc, E.TypeAnnotationNotAgree
                                           ("081",{ty=ty2,annotatedTy=ty1}));
                                 raise Fail
                                )
                            val _ = addConstraints newConstraints;
                            val newTpexp =
                                TC.TPFNM {argVarList=[firstVar],
                                          bodyExp= TC.TPFNM{argVarList=polyVars,
                                                            bodyExp=newBodyExp,
                                                            bodyTy=bodyTy,
                                                            loc=loc},
                                          bodyTy=toBodyTy,
                                          loc=loc}
                            val tpexp =
                                TC.TPPOLY{btvEnv=boundtvars,
                                          expTyWithoutTAbs=toBodyTy,
                                          exp=newTpexp,
                                          loc=loc}
                            val newId = VarID.generate()
                            val newVar = {id=newId, path=longsymbol, ty=ty1, opaque=false}
                            val newExternalVar = {path=externalLongsymbol, ty=ty1}
                            val newDecl = TC.TPVAL([(newVar, tpexp)], loc)
                            val newIdstatus = TC.VARID newVar
                          in
                            (TIC.emptyContext,
                             [newDecl,
                              TC.TPEXPORTVAR {path=externalLongsymbol, id=newId, ty=ty1, opaque=false}]
                            )
                          end
                         )
                       | _ =>
                         (E.enqueueError
                            "Typeinf 082"
                            (loc, E.TypeAnnotationNotAgree
                                    ("082",{ty=ty2,annotatedTy=ty1}));
                          raise Fail
                         )
                      )
                    end
                  | (* 2. TYPOLY(btvs, TYFUNM([firstArgty], body)) *)
                    T.POLYty{boundtvars,
                             constraints,
                             body =
                             toBodyTy
                               as
                               T.FUNMty([first as T.FUNMty _], bodyTy)} =>
                    let
                      val (ty22, instConstraints, tpexp) = TCU.freshToplevelInst(ty2,tpexp)
                      val _ = addConstraints instConstraints
                    in
                      (case ty22 of
                         T.FUNMty([fromFirst], fromBodyTy) =>
                         let
                           val _ = U.unify[(fromFirst, first)]
                               handle
                               U.Unify =>
                               (E.enqueueError
                                  "Typeinf 083"
                                  (loc, E.TypeAnnotationNotAgree
                                          ("083",{ty=ty2,annotatedTy=ty1}));
                                raise Fail
                               )
                           val firstVar = TCU.newTCVarInfo loc first
                           val firstExp = TC.TPVAR firstVar
                           val bodyExp =
                               TC.TPAPPM{funExp=tpexp,
                                         funTy=ty22,
                                         argExpList=[firstExp],
                                         loc=loc}
                           val {tpexp= newBodyExp, constraints = newConstraints} =
                               TIU.coerceTy(bodyExp,fromBodyTy,bodyTy,loc)
                               handle
                               TIU.CoerceTy =>
                               (E.enqueueError
                                  "Typeinf 084"
                                  (loc, E.TypeAnnotationNotAgree
                                          ("084",{ty=ty2,annotatedTy=ty1}));
                                raise Fail
                               )
                           val _ = addConstraints newConstraints
                           val newTpexp =
                               TC.TPFNM {argVarList=[firstVar],
                                         bodyExp=newBodyExp,
                                         bodyTy=bodyTy,
                                         loc=loc}
                           val tpexp =
                               TC.TPPOLY{btvEnv=boundtvars,
                                         expTyWithoutTAbs=toBodyTy,
                                         exp=newTpexp,
                                         loc=loc}
                           val newId = VarID.generate()
                           val newVar = {id=newId, path=longsymbol, ty=ty1, opaque=false}
                           val newExternalVar = {path=externalLongsymbol, ty=ty1}
                           val newDecl = TC.TPVAL([(newVar, tpexp)], loc)
                           val exportDecl = 
                               TC.TPEXPORTVAR {path = externalLongsymbol, id = newId, ty = ty1, opaque=false}
                         in
                           (TIC.emptyContext, [newDecl,exportDecl]
                           )
                         end
                       | _ =>
                         (E.enqueueError
                            "Typeinf 085"
                            (loc, E.TypeAnnotationNotAgree
                                    ("085",{ty=ty2,annotatedTy=ty1}));
                          raise Fail
                         )
                      )
                    end
                  | (* 3. TYFUNM(polyList, body) *)
                    (* 4. TYFUNM([unit], body) *)
                    T.FUNMty(polyTys, bodyTy) =>
                    (case ty2 of
                       T.FUNMty(actualPolyTys,actualBodyTy) =>
                       (let
                          val _ = checkPoly (actualPolyTys, polyTys)
                          val polyVars = map (TCU.newTCVarInfo loc) polyTys
                          val polyExps = map TC.TPVAR polyVars
                          val bodyExp =
                              TC.TPAPPM{funExp=tpexp,
                                        funTy=T.FUNMty(actualPolyTys,actualBodyTy),
                                        argExpList=polyExps,
                                        loc=loc}
                          val {tpexp=newBodyExp, constraints=newConstraints} =
                              TIU.coerceTy (bodyExp, actualBodyTy, bodyTy, loc)
                              handle
                              TIU.CoerceTy =>
                              (E.enqueueError
                                 "Typeinf 086"
                                 (loc, E.TypeAnnotationNotAgree
                                         ("086",{ty=ty2,annotatedTy=ty1}));
                               raise Fail
                              )
                          val _ = addConstraints newConstraints
                          val newTpexp =
                              TC.TPFNM {argVarList=polyVars,
                                        bodyExp=newBodyExp,
                                        bodyTy=bodyTy,
                                        loc=loc}
                          val newId = VarID.generate()
                          val newVar = {id=newId, path=longsymbol, ty=ty1,  opaque=false}
                          val newExternalVar = {path=externalLongsymbol, ty=ty1}
(*
                          val newDecl = TC.TPVAL([(newVar, tpexp)], loc)
*)
                          val newDecl = TC.TPVAL([(newVar, newTpexp)], loc)
                          val exportDecl = 
                              TC.TPEXPORTVAR {path=externalLongsymbol, id = newId, ty=ty1, opaque=false}
                        in
                          (TIC.emptyContext, [newDecl, exportDecl]
                          )
                        end
                       )
                     | _ =>
                       (E.enqueueError
                          "Typeinf 087"
                          (loc, E.TypeAnnotationNotAgree
                                  ("087",{ty=ty2,annotatedTy=ty1}));
                        raise Fail
                       )
                    )
                  | _ =>
                    (P.print "illeagal functor annotation type";
                     P.print "ty1\n";
                     P.printTy ty1;
                     P.print "\n";
                     raise bug "illeagal functor annotation type"
                    )
            in
              (context, decls)
            end
        end
      | IC.ICEXPORTTYPECHECKEDVAR ({longsymbol, id, version}) =>
        let
          val externalLongsymbol = Symbol.setVersion (longsymbol, version)
          val (ty, tpdecl) =
              case VarMap.find(#varEnv context, {longsymbol=longsymbol, id=id}) of
                SOME (idstatus as TC.VARID {ty,...}) =>
                (ty, TC.TPEXPORTVAR {ty=ty, id=id, path=externalLongsymbol, opaque=false})
              | SOME (idstatus as TC.RECFUNID({ty,...},arity)) =>
                (ty, TC.TPEXPORTRECFUNVAR{var={ty=ty, id=id, path=externalLongsymbol, opaque=false}, 
                                          arity=arity}
                )
              | NONE => 
                if E.isError() then raise Fail
                else raise bug "var not found (5)"
        in
          (TIC.emptyContext, [tpdecl])
        end
      | IC.ICEXPORTVAR {exInfo= exInfo as {used, longsymbol, ty=ity, version}, id} =>
        let
          val loc = Symbol.longsymbolToLastLoc longsymbol
          val externalLongsymbol = exInfoToLongsymbol exInfo
          val ty1 = ITy.evalIty context ity handle e => (P.print "ity35\n"; raise e)
          val (ty2, tpdecl) =
              case VarMap.find(#varEnv context, {longsymbol=longsymbol, id=id}) of
                SOME (idstatus as TC.VARID {ty,...}) =>
                (ty, TC.TPEXPORTVAR {ty=ty, id=id, path=externalLongsymbol, opaque=false})
              | SOME (idstatus as TC.RECFUNID({ty,...},arity)) =>
                (ty, TC.TPEXPORTRECFUNVAR{var={ty=ty, id=id, path=externalLongsymbol, opaque=false}, 
                                          arity=arity}
                )
              | NONE => 
                if E.isError() then raise Fail
                else raise bug "var not found (6)"
        in
          if U.eqTy BoundTypeVarID.Map.empty (ty1, ty2) then
            (TIC.emptyContext, [tpdecl])
          else
            let
              val (ty11, constraints11) = TB.freshRigidInstTy ty1
              val _ = addConstraints constraints11
            in
              if TB.monoTy ty2 then
                (U.unify [(ty11, ty2)];
                 (TIC.emptyContext, [tpdecl])
                )
                handle U.Unify =>
                       (E.enqueueError
                          "Typeinf 088"
                          (loc, E.TypeAnnotationNotAgree
                                  ("088",{ty=ty2,annotatedTy=ty11}));
                        (TIC.emptyContext,nil)
                       )

              else
                let
                  val tpexp = TC.TPVAR {path=longsymbol,id=id,ty=ty2, opaque=false}
                  val {tpexp=tpexp, constraints=newConstraints} = TIU.coerceTy(tpexp,ty2,ty1,loc)
                      handle
                      TIU.CoerceTy =>
                      (E.enqueueError
                         "Typeinf 089"
                         (loc, E.TypeAnnotationNotAgree
                                 ("089",{ty=ty2,annotatedTy=ty1}));
                       raise Fail
                      )
                  val _ = addConstraints newConstraints
                  val newId = VarID.generate()
                  val newVar = {path=longsymbol,id=newId,ty=ty1, opaque=false}
                  val newDecl = TC.TPVAL([(newVar, tpexp)], loc)
                  val newTpdecl =
                      case tpdecl of
                        TC.TPEXPORTVAR {path,opaque,...} =>
                        TC.TPEXPORTVAR {path=path, id=newId, ty=ty1, opaque=opaque}
                      | TC.TPEXPORTRECFUNVAR {var={path,opaque,...}, arity} => 
                        TC.TPEXPORTRECFUNVAR {var={path=path, id=newId, ty=ty1, opaque=opaque},
                                              arity=arity}
                      | _ => raise bug "impossible"
                        
                in
                  (TIC.emptyContext, [newDecl, newTpdecl]
                  )
                end
                handle TIU.CoerceTy =>
                       (E.enqueueError
                          "Typeinf 090"
                          (loc, E.TypeAnnotationNotAgree
                                  ("090",{ty=ty2,annotatedTy=ty1}));
                        (TIC.emptyContext,nil)
                       )
            end
        end
      | IC.ICEXPORTEXN {exInfo= exInfo as {used, longsymbol, ty=ity, version}, id} =>
        let
          val externalLongsymbol = exInfoToLongsymbol exInfo
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity36\n"; raise e)
        in
          (TIC.emptyContext,
           [TC.TPEXPORTEXN {path=externalLongsymbol, id=id, ty=ty}]
           )
        end
      | IC.ICEXTERNVAR {used, longsymbol, ty=ity, version} =>
        let
          val externalLongsymbol = Symbol.setVersion(longsymbol, version)
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity37\n"; 
                           P.print "path:\n";
                           (* P.printPath path; *)
                           raise e)
        in
          (TIC.emptyContext,
           [TC.TPEXTERNVAR {path=externalLongsymbol, ty=ty}]
           )
        end
      | IC.ICEXTERNEXN {used, longsymbol, ty=ity, version} =>
        let
          val externalLongsymbol = Symbol.setVersion(longsymbol, version)
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity38\n"; raise e)
        in
          (TIC.emptyContext,
           [TC.TPEXTERNEXN {path=externalLongsymbol, ty=ty}]
           )
        end
      | IC.ICBUILTINEXN {longsymbol, ty=ity} =>
        let
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity38\n"; raise e)
        in
          (TIC.emptyContext,
           [TC.TPBUILTINEXN {path=longsymbol, ty=ty}]
           )
        end
      | IC.ICTYCASTDECL (tycastList, icdeclList, loc) =>
        let
          val {varEnv, tvarEnv, oprimEnv} = context
          val typIdMap =
              foldl
              (fn ({from, to}, typIdMap) =>
                  let
                    val fromId = IC.tfunId from
                    val to = ITy.evalTfun context to
                             handle e => (P.print "ity19\n"; raise e)
                  in
                    TypID.Map.insert(typIdMap, fromId, to)
                  end
              )
              TypID.Map.empty
              tycastList
          val (context, tpdeclList) =
              typeinfDeclList lambdaDepth context icdeclList
          val context = tyConSubstContext typIdMap context
        in
          (context, tpdeclList)
        end
      | IC.ICOVERLOADDEF {boundtvars,id,longsymbol,overloadCase,loc} =>
        let
          val lambdaDepth = incDepth ()
          val (context, addedUtvars) =
              evalScopedTvars lambdaDepth context boundtvars loc

          fun substFTvar (subst as (ftvid, ty')) ty =
              case ty of
                T.SINGLETONty singletonTy =>
                raise bug "ICOVERLOADDEF: substFTvar: SINGLETONty"
              | T.BACKENDty _ =>
                raise bug "ICOVERLOADDEF: substFTvar: BACKENDty"
              | T.ERRORty => ty
              | T.DUMMYty _ => ty
              | T.TYVARty (ref (T.TVAR {id,...})) =>
                if FreeTypeVarID.eq (ftvid, id) then ty' else ty
              | T.TYVARty (ref (T.SUBSTITUTED ty)) => substFTvar subst ty
              | T.BOUNDVARty n => ty
              | T.FUNMty (tyList, ty) =>
                T.FUNMty (map (substFTvar subst) tyList, substFTvar subst ty)
              | T.RECORDty tySenvMap =>
                T.RECORDty (RecordLabel.Map.map (substFTvar subst) tySenvMap)
              | T.CONSTRUCTty {tyCon,args} =>
                T.CONSTRUCTty {tyCon=tyCon, args = map (substFTvar subst) args}
              | T.POLYty {boundtvars, constraints, body} =>
                T.POLYty {boundtvars=boundtvars, 
                          constraints = List.map (fn c =>
                                                     case c of T.JOIN {res, args = (arg1, arg2), loc} =>
                                                       T.JOIN
                                                           {res = substFTvar subst res,
                                                            args = (substFTvar subst arg1,
                                                                    substFTvar subst arg2), loc=loc})
                                                 constraints,
                          body = substFTvar subst body}

          fun typeinfOverloadMatch (tvId, expTy) {instTy, instance} =
              let
                val instTypId =
                    case TB.derefTy instTy of
                      T.CONSTRUCTty {tyCon={id,...}, ...} => id
                    | _ => raise bug "FIXME: user error: invalid instTy"
                val expectTy = substFTvar (tvId, instTy) expTy
                val (actualTy, keyList, branch) =
                    case instance of
                      IC.INST_OVERLOAD c => typeinfOverloadCase c
                    | IC.INST_EXVAR {exInfo= exInfo as {used, longsymbol, ty, version}, loc} =>
                      let
                        val ty = ITy.evalIty context ty
                            handle e => (P.print "ity39\n"; raise e)
                        val externalLongsymbol = exInfoToLongsymbol exInfo
                        val exVarInfo = {path = externalLongsymbol, ty = ty}
                        val (monoTy, instTyList, exvarConstraints) = TIU.freshTopLevelInstTy ty
                        val _ = addConstraints exvarConstraints
                      in
                        (monoTy, nil,
                         T.OVERLOAD_EXVAR {exVarInfo = exVarInfo,
                                           instTyList = instTyList})
                      end
                    | IC.INST_PRIM ({primitive, ty}, loc) =>
                      let
                        val ty = ITy.evalIty context ty
                            handle e => (P.print "ity40\n"; raise e)
                        val primInfo = {primitive = primitive, ty = ty}
                        val (monoTy, instTyList, primConstraints) = TIU.freshTopLevelInstTy ty
                        val _ = addConstraints primConstraints
                      in
                        (monoTy, nil,
                         T.OVERLOAD_PRIM {primInfo = primInfo,
                                          instTyList = instTyList})
                      end
                val _ =
                    U.unify [(expectTy, actualTy)]
                    handle U.Unify =>
                           E.enqueueError "Typeinf 091"
                             (loc,
                              E.TypeAnnotationNotAgree
                                ("091",{ty=actualTy,annotatedTy=expectTy}))
              in
                (keyList, (instTypId, branch))
              end

          and typeinfOverloadMatches ty map nil = (nil, map)
            | typeinfOverloadMatches ty map (match::matches) =
              let
                val (keys1, (tyid, branch)) = typeinfOverloadMatch ty match
                val map =
                    if TypID.Map.inDomain (map, tyid)
                    then
                      (
                      raise bug "FIXME: user error: doubled tycon"
                      )
                    else TypID.Map.insert (map, tyid, branch)
                val (keys2, map) = typeinfOverloadMatches ty map matches
              in
                (keys1 @ keys2, map)
              end

          and typeinfOverloadCase ({tvar,expTy,matches,loc}:IC.overloadCase) =
              let
                val (tvStateRef, tvId) =
                    case TvarMap.find (addedUtvars, tvar) of
                      SOME (r as ref (T.TVAR {kind = T.KIND {tvarKind=T.UNIV,...}, id,...})) =>
                      (r, id)
                    | _ => raise bug "typeinfOverloadCase"
                val expTy = ITy.evalIty context expTy
                    handle e => (P.print "ity41\n"; raise e)
                val matches =
                    map (fn {instTy, instance} =>
                            {instTy = ITy.evalIty context instTy
                                      handle e => (P.print "ity42\n"; raise e),
                             instance = instance})
                        matches
                val instTys = map #instTy matches
                val (keyList, match) =
                    typeinfOverloadMatches (tvId,expTy) TypID.Map.empty matches
              in
                (expTy, (tvStateRef, instTys) :: keyList,
                 T.OVERLOAD_CASE (T.TYVARty tvStateRef, match))
              end

          local
            fun getFTVid (T.TYVARty (ref (T.TVAR {id,...}))) = id
              | getFTVid _ = raise bug "getFTVid"
            datatype key = TV of FreeTypeVarID.id | TYCON of TypID.id

            fun substKey (tid, r) key =
                case key of
                  TV id => if FreeTypeVarID.eq (tid, id) then r else key
                | TYCON _ => key

            fun fixKey keys =
                map (fn TV _ => NONE | TYCON id => SOME id) keys

            fun insertCases key dst match =
                case match of
                  T.OVERLOAD_EXVAR longsymbol =>
                  OPrimInstMap.insert (dst, fixKey key, match)
                | T.OVERLOAD_PRIM longsymbol =>
                  OPrimInstMap.insert (dst, fixKey key, match)
                | T.OVERLOAD_CASE (ty, matches) =>
                  let
                    val tvid = getFTVid ty
                  in
                    TypID.Map.foldli
                      (fn (tyid, match, z) =>
                          insertCases (map (substKey (tvid, TYCON tyid)) key)
                                      z match)
                      dst
                      matches
                  end
          in
          fun matchToInstMap keyTyList match =
              insertCases (map (fn ty => TV (getFTVid ty)) keyTyList)
                         OPrimInstMap.empty
                         match
          end (* local *)

          val (ty, keyList, match) = typeinfOverloadCase overloadCase
handle exn =>
let
  val _ = P.print "typeinfOverloadCase bug\n"
  val _ = P.print "icdecl\n"
  val _ = P.printIcdecl icdecl
  val _ = P.print "\n"
in
  raise exn
end
          val keyTyList = map (fn (r,_) => T.TYVARty r) keyList
          val instMap = matchToInstMap keyTyList match
          val selectors = [{oprimId = id,
                            longsymbol = longsymbol,
                            keyTyList = keyTyList,
                            match = match,
                            instMap = instMap}]
          val _ =
              app (fn (r as ref (T.TVAR {lambdaDepth, id, kind = T.KIND kind, utvarOpt}), instTys) =>
                      r := T.TVAR
                             {lambdaDepth = lambdaDepth,
                              id = id,
                              kind = T.KIND
                                       {tvarKind = T.OPRIMkind {instances = instTys,
                                                                operators = selectors},
                                        eqKind = #eqKind kind,
                                        dynKind = #dynKind kind,
                                        reifyKind = #reifyKind kind,
                                        subkind = #subkind kind},
                              utvarOpt = utvarOpt}
                    | _ => raise bug "ICOVERLOADDEF")
                  keyList
          val {boundEnv, boundConstraints, ...} = generalizer (ty, lambdaDepth)
          val oprimTy =
              if BoundTypeVarID.Map.isEmpty boundEnv
              then ty else T.POLYty {boundtvars = boundEnv, constraints = boundConstraints, body = ty}
          val oprimInfo =
              {ty = oprimTy, path = longsymbol, id = id}
        in
          (TIC.bindOPrim (TIC.emptyContext, {longsymbol=longsymbol, id=id}, oprimInfo), nil)
        end
    end (* typeinfDec *)
    handle Fail => (TIC.emptyContext,nil)

  fun typeinfDecls (context, icdecls) =
      let
       (* 2012-7-11 ohori: to fix bug 195_dummtType.sml *)
        val startDummyTyId = ! TIU.dummyTyId
        val _ = E.initializeTypeinfError ()
        val _ = T.kindedTyvarList := nil
        val _ = constraints := nil
(*
        val ({varEnv,...}, tpdecls) =
            typeinfDeclList T.toplevelDepth TIC.emptyContext icdecls
            handle Fail => (TIC.emptyContext,nil)
*)
        val (context as {varEnv,...}, tpdecls) =
            typeinfDeclList T.toplevelDepth context icdecls
            handle Fail => (TIC.emptyContext,nil)
        val (context, tpdecls) =
            if E.isError() then
              (context, tpdecls)
            else
              let
                (* 2016-06-01 sasaki: ここから自然結合制約の解消のための追加部分 *)
                val _ = constraints := resolveJoinConstraints (!constraints)

                (* 2016-12-02 resolveJoinConstrantsの前の移動 *)
                val _ = List.app TIU.instantiateTv (!T.kindedTyvarList)

                fun isDummy ty =
                    let
                      exception DUMMY
                      fun visit ty =
                          case TB.derefTy ty of
                            T.SINGLETONty _ => ()
                          | T.BACKENDty _ => ()
                          | T.ERRORty => ()
                            (* 2012-7-11 ohori: to fix bug 195_dummtType.sml *)
                          | T.DUMMYty (id, _) => if id >= startDummyTyId then raise DUMMY else ()
                          | T.TYVARty _ => ()
                          | T.BOUNDVARty _ => ()
                          | T.FUNMty (tyList, ty) => (app visit tyList; visit ty)
                          | T.RECORDty tySEnvMap => RecordLabel.Map.app visit tySEnvMap
                          | T.CONSTRUCTty {tyCon, args} => app visit args
                          | T.POLYty {body,...} => visit body
                    in
                      (visit ty; false)
                      handle DUMMY => true
                    end

                val _ = app (fn (T.JOIN {res, args=(ty1, ty2), loc}) =>
                                if isDummy res orelse isDummy ty1 orelse isDummy ty2
                                then 
                                  if E.isError() then ()
                                  else
                                    E.enqueueError 
                                      "ResolveJoin 007"
                                      (loc, E.JoinWithDummy ("007", res, ty1, ty2))
                                else ())
                            (!constraints)

                val _ = constraints := nil


(*
                val varEnv = 
                    VarMap.map 
                        (fn var => case var of
                                     TC.RECFUNID (vi, i) =>
                                     TC.RECFUNID (insertConstraintsToVarInfo vi (!constraints), i)
                                   | TC.VARID vi =>
                                     TC.VARID (insertConstraintsToVarInfo vi (!constraints)))
                                 varEnv
                val tpdecls =
                    List.map
                        (fn tpdecl => insertConstraintsToTpdecl tpdecl (!constraints))
                        tpdecls
*)
                (* TODO: tpdeclのための処理を追加 *)
                (* 2016-06-01 sasaki: 追加部分ここまで *)

                val _ = T.kindedTyvarList := nil

                val _ =
                    if E.isError() then ()
                    else
                      let
                        val dummyTyPaths =
                            VarMap.foldli
                              (fn ({id, longsymbol}, TC.VARID {ty,...}, paths) =>
                                  if isDummy ty then longsymbol::paths
                                  else paths
                                | ({id, longsymbol},TC.RECFUNID ({ty,...},_),paths) =>
                                  if isDummy ty then longsymbol::paths
                                  else paths
                              )
                              nil
                              varEnv
                      in
                        case dummyTyPaths of
                          nil => ()
                        | first::rest =>
                          let
                            val loc =
                                foldl
                                  (fn (longsymbol, loc) =>
                                      Loc.mergeLocs(Symbol.longsymbolToLoc longsymbol, loc))
                                  (Symbol.longsymbolToLoc first)
                                  rest
                          in
                            E.enqueueWarning
                              (loc, E.ValueRestriction("065",{dummyTyPaths=dummyTyPaths}))
                          end
                      end

(* FIXME: do we need the following?
                val _ = List.app (fn (ty as T.TYVARty(ref(T.TVAR _)), loc) =>
                                     E.enqueueError "Typeinf 077" (loc, E.FFIInvalidTyvar ty)
                                   | _ => ())
                                 (!ffiApplyTyvars)
*)
              in
                (context, tpdecls)
              end
        val errors = E.getErrors ()
      in
        case errors of
          [] => (context, tpdecls, E.getWarnings())
        | errors =>
          let
            val errorsAndWornings = E.getErrorsAndWarnings ()
          in
            raise UE.UserErrors (errorsAndWornings)
          end
      end

  fun typeinf icdecls = 
      let
        val ({varEnv,...}, icdecls, wrarnings) = typeinfDecls (TIC.emptyContext, icdecls)
      in
        (varEnv, icdecls, wrarnings)
      end

  fun typeinfBody (context, icdecls) = 
      let
        val ({varEnv,...}, icdecls, wrarnings) = typeinfDecls (context, icdecls)
      in
        (varEnv, icdecls, wrarnings)
      end

end
end
