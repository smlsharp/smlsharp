(**
 * Copyright (c) 2006, Tohoku University.
 *
 * SML# match compiler.
 * @author Satoshi Osaka 
 * @author Atsushi Ohori
 * @version $Id: MatchCompiler.sml,v 1.38 2006/02/18 04:59:22 ohori Exp $

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
 *)

structure MatchCompiler : MATCH_COMPILER = 
struct
    val tyToString = TypeFormatter.tyToString
    fun printTy ty = print (tyToString ty ^ "\n")

  val nextBranchId = ref 0
  fun newBranchId () = 
    let val next = !nextBranchId 
    in  
      nextBranchId := next + 1 ; 
      next 
    end
  open TypedFlatCalc RecordCalc MatchData
  structure C = Control
  structure UE = UserError
  structure T = Types
  structure TU = TypesUtils
  structure RCU = RecordCalcUtils
  structure TFCU = TypedFlatCalcUtils
  structure SE = StaticEnv
  structure ME = MatchError
  structure VIdMap = TFCU.VIdEnv
  structure VIdSet = TFCU.VIdSet

  type branchData = {
                     funArgs : VIdSet.item list,
                     funBodyTy : T.ty,
                     funLoc : Loc.loc,
                     funTy : (T.ty option) ref,
                     funVarId : ID.id,
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
              Exp rcepx => limitCheckExp tfpexp itemList n 
            | Decl tfpdecl => limitCheckDecl tfpdecl itemList n 

      and limitCheckExp tfpexp itemList n = 
        case tfpexp of
          TFPFOREIGNAPPLY 
            {
             funExp=tfpexp1, 
             instTyList=tyList1, 
             argExp=tfpexp2, 
             argTyList=tyList2, 
             loc
             } => 
            limitCheck (Exp tfpexp1 :: Exp tfpexp2 :: itemList) (n + 1)
        | TFPCONSTANT (constant,loc) => limitCheck itemList (n + 1)
        | TFPVAR (varIdInfo,loc) => limitCheck itemList (n + 1)
        | TFPGETGLOBAL (string,ty,loc) => limitCheck itemList (n + 1)
        | TFPGETGLOBALVALUE (arrayIndex, offset, ty, loc) => limitCheck itemList (n + 1)
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
        | TFPPRIMAPPLY {primOp=primInfo, instTyList=tyList, argExpOpt=NONE, loc} => limitCheck itemList (n + 1)
        | TFPPRIMAPPLY {primOp=primInfo, instTyList=tyList, argExpOpt=SOME tfpexp1, loc} => 
            limitCheck (Exp tfpexp1::itemList) (n + 1)
        | TFPOPRIMAPPLY {oprimOp=oprimInfo, instances=tyList, argExpOpt=NONE, loc} => limitCheck itemList (n + 1)
        | TFPOPRIMAPPLY {oprimOp=oprimInfo, 
                         instances=tyList, 
                         argExpOpt=SOME tfpexp1, 
                         loc} => limitCheck (Exp tfpexp1::itemList) (n + 1)
        | TFPCONSTRUCT {con=conIdInfo, instTyList=tyList, argExpOpt=NONE, loc} 
            => limitCheck itemList (n + 1)
        | TFPCONSTRUCT {con=conIdInfo, instTyList=tyList, argExpOpt=SOME tfpexp1,
                        loc} => 
            limitCheck (Exp tfpexp1 :: itemList) (n + 1)
        | TFPAPPM {funExp=tfpexp1, funTy=ty, argExpList=tfpexpList, loc} => 
            limitCheck (Exp tfpexp1 :: (map Exp tfpexpList) @ itemList) (n + 1)
        | TFPMONOLET {binds=nil, bodyExp=tfpexp1, loc} => limitCheck (Exp tfpexp1 :: itemList) (n + 1)
        | TFPMONOLET {binds=(varIdInfo,tfpexp1)::varIdInfotfpexpList, 
                      bodyExp=tfpexp2, 
                      loc} =>
            limitCheck (Exp tfpexp1 :: 
                        Exp (TFPMONOLET {binds=varIdInfotfpexpList, bodyExp=tfpexp2, loc=loc}) ::
                        itemList)
            (n + 1)
        | TFPLET (tfpdeclList, tfpexpList, tyList, loc) =>
            limitCheck ((map Decl tfpdeclList) @ (map Exp tfpexpList) @ itemList) (n + 1)
        | TFPRECORD {fields, recordTy=ty, loc} => 
            limitCheck ((map (fn (l,tfpexp) => Exp tfpexp) (SEnv.listItemsi fields)) @ itemList) (n + 1)
        | TFPSELECT {label=string, exp=tfpexp, expTy=ty, loc} => limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPMODIFY {label=string, 
                     recordExp=tfpexp1, 
                     recordTy=ty1, 
                     elementExp=tfpexp2, 
                     elementTy=ty2,  
                     loc} =>
            limitCheck (Exp tfpexp1 :: Exp tfpexp2 :: itemList) (n + 1)
        | TFPRAISE (tfpexp, ty, loc) => limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPHANDLE {exp=tfpexp1,  exnVar=varIdInfo, handler=tfpexp2, loc} =>
            limitCheck (Exp tfpexp1 :: Exp tfpexp2 :: itemList) (n + 1)
        | TFPCASEM {expList=tfpexpList, 
                    expTyList=tyList,  
                    ruleList=tfpPatListTfpexpList, 
                    ruleBodyTy=ty, 
                    caseKind=kind, 
                    loc} =>
            limitCheck (map Exp tfpexpList
                        @
                        map (fn (tfppatList, tfpexp) => Exp tfpexp) tfpPatListTfpexpList 
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
        | TFPPOLY {btvEnv=btvKindIEnvMap, expTyWithoutTAbs=ty, exp=tfpexp, loc} =>
            limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPTAPP {exp=tfpexp, expTy=ty1, instTyList=tylist, loc} => 
            limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPSEQ {expList, ...} =>
            limitCheck (map Exp expList @ itemList) (n + 1)
        | TFPCAST (tfpexp, ty, loc) => limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPFFIVAL {funExp, libExp, ...} =>
            limitCheck (Exp funExp :: Exp libExp :: itemList) (n + 1)
      and limitCheckDecl tfpdecl itemList n = 
        case tfpdecl of
          TFPVAL (valIdtfpexpList, loc) => 
            limitCheck ((map (fn (varId, tfpexp) => Exp tfpexp) valIdtfpexpList) @ itemList) (n + 1)
        | TFPVALREC (varIdInfoTytfpexpList,loc) =>
          limitCheck ((map (fn (varIdInfo, ty, tfpexp) => Exp tfpexp) varIdInfoTytfpexpList) @ itemList) (n + 1)
        | TFPVALPOLYREC (btvKindIEnvMap, varIdInfoTyTfpexpList, loc) =>
          limitCheck ((map (fn (varIdInfo, ty, tfpexp) => Exp tfpexp) varIdInfoTyTfpexpList) @ itemList) (n + 1)
        | TFPLOCALDEC (tfpdeclList1, tfpdeclList2, loc) =>
          limitCheck (map Decl tfpdeclList1 @ map Decl tfpdeclList2 @ itemList) (n + 1)
        | TFPSETFIELD (tfpexp1, tfpexp2, int, ty, loc) => 
          limitCheck (Exp tfpexp1 :: Exp tfpexp2 :: itemList) (n + 1)
        | TFPSETGLOBAL (string, tfpexp, loc) => limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPSETGLOBALVALUE(arrayIndex, offset, tfpexp, ty, loc) =>
          limitCheck (Exp tfpexp :: itemList) (n + 1)
        | TFPINITARRAY(arrayIndex, size, ty, loc) =>
          limitCheck itemList (n + 1)
    in
      limitCheck [(Exp tfpexp)] 0
    end

(* *)
  infixr ++
  infixr +++
  fun nil +++ x = x 
    | (h::t) +++ x= h ++ (t +++ x)

  type con = T.constant
  type tag = T.conInfo

(*
  fun freshVar ty =
      {id = SE.newVarId(), displayName = Vars.newRCVarName (),  ty = ty}
      : T.varIdInfo
*)

  fun freshVarIdWithDisplayName (ty, name) =
      let
        val id = SE.newVarId()
      in
        {id = id, displayName = name, ty = ty} : TFC.varIdInfo
      end

  fun freshVarWithDisplayName (ty, name) =
      {id = SE.newVarId(), displayName = name, ty = ty}
      : T.varIdInfo

  fun makeVar (id,name, ty) =  {id = id, displayName = name,  ty = ty} : T.varIdInfo

  fun unionBtvEnv(outerBtvEnv, innerBtvEnv) =
      IEnv.unionWith #2 (outerBtvEnv, innerBtvEnv)

  fun unionVarEnv(outerVarEnv, innerVarEnv) =
      VIdMap.unionWith #2 (outerVarEnv, innerVarEnv)

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
      | T.TYVARty(ref(T.TVAR{recKind = T.REC fields, ...})) => fields
      | T.BOUNDVARty index =>
        (case IEnv.find (btvEnv, index) of
           SOME{recKind = T.REC fields, ...} => fields
         | _ =>
           raise
             C.Bug
             ("getFieldsOfTy found invalid BTV(" ^ Int.toString index ^ ")"))
      | ty =>
        raise
          C.Bug
              ("getFieldsOfTy found unexpected:" ^ TypeFormatter.tyToString ty)

  fun getTagNums (tag : tag) = SEnv.numItems (!(#datacon (#tyCon tag)))

  (***** return access path of root node *****)
  fun getPath (EqNode (path, _, _)) = path
    | getPath (TagNode (path, _, _)) = path
    | getPath (RecNode (path, _, _)) = path
    | getPath (UnivNode (path, _)) = path
    | getPath _ = raise C.Bug "match comp, getPath bug"

  (* ADDED for type preservation *)
  fun getTyInPat (WildPat ty) = ty
    | getTyInPat (VarPat ({ ty, ... })) = ty
    | getTyInPat (ConPat (_, ty)) = ty
    | getTyInPat (TagPat (_, _, _, ty)) = ty
    | getTyInPat (RecPat (_, ty)) = ty
    | getTyInPat (LayerPat (pat, _)) = getTyInPat pat
    | getTyInPat (OrPat (pat, _)) = getTyInPat pat

  (* ADDED for type preservation *)
  fun getDisplayNameInPat (WildPat _) = Vars.newRCVarName ()
    | getDisplayNameInPat (VarPat ({displayName, ... })) = displayName
    | getDisplayNameInPat (ConPat _) = Vars.newRCVarName ()
    | getDisplayNameInPat (TagPat _) = Vars.newRCVarName ()
    | getDisplayNameInPat (RecPat _) = Vars.newRCVarName ()
    | getDisplayNameInPat (LayerPat (pat, _)) = getDisplayNameInPat pat
    | getDisplayNameInPat (OrPat (pat, _)) = getDisplayNameInPat pat

  fun incrementUseCount (branchEnv:branchEnv, branchId) =
      case IEnv.find(branchEnv, branchId) of
        SOME {useCount, ...} => useCount := !useCount + 1
      | NONE => raise C.Bug "incrementUseCount in MatchCompiler: BranchId not found"

  fun canInlineBranch ({isSmall, useCount, ...} : branchData) =
      (!C.doInlineCaseBranch)
      andalso (isSmall orelse !useCount = 1)

  fun makeNestedFun [] body bodyTy loc =
       (
        RCFNM {
               argVarList = [freshVarWithDisplayName (SE.unitty, "unitExp(" ^ Vars.newRCVarName () ^ ")")],
               bodyTy=bodyTy, 
               bodyExp=body, 
               loc=loc
               },
        T.FUNMty ([SE.unitty], bodyTy)
        )
    | makeNestedFun argList body bodyTy loc =
       foldr 
       (fn (arg, (body, bodyTy)) => 
        (RCFNM {argVarList=[arg], bodyTy=bodyTy, bodyExp=body, loc=loc}, T.FUNMty ([#ty arg], bodyTy)))
       (body, bodyTy)
       argList 

  fun makeUncurriedFun [] body bodyTy loc =
       (
        RCFNM 
        {
         argVarList=[freshVarWithDisplayName (SE.unitty,"unitExp(" ^ Vars.newRCVarName () ^ ")")], 
         bodyTy=bodyTy, 
         bodyExp=body, 
         loc=loc
         },
        T.FUNMty ([SE.unitty], bodyTy)
        )
    | makeUncurriedFun argList body bodyTy loc =
       (RCFNM {argVarList=argList, bodyTy=bodyTy, bodyExp=body, loc=loc}, T.FUNMty (map #ty argList, bodyTy))

  (*
     [..., ([P1,...,Pn], e),...] ->  (branchEnv, [..., P1++...++Pn++n,...])
   *)
  fun makeRules branchTy tfpruleIntRefList loc =
      let
        fun getVars (VarPat x) = VIdSet.singleton x
          | getVars (TagPat (_, _, argPat, _)) = getVars argPat
          | getVars (RecPat (fields, _)) =
              foldl 
              (fn (field, vars) => VIdSet.union (getVars (#2 field), vars))
              VIdSet.empty
              fields
          | getVars (LayerPat (pat1, pat2) | OrPat (pat1, pat2)) =
              VIdSet.union (getVars pat1, getVars pat2)
          | getVars _ = VIdSet.empty
        fun getVarsInPatList patList = 
            foldr (fn (pat, V) => VIdSet.union(getVars pat, V)) 
            VIdSet.empty 
            patList
        val (branchEnv, rules) =
            foldr
            (fn (((patList, tfpexp), useCounter), (branchEnv, rules)) =>
             let
               val argList = VIdSet.listItems (getVarsInPatList patList)
               val branchId = newBranchId()
               val branchEnvEntry =
                 {
                  tfpexp = tfpexp,
                  isSmall = isSmall tfpexp,
                  useCount = useCounter,
                  funVarName = Vars.newRCVarName (),
                  funVarId = SE.newVarId(),
                  funBodyTy = branchTy,
                  funTy = ref NONE,
                  funLoc = loc,
                  funArgs = argList
                  } : branchData
             in
               (
                IEnv.insert(branchEnv, branchId, branchEnvEntry),
                ( patList +++ End branchId, VIdMap.empty) :: rules
                )
             end)
            (IEnv.empty, [])
            tfpruleIntRefList
      in
        (branchEnv, rules)
      end


  fun tfppatToPat btvEnv FV (TFPPATWILD (ty, _)) = WildPat ty
    | tfppatToPat btvEnv  FV (TFPPATVAR (x, _)) = 
        if VIdSet.member (FV, x) then VarPat x else WildPat (#ty x)
    | tfppatToPat btvEnv FV  (TFPPATCONSTANT (con, ty, _)) = ConPat (con, ty)
    | tfppatToPat btvEnv FV (TFPPATCONSTRUCT {conPat, argPatOpt=NONE, patTy=ty, ...}) =
        TagPat (conPat, false, WildPat SE.unitty, ty)
    | tfppatToPat btvEnv FV (TFPPATCONSTRUCT {conPat, argPatOpt = SOME argPat, patTy=ty, ...}) =
        TagPat (conPat, true, tfppatToPat btvEnv FV argPat, ty)
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


    fun removeOtherPat _ [] = []
      | removeOtherPat _ (REs as ((End _, _) :: _)) = REs
      | removeOtherPat path ((VarPat x ++ rule, env) :: REs) =
        (WildPat (#ty x) ++ rule, VIdMap.insert (env, x, path)) ::
        removeOtherPat path REs
      | removeOtherPat path ((LayerPat (VarPat x, pat) ++ rule, env) :: REs) =
        removeOtherPat path ((pat ++ rule, VIdMap.insert (env, x, path)) :: REs)
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
  
    and makeTagTree branchEnv tagNums (path :: paths) REs =
        let
  	val (branches, defBranch) = 
                foldr 
  	      (fn (
  		    (TagPat (tag, hasArg, argPat, ty) ++ rule, env), 
  		    (branches, defBranch)
  		  ) =>
  	            let
  		      val key = (tag, hasArg)
  		      val REs = 
  			  case TagMap.find (branches, key)
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
  		        TagMap.insert
  			(branches, key, (argPat ++ rule, env) :: REs),
  			defBranch
  		      )
  		    end
  		| ((WildPat _ ++ rule, env), (branches, defBranch)) =>
  		    (
  		      TagMap.map
  		      (fn (REs as ((pat ++ _, _) :: _)) => 
  		            (WildPat (getTyInPat pat) ++ rule, env) :: REs
  			| _ => raise C.Bug "match comp, in makeTagTree")
  		      branches,
  		      (rule, env) :: defBranch
  		    )
  		| _ => raise C.Bug "match comp, in makeTagTree")
  	      (TagMap.empty, [])
  	      REs
        in
  	TagNode (
  		  path,
  		  TagMap.mapi
  		  (fn ((tag, _), REs as ((pat ++ _, _) :: _)) =>
  		        matchToTree branchEnv
  			(freshVarIdWithDisplayName (getTyInPat pat, getDisplayNameInPat pat) :: paths)
  			REs
  		    | _ => raise C.Bug "match comp, in makeTagTree")
  		  branches,
  		  if TagMap.numItems branches = tagNums
  		  then EmptyNode
  		  else matchToTree branchEnv paths defBranch
  		)
        end
      | makeTagTree _  _ _ _ = raise C.Bug "match comp, makeTagTree"
  
    (*
     * Because unit type has only one value (), pattern match on unit type
     * succeeds always. So, make a univ node.
     *)
    and makeUnitTree branchEnv paths REs = makeUnivTree branchEnv paths REs
  
    and makeNRecTree branchEnv (label, fieldTy, fieldDisplayName) (path :: paths) REs =
          RecNode	
  	(
  	  path, 
  	  label,
  	  matchToTree branchEnv
  	  (freshVarIdWithDisplayName (fieldTy,fieldDisplayName) :: paths)
  	  (map
  	   (fn (RecPat ([(_, pat)], _) ++ rule, env) => (pat ++ rule, env)
  	     | (WildPat _ ++ rule, env) => (WildPat fieldTy ++ rule, env)
  	     | _ => raise C.Bug "match comp, in makeNRecTree")
  	   REs)
  	)
      | makeNRecTree _ _ _ _ = raise C.Bug "match comp, makeNRecTree"
  
    and makeIRecTree branchEnv (recordTy, label, fieldTy, fieldDisplayName) (paths as (path :: _)) REs =
        RecNode (
  	        path,
  		label, 
  		matchToTree branchEnv
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
          UnivNode (
  		   path,
  		   matchToTree branchEnv 
  		   paths 
  		   (map (fn (pat ++ rule, env) => (rule, env) 
  		          | _ => raise C.Bug "makeUnivTree") 
  		    REs)
  		 )
      | makeUnivTree _  _ _ = raise C.Bug "match comp, makeUnivTree"
  
    and decideRootNode branchEnv [] = makeUnivTree branchEnv
      | decideRootNode branchEnv ((WildPat _ ++ _, _) :: REs) = decideRootNode branchEnv REs
      | decideRootNode branchEnv ((ConPat _ ++ _, _) :: _) = makeEqTree branchEnv
      | decideRootNode branchEnv ((TagPat (tag, _, _, _) ++ _, _) :: _) = 
        makeTagTree branchEnv (getTagNums tag)
      | decideRootNode branchEnv ((RecPat ([], _) ++ _, _) :: _) = 
        makeUnitTree branchEnv
      | decideRootNode branchEnv ((RecPat ([(label, pat)], _) ++ _, _) :: _) = 
        makeNRecTree branchEnv (label, getTyInPat pat, getDisplayNameInPat pat)
      | decideRootNode branchEnv ((RecPat ((label, pat) :: _, recTy) ++ _, _) :: _) = 
        makeIRecTree branchEnv (recTy, label, getTyInPat pat, getDisplayNameInPat pat)
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
	fun getTagNums (tyCon : tyCon) = 
	    SEnv.numItems (! (#datacon tyCon))
	fun toExp EmptyNode = (VIdSet.empty, failureExp)
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
		VIdMap.foldl VIdSet.add' VIdSet.empty env,
                if canInlineBranch branchData 
                then tfpexpToRcexp (unionVarEnv(varEnv, env)) btvEnv tfpexp
                else
                  case funArgs of 
                    [] => RCAPPM 
                           {
                            funExp=RCVAR (makeVar(funVarId, funVarName, valOf (!funTy)), funLoc),
                            funTy=valOf (!funTy), 
                            argExpList=[unitExp], 
                            loc=loc
                            }
                  | _ => 
                      if !C.doUncurryingOptimizeInMachCompile
                        then
                          let
                            val funArgs = 
                                 map
                                  (fn x => 
                                   case VIdMap.find (env, x) of
                                     SOME v => RCVAR (v, loc)
                                   | _ => raise C.Bug "match comp, treeToExp, leaf node for fun")
                                  funArgs
                          in
                            RCAPPM
                             {
                              funExp = RCVAR (makeVar(funVarId, funVarName, valOf (!funTy)), funLoc),
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
                             argExpList = case VIdMap.find (env, arg) of
                                               SOME v => [RCVAR (v, loc)]
                                            | _ => raise C.Bug "match comp, treeToExp, leaf node for fun",
                             loc=loc
                             }
                            )
                      | _ => raise C.Bug "match comp, treeToExp, leaf node for fun"
                           )
                        (valOf (!funTy), RCVAR (makeVar(funVarId, funVarName, valOf (!funTy)), funLoc))
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
			  (VIdSet.union (vars', vars), (c, exp) :: branches)
			end)
		    (VIdSet.empty, [])
		    branches
	      val (defVars, defBranch) = toExp defBranch
	    in
	      ( 
	        VIdSet.add (VIdSet.union (vars, defVars), path), 
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
	  | toExp (TagNode (path as {ty = pty, displayName,...}, branches, defBranch)) = 
	    let
	      val T.CONty {tyCon, ...} = (TU.derefTy (#ty path))
	      val branchNums = TagMap.numItems branches
	      val (vars, branches) = 
		    TagMap.foldri
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
                          VIdSet.union (vars', vars),
                          (i, argOpt, newExp) :: branches
                        )
		      end)
		    (VIdSet.empty, [])
		    branches
	      val (defVars, defBranch) = 
		  if getTagNums tyCon <> branchNums
		  then toExp defBranch
		  else 
		    case defBranch
		    of EmptyNode =>
                       (VIdSet.empty, ME.raiseMatchCompBugExp resultTy loc)
		     | _ => toExp defBranch
	    in
	      ( 
	        VIdSet.add (VIdSet.union (vars, defVars), path), 
		RCCASE
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
	      if not (VIdSet.member (vars, pi))
	      then z
	      else
		( 
		  VIdSet.add (vars, path),
		  RCMONOLET 
		  { 
		    binds = [(pi, 
                              RCSELECT 
                              {exp = RCVAR (path, loc), 
                               label=label, 
                               expTy = #ty path, 
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
      of TFPFOREIGNAPPLY {funExp=tfpexp1, instTyList=tyList, argExp=tfpexp2, argTyList=argTyList, loc} =>
         let
           val rcexp1 = tfpexpToRcexp varEnv btvEnv tfpexp1
           val rcexp2 = tfpexpToRcexp varEnv btvEnv tfpexp2
         in
           RCFOREIGNAPPLY
            {
             funExp=rcexp1, 
             instTyList=tyList, 
             argExp=rcexp2, 
             argTyList=argTyList, 
             loc=loc
             }
         end
       | TFPCONSTANT (con, loc) => RCCONSTANT (con, loc)
       | TFPVAR (var, loc) => 
         (case (VIdMap.find (varEnv, var)) of
            SOME v => RCVAR(v, loc)
          | NONE => RCVAR (var, loc) )
       | TFPGETGLOBAL (string, ty, loc) => RCGETGLOBAL(string, ty, loc)
       | TFPGETGLOBALVALUE (arrayIndex, offset, ty, loc) => 
         RCGETGLOBALVALUE (arrayIndex, offset, ty, loc)
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
       | TFPPRIMAPPLY {primOp=prim, instTyList=tys, argExpOpt=tfpexpOpt, loc} =>
         RCPRIMAPPLY 
           {
            primOp=prim, 
            instTyList=tys, 
            argExpOpt = case tfpexpOpt of
                          NONE => NONE 
                        | SOME tfpexp => SOME (tfpexpToRcexp varEnv btvEnv tfpexp),
            loc=loc
            }
       | TFPOPRIMAPPLY {
                        oprimOp=oprim, 
                        instances=tys, 
                        argExpOpt=tfpexpOpt, 
                        loc
                        } =>
         RCOPRIMAPPLY 
           {
            oprimOp=oprim, 
            instances=tys, 
            argExpOpt= case tfpexpOpt of
                             NONE => NONE
                           | SOME tfpexp => SOME (tfpexpToRcexp varEnv btvEnv tfpexp),
            loc=loc
            }
       | TFPCONSTRUCT {con, instTyList=tys, argExpOpt=tfpexpOpt, loc} => 
         RCCONSTRUCT
           {
            con=con, 
            instTyList=tys, 
            argExpOpt = case tfpexpOpt of
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
               binds=map (fn (v, e) =>(v, tfpexpToRcexp varEnv btvEnv e)) binds,
	       bodyExp=tfpexpToRcexp varEnv btvEnv exp,
               loc=loc
             }
       | TFPLET (decs, exps, tyl, loc) => 
	 RCLET
             (
               map (tfpdecToRcdec varEnv btvEnv) decs,
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
       | TFPRAISE (exp, ty, loc) => RCRAISE (tfpexpToRcexp varEnv btvEnv exp, ty, loc)
       | TFPHANDLE {exp=exp1, exnVar=v, handler=exp2, loc} => 
	 RCHANDLE
           {
            exp=tfpexpToRcexp varEnv btvEnv exp1, 
            exnVar= v, 
            handler=tfpexpToRcexp varEnv btvEnv exp2, 
            loc=loc
            }
       | TFPCASEM {expList, expTyList, ruleList=tfprules, ruleBodyTy=ty2, caseKind=kind, loc} =>
	 let
	   val (topVarList, topBinds) = 
             foldr
             (fn ((exp, ty1), (topVarList, topBinds))
              => case exp of 
                      TFPVAR (var, _) => 
                        (case (VIdMap.find (varEnv, var)) of
                           SOME v => (v::topVarList, topBinds)
                         | NONE => (var::topVarList, topBinds)
                             )
                    | _ => 
                      let
                        val newVar = freshVarIdWithDisplayName 
                          (ty1, "caseExp(" ^ Vars.newRCVarName () ^ ")")
                        val rcexp = tfpexpToRcexp varEnv btvEnv exp
                      in
                        (newVar::topVarList, (newVar, rcexp)::topBinds)
                      end
              )
             (nil,nil)
             (ListPair.zip (expList, expTyList))
	   val kind = 
	       case kind
	       of T.MATCH => Match
	        | T.BIND => Bind
	        | T.HANDLE => 
                    (case topVarList of
                          [v] => (Handle v)
                        | _ => raise Control.Bug "non single var in casem for handler"
                     )
	   val tfpPatListTfpexpUseCountList = 
                map (fn tfpRule  => (tfpRule, ref 0)) tfprules
	   val patListTfpexpUseCountList = 
               map (fn ((tfppatList, tfpexp), useCount)  => 
                    ((map (tfppatToPat btvEnv (TypedFlatCalcUtils.getFV tfpexp)) tfppatList, 
                      tfpexp), 
                     useCount)) 
               tfpPatListTfpexpUseCountList
	   val (branchEnv, rules) = makeRules ty2 patListTfpexpUseCountList loc
	   val _ = ME.clearFlag ME.NotExhaustive
	   val tree = matchToTree branchEnv topVarList rules
	   val redundantFlag = haveRedundantRules branchEnv
	   val _ = if redundantFlag then ME.setFlag ME.Redundant else ()
	   val _ = ME.checkError 
             (kind, redundantFlag, ME.isNotExhaustive (), tfpPatListTfpexpUseCountList, loc)
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
                         if !C.doUncurryingOptimizeInMachCompile
                           then
                             makeUncurriedFun funArgs (tfpexpToRcexp varEnv btvEnv tfpexp) funBodyTy funLoc
                         else
                           makeNestedFun funArgs (tfpexpToRcexp varEnv btvEnv tfpexp) funBodyTy funLoc
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
                   (nil, nil) => treeToRcexp varEnv btvEnv branchEnv kind tree ty2 loc
                 | _ => 
                     RCMONOLET {
                                binds= topBinds @ funDecs, 
                                bodyExp=treeToRcexp varEnv btvEnv branchEnv kind tree ty2 loc,
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
       | TFPPOLYFNM {btvEnv=localBtvEnv, argVarList=varList, bodyTy=ty, bodyExp=exp, loc} =>
         RCPOLYFNM
           {
            btvEnv=localBtvEnv, 
            argVarList= varList, 
            bodyTy=ty, 
            bodyExp=tfpexpToRcexp varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp, 
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
       | TFPSELECT {label, exp, expTy=ty, loc} => 
	 RCSELECT 
           {
            label=label,
            exp=tfpexpToRcexp varEnv btvEnv exp, 
            expTy=ty, 
            loc=loc
            }
       | TFPMODIFY {label, recordExp=exp1, recordTy=ty1, elementExp=exp2, elementTy=ty2, loc} =>
	 RCMODIFY
             {
              label=label,
              recordExp=tfpexpToRcexp varEnv btvEnv exp1,
              recordTy=ty1,
              elementExp=tfpexpToRcexp varEnv btvEnv exp2,
              elementTy=ty2,
              loc=loc
             }
       | TFPCAST (exp, ty, loc) => RCCAST(tfpexpToRcexp varEnv btvEnv exp, ty, loc)
       | TFPFFIVAL {funExp, libExp, argTyList, resultTy, funTy, loc} =>
         let
           val newFunExp = tfpexpToRcexp varEnv btvEnv funExp
           val newLibExp = tfpexpToRcexp varEnv btvEnv libExp
         in
           RCFFIVAL 
             {
              funExp=newFunExp, 
              libExp=newLibExp, 
              argTyList=argTyList, 
              resultTy=resultTy, 
              funTy=funTy, 
              loc=loc
              }
         end
       | TFPSEQ {expList, expTyList, loc} =>
         RCSEQ {
                expList=map (tfpexpToRcexp varEnv btvEnv) expList, 
                expTyList=expTyList, 
                loc=loc
                }

  and tfpdecToRcdec varEnv btvEnv tfpdec = 
      case tfpdec
      of TFPVAL (binds, loc) =>
         let
           fun toRcbind (var, exp) = 
               let
                 val newvar =
                     case var of
                       TFC.VALDECIDENT varIdentInfo => 
                       T.VALIDENT varIdentInfo
                     | TFC.VALDECIDENTWILD ty => T.VALIDENTWILD ty 
               in
                 (newvar, tfpexpToRcexp varEnv btvEnv exp)
               end
         in
	   RCVAL (map toRcbind binds, loc)
         end
       | TFPVALREC (binds, loc) =>
         let
           fun toRcbind (var, expTy, exp) = 
             {var=var, expTy=expTy, exp = tfpexpToRcexp varEnv btvEnv exp}
         in
	   RCVALREC (map toRcbind binds, loc)
         end
       | TFPVALPOLYREC (localBtvEnv, binds, loc) =>
         let
           fun toRcbind (var, ty, exp) =
               {var=var, expTy = ty, exp = tfpexpToRcexp varEnv (unionBtvEnv(btvEnv, localBtvEnv)) exp}
         in
	   RCVALPOLYREC (localBtvEnv, map toRcbind binds, loc)
         end
       | TFPLOCALDEC (localDecs, decs, loc) => 
	 RCLOCALDEC
             (
               map (tfpdecToRcdec varEnv btvEnv) localDecs,
               map (tfpdecToRcdec varEnv btvEnv) decs,
               loc
             )
       | TFPSETFIELD (e1, e2, int, ty, loc) =>
         RCSETFIELD
             (
               tfpexpToRcexp varEnv btvEnv e1,
               tfpexpToRcexp varEnv btvEnv e2,
               int,
               ty,
               loc
             )
       | TFPSETGLOBAL(string, e, loc) =>
         RCSETGLOBAL (string, tfpexpToRcexp varEnv btvEnv e, loc)
       | TFPSETGLOBALVALUE (arrayIndex, offset, e, ty, loc) =>
         RCSETGLOBALVALUE(arrayIndex, offset, tfpexpToRcexp varEnv btvEnv e, ty, loc)
       | TFPINITARRAY (arrayIndex, offset, ty, loc) =>
         RCINITARRAY (arrayIndex, offset, ty, loc)

  fun compile decs =
      let
        val _ = nextBranchId := 0
	val _ = ME.clearFlag ME.Redundant
	val _ = ME.clearErrorMessages ()
	val decs = map (tfpdecToRcdec VIdMap.empty IEnv.empty) decs
      in
	if ME.isRedundant ()
	then raise UE.UserErrors (rev (ME.getErrorMessages ()))
	else (decs, rev (ME.getErrorMessages ()))
      end
end
