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

structure MatchCompiler : MATCH_COMPILER = 
struct
  val tyToString = TypeFormatter.tyToString
  fun printTy ty = print (tyToString ty ^ "\n")

  fun newLocalId () = VarID.generate ()

  fun newVarName () = VarName.generate ()

  val nextBranchId = ref 0
  fun newBranchId () = 
    let val next = !nextBranchId 
    in  
      nextBranchId := next + 1 ; 
      next 
    end
  open TypedFlatCalc RecordCalc MatchData
  structure C = Control
  structure CT = ConstantTerm
  structure ME = MatchError
  structure PT = PredefinedTypes
  structure PC = PatternCalc
  structure RCU = RecordCalcUtils
  structure T = Types
  structure TU = TypesUtils
  structure TFCU = TypedFlatCalcUtils
  structure UE = UserError

  type branchData = {
                     funArgs : VarSet.item list,
                     funBodyTy : T.ty,
                     funLoc : Loc.loc,
                     funTy : (T.ty option) ref,
                     funVarId : VarID.id,
                     funVarName : string,
                     isSmall : bool,
                     tfpexp: tfpexp, 
                     useCount : int ref
                    }

  type branchEnv = branchData IEnv.map
  
 (*
   Check whether a given expression is smaller than the limit.
   The functionl only traverses upto the inlineLimit number 
   of constructors in the given expression. 
  *)
  fun isSmall tfpexp = 
    let
      datatype item = Exp of tfpexp | Decl of tfpdecl
      fun limitCheck nil n = true
        | limitCheck (item::itemList) n =
          if n > !C.limitOfInlineCaseBranch then false
          else
            case item of 
              Exp rcepx => limitCheckExp rcepx itemList n 
            | Decl tfpdecl => limitCheckDecl tfpdecl itemList n 

      and limitCheckExp tfpexp itemList n = 
        case tfpexp of
          TFPFOREIGNAPPLY 
            {
             funExp=tfpexp1, 
             funTy=funTy,
             instTyList=tyList1, 
             argExpList=tfpexpList2, 
             argTyList=tyList2,
             ...
            } => 
            limitCheck (Exp tfpexp1 :: (map Exp tfpexpList2)
                        @ itemList) (n + 1)
        | TFPEXPORTCALLBACK
            {
             funExp=tfpexp1,
             argTyList=argTyList,
             resultTy=resultTy,
             attributes=attributes,
             loc
             } => 
            limitCheck (Exp tfpexp1 :: itemList) (n + 1)
        | TFPSIZEOF _ => limitCheck itemList (n + 1)
        | TFPCONSTANT (constant,loc) => limitCheck itemList (n + 1)
        | TFPGLOBALSYMBOL _ => limitCheck itemList (n + 1)
        | TFPVAR (varIdInfo,loc) => limitCheck itemList (n + 1)
        | TFPGETFIELD (tfpexp1, int, ty, loc) => 
            limitCheck (Exp tfpexp1::itemList) (n + 1)
        | TFPARRAY 
            {
             sizeExp=tfpexp1,  
             initExp=tfpexp2,  
             elementTy=ty1, 
             resultTy=ty2, 
             loc
             } => 
            limitCheck (Exp tfpexp1:: Exp tfpexp2 :: itemList) (n + 1)
        | TFPPRIMAPPLY {primOp=primInfo,
                        instTyList=tyList,
                        argExpOpt=NONE, loc} =>
          limitCheck itemList (n + 1)
        | TFPPRIMAPPLY
            {primOp=primInfo,
             instTyList=tyList,
             argExpOpt=SOME tfpexp1,
             loc} => 
            limitCheck (Exp tfpexp1::itemList) (n + 1)
        | TFPOPRIMAPPLY
            {oprimOp=oprimInfo,
             keyTyList=keyTyList,
             instances=tyList,
             argExpOpt=NONE, loc} => limitCheck itemList (n + 1)
        | TFPOPRIMAPPLY
            {oprimOp=oprimInfo, 
             keyTyList=keyTyList,
             instances=tyList, 
             argExpOpt=SOME tfpexp1, 
             loc} => limitCheck (Exp tfpexp1::itemList) (n + 1)
        | TFPDATACONSTRUCT
            {con=conIdInfo,
             instTyList=tyList,
             argExpOpt=NONE, loc} => limitCheck itemList (n + 1)
        | TFPDATACONSTRUCT
            {con=conIdInfo,
             instTyList=tyList,
             argExpOpt=SOME tfpexp1,
             loc} => 
            limitCheck (Exp tfpexp1 :: itemList) (n + 1)
        | TFPEXNCONSTRUCT
            {exn=conIdInfo, instTyList=tyList, argExpOpt=NONE, loc} =>
          limitCheck itemList (n + 1)
        | TFPEXNCONSTRUCT
            {exn=conIdInfo,
             instTyList=tyList,
             argExpOpt=SOME tfpexp1,
             loc} => 
            limitCheck (Exp tfpexp1 :: itemList) (n + 1)
        | TFPAPPM {funExp=tfpexp1, funTy=ty, argExpList=tfpexpList, loc} => 
          limitCheck (Exp tfpexp1 :: (map Exp tfpexpList) @ itemList) (n + 1)
        | TFPMONOLET {binds=nil, bodyExp=tfpexp1, loc} =>
          limitCheck (Exp tfpexp1 :: itemList) (n + 1)
        | TFPMONOLET {binds=(varIdInfo,tfpexp1)::varIdInfotfpexpList, 
                      bodyExp=tfpexp2, 
                      loc} =>
          limitCheck (Exp tfpexp1 :: 
                      Exp (TFPMONOLET
                             {binds=varIdInfotfpexpList,
                              bodyExp=tfpexp2,
                              loc=loc}) ::
                        itemList)
            (n + 1)
        | TFPLET (tfpdeclList, tfpexpList, tyList, loc) =>
          limitCheck ((map Decl tfpdeclList)
                      @ (map Exp tfpexpList)
                      @ itemList)
                     (n + 1)
        | TFPRECORD {fields, recordTy=ty, loc} => 
            limitCheck
              ((map (fn (l,tfpexp) => Exp tfpexp) (SEnv.listItemsi fields))
               @ itemList) (n + 1)
        | TFPSELECT {label=string, exp=tfpexp, expTy=ty, resultTy, loc} 
            => limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPMODIFY {label=string, 
                     recordExp=tfpexp1, 
                     recordTy=ty1, 
                     elementExp=tfpexp2, 
                     elementTy=ty2,  
                     loc} =>
            limitCheck (Exp tfpexp1 :: Exp tfpexp2 :: itemList) (n + 1)
        | TFPRAISE (tfpexp, ty, loc) =>
          limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPHANDLE {exp=tfpexp1,  exnVar=varIdInfo, handler=tfpexp2, loc} =>
            limitCheck (Exp tfpexp1 :: Exp tfpexp2 :: itemList) (n + 1)
        | TFPCASEM {expList=tfpexpList, 
                    expTyList=tyList,  
                    ruleList=tfpPatListTfpexpList, 
                    ruleBodyTy=ty, 
                    caseKind=kind, 
                    loc} =>
            limitCheck
              (map Exp tfpexpList
               @
               map (fn (tfppatList, tfpexp) => Exp tfpexp)
                   tfpPatListTfpexpList 
               @
               itemList
              ) 
            (n + 1)
        | TFPFNM {argVarList=varIdInfoList, bodyTy, bodyExp, loc} => 
            limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPPOLYFNM {btvEnv=btvKindIEnvMap, 
                      argVarList=varIdInfoList, 
                      bodyTy=ty, 
                      bodyExp=tfpexp, 
                      loc} =>
            limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPPOLY
            {btvEnv=btvKindIEnvMap,
             expTyWithoutTAbs=ty,
             exp=tfpexp,
             loc} =>
            limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPTAPP {exp=tfpexp, expTy=ty1, instTyList=tylist, loc} => 
            limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPLIST {expList, ...} =>
            limitCheck (map Exp expList @ itemList) (n + 1)
        | TFPSEQ {expList, ...} =>
            limitCheck (map Exp expList @ itemList) (n + 1)
        | TFPCAST (tfpexp, ty, loc) =>
          limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPSQLSERVER {server, schema, resultTy, loc} =>
            limitCheck (map (Exp o #2) server @ itemList) (n + 1)

      and limitCheckDecl tfpdecl itemList n = 
        case tfpdecl of
          TFPVAL (valIdtfpexpList, loc) => 
            limitCheck
              ((map (fn (varId, tfpexp) => Exp tfpexp) valIdtfpexpList)
               @ itemList) (n + 1)
        | TFPVALREC (varIdInfoTytfpexpList,loc) =>
          limitCheck
            ((map (fn (varIdInfo, ty, tfpexp) => Exp tfpexp)
                  varIdInfoTytfpexpList)
             @ itemList) (n + 1)
        | TFPVALPOLYREC (btvKindIEnvMap, varIdInfoTyTfpexpList, loc) =>
          limitCheck
            ((map (fn (varIdInfo, ty, tfpexp) => Exp tfpexp)
                  varIdInfoTyTfpexpList)
             @ itemList) (n + 1)
        | TFPLOCALDEC (tfpdeclList1, tfpdeclList2, loc) =>
          limitCheck
            (map Decl tfpdeclList1 @ map Decl tfpdeclList2 @ itemList)
            (n + 1)
        | TFPSETFIELD (tfpexp1, tfpexp2, int, ty, loc) => 
          limitCheck (Exp tfpexp1 :: Exp tfpexp2 :: itemList) (n + 1)
        | TFPEXNBINDDEF _ => limitCheck itemList (n + 1)
        | TFPFUNCTORDEC _ =>
          raise Control.Bug "functor declaration should be on top"
        | TFPLINKFUNCTORDEC _ =>
          raise Control.Bug "functor declaration should be on top"
    in
      limitCheck [(Exp tfpexp)] 0
    end

(* *)
  infixr ++
  infixr +++
  fun nil +++ x = x 
    | (h::t) +++ x= h ++ (t +++ x)

  type con = ConstantTerm.constant
  type tag = T.conInfo

(*
  fun freshVar ty =
      {id = Counters.newLocalId(),
       displayName = Counters.newVarName (),
       ty = ty}
      : T.varIdInfo
*)

  fun freshVarIdWithDisplayName (ty, name) =
      let
        val id = newLocalId()
      in
        {displayName = name, ty = ty, varId = T.INTERNAL id} : TFC.varIdInfo
      end

  fun freshVarWithDisplayName (ty, name) =
      {displayName = name, ty = ty, varId = T.INTERNAL (newLocalId())}
      : T.varIdInfo

  fun makeVar (id, name, ty) =
      {displayName = name,  ty = ty, varId = T.INTERNAL id} : T.varIdInfo

  fun unionBtvEnv(outerBtvEnv, innerBtvEnv) =
      IEnv.unionWith #1 (innerBtvEnv, outerBtvEnv)

  fun unionVarEnv(outerVarEnv, innerVarEnv) =
      VarEnv.unionWith #1 (innerVarEnv, outerVarEnv)

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
      case TU.derefTy ty of
        T.RECORDty fields => fields
      | T.TYVARty(ref(T.TVAR{recordKind = T.REC fields, ...})) => fields
      | T.BOUNDVARty index =>
        (case IEnv.find (btvEnv, index) of
           SOME{recordKind = T.REC fields, ...} => fields
         | _ =>
           raise
             C.Bug
             ("getFieldsOfTy found invalid BTV(" ^ Int.toString index ^ ")"))
      | ty =>
        raise
          C.Bug
              ("getFieldsOfTy found unexpected:" ^ TypeFormatter.tyToString ty)

(*
  fun getTagNums (tag : tag) = SEnv.numItems ((#datacon (#tyCon tag)))
*)
  fun getTagNums (tag : tag) = 
    case #constructorHasArgFlagList (#tyCon tag) of
      nil => raise Control.Bug "NON span field in userdefined type"
    | L => List.length L

  (***** return access path of root node *****)
  fun getPath (EqNode (path, _, _)) = path
    | getPath (DataTagNode (path, _, _)) = path
    | getPath (ExnTagNode (path, _, _)) = path
    | getPath (RecNode (path, _, _)) = path
    | getPath (UnivNode (path, _)) = path
    | getPath _ = raise C.Bug "match comp, getPath bug"

  (* ADDED for type preservation *)
  fun getTyInPat (WildPat ty) = ty
    | getTyInPat (VarPat ({ ty, ... })) = ty
    | getTyInPat (ConPat (_, ty)) = ty
    | getTyInPat (DataTagPat (_, _, _, ty)) = ty
    | getTyInPat (ExnTagPat (_, _, _, ty)) = ty
    | getTyInPat (RecPat (_, ty)) = ty
    | getTyInPat (LayerPat (pat, _)) = getTyInPat pat
    | getTyInPat (OrPat (pat, _)) = getTyInPat pat

  (* ADDED for type preservation *)
  fun getDisplayNameInPat (WildPat _) = newVarName ()
    | getDisplayNameInPat (VarPat ({displayName, ... })) = displayName
    | getDisplayNameInPat (ConPat _) = newVarName ()
    | getDisplayNameInPat (DataTagPat _) = newVarName ()
    | getDisplayNameInPat (ExnTagPat _) = newVarName ()
    | getDisplayNameInPat (RecPat _) = newVarName ()
    | getDisplayNameInPat (LayerPat (pat, _)) = getDisplayNameInPat pat
    | getDisplayNameInPat (OrPat (pat, _)) = getDisplayNameInPat pat

  fun incrementUseCount (branchEnv:branchEnv, branchId) =
      case IEnv.find(branchEnv, branchId) of
        SOME {useCount, ...} => useCount := !useCount + 1
      | NONE =>
        raise C.Bug "incrementUseCount in MatchCompiler: BranchId not found"

  fun canInlineBranch ({isSmall, useCount, ...} : branchData) =
      (!C.doInlineCaseBranch)
      andalso (isSmall orelse !useCount = 1)

  fun makeNestedFun [] body bodyTy loc =
       (
        RCFNM
          {
           argVarList = [freshVarWithDisplayName
                           (PT.unitty, "unitExp(" ^ newVarName () ^ ")")],
           bodyTy=bodyTy, 
           bodyExp=body, 
           loc=loc
          },
        T.FUNMty ([PT.unitty], bodyTy)
        )
    | makeNestedFun argList body bodyTy loc =
      foldr 
        (fn (arg, (body, bodyTy)) => 
        (RCFNM {argVarList=[arg], bodyTy=bodyTy, bodyExp=body, loc=loc},
         T.FUNMty ([#ty arg], bodyTy)))
        (body, bodyTy)
        argList 

  fun makeUncurriedFun [] body bodyTy loc =
       (
        RCFNM 
        {
         argVarList=[freshVarWithDisplayName
                       (PT.unitty,"unitExp(" ^ newVarName () ^ ")")], 
         bodyTy=bodyTy, 
         bodyExp=body, 
         loc=loc
         },
        T.FUNMty ([PT.unitty], bodyTy)
        )
    | makeUncurriedFun argList body bodyTy loc =
       (
        RCFNM 
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
        fun getVars (VarPat x) = VarSet.singleton x
          | getVars (DataTagPat (_, _, argPat, _)) = getVars argPat
          | getVars (ExnTagPat (_, _, argPat, _)) = getVars argPat
          | getVars (RecPat (fields, _)) =
              foldl 
              (fn (field, vars) => VarSet.union (getVars (#2 field), vars))
              VarSet.empty
              fields
          | getVars (LayerPat (pat1, pat2)) =
              VarSet.union (getVars pat1, getVars pat2)
          | getVars (OrPat (pat1, pat2)) =
              VarSet.union (getVars pat1, getVars pat2)
          | getVars _ = VarSet.empty
        fun getVarsInPatList patList = 
            foldr (fn (pat, V) => VarSet.union(getVars pat, V)) 
            VarSet.empty 
            patList
        val (branchEnv, rules) =
            foldr
            (fn (((patList, tfpexp), useCounter), (branchEnv, rules)) =>
             let
               val argList = VarSet.listItems (getVarsInPatList patList)
               val branchId = newBranchId()
               val branchEnvEntry =
                 {
                  tfpexp = tfpexp,
                  isSmall = isSmall tfpexp,
                  useCount = useCounter,
                  funVarName = newVarName (),
                  funVarId = newLocalId(),
                  funBodyTy = branchTy,
                  funTy = ref NONE,
                  funLoc = loc,
                  funArgs = argList
                  } : branchData
             in
               (
                IEnv.insert(branchEnv, branchId, branchEnvEntry),
                ( patList +++ End branchId, VarEnv.empty) :: rules
                )
             end)
            (IEnv.empty, [])
            tfpruleIntRefList
      in
        (branchEnv, rules)
      end


  fun tfppatToPat btvEnv FV (TFPPATWILD (ty, _)) = WildPat ty
    | tfppatToPat btvEnv  FV (TFPPATVAR (x, _)) = 
        if VarSet.member (FV, x) then VarPat x else WildPat (#ty x)
    | tfppatToPat btvEnv FV  (TFPPATCONSTANT (CT.UNIT, ty, _)) = WildPat ty
    | tfppatToPat btvEnv FV  (TFPPATCONSTANT (con, ty, _)) = ConPat (con, ty)
    | tfppatToPat
        btvEnv
        FV
        (TFPPATDATACONSTRUCT {conPat, argPatOpt=NONE, patTy=ty, ...}) =
      DataTagPat (conPat, false, WildPat PT.unitty, ty)
    | tfppatToPat
        btvEnv
        FV
        (TFPPATDATACONSTRUCT
           {conPat, argPatOpt = SOME argPat, patTy=ty, ...}) =
      DataTagPat (conPat, true, tfppatToPat btvEnv FV argPat, ty)
    | tfppatToPat
        btvEnv
        FV
        (TFPPATEXNCONSTRUCT {exnPat, argPatOpt=NONE, patTy=ty, ...}) =
      ExnTagPat (exnPat, false, WildPat PT.unitty, ty)
    | tfppatToPat
        btvEnv
        FV
        (TFPPATEXNCONSTRUCT {exnPat, argPatOpt = SOME argPat, patTy=ty, ...}) =
      ExnTagPat (exnPat, true, tfppatToPat btvEnv FV argPat, ty)
    | tfppatToPat btvEnv FV (TFPPATRECORD {fields=patRows, recordTy=ty,...}) =
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
            SEnv.foldri
            (fn (label, ty, pats) =>
             let
               val pat = 
                 case SEnv.find(patRows, label) of
                   SOME pat => tfppatToPat btvEnv FV pat
                 | NONE => WildPat ty
             in (label, pat) :: pats
             end)
            []
            expectedFields
        in
          RecPat (augmentedPatRows, ty)
        end
    | tfppatToPat btvEnv FV (TFPPATLAYERED {varPat=pat1, asPat=pat2, ...}) =
        (case tfppatToPat btvEnv FV pat1
          of x as (VarPat _) => LayerPat (x, tfppatToPat btvEnv FV pat2)
           | _ => tfppatToPat btvEnv FV pat2)
    | tfppatToPat btvEnv FV  (TFPPATORPAT (pat1, pat2, _)) = 
        OrPat (tfppatToPat btvEnv FV pat1, tfppatToPat btvEnv FV pat2)


    fun removeOtherPat _ [] = []
      | removeOtherPat _ (REs as ((End _, _) :: _)) = REs
      | removeOtherPat path ((VarPat x ++ rule, env) :: REs) =
        (WildPat (#ty x) ++ rule, VarEnv.insert (env, x, path)) ::
        removeOtherPat path REs
      | removeOtherPat path ((LayerPat (VarPat x, pat) ++ rule, env) :: REs) =
        removeOtherPat
          path
          ((pat ++ rule, VarEnv.insert (env, x, path)) :: REs)
      | removeOtherPat path ((OrPat (pat1, pat2) ++ rule, env) :: REs) =
        removeOtherPat path ((pat1 ++ rule, env) :: (pat2 ++ rule, env) :: REs)
      | removeOtherPat path (RE :: REs) = RE :: removeOtherPat path REs

    fun makeEqTree branchEnv (path :: paths) REs =
        let
  	val (branches, defBranch) = 
              foldr 
  	    (fn ((ConPat (c, _) ++ rule, env), (branches, defBranch)) =>
  	          (
  		   ConMap.insert
  		   ( 
                    branches, 
  		    c,
                    (rule, env) ::
                    getOpt (ConMap.find (branches, c), defBranch)
  		   ),
  		   defBranch
  		  )
  	      | ((WildPat _ ++ rule, env), (branches, defBranch)) =>
  		let
  		  val RE = (rule, env)
  		in
  		  (ConMap.map (fn REs => RE :: REs) branches, RE :: defBranch)
  		end
  	      | _ => raise C.Bug "match comp, in makeEqTree")
  	    (ConMap.empty, [])
  	    REs
        in
  	EqNode (
  		 path, 
  		 ConMap.map (matchToTree branchEnv paths) branches, 
  		 matchToTree branchEnv paths defBranch
  	       )
        end
      | makeEqTree _  _ _ = raise C.Bug "match comp, makeEqTree"
  
    and makeDataTagTree branchEnv spans (path :: paths) REs =
        let
  	  val (branches, defBranch) = 
              foldr 
  	        (fn
                 (
  		  (DataTagPat (tag, hasArg, argPat, ty) ++ rule, env), 
  		  (branches, defBranch)
  		 ) =>
  	         let
  		   val key = (tag, hasArg)
  		   val REs = 
  		       case DataTagMap.find (branches, key)
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
  		    DataTagMap.insert
  		      (branches, key, (argPat ++ rule, env) :: REs),
  		    defBranch
  		   )
  		 end
  	       | ((WildPat _ ++ rule, env), (branches, defBranch)) =>
  		 (
  		  DataTagMap.map
  		    (fn (REs as ((pat ++ _, _) :: _)) => 
  		        (WildPat (getTyInPat pat) ++ rule, env) :: REs
  		      | _ => raise C.Bug "match comp, in makeTagTree")
  		    branches,
  		  (rule, env) :: defBranch
  		 )
  	       | _ => raise C.Bug "match comp, in makeTagTree")
  	        (DataTagMap.empty, [])
  	        REs
        in
  	  DataTagNode
            (
  	     path,
  	     DataTagMap.mapi
  	       (fn ((tag, _), REs as ((pat ++ _, _) :: _)) =>
  		   matchToTree
                     branchEnv
  		     (freshVarIdWithDisplayName
                        (getTyInPat pat, getDisplayNameInPat pat) :: paths)
  		     REs
  		 | _ => raise C.Bug "match comp, in makeTagTree")
  	       branches,
  	     if DataTagMap.numItems branches = spans
  	     then EmptyNode
  	     else matchToTree branchEnv paths defBranch
  	    )
        end
      | makeDataTagTree _  _ _ _ = raise C.Bug "match comp, makeTagTree"
  
    and makeExnTagTree branchEnv (path :: paths) REs =
        let
  	  val (branches, defBranch) = 
              foldr 
  	        (fn
                 (
  		  (ExnTagPat (tag, hasArg, argPat, ty) ++ rule, env), 
  		  (branches, defBranch)
  		 ) =>
  	         let
  		   val key = (tag, hasArg)
  		   val REs = 
  		       case ExnTagMap.find (branches, key)
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
  		    ExnTagMap.insert
  		      (branches, key, (argPat ++ rule, env) :: REs),
  		    defBranch
  		   )
  		 end
  	       | ((WildPat _ ++ rule, env), (branches, defBranch)) =>
  		 (
  		  ExnTagMap.map
  		    (fn (REs as ((pat ++ _, _) :: _)) => 
  		        (WildPat (getTyInPat pat) ++ rule, env) :: REs
  		      | _ => raise C.Bug "match comp, in makeTagTree")
  		    branches,
  		  (rule, env) :: defBranch
  		 )
  	       | _ => raise C.Bug "match comp, in makeTagTree")
  	        (ExnTagMap.empty, [])
  	        REs
        in
  	  ExnTagNode
            (
  	     path,
  	     ExnTagMap.mapi
  	       (fn ((tag, _), REs as ((pat ++ _, _) :: _)) =>
  		   matchToTree
                     branchEnv
  		     (freshVarIdWithDisplayName
                        (getTyInPat pat, getDisplayNameInPat pat) :: paths)
  		     REs
  		 | _ => raise C.Bug "match comp, in makeTagTree")
  	       branches,
(*
  The case of exn, spans is infinite, so if branch will never happen.

  		            if ExnTagMap.numItems branches = spans
  		            then EmptyNode
  		            else matchToTree branchEnv paths defBranch
*)
              matchToTree branchEnv paths defBranch
   	    )
        end
      | makeExnTagTree _ _ _ = raise C.Bug "match comp, makeTagTree"

    (*
     * Because unit type has only one value (), pattern match on unit type
     * succeeds always. So, make a univ node.
     *)
    and makeUnitTree branchEnv paths REs = makeUnivTree branchEnv paths REs
  
    and makeNRecTree
          branchEnv
          (label, fieldTy, fieldDisplayName) (path :: paths) REs =
        RecNode	
  	  (
  	   path, 
  	   label,
  	   matchToTree
             branchEnv
  	     (freshVarIdWithDisplayName (fieldTy,fieldDisplayName) :: paths)
  	     (map
  	        (fn (RecPat ([(_, pat)], _) ++ rule, env) => (pat ++ rule, env)
  	          | (WildPat _ ++ rule, env) => (WildPat fieldTy ++ rule, env)
  	          | _ => raise C.Bug "match comp, in makeNRecTree")
  	        REs)
  	  )
      | makeNRecTree _ _ _ _ = raise C.Bug "match comp, makeNRecTree"
  
    and makeIRecTree
          branchEnv
          (recordTy, label, fieldTy, fieldDisplayName)
          (paths as (path :: _))
          REs =
        RecNode
          (
  	   path,
  	   label, 
  	   matchToTree
             branchEnv
  	     (freshVarIdWithDisplayName (fieldTy,fieldDisplayName) :: paths)
  	     (map
  		(fn (RecPat ((_, pat) :: fields, ty) ++ rule, env) =>
  		    (pat ++ RecPat (fields, ty) ++ rule, env)
  	          | (WildPat _ ++ rule, env) =>
  		    (WildPat fieldTy ++ WildPat recordTy ++ rule, env)
  		  | _ => raise C.Bug "match comp, in makeIRecTree")
  		REs)
  	  )
      | makeIRecTree _ _ _ _ = raise C.Bug "match comp, makeIRecTree"
  	
    and makeUnivTree branchEnv (path :: paths) REs = 
        UnivNode
          (
  	   path,
  	   matchToTree
             branchEnv 
  	     paths 
  	     (map (fn (pat ++ rule, env) => (rule, env) 
  		    | _ => raise C.Bug "makeUnivTree") 
  		  REs)
  	  )
      | makeUnivTree _  _ _ = raise C.Bug "match comp, makeUnivTree"
  
    and decideRootNode branchEnv [] = makeUnivTree branchEnv
      | decideRootNode branchEnv ((WildPat _ ++ _, _) :: REs) =
        decideRootNode branchEnv REs
      | decideRootNode branchEnv ((ConPat _ ++ _, _) :: _) =
        makeEqTree branchEnv
      | decideRootNode branchEnv ((DataTagPat (tag, _, _, _) ++ _, _) :: _) = 
        makeDataTagTree branchEnv (getTagNums tag)
      | decideRootNode branchEnv ((ExnTagPat (tag, _, _, _) ++ _, _) :: _) = 
        makeExnTagTree branchEnv 
      | decideRootNode branchEnv ((RecPat ([], _) ++ _, _) :: _) = 
        makeUnitTree branchEnv
      | decideRootNode branchEnv ((RecPat ([(label, pat)], _) ++ _, _) :: _) = 
        makeNRecTree branchEnv (label, getTyInPat pat, getDisplayNameInPat pat)
      | decideRootNode
          branchEnv
          ((RecPat ((label, pat) :: _, recTy) ++ _, _) :: _) = 
        makeIRecTree
          branchEnv
          (recTy, label, getTyInPat pat, getDisplayNameInPat pat)
      | decideRootNode branchEnv _ = raise C.Bug "match comp, decideRootNode"
  
    and matchToTree branchEnv _ [] = (ME.setFlag ME.NotExhaustive; EmptyNode )
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
            case #constructorHasArgFlagList tyCon of
              nil =>  raise Control.Bug "NON span field in userdefined type"
            | L => List.length L
              
	fun toExp EmptyNode = (VarSet.empty, failureExp)
	  | toExp (LeafNode (branchId, env)) =
            let
              val branchData 
                  as {
                       tfpexp, 
                       isSmall,
                       useCount,
                       funVarName,
                       funVarId,
                       funBodyTy,
                       funTy,
                       funLoc,
                       funArgs
                     } : branchData
                = 
                case IEnv.find(branchEnv, branchId) of
                  SOME branchData => branchData
                | NONE => raise C.Bug "MatchCompiler toExp: undefined branchId"
            in
              (
		VarEnv.foldl VarSet.add' VarSet.empty env,
                if canInlineBranch branchData
                then tfpexpToRcexp (unionVarEnv(varEnv, env)) btvEnv tfpexp
                else
                  case funArgs of 
                    [] => RCAPPM
                           {
                            funExp=
                              RCVAR
                              (makeVar(funVarId, funVarName, valOf (!funTy)),
                               funLoc),
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
                                  case VarEnv.find (env, x) of
                                    SOME v => RCVAR (v, loc)
                                  | _ =>
                                    raise
                                      C.Bug
                                        "match comp, treeToExp, \
                                        \leaf node for fun")
                              funArgs
                      in
                        RCAPPM
                          {
                           funExp =
                           RCVAR
                             (makeVar(funVarId, funVarName, valOf (!funTy)),
                              funLoc),
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
                               RCAPPM 
                                 { 
                                  funExp = func,
                                  funTy = T.FUNMty([ty1], ty2),
                                  argExpList =
                                  case VarEnv.find (env, arg) of
                                    SOME v => [RCVAR (v, loc)]
                                  | _ =>
                                    raise
                                      C.Bug
                                        "match comp, treeToExp,\
                                        \ leaf node for fun",
                                  loc=loc
                                 }
                              )
                            | _ =>
                              raise
                                C.Bug "match comp, treeToExp,\
                                      \ leaf node for fun"
                           )
                          (valOf (!funTy),
                           RCVAR
                             (makeVar(funVarId, funVarName, valOf (!funTy)),
                              funLoc))
                          funArgs
                       )
              )
            end
	  | toExp (EqNode (path as {ty= pty,...}, branches, defBranch)) = 
	    let
	      val (vars, branches) = 
		    ConMap.foldri
		    (fn (c, T, (vars, branches)) =>
		        let
			  val (vars', exp) = toExp T
			in
			  (VarSet.union (vars', vars), (c, exp) :: branches)
			end)
		    (VarSet.empty, [])
		    branches
	      val (defVars, defBranch) = toExp defBranch
	    in
	      ( 
	        VarSet.add (VarSet.union (vars, defVars), path), 
		RCSWITCH 
                 {
                  switchExp = RCVAR (path, loc), 
                  expTy = pty, 
                  branches = branches, 
                  defaultExp = defBranch, 
                  loc=loc
                  }
	      )
	    end
	  | toExp
              (DataTagNode (path as {ty = pty, displayName,...},
                            branches,
                            defBranch)) = 
	    let
	      val tyCon = 
                case (TU.derefTy (#ty path)) of 
                  T.RAWty {tyCon, ...} => tyCon
                | _ => 
                  raise 
                    Control.Bug 
                    "non tyCon in TagNode\
                    \ (matchcompilation/main/MatchCompiler.sml)"
	      val branchNums = DataTagMap.numItems branches
	      val (vars, branches) = 
		    DataTagMap.foldri
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
                          VarSet.union (vars', vars),
                          ( i, argOpt, newExp) :: branches
                        )
		      end)
		    (VarSet.empty, [])
		    branches
	      val (defVars, defBranch) = 
		  if getTagNums tyCon <> branchNums
		  then toExp defBranch
		  else 
		    case defBranch
		    of EmptyNode =>
                       (VarSet.empty, ME.raiseMatchCompBugExp resultTy loc)
		     | _ => toExp defBranch
	    in
	      ( 
	        VarSet.add (VarSet.union (vars, defVars), path), 
		RCCASE
                  {exp = RCVAR (path, loc), 
                   expTy = pty, 
                   ruleList=branches, 
                   defaultExp = defBranch, 
                   loc= loc
                   }
	      )
	    end
	  | toExp
              (ExnTagNode (path as {ty = pty, displayName,...},
                           branches,
                           defBranch)) = 
	    let
	      val tyCon = 
                case (TU.derefTy (#ty path)) of 
                  T.RAWty {tyCon, ...} => tyCon
                | _ => 
                  raise 
                    Control.Bug 
                    "non tyCon in TagNode\
                    \ (matchcompilation/main/MatchCompiler.sml)"
	      val branchNums = ExnTagMap.numItems branches
	      val (vars, branches) = 
		    ExnTagMap.foldri
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
                          VarSet.union (vars', vars),
                          ( i, argOpt, newExp) :: branches
                        )
		      end)
		    (VarSet.empty, [])
		    branches
	      val (defVars, defBranch) = 
                  (* spans is infinite, so it always have default branch. *)
                  toExp defBranch
	    in
	      ( 
	        VarSet.add (VarSet.union (vars, defVars), path), 
		RCEXNCASE
                  {exp = RCVAR (path, loc), 
                   expTy = pty, 
                   ruleList=branches, 
                   defaultExp = defBranch, 
                   loc= loc
                   }
	      )
	    end
	  | toExp (RecNode (path, label, child)) = 
	    let
	      val pi = getPath child
	      val z as (vars, exp) = toExp child
	    in
	      if not (VarSet.member (vars, pi))
	      then z
	      else
		( 
		  VarSet.add (vars, path),
		  RCMONOLET 
		  { 
		    binds = [(pi, 
                              RCSELECT 
                              {exp = RCVAR (path, loc), 
                               label=label, 
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
	  | toExp _ = raise C.Bug "match comp, treeToRcexp bug"
*)
        val result = #2 (toExp tree)
      in
	result
      end

  and tfpexpToRcexp varEnv btvEnv tfpexp = 
      case tfpexp
      of TFPFOREIGNAPPLY
           {funExp=tfpexp1,
            funTy,
            instTyList,
            argExpList=tfpExpList,
            argTyList,
            attributes,
            loc} =>
         let
           val rcexp1 = tfpexpToRcexp varEnv btvEnv tfpexp1
           val rcExpList = map (tfpexpToRcexp varEnv btvEnv) tfpExpList
         in
           RCFOREIGNAPPLY
            {
             funExp=rcexp1, 
             funTy=funTy,
             instTyList=instTyList, 
             argExpList=rcExpList,
             argTyList=argTyList,
             attributes=attributes,
             loc=loc
             }
         end
       | TFPEXPORTCALLBACK
           {funExp=tfpexp1,
            argTyList=argTyList,
            resultTy=resultTy,
            attributes=attributes,
            loc} =>
         let
           val rcexp1 = tfpexpToRcexp varEnv btvEnv tfpexp1
         in
           RCEXPORTCALLBACK
            {
             funExp=rcexp1, 
             argTyList=argTyList,
             resultTy=resultTy,
             attributes=attributes,
             loc=loc
             }
         end
       | TFPSIZEOF (ty, loc) => RCSIZEOF (ty, loc)
       | TFPCONSTANT (con, loc) => RCCONSTANT (con, loc)
       | TFPGLOBALSYMBOL (name, kind, ty, loc) =>
         RCGLOBALSYMBOL (name, kind, ty, loc)
       | TFPVAR (var, loc) => 
         (case (VarEnv.find (varEnv, var)) of
            SOME v => RCVAR(v, loc)
          | NONE => RCVAR (var, loc) )
(*       | TFPGETGLOBALVALUE (arrayIndex, offset, ty, loc) => 
         RCGETGLOBALVALUE (arrayIndex, offset, ty, loc)*)
       | TFPGETFIELD (e1, int, ty, loc) =>
         RCGETFIELD (tfpexpToRcexp varEnv btvEnv e1, int, ty, loc)
       | TFPARRAY {sizeExp=e1, initExp=e2, elementTy=ty1, resultTy=ty2, loc} =>
         RCARRAY
          {
           sizeExp=tfpexpToRcexp varEnv btvEnv e1, 
           initExp=tfpexpToRcexp varEnv btvEnv e2, 
           elementTy=ty1, 
           resultTy=ty2, 
           loc=loc
           }
       | TFPPRIMAPPLY
           {primOp=prim, instTyList=tys, argExpOpt=tfpexpOpt, loc} =>
         RCPRIMAPPLY 
           {
            primOp=prim, 
            instTyList=tys, 
            argExpOpt =
            case tfpexpOpt of
              NONE => NONE 
            | SOME tfpexp => SOME (tfpexpToRcexp varEnv btvEnv tfpexp),
            loc=loc
           }
       | TFPOPRIMAPPLY {
                        oprimOp=oprim, 
                        instances=tys,
                        keyTyList = keyTyList,
                        argExpOpt=tfpexpOpt, 
                        loc
                        } =>
         RCOPRIMAPPLY 
           {
            oprimOp=oprim, 
            instances=tys,
            keyTyList = keyTyList,
            argExpOpt=
            case tfpexpOpt of
              NONE => NONE
            | SOME tfpexp => SOME (tfpexpToRcexp varEnv btvEnv tfpexp),
            loc=loc
            }
       | TFPDATACONSTRUCT {con, instTyList=tys, argExpOpt=tfpexpOpt, loc} => 
         RCDATACONSTRUCT
           {
            con=con, 
            instTyList=tys, 
            argExpOpt =
            case tfpexpOpt of
              NONE => NONE 
            | SOME tfpexp => SOME (tfpexpToRcexp varEnv btvEnv tfpexp),
            loc=loc
            }
       | TFPEXNCONSTRUCT {exn, instTyList=tys, argExpOpt=tfpexpOpt, loc} => 
         RCEXNCONSTRUCT
           {
            exn=exn, 
            instTyList=tys, 
            argExpOpt =
            case tfpexpOpt of
              NONE => NONE 
            | SOME tfpexp => SOME (tfpexpToRcexp varEnv btvEnv tfpexp),
            loc=loc
            }
       | TFPAPPM {funExp=operator, funTy=ty, argExpList=operandList, loc} =>
	 RCAPPM
             {
              funExp=tfpexpToRcexp varEnv btvEnv operator,
              funTy=ty,
              argExpList=map (tfpexpToRcexp varEnv btvEnv) operandList,
              loc=loc
             }
       | TFPMONOLET {binds, bodyExp=exp, loc} => 
	 RCMONOLET
             {
               binds=
                 map (fn (v, e) =>(v, tfpexpToRcexp varEnv btvEnv e)) binds,
	       bodyExp=tfpexpToRcexp varEnv btvEnv exp,
               loc=loc
             }
       | TFPLET (decs, exps, tyl, loc) => 
	 RCLET
             (
               List.concat(map (tfpdecToRcdecs varEnv btvEnv) decs),
               map (tfpexpToRcexp varEnv btvEnv) exps,
               tyl,
               loc
             )
       | TFPRECORD {fields, recordTy=ty, loc} =>
         RCRECORD 
           {
            fields=SEnv.map (tfpexpToRcexp varEnv btvEnv) fields, 
            recordTy=ty, 
            loc=loc
            }
       | TFPRAISE (exp, ty, loc) =>
         RCRAISE (tfpexpToRcexp varEnv btvEnv exp, ty, loc)
       | TFPHANDLE {exp=exp1, exnVar=v, handler=exp2, loc} => 
	 RCHANDLE
           {
            exp=tfpexpToRcexp varEnv btvEnv exp1, 
            exnVar= v, 
            handler=tfpexpToRcexp varEnv btvEnv exp2, 
            loc=loc
            }
       | TFPCASEM
           {expList, expTyList,
            ruleList=tfprules,
            ruleBodyTy=ty2,
            caseKind=kind,
            loc} =>
	 let
	   val (topVarList, topBinds) = 
             foldr
             (fn ((exp, ty1), (topVarList, topBinds))
              => case exp of 
                      TFPVAR (var, _) => 
                        (case (VarEnv.find (varEnv, var)) of
                           SOME v => (v::topVarList, topBinds)
                         | NONE => (var::topVarList, topBinds)
                             )
                    | _ => 
                      let
                        val newVar = freshVarIdWithDisplayName 
                          (ty1, "caseExp(" ^ newVarName () ^ ")")
                        val rcexp = tfpexpToRcexp varEnv btvEnv exp
                      in
                        (newVar::topVarList, (newVar, rcexp)::topBinds)
                      end
              )
             (nil,nil)
             (ListPair.zip (expList, expTyList))
	   val kind = 
	       case kind
	       of PC.MATCH => Match
	        | PC.BIND => Bind
	        | PC.HANDLE => 
                    (case topVarList of
                       [v] => (Handle v)
                     | _ =>
                       raise
                         Control.Bug "non single var in casem for handler"
                     )
	   val tfpPatListTfpexpUseCountList = 
                map (fn tfpRule  => (tfpRule, ref 0)) tfprules
	   val patListTfpexpUseCountList = 
               map (fn ((tfppatList, tfpexp), useCount)  => 
                    ((map
                        (tfppatToPat btvEnv (TypedFlatCalcUtils.getFV tfpexp))
                        tfppatList, 
                      tfpexp), 
                     useCount)) 
               tfpPatListTfpexpUseCountList
	   val (branchEnv, rules) =
               makeRules ty2 patListTfpexpUseCountList loc
	   val _ = ME.clearFlag ME.NotExhaustive
	   val tree = matchToTree branchEnv topVarList rules
	   val redundantFlag = haveRedundantRules branchEnv
	   val _ = if redundantFlag then ME.setFlag ME.Redundant else ()
	   val _ = ME.checkError 
             (kind,
              redundantFlag, ME.isNotExhaustive (),
              tfpPatListTfpexpUseCountList, loc)
           val funDecs = 
               IEnv.foldl 
               (fn (branchData
                    as {
                         tfpexp, 
                         isSmall,
                         useCount,
                         funVarName,
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
                             (tfpexpToRcexp varEnv btvEnv tfpexp)
                             funBodyTy
                             funLoc
                         else
                           makeNestedFun
                             funArgs
                             (tfpexpToRcexp varEnv btvEnv tfpexp)
                             funBodyTy
                             funLoc
                       val _ = funTyRef := (SOME funTy)
                     in
                       (makeVar(funVarId, funVarName, funTy), funTerm)::funDecs
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
                 varEnv btvEnv branchEnv kind tree ty2 loc
             | _ => 
               RCMONOLET
                 {
                  binds= topBinds @ funDecs, 
                  bodyExp=
                    treeToRcexp varEnv btvEnv branchEnv kind tree ty2 loc,
                  loc=loc
                 }
         end
       | TFPFNM {argVarList=varIdInfoList, bodyTy, bodyExp, loc} =>
         RCFNM 
           {
            argVarList= varIdInfoList,
            bodyTy=bodyTy,
            bodyExp=tfpexpToRcexp varEnv btvEnv bodyExp, 
            loc=loc
            }
       | TFPPOLYFNM
           {btvEnv=localBtvEnv,
            argVarList=varList,
            bodyTy=ty,
            bodyExp=exp,
            loc} =>
         RCPOLYFNM
           {
            btvEnv=localBtvEnv, 
            argVarList= varList, 
            bodyTy=ty, 
            bodyExp=
              tfpexpToRcexp varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp, 
            loc=loc
            }
       | TFPPOLY {btvEnv=localBtvEnv, expTyWithoutTAbs=ty, exp=exp, loc} =>
         RCPOLY 
           {
            btvEnv=localBtvEnv, 
            expTyWithoutTAbs=ty, 
            exp=tfpexpToRcexp varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp, 
            loc=loc
            }
       | TFPTAPP {exp, expTy=ty1, instTyList=tys, loc} =>
         RCTAPP 
           {
            exp=tfpexpToRcexp varEnv btvEnv exp, 
            expTy=ty1, 
            instTyList=tys, 
            loc=loc
            }
       | TFPSELECT {label, exp, expTy=ty, resultTy, loc} => 
	 RCSELECT 
           {
            label=label,
            exp=tfpexpToRcexp varEnv btvEnv exp, 
            expTy=ty, 
            resultTy = resultTy,
            loc=loc
            }
       | TFPMODIFY
           {label,
            recordExp=exp1,
            recordTy=ty1,
            elementExp=exp2,
            elementTy=ty2,
            loc} =>
	 RCMODIFY
             {
              label=label,
              recordExp=tfpexpToRcexp varEnv btvEnv exp1,
              recordTy=ty1,
              elementExp=tfpexpToRcexp varEnv btvEnv exp2,
              elementTy=ty2,
              loc=loc
             }
       | TFPCAST (exp, ty, loc) =>
         RCCAST(tfpexpToRcexp varEnv btvEnv exp, ty, loc)
       | TFPLIST {expList, listTy, loc} =>
         RCLIST {
                 expList=map (tfpexpToRcexp varEnv btvEnv) expList, 
                 listTy=listTy, 
                 loc=loc
                }
       | TFPSEQ {expList, expTyList, loc} =>
         RCSEQ {
                expList=map (tfpexpToRcexp varEnv btvEnv) expList, 
                expTyList=expTyList, 
                loc=loc
                }
      | TFPSQLSERVER {server, schema, resultTy, loc} =>
        RCSQL (RCSQLSERVER
                 {server = map (fn (l,e) => (l,tfpexpToRcexp varEnv btvEnv e)) server,
                  schema = schema},
               resultTy, loc)

  and tfpdecToRcdecs varEnv btvEnv tfpdec = 
      case tfpdec of
          TFPVAL (binds, loc) =>
         let
           fun toRcbind (var, exp) = 
                 (var, tfpexpToRcexp varEnv btvEnv exp)
         in
	     [RCVAL (map toRcbind binds, loc)]
         end
       | TFPVALREC (binds, loc) =>
         let
           fun toRcbind (var, expTy, exp) = 
             {var=var, expTy=expTy, exp = tfpexpToRcexp varEnv btvEnv exp}
         in
	     [RCVALREC (map toRcbind binds, loc)]
         end
       | TFPVALPOLYREC (localBtvEnv, binds, loc) =>
         let
           fun toRcbind (var, ty, exp) =
               {var=var,
                expTy = ty,
                exp = tfpexpToRcexp
                        varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp}
         in
	     [RCVALPOLYREC (localBtvEnv, map toRcbind binds, loc)]
         end
       | TFPLOCALDEC (localDecs, decs, loc) => 
	 [RCLOCALDEC
             (
              List.concat(map (tfpdecToRcdecs varEnv btvEnv) localDecs),
              List.concat(map (tfpdecToRcdecs varEnv btvEnv) decs),
              loc
             )]
       | TFPSETFIELD (e1, e2, int, ty, loc) =>
         [RCSETFIELD
             (
               tfpexpToRcexp varEnv btvEnv e1,
               tfpexpToRcexp varEnv btvEnv e2,
               int,
               ty,
               loc
             )]
       | TFPEXNBINDDEF _ => nil
       | TFPFUNCTORDEC _ => nil
       | TFPLINKFUNCTORDEC _ => nil

  fun compileBasicBlock varEnv btvEnv basicBlock =
      case basicBlock of
          TFPVALBLOCK {code, exnIDSet} =>
          RCVALBLOCK
            {code =
             List.concat (map (tfpdecToRcdecs varEnv btvEnv) code),
             exnIDSet = exnIDSet} 
        | TFPLINKFUNCTORBLOCK x => RCLINKFUNCTORBLOCK x
      
  fun compileTopBlock varEnv btvEnv topBlock =
      case topBlock of
          TFPBASICBLOCK basicBlock => 
          RCBASICBLOCK (compileBasicBlock varEnv btvEnv basicBlock)
        | TFPFUNCTORBLOCK {name, 
                           formalAbstractTypeIDSet, 
                           formalExnIDSet,                  
                           formalVarIDSet,
                           generativeExnIDSet,
                           generativeVarIDSet,
                           bodyCode} => 
          RCFUNCTORBLOCK {name = name,
                          formalAbstractTypeIDSet = formalAbstractTypeIDSet,
                          formalVarIDSet = formalVarIDSet,
                          formalExnIDSet = formalExnIDSet,                  
                          generativeExnIDSet = generativeExnIDSet,
                          generativeVarIDSet = generativeVarIDSet,
                          bodyCode =
                          map (compileBasicBlock varEnv btvEnv) bodyCode}
          
  fun compile topBlockList =
      let
        val _ = nextBranchId := 0
	val _ = ME.clearFlag ME.Redundant
	val _ = ME.clearErrorMessages ()
	val topBlockList =
            map (compileTopBlock VarEnv.empty IEnv.empty) topBlockList
      in
	  if ME.isRedundant ()
	  then raise UE.UserErrors (rev (ME.getErrorMessages ()))
	  else (topBlockList, rev (ME.getErrorMessages ()))
      end
      handle exn => raise exn
end
