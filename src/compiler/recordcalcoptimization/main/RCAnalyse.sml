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
  type varInfo = T.varInfo

  fun bug s = Control.Bug ("RCAnalyse: " ^ s)
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
           ruleList:(T.conInfo * varInfo option * rcexp) list} =>
         (visitExp defaultExp;
          visitExp exp;
          visitExpList (map #3 ruleList))
      | RC.RCCAST (rcexp, ty, loc) => visitExp rcexp
      | RC.RCCONSTANT {const, loc, ty} => ()
      | RC.RCDATACONSTRUCT
          {argExpOpt = NONE,
           argTyOpt,
           con:T.conInfo, 
           instTyList, 
           loc
          } => 
        ()
      | RC.RCDATACONSTRUCT
          {argExpOpt = SOME exp,
           argTyOpt,
           con:T.conInfo, 
           instTyList, 
           loc
          } =>
        visitExp exp
      | RC.RCEXNCASE {defaultExp:rcexp, exp:rcexp, expTy:ty, loc:Loc.loc,
                      ruleList:(TC.exnCon * varInfo option * rcexp) list} =>
        (visitExp defaultExp;
         visitExp exp;
         visitExpList (map #3 ruleList))
      | RC.RCEXNCONSTRUCT
          {argExpOpt = NONE,
           exn:TC.exnCon,
           instTyList,
           loc
          } =>
        ()
      | RC.RCEXNCONSTRUCT
          {argExpOpt = SOME exp,
           exn:TC.exnCon,
           instTyList,
           loc
          } =>
        visitExp exp
      | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} => 
        ()
      | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
        ()
      | RC.RCEXVAR ({path, ty}, loc) => ()
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, ptrExp:rcexp}, ty, loc) =>
        visitExp ptrExp
      | RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
        visitExp bodyExp
      | RC.RCGLOBALSYMBOL {kind, loc, name, ty} =>
        ()
      | RC.RCHANDLE {exnVar, exp, handler, loc} =>
        (visitExp exp; visitExp handler)
      | RC.RCLET {body:rcexp list, decls, loc, tys} =>
        (visitExpList body;
         visitDeclList decls)
      | RC.RCMODIFY {elementExp, elementTy, indexExp, label, loc, recordExp, recordTy} =>
        (visitExp elementExp;
         visitExp indexExp;
         visitExp recordExp)
      | RC.RCMONOLET {binds:(T.varInfo * rcexp) list, bodyExp, loc} =>
        (visitExpList (map #2 binds);
         visitExp bodyExp)
      | RC.RCOPRIMAPPLY {argExp, instTyList, loc, oprimOp:T.oprimInfo} =>
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
      | RC.RCSQL (RC.RCSQLSERVER 
                    {schema:Types.ty LabelEnv.map LabelEnv.map,
                     server:string}, 
                  ty, 
                  loc) =>
        ()
      | RC.RCTAPP {exp, expTy, instTyList, loc} =>
        visitExp exp
      | RC.RCVAR (varInfo, loc) =>
        inc (#id varInfo)
      | RC.RCEXPORTCALLBACK {foreignFunTy:Types.foreignFunTy, funExp:rcexp,
                             loc:Loc.loc} =>
        visitExp funExp
      | RC.RCFOREIGNAPPLY {argExpList:rcexp list,
                           foreignFunTy:Types.foreignFunTy, funExp:rcexp,
                           loc:Loc.loc} =>
        (visitExpList argExpList;
         visitExp funExp)
      | RC.RCINDEXOF (string, ty, loc) => ()
      | RC.RCSWITCH {branches:(Absyn.constant * rcexp) list, defaultExp:rcexp,
                     expTy:Types.ty, loc:Loc.loc, switchExp:rcexp} =>
        (visitExpList (map #2 branches);
         visitExp defaultExp;
         visitExp switchExp)
      | RC.RCTAGOF (ty, loc) => ()
  and visitRecordField exp =
      case exp of
        RC.RCCONSTANT {const, loc, ty} => ()
      | RC.RCVAR (var, loc) => incInf (#id var)
      | RC.RCEXVAR (exVarInfo, loc) => ()
      | RC.RCGLOBALSYMBOL {kind, loc, name, ty} => ()
      | _ => visitExp exp
  and visitExpList expList = List.app visitExp expList
  and visitDecl tpdecl =
      case tpdecl of
         RC.RCEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
         ()
       | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
         ()
       | RC.RCEXPORTEXN (exnInfo, loc) =>
         ()
       | RC.RCEXPORTVAR {internalVar, externalVar, loc} =>
         incInf (#id internalVar)
       | RC.RCEXTERNEXN ({path, ty}, loc) =>
         ()
       | RC.RCEXTERNVAR ({path, ty}, loc) =>
         ()
       | RC.RCVAL (binds:(T.varInfo * rcexp) list, loc) =>
         visitExpList (map #2 binds)
       | RC.RCVALPOLYREC
           (btvEnv,
            recbinds:{exp:rcexp, expTy:ty, var:T.varInfo} list,
            loc) =>
         visitExpList (map #exp recbinds)
       | RC.RCVALREC (recbinds:{exp:rcexp, expTy:ty, var:T.varInfo} list,loc) =>
         visitExpList (map #exp recbinds)
  and visitDeclList declList = List.app visitDecl declList
in
  fun analyseDeclList declList = 
      (countMapRef := VarID.Map.empty;
       visitDeclList declList;
       !countMapRef)
end
end
