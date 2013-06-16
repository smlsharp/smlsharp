(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure InferTypes =
struct
local
  structure T = Types
  structure IC = IDCalc
  structure NEU = NameEvalUtils
  structure ITy = EvalIty
  structure BT = BuiltinTypes
  structure A = Absyn
  structure TC = TypedCalc
  structure TCU = TypedCalcUtils
  structure E = TypeInferenceError
  structure TIC = TypeInferenceContext
  structure TIU = TypeInferenceUtils
  structure CT = ConstantTerm
  structure TU = TypesUtils
  structure UE = UserError
  structure U = Unify
  structure P = Printers

  exception CyclicTvarkindSpec of string
  exception Fail

  val maxDepth = ref 0
  fun incDepth () = (maxDepth := !maxDepth + 1; !maxDepth)
  val ffiApplyTyvars = ref nil : (T.ty * Loc.loc) list ref
  fun bug s = Control.Bug ("InferType: " ^ s)

  val emptyScopedTvars = nil : IC.scopedTvars

  fun mapi f l =
      let
        fun loop (i, nil) = nil
          | loop (i, h::t) = f (i,h) :: loop (i+1, t)
      in
        loop (1, l)
      end

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
                     LabelEnv.insert (tpexpSmap, label, tpexp),
                     LabelEnv.insert (tySmap, label, ty),
                     tpbindsRev
                    )
                  else
                    let
                      val newVarInfo = TCU.newTCVarInfo ty
                    in
                      (
                       LabelEnv.insert
                         (tpexpSmap, label, TC.TPVAR (newVarInfo, loc)),
                       LabelEnv.insert(tySmap, label, ty),
                       (newVarInfo, tpexp) :: tpbindsRev
                      )
                    end
              )
              (LabelEnv.empty, LabelEnv.empty, nil)
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

  fun makeTupleFields l =
      mapi (fn (i,x) => (Int.toString i, x)) l

  fun labelEnvFromList list =
      List.foldl (fn ((key, item), m) => LabelEnv.insert (m, key, item)) LabelEnv.empty list

  fun makeTupleTy nil = BT.unitTy
    | makeTupleTy [ty] = ty
    | makeTupleTy tys = T.RECORDty (labelEnvFromList (makeTupleFields tys))

  fun makeTupleExp (nil, loc) =
      TC.TPCONSTANT {const=A.UNITCONST loc, ty=BT.unitTy, loc=loc}
    | makeTupleExp ([(ty, exp)], loc) = exp
    | makeTupleExp (fields, loc) =
      let
        val (_, recordExp) = 
            makeTPRecord (makeTupleFields fields) loc
      in
        recordExp
      end

  fun LabelEnv_all f env =
      LabelEnv.foldl (fn (x,z) => z andalso f x) true env

  datatype dir = IMPORT of {force: bool} | EXPORT

  fun exportOnly (IMPORT {force}) = force
    | exportOnly EXPORT = true

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
            case TU.derefTy ty of
              T.SINGLETONty (T.INSTCODEty operator) =>
              T.SINGLETONty
                (T.INSTCODEty(oprimSelectorSubst typIdMap operator))
            | T.SINGLETONty (T.INDEXty (string, ty)) =>
              T.SINGLETONty (T.INDEXty (string, tySubst ty))
            | T.SINGLETONty (T.TAGty ty) =>
              T.SINGLETONty (T.TAGty (tySubst ty))
            | T.SINGLETONty (T.SIZEty ty) =>
              T.SINGLETONty (T.SIZEty (tySubst ty))
            | T.ERRORty => ty
            | T.DUMMYty dummyTyID => ty
            | T.TYVARty tvStateRef => ty
            | T.BOUNDVARty boundTypeVarID => ty
            | T.FUNMty (tyList, ty) =>
              T.FUNMty (map tySubst tyList, tySubst ty)
            | T.RECORDty tySenvMap =>
              T.RECORDty (LabelEnv.map tySubst tySenvMap)
            | T.CONSTRUCTty {tyCon:T.tyCon as {path,...},args} =>
              (case TypID.Map.find(typIdMap, #id tyCon) of
                 NONE => T.CONSTRUCTty {tyCon=tyCon,
                                        args= map tySubst args}
               | SOME tyCon =>
                 T.CONSTRUCTty{tyCon=tyCon,args =map tySubst args}
              )
            | T.POLYty {boundtvars, body} =>
              T.POLYty {boundtvars =
                        BoundTypeVarID.Map.map
                          (fn {eqKind, tvarKind} =>
                              {eqKind=eqKind,
                               tvarKind = tvarKindSubst tvarKind})
                          boundtvars,
                        body = tySubst body
                       }
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
            | T.REC tySenvMap =>
              T.REC (LabelEnv.map tySubst tySenvMap)
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
  and oprimSelectorSubst typIdMap {oprimId,path,keyTyList,match,instMap} =
      {oprimId=oprimId,
       path = path,
       keyTyList = map (tyConSubstTy typIdMap) keyTyList,
       match = overloadMatchSubst typIdMap match,
       instMap = OPrimInstMap.map (overloadMatchSubst typIdMap) instMap
      }
  and tyConSubstExp typIdMap tpexp =
      let
        fun tySubst ty = tyConSubstTy typIdMap ty
        fun expSubst tpexp =
            case tpexp of
              TC.TPERROR => tpexp
            | TC.TPCONSTANT {const, ty, loc} => tpexp
            | TC.TPGLOBALSYMBOL {name, kind,ty,loc} => tpexp
            | TC.TPVAR ({id,path,ty}, loc) =>
              TC.TPVAR ({id=id,path=path,ty=tySubst ty}, loc)
            | TC.TPEXVAR ({path,ty}, loc) =>
              TC.TPEXVAR ({path=path, ty=tySubst ty}, loc)
            | TC.TPRECFUNVAR {var={path,id,ty}, arity, loc} =>
              TC.TPRECFUNVAR
                {
                 var={path=path, id=id, ty=tySubst ty},
                 arity=arity,
                 loc=loc
                }
            | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} =>
              TC.TPFNM
                {argVarList =
                 map
                   (fn {id, path, ty} =>
                       {id=id,path=path,ty=tySubst ty}
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
                {fields = LabelEnv.map expSubst fields,
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
            | TC.TPMONOLET {binds, bodyExp, loc} =>
              TC.TPMONOLET
                {binds =
                 map
                   (fn ({id,path,ty},exp) =>
                       ({id=id,path=path,ty=tySubst ty},expSubst exp))
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
            | TC.TPHANDLE {exp, exnVar={path,id,ty}, handler, loc} =>
              TC.TPHANDLE
                {exp = expSubst exp,
                 exnVar = {path=path, id=id, ty=tySubst ty},
                 handler = expSubst exp,
                 loc = loc}
            | TC.TPPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
              TC.TPPOLYFNM
                {btvEnv = BoundTypeVarID.Map.map tvarKindSubst btvEnv,
                 argVarList = map varSubst argVarList,
                 bodyTy = tySubst bodyTy,
                 bodyExp = expSubst bodyExp,
                 loc = loc}
            | TC.TPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
              TC.TPPOLY
                {btvEnv = BoundTypeVarID.Map.map tvarKindSubst btvEnv,
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
            | TC.TPFFIIMPORT {ptrExp, ffiTy, stubTy, loc} =>
              TC.TPFFIIMPORT
                {ptrExp = expSubst ptrExp,
                 ffiTy = ffiTySubst ffiTy,
                 stubTy = tySubst stubTy,
                 loc=loc}
            | TC.TPCAST (tpexp, ty, loc) =>
              TC.TPCAST (expSubst tpexp, tySubst ty, loc)
            | TC.TPSIZEOF (ty, loc) =>
              TC.TPSIZEOF (tySubst ty, loc)
            | TC.TPSQLSERVER {server, schema, resultTy, loc} =>
              TC.TPSQLSERVER
                {server = server,
                 schema = schema,
                 resultTy = tySubst resultTy,
                 loc = loc}
        and tvarKindSubst {eqKind, tvarKind} =
            {eqKind=eqKind,
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
             | T.REC tyMap => T.REC (LabelEnv.map tySubst tyMap)
            }
        and patSubst pat =
            case pat of
              TC.TPPATERROR (ty, loc) =>
              TC.TPPATERROR (tySubst ty, loc)
            | TC.TPPATWILD (ty, loc) =>
              TC.TPPATWILD (tySubst ty, loc)
            | TC.TPPATVAR (var, loc) =>
              TC.TPPATVAR (varSubst var, loc)
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
                {fields = LabelEnv.map patSubst fields,
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
              (BoundTypeVarID.Map.map tvarKindSubst btvEnv,
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
              (BoundTypeVarID.Map.map tvarKindSubst btvEnv,
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
          | TC.TPEXPORTVAR {internalVar, externalVar, loc} =>
            TC.TPEXPORTVAR {internalVar=varSubst internalVar,
                            externalVar=exVarSubst externalVar,
                            loc=loc}
          | TC.TPEXPORTRECFUNVAR {var, arity, loc} =>
            TC.TPEXPORTRECFUNVAR {var=varSubst var, arity=arity, loc=loc}
          | TC.TPEXPORTEXN ({id, path, ty} , loc) =>
            TC.TPEXPORTEXN ({id=id, path=path, ty=tySubst ty} , loc)
          | TC.TPEXTERNVAR ({path, ty}, loc) =>
            TC.TPEXTERNVAR ({path=path, ty=tySubst ty}, loc)
          | TC.TPEXTERNEXN ({path, ty}, loc) =>
            TC.TPEXTERNEXN ({path=path, ty=tySubst ty}, loc)
        and ffiTySubst ffiTy =
            case ffiTy of
              TC.FFIFUNTY (ffiAttribOpt, ffiTyList1, ffiTyList2, loc) =>
              TC.FFIFUNTY
                (ffiAttribOpt,
                 map ffiTySubst ffiTyList1,
                 map ffiTySubst ffiTyList2,
                 loc)
            | TC.FFIRECORDTY (stringFfityList, loc) =>
              TC.FFIRECORDTY
                (map (fn (string, ffiTy) =>
                         (string, ffiTySubst ffiTy)
                     )
                     stringFfityList,
                 loc)
            | TC.FFIBASETY (ty, loc) => TC.FFIBASETY (tySubst ty, loc)

        and varSubst {id, path,ty} =
            {id=id, path=path, ty=tyConSubstTy typIdMap ty}
        and exVarSubst {path,ty} =
            {path=path, ty=tyConSubstTy typIdMap ty}
      in
        expSubst tpexp
      end

  fun tyConSubstVarInfo typIdMap {path, id, ty} =
      {path=path, id=id, ty = tyConSubstTy typIdMap ty}
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

  fun isForceImportAttribute (attribute:A.ffiAttributes option) =
      case attribute of
        SOME {allocMLValue, ...} => allocMLValue
      | NONE => false

  fun isInteroperableArgTy dir ty =
      case TU.derefTy ty of
        T.TYVARty (ref (T.TVAR ({tvarKind,...}))) =>
        (
          case tvarKind of
            T.UNIV => exportOnly dir
          | T.REC _ => exportOnly dir
          | T.OCONSTkind _ => false
          | T.OPRIMkind _ => false
        )
      | _ => isInteroperableTy dir ty

  and isInteroperableBuiltinTy dir (ty, args) =
      case ty of
        BuiltinTypeNames.INTty => true
      | BuiltinTypeNames.INTINFty => exportOnly dir
      | BuiltinTypeNames.WORDty => true
      | BuiltinTypeNames.WORD8ty => true
      | BuiltinTypeNames.CHARty => true
      | BuiltinTypeNames.STRINGty => exportOnly dir
      | BuiltinTypeNames.REALty => true
      | BuiltinTypeNames.REAL32ty => true
      | BuiltinTypeNames.UNITty => false
      | BuiltinTypeNames.PTRty =>
        List.all (isInteroperableArgTy dir) args orelse
        (
          case args of
            [ty] => (case TU.derefTy ty of
                       T.CONSTRUCTty {tyCon, args=[]} =>
                       TypID.eq (#id tyCon, #id BT.unitTyCon)
                     | T.TYVARty (ref (T.TVAR ({tvarKind=T.UNIV,...}))) =>
                       true
                     | _ => false)
          | _ => raise bug "non singleton arg in PTRty"
        )
      | BuiltinTypeNames.ARRAYty =>
        exportOnly dir andalso List.all (isInteroperableArgTy dir) args
      | BuiltinTypeNames.VECTORty =>
        exportOnly dir andalso List.all (isInteroperableArgTy dir) args
      | BuiltinTypeNames.EXNty => false
      | BuiltinTypeNames.BOXEDty => false
      (* FIXME : check the following *)
      | BuiltinTypeNames.EXNTAGty => false
      | BuiltinTypeNames.REFty => false
      | BuiltinTypeNames.BOOLty => false
      | BuiltinTypeNames.LISTty => false
      | BuiltinTypeNames.OPTIONty => false
      | BuiltinTypeNames.ORDERty => false
      | BuiltinTypeNames.SERVERty  => false
      | BuiltinTypeNames.DBIty  => false
      | BuiltinTypeNames.VALUEty  => false
      | BuiltinTypeNames.CONNty  => false
      | BuiltinTypeNames.DBty  => false
      | BuiltinTypeNames.TABLEty  => false
      | BuiltinTypeNames.ROWty  => false
      | BuiltinTypeNames.RESULTty  => false
      | BuiltinTypeNames.RELty  => false
      | BuiltinTypeNames.QUERYty  => false
      | BuiltinTypeNames.COMMANDty  => false

  and isInteroperableTycon dir ({id, dtyKind, runtimeTy, ...}:T.tyCon, args) =
      case dtyKind of
        T.BUILTIN ty => isInteroperableBuiltinTy dir (ty, args)
      | T.OPAQUE {opaqueRep = T.TYCON tyCon, revealKey} =>
        isInteroperableTycon dir (tyCon, args)
      | T.OPAQUE {opaqueRep = T.TFUNDEF _, revealKey} => false
      | T.DTY =>
        isInteroperableBuiltinTy dir (runtimeTy, args)
        orelse (TypID.eq (id, #id BT.refTyCon)
                andalso List.all (isInteroperableArgTy dir) args)

  and isInteroperableTy dir ty =
      case TU.derefTy ty of
        T.CONSTRUCTty {tyCon, args} =>
        isInteroperableTycon dir (tyCon, args)
      | T.RECORDty fields =>
        exportOnly dir andalso LabelEnv_all (isInteroperableArgTy dir) fields
      | _ => false

  fun evalForceImportFFIty (context:TIC.context) ffity =
      case ffity of
        IC.FFIBASETY (ty, loc) =>
        (ITy.evalIty context ty
         handle e => (P.print "ity1\n"; raise e))
      | IC.FFIFUNTY (_, _, _, loc) =>
        (E.enqueueError "Typeinf 001" (loc, E.ForceImportForeignFunction("001", ffity));
         T.ERRORty)
      | IC.FFIRECORDTY (fields, loc) =>
        T.RECORDty
          (labelEnvFromList
             (map (fn (k,v) => (k, evalForceImportFFIty context v)) fields))

  fun evalFFIFunTyArgs (context:TIC.context) dir ffitys =
      case ffitys of
        [IC.FFIBASETY (ty, loc)] =>
        (
          (* "unit" means either no argument or no return value. *)
          case ty of
            IC.TYCONSTRUCT
              {tfun=IC.TFUN_VAR(ref(IC.TFUN_DTY{id,...})),
               args=[]} =>
            if TypID.eq (id, #id BT.unitTyCon)
            then nil
            else map (evalFFIty context dir) ffitys
          | _ => map (evalFFIty context dir) ffitys
        )
      | _ => map (evalFFIty context dir) ffitys

  and evalFFIty (context:TIC.context) dir ffity =
      case ffity of
        IC.FFIFUNTY (attributes, argTys, retTys, loc) =>
        let
          val forceImport = isForceImportAttribute attributes
          val (argDir, retDir) =
              case dir of
                IMPORT {force} =>
                (EXPORT, IMPORT {force = force orelse forceImport})
              | EXPORT =>
                (IMPORT {force = forceImport}, EXPORT)
          val argTys = evalFFIFunTyArgs context argDir argTys
          val retTys = evalFFIFunTyArgs context retDir retTys
          val retTys =
              case retTys of
                nil => [TC.FFIBASETY (BT.unitTy, loc)]
              | [ty] => [ty]
              | _ =>
                (E.enqueueError "Typeinf 002" (loc, E.NonInteroperableType ("002",ffity));
                 retTys)
        in
          TC.FFIFUNTY (attributes, argTys, retTys, loc)
        end
      | IC.FFIRECORDTY (fields, loc) =>
        (
          case dir of
            EXPORT =>
            TC.FFIRECORDTY (map (fn (k,v) => (k, evalFFIty context dir v))
                                fields, loc)
          | IMPORT {force=true} =>
            TC.FFIBASETY (evalForceImportFFIty context ffity, loc)
          | IMPORT {force=false} =>
            (E.enqueueError "Typeinf 003" (loc, E.NonInteroperableType ("002",ffity));
             TC.FFIBASETY (T.ERRORty, loc))
        )
      | IC.FFIBASETY (ty, loc) =>
        let
          val ty = ITy.evalIty context ty
                   handle e => (P.print "ity2\n";raise e)
        in
          if isInteroperableTy dir ty
          then TC.FFIBASETY (ty, loc)
          else (E.enqueueError "Typeinf 004" (loc, E.NonInteroperableType ("003",ffity));
                TC.FFIBASETY (T.ERRORty, loc))
        end

  fun evalForeignFunTy (context:TIC.context) ffity =
      let
        val newFFIty = evalFFIty context (IMPORT {force=false}) ffity
      in
        case newFFIty of
          TC.FFIFUNTY _ => ()
        | TC.FFIRECORDTY (_, loc) =>
          E.enqueueError "Typeinf 005" (loc, E.NonInteroperableType ("004",ffity))
        | TC.FFIBASETY (_, loc) =>
          E.enqueueError "Typeinf 006" (loc, E.NonInteroperableType ("005",ffity));
        newFFIty
      end

  fun ffiStubTy ffity =
      case ffity of
        TC.FFIBASETY (ty, loc) => ty
      | TC.FFIFUNTY (attributes, argTys, retTys, loc) =>
        T.FUNMty ([makeTupleTy (map ffiStubTy argTys)],
                  makeTupleTy (map ffiStubTy retTys))
      | TC.FFIRECORDTY (fields, loc) =>
        T.RECORDty (labelEnvFromList (map (fn (k,v) => (k, ffiStubTy v)) fields))

  fun isSQLBuiltinTy bty =
      case bty of
        BuiltinTypeNames.INTty => true
      | BuiltinTypeNames.INTINFty => false
      | BuiltinTypeNames.WORDty => true
      | BuiltinTypeNames.WORD8ty => false
      | BuiltinTypeNames.CHARty => true
      | BuiltinTypeNames.STRINGty => true
      | BuiltinTypeNames.REALty => true
      | BuiltinTypeNames.REAL32ty => false
      | BuiltinTypeNames.UNITty => false
      | BuiltinTypeNames.PTRty => false
      | BuiltinTypeNames.ARRAYty => false
      | BuiltinTypeNames.VECTORty => false
      | BuiltinTypeNames.EXNty => false
      | BuiltinTypeNames.BOXEDty => false
      | BuiltinTypeNames.EXNTAGty => false
      | BuiltinTypeNames.REFty => false
      | BuiltinTypeNames.BOOLty => false
      | BuiltinTypeNames.LISTty => false
      | BuiltinTypeNames.OPTIONty => false
      | BuiltinTypeNames.ORDERty => false
      | BuiltinTypeNames.SERVERty => false
      | BuiltinTypeNames.DBIty => false
      | BuiltinTypeNames.VALUEty => false
      | BuiltinTypeNames.CONNty  => false
      | BuiltinTypeNames.DBty  => false
      | BuiltinTypeNames.TABLEty  => false
      | BuiltinTypeNames.ROWty  => false
      | BuiltinTypeNames.RESULTty  => false
      | BuiltinTypeNames.RELty  => false
      | BuiltinTypeNames.QUERYty  => false
      | BuiltinTypeNames.COMMANDty  => false

  fun isCompatibleWithSQL ty =
      case TU.derefTy ty of
        T.CONSTRUCTty {tyCon={dtyKind=T.BUILTIN bty,...}, args=[]} =>
        isSQLBuiltinTy bty
      | T.CONSTRUCTty {tyCon={dtyKind=T.DTY,id,...}, args=[argTy]} =>
        TypID.eq (id, #id BT.optionTyCon)
        andalso
        (case TU.derefTy argTy of
           T.CONSTRUCTty {tyCon={dtyKind=T.BUILTIN bty,...}, args=[]} =>
           isSQLBuiltinTy bty
         | T.CONSTRUCTty {tyCon={dtyKind=T.DTY,id,...}, args=[]} =>
           TypID.eq (id, #id BT.boolTyCon)
         | _ => false)
      | _ => false

  fun evalTvarKind (context:TIC.context) tvarkind =
    case tvarkind of
      IC.UNIV => T.UNIV
    | IC.REC fields =>
      T.REC
        (LabelEnv.map
           (ITy.evalIty context handle e => (P.print "ity3\n"; raise e))
           fields)
      handle e => raise e

  fun evalScopedTvars lambdaDepth (context:TIC.context) kindedTvarList loc =
    let
      fun occurresTvarInTvarkind (tvstateRef, T.UNIV) = false
        | occurresTvarInTvarkind (tvstateRef, T.OCONSTkind tyList) =
          U.occurresTyList tvstateRef tyList
        | occurresTvarInTvarkind (tvstateRef, T.OPRIMkind {instances,...}) =
          U.occurresTyList tvstateRef instances
        | occurresTvarInTvarkind (tvstateRef, T.REC fields) =
          U.occurres tvstateRef (T.RECORDty fields)
      fun setTvarkind
            (
             tvstateRef as (ref (T.TVAR{lambdaDepth,id,eqKind,utvarOpt,...})),
             tvarKind
            )
        =
        if occurresTvarInTvarkind (tvstateRef, tvarKind) then
          raise
            CyclicTvarkindSpec
              ((case eqKind of A.EQ => "''" | A.NONEQ  => "'") ^
               (case utvarOpt of SOME {name,...} => name | NONE => ""))
        else
          tvstateRef := T.TVAR{lambdaDepth = lambdaDepth,
                               id = id,
                               tvarKind = tvarKind,
                               eqKind = eqKind,
                               utvarOpt = utvarOpt
                              }
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
            (fn (newTvstateRef, tvarkind) =>
                (setTvarkind (newTvstateRef, tvarkind); newTvstateRef))
            addedUtvars
    in
      (newContext, addedUtvars)
    end
      handle CyclicTvarkindSpec string =>
             (
              E.enqueueError "Typeinf 007"
                (
                 loc,
                 E.CyclicTvarkindSpec ("006",string)
                );
              (context, TvarMap.empty)
             )

  fun typeinfConst const =
    let
      val (ty, _) = TIU.freshTopLevelInstTy (CT.constTy const)
    in
      (ty, const)
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
        IC.ICPATERROR loc => VarSet.empty
      | IC.ICPATWILD loc => VarSet.empty
      | IC.ICPATVAR (varInfo, loc) => VarSet.singleton varInfo
      | IC.ICPATCON (conInfo, loc) => VarSet.empty
      | IC.ICPATEXN (exnInfo, loc) => VarSet.empty
      | IC.ICPATEXEXN ({path, ty}, loc) => VarSet.empty
      | IC.ICPATCONSTANT (constant, loc) => VarSet.empty
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
            val newVarExps = map (fn var => IC.ICVAR(var, loc)) newVars
            val newVarPats = map (fn var => IC.ICPATVAR(var, loc)) newVars
            val argRecord = IC.ICRECORD (Utils.listToTuple newVarExps, loc)
            val funRules =
              map
              (fn {args, body} =>
               {args=[IC.ICPATRECORD{flex=false,
                               fields=Utils.listToTuple args,
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
        [(IC.ICPATVAR (funVarInfo,loc), funBody)]
      end
    | transFunDecl _ _ _ = raise bug "illegal fun decl "


 (* type generalization *)
  fun generalizer (ty, lambdaDepth) =
    if E.isError()
      then {boundEnv = BoundTypeVarID.Map.empty, removedTyIds = OTSet.empty}
    else
      let
        val newTy = TU.generalizer (ty, lambdaDepth)
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
        val (domtyList, ranty, instlist) = TU.coerceFunM (funTy, argTyList)
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
         E.enqueueError "Typeinf 0071"
           (termLoc,
            E.TyConListMismatch
              ("007",{argTyList = argTyList, domTyList = domtyList}));
         (T.ERRORty, TC.TPERROR)
        )
      end
    handle TU.CoerceFun =>
      (
       E.enqueueError "Typeinf 008" (funLoc, E.NonFunction ("008",{ty = funTy}));
       (T.ERRORty, TC.TPERROR)
       )

  fun revealTy key ty =
      case TU.derefTy ty of
        T.SINGLETONty _ => raise bug "SINGLETONty in revealTy"
      | T.ERRORty => ty
      | T.DUMMYty _ => ty
      | T.TYVARty _ => ty
      | T.BOUNDVARty _ => ty
      | T.FUNMty (tyList,ty) =>
        T.FUNMty (map (revealTy key) tyList, revealTy key ty)
      | T.RECORDty tyMap => T.RECORDty (LabelEnv.map (revealTy key) tyMap)
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
        if E.isError() orelse TCU.expansive tpexp then (ty, tpexp)
        else
          let
            val {boundEnv,...} = generalizer (ty, lambdaDepth)
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
                    T.POLYty{boundtvars=boundEnv2, body= ty2} =>
                    (T.POLYty
                       {boundtvars = mergeBoundEnvs(boundEnv,boundEnv2),
                        body = ty2},
                     TC.TPPOLY{btvEnv=mergeBoundEnvs(boundEnv,boundEnv1),
                               expTyWithoutTAbs=ty1,
                               exp=tpexp1,
                               loc=loc1}
                    )
                  | _ => raise bug "non polyty for TPPOLY"
                 )
               | TC.TPPOLYFNM {btvEnv=boundEnv1,
                               argVarList=argVarPathInfo,
                               bodyTy=ranTy,
                               bodyExp=tpexp1,
                               loc=loc1} =>
                 (
                  case ty of
                    T.POLYty{boundtvars=boundEnv2, body= ty2} =>
                    (T.POLYty
                       {boundtvars = mergeBoundEnvs (boundEnv, boundEnv2),
                        body = ty2},
                     TC.TPPOLYFNM
                       {btvEnv=mergeBoundEnvs (boundEnv, boundEnv1),
                        argVarList=argVarPathInfo,
                        bodyTy=ranTy,
                        bodyExp=tpexp1,
                        loc=loc1}
                    )
                  | _ => raise bug "non polyty for TPPOLY"
                 )
               | _ => (T.POLYty {boundtvars = boundEnv, body = ty},
                       TC.TPPOLY {btvEnv=boundEnv,
                                  expTyWithoutTAbs=ty,
                                  exp=tpexp,
                                  loc=loc}
                      )
              )
          end

      fun isStrictValuePat icpat =
          case icpat of
            IC.ICPATERROR _ => false
          | IC.ICPATWILD _ => true
          | IC.ICPATVAR (varInfo, loc) => true
          | IC.ICPATCON (conInfo, loc) => false
          | IC.ICPATEXN (exnInfo, loc) => false
          | IC.ICPATEXEXN ({path, ty}, loc) => false
          | IC.ICPATCONSTANT (constant, loc) => false
          | IC.ICPATCONSTRUCT {con=icpat1, arg=icpat2, loc} => false
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
                    val varInfo = TCU.newTCVarInfo ty
                  in
                    (nil, [(varInfo, tpexp)], nil, TC.TPVAR (varInfo, loc), ty)
                  end
              else
                case VarSet.listItems varSet of
                  [x] =>
                    let
                      val newIcexp =
                        IC.ICCASEM
                        (
                         [icexp],
                         [{args=[icpat], body=IC.ICVAR(x, icpatLoc)}],
                         PatternCalc.BIND,
                         loc
                         )
                      val (ty, tpexp) =
                          typeinfExp lambdaDepth inf context newIcexp
                      val (path, id) =
                          case VarSet.listItems resVarSet of
                            [{path, id}] => (path, id)
                          | _ => raise bug "non singleton resVarSet"
                      val varInfo = {path = path, id = id, ty = ty}
                    in
                      (
                        nil,
                        [(varInfo, tpexp)],
                        nil,
                        TC.TPVAR (varInfo, loc),
                        ty
                      )
                    end
                | _ =>
                  let
                    val resTuple =
                      makeTupleFields
                        (map (fn x => IC.ICVAR (x, icpatLoc))
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
                    val newVarInfo = TCU.newTCVarInfo tupleTy
                    val tyList =
                      case tupleTy of
                        T.RECORDty tyFields => LabelEnv.listItems tyFields
                      | T.ERRORty => map (fn x => T.ERRORty) resTuple
                      | _ => raise bug "decompose"
                    val resBinds =
                      mapi
                      (fn (i, ({path, id}, ty)) =>
                        (
                         {path = path, id = id, ty = ty},
                         TC.TPSELECT
                         {
                          label=Int.toString i,
                          exp=TC.TPVAR (newVarInfo, loc),
                          expTy=tupleTy,
                          resultTy = ty,
                          loc=loc
                          }
                         ))
                      (ListPair.zip (VarSet.listItems resVarSet, tyList))
                  in
                    (
                     [(newVarInfo, tpexp)],
                     resBinds,
                     nil,
                     TC.TPVAR (newVarInfo, loc),
                     tupleTy
                     )
                  end
            end
        in (* decompose body *)
          if not (isStrictValuePat icpat) then makeCase (icpat, icexp)
          else
            case icpat of
              IC.ICPATERROR loc => raise bug "expansive pat"
            | IC.ICPATWILD loc =>
                let
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    lambdaDepth
                    (typeinfExp lambdaDepth zero context icexp, icexpLoc)
                  val newVarInfo = TCU.newTCVarInfo ty
                in
                  (nil,[(newVarInfo,tpexp)], nil, TC.TPVAR (newVarInfo,loc), ty)
                end
            | IC.ICPATVAR ({path,id}, loc) =>
                let
                  val (ty, tpexp) =
                      typeinfExp lambdaDepth zero context icexp
                  val (ty, tpexp) =
                    generalizeIfNotExpansive
                    lambdaDepth
                    ((ty, tpexp), icexpLoc)
                  val varInfo  = {path = path, id=id, ty = ty}
                in
                  (
                   nil,
                   [(varInfo, tpexp)],
                   nil,
                   TC.TPVAR (varInfo, loc),
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
                             SEnv.insert(icpatSEnvMap, l, icpat))
                         SEnv.empty
                         stringIcpatList
                   val expLabelSet =
                       foldl
                         (fn ((l, _), lset) => SSet.add(lset, l))
                         SSet.empty
                         stringIcexpList
                   val _ =
                   (* check that the labels of patterns is
                    * included in the labels of expressions
                    *)
                       SEnv.appi
                       (fn (l, _) =>
                           if SSet.member(expLabelSet, l)
                           then ()
                           else raise E.RecordLabelSetMismatch "009")
                       icpatSEnvMap
                   val labelIcpatIcexpList =
                       map
                         (fn (label, icexp) =>
                             let
                               val icpat =
                                   case SEnv.find(icpatSEnvMap, label) of
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
                   val (bodyVar as {path, id}) = IC.newICVar()
                   val icBodyVar = IC.ICVAR (bodyVar, loc1)
                   val tpVarInfo = {path=path, id=id, ty=tyBody}
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
                    TC.TPVAR (tpVarInfo, loc1),
                    tyBody
                   )
                 end
              )
            | IC.ICPATLAYERED {patVar={path, id}, tyOpt, pat, loc} =>
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
                 @ [({path=path, id=id, ty=ty},
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
          recordKind : recordKind,
          eqKind : eqKind,
          utvarOpt : string option
       }
    When a binding {x:tau} is entered in the typeInferenceContext (context),
    the lambdaDepth of each t in tau is set to the lambdaDepth of the context
    where x occurres.
    When two types are unified, their lambda depth is adjusted by taking
    the minimal.
   *)
  and typeinfExp lambdaDepth applyDepth (context : TIC.context) icexp =
      case icexp of
        IC.ICERROR loc =>
        let
          val resultTy = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
        in
          (resultTy, TC.TPERROR)
        end
      | IC.ICCONSTANT (constant, loc) =>
        let
          val (ty, staticConst) = typeinfConst constant
        in
          (ty, TC.TPCONSTANT {const=staticConst,ty=ty,loc=loc})
        end
      | IC.ICGLOBALSYMBOL (string, globalSymbolKind, loc) =>
        (
         case globalSymbolKind of
           Absyn.ForeignCodeSymbol =>
           (BT.ptrTy,
            TC.TPGLOBALSYMBOL
              {name=string, kind=globalSymbolKind, ty=BT.ptrTy, loc=loc}
           )
        )
      | IC.ICVAR (var as {path, id}, loc) =>
        (
         case VarMap.find(#varEnv context, var)  of
           SOME (TC.VARID varInfo) => (#ty varInfo, TC.TPVAR (varInfo, loc))
         | SOME (TC.RECFUNID (varInfo as {ty,...}, arity)) =>
	   (ty, TC.TPRECFUNVAR {var=varInfo, arity=arity, loc=loc})
         | NONE =>
           (T.ERRORty, TC.TPVAR ({path=path, id=id, ty=T.ERRORty}, loc))
           (* bug 076: This must be due to some user error.
              raise bug "var not found"
            *)
	)
      | IC.ICEXVAR ({path, ty}, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity4\n"; raise e)
        in
          (ty, TC.TPEXVAR ({path=path, ty=ty},loc))
        end
      | IC.ICEXVAR_TOBETYPED _ => raise bug "ICEXVAR_TOBETYPED"
      | IC.ICBUILTINVAR {primitive, ty, loc} =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity5\n";raise e)
          val primInfo = {primitive=primitive, ty=ty}
        in
          case ty of
            T.POLYty{boundtvars, body = T.FUNMty([argTy], resultTy)} =>
            let
              val (subst, newBoundEnv) = TU.copyBoundEnv boundtvars
              val newArgTy = TU.substBTvar subst argTy
              val newResultTy = TU.substBTvar subst resultTy
              val argVarInfo = TCU.newTCVarInfo newArgTy
              val newTy =
                  T.POLYty{boundtvars=newBoundEnv,
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
                     argExp=TC.TPVAR (argVarInfo, loc),
                     argTy=newArgTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.POLYty{boundtvars, body = T.FUNMty(_, ty)} =>
            raise Control.Bug "Uncurried fun type in OPRIM"
          | T.FUNMty([argTy], resultTy) =>
            let
              val argVarInfo = TCU.newTCVarInfo argTy
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
                     argExp=TC.TPVAR (argVarInfo, loc),
                     argTy=argTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.FUNMty(_, ty) => raise Control.Bug "Uncurried fun type in PRIM"
          | _ =>raise Control.Bug "primitive type"
        end
      | IC.ICCON (con as {path, id, ty}, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity6\n";raise e)
          val conInfo = {path=path, ty=ty, id=id}
        in
          case ty of
            T.POLYty{boundtvars, body = T.FUNMty([argTy], resultTy)} =>
            let
              val (subst, newBoundEnv) = TU.copyBoundEnv boundtvars
              val newArgTy = TU.substBTvar subst argTy
              val newResultTy = TU.substBTvar subst resultTy
              val argVarInfo = TCU.newTCVarInfo newArgTy
              val newTy =
                  T.POLYty{boundtvars=newBoundEnv,
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
                     argExpOpt= SOME (TC.TPVAR (argVarInfo, loc)),
                     argTyOpt = SOME newArgTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.POLYty{boundtvars, body = T.FUNMty(_, ty)} =>
            raise Control.Bug "Uncurried fun type in OPRIM"
          | T.FUNMty([argTy], resultTy) =>
            let
              val argVarInfo = TCU.newTCVarInfo argTy
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
                     argExpOpt=SOME (TC.TPVAR (argVarInfo, loc)),
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
      | IC.ICEXN (exn as {path, id, ty}, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity7\n";raise e)
          val exnInfo = {path=path, ty=ty, id=id}
        in
          case ty of
            T.FUNMty([argTy], resultTy) =>
            let
              val argVarInfo = TCU.newTCVarInfo argTy
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
                     argExpOpt=SOME (TC.TPVAR (argVarInfo, loc)),
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
      | IC.ICEXN_CONSTRUCTOR (exn as {path, id, ty}, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity8\n";raise e)
          val exnInfo = {path=path, ty=ty, id=id}
        in
          (BT.exntagTy,
           TC.TPEXN_CONSTRUCTOR{exnInfo = exnInfo, loc=loc}
          )
        end
      | IC.ICEXEXN_CONSTRUCTOR (exn as {path, ty}, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity9\n";raise e)
          val exExnInfo = {path=path, ty=ty}
        in
          (BT.exntagTy,
           TC.TPEXEXN_CONSTRUCTOR{exExnInfo = exExnInfo, loc=loc}
          )
        end
      | IC.ICEXEXN ({path, ty}, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity10\n"; raise e)
          val exExnInfo = {path=path, ty=ty}
        in
          case ty of
            T.FUNMty([argTy], resultTy) =>
            let
              val argVarInfo = TCU.newTCVarInfo argTy
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
                     argExpOpt=SOME (TC.TPVAR (argVarInfo, loc)),
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
      | IC.ICOPRIM (oprimInfo, loc) =>
        let
          val oprimInfo as {id, path, ty} =
              case OPrimMap.find(#oprimEnv context, oprimInfo) of
                SOME oprimInfo => oprimInfo
              | NONE => raise bug "OPrim not found"
        in
          case ty of
            T.POLYty{boundtvars, body = T.FUNMty([argTy], resultTy)} =>
            let
              val (subst, newBoundEnv) = TU.copyBoundEnv boundtvars
              val newArgTy = TU.substBTvar subst argTy
              val newResultTy = TU.substBTvar subst resultTy
              val argVarInfo = TCU.newTCVarInfo newArgTy
              val newTy =
                  T.POLYty{boundtvars=newBoundEnv,
                           body = T.FUNMty([newArgTy], newResultTy)}
              val instTyList =
                  BoundTypeVarID.Map.foldri
                    (fn (i, {eqKind, tvarKind}, instTyList)=>
                        T.BOUNDVARty i :: instTyList)
                    nil
                    newBoundEnv
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
                     argExp=TC.TPVAR (argVarInfo, loc),
                     argTy=newArgTy,
                     loc=loc
                    },
                  loc=loc
                 }
              )
            end
          | T.POLYty{boundtvars, body = T.FUNMty(_, ty)} =>
            raise bug "Uncurried fun type in OPRIM"
          | _ => raise bug "non poly oprim ty"
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
               val (instTy, tpexp) = TCU.freshInst (ty1, tpexp)
               val ty2 = TU.freshRigidInstTy ty2
             in
               (
                U.unify [(instTy, ty2)];
                (ty2, tpexp)
               )
               handle
               U.Unify =>
               (
                E.enqueueError
                  "Typeinf 009"
                  (
                   loc,
                   E.TypeAnnotationNotAgree ("012",{ty=instTy,annotatedTy=ty2})
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
           val ty2 = TU.freshRigidInstTy ty2
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
               val (instTy, tpexp) = TCU.freshInst (ty1, tpexp)
               val ty22 = TU.freshRigidInstTy ty2
               val revealedTy2 =
                   case revealKey of
                     NONE => ty22
                   | SOME key => revealTy key ty22
             in
               (
                U.unify [(instTy, revealedTy2)];
                (ty22, tpexp)
               )
               handle
               U.Unify =>
               (
                E.enqueueError
                  "Typeinf 010"
                  (
                   loc,
                   E.SignatureMismatch ("012",{path=[], ty=instTy,
                                               annotatedTy=ty22})
                  );
                (T.ERRORty, TC.TPERROR)
               )
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
                      val (ty, tpexp) = TCU.freshInst (ty, tpexp)
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
                      val (ty, tpexp) = TCU.freshInst (ty, tpexp)
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
                       val (funTy, _) = TIU.freshTopLevelInstTy funTy
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
                               E.enqueueError "Typeinf 012"
                                              (
                                               funLoc,
                                               E.TypeAnnotationNotAgree
                                                 ("013",{ty=funTy, annotatedTy=annotatedTy})
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
                  val (argTy, argExp) = TCU.freshInst (argTy, argExp)
                  val polyFunTy = ITy.evalIty context funITy
                      handle e => (P.print "ity14\n"; raise e)
                  (*  a con type must be rank zero *)
                  val (funTy, instTyList) = TIU.freshTopLevelInstTy polyFunTy
                  val _ =
                      app
                        (fn ity =>
                            let val annotatedTy1 = ITy.evalIty context ity
                                    handle e => (P.print "ity15\n"; raise e)
                            in
                              U.unify [(funTy, annotatedTy1)]
                              handle U.Unify =>
                                     E.enqueueError "Typeinf 013"
                                       (
                                        loc,
                                        E.TypeAnnotationNotAgree
                                          ("014",
                                           {ty=funTy,annotatedTy=annotatedTy1})
                                       )
                            end)
                        funItyList
                 val (domtyList,ranty,instlist) = TU.coerceFunM (funTy,[argTy])
                     handle TU.CoerceFun =>
                            (
                             E.enqueueError "Typeinf 014"
                               (funLoc,E.NonFunction("015",{ty=funTy}));
                             ([T.ERRORty], T.ERRORty, nil)
                            )
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
                       val {boundEnv, ...} = generalizer (ranty, lambdaDepth)
                     in
                       if BoundTypeVarID.Map.isEmpty boundEnv
                       then (ranty, newTermBody)
                       else
                         (
                          T.POLYty{boundtvars = boundEnv, body = ranty},
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
                   E.enqueueError "Typeinf 015"
                     (loc, E.TyConMismatch ("016",{domTy=domty,argTy=argTy}));
                   (T.ERRORty, TC.TPERROR)
                  )
                end
              | _ => raise bug "con in multiple apply"
          fun processPrim (lambdaDepth, makeNewTermBody, polyFunTy, funLoc) =
              case evalArgs lambdaDepth icexpList of
               ([argTy], [tpexp2]) =>
               let
                 (*  a primitive type must be rank zero *)
                 val (funTy,instTyList) = TIU.freshTopLevelInstTy polyFunTy
                 val _ =
                     app
                       (fn ity =>
                           let
                             val annotatedTy1 = ITy.evalIty context ity
                                 handle e => (P.print "ity16\n"; raise e)
                           in
                             U.unify [(funTy, annotatedTy1)]
                             handle U.Unify =>
                                    E.enqueueError "Typeinf 016"
                                      (
                                       loc,
                                       E.TypeAnnotationNotAgree
                                         ("017",
                                          {ty=funTy,annotatedTy=annotatedTy1})
                                      )
                           end)
                       funItyList
                 val (domtyList,ranty,instlist) = TU.coerceFunM (funTy,[argTy])
                     handle TU.CoerceFun =>
                            (
                             E.enqueueError "Typeinf 017"
                               (loc,E.NonFunction("018",{ty=funTy}));
                             ([T.ERRORty], T.ERRORty, nil)
                            )
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
                         E.enqueueError "Typeinf 018"
                           (loc, E.TyConMismatch
                                   ("019",{domTy=domty,argTy=argTy}));
                         (T.ERRORty, TC.TPERROR)
                        )
               end
             | _ => raise bug "PrimOp in multiple apply"
        in
          case funExp of
            IC.ICVAR (var, funVarLoc) =>
	    let
              val (funExp, funTy) =
                  case VarMap.find(#varEnv context, var) of
                    SOME (TC.VARID (var as {ty,...})) =>
                    (TC.TPVAR (var, funVarLoc), ty)
                  | SOME (TC.RECFUNID(var as {ty,...},arity)) =>
                    (TC.TPRECFUNVAR{var=var,arity=arity,loc=funVarLoc},ty)
                  | NONE => raise bug "var not found (1)"
              val (funTy, funExp) =
                  case funItyList of
                    nil => (funTy, funExp)
                  | _ => TCU.freshInst (funTy, funExp)
            in
              processVar (funTy, funExp, funVarLoc)
            end
          | IC.ICEXVAR ({path, ty}, loc) =>
	    let
              val ty = ITy.evalIty context ty
                  handle e => (P.print "ity17\n"; raise e)
	      val funExp = TC.TPEXVAR ({path=path, ty=ty}, loc)
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
                 val (domtyList,ranty,instlist) = TU.coerceFunM (funTy,[argTy])
                     handle TU.CoerceFun =>
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
          | IC.ICCON ({path, id, ty=funIty}, funLoc) =>
            let
              val lambdaDepth = incDepth ()
              fun makeNewTermBody (argExp, argTy, funTy, instTyList) =
                  TC.TPDATACONSTRUCT
                    {
                     con={path=path,id=id,ty=funTy},
                     instTyList=instTyList,
                     argExpOpt=SOME argExp,
                     argTyOpt=SOME argTy,
                     loc=loc
                    }
            in
              processCon(lambdaDepth,makeNewTermBody,funIty,funLoc)
            end
          | IC.ICEXN ({path, id, ty}, loc) =>
            let
              val lambdaDepth = incDepth ()
              fun makeNewTermBody (argExp, argTy, funTy, instTyList) =
                  TC.TPEXNCONSTRUCT
                    {
                     exn=TC.EXN {path=path,id=id,ty=funTy},
                     instTyList=instTyList,
                     argExpOpt=SOME argExp,
                     argTyOpt=SOME argTy,
                     loc=loc
                    }

            in
              processCon (lambdaDepth, makeNewTermBody, ty, loc)
            end
          | IC.ICEXEXN ({path, ty}, loc) =>
            let
              val lambdaDepth = incDepth ()
              fun makeNewTermBody (argExp, argTy, funTy, instTyList) =
                  TC.TPEXNCONSTRUCT
                    {
                     exn=TC.EXEXN {path=path,ty=funTy},
                     instTyList=instTyList,
                     argExpOpt=SOME argExp,
                     argTyOpt=SOME argTy,
                     loc=loc
                    }

            in
              processCon (lambdaDepth, makeNewTermBody, ty, loc)
            end
          | IC.ICOPRIM (oprimInfo, loc) =>
            let
              val oprimInfo as {id, path, ty} =
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
                      (E.enqueueError "Typeinf 022"
                         (loc, E.TyConListMismatch
                                 ("091",{argTyList=argTyList,
                                         domTyList=domTyList}));
                       raise Fail
                      )
            val _ =
                if eqList (argTyList, domTyList) then ()
                else
                  (
                   E.enqueueError "Typeinf 023"
                     (loc,
                      E.TyConListMismatch
                        ("007",{argTyList = argTyList,
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
          handle Fail => (T.ERRORty, TC.TPERROR)
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
          val  (ty, tpexp) =
               typeinfExp lambdaDepth applyDepth context icexp
          val ty = tyConSubstTy typIdMap ty
(*
          val tpexp = tyConSubstExp typIdMap tpexp
*)
        in
          (ty, TC.TPCAST(tpexp, ty, loc)) (* bug 118 *)
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
                  E.enqueueError "Typeinf 024"
                    (loc, E.RaiseArgNonExn("023",{ty = ty1}));
                  (T.ERRORty, TC.TPERROR)
                 )
        end
      | IC.ICHANDLE (icexp, icpatIcexpList, loc) =>
        let
          val (ty1, tpexp) =
              TCU.freshInst (typeinfExp lambdaDepth inf context icexp)
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
              case TU.derefTy ruleTy of
                T.FUNMty([domTy], ranTy)=>(domTy, ranTy)
              | T.ERRORty => (T.ERRORty, T.ERRORty)
              | _ => raise bug "Case Type Inference"
          val newVarInfo = TCU.newTCVarInfo domTy
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
                  expList=[TC.TPVAR (newVarInfo, loc)],
                  expTyList=[domTy],
                  ruleList=tppatTpexpList,
                  ruleBodyTy=ranTy,
                  caseKind= PatternCalc.HANDLE,
                  loc=loc
                 },
               loc=loc
              }
           )
          )
          handle U.Unify =>
                 (
                  E.enqueueError "Typeinf 025"
                    (loc, E.HandlerTy("024",{expTy=ty1, handlerTy=ranTy}));
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
                           IC.ICPATVAR (var, _) => (var, ityList)
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
                     map (fn pat => (IC.newICVar (), IC.getLocPat pat)) patList
                 val newPtexp =
                     IC.ICFNM1
                       (
                        map (fn (var, loc) => (var, nil)) varList,
                        IC.ICCASEM
                          (
                           map (fn (var, loc) => IC.ICVAR(var, loc)) varList,
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
                 map (fn pat => (IC.newICVar (), IC.getLocPat pat)) patList
             val newPtexp =
                 IC.ICFNM1
                   (
                    map (fn (var, loc) => (var, nil)) varList,
                    IC.ICCASEM
                      (
                       map (fn (var,loc) => IC.ICVAR(var, loc)) varList,
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
                 (fn ((var as {path, id}, ityList),
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
                                E.enqueueError "Typeinf 026"
                                  (
                                   loc,
                                   E.TypeAnnotationNotAgree
                                     ("025",
                                      {ty=domTy, annotatedTy=annotatedTy1})
                                  )
                              end)
                          ityList
                    val varInfo = {path=path, id=id, ty=domTy}
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
         in
           (ty, tpexp)
         end
      | IC.ICFNM1_POLY(varTyList, icexp, loc) =>
         let
           val lambdaDepth = incDepth ()
           val (newContext, tyVarInfoList) =
               foldr
                 (fn ((var as {path, id}, ity),
                      (newContext, tyVarInfoList)) =>
                  let
                    val domTy = ITy.evalIty newContext ity
                                handle e => (P.print "ity21\n"; raise e)
                    val varInfo = {path=path, id=id, ty=domTy}
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
          val (tyListRev, tpexpListRev) =
              foldl
                (fn (ptexp, (tyListRev, tpexpListRev)) =>
                    let
                      val (ty,tpexp) = typeinfExp lambdaDepth inf context ptexp
                      val (ty,tpexp) = TCU.freshInst (ty,tpexp)
                    in
                      (ty::tyListRev, tpexp::tpexpListRev)
                    end
                )
                (nil,nil)
                icexpList
          val (tyList, tpexpList) = (List.rev tyListRev, List.rev tpexpListRev)
          val (ruleTy, tpMatchM) =
              typeinfMatch lambdaDepth applyDepth tyList context argsBodyList
          val ranTy =
              case TU.derefTy ruleTy of
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
          val (ty1, tpexp1) =
              TCU.freshInst (typeinfExp lambdaDepth applyDepth context icexp)
          val (modifyTpexp, tySmap) =
              (* this inside-out term is correct under the call-by-value
                 semantics *)
              foldl
	        (fn ((label, icexp), (modifyTpexp, tySmap)) =>
                    let
                      val (ty, tpexp) =
                          TCU.freshInst
                            (typeinfExp lambdaDepth applyDepth context icexp)
                    in
                      (TC.TPMODIFY {label=label,
                                    recordExp=modifyTpexp,
                                    recordTy=ty1,
                                    elementExp=tpexp,
                                    elementTy=ty,
                                    loc=loc},
                       LabelEnv.insert (tySmap, label, ty))
                    end)
                (tpexp1, LabelEnv.empty)
                stringIcexpList
          val modifierTy =
              T.newtyRaw
                {
                 lambdaDepth = lambdaDepth,
                 tvarKind = T.REC tySmap,
                 eqKind = A.NONEQ,
                 utvarOpt = NONE
                }
        in
          (
           U.unify [(ty1, modifierTy)];
           (ty1, modifyTpexp)
          )
          handle U.Unify =>
                 (
                  E.enqueueError "Typeinf 027"
	            (
		     loc,
		     E.TyConMismatch("026",{argTy = ty1, domTy = modifierTy})
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
                   IC.ICVAR(newVar, loc),
                   loc
                  ),
                loc
               )
            )
        end
      | IC.ICSELECT (label, icexp, loc) =>
        let
          val (ty1, tpexp) = typeinfExp lambdaDepth applyDepth context icexp
          val ty1 = TU.derefTy ty1
        in
          case ty1 of
            T.RECORDty tyFields =>
            (* here we cannot use U.unify, which is for monotype only. *)
              (case LabelEnv.find(tyFields, label) of
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
                 (E.enqueueError "Typeinf 028"
                    (loc, E.FieldNotInRecord("027",{label = label}));
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
                    tvarKind = T.REC (LabelEnv.singleton(label, elemTy)),
                    eqKind = A.NONEQ,
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
                       E.enqueueError "Typeinf 029"
                         (loc,E.TyConMismatch
                                ("028",{domTy=recordTy, argTy=ty1}));
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
                     tvarKind = T.REC (LabelEnv.singleton(label, elemTy)),
                     eqKind = A.NONEQ,
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
                        E.enqueueError "Typeinf 030"
                        (loc,
                         E.TyConMismatch("029",{domTy=recordTy,argTy=ty1}));
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
      | IC.ICCAST (icexp, loc) =>
        let
          val (ty1, tpexp) = typeinfExp lambdaDepth inf context icexp
          val ty = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
        in
          (ty, TC.TPCAST(tpexp, ty, loc))
        end
      | IC.ICFFIIMPORT (icexp, ffity, loc) =>
        let
          val (expTy, tpexp) =
              TCU.freshInst (typeinfExp lambdaDepth inf context icexp)
          val _ =
              U.unify [(BT.ptrTy, expTy)]
              handle U.Unify =>
                     E.enqueueError "Typeinf 031"
                       (loc, E.FFIStubMismatch("030",BT.ptrTy, expTy))
          val ffity = evalForeignFunTy context ffity
          val stubTy = ffiStubTy ffity
        in
          (stubTy,
           TC.TPFFIIMPORT {ptrExp = tpexp,
                           ffiTy = ffity,
                           stubTy = stubTy,
                           loc = loc})
        end
      | IC.ICFFIEXPORT (icexp, ffity, loc) =>
        raise bug "ICFFIEXPORT"
      | IC.ICFFIAPPLY (attributes, icexp, ffiArgList, ffiRetTy, loc) =>
        let
          val retDir = IMPORT {force = isForceImportAttribute attributes}
          val (funTy, funExp) =
              TCU.freshInst (typeinfExp lambdaDepth applyDepth context icexp)
          val _ =
              U.unify [(BT.ptrTy, funTy)]
              handle U.Unify =>
                     E.enqueueError "Typeinf 032"
                       (loc, E.FFIStubMismatch("031",BT.ptrTy, funTy))
          val (argFFItys, args) =
              ListPair.unzip
                (map (typeinfFFIArg lambdaDepth applyDepth context) ffiArgList)
          val argTupleExp = makeTupleExp (args, loc)
          val retFFItys = evalFFIFunTyArgs context retDir [ffiRetTy]
          val ffity = TC.FFIFUNTY (attributes, argFFItys, retFFItys, loc)
          val stubTy = ffiStubTy ffity
          val retTy = case stubTy of T.FUNMty (_,retTy) => retTy
                                   | _ => raise Control.Bug "ICFFIAPPLY"
        in
          (retTy,
           TC.TPAPPM {funExp = TC.TPFFIIMPORT {ptrExp = funExp,
                                               ffiTy = ffity,
                                               stubTy = stubTy,
                                               loc = loc},
                      funTy = stubTy,
                      argExpList = [argTupleExp],
                      loc = loc})
        end
      | IC.ICSQLSERVER (server, ty, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity22\n"; raise e)
          val schema =
              case TU.derefTy ty of
                T.RECORDty fieldTys =>
                LabelEnv.map
                  (fn ty =>
                      case TU.derefTy ty of
                        T.RECORDty fieldTys =>
                        (LabelEnv.app
                           (fn ty =>
                               if isCompatibleWithSQL ty then ()
                               else (E.enqueueError "Typeinf 035"
                                       (loc, E.IncompatibleWithSQL("033",ty))))
                           fieldTys;
                         fieldTys)
                      | _ =>
                        (E.enqueueError "Typeinf 036"
                           (loc, E.InvalidSQLTableDecl("034",ty));
                         LabelEnv.empty))
                  fieldTys
              | T.CONSTRUCTty {tyCon,...} =>
                (if TypID.eq (#id tyCon, #id BT.unitTyCon) then ()
                 else E.enqueueError "Typeinf 037" (loc, E.InvalidSQLTableDecl("035",ty));
                 LabelEnv.empty)
              | _ => (E.enqueueError "Typeinf 038" (loc, E.InvalidSQLTableDecl("036",ty));
                      LabelEnv.empty)
          val resultTy =
              T.CONSTRUCTty
                {tyCon = BT.serverTyCon,
                 args = [ty]}
        in
          (resultTy,
           TC.TPSQLSERVER {server = server, schema = schema,
                           resultTy = resultTy, loc = loc})
        end
      | IC.ICSQLDBI (icpat, icexp, loc) =>
        let
          (*
           *  T{x:t dbi} |- e : tau   t \not\in FTV(T)   t \not\in FTV(tau)
           * ----------------------------------------------------------------
           *  T |- sqldbi x in e : tau
           *
           * This term is derived from "abstype" of Mitchell-Protokin's
           * exsitential type scheme. This term means the following:
           *   abstype X with x : X dbi is DBI in e
           *)
          val lambdaDepth = incDepth ()
          val tv = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
          val dbiTy = T.CONSTRUCTty
                        {tyCon = BT.dbiTyCon,
                         args = [tv]}
          val (patVarEnv, patTy, tppat) = typeinfPat lambdaDepth context icpat
          val _ = U.unify [(patTy, dbiTy)]
              handle U.Unify =>
                     E.enqueueError "Typeinf 038-2"
                       (loc,
                        E.RuleTypeMismatch
                          ("037",{thisRule=patTy, otherRules=dbiTy}))
          val newContext = TIC.extendContextWithVarEnv (context, patVarEnv)
          val (expTy, tpexp) =
              typeinfExp lambdaDepth applyDepth newContext icexp

          val _ =
              if (case TU.derefTy tv of
                    T.TYVARty (tvs as ref (T.TVAR {lambdaDepth=depth, ...})) =>
                    T.youngerDepth {contextDepth = lambdaDepth,
                                    tyvarDepth = depth}
                    andalso not (OTSet.member (TU.EFTV expTy, tvs))
                  | _ => false)
              then ()
              else E.enqueueError "Typeinf 039" (loc, E.InvalidSQLDBI("038",tv))
        in
          (expTy,
           TC.TPCASEM
             {expList=[TC.TPDATACONSTRUCT
                         {con = BT.DBITPConInfo,
                          instTyList = [tv],
                          argExpOpt = NONE,
                          argTyOpt = NONE,
                          loc = loc}],
              expTyList = [dbiTy],
              ruleList = [{args=[tppat], body=tpexp}],
              ruleBodyTy = expTy,
              caseKind = PatternCalc.MATCH,
              loc = loc})
        end

  and typeinfPat
        lambdaDepth
        (context as {tvarEnv, varEnv,...} :TIC.context)
        icpat =
      case icpat of
        IC.ICPATERROR loc =>
        let val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
        in (VarMap.empty, ty1, TC.TPPATERROR (ty1, loc)) end
      | IC.ICPATWILD loc =>
         let val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
         in (VarMap.empty, ty1, TC.TPPATWILD (ty1, loc)) end
      | IC.ICPATVAR (var as {path, id}, loc) =>
        let
          val ty1 = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
          val varInfo = {path=path, id=id, ty=ty1}
          val varEnv1 = VarMap.insert (VarMap.empty, var, TC.VARID varInfo)
        in
          (varEnv1, ty1, TC.TPPATVAR (varInfo, loc))
        end
      | IC.ICPATCON ({path, id, ty=ity}, loc) =>
        let
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity23\n"; raise e)
          val conInfo = {path=path, id=id, ty=ty}
          val (ty1, tylist) =
              case ty of
                (T.POLYty{boundtvars, body, ...}) =>
                let val subst = TU.freshSubst boundtvars
                in
                  (TU.substBTvar subst body, BoundTypeVarID.Map.listItems subst)
                end
              | _ => (ty, nil)

        in
          case TU.derefTy ty1 of
            T.FUNMty _ =>
                (
                 E.enqueueError "Typeinf 040"
                   (loc,
                    E.ConRequireArg("039",{longid = path}));
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

      | IC.ICPATEXN ({path, id, ty=ity}, loc) =>
        let
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity24\n"; raise e)
          val exnInfo = {path=path, id=id, ty=ty}
        in
          case TU.derefTy ty of
            T.FUNMty _ =>
            (
             E.enqueueError "Typeinf 041"
               (loc,
                E.ConRequireArg("040",{longid = path}));
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
      | IC.ICPATEXEXN ({path, ty=ity}, loc) =>
        let
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity25\n"; raise e)
          val exExnInfo = {path=path, ty=ty}
        in
          case TU.derefTy ty of
            T.FUNMty _ =>
            (
             E.enqueueError "Typeinf 042"
               (loc,
                E.ConRequireArg("041",{longid = path}));
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
      | IC.ICPATCONSTANT (constant, loc) =>
        let
          val (ty, staticConst) = typeinfConst constant
        in
          (VarMap.empty, ty, TC.TPPATCONSTANT(staticConst, ty, loc))
        end
      | IC.ICPATCONSTRUCT {con=icpat1, arg=icpat2, loc} =>
        (case icpat1 of
           IC.ICPATCON({path, id, ty=ity}, loc) =>
           let
             val ty = ITy.evalIty context ity
                 handle e => (P.print "ity26\n"; raise e)
             val conInfo = {path=path, id=id, ty=ty}
             val (ty1, tylist) =
                 case ty of
                   (T.POLYty{boundtvars, body, ...}) =>
                   let val subst = TU.freshSubst boundtvars
                   in
                     (TU.substBTvar subst body,
                      BoundTypeVarID.Map.listItems subst)
                   end
                 | _ => (ty, nil)
             val (varEnv1, patTy2, tppat2) =
                 typeinfPat lambdaDepth context icpat2
             val (domtyList, ranty, instTyList) =
                 TU.coerceFunM (ty, [patTy2])
                 handle TU.CoerceFun =>
                        (
                         E.enqueueError "Typeinf 043"
                           (loc,E.NonFunction("042",{ty = ty}));
                         ([T.ERRORty], T.ERRORty, nil)
                        )
             val domty =
                 case domtyList of
                   [ty] => ty
                 | _ => raise bug "arity mismatch"
             val _ =
                 U.unify [(patTy2, domty)]
                 handle U.Unify =>
                        E.enqueueError "Typeinf 044"
                          (
                           loc,
                           E.TyConMismatch
                             ("043",{argTy = patTy2, domTy = domty})
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
         | IC.ICPATEXN ({path, id, ty=ity}, loc) =>
           let
             val ty = ITy.evalIty context ity
                 handle e => (P.print "ity27\n"; raise e)
             val exnInfo = {path=path, id=id, ty=ty}
             val (varEnv1, patTy2, tppat2) =
                 typeinfPat lambdaDepth context icpat2
             val (domtyList, ranty, instTyList) =
                 TU.coerceFunM (ty, [patTy2])
             val domty =
                 case domtyList of
                   [ty] => ty
                 | _ => raise bug "arity mismatch"
             val _ =
                 U.unify [(patTy2, domty)]
                 handle U.Unify =>
                        E.enqueueError "Typeinf 045"
                          (
                           loc,
                           E.TyConMismatch
                             ("044",{argTy = patTy2, domTy = domty})
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
         | IC.ICPATEXEXN ({path, ty=ity}, loc) =>
           let
             val ty = ITy.evalIty context ity
                 handle e => (P.print "ity28\n"; raise e)
             val exExnInfo = {path=path, ty=ty}
             val (varEnv1, patTy2, tppat2) =
                 typeinfPat lambdaDepth context icpat2
             val (domtyList, ranty, instTyList) =
                 TU.coerceFunM (ty, [patTy2])
             val domty =
                 case domtyList of
                   [ty] => ty
                 | _ => raise bug "arity mismatch"
             val _ =
                 U.unify [(patTy2, domty)]
                 handle U.Unify =>
                        E.enqueueError "Typeinf 046"
                          (
                           loc,
                           E.TyConMismatch
                             ("045",{argTy = patTy2, domTy = domty})
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
            E.enqueueError "Typeinf 047"(loc, E.NonConstruct("046",{pat = icpat1}));
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
                       LabelEnv.insert(tyFields, label, ty),
                       LabelEnv.insert(tppatFields, label, tppat)
                      )
                    end)
                (VarMap.empty, LabelEnv.empty, LabelEnv.empty)
                fields
          val ty1 =
              if flex
              then
                T.newtyRaw
                  {
                   lambdaDepth = lambdaDepth,
                   tvarKind = T.REC tyFields,
                   eqKind = A.NONEQ,
                   utvarOpt = NONE
                  }
              else T.RECORDty tyFields
        in
          (varEnv1,
           ty1,
           TC.TPPATRECORD{fields=tppatFields, recordTy=ty1, loc=loc}
          )
        end
      | IC.ICPATLAYERED {patVar as {path,id}, tyOpt, pat, loc} =>
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
                         E.enqueueError "Typeinf 048"
                           (
                            loc,
                            E.TypeAnnotationNotAgree
                              ("047",{ty = ty1, annotatedTy = ty2})
                           )
                end
          val varInfo = TCU.newTCVarInfoWithPath (path, ty1)
        in
          (
           VarMap.insert (varEnv1, patVar, TC.VARID varInfo),
           ty1,
           TC.TPPATLAYERED
             {varPat=TC.TPPATVAR (varInfo, loc), asPat=tpat, loc=loc}
          )
        end
      | IC.ICPATTYPED (icpat, ty, loc) =>
        let
          val (varEnv1, ty1, tppat) = typeinfPat lambdaDepth context icpat
          val ty2 = ITy.evalIty context ty
              handle e => (P.print "ity30\n"; raise e)
          val _ = U.unify [(ty1, ty2)]
              handle U.Unify =>
                     E.enqueueError "Typeinf 049"
                       (
                        loc,
                        E.TypeAnnotationNotAgree
                          ("048",{ty = ty1, annotatedTy = ty2})
                       )
        in
          (varEnv1, ty2, tppat)
        end

  and typeinfFFIArg lambdaDepth applyDepth context ffiarg =
      case ffiarg of
        IC.ICFFIARG (icexp, ffity, loc) =>
        let
          val (argTy, argExp) =
              TCU.freshInst (typeinfExp lambdaDepth applyDepth context icexp)
          val ffity = evalFFIty context EXPORT ffity
          val stubTy = ffiStubTy ffity
          val _ =
              U.unify [(argTy, stubTy)]
              handle U.Unify =>
                     E.enqueueError "Typeinf 050"
                       (loc, E.TypeAnnotationNotAgree
                               ("049",{ty = argTy, annotatedTy = stubTy}))
        in
          (ffity, (argTy, argExp))
        end
      | IC.ICFFIARGSIZEOF (ty, factorExpOpt, loc) =>
        let
          val ty = ITy.evalIty context ty
              handle e => (P.print "ity31\n"; raise e)
          val sizeofExp = TC.TPCAST (TC.TPSIZEOF (ty, loc), BT.wordTy, loc)
          val argExp =
              case factorExpOpt of
                NONE => sizeofExp
              | SOME ptfactorExp =>
                let
                  val (factorTy, factorExp) =
                      TCU.freshInst (typeinfExp lambdaDepth applyDepth context
                                                ptfactorExp)
                  val _ =
                      U.unify [(BT.wordTy, factorTy)]
                      handle U.Unify =>
                             (E.enqueueError "Typeinf 051"
                                (loc, E.FFIStubMismatch
                                        ("050",BT.wordTy, factorTy)))
                  val argPair =
                      makeTupleExp ([(BT.wordTy, sizeofExp),
                                     (BT.wordTy, factorExp)], loc)
                  val argTy = makeTupleTy [BT.wordTy, BT.wordTy]
                in
                  TC.TPPRIMAPPLY
                    {primOp =
                       {primitive = BuiltinPrimitive.Word_mul,
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
                 E.enqueueError "Typeinf 052"
                     (
                       IC.getRuleLocM [rule],
                       E.RuleTypeMismatch
                         ("051",{thisRule = tyRule, otherRules = tyRules})
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
                 E.enqueueError "Typeinf 053"
                     (
                       getRuleLocM [rule],
                       E.RuleTypeMismatch
                         ("052",{thisRule = ruleTy, otherRules = rulesTy})
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
        val (bodyTy, typedExp) =
          TCU.freshInst (typeinfExp
                         lambdaDepth
                         inf
                         (TIC.extendContextWithVarEnv(context, varEnv1))
                         exp)
      in
        (
          U.unify (ListPair.zip(patTyList, argtyList));
          (T.FUNMty(patTyList, bodyTy), {args=typedPatList, body=typedExp})
        )
        handle U.Unify =>
               let val ruleLoc = IC.getRuleLocM [{args=patList, body=exp}]
               in
                 E.enqueueError "Typeinf 054"
                 (ruleLoc,
                  E.TyConListMismatch
                    ("053",{argTyList = argtyList, domTyList = patTyList}));
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
                 E.enqueueError "Typeinf 055"
                 (ruleLoc,
                  E.TyConListMismatch
                    ("054",{argTyList = argtyList, domTyList = patTyList}));
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
                              "Typeinf 056"
                              (
                               IC.getLocPat icpat,
                               E.DuplicatePatternVar
                                 ("055",{vars = [String.concatWith "." path]}));
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
                           E.enqueueError "Typeinf 056-2"
                             (Loc.mergeLocs
                                (IC.getLocPat icpat, IC.getLocExp icexp),
                              exn);
                           (nil, nil, nil)
                          )
                        | exn as E.PatternExpMismatch _ =>
                          (
                           E.enqueueError "Typeinf 057"
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
                                 OTSet.union(TU.EFTV ty, tyvarSet)
                             )
                             OTSet.empty
                             (patternVarBinds1@extraBinds1)
                          )
                          handle x => raise x
                      val _ =
                          (
                           TvarMap.appi
                             (fn (utvar, ref (T.SUBSTITUTED ty)) =>
                                 (case TU.derefSubstTy ty of
                                    T.BOUNDVARty _ => ()
                                  | T.TYVARty (tvstateRef
                                                 as ref (T.TVAR {eqKind,...}))
                                    =>
                                    if OTSet.member(tyvarSet, tvstateRef) then
                                      E.enqueueError "Typeinf 058"
                                        (loc,
                                         E.UserTvarNotGeneralized
                                           ("056",
                                            {utvarName =
                                             (case eqKind of A.EQ => "''"
                                                           | A.NONEQ  => "'")
                                             ^ #name utvar}))
                                    else ()
                                  | _ =>
                                    (
                                     T.printTy ty;
                                     raise bug "SUBSTITUTED to Non BoundVarTy"
                                    )
                                 )
                               | (utvar,
                                  tvstateRef as (ref (T.TVAR{eqKind,...}))) =>
                                 if OTSet.member(tyvarSet, tvstateRef) then
                                   E.enqueueError "Typeinf 059"
                                     (loc,
                                      E.UserTvarNotGeneralized
                                        ("057",
                                         {utvarName =
                                          (case eqKind of A.EQ => "''"
                                                        | A.NONEQ  => "'")
                                          ^ #name utvar})
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
          fun bindVar (lambdaDepth, varEnv, var, varInfo as {ty, id, path}) =
              (TU.adjustDepthInTy lambdaDepth ty;
               VarMap.insert(varEnv, var, TC.VARID varInfo))
          val newVarEnv =
              foldl
                (fn ((varInfo, _), newVarEnv) =>
                    let
                      val var = {path = #path varInfo, id = #id varInfo}
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
                (fn ({funVarInfo=funVar as {path, id},
                      tyList,
                      rules=icmatch},
                     (newContext,funTyList)) =>
                    let
                      val arity = arityOfMatch icmatch
                      val funTy =
                          T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                      val funVarInfo = {path=path, id=id, ty=funTy}
                      val tyList = map (ITy.evalIty context) tyList
                      (* ty should be all mono,
                         so the following should not be needed *)
                      val tyList = map TU.freshRigidInstTy tyList
                    in
                      (
                       TIC.bindVar
                         (lambdaDepth,
                          newContext,
                          funVar,
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
                (fn (({funVarInfo={path,id},tyList=_, rules=icmatch},(funTy, tyList)),
                     funBindListRev) =>
                    let
                      val argTyList = argTyListOfMatch icmatch
                      val funVarInfo = {path=path, id=id, ty=funTy}
                      val (tpmatchTy, tpmatch) =
                          monoTypeinfMatch
                            lambdaDepth argTyList newContext icmatch
                      fun curryTy (T.FUNMty(argTyList, ty)) =
                          foldr
                            (fn (ty, body) => T.FUNMty([ty], body))
                            ty
                            argTyList
                        | curryTy ty = ty
                      val funType = curryTy (TU.derefTy tpmatchTy)
                      val tyEquations = map (fn x => (funTy, x)) (funType::tyList)
                      val _ =
                          U.unify tyEquations
                          handle U.Unify =>
                                 E.enqueueError "Typeinf 060"
                                   (
                                    loc,
                                    E.RecDefinitionAndOccurrenceNotAgree
                                      ("058",
                                       {
                                        id = String.concatWith "." path,
                                        definition = funType,
                                        occurrence = funTy
                                       }
                                      )
                                   )
                    in
                      {
                       funVarInfo = funVarInfo,
                       bodyTy = case TU.derefTy tpmatchTy of
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
                   (fn ({funVarInfo={path, id, ty},...}, tyFields) =>
                       LabelEnv.insert(tyFields, String.concat path, ty))
                   LabelEnv.empty
                   funBindList)

          val {boundEnv, ...} = generalizer (TypesOfAllElements, lambdaDepth)

          val _ =
              TvarMap.appi
                (fn ({name, id, eq, lifted}, ref (T.SUBSTITUTED ty)) =>
                    (case TU.derefSubstTy ty of
                       T.BOUNDVARty _ => ()
                     | T.TYVARty (tvstateRef as ref (T.TVAR {eqKind,...}))
                       =>
                       E.enqueueError "Typeinf 061"
                         (loc,
                          E.UserTvarNotGeneralized
                            ("059",{utvarName =
                                    (case eqKind of A.EQ => "''"
                                                  | A.NONEQ  => "'")
                                    ^ name}))
                     | _ =>
                       (
                        T.printTy ty;
                        raise
                          bug
                            "illeagal utvar instance in\
                            \ UserTvarNotGeneralized  check"
                       )
                    )
                  | ({name, id, eq, lifted}, ref (T.TVAR {eqKind,...}))  =>
                    E.enqueueError "Typeinf 062"
                      (loc,
                       E.UserTvarNotGeneralized
                         ("060",
                          {
                           utvarName =
                           (case eqKind of A.EQ => "''" | A.NONEQ  => "'")
                           ^ name
                          }
                         )
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
                  funVarInfo as {path, id, ty},
                  argTyList,
                  bodyTy,
                  ruleList
                 },
                 newContext) =>
                   TIC.bindVar
                     (
                      lambdaDepth,
                      newContext,
                      {path=path, id=id},
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
               (fn ({funVarInfo={path, id, ty}, argTyList,...},
                    newContext) =>
                   TIC.bindVar
                     (
                      lambdaDepth,
                      newContext,
                      {path=path, id=id},
                        TC.RECFUNID
                          (
                           {path=path,
                            id=id,
                            ty=T.POLYty{boundtvars=boundEnv, body = ty}},
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
               (IC.ICPATVAR(funVarInfo,loc))
               tyList
           val icdecls =
             case rules of
               {args = [pat], body} :: _ =>
               [(funPat, IC.ICFNM(rules, loc))]
             | [{args=patList as (pat::_), body}] =>
               let
                 val firstLoc = IC.getLocPat pat
                 val lastLoc = IC.getLocPat (List.last patList)
                 val patFields = makeTupleFields patList
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
                (fn ({varInfo = var as {path,id}, tyList, body},
                     (recbinds, newContext)) =>
                    let
                      val ty = T.newtyWithLambdaDepth (lambdaDepth, T.univKind)
                      val varInfo = {path=path, id=id, ty=ty}
                      val tyList = map (ITy.evalIty context) tyList
                      (* ty should be all mono,
                         so the following should not be needed *)
                      val tyList = map TU.freshRigidInstTy tyList
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
                fun inferRule (varInfo as {path, ty, id}, tyList, icexp) =
                    let
                      val (icexpTy, tpexp) =
                          typeinfExp lambdaDepth inf newContext icexp
                      val tyEquations = map (fn x => (ty, x)) (icexpTy::tyList)
                      val _ =
                          U.unify tyEquations
                          handle
                          U.Unify =>
                          E.enqueueError "Typeinf 063"
                            (
                             loc,
                             E.RecDefinitionAndOccurrenceNotAgree
                               ("061",
                                {
                                 id = String.concatWith "." path,
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
                   (fn ({var={path,ty,id},...}, tyFields) =>
                       LabelEnv.insert(tyFields, String.concatWith "." path, ty))
                   LabelEnv.empty
                   varInfoTyTpexpList)
          val {boundEnv, ...} =
              generalizer (TypesOfAllElements, lambdaDepth)
          val _ =
              TvarMap.appi
                (fn ({name,...}, ref (T.SUBSTITUTED (T.BOUNDVARty _))) =>()
                  | ({name,...}, ref (T.TVAR{eqKind,...}))  =>
                    E.enqueueError "Typeinf 064"
                      (loc,
                       E.UserTvarNotGeneralized
                         ("062",
                          {utvarName =
                           (case eqKind of A.EQ => "''" | A.NONEQ  => "'")
                           ^ name}
                         )
                      )
                  | _ =>
                    raise
                      bug
                        "illeagal utvar instance in\
                        \ UserTvarNotGeneralized  check"
                )
                addedUtvars
        in
          if BoundTypeVarID.Map.isEmpty boundEnv
          then
            (
             foldl
               (fn ({var=varInfo as {path,id,ty},...}, newContext) =>
                   TIC.bindVar
                     (
                      lambdaDepth,
                      newContext,
                      {path=path, id=id},
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
               (fn ({var={path, id, ty},...}, newContext) =>
                   TIC.bindVar
                     (
                      lambdaDepth,
                      newContext,
                      {path=path, id=id},
                      TC.VARID {path=path,
                                 id=id,
                                 ty= T.POLYty{boundtvars = boundEnv, body = ty}
                                 }
                     )
               )
               TIC.emptyContext
               varInfoTyTpexpList,
             [TC.TPVALPOLYREC (boundEnv, varInfoTyTpexpList, loc)]
            )
        end
      | IC.ICEXND (exnconLocList, loc) =>
        (TIC.emptyContext,
         [TC.TPEXD
            (map
               (fn {exnInfo = {path, id, ty=ity}, loc} =>
                   {exnInfo={path=path,
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
      | IC.ICEXNTAGD ({exnInfo={path, id, ty=ity}, varInfo},loc) =>
        let
          val varInfo =
              case VarMap.find(#varEnv context, varInfo)  of
                SOME (TC.VARID varInfo) => varInfo
              | SOME (TC.RECFUNID _) =>
                raise bug "recfunvar in ICEXNTAGD"
              | NONE =>
                if E.isError() then raise Fail
                else raise bug "var not found (2)"
        in
          (TIC.emptyContext,
           [TC.TPEXNTAGD
              (
               {exnInfo = {path=path,id=id,
                           ty=ITy.evalIty context ity
                              handle e => (P.print "ity33\n"; raise e)
                          },
                varInfo = varInfo},
               loc
              )
           ]
           )
        end
      | IC.ICEXPORTFUNCTOR (var as {path, id}, ity, loc) =>
       (
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
          val ty1 = ITy.evalIty context ity handle e => (P.print "ity34\n"; raise e)
          val (ty2, tpdecl) =
              case VarMap.find(#varEnv context, var) of
                     SOME (idstatus as TC.VARID {ty,...}) =>
                     (ty, TC.TPEXPORTVAR {internalVar={ty=ty, id=id, path=path}, 
                                          externalVar = {ty=ty, path=path},
                                          loc=loc}
                     )
                   | SOME (TC.RECFUNID({ty,...},_)) =>
                     raise bug "RECFUNID for functor"
                   | NONE =>raise bug "var not found (3)"
        in
          if U.eqTy  BoundTypeVarID.Map.empty (ty1, ty2) then
            (TIC.emptyContext, [tpdecl])
          else
            let
              val _ = P.print "ICEXPORTFUNCTOR: noneq:"
              val _ = P.print (String.concatWith "." path)
              val _ = P.print "\n"
              val tpexp = TC.TPVAR ({path=path,id=id,ty=ty2},loc)
              fun checkPoly (polyList, actualPolyList) =
                  if U.eqTyList
                       BoundTypeVarID.Map.empty (polyList,actualPolyList) then ()
                  else
                    (E.enqueueError
                       "Typeinf 065"
                       (loc, E.TypeAnnotationNotAgree
                               ("063-1",{ty=ty2,annotatedTy=ty1}));
                     raise Fail
                    )
              val (context, decls) =
                  case ty1 of
                    (* 1. TYPOLY(btvs,TYFUNM([firstArgty],TYFUNM(polyList,body)))*)
                    T.POLYty{boundtvars,
                             body=
                             toBodyTy
                               as T.FUNMty([first],T.FUNMty(polyTys,bodyTy))} =>
                    let
                      val (ty22, tpexp) = TCU.freshToplevelInst(ty2,tpexp)
                    in
                      (case ty22 of
                         T.FUNMty([actualFirst],
                                  T.FUNMty(actualPolyTys,actualBodyTy))=>
                         (let
                            val _ = U.unify[(actualFirst, first)]
                                handle
                                U.Unify =>
                                (E.enqueueError
                                   "Typeinf 066"
                                   (loc, E.TypeAnnotationNotAgree
                                           ("063-2",{ty=ty2,annotatedTy=ty1}));
                                 raise Fail
                                )
                            val _ = checkPoly (actualPolyTys, polyTys)
                            val firstVar = TCU.newTCVarInfo first
                            val firstExp = TC.TPVAR (firstVar, loc)
                            val polyVars = map TCU.newTCVarInfo polyTys
                            val polyExps = map (fn x => TC.TPVAR(x, loc)) polyVars
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
                            val newBodyExp =
                                TIU.coerceTy(bodyExp,actualBodyTy,bodyTy,loc)
                                handle
                                TIU.CoerceTy =>
                                (E.enqueueError
                                   "Typeinf 067"
                                   (loc, E.TypeAnnotationNotAgree
                                           ("063-3",{ty=ty2,annotatedTy=ty1}));
                                 raise Fail
                                )
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
                            val newVar = {id=VarID.generate(), path=path, ty=ty1}
                            val newExternalVar = {path=path, ty=ty1}
                            val newDecl = TC.TPVAL([(newVar, tpexp)], loc)
                            val newIdstatus = TC.VARID newVar
                          in
                            (TIC.emptyContext,
                             [newDecl,
                              TC.TPEXPORTVAR {internalVar = newVar, 
                                              externalVar=newExternalVar,
                                              loc=loc}]
                            )
                          end
                         )
                       | _ =>
                         (E.enqueueError
                            "Typeinf 068"
                            (loc, E.TypeAnnotationNotAgree
                                    ("063-4",{ty=ty2,annotatedTy=ty1}));
                          raise Fail
                         )
                      )
                    end
                  | (* 2. TYPOLY(btvs, TYFUNM([firstArgty], body)) *)
                    T.POLYty{boundtvars,
                             body =
                             toBodyTy
                               as
                               T.FUNMty([first as T.FUNMty _], bodyTy)} =>
                    let
                      val (ty22, tpexp) = TCU.freshToplevelInst(ty2,tpexp)
                    in
                      (case ty22 of
                         T.FUNMty([fromFirst], fromBodyTy) =>
                         let
                           val _ = U.unify[(fromFirst, first)]
                               handle
                               U.Unify =>
                               (E.enqueueError
                                  "Typeinf 069"
                                  (loc, E.TypeAnnotationNotAgree
                                          ("063-5",{ty=ty2,annotatedTy=ty1}));
                                raise Fail
                               )
                           val firstVar = TCU.newTCVarInfo first
                           val firstExp = TC.TPVAR (firstVar, loc)
                           val bodyExp =
                               TC.TPAPPM{funExp=tpexp,
                                         funTy=ty22,
                                         argExpList=[firstExp],
                                         loc=loc}
                           val newBodyExp =
                               TIU.coerceTy(bodyExp,fromBodyTy,bodyTy,loc)
                               handle
                               TIU.CoerceTy =>
                               (E.enqueueError
                                  "Typeinf 070"
                                  (loc, E.TypeAnnotationNotAgree
                                          ("063-6-1",{ty=ty2,annotatedTy=ty1}));
                                raise Fail
                               )
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
                           val newVar = {id=VarID.generate(), path=path, ty=ty1}
                           val newExternalVar = {path=path, ty=ty1}
                           val newDecl = TC.TPVAL([(newVar, tpexp)], loc)
                           val exportDecl = 
                               TC.TPEXPORTVAR
                                 {internalVar = newVar,
                                  externalVar = newExternalVar,
                                  loc=loc}
                         in
                           (TIC.emptyContext, [newDecl,exportDecl]
                           )
                         end
                       | _ =>
                         (E.enqueueError
                            "Typeinf 071"
                            (loc, E.TypeAnnotationNotAgree
                                    ("063-6-2",{ty=ty2,annotatedTy=ty1}));
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
                          val polyVars = map TCU.newTCVarInfo polyTys
                          val polyExps = map (fn x => TC.TPVAR(x, loc)) polyVars
                          val bodyExp =
                              TC.TPAPPM{funExp=tpexp,
                                        funTy=T.FUNMty(actualPolyTys,actualBodyTy),
                                        argExpList=polyExps,
                                        loc=loc}
                          val newBodyExp =
                              TIU.coerceTy (bodyExp, actualBodyTy, bodyTy, loc)
                              handle
                              TIU.CoerceTy =>
                              (E.enqueueError
                                 "Typeinf 072"
                                 (loc, E.TypeAnnotationNotAgree
                                         ("063-7",{ty=ty2,annotatedTy=ty1}));
                               raise Fail
                              )
                          val newTpexp =
                              TC.TPFNM {argVarList=polyVars,
                                        bodyExp=newBodyExp,
                                        bodyTy=bodyTy,
                                        loc=loc}
                          val newVar = {id=VarID.generate(), path=path, ty=ty1}
                          val newExternalVar = {path=path, ty=ty1}
                          val newDecl = TC.TPVAL([(newVar, tpexp)], loc)
                          val exportDecl = 
                              TC.TPEXPORTVAR
                                {internalVar=newVar,
                                 externalVar=newExternalVar, 
                                 loc=loc}
                        in
                          (TIC.emptyContext, [newDecl, exportDecl]
                          )
                        end
                       )
                     | _ =>
                       (E.enqueueError
                          "Typeinf 073"
                          (loc, E.TypeAnnotationNotAgree
                                  ("063-8",{ty=ty2,annotatedTy=ty1}));
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
            handle Fail => (TIC.emptyContext,nil)
        end
       )
      | IC.ICEXPORTTYPECHECKEDVAR (var as {path,id}, loc) =>
        let
          val (ty, tpdecl) =
              case VarMap.find(#varEnv context, var) of
                SOME (idstatus as TC.VARID {ty,...}) =>
                (ty, TC.TPEXPORTVAR{internalVar = {ty=ty, id=id, path=path}, 
                                    externalVar={ty=ty, path=path},
                                    loc=loc}
                )
              | SOME (idstatus as TC.RECFUNID({ty,...},arity)) =>
                (ty, TC.TPEXPORTRECFUNVAR{var={ty=ty, id=id, path=path}, 
                                          arity=arity,
                                          loc=loc}
                )
              | NONE => raise bug "var not found(4)"
        in
          (TIC.emptyContext, [tpdecl])
        end
      | IC.ICEXPORTVAR (var as {path, id}, ity, loc) =>
        let
          val ty1 = ITy.evalIty context ity handle e => (P.print "ity35\n"; raise e)
          val (ty2, tpdecl) =
              case VarMap.find(#varEnv context, var) of
                SOME (idstatus as TC.VARID {ty,...}) =>
                (ty, TC.TPEXPORTVAR{internalVar = {ty=ty, id=id, path=path}, 
                                    externalVar={ty=ty, path=path},
                                    loc=loc}
                )
              | SOME (idstatus as TC.RECFUNID({ty,...},arity)) =>
                (ty, TC.TPEXPORTRECFUNVAR{var={ty=ty, id=id, path=path}, 
                                          arity=arity,
                                          loc=loc}
                )
              | NONE => raise bug "var not found(4)"
        in
          if U.eqTy BoundTypeVarID.Map.empty (ty1, ty2) then
            (TIC.emptyContext, [tpdecl])
          else
            let
               val _ = P.print "ICEXPORTVAR: noneq:"
               val _ = P.print (String.concatWith "." path)
               val _ = P.print "\n"
               val _ = P.print "ty1:"
               val _ =  P.printTy ty1
               val _ =  P.print "\n"
               val _ =  P.print "ty2:"
               val _ =  P.printTy ty2
               val _ =  P.print "\n"
              val ty11 = TU.freshRigidInstTy ty1
            in
              if TU.monoTy ty2 then
                (U.unify [(ty11, ty2)];
                 (TIC.emptyContext, [tpdecl])
                )
                handle U.Unify =>
                       (E.enqueueError
                          "Typeinf 074"
                          (loc, E.TypeAnnotationNotAgree
                                  ("063-9",{ty=ty2,annotatedTy=ty11}));
                        (TIC.emptyContext,nil)
                       )
              else
                let
                  val tpexp = TC.TPVAR({path=path,id=id,ty=ty2},loc)
                  val tpexp = TIU.coerceTy(tpexp,ty2,ty1,loc)
                  val newVar = {path=path,id=VarID.generate(),ty=ty1}
                  val newDecl = TC.TPVAL([(newVar, tpexp)], loc)
                  val newTpdecl =
                      case tpdecl of
                        TC.TPEXPORTVAR {externalVar={path,...}, loc,...} =>
                        TC.TPEXPORTVAR {internalVar=newVar,
                                        (* 2012-9-10 bug inline *)
                                        externalVar={path=path, ty=ty1}, 
                                       loc=loc}
                      | TC.TPEXPORTRECFUNVAR {var, arity, loc} => 
                        TC.TPEXPORTRECFUNVAR {var=newVar,
                                              arity=arity,
                                              loc=loc}
                      | _ => raise bug "impossible"
                        
                in
                  (TIC.emptyContext, [newDecl, newTpdecl]
                  )
                end
                handle TIU.CoerceTy =>
                       (E.enqueueError
                          "Typeinf 075"
                          (loc, E.TypeAnnotationNotAgree
                                  ("063-10",{ty=ty2,annotatedTy=ty1}));
                        (TIC.emptyContext,nil)
                       )
            end
        end
      | IC.ICEXPORTEXN ({path, id, ty=ity}, loc) =>
        let
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity36\n"; raise e)
        in
          (TIC.emptyContext,
           [TC.TPEXPORTEXN ({path=path, id=id, ty=ty}, loc)]
           )
        end
      | IC.ICEXTERNVAR ({path, ty=ity}, loc) =>
        let
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity37\n"; 
                           P.print "path:\n";
                           P.printPath path;
                           raise e)
        in
          (TIC.emptyContext,
           [TC.TPEXTERNVAR ({path=path, ty=ty}, loc)]
           )
        end
      | IC.ICEXTERNEXN ({path, ty=ity}, loc) =>
        let
          val ty = ITy.evalIty context ity
              handle e => (P.print "ity38\n"; raise e)
        in
          (TIC.emptyContext,
           [TC.TPEXTERNEXN ({path=path, ty=ty}, loc)]
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
      | IC.ICOVERLOADDEF {boundtvars,id,path,overloadCase,loc} =>
        let
          val lambdaDepth = incDepth ()
          val (context, addedUtvars) =
              evalScopedTvars lambdaDepth context boundtvars loc

          fun substFTvar (subst as (ftvid, ty')) ty =
              case ty of
                T.SINGLETONty singletonTy =>
                raise Control.Bug "ICOVERLOADDEF: substFTvar"
              | T.ERRORty => ty
              | T.DUMMYty dummyTyID => ty
              | T.TYVARty (ref (T.TVAR {id,...})) =>
                if FreeTypeVarID.eq (ftvid, id) then ty' else ty
              | T.TYVARty (ref (T.SUBSTITUTED ty)) => substFTvar subst ty
              | T.BOUNDVARty n => ty
              | T.FUNMty (tyList, ty) =>
                T.FUNMty (map (substFTvar subst) tyList, substFTvar subst ty)
              | T.RECORDty tySenvMap =>
                T.RECORDty (LabelEnv.map (substFTvar subst) tySenvMap)
              | T.CONSTRUCTty {tyCon,args} =>
                T.CONSTRUCTty {tyCon=tyCon, args = map (substFTvar subst) args}
              | T.POLYty {boundtvars, body} =>
                T.POLYty {boundtvars=boundtvars, body = substFTvar subst body}

          fun typeinfOverloadMatch (tvId, expTy) {instTy, instance} =
              let
                val instTypId =
                    case TU.derefTy instTy of
                      T.CONSTRUCTty {tyCon={id,...}, ...} => id
                    | _ => raise bug "FIXME: user error: invalid instTy"
                val expectTy = substFTvar (tvId, instTy) expTy
                val (actualTy, keyList, branch) =
                    case instance of
                      IC.INST_OVERLOAD c => typeinfOverloadCase c
                    | IC.INST_EXVAR ({path, used, ty}, loc) =>
                      let
                        val ty = ITy.evalIty context ty
                            handle e => (P.print "ity39\n"; raise e)
                        val exVarInfo = {path = path, ty = ty}
                        val (monoTy, instTyList) = TIU.freshTopLevelInstTy ty
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
                        val (monoTy, instTyList) = TIU.freshTopLevelInstTy ty
                      in
                        (monoTy, nil,
                         T.OVERLOAD_PRIM {primInfo = primInfo,
                                          instTyList = instTyList})
                      end
                val _ =
                    U.unify [(expectTy, actualTy)]
                    handle U.Unify =>
                           E.enqueueError "Typeinf 076"
                             (loc,
                              E.TypeAnnotationNotAgree
                                ("064",{ty=actualTy,annotatedTy=expectTy}))
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
                      SOME (r as ref (T.TVAR {tvarKind=T.UNIV,id,...})) =>
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
                  T.OVERLOAD_EXVAR path =>
                  OPrimInstMap.insert (dst, fixKey key, match)
                | T.OVERLOAD_PRIM path =>
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
                            path = path,
                            keyTyList = keyTyList,
                            match = match,
                            instMap = instMap}]
          val _ =
              app (fn (r as ref (T.TVAR tvKind), instTys) =>
                      r := T.TVAR
                             {lambdaDepth = #lambdaDepth tvKind,
                              id = #id tvKind,
                              tvarKind = T.OPRIMkind {instances = instTys,
                                                      operators = selectors},
                              eqKind = #eqKind tvKind,
                              utvarOpt = #utvarOpt tvKind}
                    | _ => raise bug "ICOVERLOADDEF")
                  keyList
          val {boundEnv, ...} = generalizer (ty, lambdaDepth)
          val oprimTy =
              if BoundTypeVarID.Map.isEmpty boundEnv
              then ty else T.POLYty {boundtvars = boundEnv, body = ty}
          val oprimInfo =
              {ty = oprimTy, path = path, id = id}
        in
          (TIC.bindOPrim (TIC.emptyContext, oprimInfo), nil)
        end
    end

  fun typeinf {decls=icdecls, loc} =
      let
       (* 2012-7-11 ohori: to fix bug 195_dummtType.sml *)
        val startDummyTyId = ! TIU.dummyTyId
        val _ = E.initializeTypeinfError ()
        val _ = T.kindedTyvarList := nil
        val ({varEnv,...}, tpdecls) =
            typeinfDeclList T.toplevelDepth TIC.emptyContext icdecls
            handle Fail => (TIC.emptyContext,nil)
        val tpdecls =
            if E.isError() then
              tpdecls
            else
              let
                val _ = TIU.eliminateVacuousTyvars()
                fun isDummy ty =
                    let
                      exception DUMMY
                      fun visit ty =
                          case TU.derefTy ty of
                            T.SINGLETONty _ => ()
                          | T.ERRORty => ()
                            (* 2012-7-11 ohori: to fix bug 195_dummtType.sml *)
                          | T.DUMMYty id => if id >= startDummyTyId then raise DUMMY else ()
                          | T.TYVARty _ => ()
                          | T.BOUNDVARty _ => ()
                          | T.FUNMty (tyList, ty) =>
                            (app visit tyList; visit ty)
                          | T.RECORDty tySEnvMap => LabelEnv.app visit tySEnvMap
                          | T.CONSTRUCTty {tyCon, args} => app visit args
                          | T.POLYty {body,...} => visit body
                    in
                      (visit ty; false)
                      handle DUMMY => true
                    end
                val dummyTyPaths =
                    VarMap.foldli
                      (fn ({id, path}, TC.VARID {ty,...}, paths) =>
                          if isDummy ty then path::paths
                          else paths
                        | ({id, path},TC.RECFUNID ({ty,...},_),paths) =>
                          if isDummy ty then path::paths
                          else paths
                      )
                      nil
                      varEnv
                val _ =
                    case dummyTyPaths of
                      nil => ()
                    | _ =>
                      E.enqueueWarning
                        (loc, E.ValueRestriction("065",{dummyTyPaths=dummyTyPaths}))
(* FIXME: do we need the following?
                val _ = List.app (fn (ty as T.TYVARty(ref(T.TVAR _)), loc) =>
                                     E.enqueueError "Typeinf 077" (loc, E.FFIInvalidTyvar ty)
                                   | _ => ())
                                 (!ffiApplyTyvars)
*)
              in
                tpdecls
              end
        val errors = E.getErrors ()
      in
        case errors of
          [] => (varEnv, tpdecls, E.getWarnings())
        | errors =>
          let
            val errorsAndWornings = E.getErrorsAndWarnings ()
          in
            raise UE.UserErrors (errorsAndWornings)
          end
      end

end
end
