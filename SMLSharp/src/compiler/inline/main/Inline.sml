(**
 * @copyright (c) 2007, Tohoku University.
 * @author Isao Sasano
 * @version $Id: Inline.sml,v 1.25 2008/08/06 17:23:39 ohori Exp $
 *)

structure Inline : INLINE =
struct

local
structure ID = VarID
structure MV = MultipleValueCalc
structure MU = MultipleValueCalcUtils
structure IU = InlineUtils
structure IE = InlineEnv
structure ATU = AnnotatedTypesUtils
structure AT = AnnotatedTypes
structure T = Types

in 
local

(* we consider EXTERNAL variable as non-free variable. *)
fun hasFV env mvexp =
    case mvexp of
	MV.MVFOREIGNAPPLY {funExp, argExpList,...}
	=> hasFV env funExp orelse 
	   foldr (fn (mvexp,r) => hasFV env mvexp orelse r) false argExpList
      | MV.MVEXPORTCALLBACK {funExp,...}
	=> hasFV env funExp
      | MV.MVSIZEOF _
	=> false
      | MV.MVCONSTANT _
	=> false
      | MV.MVGLOBALSYMBOL _
        => false
      | MV.MVEXCEPTIONTAG _
	=> false
      | MV.MVVAR {varInfo={varId=T.INTERNAL id,...},...}
	=> not (ID.Set.member (env,id))
      | MV.MVVAR {varInfo={varId=T.EXTERNAL _,...},...}
	=> false (* consider EXTERNAL as non-free variable *)
      | MV.MVGETFIELD {arrayExp, indexExp,...}
	=> hasFV env arrayExp orelse hasFV env indexExp
      | MV.MVSETFIELD {valueExp, arrayExp, indexExp,...}
	=> hasFV env valueExp 
	   orelse hasFV env arrayExp 
	   orelse hasFV env indexExp
      | MV.MVSETTAIL {consExp, newTailExp,...}
	=> hasFV env consExp orelse hasFV env newTailExp
      | MV.MVARRAY {sizeExp, initialValue,...}
	=> hasFV env sizeExp orelse hasFV env initialValue
      | MV.MVCOPYARRAY {srcExp,srcIndexExp,dstExp,dstIndexExp,lengthExp,...}
	=> hasFV env srcExp 
	   orelse hasFV env srcIndexExp
	   orelse hasFV env dstExp
	   orelse hasFV env dstIndexExp
	   orelse hasFV env lengthExp
      | MV.MVPRIMAPPLY {argExpList,...}
	=> foldr (fn (mvexp,r) => hasFV env mvexp orelse r) 
		 false argExpList
      | MV.MVAPPM {funExp,argExpList,...}
	=> hasFV env funExp orelse
	   foldr (fn (mvexp,r) => hasFV env mvexp orelse r) 
		 false argExpList
      | MV.MVLET {localDeclList, mainExp,...}
	=> let val (env,r) = hasFVDeclList env localDeclList
	   in r orelse hasFV env mainExp
	   end
      | MV.MVMVALUES {expList,...}
	=> foldr (fn (mvexp,r) => hasFV env mvexp orelse r) 
		 false expList
      | MV.MVRECORD {expList,...}
	=> foldr (fn (mvexp,r) => hasFV env mvexp orelse r) 
		 false expList
      | MV.MVSELECT {recordExp,...}
	=> hasFV env recordExp
      | MV.MVMODIFY {recordExp, valueExp,...}
	=> hasFV env recordExp orelse hasFV env valueExp
      | MV.MVRAISE {argExp,...}
	=> hasFV env argExp
      | MV.MVHANDLE {exp, exnVar={varId,...}, handler,...}
	=> 
	(case varId of 
	     T.EXTERNAL _ => raise Control.Bug "invalid MVHANDLE in inliner"
	   | T.INTERNAL id =>
	     hasFV env exp orelse 
	     let val env = ID.Set.add (env,id)
	     in
		 hasFV env handler
	     end
	)
      | MV.MVFNM {argVarList, bodyExp,...}
	=> let val env = 
		   foldr (fn ({varId=T.INTERNAL id,...}, env) => ID.Set.add (env,id)
			   | _ => raise Control.Bug "invalid argVarList in inliner")
			 env argVarList
	   in hasFV env bodyExp
	   end
      | MV.MVPOLY {exp,...}
	=> hasFV env exp
      | MV.MVTAPP {exp,...}
	=> hasFV env exp
      | MV.MVSWITCH {switchExp, branches, defaultExp,...}
	=> let val s = hasFV env switchExp
	       val b = foldr (fn ({exp,...},r) => hasFV env exp orelse r)
			     false branches
	       val d = hasFV env defaultExp
	   in s orelse b orelse d
	   end
      | MV.MVCAST {exp,...}	   
	=> hasFV env exp

and hasFVDecl env decl =
    case decl of
	MV.MVVAL {boundVars, boundExp,...}
	=> let val r = hasFV env boundExp
	       val env = foldr (fn ({varId=T.INTERNAL id,...}, env) => ID.Set.add (env,id)
				 | ({varId=T.EXTERNAL _,...}, env) => env)
			       env boundVars
	   in (env,r)
	   end
      | MV.MVVALREC {recbindList,...}
	=> let val env = foldr (fn ({boundVar={varId=T.INTERNAL id,...},...},env) 
				   => ID.Set.add (env,id)
				 | ({boundVar={varId=T.EXTERNAL _,...},...},env)
				   => env)
			       env recbindList
	   in (env,
	       foldr (fn ({boundExp,...},r) => hasFV env boundExp orelse r)
		     false recbindList
	      )
	   end
      | MV.MVVALPOLYREC {recbindList,...}
	=> let val env = foldr (fn ({boundVar={varId=T.INTERNAL id,...},...},env) 
				   => ID.Set.add (env,id)
				 | ({boundVar={varId=T.EXTERNAL _,...},...},env)
				   => env)
			       env recbindList
	   in (env,
	       foldr (fn ({boundExp,...},r) => hasFV env boundExp orelse r)
		     false recbindList
	      )
	   end

and hasFVDeclList env declList =
    let fun f (decl, (env,r)) = 
	    let val (env',r') = hasFVDecl env decl
	    in (env', r orelse r')
	    end
    in
	foldl f (env,false) declList
    end

in
fun hasFreeVar mvexp = hasFV ID.Set.empty mvexp
end  

fun addSimples {varList=nil, mvexpList=nil, localEnv} = localEnv
  | addSimples 
    {varList = ({varId=T.INTERNAL id,...}:MV.varInfo) :: varList,
     mvexpList = mvexp :: mvexpList,
     localEnv} =
    let val newLocalEnv = ID.Map.insert (localEnv,id,IE.SIMPLE mvexp)
    in addSimples {varList=varList,
		  mvexpList=mvexpList,
		  localEnv=newLocalEnv}
    end
  | addSimples _ = raise Control.Bug "inliner bug"

