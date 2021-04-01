(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
(* Efficient size calculation throug depth-first travasal.
*)
structure RCAnalyse =
struct
  datatype count = INF | FIN of int
local
  (* structure TC = TypedCalc *)
  structure RC = RecordCalc
  structure T = Types
  type rcexp = RC.rcexp
  type ty = T.ty
  type varInfo = RC.varInfo

  fun bug s = Bug.Bug ("RCAnalyse: " ^ s)
  fun countAdd (INF,_ ) = INF
    | countAdd (_, INF) = INF
    | countAdd (FIN i, FIN j) = FIN (i+j)
  val countMapRef = ref VarID.Map.empty : (count VarID.Map.map) ref
  fun inc var =
      let
        val countMap =
            VarID.Map.unionWith
              countAdd
              (!countMapRef, VarID.Map.singleton(var, FIN 1))
      in
        countMapRef := countMap
      end
  fun incInf var =
      let
        val countMap =
            VarID.Map.unionWith
              countAdd
              (!countMapRef, VarID.Map.singleton(var, INF))
      in
        countMapRef := countMap
      end

  fun visitExp exp =
      case exp of
        RC.RCAPPM {argExpList, funExp, funTy, loc} =>
        (visitExpList argExpList; 
         visitExp funExp)
      | RC.RCCASE 
          {defaultExp:rcexp, 
           exp:rcexp, 
           expTy:Types.ty, 
           loc:Loc.loc,
           ruleList:(RC.conInfo * varInfo option * rcexp) list,
           resultTy} =>
         (visitExp defaultExp;
          visitExp exp;
          visitExpList (map #3 ruleList))
      | RC.RCCAST ((rcexp, expTy), ty, loc) => visitExp rcexp
      | RC.RCCONSTANT {const, loc, ty} => ()
      | RC.RCDATACONSTRUCT
          {argExpOpt = NONE,
           con:RC.conInfo, 
           instTyList, 
           loc
          } => 
        ()
      | RC.RCDATACONSTRUCT
          {argExpOpt = SOME exp,
           con:RC.conInfo, 
           instTyList, 
           loc
          } =>
        visitExp exp
      | RC.RCEXNCASE {defaultExp:rcexp, exp:rcexp, expTy:ty, loc:Loc.loc,
                      ruleList:(RC.exnCon * varInfo option * rcexp) list,
                      resultTy} =>
        (visitExp defaultExp;
         visitExp exp;
         visitExpList (map #3 ruleList))
      | RC.RCEXNCONSTRUCT
          {argExpOpt = NONE,
           exn:RC.exnCon,
           loc
          } =>
        ()
      | RC.RCEXNCONSTRUCT
          {argExpOpt = SOME exp,
           exn:RC.exnCon,
           loc
          } =>
        visitExp exp
      | RC.RCEXNTAG {exnInfo, loc} => 
        ()
      | RC.RCEXEXNTAG {exExnInfo, loc} =>
        ()
      | RC.RCEXVAR {path, ty} => ()
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, funExp=RC.RCFFIFUN (ptrExp, _)}, ty, loc) =>
        visitExp ptrExp
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, funExp=RC.RCFFIEXTERN _}, ty, loc) =>
        ()
      | RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
        visitExp bodyExp
      | RC.RCFOREIGNSYMBOL {loc, name, ty} =>
        ()
      | RC.RCHANDLE {exnVar, exp, handler, resultTy, loc} =>
        (visitExp exp; visitExp handler)
      | RC.RCCATCH {catchLabel, argVarList, catchExp, tryExp, resultTy, loc} =>
        (visitExp catchExp; visitExp tryExp)
      | RC.RCTHROW {catchLabel, argExpList, resultTy, loc} =>
        visitExpList argExpList
      | RC.RCLET {body, decls, loc} =>
        (visitExp body;
         visitDeclList decls)
      | RC.RCMODIFY {elementExp, elementTy, indexExp, label, loc, recordExp, recordTy} =>
        (visitExp elementExp;
         visitExp indexExp;
         visitExp recordExp)
      | RC.RCOPRIMAPPLY {argExp, instTyList, loc, oprimOp:RC.oprimInfo} =>
        visitExp argExp
      | RC.RCPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
        visitExp exp
      | RC.RCPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
        visitExp argExp
      | RC.RCRAISE {exp, loc, ty} =>
        visitExp exp
      | RC.RCRECORD {fields:rcexp RecordLabel.Map.map, loc, recordTy} =>
        RecordLabel.Map.app visitRecordField fields
      | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} =>
        (visitExp exp; visitExp indexExp)
      | RC.RCSIZEOF (ty, loc) => ()
      | RC.RCREIFYTY (ty, loc) => ()
      | RC.RCTAPP {exp, expTy, instTyList, loc} =>
        visitExp exp
      | RC.RCVAR varInfo =>
        inc (#id varInfo)
      | RC.RCCALLBACKFN {attributes, resultTy, argVarList, bodyExp:rcexp,
                         loc:Loc.loc} =>
        visitExp bodyExp
      | RC.RCFOREIGNAPPLY {argExpList:rcexp list,
                           attributes, resultTy, funExp:rcexp,
                           loc:Loc.loc} =>
        (visitExpList argExpList;
         visitExp funExp)
      | RC.RCINDEXOF (string, ty, loc) => ()
      | RC.RCSWITCH {branches:(RC.constant * rcexp) list, defaultExp:rcexp,
                     expTy:Types.ty, loc:Loc.loc, switchExp:rcexp, resultTy} =>
        (visitExpList (map #2 branches);
         visitExp defaultExp;
         visitExp switchExp)
      | RC.RCTAGOF (ty, loc) => ()
      | RC.RCJOIN {isJoin, ty,args=(arg1,arg2),argTys,loc} =>
        (visitExp arg1;
         visitExp arg2)
      | RC.RCDYNAMIC _ => raise bug "RCDYNAMIC to RCAnalye"
      | RC.RCDYNAMICIS _ => raise bug "RCDYNAMICIS to RCAnalye"
      | RC.RCDYNAMICNULL _ => raise bug "RCDYNAMICNULL to RCAnalye"
      | RC.RCDYNAMICTOP _ => raise bug "RCDYNAMICTOP to RCAnalye"
      | RC.RCDYNAMICVIEW _ => raise bug "RCDYNAMICVIEW to RCAnalye"
      | RC.RCDYNAMICCASE _ => raise bug "RCDYNAMICCASE to RCAnalye"
      | RC.RCDYNAMICEXISTTAPP _ => raise bug "RCDYNAMICEXISTTAPP to RCAnalye"

  and visitRecordField exp =
      case exp of
        RC.RCCONSTANT {const, loc, ty} => ()
      | RC.RCVAR var => incInf (#id var)
      | RC.RCEXVAR exVarInfo => ()
      | RC.RCFOREIGNSYMBOL {loc, name, ty} => ()
      | _ => visitExp exp
  and visitExpList expList = List.app visitExp expList
  and visitDecl tpdecl =
      case tpdecl of
         RC.RCEXD (exnInfo, loc) =>
         ()
       | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
         ()
       | RC.RCEXPORTEXN exnInfo =>
         ()
       | RC.RCEXPORTVAR {var, exp} =>
         visitExp exp
       | RC.RCEXTERNEXN ({path, ty}, provider) =>
         ()
       | RC.RCBUILTINEXN {path, ty} =>
         ()
       | RC.RCEXTERNVAR ({path, ty}, provider) =>
         ()
       | RC.RCVAL (bind:(varInfo * rcexp), loc) =>
         visitExp (#2 bind)
       | RC.RCVALPOLYREC
           (btvEnv,
            recbinds:{exp:rcexp, var:varInfo} list,
            loc) =>
         visitExpList (map #exp recbinds)
       | RC.RCVALREC (recbinds:{exp:rcexp, var:varInfo} list,loc) =>
         visitExpList (map #exp recbinds)
  and visitDeclList declList = List.app visitDecl declList
in
  fun analyseDeclList declList = 
      (countMapRef := VarID.Map.empty;
       visitDeclList declList;
       !countMapRef)
end
end
