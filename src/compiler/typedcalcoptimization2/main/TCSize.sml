(* Efficient and accurate size calculation. *)
structure TCSize =
struct
local
  structure TC = TypedCalc
  structure T = Types
  structure A = Absyn
  fun bug s = Bug.Bug ("TypedCalcSize: " ^ s)

  exception Limit

  val limit = ref NONE : int option ref

  fun checkLimit n =
      case !limit of
        NONE => ()
      | SOME limit => if n > limit then raise Limit else ()

  fun constSize const =
      case const of
        A.INT _ => 1
      | A.WORD _ => 1
      | A.STRING (string, loc) => 1 + String.size string  div 4
      | A.REAL _ => 2
      | A.CHAR _ => 1
      | A.UNITCONST _ => 1
      | A.NULLCONST _ => 1

  fun inc n = n + 1
  fun incN (n,N) = n + N
  fun incConst (n, const) = n + (constSize const)
  fun incVar (n, vars) = n + (List.length vars)
  fun incBtvEnv (n, btvEnv) = n + (BoundTypeVarID.Map.numItems btvEnv)

  datatype items 
    = EXP of TC.tpexp list 
    | PAT of TC.tppat list
    | DECL of TC.tpdecl list
    | RULE of {args:TC.tppat list, body:TC.tpexp} list
    | BIND of (T.varInfo * TC.tpexp) list

  fun size n nil = n
    | size n (EXP nil :: items) = size n items
    | size n (EXP (exp::rest) :: items) = sizeExp n exp (EXP rest :: items)
    | size n (PAT nil :: items) = size n items
    | size n (PAT (pat::rest) :: items) = sizePat n pat (PAT rest :: items)
    | size n (DECL nil :: items) = size n items
    | size n (DECL (decl::rest) :: items) = sizeDecl n decl (DECL rest :: items)
    | size n (RULE nil :: items) = size n items
    | size n (RULE ({args,body}::rest) :: items) = 
      size n (PAT args :: EXP [body] :: RULE rest :: items)
    | size n (BIND nil :: items) = size n items
    | size n (BIND ((var,body)::rest) :: items) = 
      size (incVar (n, [var])) (EXP [body] :: BIND rest :: items)
  and sizeExp n exp items =
      (checkLimit n;
       case exp of
         TC.TPAPPM {argExpList, funExp, funTy, loc} =>
         size (inc n) (EXP (funExp::argExpList) :: items)
       | TC.TPCASEM
           {caseKind,
            expList,
            expTyList,
            loc,
            ruleBodyTy,
            ruleList} =>
         size (inc n) (EXP expList :: RULE ruleList :: items)
       | TC.TPCAST ((tpexp, expTy), ty, loc) => sizeExp (inc n) tpexp items
       | TC.TPCONSTANT {const, loc, ty} => size (incConst(n, const)) items
       | TC.TPDATACONSTRUCT
           {argExpOpt = NONE,
            argTyOpt,
            con:T.conInfo, 
            instTyList, 
            loc
           } => 
         size (inc n) items
       | TC.TPDATACONSTRUCT
           {argExpOpt = SOME exp,
            argTyOpt,
            con:T.conInfo, 
            instTyList, 
            loc
           } =>
         sizeExp (inc n) exp items
      | TC.TPERROR => size (inc n) items
      | TC.TPEXNCONSTRUCT
          {argExpOpt = NONE,
           argTyOpt,
           exn:TC.exnCon,
           instTyList,
           loc
          } =>
        size (inc n) items
      | TC.TPEXNCONSTRUCT
          {argExpOpt = SOME exp,
           argTyOpt,
           exn:TC.exnCon,
           instTyList,
           loc
          } =>
        sizeExp (inc n) exp items
      | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} => 
        size (inc n) items
      | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} => 
        size (inc n) items
      | TC.TPEXVAR exVarInfo => size (inc n) items
      | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIFUN ptrExp, stubTy} => 
        sizeExp (inc n) ptrExp items
      | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIEXTERN _, stubTy} => 
        size (inc n) items
      | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
        sizeExp (incVar (inc n, argVarList)) bodyExp items 
      | TC.TPHANDLE {exnVar, exp, handler, resultTy, loc} =>
        size (incVar (inc n, [exnVar])) (EXP [exp, handler]:: items)
      | TC.TPLET {body:TC.tpexp list, decls, loc, tys} =>
        size (inc n) (EXP body :: DECL decls :: items)
      | TC.TPMODIFY
          {elementExp, 
           elementTy, 
           label, 
           loc, 
           recordExp, 
           recordTy
          } =>
        size (inc n) (EXP [elementExp, recordExp] :: items)
      | TC.TPMONOLET {binds:(T.varInfo * TC.tpexp) list, bodyExp, loc} =>
        size (inc n) (BIND binds :: EXP [bodyExp] :: items)
      | TC.TPOPRIMAPPLY {argExp, argTy, instTyList, loc, oprimOp} =>
        sizeExp (inc n) argExp items
      | TC.TPPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
        sizeExp (incBtvEnv (inc n, btvEnv)) exp items
      | TC.TPPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
        sizeExp (incBtvEnv(incVar(inc n,argVarList),btvEnv)) bodyExp items
      | TC.TPPRIMAPPLY {argExp, argTy, instTyList, loc, primOp} =>
        sizeExp (inc n) argExp items
      | TC.TPRAISE {exp, loc, ty} => sizeExp (inc n) exp items
      | TC.TPRECORD {fields:TC.tpexp LabelEnv.map, loc, recordTy} =>
        size (inc n) (EXP (LabelEnv.listItems fields) :: items)
      | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
        sizeExp (inc n) exp items
      | TC.TPSEQ {expList, expTyList, loc} =>
        size (inc n) (EXP expList :: items)
      | TC.TPSIZEOF (ty, loc) => size (inc n) items
      | TC.TPTAPP {exp, expTy, instTyList, loc} =>
        sizeExp (inc n) exp items
      | TC.TPVAR varInfo => size (inc n) items
      (* the following should have been eliminate *)
      | TC.TPRECFUNVAR {arity, var} =>size (inc n) items
      )
  and sizePat n tppat items =
      (checkLimit n;
       case tppat of
         TC.TPPATCONSTANT (constant, ty, loc) =>
         size (incConst (n,constant)) items
       | TC.TPPATDATACONSTRUCT
           {argPatOpt = NONE,
            conPat:T.conInfo,
            instTyList, 
            loc,
            patTy
           } =>
         size (inc n) items
       | TC.TPPATDATACONSTRUCT
           {argPatOpt = SOME pat,
            conPat:T.conInfo,
            instTyList, 
            loc,
            patTy
           } =>
         sizePat (inc n) pat items
       | TC.TPPATERROR (ty, loc) => size (inc n) items
       | TC.TPPATEXNCONSTRUCT
           {argPatOpt = NONE,
            exnPat:TC.exnCon,
            instTyList,
            loc,
            patTy
           } =>
         size (inc n) items
       | TC.TPPATEXNCONSTRUCT 
           {argPatOpt = SOME pat,
            exnPat:TC.exnCon,
            instTyList, 
            loc,
            patTy
           } =>
         sizePat (inc n) pat items
      | TC.TPPATLAYERED {asPat, loc, varPat} =>
         size (inc n) (PAT [asPat, varPat] :: items)
      | TC.TPPATRECORD {fields:TC.tppat LabelEnv.map, loc, recordTy} =>
        size (inc n) (PAT (LabelEnv.listItems fields) :: items)
      | TC.TPPATVAR varInfo => size (inc n) items 
      | TC.TPPATWILD (ty, loc) => size (inc n) items
      )
  and sizeDecl n tpdecl items =
      (checkLimit n;
       case tpdecl of
         TC.TPEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
         size (incN (n, length exbinds)) items 
       | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
         size (inc n) items 
       | TC.TPEXPORTEXN exnInfo =>
         size (inc n) items 
       | TC.TPEXPORTVAR varInfo =>
         size (inc n) items 
       | TC.TPEXPORTRECFUNVAR {var, arity} =>
         size (inc n) items 
       | TC.TPEXTERNEXN {longsymbol, ty} =>
         size (inc n) items 
       | TC.TPEXTERNVAR {longsymbol, ty} =>
         size (inc n) items 
       | TC.TPVAL (binds:(T.varInfo * TC.tpexp) list, loc) =>
         size (inc n) (BIND binds :: items)
       | TC.TPVALPOLYREC (btvEnv,
                          recbinds:{exp:TC.tpexp, expTy:T.ty, var:T.varInfo} list,
                          loc) =>
         size
           (incBtvEnv (inc n, btvEnv))
           (BIND (map (fn {exp,expTy,var} => (var, exp)) recbinds) :: items)
       | TC.TPVALREC (recbinds:{exp:TC.tpexp, expTy:T.ty, var:T.varInfo} list,loc) =>
         size
           (inc n) 
           (BIND (map (fn {exp,expTy,var} => (var, exp)) recbinds) :: items)
       (* the following should have been eliminate *)
       | TC.TPFUNDECL _ => raise bug "TPFUNDECL not eliminated"
       | TC.TPPOLYFUNDECL _  => raise bug "TPPOLYFUNDECL not eliminated"
      )
in
  val sizeExp = fn exp => sizeExp 0 exp nil
  val sizePat = fn pat => sizePat 0 pat nil
  val sizeDecl = fn decl => sizeDecl 0 decl nil
  val sizeDeclList = fn declList => size 0 [DECL declList]
  fun isSmallerExp (exp,n) =
      if n <= 0 then false else
      (limit := SOME n; sizeExp exp; true)
      handle Limit => false
  fun isSmallerPat (pat,n) =
      if n <= 0 then false else
      (limit := SOME n; sizePat pat; true)
      handle Limit => false
  fun isSmallerDecl (decl,n) =
      if n <= 0 then false else
      (limit := SOME n; sizeDecl decl; true)
      handle Limit => false
  fun isSmallerDeclList (declList,n) =
      if n <= 0 then false else
      (limit := SOME n; sizeDeclList declList; true)
      handle Limit => false
end
end
