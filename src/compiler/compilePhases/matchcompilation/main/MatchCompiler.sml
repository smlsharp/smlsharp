 (**
 * SML# match compiler.
 This code is based on the following works.
 * Atsushi Ohori and Satoshi Osaka
   "A Fresh Look at Pattern Matchning Compilation"
  (submitted for publication)
 * Satoshi Osana, "Pallalel Pattern Maching" (in Japanese)
 The latter one is an optimized version of the former, and is not published.

 The code was written by Satoshi Osaka. It was then re-written
 by Atsushi Ohori to incorporate verious optimization.

 A note by A. Ohori:
 In addition to the algorithms descrived in the above two articples,
 I incorporated the following for optimization:
   Instead of generating function declarations for brances, 
   the new version set up a branch environmnet of the form
       branch id =>
      {expression : exp
       functionExpression : 
           {
            funId : F, 
            funBody : Fbody
            funTy : FunTy
            funArgs : args
            }    
       useCount: int ref
      }
  If the branch exceed the inlineLimit value and
     invoked more than once   
  then the predefined limit then the following code is generated
        let val F = Fbody in 
            case ...
              | .. => F args
  otherwise
         case ... 
             | ... => exp
  is generated.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Satoshi Osaka 
 * @author Atsushi Ohori
 * @version $Id: MatchCompiler.sml,v 1.70 2008/08/06 17:23:40 ohori Exp $
 *)
structure MatchCompiler : sig

  val compile : TypedCalc.tpdecl list
                -> TypedCalc.tpdecl list * UserError.errorInfo list

