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
      | TC.TPSWITCH {exp, expTy, ruleList, defaultExp, ruleBodyTy, loc} =>
        let
          fun visitBody {body, ...} = visitExp body
          fun visitRules (TC.CONSTCASE rules) = app visitBody rules
            | visitRules (TC.CONCASE rules) = app visitBody rules
            | visitRules (TC.EXNCASE rules) = app visitBody rules
        in
          visitExp exp;
          visitRules ruleList;
          visitExp defaultExp
        end
      | TC.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
        (visitExp tryExp;
         visitExp catchExp)
      | TC.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
        visitExpList argExpList
       | TC.TPCAST ((tpexp, expTy), ty, loc) =>
         visitExp tpexp
       | TC.TPCONSTANT {const, loc, ty} => ()
       | TC.TPDATACONSTRUCT
           {argExpOpt = NONE,
            con:T.conInfo, 
            instTyList, 
            loc
           } => 
         ()
       | TC.TPDATACONSTRUCT
           {argExpOpt = SOME exp,
            con:T.conInfo, 
            instTyList, 
            loc
           } =>
         visitExp exp
      | TC.TPDYNAMICCASE {groupListTerm, groupListTy, dynamicTerm, dynamicTy, elemTy, ruleBodyTy, loc} => 
        (visitExp groupListTerm; visitExp dynamicTerm)
      | TC.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
        (visitExp existInstMap; visitExp exp)
      | TC.TPERROR => ()
      | TC.TPEXNCONSTRUCT
          {argExpOpt = NONE,
           exn:TC.exnCon,
           loc
          } =>
        ()
      | TC.TPEXNCONSTRUCT
          {argExpOpt = SOME exp,
           exn:TC.exnCon,
           loc
          } =>
        visitExp exp
      | TC.TPEXNTAG {exnInfo, loc} => 
        ()
      | TC.TPEXEXNTAG {exExnInfo, loc} => 
        ()
      | TC.TPEXVAR exVarInfo => ()
      | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIFUN (ptrExp, _), stubTy} => 
        visitExp ptrExp
      | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIEXTERN _, stubTy} => ()
      | TC.TPFOREIGNSYMBOL _ => ()
      | TC.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        (visitExp funExp;
         visitExpList argExpList)
      | TC.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        visitExp bodyExp
      | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
        visitExp bodyExp
      | TC.TPHANDLE {exnVar, exp, handler, resultTy, loc} =>
        (visitExp exp; visitExp handler)
      | TC.TPLET {body, decls, loc} =>
        (visitExp body;
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
      | TC.TPOPRIMAPPLY {argExp, instTyList, loc, oprimOp} =>
        visitExp argExp
      | TC.TPPOLY {btvEnv, constraints, exp, expTyWithoutTAbs, loc} =>
        visitExp exp
      | TC.TPPRIMAPPLY {argExp, instTyList, loc, primOp} =>
        visitExp argExp
      | TC.TPRAISE {exp, loc, ty} =>
        visitExp exp
      | TC.TPRECORD {fields:TC.tpexp RecordLabel.Map.map, loc, recordTy} =>
        RecordLabel.Map.app visitRecordField fields
      | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
        visitExp exp
      | TC.TPSIZEOF (ty, loc) => ()
      | TC.TPTAPP {exp, expTy, instTyList, loc} =>
        visitExp exp
      | TC.TPVAR var => 
        inc (#id var)
      (* the following should have been eliminate *)
      | TC.TPRECFUNVAR {arity, var} =>
        inc (#id var)
      | TC.TPJOIN {isJoin, ty, args = (arg1, arg2), argtys, loc} =>
        (visitExp arg1; visitExp arg2)
      | TC.TPDYNAMIC {exp,ty,elemTy, coerceTy,loc} =>
        visitExp exp
      | TC.TPDYNAMICIS {exp,ty,elemTy, coerceTy,loc} =>
        visitExp exp
      | TC.TPDYNAMICVIEW {exp,ty,elemTy, coerceTy,loc} =>
        visitExp exp
      | TC.TPDYNAMICNULL {ty, coerceTy, loc} => ()
      | TC.TPDYNAMICTOP {ty, coerceTy, loc} => ()
      | TC.TPREIFYTY (ty,loc) => ()
  and visitRecordField exp =
      case exp of
        TC.TPVAR var => incInf (#id var)
      | TC.TPRECFUNVAR {arity, var} => incInf (#id var)
      | TC.TPCAST ((tpexp, expTy), ty, loc) => visitRecordField tpexp
      | _ => visitExp exp
  and visitExpList expList = List.app visitExp expList
  and visitDecl tpdecl =
      case tpdecl of
         TC.TPEXD (exnInfo, loc) =>
         ()
       | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
         ()
       | TC.TPEXPORTEXN exnInfo =>
         ()
       | TC.TPEXPORTVAR {var, exp} =>
         visitExp exp
       | TC.TPEXTERNEXN ({path, ty}, provider) =>
         ()
       | TC.TPBUILTINEXN {path, ty} =>
         ()
       | TC.TPEXTERNVAR ({path, ty}, provider) =>
         ()
       | TC.TPVAL (bind:(T.varInfo * TC.tpexp), loc) =>
         visitExp (#2 bind)
       | TC.TPVALPOLYREC {btvEnv,
                          constraints,
                          recbinds:{exp:TC.tpexp, var:T.varInfo} list,
                          loc} =>
         visitExpList (map #exp recbinds)
       | TC.TPVALREC (recbinds:{exp:TC.tpexp, var:T.varInfo} list,loc) =>
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