fun inlineBranches {globalEnv, localEnv, intRenameEnv, 
		    tyEnv, branches=nil}
    = {branches=nil, size=0}
  | inlineBranches {globalEnv, localEnv, intRenameEnv, 
		    tyEnv, branches={constant, exp}::branches}
    = let val {mvexp=constant, size=sizeConst,...} = (* can i delete this case ? *)
	      inlineExp 
		  {
		   globalEnv=globalEnv,
		   localEnv=localEnv,
		   intRenameEnv=intRenameEnv,
		   tyEnv=tyEnv,
		   mvexp=constant
		  }
	  val {mvexp=exp, size=sizeExp,...} =
	      inlineExp 
		  {
		   globalEnv=globalEnv,
		   localEnv=localEnv,
		   intRenameEnv=intRenameEnv,
		   tyEnv=tyEnv,
		   mvexp=exp
		  }
	  val {branches, size=sizeBranch,...} =
	      inlineBranches
		  {
		   globalEnv=globalEnv,
		   localEnv=localEnv,
		   intRenameEnv=intRenameEnv,
		   tyEnv=tyEnv,
		   branches=branches
		  }
	  val inlinedBranches =
	      {constant=constant, exp=exp} :: branches
	  val size = sizeConst + sizeExp + sizeBranch
      in
	  {branches=inlinedBranches, size=size}
      end

and inlineExpList {globalEnv,localEnv,intRenameEnv,tyEnv,
		   mvexpList=nil}
    = {mvexpList=nil, size=0, etyList=nil}
  | inlineExpList {globalEnv, localEnv, intRenameEnv, tyEnv, 
		   mvexpList=mvexp::mvexpList}
    = let val {mvexp, size=sizeExp,ety,...} = 
	      inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			 tyEnv=tyEnv, mvexp=mvexp}
	  val {mvexpList, size=sizeExpList,etyList,...} =
	      inlineExpList {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			     tyEnv=tyEnv, mvexpList=mvexpList}
	  val size = sizeExp + sizeExpList
	  val etyList=ety::etyList
      in {mvexpList=mvexp::mvexpList, size=size, etyList=etyList}
      end