end =
struct
local
  structure C = Control
  structure A = AbsynConst
  structure T = Types
  structure PC = PatternCalc
  structure TC = TypedCalc
  structure TB = TypesBasics
  structure TCU = TypedCalcUtils
  structure UE = UserError
  structure BT = BuiltinTypes
  structure ME = MatchError
  (* structure S = Symbol *)
  fun bug s = Bug.Bug ("MatchCompiler: " ^ s)
  type path = Symbol.longsymbol
  type constant = A.constant
  type conInfo = T.conInfo

  fun systemModeError (loc, ruleList) =
      raise 
        UserError.UserErrors
        [(loc,
          UserError.Error,
          MatchError.MatchError
            ("Fancy pattern not allowed in the operating system coding mode:", 
             map (fn {args, body} => ((args, body), ref 1))
                 ruleList
            )
         )
        ]

  fun newLocalId () = VarID.generate ()
  fun freshVar ty =
      {path=nil,ty=ty,id=newLocalId(),opaque=false} : T.varInfo
  fun makeVar (id, ty) =
      {path=nil,ty=ty,id=id,opaque=false} : T.varInfo
  fun printVarInfo var =
      print (Bug.prettyPrint (T.format_varInfo var))

  open MatchData

  (* this function collects all the variables free or bound.
     This is used to optimize variable pattern to wild pattern
     when the variable is not used.
   *)
  fun getAllVars tpexp =
      let
        fun get (tpexp, set) =
            case tpexp  of
              TC.TPERROR => set
            | TC.TPDYNAMICCASE
                {
                 groupListTerm : TC.tpexp, 
                 groupListTy, 
                 dynamicTerm : TC.tpexp,
                 dynamicTy, 
                 elemTy, 
                 ruleBodyTy, 
                 loc} => get (groupListTerm, get (dynamicTerm, set))
            | TC.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
              get (exp, get (existInstMap, set))
            | TC.TPDYNAMIC {exp, ty, elemTy, coerceTy, loc} => get (exp, set)
            | TC.TPDYNAMICIS {exp, ty, elemTy, coerceTy, loc} => get (exp, set)
            | TC.TPDYNAMICNULL {ty, coerceTy, loc} => set
            | TC.TPDYNAMICTOP {ty, coerceTy, loc} => set
            | TC.TPDYNAMICVIEW {exp, ty, elemTy, coerceTy, loc} => get (exp, set)
            | TC.TPCONSTANT {const,ty,loc} => set
            | TC.TPVAR varInfo => VarInfoSet.add(set, varInfo)
            | TC.TPEXVAR (exVarInfo,loc) => set
            | TC.TPRECFUNVAR {var, arity} => VarInfoSet.add(set, var)
            | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} => get (bodyExp,set)
            | TC.TPAPPM {funExp, funTy, argExpList, loc} =>
              foldl get (get (funExp, set)) argExpList
            | TC.TPDATACONSTRUCT {argExpOpt=NONE,...} => set
            | TC.TPDATACONSTRUCT {argExpOpt=SOME exp,...} => get (exp,set)
            | TC.TPEXNCONSTRUCT {argExpOpt=NONE,...} => set
            | TC.TPEXNCONSTRUCT {argExpOpt=SOME exp,...} => get (exp, set)
            | TC.TPEXNTAG _ => set
            | TC.TPEXEXNTAG _ => set
            | TC.TPCASEM {expList,ruleList,...} =>
              foldl
                (fn ({args, body},set) => get(body, set))
                (foldl get set expList)
                ruleList
            | TC.TPSWITCH {exp, ruleList, defaultExp, expTy, ruleBodyTy, loc} =>
              foldl
                get
                set
                (exp :: defaultExp ::
                 (case ruleList of
                    TC.CONSTCASE rules => map #body rules
                  | TC.CONCASE rules => map #body rules
                  | TC.EXNCASE rules => map #body rules))
            | TC.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
              get (tryExp, get (catchExp, set))
            | TC.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
              foldl get set argExpList
            | TC.TPPRIMAPPLY {argExp=exp,...} => get (exp, set)
            | TC.TPOPRIMAPPLY {argExp=exp,...} => get (exp, set)
            | TC.TPRECORD {fields, recordTy, loc} =>
              RecordLabel.Map.foldl get set fields
            | TC.TPSELECT {label, exp, expTy, resultTy, loc} => get (exp,set)
            | TC.TPMODIFY {recordExp,elementExp,...} =>
              get(elementExp, get(recordExp, set))
            | TC.TPMONOLET {binds, bodyExp, loc} =>
              get(bodyExp,foldl(fn ((var,exp),set) => get(exp,set)) set binds)
            | TC.TPLET {decls, body, loc} =>
              get (body, foldl getDecl set decls)
            | TC.TPRAISE {exp, ty, loc} => get(exp, set)
            | TC.TPHANDLE {exp, exnVar, handler, resultTy, loc} =>
              get(handler, get(exp, set))
            | TC.TPPOLY {btvEnv, constraints, expTyWithoutTAbs, exp, loc} => get(exp, set)
            | TC.TPTAPP {exp, expTy, instTyList, loc} => get(exp, set)
            | TC.TPFFIIMPORT {funExp=TC.TPFFIFUN (ptrExp, _), ffiTy, stubTy, loc} => get(ptrExp, set)
            | TC.TPFFIIMPORT {funExp=TC.TPFFIEXTERN _, ffiTy, stubTy, loc} => set
            | TC.TPFOREIGNSYMBOL _ => set
            | TC.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
              foldl get (get (funExp, set)) argExpList
            | TC.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
              get (bodyExp, set)
            | TC.TPCAST ((tpexp, expTy), ty, loc) => get(tpexp, set)
            | TC.TPSIZEOF (ty, loc) => set
            | TC.TPJOIN {isJoin, ty, args = (arg1, arg2), argtys, loc} =>
              get (arg1, get (arg2, set))
            | TC.TPREIFYTY (ty, loc) => set
        and getDecl (decl, set) =
            case decl of
              TC.TPVAL ((var, exp), loc) =>
              get (exp, set)
            | TC.TPFUNDECL (funBindlist, loc) =>
              foldl
                (fn ({ruleList,...}, set) =>
                    foldl (fn({args,body},set)=>get(body,set)) set ruleList)
                set
                funBindlist
            | TC.TPPOLYFUNDECL {btvEnv, constraints, recbinds=funBindList, loc} =>
              foldl
                (fn ({ruleList,...}, set) =>
                    foldl (fn({args,body},set)=>get(body,set)) set ruleList)
                set
                funBindList
            | TC.TPVALREC (varExpList, loc) =>
              foldl 
                (fn ({exp,...},set) => get(exp, set))
                set
                varExpList
            | TC.TPVALPOLYREC {btvEnv, constraints, recbinds=varExpList, loc} =>
              foldl 
                (fn ({exp,...},set) => get(exp, set))
                set
                varExpList
            | TC.TPEXD (exnconLocList, loc) => set
            | TC.TPEXNTAGD ({varInfo,...},loc) => VarInfoSet.add(set, varInfo)
            | TC.TPEXPORTVAR {var, exp} =>
              get (exp, set)
            | TC.TPEXPORTEXN exnInfo => set
            | TC.TPEXTERNVAR exVarInfo => set
            | TC.TPEXTERNEXN exExnInfo => set
            | TC.TPBUILTINEXN exExnInfo => set
      in
        get (tpexp, VarInfoSet.empty)
      end

in
  val nextBranchId = ref 0
  fun newBranchId () = 
    let val next = !nextBranchId 
    in  
      nextBranchId := next + 1 ; 
      next 
    end


  type branchData = {
                     funArgs : VarInfoSet.item list,
                     funBodyTy : T.ty,
                     funLoc : Loc.loc,
                     funTy : (T.ty option) ref,
                     funVarId : VarID.id,
                     funLabel : FunLocalLabel.id,
                     isSmall : bool,
                     tpexp: TC.tpexp, 
                     useCount : int ref
                    }

  type branchEnv = branchData IEnv.map

 (*
   Check whether a given expression is smaller than the limit.
   The functionl only traverses upto the inlineLimit number 
   of constructors in the given expression. 
  *)
  fun isSmall tpexp = 
    let
      datatype item = Exp of TC.tpexp | Decl of TC.tpdecl
      fun limitCheck nil n = true
        | limitCheck (item::itemList) n =
          if n > !C.limitOfInlineCaseBranch then false
          else
            case item of 
              Exp rcepx => limitCheckExp rcepx itemList n 
            | Decl tpdecl => limitCheckDecl tpdecl itemList n 

      and limitCheckExp tpexp itemList n = 
        case tpexp of
          TC.TPERROR => limitCheck itemList (n + 1)
        | TC.TPDYNAMICCASE 
            {groupListTerm, groupListTy, dynamicTerm, dynamicTy, elemTy, ruleBodyTy, loc} =>
          limitCheck (Exp groupListTerm :: itemList) (n + 1)
        | TC.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
          limitCheck (Exp existInstMap :: Exp exp :: itemList) (n + 1)
        | TC.TPDYNAMIC {exp, ty, elemTy, coerceTy, loc} =>
          limitCheck (Exp exp::itemList) (n + 1)
        | TC.TPDYNAMICIS {exp, ty, elemTy, coerceTy, loc} =>
          limitCheck (Exp exp::itemList) (n + 1)
        | TC.TPDYNAMICNULL {ty, coerceTy, loc} => limitCheck itemList (n + 1)
        | TC.TPDYNAMICTOP {ty, coerceTy, loc} => limitCheck itemList (n + 1)
        | TC.TPDYNAMICVIEW {exp, ty, elemTy, coerceTy, loc} =>
          limitCheck (Exp exp::itemList) (n + 1)
        | TC.TPCONSTANT {const, ty, loc} => limitCheck itemList (n + 1)
        | TC.TPVAR varIdInfo => limitCheck itemList (n + 1)
        | TC.TPEXVAR (exVarInfo,loc) => limitCheck itemList (n + 1)
        | TC.TPRECFUNVAR {var, arity} => limitCheck itemList (n + 1)
        | TC.TPFNM {argVarList=varIdInfoList, bodyTy, bodyExp, loc} => 
            limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPAPPM {funExp=tpexp1, funTy=ty, argExpList=tpexpList, loc} => 
          limitCheck (Exp tpexp1 :: (map Exp tpexpList) @ itemList) (n + 1)
        | TC.TPDATACONSTRUCT
            {con=conIdInfo,
             instTyList=tyList,
             argExpOpt=NONE, 
             loc} => limitCheck itemList (n + 1)
        | TC.TPDATACONSTRUCT
            {con=conIdInfo,
             instTyList=tyList,
             argExpOpt=SOME tpexp1,
             loc} => 
            limitCheck (Exp tpexp1 :: itemList) (n + 1)
        | TC.TPEXNCONSTRUCT
            {exn=conIdInfo, argExpOpt=NONE, loc} =>
          limitCheck itemList (n + 1)
        | TC.TPEXNCONSTRUCT
            {exn=conIdInfo,
             argExpOpt=SOME tpexp1,
             loc} => 
            limitCheck (Exp tpexp1 :: itemList) (n + 1)
        | TC.TPEXNTAG {exnInfo, loc} => limitCheck itemList (n + 1)
        | TC.TPEXEXNTAG {exExnInfo, loc} => limitCheck itemList (n + 1)
        | TC.TPCASEM {expList,expTyList,ruleList,ruleBodyTy,caseKind,loc} =>
            limitCheck
              (map Exp expList
               @
               map (fn {args, body} => Exp body) ruleList 
               @
               itemList
              ) 
            (n + 1)
        | TC.TPSWITCH {exp, expTy, ruleList, defaultExp, ruleBodyTy, loc} =>
          limitCheck
            (Exp exp
             :: Exp defaultExp
             :: (case ruleList of
                   TC.CONSTCASE rules => map (Exp o #body) rules
                 | TC.CONCASE rules => map (Exp o #body) rules
                 | TC.EXNCASE rules => map (Exp o #body) rules)
             @ itemList)
            (n + 1)
        | TC.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
          limitCheck (Exp tryExp :: Exp catchExp :: itemList) (n + 1)
        | TC.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
          limitCheck (map Exp argExpList @ itemList) (n + 1)
        | TC.TPPRIMAPPLY {primOp,instTyList,argExp=tpexp1,loc} =>
          limitCheck (Exp tpexp1::itemList) (n + 1)
        | TC.TPOPRIMAPPLY {argExp=tpexp1,...} =>
          limitCheck (Exp tpexp1::itemList) (n + 1)
        | TC.TPRECORD {fields, recordTy=ty, loc} => 
            limitCheck
              ((map (fn (l,tpexp) => Exp tpexp) (RecordLabel.Map.listItemsi fields))
               @ itemList) (n + 1)
        | TC.TPSELECT {label=string, exp=tpexp, expTy=ty, resultTy, loc} 
            => limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPMODIFY {label=string, 
                     recordExp=tpexp1, 
                     recordTy=ty1, 
                     elementExp=tpexp2, 
                     elementTy=ty2,  
                     loc} =>
            limitCheck (Exp tpexp1 :: Exp tpexp2 :: itemList) (n + 1)
        | TC.TPMONOLET {binds=(varIdInfo,tpexp1)::varIdInfotpexpList, 
                      bodyExp=tpexp2, 
                      loc} =>
          limitCheck (Exp tpexp1 :: 
                      Exp (TC.TPMONOLET
                             {binds=varIdInfotpexpList,
                              bodyExp=tpexp2,
                              loc=loc}) ::
                        itemList)
            (n + 1)
        | TC.TPMONOLET {binds=nil, bodyExp=tpexp1, loc} =>
          limitCheck (Exp tpexp1 :: itemList) (n + 1)
        | TC.TPLET {decls, body, loc} =>
          limitCheck ((map Decl decls) @ [Exp body] @ itemList) (n + 1)
        | TC.TPRAISE {exp, ty, loc} =>
          limitCheck (Exp exp :: itemList) (n + 1)
        | TC.TPHANDLE {exp=tpexp1,  exnVar=varIdInfo, handler=tpexp2,
                       resultTy, loc} =>
            limitCheck (Exp tpexp1 :: Exp tpexp2 :: itemList) (n + 1)
        | TC.TPPOLY
            {btvEnv=btvKindIEnvMap,
             constraints,
             expTyWithoutTAbs=ty,
             exp=tpexp,
             loc} =>
            limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPTAPP {exp=tpexp, expTy=ty1, instTyList=tylist, loc} => 
            limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPFFIIMPORT
            {
             funExp=TC.TPFFIFUN (tpexp1, _),
             ...
            } => 
            limitCheck (Exp tpexp1 :: itemList) (n + 1)
        | TC.TPFFIIMPORT {funExp=TC.TPFFIEXTERN _, ...} =>
          limitCheck itemList (n + 1)
        | TC.TPFOREIGNSYMBOL _ => limitCheck itemList (n + 1)
        | TC.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
          limitCheck (Exp funExp :: map Exp argExpList @ itemList) (n + 1)
        | TC.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
          limitCheck (Exp bodyExp :: itemList) (n + 1)
        | TC.TPSIZEOF _ => limitCheck itemList (n + 1)
        | TC.TPREIFYTY _ => limitCheck itemList (n + 1)
        | TC.TPCAST ((tpexp, expTy), ty, loc) =>
          limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPJOIN {isJoin, ty, args = (arg1, arg2), argtys, loc} =>
          limitCheck (Exp arg1 :: Exp arg2 :: itemList) (n + 1)

      and limitCheckDecl tfpdecl itemList n = 
        case tfpdecl of
          TC.TPVAL ((var, exp), loc) =>
            limitCheck
              ([Exp exp] @ itemList) (n + 1)
        | TC.TPFUNDECL _ => raise bug "TC.TPFUNDECL in MatchCompiler"
        | TC.TPPOLYFUNDECL  _ => raise bug "TC.TPPOLYFUNDECL in MatchCompiler"
        | TC.TPVALREC (varExpList,loc) =>
          limitCheck
            ((map (fn {var, exp} => Exp exp) varExpList)
             @ itemList) (n + 1)
        | TC.TPVALPOLYREC {btvEnv=btvKindIEnvMap, constraints, recbinds=varExpList, loc} =>
          limitCheck
            ((map (fn {var, exp} => Exp exp) varExpList)
             @ itemList) (n + 1)
        | TC.TPEXD (exnconLocList, loc) => limitCheck itemList (n + 1)
        | TC.TPEXNTAGD (bind, loc) => limitCheck itemList (n + 1)
        | TC.TPEXPORTVAR {var, exp} => limitCheck (Exp exp :: itemList) (n + 1)
        | TC.TPEXPORTEXN exnInfo => limitCheck itemList (n + 1)
        | TC.TPEXTERNVAR exVarInfo => limitCheck itemList (n + 1)
        | TC.TPEXTERNEXN exExnInfo => limitCheck itemList (n + 1)
        | TC.TPBUILTINEXN exExnInfo => limitCheck itemList (n + 1)
    in
      limitCheck [(Exp tpexp)] 0
    end

  infixr ++
  infixr +++
  fun nil +++ x = x 
    | (h::t) +++ x= h ++ (t +++ x)

  fun unionBtvEnv(outerBtvEnv, innerBtvEnv) =
      BoundTypeVarID.Map.unionWith #1 (innerBtvEnv, outerBtvEnv)

  fun unionVarInfoEnv(outerVarEnv, innerVarEnv) =
      VarInfoEnv.unionWith #1 (innerVarEnv, outerVarEnv)

  fun haveRedundantRules (branchEnv:branchEnv) = 
    let
      exception Redundant
    in
      (IEnv.map
       (fn {useCount, ...} => if !useCount = 0 then raise Redundant else ())
       branchEnv;
       false)
      handle Redundant => true
    end

  fun getFieldsOfTy (btvEnv : T.btvEnv) ty =
      case TB.derefTy ty of
        T.RECORDty fields => fields
      | T.TYVARty(ref(T.TVAR{kind = T.KIND {tvarKind = T.REC fields, ...}, ...})) => fields
      | T.BOUNDVARty index =>
        (case BoundTypeVarID.Map.find (btvEnv, index) of
           SOME (T.KIND {tvarKind = T.REC fields, ...}) => fields
         | _ =>
           raise
             Bug.Bug
             ("getFieldsOfTy found invalid BTV("
              ^ BoundTypeVarID.toString index ^ ")"))
      | T.DUMMYty (id,T.KIND {tvarKind = T.REC fields, ...}) => fields
      (* 2019-05-24 338?dummytype.smlのバグ対応のため、修正。
       *)
      | ty =>
        raise
          Bug.Bug
              ("getFieldsOfTy found unexpected:"
               ^ Bug.prettyPrint (T.format_ty ty))

  fun getTagNums {ty, path, id} = 
      let
        val tyCon = 
            case TB.derefTy ty of
              T.FUNMty(args, ty) =>
              (case TB.derefTy ty of
                 T.CONSTRUCTty{tyCon, ...} => tyCon
               | _ => 
                 (print "getTagNums\n";
                  print (Bug.prettyPrint (T.format_ty ty));
                  print "\n";
                  raise bug "Non conty in userdefined type"
                 )
              )
            | T.POLYty{body,...} =>
              (case TB.derefTy body of
                 T.FUNMty(args, ty) =>
                 (case TB.derefTy ty of
                    T.CONSTRUCTty{tyCon, ...} => tyCon
                  | _ => 
                    (print "getTagNums\n";
                     print (Bug.prettyPrint (T.format_ty ty));
                     print "\n";
                     raise bug "Non conty in userdefined type"
                    )
                 )
               | T.CONSTRUCTty{tyCon, ...} => tyCon
               | _ => 
                 (print "getTagNums\n";
                  print (Bug.prettyPrint (T.format_ty ty));
                  print "\n";
                  raise bug "Non conty in userdefined type"
                 )
              )
            | T.CONSTRUCTty{tyCon, ...} => tyCon
            | _ => 
              (print "getTagNums\n";
               print (Bug.prettyPrint (T.format_ty ty));
               print "\n";
               raise bug "Non conty in userdefined type"
              )
      in
        case SymbolEnv.listItems (#conSet tyCon) of
          nil => raise Bug.Bug "NON span field in userdefined type"
        | L => List.length L
      end

  (***** return access path of root node *****)
  fun getPath tree =
      case tree of
        (EqNode (path, _, _)) => path
      | (DataConNode (path, _, _)) => path
      | (ExnConNode (path, _, _)) => path
      | (RecNode (path, _, _)) => path
      | (UnivNode (path, _)) => path
      | _ => raise Bug.Bug "match comp, getPath bug"

  (* ADDED for type preservation *)
  fun getTyInPat pat =
      case pat of
        (WildPat ty) => ty
      | (VarPat ({ ty, ... })) => ty
      | (ConstPat (_, ty)) => ty
      | (DataConPat (_, _, _, _, ty)) => ty
      | (ExnConPat (_, _, _, ty)) => ty
      | (RecPat (_, ty)) => ty
      | (LayerPat (pat, _)) => getTyInPat pat
      | (OrPat (pat, _)) => getTyInPat pat

  fun incrementUseCount (branchEnv:branchEnv, branchId) =
      case IEnv.find(branchEnv, branchId) of
        SOME {useCount, ...} => useCount := !useCount + 1
      | NONE =>
        raise Bug.Bug "incrementUseCount in MatchCompiler: BranchId not found"

  fun canInlineBranch ({isSmall, useCount, ...} : branchData) =
      (!C.doInlineCaseBranch)
      andalso (isSmall orelse !useCount = 1)

  fun makeNestedFun argList body bodyTy loc =
      case argList of
        [] =>
        (
         TC.TPFNM
           {
            argVarList =
            [freshVar BT.unitTy],
            bodyTy=bodyTy, 
            bodyExp=body, 
            loc=loc
           },
         T.FUNMty ([BT.unitTy], bodyTy)
        )
      | argList =>
        foldr 
          (fn (arg, (body, bodyTy)) => 
              (TC.TPFNM {argVarList=[arg],
                         bodyTy=bodyTy,
                         bodyExp=body,
                         loc=loc},
               T.FUNMty ([#ty arg], bodyTy)))
          (body, bodyTy)
          argList

  fun makeUncurriedFun argList body bodyTy loc =
      case argList of
       [] =>
       (
        TC.TPFNM
          {
           argVarList=[freshVar BT.unitTy], 
           bodyTy=bodyTy, 
           bodyExp=body, 
           loc=loc
          },
        T.FUNMty ([BT.unitTy], bodyTy)
       )
     | argList =>
       (
        TC.TPFNM
          {
           argVarList=argList, 
           bodyTy=bodyTy, 
           bodyExp=body, 
           loc=loc
          }, 
        T.FUNMty (map #ty argList, bodyTy)
       )

  (*
     [..., ([P1,...,Pn], e),...] ->  (branchEnv, [..., P1++...++Pn++n,...])
   *)
  fun makeRules branchTy tfpruleIntRefList loc =
      let
        fun getVars (VarPat x) = VarInfoSet.singleton x
          | getVars (DataConPat (_, _, _, argPat, _)) = getVars argPat
          | getVars (ExnConPat (_, _, argPat, _)) = getVars argPat
          | getVars (RecPat (fields, _)) =
              foldl 
              (fn (field, vars) => VarInfoSet.union (getVars (#2 field), vars))
              VarInfoSet.empty
              fields
          | getVars (LayerPat (pat1, pat2)) =
              VarInfoSet.union (getVars pat1, getVars pat2)
          | getVars (OrPat (pat1, pat2)) =
              VarInfoSet.union (getVars pat1, getVars pat2)
          | getVars _ = VarInfoSet.empty
        fun getVarsInPatList patList = 
            foldr (fn (pat, V) => VarInfoSet.union(getVars pat, V)) 
            VarInfoSet.empty 
            patList
        val (branchEnv, rules) =
            foldr
            (fn (((patList, tpexp), useCounter), (branchEnv, rules)) =>
             let
               val argList = VarInfoSet.listItems (getVarsInPatList patList)
               val branchId = newBranchId()
               val branchEnvEntry =
                 {
                  tpexp = tpexp,
                  isSmall = isSmall tpexp,
                  useCount = useCounter,
                  funVarId = newLocalId(),
                  funLabel = FunLocalLabel.generate nil,
                  funBodyTy = branchTy,
                  funTy = ref NONE,
                  funLoc = loc,
                  funArgs = argList
                  } : branchData
             in
               (
                IEnv.insert(branchEnv, branchId, branchEnvEntry),
                ( patList +++ End branchId, VarInfoEnv.empty) :: rules
                )
             end)
            (IEnv.empty, [])
            tfpruleIntRefList
      in
        (branchEnv, rules)
      end

  fun tppatToPat btvEnv FV tppat =
      case tppat of
        TC.TPPATERROR (ty, loc) => WildPat ty
      | TC.TPPATWILD (ty, _) => WildPat ty
      | TC.TPPATVAR x =>
        if VarInfoSet.member (FV, x) then VarPat x else WildPat (#ty x)
      | TC.TPPATCONSTANT (A.UNITCONST, ty, _) => WildPat ty
      | TC.TPPATCONSTANT (con, ty, _) => ConstPat (con, ty)
      | TC.TPPATDATACONSTRUCT {conPat, argPatOpt=NONE, patTy=ty, instTyList, loc} =>
        DataConPat (conPat, instTyList, false, WildPat BT.unitTy, ty)
      | TC.TPPATDATACONSTRUCT{conPat,argPatOpt = SOME argPat,patTy=ty,instTyList, loc}=>
        DataConPat (conPat, instTyList, true, tppatToPat btvEnv FV argPat, ty)
      | TC.TPPATEXNCONSTRUCT {exnPat, argPatOpt=NONE, patTy=ty, loc} =>
        ExnConPat (exnPat, false, WildPat BT.unitTy, ty)
      | TC.TPPATEXNCONSTRUCT {exnPat,argPatOpt = SOME argPat,patTy=ty, loc} =>
        ExnConPat (exnPat, true, tppatToPat btvEnv FV argPat, ty)
      | TC.TPPATRECORD {fields=patRows, recordTy=ty,...} =>
        let
          (*  The match compilation algorithm assumes that every record
           * patterns at the same path in all branches have the same
           * label set.
           *  That is, it does not consider flexible record pattern, by
           * which record patterns at the same path may have different
           * fields.
           *  Therefore, before match compilation, every record patterns
           * should be filled with "missing" fields.
           * Assume the record pattern is
           *     {x = p1, y = p2, ...} 
           * which is typed as t.
           * If t is a record type {x : t1, y : t2, z : t3}, or a type 
           * variable of a kind {{x : t1, y : t2, z : t3}}, a missing
           * field "z" should be added to obtain the following record
           * pattern.
           *     {x = p1, y = p2, z = _}
           *)
          val expectedFields = getFieldsOfTy btvEnv ty
          val augmentedPatRows =
            RecordLabel.Map.foldri
            (fn (label, ty, pats) =>
             let
               val pat = 
                 case RecordLabel.Map.find(patRows, label) of
                   SOME pat => tppatToPat btvEnv FV pat
                 | NONE => WildPat ty
             in (label, pat) :: pats
             end)
            []
            expectedFields
        in
          RecPat (augmentedPatRows, ty)
        end
      | TC.TPPATLAYERED {varPat=pat1, asPat=pat2, ...} =>
        (case tppatToPat btvEnv FV pat1
          of x as (VarPat _) => LayerPat (x, tppatToPat btvEnv FV pat2)
           | _ => tppatToPat btvEnv FV pat2)

    fun removeOtherPat path ruleList =
        case ruleList of 
          [] => []
        | (REs as ((End _, _) :: _)) => REs
        | ((VarPat x ++ rule, env) :: REs) =>
          (WildPat (#ty x) ++ rule, VarInfoEnv.insert (env, x, path)) ::
          removeOtherPat path REs
        | ((LayerPat (VarPat x, pat) ++ rule, env) :: REs) =>
          removeOtherPat
            path
            ((pat ++ rule, VarInfoEnv.insert (env, x, path)) :: REs)
        | ((OrPat (pat1, pat2) ++ rule, env) :: REs) =>
          removeOtherPat
            path
            ((pat1 ++ rule, env) :: (pat2 ++ rule, env) :: REs)
        | (RE :: REs) => RE :: removeOtherPat path REs

    fun makeEqTree branchEnv (path :: paths) REs =
        let
  	val (branches, defBranch) = 
              foldr 
  	    (fn ((ConstPat (c, _) ++ rule, env), (branches, defBranch)) =>
  	          (
  		   ConstMap.insert
  		   ( 
                    branches, 
  		    c,
                    (rule, env) ::
                    getOpt (ConstMap.find (branches, c), defBranch)
  		   ),
  		   defBranch
  		  )
  	      | ((WildPat _ ++ rule, env), (branches, defBranch)) =>
  		let
  		  val RE = (rule, env)
  		in
  		  (ConstMap.map (fn REs => RE :: REs) branches,
                   RE :: defBranch)
  		end
  	      | _ => raise Bug.Bug "match comp, in makeEqTree")
  	    (ConstMap.empty, [])
  	    REs
        in
  	EqNode (
  		 path, 
  		 ConstMap.map (matchToTree branchEnv paths) branches, 
  		 matchToTree branchEnv paths defBranch
  	       )
        end
      | makeEqTree _  _ _ = raise Bug.Bug "match comp, makeEqTree"
  
    and makeDataConTree branchEnv spans (path :: paths) REs =
        let
  	  val (branches, defBranch) = 
              foldr 
  	        (fn
                 (
                  (DataConPat (tag, instTyList, hasArg, argPat, ty) ++ rule, env),
  		  (branches, defBranch)
  		 ) =>
  	         let
                   val key = (tag, instTyList, hasArg)
  		   val REs = 
  		       case DataConMap.find (branches, key)
  			of SOME REs => REs
  			 | NONE =>
  			   let
  			     val wildPat = WildPat (getTyInPat argPat)
  			   in
  			     map 
  			       (fn (rule, env) => (wildPat ++ rule, env))
  			       defBranch
  			   end
  		 in
  		   (
  		    DataConMap.insert
  		      (branches, key, (argPat ++ rule, env) :: REs),
  		    defBranch
  		   )
  		 end
  	       | ((WildPat _ ++ rule, env), (branches, defBranch)) =>
  		 (
  		  DataConMap.map
  		    (fn (REs as ((pat ++ _, _) :: _)) => 
  		        (WildPat (getTyInPat pat) ++ rule, env) :: REs
  		      | _ => raise Bug.Bug "match comp, in makeTagTree")
  		    branches,
  		  (rule, env) :: defBranch
  		 )
  	       | _ => raise Bug.Bug "match comp, in makeTagTree")
  	        (DataConMap.empty, [])
  	        REs
        in
  	  DataConNode
            (
  	     path,
  	     DataConMap.mapi
               (fn ((tag, _, _), REs as ((pat ++ _, _) :: _)) =>
  		   matchToTree
                     branchEnv
  		     (freshVar (getTyInPat pat) :: paths)
  		     REs
  		 | _ => raise Bug.Bug "match comp, in makeTagTree")
  	       branches,
  	     if DataConMap.numItems branches = spans
  	     then EmptyNode
  	     else matchToTree branchEnv paths defBranch
  	    )
        end
      | makeDataConTree _  _ _ _ = raise Bug.Bug "match comp, makeTagTree"
  
    and makeExnConTree branchEnv (path :: paths) REs =
        let
  	  val (branches, defBranch) = 
              foldr 
  	        (fn
                 (
                  (ExnConPat (tag, hasArg, argPat, ty) ++ rule, env),
  		  (branches, defBranch)
  		 ) =>
  	         let
                   val key = (tag, hasArg)
  		   val REs = 
  		       case ExnConMap.find (branches, key)
  			of SOME REs => REs
  			 | NONE =>
  			   let
  			     val wildPat = WildPat (getTyInPat argPat)
  			   in
  			     map 
  			       (fn (rule, env) => (wildPat ++ rule, env))
  			       defBranch
  			   end
  		 in
  		   (
  		    ExnConMap.insert
  		      (branches, key, (argPat ++ rule, env) :: REs),
  		    defBranch
  		   )
  		 end
  	       | ((WildPat _ ++ rule, env), (branches, defBranch)) =>
  		 (
  		  ExnConMap.map
  		    (fn (REs as ((pat ++ _, _) :: _)) => 
  		        (WildPat (getTyInPat pat) ++ rule, env) :: REs
  		      | _ => raise Bug.Bug "match comp, in makeTagTree")
  		    branches,
  		  (rule, env) :: defBranch
  		 )
  	       | _ => raise Bug.Bug "match comp, in makeTagTree")
  	        (ExnConMap.empty, [])
  	        REs
        in
  	  ExnConNode
            (
  	     path,
  	     ExnConMap.mapi
               (fn ((tag, _), REs as ((pat ++ _, _) :: _)) =>
  		   matchToTree
                     branchEnv
  		     (freshVar (getTyInPat pat) :: paths)
  		     REs
  		 | _ => raise Bug.Bug "match comp, in makeTagTree")
  	       branches,
(*
  The case of exn, spans is infinite, so if branch will never happen.
  		            if ExnConMap.numItems branches = spans
  		            then EmptyNode
  		            else matchToTree branchEnv paths defBranch
*)
              matchToTree branchEnv paths defBranch
   	    )
        end
      | makeExnConTree _ _ _ = raise Bug.Bug "match comp, makeTagTree"

    (*
     * Because unit type has only one value (), pattern match on unit type
     * succeeds always. So, make a univ node.
     *)
    and makeUnitTree branchEnv paths REs = makeUnivTree branchEnv paths REs
  
    and makeNRecTree
          branchEnv
          (label, fieldTy) (path :: paths) REs =
        RecNode	
  	  (
  	   path, 
  	   label,
  	   matchToTree
             branchEnv
  	     (freshVar fieldTy :: paths)
  	     (map
  	        (fn (RecPat ([(_, pat)], _) ++ rule, env) => (pat ++ rule, env)
  	          | (WildPat _ ++ rule, env) => (WildPat fieldTy ++ rule, env)
  	          | _ => raise Bug.Bug "match comp, in makeNRecTree")
  	        REs)
  	  )
      | makeNRecTree _ _ _ _ = raise Bug.Bug "match comp, makeNRecTree"
  
    and makeIRecTree
          branchEnv
          (recordTy, label, fieldTy)
          (paths as (path :: _))
          REs =
        RecNode
          (
  	   path,
  	   label, 
  	   matchToTree
             branchEnv
  	     (freshVar fieldTy :: paths)
  	     (map
  		(fn (RecPat ((_, pat) :: fields, ty) ++ rule, env) =>
  		    (pat ++ RecPat (fields, ty) ++ rule, env)
  	          | (WildPat _ ++ rule, env) =>
  		    (WildPat fieldTy ++ WildPat recordTy ++ rule, env)
  		  | _ => raise Bug.Bug "match comp, in makeIRecTree")
  		REs)
  	  )
      | makeIRecTree _ _ _ _ = raise Bug.Bug "match comp, makeIRecTree"
  	
    and makeUnivTree branchEnv (path :: paths) REs = 
        UnivNode
          (
  	   path,
  	   matchToTree
             branchEnv 
  	     paths 
  	     (map (fn (pat ++ rule, env) => (rule, env) 
  		    | _ => raise Bug.Bug "makeUnivTree") 
  		  REs)
  	  )
      | makeUnivTree _  _ _ = raise Bug.Bug "match comp, makeUnivTree"
  
    and decideRootNode branchEnv ruleList =
        case ruleList of
          [] => makeUnivTree branchEnv
        | ((WildPat _ ++ _, _) :: REs) =>
          decideRootNode branchEnv REs
        | ((ConstPat _ ++ _, _) :: _) =>
          makeEqTree branchEnv
        | ((DataConPat (tag, _, _, _, _) ++ _, _) :: _) =>
          makeDataConTree branchEnv (getTagNums tag)
        | ((ExnConPat (tag, _, _, _) ++ _, _) :: _) =>
          makeExnConTree branchEnv 
        | ((RecPat ([], _) ++ _, _) :: _) =>
          makeUnitTree branchEnv
        | ((RecPat ([(label, pat)], _) ++ _, _) :: _) =>
          makeNRecTree
            branchEnv
            (label, getTyInPat pat)
        | ((RecPat ((label, pat) :: _, recTy) ++ _, _) :: _) =>
          makeIRecTree
            branchEnv
            (recTy, label, getTyInPat pat)
        | _ => raise Bug.Bug "match comp, decideRootNode"

    and matchToTree branchEnv _ [] =
        (ME.setFlag ME.NotExhaustive; EmptyNode )
      | matchToTree branchEnv [] ((End branchId, env) :: REs)=
        (incrementUseCount (branchEnv, branchId); 
         LeafNode (branchId, env))
      | matchToTree branchEnv paths REs =
        let
          val REs = removeOtherPat (hd paths) REs
        in
	  (decideRootNode branchEnv REs) paths REs
        end

  fun treeToRcexp varEnv btvEnv branchEnv kind tree resultTy loc = 
      let
	val failureExp = 
	    case kind
	    of Handle v => ME.handleFail v resultTy loc
	     | Match => ME.raiseMatchFailExp resultTy loc
	     | Bind => ME.raiseBindFailExp resultTy loc
(*
        fun getTagNums (tyCon : tyCon) = 
	    SEnv.numItems ((#datacon tyCon))
*)
	fun getTagNums (tyCon : Types.tyCon) = 
            case SymbolEnv.listItems (#conSet tyCon) of
              nil =>  raise Bug.Bug "NON span field in userdefined type"
            | L => List.length L
              
	fun toExp EmptyNode = (VarInfoSet.empty, failureExp)
	  | toExp (LeafNode (branchId, env)) =
            let
              val branchData 
                  as {
                       tpexp, 
                       isSmall,
                       useCount,
                       funVarId,
                       funLabel,
                       funBodyTy,
                       funTy,
                       funLoc,
                       funArgs
                     } : branchData
                = 
                case IEnv.find(branchEnv, branchId) of
                  SOME branchData => branchData
                | NONE => raise Bug.Bug "MatchCompiler toExp: undefined branchId"
            in
              (
		VarInfoEnv.foldl VarInfoSet.add' VarInfoSet.empty env,
                if !C.doLocalizeCaseBranch
                then
                  if !useCount = 1
                  then compileExp (unionVarInfoEnv(varEnv, env)) btvEnv tpexp
                  else
                    TC.TPTHROW
                      {catchLabel = funLabel,
                       argExpList =
                         map (fn v => case VarInfoEnv.find (env, v) of
                                        SOME v => TC.TPVAR v
                                      | _ => raise Bug.Bug "TPTHROW")
                             funArgs,
                       resultTy = funBodyTy,
                       loc = loc}
                else
                if canInlineBranch branchData
                then compileExp (unionVarInfoEnv(varEnv, env)) btvEnv tpexp
                else
                  case funArgs of 
                    [] => TC.TPAPPM
                           {
                            funExp=
                              TC.TPVAR
                              (makeVar(funVarId, valOf (!funTy))),
                            funTy=valOf (!funTy), 
                            argExpList=[unitExp], 
                            loc=loc
                           }
                  | _ => 
                    if !C.doUncurryingOptimizeInMatchCompile
                    then
                      let
                        val funArgs = 
                            map
                              (fn x => 
                                  case VarInfoEnv.find (env, x) of
                                    SOME v => TC.TPVAR v
                                  | _ =>
                                    raise
                                      Bug.Bug
                                        "match comp, treeToExp, \
                                        \leaf node for fun")
                              funArgs
                      in
                        TC.TPAPPM
                          {
                           funExp =
                           TC.TPVAR
                             (makeVar(funVarId, valOf (!funTy))),
                           funTy = valOf(!funTy), 
                           argExpList = funArgs,
                           loc=funLoc
                          }
                      end
                    else
                      #2 
                       (foldl 
                          (fn (arg, (T.FUNMty([ty1],ty2), func)) => 
                              (ty2,
                               TC.TPAPPM
                                 { 
                                  funExp = func,
                                  funTy = T.FUNMty([ty1], ty2),
                                  argExpList =
                                  case VarInfoEnv.find (env, arg) of
                                    SOME v => [TC.TPVAR v]
                                  | _ =>
                                    raise
                                      Bug.Bug
                                        "match comp, treeToExp,\
                                        \ leaf node for fun",
                                  loc=loc
                                 }
                              )
                            | _ =>
                              raise
                                Bug.Bug "match comp, treeToExp,\
                                      \ leaf node for fun"
                           )
                          (valOf (!funTy),
                           TC.TPVAR
                             (makeVar(funVarId, valOf (!funTy))))
                           funArgs
                          )
              )
            end
	  | toExp (EqNode (path as {ty= pty,...}, branches, defBranch)) = 
	    let
	      val (vars, branches) = 
		    ConstMap.foldri
		    (fn (c, T, (vars, branches)) =>
		        let
			  val (vars', exp) = toExp T
			in
			  (VarInfoSet.union (vars', vars),
                           {const = c, ty = pty, body = exp} :: branches)
			end)
		    (VarInfoSet.empty, [])
		    branches
	      val (defVars, defBranch) = toExp defBranch
	    in
	      ( 
	        VarInfoSet.add (VarInfoSet.union (vars, defVars), path), 
		TC.TPSWITCH
                 {
                  exp = TC.TPVAR path,
                  expTy = pty, 
                  ruleList = TC.CONSTCASE branches,
                  defaultExp = defBranch, 
                  ruleBodyTy = resultTy,
                  loc=loc
                  }
	      )
	    end
	  | toExp
              (DataConNode (varInfo as {ty = pty, path,...},
                            branches,
                            defBranch)) = 
	    let
	      val tyCon = 
                case (TB.derefTy pty) of 
                  T.CONSTRUCTty {tyCon, ...} => tyCon
                | _ => 
                  raise 
                    Bug.Bug 
                    "non tyCon in TagNode (1)\
                    \ (matchcompilation/main/MatchCompiler.sml)"
	      val branchNums = DataConMap.numItems branches
	      val (vars, branches) = 
		    DataConMap.foldri
		    (fn ((i, instTyList, hasArg), Ti, (vars, branches)) =>
		      let
			val (vars', exp) = toExp Ti
			val (argOpt, newExp) = 
			    if hasArg then
			      let
				val arg  = getPath Ti
			      in
				(SOME arg, exp)
			      end
			    else
			      (NONE,exp)
		      in
			(
                          VarInfoSet.union (vars', vars),
                          {con=i, instTyList=instTyList, argVarOpt=argOpt, body=newExp} :: branches
                        )
		      end)
		    (VarInfoSet.empty, [])
		    branches
	      val (defVars, defBranch) = 
		  if getTagNums tyCon <> branchNums
		  then toExp defBranch
		  else 
		    case defBranch
		    of EmptyNode =>
                       (VarInfoSet.empty, ME.raiseMatchCompBugExp resultTy loc)
		     | _ => toExp defBranch
	    in
	      ( 
	        VarInfoSet.add (VarInfoSet.union (vars, defVars), varInfo), 
                TC.TPSWITCH
                  {exp = TC.TPVAR varInfo,
                   expTy = pty, 
                   ruleList=TC.CONCASE branches,
                   defaultExp = defBranch, 
                   ruleBodyTy = resultTy,
                   loc= loc
                   }
	      )
	    end
	  | toExp (ExnConNode (var as {ty,...}, branches, defBranch)) = 
	    let
	      val tyCon = 
                  case TB.derefTy ty of 
                    T.CONSTRUCTty {tyCon, ...} => tyCon
                  | _ => 
                    raise 
                      Bug.Bug 
                        "non tyCon in TagNode (2)\
                        \ (matchcompilation/main/MatchCompiler.sml)"
	      val branchNums = ExnConMap.numItems branches
	      val (vars, branches) = 
		    ExnConMap.foldri
		    (fn ((i, hasArg), Ti, (vars, branches)) =>
		      let
			val (vars', exp) = toExp Ti
			val (argOpt, newExp) = 
			    if hasArg then
			      let
				val arg  = getPath Ti
			      in
				(SOME arg, exp)
			      end
			    else
			      (NONE,exp)
		      in
			(
                          VarInfoSet.union (vars', vars),
                          {exn=i, argVarOpt=argOpt, body=newExp} :: branches
                        )
		      end)
		    (VarInfoSet.empty, [])
		    branches
	      val (defVars, defBranch) = 
                  (* spans is infinite, so it always have default branch. *)
                  toExp defBranch
	    in
	      ( 
	        VarInfoSet.add (VarInfoSet.union (vars, defVars), var), 
                TC.TPSWITCH
                  {exp = TC.TPVAR var,
                   expTy = ty, 
                   ruleList=TC.EXNCASE branches,
                   defaultExp = defBranch, 
                   ruleBodyTy = resultTy,
                   loc= loc
                   }
	      )
	    end
	  | toExp (RecNode (path, label, child)) = 
	    let
	      val pi = getPath child
	      val z as (vars, exp) = toExp child
	    in
	      if not (VarInfoSet.member (vars, pi))
	      then z
	      else
		( 
		  VarInfoSet.add (vars, path),
		  TC.TPLET
		  { 
		    decls = [TC.TPVAL
                               ((pi,
                                 TC.TPSELECT
                                 {exp = TC.TPVAR path,
                                  label = label,
                                  expTy = #ty path,
                                  resultTy = #ty pi,
                                  loc=loc
                                  }),
                                loc)],
		    body = exp,
                    loc=loc
		  }
		)
	    end
	  | toExp (UnivNode (path, child)) = toExp child
(*
	  | toExp _ = raise Bug.Bug "match comp, treeToRcexp bug"
*)
        val result = #2 (toExp tree)
      in
	result
      end

  and compileExp varEnv btvEnv tpexp =
      case tpexp of
        TC.TPERROR => raise bug "TPERROR"
      | TC.TPDYNAMIC {exp, ty, elemTy, coerceTy, loc} =>
        TC.TPDYNAMIC {exp=compileExp varEnv btvEnv exp,
                      ty=ty, 
                      elemTy=elemTy, 
                      coerceTy = coerceTy, 
                      loc=loc}
      | TC.TPDYNAMICIS {exp, ty, elemTy, coerceTy, loc} =>
        TC.TPDYNAMICIS {exp=compileExp varEnv btvEnv exp,
                        ty=ty, 
                        elemTy=elemTy, 
                        coerceTy = coerceTy, 
                        loc=loc}
      | TC.TPDYNAMICNULL {ty, coerceTy, loc} =>
        TC.TPDYNAMICNULL {ty=ty,
                          coerceTy = coerceTy, 
                          loc=loc}
      | TC.TPDYNAMICTOP {ty, coerceTy, loc} =>
        TC.TPDYNAMICTOP {ty=ty,
                         coerceTy = coerceTy, 
                         loc=loc}
      | TC.TPDYNAMICVIEW {exp, ty, elemTy, coerceTy, loc} =>
        TC.TPDYNAMICVIEW {exp=compileExp varEnv btvEnv exp,
                          ty=ty, 
                          elemTy=elemTy, 
                          coerceTy = coerceTy, 
                          loc=loc}
      | TC.TPDYNAMICCASE 
          {groupListTerm, groupListTy, dynamicTerm, dynamicTy, elemTy, ruleBodyTy, loc} =>
        TC.TPDYNAMICCASE
          {
           groupListTerm = compileExp varEnv btvEnv groupListTerm,
           groupListTy = groupListTy,

           dynamicTerm = compileExp varEnv btvEnv dynamicTerm,
           dynamicTy = dynamicTy,
           elemTy = elemTy,
           ruleBodyTy = ruleBodyTy,
           loc=loc}
      | TC.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
        TC.TPDYNAMICEXISTTAPP
          {existInstMap = compileExp varEnv btvEnv existInstMap,
           exp = compileExp varEnv btvEnv exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | TC.TPCONSTANT {const,ty,loc} =>
        TC.TPCONSTANT {const = const, ty = ty, loc = loc}
      | TC.TPVAR var => 
        (case (VarInfoEnv.find (varEnv, var)) of
           SOME v => TC.TPVAR v
         | NONE => TC.TPVAR (var)
        )
      | TC.TPEXVAR (exVarInfo,loc) => TC.TPEXVAR (exVarInfo, loc)
      | TC.TPRECFUNVAR {var, arity} =>
        raise bug "RECFUNVAR should be eliminated"
      | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} =>
        TC.TPFNM
          {
           argVarList= argVarList,
           bodyTy=bodyTy,
           bodyExp=compileExp varEnv btvEnv bodyExp,
           loc=loc
          }
      | TC.TPAPPM {funExp, funTy, argExpList, loc} =>
	TC.TPAPPM
          {
           funExp=compileExp varEnv btvEnv funExp,
           funTy=funTy,
           argExpList=map (compileExp varEnv btvEnv) argExpList,
           loc=loc
          }
      | TC.TPDATACONSTRUCT {con, instTyList=tys, argExpOpt, loc} =>
        TC.TPDATACONSTRUCT
          {
           con=con, 
           instTyList=tys, 
           argExpOpt =
           case argExpOpt of
             NONE => NONE 
           | SOME tpexp => SOME (compileExp varEnv btvEnv tpexp),
           loc=loc
          }
      | TC.TPEXNCONSTRUCT {exn, argExpOpt, loc} =>
        TC.TPEXNCONSTRUCT
          {
           exn=exn, 
           argExpOpt =
           case argExpOpt of
             NONE => NONE 
           | SOME tpexp => SOME (compileExp varEnv btvEnv tpexp),
           loc=loc
          }
      | TC.TPEXNTAG {exnInfo,loc} =>
        TC.TPEXNTAG {exnInfo=exnInfo,loc=loc}
      | TC.TPEXEXNTAG {exExnInfo,loc} =>
        TC.TPEXEXNTAG {exExnInfo=exExnInfo,loc=loc}
      | TC.TPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
	 let
(* 徳永君，systemModeError関数を，locとruleListを引数として呼び出すと，
  (interactive):5.0-5.28 Error:
    Fancy pattern not allowed in the operating system coding mode:
        :: ((1, 2), nil ) => ...
のようなエラーメッセージを出力してコンパイルが終了します．
           val _ = systemModeError (loc, ruleList)
*)
	   val (topVarList, topBinds) = 
               foldr
                 (fn ((exp, ty1), (topVarList, topBinds))
                     => case exp of 
                          TC.TPVAR var => 
                          (case (VarInfoEnv.find (varEnv, var)) of
                             SOME v => (v::topVarList, topBinds)
                           | NONE => (var::topVarList, topBinds)
                          )
                        | _ => 
                          let
                            val newVar =
                                freshVar ty1
                            val rcexp = compileExp varEnv btvEnv exp
                          in
                            (newVar::topVarList, (newVar, rcexp)::topBinds)
                          end
                 )
                 (nil,nil)
                 (ListPair.zip (expList, expTyList))
	   val caseKind = 
	       case caseKind
	       of PC.MATCH => Match
	        | PC.BIND => Bind
	        | PC.HANDLE => 
                    (case topVarList of
                       [v] => (Handle v)
                     | _ =>
                       raise
                         Bug.Bug "non single var in casem for handler"
                     )
	   val tpPatListTpexpUseCountList = 
                map (fn tpRule  => (tpRule, ref 0)) ruleList
	   val patListTpexpUseCountList =
               map (fn ({args, body}, useCount)  => 
                    ((map
                        (tppatToPat btvEnv (getAllVars body))
                        args, 
                      body), 
                     useCount)) 
               tpPatListTpexpUseCountList
	   val (branchEnv, rules) =
               makeRules ruleBodyTy patListTpexpUseCountList loc
	   val _ = ME.clearFlag ME.NotExhaustive
	   val tree = matchToTree branchEnv topVarList rules
	   val redundantFlag = haveRedundantRules branchEnv
	   val _ = if redundantFlag then ME.setFlag ME.Redundant else ()
	   val _ = ME.checkError
                     (caseKind,
                      redundantFlag,
                      ME.isNotExhaustive (),
                      map (fn ({args, body}, useCount) =>
                              ((args, body), useCount)) 
                          tpPatListTpexpUseCountList,
                      loc)

           val catchExp =
               if !C.doLocalizeCaseBranch andalso not (IEnv.isEmpty branchEnv)
               then
                 SOME
                   (IEnv.foldl
                      (fn ({funLabel, funBodyTy, funArgs, tpexp, useCount, ...}, z) =>
                          if !useCount = 1
                          then z
                          else
                            let
                              val catchExp = compileExp varEnv btvEnv tpexp
                            in
                              (fn k => TC.TPCATCH {catchLabel = funLabel,
                                                   argVarList = funArgs,
                                                   catchExp = catchExp,
                                                   tryExp = k,
                                                   resultTy = funBodyTy,
                                                   loc = loc})
                              o z
                            end)
                      (fn x => x)
                      branchEnv)
               else NONE

           val funDecs = 
               if !C.doLocalizeCaseBranch then nil else
               IEnv.foldl 
               (fn (branchData
                    as {
                         tpexp, 
                         isSmall,
                         useCount,
                         funVarId,
                         funLabel,
                         funBodyTy,
                         funLoc,
                         funTy = funTyRef,
                         funArgs
                       } : branchData,
                    funDecs)
                => if canInlineBranch branchData 
                   then funDecs
                   else 
                     let
                       val (funTerm, funTy) = 
                         if !C.doUncurryingOptimizeInMatchCompile
                         then
                           makeUncurriedFun
                             funArgs
                             (compileExp varEnv btvEnv tpexp)
                             funBodyTy
                             funLoc
                         else
                           makeNestedFun
                             funArgs
                             (compileExp varEnv btvEnv tpexp)
                             funBodyTy
                             funLoc
                       val _ = funTyRef := (SOME funTy)
                     in
                       (makeVar(funVarId, funTy), funTerm)::funDecs
                     end
              )
               nil
               branchEnv
	 in
	   if redundantFlag
	   then expDummy
	   else
             case (topBinds,funDecs,catchExp) of
               (nil, nil, NONE) =>
               treeToRcexp
                 varEnv btvEnv branchEnv caseKind tree ruleBodyTy loc
             | (topBinds, funDecs, NONE) =>
               TC.TPLET
                 {
                  decls= map (fn x => TC.TPVAL (x, loc)) (topBinds @ funDecs),
                  body=
                    treeToRcexp
                    varEnv btvEnv branchEnv caseKind tree ruleBodyTy loc,
                  loc=loc
                 }
             | (topBinds, _, SOME catchExp) =>
               (case topBinds of
                  nil => (fn x => x)
                | _::_ =>
                  (fn k => TC.TPLET
                             {decls = map (fn x => TC.TPVAL (x, loc)) topBinds,
                              body = k,
                              loc = loc}))
                 (catchExp
                    (treeToRcexp
                       varEnv btvEnv branchEnv caseKind tree ruleBodyTy loc))
         end
      | TC.TPSWITCH {exp, expTy, ruleList, defaultExp, ruleBodyTy, loc} =>
        let
          fun compileRule r = r # {body = compileExp varEnv btvEnv (#body r)}
        in
          TC.TPSWITCH
            {exp = compileExp varEnv btvEnv exp,
             expTy = expTy,
             ruleList =
               case ruleList of
                 TC.CONSTCASE rules => TC.CONSTCASE (map compileRule rules)
               | TC.CONCASE rules => TC.CONCASE (map compileRule rules)
               | TC.EXNCASE rules => TC.EXNCASE (map compileRule rules),
             defaultExp = compileExp varEnv btvEnv defaultExp,
             ruleBodyTy = ruleBodyTy,
             loc = loc}
        end
      | TC.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
        TC.TPCATCH
          {catchLabel = catchLabel,
           argVarList = argVarList,
           catchExp = compileExp varEnv btvEnv catchExp,
           tryExp = compileExp varEnv btvEnv tryExp,
           resultTy = resultTy,
           loc = loc}
      | TC.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
        TC.TPTHROW
          {catchLabel = catchLabel,
           argExpList = map (compileExp varEnv btvEnv) argExpList,
           resultTy = resultTy,
           loc = loc}
      | TC.TPPRIMAPPLY {primOp, instTyList, argExp, loc} =>
        TC.TPPRIMAPPLY
          {
            primOp=primOp,
            instTyList=instTyList,
            argExp=compileExp varEnv btvEnv argExp,
            loc=loc
           }
      | TC.TPOPRIMAPPLY {oprimOp, instTyList, argExp, loc} =>
        TC.TPOPRIMAPPLY
          {
           oprimOp=oprimOp,
           instTyList=instTyList,
           argExp=compileExp varEnv btvEnv argExp,
           loc=loc
          }
      | TC.TPRECORD {fields, recordTy=ty, loc} =>
        TC.TPRECORD
          {
           fields=RecordLabel.Map.map (compileExp varEnv btvEnv) fields,
           recordTy=ty, 
           loc=loc
          }
       | TC.TPSELECT {label, exp, expTy=ty, resultTy, loc} => 
	 TC.TPSELECT
           {
            label = label,
            exp=compileExp varEnv btvEnv exp,
            expTy=ty, 
            resultTy = resultTy,
            loc=loc
           }
       | TC.TPMODIFY
           {label,
            recordExp=exp1,
            recordTy=ty1,
            elementExp=exp2,
            elementTy=ty2,
            loc} =>
	 TC.TPMODIFY
           {
            label = label,
            recordExp=compileExp varEnv btvEnv exp1,
            recordTy=ty1,
            elementExp=compileExp varEnv btvEnv exp2,
            elementTy=ty2,
            loc=loc
           }
      | TC.TPMONOLET {binds, bodyExp, loc} => 
        TC.TPLET
          {
           decls=
             map (fn (v, e) =>
                     TC.TPVAL ((v, compileExp varEnv btvEnv e), loc))
                 binds,
           body = compileExp varEnv btvEnv bodyExp,
           loc=loc
          }
      | TC.TPLET {decls, body, loc} =>
	TC.TPLET
          {decls= map (tpdecToRcdec varEnv btvEnv) decls,
           body= compileExp varEnv btvEnv body,
           loc=loc
          }

      | TC.TPRAISE {exp, ty, loc} =>
        TC.TPRAISE {exp=compileExp varEnv btvEnv exp, ty=ty, loc=loc}
      | TC.TPHANDLE {exp=exp1, exnVar, handler=exp2, resultTy, loc} => 
	TC.TPHANDLE
          {
           exp=compileExp varEnv btvEnv exp1,
           exnVar= exnVar,
           handler=compileExp varEnv btvEnv exp2,
           resultTy = resultTy,
           loc=loc
          }
       | TC.TPPOLY {btvEnv=localBtvEnv, constraints, expTyWithoutTAbs=ty, exp=exp, loc} =>
         TC.TPPOLY
           {
            btvEnv=localBtvEnv, 
            constraints = constraints,
            expTyWithoutTAbs=ty, 
            exp=compileExp varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp,
            loc=loc
            }
       | TC.TPTAPP {exp, expTy=ty1, instTyList=tys, loc} =>
         TC.TPTAPP
           {
            exp=compileExp varEnv btvEnv exp,
            expTy=ty1, 
            instTyList=tys, 
            loc=loc
           }
      | TC.TPFFIIMPORT {funExp, ffiTy, stubTy, loc} =>
        TC.TPFFIIMPORT
          {funExp =
             case funExp of
               TC.TPFFIFUN (tpexp1, ty1) =>
               TC.TPFFIFUN (compileExp varEnv btvEnv tpexp1, ty1)
             | TC.TPFFIEXTERN s => TC.TPFFIEXTERN s,
           ffiTy = ffiTy,
           stubTy = stubTy,
           loc = loc}
      | TC.TPFOREIGNSYMBOL {name, ty, loc} =>
        TC.TPFOREIGNSYMBOL {name = name, ty = ty, loc = loc}
      | TC.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        TC.TPFOREIGNAPPLY
          {funExp = compileExp varEnv btvEnv funExp,
           argExpList = map (compileExp varEnv btvEnv) argExpList,
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | TC.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        TC.TPCALLBACKFN
          {attributes = attributes,
           argVarList = argVarList,
           bodyExp = compileExp varEnv btvEnv bodyExp,
           resultTy = resultTy,
           loc = loc}
      | TC.TPSIZEOF (ty, loc) => TC.TPSIZEOF (ty, loc)
      | TC.TPREIFYTY (ty, loc) => TC.TPREIFYTY (ty, loc)
      | TC.TPCAST ((exp, expTy), ty, loc) =>
        TC.TPCAST((compileExp varEnv btvEnv exp, expTy), ty, loc)
      | TC.TPJOIN {isJoin, ty, args = (arg1, arg2), argtys = (argty1, argty2), loc} =>
        TC.TPJOIN
          {
           ty=ty,
           args=(compileExp varEnv btvEnv arg1, compileExp varEnv btvEnv arg2),
           argtys=(argty1,argty2),
           isJoin = isJoin,
           loc=loc
          }

  and tpdecToRcdec varEnv btvEnv tpdec = 
      case tpdec of
        TC.TPVAL (bind, loc) =>
        let
          fun toRcbind (var, exp) = 
              (var, compileExp varEnv btvEnv exp)
        in
	  TC.TPVAL (toRcbind bind, loc)
        end
       | TC.TPVALREC (binds, loc) =>
         let
           fun toRcbind {var, exp} = 
             {var=var, exp = compileExp varEnv btvEnv exp}
         in
	   TC.TPVALREC (map toRcbind binds, loc)
         end
       | TC.TPVALPOLYREC {btvEnv=localBtvEnv, constraints, recbinds=binds, loc} =>
         let
           fun toRcbind {var, exp} =
               {var=var,
                exp = compileExp
                        varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp}
         in
	   TC.TPVALPOLYREC {btvEnv = localBtvEnv,
                            constraints = constraints,
                            recbinds = map toRcbind binds,
                            loc = loc}
         end
       | TC.TPFUNDECL (funbinds, loc) =>
         raise bug "TPFUNDECL should be eliminated"
       | TC.TPPOLYFUNDECL {btvEnv, constraints, recbinds, loc} =>
         raise bug "TPPOLYFUNDECL: FIXME: not yet"
       | TC.TPEXD (exnInfo, loc) =>
         TC.TPEXD (exnInfo, loc)
       | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) => 
         TC.TPEXNTAGD ({exnInfo=exnInfo, varInfo = varInfo}, loc)
       | TC.TPEXPORTVAR {var, exp} =>
         TC.TPEXPORTVAR {var = var, exp = compileExp varEnv btvEnv exp}
       | TC.TPEXPORTEXN exnInfo => TC.TPEXPORTEXN exnInfo
       | TC.TPEXTERNVAR exVarInfo => TC.TPEXTERNVAR exVarInfo
       | TC.TPEXTERNEXN exExnInfo => TC.TPEXTERNEXN exExnInfo
       | TC.TPBUILTINEXN exExnInfo => TC.TPBUILTINEXN exExnInfo

  fun compile tpdecls =
      let
        val _ = nextBranchId := 0
	val _ = ME.clearFlag ME.Redundant
	val _ = ME.clearErrorMessages ()
	val topBlockList =
            map (tpdecToRcdec VarInfoEnv.empty BoundTypeVarID.Map.empty)
                tpdecls
      in
	  if ME.isRedundant ()
	  then raise UE.UserErrors (rev (ME.getErrorMessages ()))
	  else (topBlockList, rev (ME.getErrorMessages ()))
      end
      handle exn => raise exn

end
end
