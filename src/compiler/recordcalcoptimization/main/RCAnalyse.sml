(* Efficient size calculation throug depth-first travasal.
*)
structure RCAnalyse =
struct
  datatype count = INF | FIN of int
local
  structure TC = TypedCalc
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
           argTyOpt,
           con:RC.conInfo, 
           instTyList, 
           loc
          } => 
        ()
      | RC.RCDATACONSTRUCT
          {argExpOpt = SOME exp,
           argTyOpt,
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
           instTyList,
           loc
          } =>
        ()
      | RC.RCEXNCONSTRUCT
          {argExpOpt = SOME exp,
           exn:RC.exnCon,
           instTyList,
           loc
          } =>
        visitExp exp
      | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} => 
        ()
      | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
        ()
      | RC.RCEXVAR {path, ty} => ()
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, funExp=RC.RCFFIFUN ptrExp}, ty, loc) =>
        visitExp ptrExp
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, funExp=RC.RCFFIEXTERN _}, ty, loc) =>
        ()
      | RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
        visitExp bodyExp
      | RC.RCFOREIGNSYMBOL {loc, name, ty} =>
        ()
      | RC.RCHANDLE {exnVar, exp, handler, resultTy, loc} =>
        (visitExp exp; visitExp handler)
      | RC.RCLET {body:rcexp list, decls, loc, tys} =>
        (visitExpList body;
         visitDeclList decls)
      | RC.RCMODIFY {elementExp, elementTy, indexExp, label, loc, recordExp, recordTy} =>
        (visitExp elementExp;
         visitExp indexExp;
         visitExp recordExp)
      | RC.RCMONOLET {binds:(varInfo * rcexp) list, bodyExp, loc} =>
        (visitExpList (map #2 binds);
         visitExp bodyExp)
      | RC.RCOPRIMAPPLY {argExp, instTyList, loc, oprimOp:RC.oprimInfo} =>
        visitExp argExp
      | RC.RCPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
        visitExp exp
      | RC.RCPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
        visitExp bodyExp
      | RC.RCPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
        visitExp argExp
      | RC.RCRAISE {exp, loc, ty} =>
        visitExp exp
      | RC.RCRECORD {fields:rcexp LabelEnv.map, loc, recordTy} =>
        LabelEnv.app visitRecordField fields
      | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} =>
        (visitExp exp; visitExp indexExp)
      | RC.RCSEQ {expList, expTyList, loc} =>
        visitExpList expList
      | RC.RCSIZEOF (ty, loc) => ()
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
      | RC.RCSWITCH {branches:(Absyn.constant * rcexp) list, defaultExp:rcexp,
                     expTy:Types.ty, loc:Loc.loc, switchExp:rcexp, resultTy} =>
        (visitExpList (map #2 branches);
         visitExp defaultExp;
         visitExp switchExp)
      | RC.RCTAGOF (ty, loc) => ()
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
         RC.RCEXD (exbinds:{exnInfo:RC.exnInfo, loc:Loc.loc} list, loc) =>
         ()
       | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
         ()
       | RC.RCEXPORTEXN exnInfo =>
         ()
       | RC.RCEXPORTVAR varInfo =>
         incInf (#id varInfo)
       | RC.RCEXTERNEXN {path, ty} =>
         ()
       | RC.RCEXTERNVAR {path, ty} =>
         ()
       | RC.RCVAL (binds:(varInfo * rcexp) list, loc) =>
         visitExpList (map #2 binds)
       | RC.RCVALPOLYREC
           (btvEnv,
            recbinds:{exp:rcexp, expTy:ty, var:varInfo} list,
            loc) =>
         visitExpList (map #exp recbinds)
       | RC.RCVALREC (recbinds:{exp:rcexp, expTy:ty, var:varInfo} list,loc) =>
         visitExpList (map #exp recbinds)
  and visitDeclList declList = List.app visitDecl declList
in
  fun analyseDeclList declList = 
      (countMapRef := VarID.Map.empty;
       visitDeclList declList;
       !countMapRef)
end
end