and inlineExp {globalEnv, localEnv, intRenameEnv, tyEnv, mvexp}
  = 
  case mvexp of 
	MV.MVFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc}
	=> 
	let val {mvexp=funExp, size=sizeFun,...} 
		= inlineExp 
		      {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
		       tyEnv=tyEnv,mvexp=funExp}
	    val {mvexpList=argExpList, size=sizeArgs,...}
		= inlineExpList 
		      {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
		       tyEnv=tyEnv,mvexpList=argExpList}
	    val funTy = IU.substitute tyEnv funTy
	    val mvexp = MV.MVFOREIGNAPPLY 
			    {
			     funExp=funExp,
			     funTy=funTy,
			     argExpList=argExpList,
			     attributes=attributes,
			     loc=loc
			    }
	    val size = sizeFun + sizeArgs + 1
	    val ety = IU.bodyTy funTy
	in
	    {mvexp=mvexp, size=size, ety=ety}
	end
      | MV.MVEXPORTCALLBACK {funExp, funTy, attributes, loc} 
	=> 
	let val {mvexp=funExp,size=sizeFun,...}
	      = inlineExp {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
			   tyEnv=tyEnv,mvexp=funExp}
	    val funTy = IU.substitute tyEnv funTy
	    val mvexp = MV.MVEXPORTCALLBACK
			    {
			     funExp=funExp,
			     funTy=funTy,
                             attributes=attributes,
			     loc=loc
			    }
	    val ety = AT.wordty
	in
	    {mvexp=mvexp, size=sizeFun+1, ety=ety}
	end
      | MV.MVSIZEOF {ty, loc}
	=> 
	let val ty = IU.substitute tyEnv ty
	    val mvexp = MV.MVSIZEOF {ty=ty, loc=loc}
	    val ety = AT.intty
	in
	    {mvexp=mvexp, size=1, ety=ety}
	end
      | MV.MVCONSTANT {value, loc}
	=> 
	let val ety = ATU.constDefaultTy value
	in
	    {mvexp=mvexp, size=1, ety=ety}
	end
      | MV.MVGLOBALSYMBOL {ty, ...}
        => {mvexp=mvexp, size=1, ety=ty}
      | MV.MVEXCEPTIONTAG {tagValue, displayName, loc}
	=> 
	let val ety = AT.exntagty
	in
	    {mvexp=mvexp, size=1, ety=ety}
	end
      | MV.MVVAR {varInfo=varInfo as {varId = T.INTERNAL id,ty,...}:MV.varInfo, loc}
	=> 
	let val id = case ID.Map.find (intRenameEnv, id) of
			 SOME id => id
		       | NONE => id (* this case happens since inliner function may process 
				     * function term twice. 
                                     *)
	    val ty = IU.substitute tyEnv ty
	    val varInfo = IU.changeID id varInfo
	    val varInfo = IU.changeTY ty varInfo
	    val mvexp = MV.MVVAR {varInfo=varInfo,loc=loc}
	in case ID.Map.find (localEnv, id) of (* expand when the element is a constant, variable, 
					       * exception tag, and a cast of them. *)
	       SOME (IE.SIMPLE mvexp)
	       => 
	       let val size = case mvexp of
				  MV.MVCAST _ => 2
				| _ => 1
	       in
		   {mvexp=mvexp, size=size, ety=ty}
	       end
	     | _ (* in other cases we leave the variable unexpanded *)
	       => {mvexp=mvexp, size=1, ety=ty}
	end
      | MV.MVVAR {varInfo=varInfo as {varId = T.EXTERNAL ai,ty,...}:MV.varInfo, loc}
	=> 
	let 
	    val ty = IU.substitute tyEnv ty
	    val varInfo = IU.changeTY ty varInfo
	    val mvexp = MV.MVVAR {varInfo=varInfo,loc=loc}
	    val (mvexp,size) =
		case ExVarID.Map.find (globalEnv,ai) of
		    SOME (IE.GSIMPLE (mvexp as (MV.MVCONSTANT _),_))
		    => (mvexp, 1) (* expand constant *)
                  | SOME (IE.GSIMPLE (mvexp as (MV.MVGLOBALSYMBOL _),_))
                    => (mvexp, 1)
		  | SOME (IE.GSIMPLE (mvexp as (MV.MVVAR _),_))
		    => 
		    (mvexp, 1) (* expand variable. this is a global variable. *)
		  | SOME _
		    => (mvexp, 1) (* do not expand other cases *)
		  | NONE (* this index does not exist in the global env. *)
		    => (mvexp, 1)
	in {mvexp=mvexp, size=size, ety=ty}
	end
      | MV.MVGETFIELD {arrayExp, indexExp, elementTy, loc}
	=> let val {mvexp=arrayExp,size=sizeArray,...} = 
		   inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			      tyEnv=tyEnv, mvexp=arrayExp}
	       val {mvexp=indexExp,size=sizeIndex,...} = 
		   inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			      tyEnv=tyEnv, mvexp=indexExp}
	       val elementTy = IU.substitute tyEnv elementTy
	       val mvexp = MV.MVGETFIELD 
			       {
				arrayExp=arrayExp, 
				indexExp=indexExp, 
				elementTy=elementTy, 
				loc=loc
			       }
	   in {mvexp=mvexp, size=sizeArray+sizeIndex+1, ety=elementTy}
	   end
      | MV.MVSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc}
	=> let val {mvexp=valueExp, size=sizeValue,...} = 
		   inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			      tyEnv=tyEnv, mvexp=valueExp}
	       val {mvexp=arrayExp, size=sizeArray,...} = 
		   inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			      tyEnv=tyEnv, mvexp=arrayExp}
	       val {mvexp=indexExp, size=sizeIndex,...} = 
		   inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			      tyEnv=tyEnv, mvexp=indexExp}
	       val elementTy = IU.substitute tyEnv elementTy
	       val mvexp = MV.MVSETFIELD 
			       {
				valueExp=valueExp,
				arrayExp=arrayExp,
				indexExp=indexExp, 
				elementTy=elementTy,
				loc=loc
			       }
	       val size=sizeValue+sizeArray+sizeIndex+1
	       val ety=AT.unitty
	   in {mvexp=mvexp,size=size,ety=ety}
	   end
      | MV.MVSETTAIL {consExp, newTailExp, tailLabel, listTy, consRecordTy, loc}
	=> 
	let val {mvexp=consExp,size=sizeCons,...} = 
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			   tyEnv=tyEnv, mvexp=consExp}
	    val {mvexp=newTailExp,size=sizeTail,...} = 
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			   tyEnv=tyEnv, mvexp=newTailExp}
	    val listTy = IU.substitute tyEnv listTy
	    val consRecordTy = IU.substitute tyEnv consRecordTy
	    val mvexp = MV.MVSETTAIL
			    {
			     consExp=consExp,
			     newTailExp=newTailExp,
			     tailLabel=tailLabel,
			     listTy=listTy,
			     consRecordTy=consRecordTy,
			     loc=loc
			    }
	    val ety=AT.unitty
	in
	    {mvexp=mvexp, size=sizeCons+sizeTail+1, ety=ety}
	end
      | MV.MVARRAY {sizeExp, initialValue, elementTy, isMutable, loc}
	=> let val {mvexp=sizeExp,size=sizeSize,...} = 
		   inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			      tyEnv=tyEnv, mvexp=sizeExp}
	       val {mvexp=initialValue,size=sizeInit,...} = 
		   inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			      tyEnv=tyEnv, mvexp=initialValue}
	       val elementTy = IU.substitute tyEnv elementTy
	       val mvexp = MV.MVARRAY
			       {
				sizeExp=sizeExp,
				initialValue=initialValue,
				elementTy=elementTy,
                                isMutable=isMutable,
				loc=loc
			       }
	       val size = sizeSize + sizeInit + 1
	       val ety = AT.arrayty elementTy
	   in {mvexp=mvexp, size=size, ety=ety}
	   end
      | MV.MVCOPYARRAY {srcExp,srcIndexExp,dstExp,dstIndexExp,lengthExp,elementTy,loc}
	=> 
	let val {mvexp=srcExp, size=sizeSrcExp,...} =
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			   tyEnv=tyEnv, mvexp=srcExp}
	    val {mvexp=srcIndexExp, size=sizeSrcIndexExp,...} =
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			   tyEnv=tyEnv, mvexp=srcIndexExp}
	    val {mvexp=dstExp, size=sizeDstExp,...} =
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			   tyEnv=tyEnv, mvexp=dstExp}
	    val {mvexp=dstIndexExp, size=sizeDstIndexExp,...} =
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			   tyEnv=tyEnv, mvexp=dstIndexExp}
	    val {mvexp=lengthExp, size=sizeLengthExp,...} =
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			   tyEnv=tyEnv, mvexp=lengthExp}
	    val elementTy = IU.substitute tyEnv elementTy
	    val mvexp = MV.MVCOPYARRAY 
			    {srcExp=srcExp,
			     srcIndexExp=srcIndexExp,
			     dstExp=dstExp,
			     dstIndexExp=dstIndexExp,
			     lengthExp=lengthExp,
			     elementTy=elementTy,
			     loc=loc}
	    val size = sizeSrcExp + sizeSrcIndexExp + sizeDstExp + sizeDstIndexExp + sizeLengthExp + 1
	    val ety = AT.unitty
	in {mvexp=mvexp, size=size, ety=ety}
	end
      | MV.MVPRIMAPPLY {primInfo={name,ty}, argExpList, instTyList, loc}
	=> 
	let
	    val ty = IU.substitute tyEnv ty
	    val instTyList = map (IU.substitute tyEnv) instTyList
	    val primInfo = {name=name,ty=ty}
	    val {mvexpList=argExpList,size,...} = 
		   inlineExpList {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
				  tyEnv=tyEnv, 
				  mvexpList=argExpList}
	    val mvexp = MV.MVPRIMAPPLY
			    {
			     primInfo=primInfo,
			     argExpList=argExpList,
			     instTyList = instTyList,
			     loc=loc
			    }
	    val ety = IU.bodyTy ty
	in {mvexp=mvexp, size=size+1, ety=ety}
	end
      | MV.MVAPPM {funExp as MV.MVVAR {...}, funTy, argExpList, loc}
	=> 
	let 
	    val {mvexp=funExp,size=sizeFun,...} = 
		inlineExp {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
			   tyEnv=tyEnv,mvexp=funExp} 
	    val funTy = IU.substitute tyEnv funTy
	    val {mvexpList=argExpList, size=sizeArgExpList,...} = 
		   inlineExpList 
		       {
			globalEnv=globalEnv,
			localEnv=localEnv,
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv, 
			mvexpList=argExpList
		       }
	    val defaultMVExp = MV.MVAPPM
				   {
				    funExp=funExp, 
				    funTy=funTy,
				    argExpList=argExpList,
				    loc=loc
				   }
	    val defaultSize = sizeFun + sizeArgExpList + 1
	    val ety = IU.bodyTy funTy
	in
	    case funExp of 
		MV.MVVAR {varInfo={varId=T.INTERNAL id,...},...}
		=>
		(
		 case ID.Map.find (localEnv, id) of
		     SOME (IE.FN (MV.MVFNM {argVarList, bodyExp, ...},displayName))
		     => 
		     let 
			 (*
			 val _ = IU.localInlineCount displayName
			  *)
			 val newArgVarList = map IU.renameID argVarList
			 val intRenameEnv = ListPair.foldr
						(fn ({varId=T.INTERNAL id,...},
						     {varId=T.INTERNAL newId,...},
						     renameEnv) =>
						    ID.Map.insert (renameEnv,id,newId)
						  | _ => raise Control.Bug "invalid varinfo in inliner")
						intRenameEnv
						(argVarList,newArgVarList)
			 val localEnv =
			     addSimples
				 {
				  varList=newArgVarList, 
				  mvexpList=argExpList, 
				  localEnv=localEnv
				 }
			 val {mvexp,size,... } = 
			     inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
					tyEnv=tyEnv, mvexp=bodyExp}
		     in {mvexp=mvexp, size=size, ety=ety}
		     end
		   | _ 
		     => {mvexp=defaultMVExp, size=defaultSize, ety=ety}
		)
	      | MV.MVVAR {varInfo={varId=T.EXTERNAL ai,...},...}
		=> 
		(
		 case ExVarID.Map.find (globalEnv, ai) of
		     SOME (IE.GFN (MV.MVFNM {argVarList, funTy, bodyExp, annotation, loc},displayName))
		     => 
		     let 
			 (*
			 val _ = IU.globalInlineCount displayName
			 *)
			 val newArgVarList = map IU.renameID argVarList
			 val intRenameEnv = ListPair.foldr
						(fn ({varId=T.INTERNAL id,...},
						     {varId=T.INTERNAL newId,...},
						     renameEnv) =>
						    ID.Map.insert (renameEnv,id,newId)
						  | _ => raise Control.Bug "invalid varInfo in inliner")
						intRenameEnv
						(argVarList,newArgVarList)
			 val localEnv =
			     addSimples
				 {
				  varList=newArgVarList, 
				  mvexpList=argExpList, 
				  localEnv=localEnv
				 }
			 val {mvexp,size,... } = 
			     inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
					tyEnv=tyEnv, 
					mvexp=bodyExp}
		     in {mvexp=mvexp, size=size, ety=ety}
		     end
		   | _
		     => {mvexp=defaultMVExp, size=defaultSize, ety=ety}
		)
	      | _ 
		=> {mvexp=defaultMVExp, size=defaultSize, ety=ety}
	end
      | MV.MVAPPM {funExp as MV.MVTAPP 
			  {exp=mvvar as MV.MVVAR {...}, expTy, instTyList, loc=tappLoc},
		   funTy, argExpList, loc}
	=>
	let 
	    val {mvexp=inlinedMVVar,size=sizeInlinedMVVar,...} = 
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv,
			   tyEnv=tyEnv,mvexp=mvvar}
	    val expTy = IU.substitute tyEnv expTy
	    val instTyList = map (IU.substitute tyEnv) instTyList
	    val funExp = MV.MVTAPP {exp=inlinedMVVar,expTy=expTy,instTyList=instTyList,loc=tappLoc}
	    val funTy = IU.substitute tyEnv funTy
	    val {mvexpList=argExpList, size=sizeArgExpList,...} =
		inlineExpList {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
			       tyEnv=tyEnv,
			       mvexpList=argExpList}
	    val defaultMVExp =
		MV.MVAPPM {funExp=funExp, funTy=funTy, argExpList=argExpList, loc=loc}
	    val defaultSize = sizeInlinedMVVar + sizeArgExpList + 1
	    val ety = IU.bodyTy funTy
	in
	    case inlinedMVVar of
		MV.MVVAR {varInfo={varId=T.INTERNAL id,...},...}
		=>
		(
		 case ID.Map.find (localEnv, id) of
		     SOME (IE.PFN (btvEnv, MV.MVFNM {argVarList,bodyExp,...}, _, displayName))
		     =>
		     let 
			 val newArgVarList = map IU.renameID argVarList
			 val intRenameEnv = ListPair.foldr
						(fn ({varId=T.INTERNAL id,...},
						     {varId=T.INTERNAL newId,...},
						     renameEnv) =>
						    ID.Map.insert (renameEnv,id,newId)
						  | _ => raise Control.Bug "invalid varinfo in inliner")
						intRenameEnv
						(argVarList,newArgVarList)
			 val btvList = map (fn (key,_) => key) (IEnv.listItemsi btvEnv)
			 val tyEnv = ListPair.foldr (fn (key,ty,subst) => IU.insertTyEnv (subst,key,ty)) 
						    tyEnv (btvList, instTyList)
			 (*
			 val _ = IU.localPolyInlineCount displayName
			 *)
			 val localEnv = addSimples
					    {
					     varList=newArgVarList, 
					     mvexpList=argExpList, 
					     localEnv=localEnv
		    			    }
			 val {mvexp,size,ety,...} =
			     inlineExp {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
					tyEnv=tyEnv,
					mvexp=bodyExp}
		     in {mvexp=mvexp, size=size, ety=ety}
		     end
		   | _
		     => {mvexp=defaultMVExp, size=defaultSize, ety=ety}
		)
	      | MV.MVVAR {varInfo={varId=T.EXTERNAL ai,...},...}
		=>
		(
		 case ExVarID.Map.find (globalEnv, ai) of
		     SOME (IE.GPFN (btvEnv, MV.MVFNM {argVarList, bodyExp, ...}, _, displayName))
		     => 
		     let 
			 val newArgVarList = map IU.renameID argVarList
			 val intRenameEnv = ListPair.foldr
						(fn ({varId=T.INTERNAL id,...},
						     {varId=T.INTERNAL newId,...},
						     renameEnv) =>
						    ID.Map.insert (renameEnv,id,newId)
						  | _ => raise Control.Bug "invalid varinfo in inliner")
						intRenameEnv
						(argVarList,newArgVarList)
			 val btvList = map (fn (key,_) => key) (IEnv.listItemsi btvEnv)
			 val tyEnv = ListPair.foldr (fn (key,ty,subst) => IU.insertTyEnv (subst,key,ty)) 
						    tyEnv (btvList, instTyList)
			 (*
			  val _ = IU.globalPolyInlineCount displayName
			 *)
			 val localEnv =
			     addSimples
				 {
				  varList=newArgVarList, 
				  mvexpList=argExpList, 
				  localEnv=localEnv
				 }
			 val {mvexp,size,ety,... } = 
			     inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
					tyEnv=tyEnv, 
					mvexp=bodyExp}
		     in {mvexp=mvexp, size=size, ety=ety}
		     end
		   | _
		     => {mvexp=defaultMVExp, size=defaultSize, ety=ety}
		)
	      | _
		=> {mvexp=defaultMVExp, size=defaultSize, ety=ety}
	end
      | MV.MVAPPM {funExp, funTy, argExpList, loc} (* other cases *)
	=> 
	let 
	    val {mvexp=funExp,size=sizeFun,...} =
		inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			   tyEnv=tyEnv, 
			   mvexp=funExp}
	    val funTy = IU.substitute tyEnv funTy
	    val {mvexpList=argExpList,size=sizeArgExpList,...} =
		inlineExpList {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			       tyEnv=tyEnv, 
			       mvexpList=argExpList}
	    val mvexp = MV.MVAPPM
			    {
			     funExp=funExp,
			     funTy=funTy,
			     argExpList=argExpList,
			     loc=loc
			    }
	    val size = sizeFun + sizeArgExpList + 1
	    val ety = IU.bodyTy funTy
	in {mvexp=mvexp, size=size, ety=ety}
	end
      | MV.MVLET {localDeclList, mainExp, loc}
	=> 
	let val {globalEnv, localEnv=newLocalEnv, intRenameEnv, 
		 mvdeclList=localDeclList, size=sizeDecls}
		= 
		inlineDeclList 
		    {
		     globalEnv=globalEnv, 
		     localEnv=localEnv, 
		     intRenameEnv=intRenameEnv,
		     tyEnv=tyEnv,
		     mvdeclList=localDeclList
		    }
	    val {mvexp=mainExp, size=sizeMain, ety,...} = 
		inlineExp 
		    {
		     globalEnv=globalEnv,
		     localEnv=newLocalEnv,
		     intRenameEnv=intRenameEnv,
		     tyEnv=tyEnv,
		     mvexp=mainExp
		    }
	    val mvexp = MV.MVLET
			    {
			     localDeclList=localDeclList,
			     mainExp=mainExp,
			     loc=loc
			    }
	    val size = sizeDecls + sizeMain + 1
	in {mvexp=mvexp, size=size, ety=ety}
	end
      | MV.MVMVALUES {expList, tyList, loc}
	=> 
	let val {mvexpList=expList, size, etyList,...} =
		inlineExpList 
		    {
		     globalEnv=globalEnv, 
		     localEnv=localEnv, 
		     intRenameEnv=intRenameEnv,
		     tyEnv=tyEnv,
		     mvexpList=expList
		    }
	    val tyList = map (IU.substitute tyEnv) tyList
	    val mvexp = MV.MVMVALUES
			    {
			     expList=expList,
			     tyList=tyList,
			     loc=loc
			    }
	    val ety = AT.MVALty etyList
	in {mvexp=mvexp, size=size+1, ety=ety}
	end
      | MV.MVRECORD {expList, recordTy, annotation, isMutable, loc}
	=> 
	let val {mvexpList=expList, size,...} =
		inlineExpList 
		    {
		     globalEnv=globalEnv, 
		     localEnv=localEnv, 
		     intRenameEnv=intRenameEnv,
		     tyEnv=tyEnv,
		     mvexpList=expList
		    }
	    val recordTy = IU.substitute tyEnv recordTy
	    val mvexp = MV.MVRECORD
			    {
			     expList=expList,
			     recordTy=recordTy,
			     annotation=annotation,
			     isMutable=isMutable,
			     loc=loc
			    }
	in {mvexp=mvexp, size=size+1, ety=recordTy}
	end
      | MV.MVSELECT {recordExp, label, recordTy, resultTy, loc}
	=> let val {mvexp=recordExp, size, ety,...} =
		   inlineExp
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			mvexp=recordExp
		       }
	       val recordTy = IU.substitute tyEnv recordTy
	       val resultTy = IU.substitute tyEnv resultTy
	       val mvexp = MV.MVSELECT
			       {
				recordExp=recordExp,
				label=label,
				recordTy=recordTy,
				resultTy=resultTy,
				loc=loc
			       }
	   in {mvexp=mvexp, size=size+1, ety=resultTy}
	   end
      | MV.MVMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc}
	=> let val {mvexp=recordExp,size=sizeRecord,ety,...} =
		   inlineExp
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			mvexp=recordExp
		       }
	       val {mvexp=valueExp, size=sizeValue,...} =
		   inlineExp
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			mvexp=valueExp
		       }
               val recordTy = IU.substitute tyEnv recordTy
               val valueTy = IU.substitute tyEnv valueTy
	       val mvexp = MV.MVMODIFY
				      {
				       recordExp=recordExp,
				       recordTy=recordTy,
				       label=label,
				       valueExp=valueExp,
				       valueTy=valueTy,
				       loc=loc
				      }
	       val size = sizeRecord + sizeValue + 1
	   in {mvexp=mvexp, size=size, ety=ety}
	   end
      | MV.MVRAISE {argExp, resultTy, loc}
	=> let val {mvexp=argExp,size,...} =
		   inlineExp
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			mvexp=argExp
		       }
	       val resultTy = IU.substitute tyEnv resultTy
	       val mvexp = MV.MVRAISE
			       {
				argExp=argExp,
				resultTy=resultTy,
				loc=loc
			       }
	   in {mvexp=mvexp, size=size+1, ety=resultTy}
	   end
      | MV.MVHANDLE {exp, exnVar as {varId,...}, handler, loc}
	=> 
	(case varId of
	     T.EXTERNAL _ => raise Control.Bug "invalid MVHANDLE in inliner"
	   | T.INTERNAL id =>
	     let 
		 val {mvexp=exp, size=sizeExp,ety,...} =
		     inlineExp
			 {
			  globalEnv=globalEnv, 
			  localEnv=localEnv, 
			  intRenameEnv=intRenameEnv,
			  tyEnv=tyEnv,
			  mvexp=exp
			 }
		 val (newExnVar,newId) = let val newExnVar = IU.renameID exnVar
					 in case newExnVar of
						{varId=T.INTERNAL newId,...} =>
						(newExnVar,newId)
					      | {varId=T.EXTERNAL _,...} =>
						raise Control.Bug "invalid result of renameId in inliner"
					 end
		 val intRenameEnv = ID.Map.insert (intRenameEnv,id,newId)
		 val newExnVar = IU.substVarInfo tyEnv newExnVar
		 val {mvexp=handler, size=sizeHandler,...} =
		     inlineExp
			 {
			  globalEnv=globalEnv, 
			  localEnv=localEnv, 
			  intRenameEnv=intRenameEnv,
			  tyEnv=tyEnv,
			  mvexp=handler
			 }
		 val mvexp = MV.MVHANDLE
				 {
				  exp=exp,
				  exnVar=newExnVar,
				  handler=handler,
				  loc=loc
				 }
		 val size = sizeExp + sizeHandler + 1
	     in {mvexp=mvexp, size=size, ety=ety}
	     end
	)
      | MV.MVFNM {argVarList, funTy, bodyExp, annotation, loc}
	=> let val newArgVarList = map IU.renameID argVarList
	       val newArgVarList = map (IU.substVarInfo tyEnv) newArgVarList
	       val intRenameEnv = ListPair.foldr
				      (fn ({varId=T.INTERNAL id,...},
					   {varId=T.INTERNAL newId,...},
					   renameEnv) =>
					  ID.Map.insert (renameEnv,id,newId)
					| _ => raise Control.Bug "invalid argVarList in inliner")
				      intRenameEnv
				      (argVarList,newArgVarList)
	       val funTy = IU.substitute tyEnv funTy
	       val {mvexp=bodyExp,size=sizeBody,...} = 
		   inlineExp {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
			      tyEnv=tyEnv, 
			      mvexp=bodyExp}
	       val mvexp = MV.MVFNM
			       {
				argVarList=newArgVarList,
				funTy=funTy,
				bodyExp=bodyExp,
				annotation=annotation,
				loc=loc
			       }
	   in {mvexp=mvexp, size=sizeBody+1, ety=funTy}
	   end
      | MV.MVPOLY {btvEnv, expTyWithoutTAbs, exp, loc}
	=> 
	let 
	    val (btvEnv,tyEnv) = 
		let 
		    val (subst,freshBtvEnv) = IU.copyBtvEnv  btvEnv
		in (
		    case tyEnv of 
			NONE => freshBtvEnv
		      | SOME tyEnv => IU.substituteBtvEnv tyEnv freshBtvEnv,
		    IEnv.foldri (fn (oldId,btv,tyEnv) => IU.insertTyEnv (tyEnv,oldId,btv))
				tyEnv subst
		    )
		end
	    val expTyWithoutTAbs = IU.substitute tyEnv expTyWithoutTAbs
	    val {mvexp=exp, size, ety=bodyExpTy,...} =
		   inlineExp
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			mvexp=exp
		       }
	    val mvexp = MV.MVPOLY
			    {
			     btvEnv=btvEnv,
			     expTyWithoutTAbs=expTyWithoutTAbs,
			     exp=exp,
			     loc=loc
			    }
	    val ety = AT.POLYty {boundtvars=btvEnv, body=bodyExpTy}
	in {mvexp=mvexp, size=size+1, ety=ety}
	end 
      | MV.MVTAPP {exp, expTy, instTyList, loc}
	=> 
	let val {mvexp=exp, size=sizeExp,...} =
		inlineExp
		    {
		     globalEnv=globalEnv, 
		     localEnv=localEnv, 
		     intRenameEnv=intRenameEnv,
		     tyEnv=tyEnv,
		     mvexp=exp
		    }
	    val expTy = IU.substitute tyEnv expTy
	    val instTyList = map (IU.substitute tyEnv) instTyList
	    val ety = case expTy of
			  AT.POLYty {boundtvars, body} =>
			  ATU.tpappTy(expTy, instTyList)
			| _ =>
			  raise Control.Bug "non poly ty in MVTAPP (inline/main/Inline.sml)"
	    val defaultMVExp = MV.MVTAPP
				   {
				    exp=exp,
				    expTy=expTy,
				    instTyList=instTyList,
				    loc=loc
				   }
	    val defaultSize = sizeExp + 1
	in
	    case exp of
		MV.MVVAR {varInfo={varId=T.INTERNAL id,...},...}
		=>
		(
		 case ID.Map.find (localEnv,id) of
		     SOME (IE.PFN (btvEnv,mvfnm,sizePFN,displayName))
		     =>
		     let
			 val btvList = map (fn (key,_) => key) (IEnv.listItemsi btvEnv)
			 val tyEnv = ListPair.foldr (fn (key,ty,subst) => IU.insertTyEnv (subst,key,ty))
						    tyEnv (btvList, instTyList)
			 val mvfnm = case tyEnv of
					 NONE => raise Control.Bug "inliner bug"
				       | SOME tyEnv => MU.substExp tyEnv mvfnm
			 val sizeMVFNM = sizePFN - 1
		     in
			 {mvexp=mvfnm, size=sizeMVFNM, ety=ety}
		     end
		   | _
		     =>
		     {mvexp=defaultMVExp, size=defaultSize, ety=ety}
		)
	      | MV.MVVAR {varInfo={varId=T.EXTERNAL ai,...},...}
		=>
		(
		 case ExVarID.Map.find (globalEnv, ai) of
		     SOME (IE.GPFN (btvEnv, mvfnm, (*sizeGPFN*)_, displayName))
		     =>
		     let
			 val btvList = map (fn (key,_) => key) (IEnv.listItemsi btvEnv)
			 val tyEnv = ListPair.foldr (fn (key,ty,subst) => IU.insertTyEnv (subst,key,ty))
						    tyEnv (btvList, instTyList)
			 val {mvexp=mvfnm,size=sizeMVFNM,ety} = 
			     inlineExp {globalEnv=globalEnv,
					localEnv=localEnv,
					intRenameEnv=intRenameEnv,
					tyEnv=tyEnv,
					mvexp=mvfnm}
		     in
			 {mvexp=mvfnm, size=sizeMVFNM, ety=ety}
		     end
		   | _
		     =>
		     {mvexp=defaultMVExp, size=defaultSize, ety=ety}
		)
	      | _
		=>
		{mvexp=defaultMVExp, size=defaultSize, ety=ety}
	end 
      | MV.MVSWITCH {switchExp, expTy, branches, defaultExp, loc}
	=> let val {mvexp=switchExp, size=sizeSwitch,...} =
		   inlineExp
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			mvexp=switchExp
		       }
	       val expTy = IU.substitute tyEnv expTy
	       val {branches, size=sizeBranch,...} =
		   inlineBranches
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			branches=branches
		       }
	       val {mvexp=defaultExp, size=sizeDefault,ety,...} =
		   inlineExp
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			mvexp=defaultExp
		       }
	       val mvexp = MV.MVSWITCH
			       {
				switchExp=switchExp,
				expTy=expTy,
				branches=branches,
				defaultExp=defaultExp,
				loc=loc
			       }
	       val size = sizeSwitch + sizeBranch + sizeDefault + 1
	   in {mvexp=mvexp, size=size, ety=ety}
	   end 
      | MV.MVCAST {exp, expTy, targetTy, loc}
	=> let val {mvexp=exp, size,...} =
		   inlineExp
		       {
			globalEnv=globalEnv, 
			localEnv=localEnv, 
			intRenameEnv=intRenameEnv,
			tyEnv=tyEnv,
			mvexp=exp
		       }
	       val expTy = IU.substitute tyEnv expTy
	       val targetTy = IU.substitute tyEnv targetTy
	       val (mvexp,size) = 
		   case exp of 
		       MV.MVCAST {exp,expTy,...}
		       =>
		       (MV.MVCAST 
			    {
			     exp=exp,
			     expTy=expTy,
			     targetTy=targetTy,
			     loc=loc
			    },
			size)
		     | _
		       =>
		       (MV.MVCAST
			    {
			     exp=exp,
			     expTy=expTy,
			     targetTy=targetTy,
			     loc=loc
			    },
			size+1)
	   in {mvexp=mvexp, size=size, ety=targetTy}
	   end 

