structure TCAnalyse =
struct
datatype count = INF | FIN of int
local
  structure TC = TypedCalc
  structure T = Types
  fun bug s = Bug.Bug ("TypedCalcSize: " ^ s)
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
        TC.TPAPPM {argExpList, funExp, funTy, loc} =>
        (visitExpList argExpList; 
         visitExp funExp)
      | TC.TPCASEM
          {caseKind,
           expList,
           expTyList,
           loc,
           ruleBodyTy,
           ruleList} =>
         (visitExpList expList;
          visitExpList (map #body ruleList))
       | TC.TPCAST ((tpexp, expTy), ty, loc) =>
         visitExp tpexp
       | TC.TPCONSTANT {const, loc, ty} => ()
       | TC.TPDATACONSTRUCT
           {argExpOpt = NONE,
            argTyOpt,
            con:T.conInfo, 
            instTyList, 
            loc
           } => 
         ()
       | TC.TPDATACONSTRUCT
           {argExpOpt = SOME exp,
            argTyOpt,
            con:T.conInfo, 
            instTyList, 
            loc
           } =>
         visitExp exp
      | TC.TPERROR => ()
      | TC.TPEXNCONSTRUCT
          {argExpOpt = NONE,
           argTyOpt,
           exn:TC.exnCon,
           instTyList,
           loc
          } =>
        ()
      | TC.TPEXNCONSTRUCT
          {argExpOpt = SOME exp,
           argTyOpt,
           exn:TC.exnCon,
           instTyList,
           loc
          } =>
        visitExp exp
      | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} => 
        ()
      | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} => 
        ()
      | TC.TPEXVAR exVarInfo => ()
      | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIFUN ptrExp, stubTy} => 
        visitExp ptrExp
      | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIEXTERN _, stubTy} => ()
      | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
        visitExp bodyExp
      | TC.TPHANDLE {exnVar, exp, handler, resultTy, loc} =>
        (visitExp exp; visitExp handler)
      | TC.TPLET {body:TC.tpexp list, decls, loc, tys} =>
        (visitExpList body;
         visitDeclList decls)
      | TC.TPMODIFY
          {elementExp, 
           elementTy, 
           label, 
           loc, 
           recordExp, 
           recordTy
          } =>
        (visitExp elementExp;
         visitExp recordExp)
      | TC.TPMONOLET {binds:(T.varInfo * TC.tpexp) list, bodyExp, loc} =>
        (visitExpList (map #2 binds);
         visitExp bodyExp)
      | TC.TPOPRIMAPPLY {argExp, argTy, instTyList, loc, oprimOp} =>
        visitExp argExp
      | TC.TPPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
        visitExp exp
      | TC.TPPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
        visitExp bodyExp
      | TC.TPPRIMAPPLY {argExp, argTy, instTyList, loc, primOp} =>
        visitExp argExp
      | TC.TPRAISE {exp, loc, ty} =>
        visitExp exp
      | TC.TPRECORD {fields:TC.tpexp LabelEnv.map, loc, recordTy} =>
        LabelEnv.app visitRecordField fields
      | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
        visitExp exp
      | TC.TPSEQ {expList, expTyList, loc} =>
        visitExpList expList
      | TC.TPSIZEOF (ty, loc) => ()
      | TC.TPTAPP {exp, expTy, instTyList, loc} =>
        visitExp exp
      | TC.TPVAR var => 
        inc (#id var)
      (* the following should have been eliminate *)
      | TC.TPRECFUNVAR {arity, var} =>
        inc (#id var)
  and visitRecordField exp =
      case exp of
        TC.TPVAR var => incInf (#id var)
      | TC.TPRECFUNVAR {arity, var} => incInf (#id var)
      | TC.TPCAST ((tpexp, expTy), ty, loc) => visitRecordField tpexp
      | _ => visitExp exp
  and visitExpList expList = List.app visitExp expList
  and visitDecl tpdecl =
      case tpdecl of
         TC.TPEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
         ()
       | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
         ()
       | TC.TPEXPORTEXN exnInfo =>
         ()
       | TC.TPEXPORTVAR varInfo =>
        incInf (#id varInfo)
       | TC.TPEXPORTRECFUNVAR _ =>
         raise bug "TPEXPORTRECFUNVAR to Analyse"
       | TC.TPEXTERNEXN {longsymbol, ty} =>
         ()
       | TC.TPEXTERNVAR {longsymbol, ty} =>
         ()
       | TC.TPVAL (binds:(T.varInfo * TC.tpexp) list, loc) =>
         visitExpList (map #2 binds)
       | TC.TPVALPOLYREC (btvEnv,
                          recbinds:{exp:TC.tpexp, expTy:T.ty, var:T.varInfo} list,
                          loc) =>
         visitExpList (map #exp recbinds)
       | TC.TPVALREC (recbinds:{exp:TC.tpexp, expTy:T.ty, var:T.varInfo} list,loc) =>
         visitExpList (map #exp recbinds)
       (* the following should have been eliminate *)
       | TC.TPFUNDECL _ => raise bug "TPFUNDECL not eliminated"
       | TC.TPPOLYFUNDECL _  => raise bug "TPPOLYFUNDECL not eliminated"
  and visitDeclList declList = List.app visitDecl declList
in
  fun analyseDeclList declList = 
      (countMapRef := VarID.Map.empty;
       visitDeclList declList;
       !countMapRef)
end
end
