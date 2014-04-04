(* Efficient and accurate size calculation. *)
structure RCSize =
struct
local
  structure RC = RecordCalc
  structure TC = TypedCalc
  structure T = Types
  structure A = Absyn
  fun bug s = Bug.Bug ("RecordCalcSize: " ^ s)
  type ty = T.ty
  type rcexp = RC.rcexp

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
    = EXP of RC.rcexp list 
    | DECL of RC.rcdecl list
    | BIND of (RC.varInfo * rcexp) list

  fun size n nil = n
    | size n (EXP nil :: items) = size n items
    | size n (EXP (exp::rest) :: items) = sizeExp n exp (EXP rest :: items)
    | size n (DECL nil :: items) = size n items
    | size n (DECL (decl::rest) :: items) = sizeDecl n decl (DECL rest :: items)
    | size n (BIND nil :: items) = size n items
    | size n (BIND ((var,body)::rest) :: items) = 
      size (incVar (n, [var])) (EXP [body] :: BIND rest :: items)
  and sizeExp n exp items =
      (checkLimit n;
       case exp of
         RC.RCAPPM {argExpList, funExp, funTy, loc} =>
         size (inc n) (EXP (funExp::argExpList) :: items)
       | RC.RCCASE 
           {defaultExp:rcexp, 
            exp:rcexp, 
            expTy:Types.ty, 
            loc:Loc.loc,
            ruleList:(RC.conInfo * RC.varInfo option * rcexp) list,
            resultTy} =>
         size (inc n) (EXP (defaultExp::exp:: (map #3 ruleList)) :: items)
       | RC.RCCAST ((rcexp, expTy), ty, loc) => sizeExp (inc n) rcexp items
       | RC.RCCONSTANT {const, loc, ty} => size (incConst(n, const)) items
       | RC.RCDATACONSTRUCT
           {argExpOpt = NONE,
            argTyOpt,
            con:RC.conInfo, 
            instTyList, 
            loc
           } => 
         size (inc n) items
       | RC.RCDATACONSTRUCT
           {argExpOpt = SOME exp,
            argTyOpt,
            con:RC.conInfo, 
            instTyList, 
            loc
           } =>
         sizeExp (inc n) exp items
      | RC.RCEXNCASE {defaultExp:rcexp, exp:rcexp, expTy:ty, loc:Loc.loc,
                      ruleList:(RC.exnCon * RC.varInfo option * rcexp) list,
                      resultTy} =>
        size (inc n)  (EXP (defaultExp :: exp :: (map #3 ruleList)) :: items)
      | RC.RCEXNCONSTRUCT
          {argExpOpt = NONE,
           exn:RC.exnCon,
           instTyList,
           loc
          } =>
        size (inc n) items
      | RC.RCEXNCONSTRUCT
          {argExpOpt = SOME exp,
           exn:RC.exnCon,
           instTyList,
           loc
          } =>
        sizeExp (inc n) exp items
      | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} => 
        size (inc n) items
      | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
        size (inc n) items
      | RC.RCEXVAR {path, ty} => size (inc n) items
      | RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
        sizeExp (incVar (inc n, argVarList)) bodyExp items 
      | RC.RCFOREIGNSYMBOL {loc, name, ty} =>
        size (inc n) items
      | RC.RCHANDLE {exnVar, exp, handler, resultTy, loc} =>
        size (incVar (inc n, [exnVar])) (EXP [exp, handler]:: items)
      | RC.RCLET {body:rcexp list, decls, loc, tys} =>
        size (inc n) (EXP body :: DECL decls :: items)
      | RC.RCMODIFY {elementExp, elementTy, indexExp, label, loc, recordExp, recordTy} =>
        size (inc n) (EXP [elementExp, indexExp, recordExp] :: items)
      | RC.RCMONOLET {binds:(RC.varInfo * rcexp) list, bodyExp, loc} =>
        size (inc n) (BIND binds :: EXP [bodyExp] :: items)
      | RC.RCOPRIMAPPLY {argExp, instTyList, loc, oprimOp:RC.oprimInfo} =>
        sizeExp (inc n) argExp items
      | RC.RCPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
        sizeExp (incBtvEnv (inc n, btvEnv)) exp items
      | RC.RCPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
        sizeExp (incBtvEnv(incVar(inc n,argVarList),btvEnv)) bodyExp items
      | RC.RCPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
        sizeExp (inc n) argExp items
      | RC.RCRAISE {exp, loc, ty} =>sizeExp (inc n) exp items
      | RC.RCRECORD {fields:rcexp LabelEnv.map, loc, recordTy} =>
        size (inc n) (EXP (LabelEnv.listItems fields) :: items)
      | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} =>
        size (inc n) (EXP [exp, indexExp]::items)
      | RC.RCSEQ {expList, expTyList, loc} =>
        size (inc n) (EXP expList :: items)
      | RC.RCSIZEOF (ty, loc) => size (inc n) items
      | RC.RCTAPP {exp, expTy, instTyList, loc} =>
        sizeExp (inc n) exp items
      | RC.RCVAR varInfo => size (inc n) items
      | RC.RCCALLBACKFN {attributes, resultTy, argVarList, bodyExp:rcexp,
                         loc:Loc.loc} =>
        sizeExp (incVar (inc n, argVarList)) bodyExp items
      | RC.RCFOREIGNAPPLY {argExpList:rcexp list,
                           attributes, resultTy, funExp:rcexp,
                           loc:Loc.loc} =>
        size (inc n) (EXP argExpList :: items)
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, funExp=RC.RCFFIFUN ptrExp}, ty, loc) =>
        sizeExp (inc n) ptrExp items
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, funExp=RC.RCFFIEXTERN _}, ty, loc) =>
        size (inc n) items
      | RC.RCINDEXOF (string, ty, loc) => size (inc n) items
      | RC.RCSWITCH {branches:(Absyn.constant * rcexp) list, defaultExp:rcexp,
                     expTy:Types.ty, loc:Loc.loc, switchExp:rcexp, resultTy} =>
        size (inc n) (EXP (defaultExp :: switchExp :: (map #2 branches)) :: items)
      | RC.RCTAGOF (ty, loc) =>
        size (inc n) items
      )
  and sizeDecl n tpdecl items =
      (checkLimit n;
       case tpdecl of
         RC.RCEXD (exbinds:{exnInfo:RC.exnInfo, loc:Loc.loc} list, loc) =>
         size (incN (n, length exbinds)) items 
       | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
         size (inc n) items 
       | RC.RCEXPORTEXN exnInfo =>
         size (inc n) items 
       | RC.RCEXPORTVAR varInfo =>
         size (inc n) items 
       | RC.RCEXTERNEXN {path, ty} =>
         size (inc n) items 
       | RC.RCEXTERNVAR {path, ty} =>
         size (inc n) items 
       | RC.RCVAL (binds:(RC.varInfo * rcexp) list, loc) =>
         size (inc n) (BIND binds :: items)
       | RC.RCVALPOLYREC
           (btvEnv,
            recbinds:{exp:rcexp, expTy:ty, var:RC.varInfo} list,
            loc) =>
         size
           (incBtvEnv (inc n, btvEnv))
           (BIND (map (fn {exp,expTy,var} => (var, exp)) recbinds) :: items)
       | RC.RCVALREC (recbinds:{exp:rcexp, expTy:ty, var:RC.varInfo} list,loc) =>
         size
           (inc n) 
           (BIND (map (fn {exp,expTy,var} => (var, exp)) recbinds) :: items)
      )
in
  val sizeExp = fn exp => sizeExp 0 exp nil
  val sizeDecl = fn decl => sizeDecl 0 decl nil
  val sizeDeclList = fn declList => size 0 [DECL declList]
  fun isSmallerExp (exp,n) =
      if n <= 0 then false else
      (limit := SOME n; sizeExp exp; true)
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