and inlineDecl {globalEnv, localEnv, intRenameEnv, tyEnv, mvdecl}
  = case mvdecl of
	MV.MVVAL {boundVars, boundExp, loc}
	=>
	let 
	    val {mvexp=boundExp,size=sizeBoundExp,ety,...} = 
		inlineExp 
		    {
		     globalEnv=globalEnv,
		     localEnv=localEnv,
		     intRenameEnv=intRenameEnv,
		     tyEnv=tyEnv,
		     mvexp=boundExp
		    }
	    val (newBoundVars, intRenameEnv) =
		case boundVars of
		    [boundVar as {varId=T.EXTERNAL _,...}]
		    => 
			([boundVar], intRenameEnv) 
		  | _
		    =>
		    let val newBoundVars = map IU.renameID boundVars
			val intRenameEnv = ListPair.foldr
					    (fn ({varId=T.INTERNAL id,...},
						 {varId=T.INTERNAL newId,...},
						 renameEnv) =>
						ID.Map.insert (renameEnv,id,newId)
					      | _ => raise Control.Bug "invalid varInfo in inliner")
					    intRenameEnv
					    (boundVars,newBoundVars)
		    in (newBoundVars,intRenameEnv)
		    end
	    val newBoundVars = map (IU.substVarInfo tyEnv) newBoundVars
	    val newBoundVars = case newBoundVars of
				   [{varId,displayName,ty}] =>
				   [{varId=varId,displayName=displayName,ty=ety}]
				 | _ => newBoundVars (* this is not used
						      * since we wiil delete multiple binding declaration later. 
						      *)
	    val mvdecl = MV.MVVAL {boundVars=newBoundVars,
				   boundExp=boundExp,
				   loc=loc}
	    val sizeMVDecl = sizeBoundExp + 1
	in
	    case newBoundVars of
		[{varId,displayName,...}] => (* one variable, internal or external *)
		(case boundExp of
		     MV.MVCONSTANT _ 
		     =>
		     let 
			 val localEnv = 
			     case varId of
				 T.INTERNAL id
				 => ID.Map.insert (localEnv,id,IE.SIMPLE boundExp)
			       | T.EXTERNAL _ 
				 => localEnv
			 val globalEnv =
			     case varId of 
				 T.INTERNAL _ => globalEnv
			       | T.EXTERNAL ai
				 => ExVarID.Map.insert (globalEnv,ai,IE.GSIMPLE (boundExp,displayName))
			 val (mvdeclList,sizeMVDeclList) =
			     case varId of
				 T.INTERNAL _ => (nil,0)
			       | T.EXTERNAL _ => ([mvdecl],sizeMVDecl)
		     in 
			 {
			  globalEnv=globalEnv,
			  localEnv=localEnv,
			  intRenameEnv=intRenameEnv,
			  mvdeclList=mvdeclList,
			  size=sizeMVDeclList
			 }
		     end
		   | MV.MVGLOBALSYMBOL _
		     =>
		     let 
			 val localEnv = 
			     case varId of
				 T.INTERNAL id
				 => ID.Map.insert (localEnv,id,IE.SIMPLE boundExp)
			       | T.EXTERNAL _ 
				 => localEnv
			 val globalEnv =
			     case varId of 
				 T.INTERNAL _ => globalEnv
			       | T.EXTERNAL ai
				 => ExVarID.Map.insert (globalEnv,ai,IE.GSIMPLE (boundExp,displayName))
			 val (mvdeclList,sizeMVDeclList) =
			     case varId of
				 T.INTERNAL _ => (nil,0)
			       | T.EXTERNAL _ => ([mvdecl],sizeMVDecl)
		     in 
			 {
			  globalEnv=globalEnv,
			  localEnv=localEnv,
			  intRenameEnv=intRenameEnv,
			  mvdeclList=mvdeclList,
			  size=sizeMVDeclList
			 }
		     end
		   | MV.MVVAR {varInfo,...}
		     => 
		     let 
			 val localEnv =
			     case varId of
				 T.INTERNAL id
				 => ID.Map.insert (localEnv,id,IE.SIMPLE boundExp)
			       | T.EXTERNAL _
				 => localEnv
			 val globalEnv =
			     case varId of
				 T.INTERNAL _
				 => globalEnv
			       | T.EXTERNAL ai
				 =>
				 (
				  case #varId varInfo of
				      T.INTERNAL _ => globalEnv
				    | T.EXTERNAL _
				      => ExVarID.Map.insert (globalEnv, ai, IE.GSIMPLE (boundExp,displayName))
				 )
			 val (mvdeclList,sizeMVDeclList) = 
			     case varId of
				 T.INTERNAL _ => (nil,0)
			       | T.EXTERNAL _ => ([mvdecl],sizeMVDecl)
		     in {
			 globalEnv=globalEnv,
			 localEnv=localEnv,
			 intRenameEnv=intRenameEnv,
			 mvdeclList=mvdeclList,
			 size=sizeMVDeclList
			 }
		     end
		   | MV.MVFNM _
		     => 
		     let val localEnv = 
			     case varId of
				 T.INTERNAL id
				 =>
				 if sizeBoundExp <= !Control.inlineThreshold
				 then
				     ID.Map.insert (localEnv,id,IE.FN (boundExp,displayName))
				 else
				     localEnv
			       | T.EXTERNAL _
				 => localEnv
			 val globalEnv =
			     case varId of
				 T.INTERNAL _ => globalEnv
			       | T.EXTERNAL ai
				 => 
				 if sizeBoundExp <= !Control.inlineThreshold then
				     if hasFreeVar boundExp then globalEnv
				     else ExVarID.Map.insert 
					      (
					       globalEnv,
					       ai,
					       IE.GFN (boundExp,displayName)
					      )
				 else globalEnv
		     in 
			 {
			  globalEnv=globalEnv,
			  localEnv=localEnv,
			  intRenameEnv=intRenameEnv,
			  mvdeclList=[mvdecl],
			  size=sizeMVDecl
			 }
		     end
		   | MV.MVPOLY {btvEnv, expTyWithoutTAbs, exp=mvfnm as MV.MVFNM _,loc}
		     =>
		     let val localEnv =
			     case varId of
				 T.INTERNAL id
				 =>
				 if sizeBoundExp <= !Control.inlineThreshold
				 then
				     ID.Map.insert (localEnv,id,IE.PFN (btvEnv,mvfnm,sizeBoundExp,displayName))
				 else
				     localEnv
			       | T.EXTERNAL _
				 => localEnv
			 val globalEnv = 
			     case varId of
				 T.INTERNAL _ => globalEnv
			       | T.EXTERNAL ai
				 =>
				 if sizeBoundExp <= !Control.inlineThreshold then
				     if hasFreeVar boundExp then globalEnv
				     else ExVarID.Map.insert 
					      (
					       globalEnv,
					       ai,
					       IE.GPFN (btvEnv,mvfnm,sizeBoundExp,displayName)
					      )
				 else globalEnv
		     in
			 {
			  globalEnv=globalEnv,
			  localEnv=localEnv,
			  intRenameEnv=intRenameEnv,
			  mvdeclList=[mvdecl],
			  size=sizeMVDecl
			 }
		     end
		   | _
		     => 
		     {
		      globalEnv=globalEnv,
		      localEnv=localEnv,
		      intRenameEnv=intRenameEnv,
		      mvdeclList=[mvdecl],
		      size=sizeMVDecl
		     }
		)
	      | _ => (* more than one bound variables (multiple binding), always internal *)
		(case boundExp of (* boundExp is already inlined *)
		     MV.MVMVALUES {expList, tyList, loc}
		     => 
		     let val localEnv = 
                             addSimples
				 {
				  varList=newBoundVars,
				  mvexpList=expList,
				  localEnv=localEnv
				 }
		     in 
			 {
			  globalEnv=globalEnv,
			  localEnv=localEnv,
			  intRenameEnv=intRenameEnv,
			  mvdeclList=nil, (* since this case is internal. *)
			  size=0
			 }
		     end
		   | _
		     =>
		     {
		      globalEnv=globalEnv,
		      localEnv=localEnv,
		      intRenameEnv=intRenameEnv,
		      mvdeclList=[mvdecl],
		      size=sizeMVDecl
		     }
		)
	end
      | MV.MVVALREC {recbindList, loc}
	=> 
	let 
	    val intRenameEnv = 
		let val oldVarIdList = map (fn {boundVar,...} => #varId boundVar) recbindList
		in foldr
		       (fn (oldVarId,intRenameEnv) =>
			   case oldVarId of
			       T.INTERNAL oldId =>
			       ID.Map.insert (intRenameEnv, oldId, Counters.newLocalID())
			     | T.EXTERNAL _ =>
			       intRenameEnv)
		       intRenameEnv
		       oldVarIdList
		end
	    fun inlineBindList {globalEnv,localEnv,intRenameEnv,tyEnv,bindList=nil} = (nil, 0)
	      | inlineBindList 
		    {
		     globalEnv,
		     localEnv,
		     intRenameEnv,
		     tyEnv,
		     bindList={boundVar=boundVar:MV.varInfo,
			       boundExp} :: binds
		    } =
		let 
		    val newBoundVar = 
			case #varId boundVar of
			    T.INTERNAL id =>
			    (case ID.Map.find (intRenameEnv,id) of
				 SOME id => IU.changeID id boundVar
			       | NONE => raise Control.Bug "inliner bug")
			  | T.EXTERNAL _ => boundVar
		    val newBoundVar = IU.changeTY (IU.substitute tyEnv (#ty boundVar)) newBoundVar
		    val {mvexp,size=sizeBE,...} =
			inlineExp {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
				   tyEnv=tyEnv,mvexp=boundExp}
		    val newBind = {boundVar = newBoundVar, boundExp = mvexp}
		    val (newBinds, sizeList) = 
			inlineBindList {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
					tyEnv=tyEnv,bindList=binds}
		    val size = sizeBE + sizeList
		in
		    (newBind::newBinds, size)
		end
	    val (recbindList, size) = inlineBindList 
					  {
					   globalEnv=globalEnv,
					   localEnv=localEnv,
					   intRenameEnv=intRenameEnv,
					   
					   tyEnv=tyEnv,
					   bindList=recbindList
					  }
	    val mvdecl = MV.MVVALREC {recbindList=recbindList,loc=loc}
	in
	    {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
	     mvdeclList=[mvdecl], size=size+1}
	end
      | MV.MVVALPOLYREC {btvEnv, recbindList, loc}
	=> 
	let 
	    val intRenameEnv = 
		let val oldVarIdList = map (fn {boundVar,...} => #varId boundVar) recbindList
		in foldr
		       (fn (oldVarId,intRenameEnv) =>
			   case oldVarId of
			       T.INTERNAL oldId =>
			       ID.Map.insert (intRenameEnv, oldId, Counters.newLocalID())
			     | T.EXTERNAL _ =>
			       intRenameEnv)
		       intRenameEnv
		       oldVarIdList
		end
	    val (btvEnv,tyEnv) = 
		let 
		    val (subst,freshBtvEnv) = IU.copyBtvEnv btvEnv
		in (
		    case tyEnv of
			NONE => freshBtvEnv
		      | SOME tyEnv => IU.substituteBtvEnv tyEnv freshBtvEnv,
		    IEnv.foldri (fn (oldId,btv,tyEnv) => IU.insertTyEnv (tyEnv,oldId,btv))
				tyEnv subst
		    )
		end
	    fun inlineBindList {globalEnv,localEnv,intRenameEnv,tyEnv,bindList=nil} = (nil, 0)
	      | inlineBindList 
		    {
		     globalEnv,
		     localEnv,
		     intRenameEnv,
		     tyEnv,
		     bindList={boundVar=boundVar:MV.varInfo,
			       boundExp} :: binds
		    } =
		let 
		    val newBoundVar = 
			case #varId boundVar of
			    T.INTERNAL id =>
			    (case ID.Map.find (intRenameEnv,id) of
				 SOME id => IU.changeID id boundVar
			       | NONE => raise Control.Bug "inliner bug")
			  | T.EXTERNAL _ => boundVar
		    val newBoundVar = IU.changeTY (IU.substitute tyEnv (#ty boundVar)) newBoundVar
		    val {mvexp,size=sizeBE,...} =
			inlineExp {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
				   tyEnv=tyEnv,mvexp=boundExp}
		    val newBind = {boundVar = newBoundVar, boundExp = mvexp}
		    val (newBinds, sizeList) = 
			inlineBindList {globalEnv=globalEnv,localEnv=localEnv,intRenameEnv=intRenameEnv,
					tyEnv=tyEnv,bindList=binds}
		    val size = sizeBE + sizeList
		in
		    (newBind::newBinds, size)
		end
	    val (recbindList, size) = inlineBindList 
					  {
					   globalEnv=globalEnv,
					   localEnv=localEnv,
					   intRenameEnv=intRenameEnv,
					   tyEnv=tyEnv,
					   bindList=recbindList
					  }
	    val mvdecl = MV.MVVALPOLYREC {btvEnv=btvEnv,recbindList=recbindList,loc=loc}
	in
	    {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, 
	     mvdeclList=[mvdecl], size=size+1}
	end
	

and inlineDeclList {globalEnv,localEnv,intRenameEnv,tyEnv, mvdeclList=nil} = 
    {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, mvdeclList=nil, size=0}
  | inlineDeclList {globalEnv,localEnv,intRenameEnv,tyEnv,
		    mvdeclList=mvdecl::mvdeclList} =
    let val {globalEnv,localEnv,intRenameEnv,mvdeclList=mvdeclList1,size=sizeDecl} = 
	    inlineDecl 
		{
		 globalEnv=globalEnv,
		 localEnv=localEnv,
		 intRenameEnv=intRenameEnv,
		 tyEnv=tyEnv,
		 mvdecl=mvdecl
		}
	val {globalEnv,localEnv,intRenameEnv,mvdeclList=mvdeclList2,size=sizeDeclList} = 
	    inlineDeclList 
		{
		 globalEnv=globalEnv,
		 localEnv=localEnv,
		 intRenameEnv=intRenameEnv,
		 tyEnv=tyEnv,
		 mvdeclList=mvdeclList
		}
	val size = sizeDecl + sizeDeclList
    in {
	globalEnv=globalEnv, 
	localEnv=localEnv, 
	intRenameEnv=intRenameEnv,
	mvdeclList=mvdeclList1 @ mvdeclList2,
	size=size
	}
    end

 fun inlineBasicBlock {globalEnv, localEnv, intRenameEnv, tyEnv, basicBlock} =
     case basicBlock of
         MV.MVVALBLOCK {code, exnIDSet} =>
         let
	     val {globalEnv,localEnv,intRenameEnv,mvdeclList=newCode,size} = 
	         inlineDeclList {globalEnv=globalEnv,
		                 localEnv=localEnv,
		                 intRenameEnv=intRenameEnv,
		                 tyEnv=tyEnv,
		                 mvdeclList=code
		                }
         in
             {globalEnv = globalEnv, 
              localEnv = localEnv,
              intRenameEnv = intRenameEnv, 
              basicBlock = MV.MVVALBLOCK {code = newCode, exnIDSet = exnIDSet}, 
              size = size} 
         end
       | MV.MVLINKFUNCTORBLOCK x => 
	 {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, basicBlock = basicBlock, size=0}

fun inlineTopBlock {globalEnv, localEnv, intRenameEnv, tyEnv, topBlock} =
    case topBlock of
        MV.MVBASICBLOCK basicBlock =>
        let
            val {globalEnv,localEnv,intRenameEnv, basicBlock, size} = 
	        inlineBasicBlock
                    {globalEnv = globalEnv, 
                     localEnv = localEnv, 
                     intRenameEnv = intRenameEnv, 
                     tyEnv = tyEnv, 
                     basicBlock = basicBlock}
        in
	    {globalEnv=globalEnv, 
             localEnv=localEnv, 
             intRenameEnv=intRenameEnv, 
	     topBlock = MV.MVBASICBLOCK basicBlock,
             size=0}
        end
      | MV.MVFUNCTORBLOCK x =>
        (* Since MVFUNCTOR & MVLINKFUNCTOR appears only in toplevel, this size infomation is not used.
         * So I simply let it 0 (any value is ok). 
	 *)
	{globalEnv=globalEnv, 
         localEnv=localEnv, 
         intRenameEnv=intRenameEnv, 
	 topBlock=topBlock, 
         size=0}

fun inlineTopBlockList {globalEnv,localEnv,intRenameEnv,tyEnv, topBlockList=nil} = 
    {globalEnv=globalEnv, localEnv=localEnv, intRenameEnv=intRenameEnv, topBlockList=nil, size=0}
  | inlineTopBlockList {globalEnv,localEnv,intRenameEnv,tyEnv, topBlockList = topBlock:: topBlockList} =
    let 
        val {globalEnv, localEnv,intRenameEnv, topBlock,size=size1} = 
	    inlineTopBlock {globalEnv=globalEnv,
		         localEnv=localEnv,
		         intRenameEnv=intRenameEnv,
		         tyEnv=tyEnv,
		         topBlock=topBlock}
	val {globalEnv,localEnv,intRenameEnv, topBlockList = topBlockList,size=size2} = 
	    inlineTopBlockList {globalEnv=globalEnv,
		             localEnv=localEnv,
		             intRenameEnv=intRenameEnv,
		             tyEnv=tyEnv,
		             topBlockList=topBlockList}
	val size = size1 + size2
    in {
	globalEnv=globalEnv, 
	localEnv=localEnv, 
	intRenameEnv=intRenameEnv,
	topBlockList= topBlock :: topBlockList,
	size=size
	}
    end

fun doInlining (IE.GIE globalEnv) topBlockList = 
    let 
	val {globalEnv,topBlockList,...} = 
            inlineTopBlockList
		{
		 globalEnv=globalEnv,
		 localEnv=ID.Map.empty,
		 intRenameEnv=ID.Map.empty,
		 tyEnv=NONE,
		 topBlockList=topBlockList
		}
    in 
	(IE.GIE globalEnv, topBlockList)
    end
    handle exn => raise exn

end
end
