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
                -> RecordCalc.rcdecl list * UserError.errorInfo list

end =
struct
local
  structure C = Control
  structure A = Absyn
  structure T = Types
  structure PC = PatternCalc
  structure TC = TypedCalc
  structure TB = TypesBasics
  structure TCU = TypedCalcUtils
  structure RC = RecordCalc
  structure UE = UserError
  structure BT = BuiltinTypes
  structure ME = MatchError
  fun bug s = Bug.Bug ("MatchCompiler: " ^ s)
  type path = string list
  type constant = Absyn.constant
  type conInfo = T.conInfo

  val pos = Loc.makePos {fileName="MatchCompiler.sml", line=0, col=0}
  val loc = (pos,pos)
  fun mkSymbol string = Symbol.mkSymbol string loc
  fun mkLongsymbol path = Symbol.mkLongsymbol path loc

  fun newLocalId () = VarID.generate ()
  fun newVarName () = TCU.newTCVarName()
  fun newVarPath () = [TCU.newTCVarName()]
  fun freshVarWithName (ty,name) =
      {path = [name],ty=ty,id=newLocalId()} : RC.varInfo
  fun freshVarWithPath (ty,path) =
      {path= path,ty=ty,id=newLocalId()} : RC.varInfo
  fun makeVar (id, path, ty) = {path = path,ty=ty,id=id} : RC.varInfo
  fun printVarInfo var =
      print (Bug.prettyPrint (RC.format_varInfo var))

  open MatchData

  fun toRC {longsymbol, id, ty, opaque} =
      {path=Symbol.longsymbolToLongid longsymbol,
       id = id,
       ty = ty}
  fun toRCcon {longsymbol, id, ty} =
      {path=Symbol.longsymbolToLongid longsymbol,
       id = id,
       ty = ty}
  fun toRCEx {longsymbol, ty} =
      {path=Symbol.longsymbolToLongid longsymbol,
       ty = ty}

  fun toRCExn (TC.EXN exnInfo) = RC.EXN (toRCcon exnInfo)
    | toRCExn (TC.EXEXN exExn) =  
      RC.EXEXN (toRCEx exExn)

  (* this function collects all the variables free or bound.
     This is used to optimize variable pattern to wild pattern
     when the variable is not used.
   *)
  fun getAllVars tpexp =
      let
        fun get (tpexp, set) =
            case tpexp  of
              TC.TPERROR => set
            | TC.TPCONSTANT {const,ty,loc} => set
            | TC.TPVAR varInfo => VarInfoSet.add(set, toRC varInfo)
            | TC.TPEXVAR exVarInfo => set
            | TC.TPRECFUNVAR {var, arity} => VarInfoSet.add(set, toRC var)
            | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} => get (bodyExp,set)
            | TC.TPAPPM {funExp, funTy, argExpList, loc} =>
              foldl get (get (funExp, set)) argExpList
            | TC.TPDATACONSTRUCT {argExpOpt=NONE,...} => set
            | TC.TPDATACONSTRUCT {argExpOpt=SOME exp,...} => get (exp,set)
            | TC.TPEXNCONSTRUCT {argExpOpt=NONE,...} => set
            | TC.TPEXNCONSTRUCT {argExpOpt=SOME exp,...} => get (exp, set)
            | TC.TPEXN_CONSTRUCTOR _ => set
            | TC.TPEXEXN_CONSTRUCTOR _ => set
            | TC.TPCASEM {expList,ruleList,...} =>
              foldl
                (fn ({args, body},set) => get(body, set))
                (foldl get set expList)
                ruleList
            | TC.TPPRIMAPPLY {argExp=exp,...} => get (exp, set)
            | TC.TPOPRIMAPPLY {argExp=exp,...} => get (exp, set)
            | TC.TPRECORD {fields, recordTy, loc} =>
              LabelEnv.foldl get set fields
            | TC.TPSELECT {label, exp, expTy, resultTy, loc} => get (exp,set)
            | TC.TPMODIFY {recordExp,elementExp,...} =>
              get(elementExp, get(recordExp, set))
            | TC.TPSEQ {expList, expTyList, loc} => foldl get set expList 
            | TC.TPMONOLET {binds, bodyExp, loc} =>
              get(bodyExp,foldl(fn ((var,exp),set) => get(exp,set)) set binds)
            | TC.TPLET {decls, body, tys, loc} =>
              foldl get (foldl getDecl set decls) body
            | TC.TPRAISE {exp, ty, loc} => get(exp, set)
            | TC.TPHANDLE {exp, exnVar, handler, resultTy, loc} =>
              get(handler, get(exp, set))
            | TC.TPPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
              get(bodyExp, set)
            | TC.TPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} => get(exp, set)
            | TC.TPTAPP {exp, expTy, instTyList, loc} => get(exp, set)
            | TC.TPFFIIMPORT {funExp=TC.TPFFIFUN ptrExp, ffiTy, stubTy, loc} => get(ptrExp, set)
            | TC.TPFFIIMPORT {funExp=TC.TPFFIEXTERN _, ffiTy, stubTy, loc} => set
            | TC.TPCAST ((tpexp, expTy), ty, loc) => get(tpexp, set)
            | TC.TPSIZEOF (ty, loc) => set
        and getDecl (decl, set) =
            case decl of
              TC.TPVAL (valIdTpexpList, loc) =>
              foldl (fn ((var,exp), set) => get (exp, set)) set valIdTpexpList
            | TC.TPFUNDECL (funBindlist, loc) =>
              foldl
                (fn ({ruleList,...}, set) =>
                    foldl (fn({args,body},set)=>get(body,set)) set ruleList)
                set
                funBindlist
            | TC.TPPOLYFUNDECL (btvEnv, funBindList, loc) =>
              foldl
                (fn ({ruleList,...}, set) =>
                    foldl (fn({args,body},set)=>get(body,set)) set ruleList)
                set
                funBindList
            | TC.TPVALREC (varExpTyEexpList, loc) =>
              foldl 
                (fn ({exp,...},set) => get(exp, set))
                set
                varExpTyEexpList
            | TC.TPVALPOLYREC (btvEnv, varExpTyEexpList, loc) =>
              foldl 
                (fn ({exp,...},set) => get(exp, set))
                set
                varExpTyEexpList 
            | TC.TPEXD (exnconLocList, loc) => set
            | TC.TPEXNTAGD ({varInfo,...},loc) => VarInfoSet.add(set, toRC varInfo)
            | TC.TPEXPORTVAR varInfo => 
              VarInfoSet.add(set, toRC varInfo) 
              (* this case never happen; but this is more correct *)
            | TC.TPEXPORTRECFUNVAR {var, arity} => 
              VarInfoSet.add(set, toRC var) 
              (* this case never happen; but this is more correct *)
            | TC.TPEXPORTEXN exnInfo => set
            | TC.TPEXTERNVAR exVarInfo => set
            | TC.TPEXTERNEXN exExnInfo => set
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
                     funVarPath : path,
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
        | TC.TPCONSTANT {const, ty, loc} => limitCheck itemList (n + 1)
        | TC.TPVAR varIdInfo => limitCheck itemList (n + 1)
        | TC.TPEXVAR exVarInfo => limitCheck itemList (n + 1)
        | TC.TPRECFUNVAR {var, arity} => limitCheck itemList (n + 1)
        | TC.TPFNM {argVarList=varIdInfoList, bodyTy, bodyExp, loc} => 
            limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPAPPM {funExp=tpexp1, funTy=ty, argExpList=tpexpList, loc} => 
          limitCheck (Exp tpexp1 :: (map Exp tpexpList) @ itemList) (n + 1)
        | TC.TPDATACONSTRUCT
            {con=conIdInfo,
             instTyList=tyList,
             argExpOpt=NONE, 
             argTyOpt,
             loc} => limitCheck itemList (n + 1)
        | TC.TPDATACONSTRUCT
            {con=conIdInfo,
             instTyList=tyList,
             argExpOpt=SOME tpexp1,
             argTyOpt,
             loc} => 
            limitCheck (Exp tpexp1 :: itemList) (n + 1)
        | TC.TPEXNCONSTRUCT
            {exn=conIdInfo, instTyList=tyList, argExpOpt=NONE, argTyOpt, loc} =>
          limitCheck itemList (n + 1)
        | TC.TPEXNCONSTRUCT
            {exn=conIdInfo,
             instTyList=tyList,
             argExpOpt=SOME tpexp1,
             argTyOpt,
             loc} => 
            limitCheck (Exp tpexp1 :: itemList) (n + 1)
        | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} => limitCheck itemList (n + 1)
        | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} => limitCheck itemList (n + 1)
        | TC.TPCASEM {expList,expTyList,ruleList,ruleBodyTy,caseKind,loc} =>
            limitCheck
              (map Exp expList
               @
               map (fn {args, body} => Exp body) ruleList 
               @
               itemList
              ) 
            (n + 1)
        | TC.TPPRIMAPPLY {primOp,instTyList,argExp=tpexp1,argTy,loc} => 
          limitCheck (Exp tpexp1::itemList) (n + 1)
        | TC.TPOPRIMAPPLY {argExp=tpexp1,...} =>
          limitCheck (Exp tpexp1::itemList) (n + 1)
        | TC.TPRECORD {fields, recordTy=ty, loc} => 
            limitCheck
              ((map (fn (l,tpexp) => Exp tpexp) (LabelEnv.listItemsi fields))
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
        | TC.TPSEQ {expList, ...} =>
            limitCheck (map Exp expList @ itemList) (n + 1)
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
        | TC.TPLET {decls, body, tys, loc} =>
          limitCheck ((map Decl decls) @ (map Exp body) @ itemList) (n + 1)
        | TC.TPRAISE {exp, ty, loc} =>
          limitCheck (Exp exp :: itemList) (n + 1)
        | TC.TPHANDLE {exp=tpexp1,  exnVar=varIdInfo, handler=tpexp2,
                       resultTy, loc} =>
            limitCheck (Exp tpexp1 :: Exp tpexp2 :: itemList) (n + 1)
        | TC.TPPOLYFNM {btvEnv=btvKindIEnvMap, 
                      argVarList=varIdInfoList, 
                      bodyTy=ty, 
                      bodyExp=tpexp, 
                      loc} =>
            limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPPOLY
            {btvEnv=btvKindIEnvMap,
             expTyWithoutTAbs=ty,
             exp=tpexp,
             loc} =>
            limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPTAPP {exp=tpexp, expTy=ty1, instTyList=tylist, loc} => 
            limitCheck (Exp tpexp :: itemList) (n + 1)
        | TC.TPFFIIMPORT
            {
             funExp=TC.TPFFIFUN tpexp1, 
             ...
            } => 
            limitCheck (Exp tpexp1 :: itemList) (n + 1)
        | TC.TPFFIIMPORT {funExp=TC.TPFFIEXTERN _, ...} =>
          limitCheck itemList (n + 1)
        | TC.TPSIZEOF _ => limitCheck itemList (n + 1)
        | TC.TPCAST ((tpexp, expTy), ty, loc) =>
          limitCheck (Exp tpexp :: itemList) (n + 1)


      and limitCheckDecl tfpdecl itemList n = 
        case tfpdecl of
          TC.TPVAL (valIdtpexpList, loc) => 
            limitCheck
              ((map (fn (varId, tpexp) => Exp tpexp) valIdtpexpList)
               @ itemList) (n + 1)
        | TC.TPFUNDECL _ => raise bug "TC.TPFUNDECL in MatchCompiler"
        | TC.TPPOLYFUNDECL  _ => raise bug "TC.TPPOLYFUNDECL in MatchCompiler"
        | TC.TPVALREC (varTyExpList,loc) =>
          limitCheck
            ((map (fn {var, expTy, exp} => Exp exp) varTyExpList)
             @ itemList) (n + 1)
        | TC.TPVALPOLYREC (btvKindIEnvMap, varTyExpList, loc) =>
          limitCheck
            ((map (fn {var,expTy,exp} => Exp exp) varTyExpList)
             @ itemList) (n + 1)
        | TC.TPEXD (exnconLocList, loc) => limitCheck itemList (n + 1)
        | TC.TPEXNTAGD (bind, loc) => limitCheck itemList (n + 1)
        | TC.TPEXPORTVAR varInfo => limitCheck itemList (n + 1)
        | TC.TPEXPORTRECFUNVAR {var, arity} => limitCheck itemList (n + 1)
        | TC.TPEXPORTEXN exnInfo => limitCheck itemList (n + 1)
        | TC.TPEXTERNVAR exVarInfo => limitCheck itemList (n + 1)
        | TC.TPEXTERNEXN exExnInfo => limitCheck itemList (n + 1)
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
      | T.TYVARty(ref(T.TVAR{tvarKind = T.REC fields, ...})) => fields
      | T.BOUNDVARty index =>
        (case BoundTypeVarID.Map.find (btvEnv, index) of
           SOME{tvarKind = T.REC fields, ...} => fields
         | _ =>
           raise
             Bug.Bug
             ("getFieldsOfTy found invalid BTV("
              ^ BoundTypeVarID.toString index ^ ")"))
      | ty =>
        raise
          Bug.Bug
              ("getFieldsOfTy found unexpected:"
               ^ T.tyToString ty)

  fun getTagNums {ty, path, id} = 
      let
        val tyCon = 
            case TB.derefTy ty of
              T.FUNMty(args, ty) =>
              (case TB.derefTy ty of
                 T.CONSTRUCTty{tyCon, ...} => tyCon
               | _ => 
                 (print "getTagNums\n";
                  T.printTy ty;
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
                     T.printTy ty;
                     print "\n";
                     raise bug "Non conty in userdefined type"
                    )
                 )
               | T.CONSTRUCTty{tyCon, ...} => tyCon
               | _ => 
                 (print "getTagNums\n";
                  T.printTy ty;
                  print "\n";
                  raise bug "Non conty in userdefined type"
                 )
              )
            | T.CONSTRUCTty{tyCon, ...} => tyCon
            | _ => 
              (print "getTagNums\n";
               T.printTy ty;
               print "\n";
               raise bug "Non conty in userdefined type"
              )
      in
        case SEnv.listItems (#conSet tyCon) of
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
      | (DataConPat (_, _, _, ty)) => ty
      | (ExnConPat (_, _, _, ty)) => ty
      | (RecPat (_, ty)) => ty
      | (LayerPat (pat, _)) => getTyInPat pat
      | (OrPat (pat, _)) => getTyInPat pat

  (* ADDED for type preservation *)
  fun getPathInPat pat =
      case pat of
        (WildPat _) => newVarPath ()
      | (VarPat ({path, ... })) => path
      | (ConstPat _) => newVarPath ()
      | (DataConPat _) => newVarPath ()
      | (ExnConPat _) => newVarPath ()
      | (RecPat _) => newVarPath ()
      | (LayerPat (pat, _)) => getPathInPat pat
      | (OrPat (pat, _)) => getPathInPat pat

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
         RC.RCFNM
           {
            argVarList =
            [freshVarWithName (BT.unitTy, "unitExp(" ^ newVarName () ^ ")")],
            bodyTy=bodyTy, 
            bodyExp=body, 
            loc=loc
           },
         T.FUNMty ([BT.unitTy], bodyTy)
        )
      | argList =>
        foldr 
          (fn (arg, (body, bodyTy)) => 
              (RC.RCFNM {argVarList=[arg],
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
        RC.RCFNM 
          {
           argVarList=[freshVarWithName
                         (BT.unitTy,"unitExp(" ^ newVarName () ^ ")")], 
           bodyTy=bodyTy, 
           bodyExp=body, 
           loc=loc
          },
        T.FUNMty ([BT.unitTy], bodyTy)
       )
     | argList =>
       (
        RC.RCFNM 
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
          | getVars (DataConPat (_, _, argPat, _)) = getVars argPat
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
                  funVarPath = newVarPath (),
                  funVarId = newLocalId(),
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
        if VarInfoSet.member (FV, toRC x) then VarPat (toRC x) else WildPat (#ty x)
      | TC.TPPATCONSTANT (A.UNITCONST _, ty, _) => WildPat ty
      | TC.TPPATCONSTANT (con, ty, _) => ConstPat (con, ty)
      | TC.TPPATDATACONSTRUCT {conPat, argPatOpt=NONE, patTy=ty, ...} =>
        DataConPat (toRCcon conPat, false, WildPat BT.unitTy, ty)
      | TC.TPPATDATACONSTRUCT{conPat,argPatOpt = SOME argPat,patTy=ty,...}=>
        DataConPat (toRCcon conPat, true, tppatToPat btvEnv FV argPat, ty)
      | TC.TPPATEXNCONSTRUCT {exnPat, argPatOpt=NONE, patTy=ty, ...} =>
        ExnConPat (toRCExn exnPat, false, WildPat BT.unitTy, ty)
      | TC.TPPATEXNCONSTRUCT {exnPat,argPatOpt = SOME argPat,patTy=ty,...} =>
        ExnConPat (toRCExn exnPat, true, tppatToPat btvEnv FV argPat, ty)
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
            LabelEnv.foldri
            (fn (label, ty, pats) =>
             let
               val pat = 
                 case LabelEnv.find(patRows, label) of
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
  		  (DataConPat (tag, hasArg, argPat, ty) ++ rule, env), 
  		  (branches, defBranch)
  		 ) =>
  	         let
  		   val key = (tag, hasArg)
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
  	       (fn ((tag, _), REs as ((pat ++ _, _) :: _)) =>
  		   matchToTree
                     branchEnv
  		     (freshVarWithPath
                        (getTyInPat pat, getPathInPat pat) :: paths)
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
  		     (freshVarWithPath
                        (getTyInPat pat, getPathInPat pat) :: paths)
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
          (label, fieldTy, fieldPath) (path :: paths) REs =
        RecNode	
  	  (
  	   path, 
  	   label,
  	   matchToTree
             branchEnv
  	     (freshVarWithPath (fieldTy,fieldPath) :: paths)
  	     (map
  	        (fn (RecPat ([(_, pat)], _) ++ rule, env) => (pat ++ rule, env)
  	          | (WildPat _ ++ rule, env) => (WildPat fieldTy ++ rule, env)
  	          | _ => raise Bug.Bug "match comp, in makeNRecTree")
  	        REs)
  	  )
      | makeNRecTree _ _ _ _ = raise Bug.Bug "match comp, makeNRecTree"
  
    and makeIRecTree
          branchEnv
          (recordTy, label, fieldTy, fieldPath)
          (paths as (path :: _))
          REs =
        RecNode
          (
  	   path,
  	   label, 
  	   matchToTree
             branchEnv
  	     (freshVarWithPath (fieldTy,fieldPath) :: paths)
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
        | ((DataConPat (tag, _, _, _) ++ _, _) :: _) =>
          makeDataConTree branchEnv (getTagNums tag)
        | ((ExnConPat (tag, _, _, _) ++ _, _) :: _) =>
          makeExnConTree branchEnv 
        | ((RecPat ([], _) ++ _, _) :: _) =>
          makeUnitTree branchEnv
        | ((RecPat ([(label, pat)], _) ++ _, _) :: _) =>
          makeNRecTree
            branchEnv
            (label, getTyInPat pat, getPathInPat pat)
        | ((RecPat ((label, pat) :: _, recTy) ++ _, _) :: _) =>
          makeIRecTree
            branchEnv
            (recTy, label, getTyInPat pat, getPathInPat pat)
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
            case SEnv.listItems (#conSet tyCon) of
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
                       funVarPath,
                       funVarId,
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
                if canInlineBranch branchData
                then tpexpToRcexp (unionVarInfoEnv(varEnv, env)) btvEnv tpexp
                else
                  case funArgs of 
                    [] => RC.RCAPPM
                           {
                            funExp=
                              RC.RCVAR
                              (makeVar(funVarId, funVarPath, valOf (!funTy))),
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
                                    SOME v => RC.RCVAR v
                                  | _ =>
                                    raise
                                      Bug.Bug
                                        "match comp, treeToExp, \
                                        \leaf node for fun")
                              funArgs
                      in
                        RC.RCAPPM
                          {
                           funExp =
                           RC.RCVAR
                             (makeVar(funVarId, funVarPath, valOf (!funTy))),
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
                               RC.RCAPPM 
                                 { 
                                  funExp = func,
                                  funTy = T.FUNMty([ty1], ty2),
                                  argExpList =
                                  case VarInfoEnv.find (env, arg) of
                                    SOME v => [RC.RCVAR v]
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
                           RC.RCVAR
                             (makeVar(funVarId, funVarPath, valOf (!funTy))))
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
			  (VarInfoSet.union (vars', vars), (c, exp) :: branches)
			end)
		    (VarInfoSet.empty, [])
		    branches
	      val (defVars, defBranch) = toExp defBranch
	    in
	      ( 
	        VarInfoSet.add (VarInfoSet.union (vars, defVars), path), 
		RC.RCSWITCH 
                 {
                  switchExp = RC.RCVAR path, 
                  expTy = pty, 
                  branches = branches, 
                  defaultExp = defBranch, 
                  resultTy = resultTy,
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
                          ( i, argOpt, newExp) :: branches
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
		RC.RCCASE
                  {exp = RC.RCVAR varInfo, 
                   expTy = pty, 
                   ruleList=branches, 
                   defaultExp = defBranch, 
                   resultTy = resultTy,
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
                          ( i, argOpt, newExp) :: branches
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
		RC.RCEXNCASE
                  {exp = RC.RCVAR var, 
                   expTy = ty, 
                   ruleList=branches, 
                   defaultExp = defBranch, 
                   resultTy = resultTy,
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
		  RC.RCMONOLET 
		  { 
		    binds = [(pi, 
                              RC.RCSELECT 
                              {exp = RC.RCVAR path, 
                               indexExp = RC.RCINDEXOF (label, #ty path, loc),
                               label = label,
                               expTy = #ty path, 
                               resultTy = #ty pi,
                               loc=loc
                               })],
		    bodyExp = exp,
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

  and tpexpToRcexp varEnv btvEnv tpexp = 
      case tpexp of
        TC.TPERROR => raise bug "TPERROR"
      | TC.TPCONSTANT {const,ty,loc} =>
        RC.RCCONSTANT {const=const,ty=ty,loc=loc}
      | TC.TPVAR var => 
        (case (VarInfoEnv.find (varEnv, toRC var)) of
           SOME v => RC.RCVAR v
         | NONE => RC.RCVAR (toRC var)
        )
      | TC.TPEXVAR exVarInfo => RC.RCEXVAR (toRCEx exVarInfo)
      | TC.TPRECFUNVAR {var, arity} =>
        raise bug "RECFUNVAR should be eliminated"
      | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} =>
        RC.RCFNM 
          {
           argVarList= map toRC argVarList,
           bodyTy=bodyTy,
           bodyExp=tpexpToRcexp varEnv btvEnv bodyExp, 
           loc=loc
          }
      | TC.TPAPPM {funExp, funTy, argExpList, loc} =>
	RC.RCAPPM
          {
           funExp=tpexpToRcexp varEnv btvEnv funExp,
           funTy=funTy,
           argExpList=map (tpexpToRcexp varEnv btvEnv) argExpList,
           loc=loc
          }
      | TC.TPDATACONSTRUCT {con, instTyList=tys, argExpOpt, argTyOpt, loc} => 
        RC.RCDATACONSTRUCT
          {
           con= toRCcon con, 
           instTyList=tys, 
           argExpOpt =
           case argExpOpt of
             NONE => NONE 
           | SOME tpexp => SOME (tpexpToRcexp varEnv btvEnv tpexp),
           argTyOpt = argTyOpt,
           loc=loc
          }
      | TC.TPEXNCONSTRUCT {exn, instTyList, argExpOpt, argTyOpt, loc} =>
        RC.RCEXNCONSTRUCT
          {
           exn= toRCExn exn, 
           instTyList=instTyList,
           argExpOpt =
           case argExpOpt of
             NONE => NONE 
           | SOME tpexp => SOME (tpexpToRcexp varEnv btvEnv tpexp),
           loc=loc
          }
      | TC.TPEXN_CONSTRUCTOR {exnInfo,loc} =>
        RC.RCEXN_CONSTRUCTOR {exnInfo = toRCcon exnInfo,loc=loc}
      | TC.TPEXEXN_CONSTRUCTOR {exExnInfo,loc} =>
        RC.RCEXEXN_CONSTRUCTOR {exExnInfo = toRCEx exExnInfo,loc=loc}
      | TC.TPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
	 let
	   val (topVarList, topBinds) = 
               foldr
                 (fn ((exp, ty1), (topVarList, topBinds))
                     => case exp of 
                          TC.TPVAR var => 
                          (case (VarInfoEnv.find (varEnv, toRC var)) of
                             SOME v => (v::topVarList, topBinds)
                           | NONE => (toRC var::topVarList, topBinds)
                          )
                        | _ => 
                          let
                            val newVar =
                                freshVarWithName 
                                  (ty1, "caseExp(" ^ newVarName () ^ ")")
                            val rcexp = tpexpToRcexp varEnv btvEnv exp
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
           val funDecs = 
               IEnv.foldl 
               (fn (branchData
                    as {
                         tpexp, 
                         isSmall,
                         useCount,
                         funVarPath,
                         funVarId,
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
                             (tpexpToRcexp varEnv btvEnv tpexp)
                             funBodyTy
                             funLoc
                         else
                           makeNestedFun
                             funArgs
                             (tpexpToRcexp varEnv btvEnv tpexp)
                             funBodyTy
                             funLoc
                       val _ = funTyRef := (SOME funTy)
                     in
                       (makeVar(funVarId, funVarPath, funTy), funTerm)::funDecs
                     end
              )
               nil
               branchEnv
	 in
	   if redundantFlag
	   then expDummy
	   else
             case (topBinds,funDecs) of
               (nil, nil) =>
               treeToRcexp
                 varEnv btvEnv branchEnv caseKind tree ruleBodyTy loc
             | _ => 
               RC.RCMONOLET
                 {
                  binds= topBinds @ funDecs, 
                  bodyExp=
                    treeToRcexp
                    varEnv btvEnv branchEnv caseKind tree ruleBodyTy loc,
                  loc=loc
                 }
         end
      | TC.TPPRIMAPPLY {primOp, instTyList, argExp, argTy,loc} =>
        RC.RCPRIMAPPLY 
          {
            primOp=primOp,
            instTyList=instTyList,
            argExp=tpexpToRcexp varEnv btvEnv argExp,
            loc=loc
           }
      | TC.TPOPRIMAPPLY {oprimOp, instTyList, argExp, argTy, loc} =>
        RC.RCOPRIMAPPLY 
          {
           oprimOp=toRCcon oprimOp,
           instTyList=instTyList,
           argExp=tpexpToRcexp varEnv btvEnv argExp,
           loc=loc
          }
      | TC.TPRECORD {fields, recordTy=ty, loc} =>
        RC.RCRECORD 
          {
           fields=LabelEnv.map (tpexpToRcexp varEnv btvEnv) fields, 
           recordTy=ty, 
           loc=loc
          }
       | TC.TPSELECT {label, exp, expTy=ty, resultTy, loc} => 
	 RC.RCSELECT 
           {
            indexExp = RC.RCINDEXOF (label, ty, loc),
            label = label,
            exp=tpexpToRcexp varEnv btvEnv exp, 
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
	 RC.RCMODIFY
           {
            indexExp = RC.RCINDEXOF (label, ty1, loc),
            label = label,
            recordExp=tpexpToRcexp varEnv btvEnv exp1,
            recordTy=ty1,
            elementExp=tpexpToRcexp varEnv btvEnv exp2,
            elementTy=ty2,
            loc=loc
           }
       | TC.TPSEQ {expList, expTyList, loc} =>
         RC.RCSEQ
           {
            expList=map (tpexpToRcexp varEnv btvEnv) expList, 
            expTyList=expTyList, 
            loc=loc
           }
      | TC.TPMONOLET {binds, bodyExp, loc} => 
	RC.RCMONOLET
          {
           binds=
             map (fn (v, e) =>(toRC v, tpexpToRcexp varEnv btvEnv e)) binds,
	   bodyExp=tpexpToRcexp varEnv btvEnv bodyExp,
           loc=loc
          }
      | TC.TPLET {decls, body, tys, loc} => 
	RC.RCLET
          {decls= map (tpdecToRcdec varEnv btvEnv) decls,
           body=map (tpexpToRcexp varEnv btvEnv) body,
           tys=tys,
           loc=loc
          }

      | TC.TPRAISE {exp, ty, loc} =>
        RC.RCRAISE {exp=tpexpToRcexp varEnv btvEnv exp, ty=ty, loc=loc}
      | TC.TPHANDLE {exp=exp1, exnVar, handler=exp2, resultTy, loc} => 
	RC.RCHANDLE
          {
           exp=tpexpToRcexp varEnv btvEnv exp1, 
           exnVar= toRC exnVar, 
           handler=tpexpToRcexp varEnv btvEnv exp2, 
           resultTy = resultTy,
           loc=loc
          }
      | TC.TPPOLYFNM
          {btvEnv=localBtvEnv,
           argVarList=varList,
           bodyTy=ty,
           bodyExp=exp,
           loc} =>
        RC.RCPOLYFNM
          {
           btvEnv=localBtvEnv, 
           argVarList= map toRC varList, 
           bodyTy=ty, 
           bodyExp=
             tpexpToRcexp varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp, 
           loc=loc
          }
       | TC.TPPOLY {btvEnv=localBtvEnv, expTyWithoutTAbs=ty, exp=exp, loc} =>
         RC.RCPOLY 
           {
            btvEnv=localBtvEnv, 
            expTyWithoutTAbs=ty, 
            exp=tpexpToRcexp varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp, 
            loc=loc
            }
       | TC.TPTAPP {exp, expTy=ty1, instTyList=tys, loc} =>
         RC.RCTAPP 
           {
            exp=tpexpToRcexp varEnv btvEnv exp, 
            expTy=ty1, 
            instTyList=tys, 
            loc=loc
           }
      | TC.TPFFIIMPORT {funExp, ffiTy, stubTy, loc} =>
        let
          val funExp =
              case funExp of
                TC.TPFFIFUN tpexp1 =>
                RC.RCFFIFUN (tpexpToRcexp varEnv btvEnv tpexp1)
              | TC.TPFFIEXTERN s => RC.RCFFIEXTERN s
        in
          RC.RCFFI (RC.RCFFIIMPORT {funExp=funExp, ffiTy=ffiTy}, stubTy, loc)
        end
      | TC.TPSIZEOF (ty, loc) => RC.RCSIZEOF (ty, loc)
      | TC.TPCAST ((exp, expTy), ty, loc) =>
         RC.RCCAST((tpexpToRcexp varEnv btvEnv exp, expTy), ty, loc)

  and tpdecToRcdec varEnv btvEnv tpdec = 
      case tpdec of
        TC.TPVAL (binds, loc) =>
        let
          fun toRcbind (var, exp) = 
              (toRC var, tpexpToRcexp varEnv btvEnv exp)
        in
	  RC.RCVAL (map toRcbind binds, loc)
        end
       | TC.TPVALREC (binds, loc) =>
         let
           fun toRcbind {var, expTy, exp} = 
             {var=toRC var, expTy=expTy, exp = tpexpToRcexp varEnv btvEnv exp}
         in
	   RC.RCVALREC (map toRcbind binds, loc)
         end
       | TC.TPVALPOLYREC (localBtvEnv, binds, loc) =>
         let
           fun toRcbind {var, expTy, exp} =
               {var=toRC var,
                expTy = expTy,
                exp = tpexpToRcexp
                        varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp}
         in
	   RC.RCVALPOLYREC (localBtvEnv, map toRcbind binds, loc)
         end
       | TC.TPFUNDECL (funbinds, loc) =>
         raise bug "TPFUNDECL should be eliminated"
       | TC.TPPOLYFUNDECL (btvEnv, funbinds, loc) =>
         raise bug "TPPOLYFUNDECL: FIXME: not yet"
       | TC.TPEXD (binds, loc) => 
         RC.RCEXD (map 
                     (fn {exnInfo, loc} => 
                         {exnInfo = toRCcon exnInfo, loc = loc}
                     )
                     binds, 
                   loc)
       | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) => 
         RC.RCEXNTAGD ({exnInfo=toRCcon exnInfo, varInfo = toRC varInfo}, loc)
       | TC.TPEXPORTVAR varInfo =>
(*
         RC.RCEXPORTVAR ({id=id, path=path, ty=ty}, loc)
*)
         RC.RCEXPORTVAR (toRC varInfo)
       | TC.TPEXPORTRECFUNVAR _ => raise bug "TPEXPORTRECFUNVAR to matchcompiler"
       | TC.TPEXPORTEXN exnInfo => RC.RCEXPORTEXN (toRCcon exnInfo)
       | TC.TPEXTERNVAR exVarInfo => RC.RCEXTERNVAR (toRCEx exVarInfo)
       | TC.TPEXTERNEXN exExnInfo => RC.RCEXTERNEXN (toRCEx exExnInfo)

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
