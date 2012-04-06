(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MultipleValueCalcUtils.sml,v 1.21 2008/02/23 15:49:54 bochao Exp $
 *)
structure MultipleValueCalcUtils : MULTIPLEVALUECALCUTILS = struct
local
(*
  structure ATU = AnnotatedTypesUtils
  structure T = Types
  structure AT = AnnotatedTypes
*)
in
  open MultipleValueCalc

  fun getLocOfExp exp =
      case exp of
        MVFOREIGNAPPLY {loc,...} => loc
      | MVEXPORTCALLBACK {loc,...} => loc
      | MVTAGOF {loc,...} => loc
      | MVSIZEOF {loc,...} => loc
      | MVINDEXOF {loc,...} => loc
      | MVCONSTANT {loc,...} => loc
      | MVGLOBALSYMBOL {loc,...} => loc
      | MVVAR {loc,...} => loc
      | MVEXVAR {loc,...} => loc
(*
      | MVGETFIELD {loc,...} => loc
      | MVSETFIELD {loc,...} => loc
      | MVSETTAIL {loc,...} => loc
      | MVARRAY {loc,...} => loc
      | MVCOPYARRAY {loc,...} => loc
*)
      | MVPRIMAPPLY {loc,...} => loc
      | MVAPPM {loc,...} => loc
      | MVLET {loc,...} => loc
      | MVMVALUES {loc,...} => loc
      | MVRECORD {loc,...} => loc
      | MVSELECT {loc,...} => loc
      | MVMODIFY {loc,...} => loc
      | MVRAISE {loc,...} => loc
      | MVHANDLE {loc,...} => loc
      | MVFNM {loc,...} => loc
      | MVPOLY {loc,...} => loc
      | MVTAPP {loc,...} => loc
      | MVSWITCH {loc,...} => loc
      | MVCAST {loc,...} => loc

(*
  fun substVarInfo subst {displayName,ty,varId} =
      let val ty = ATU.substitute subst ty
      in 
	  {displayName=displayName, ty=ty, varId=varId}
      end

   fun substExp subst mvexp = 
      case mvexp of
        MVFOREIGNAPPLY {funExp,funTy,argExpList,attributes,loc}
        =>
        let
          val funExp = substExp subst funExp
          val funTy = ATU.substitute subst funTy
          val argExpList = map (substExp subst) argExpList
        in
          MVFOREIGNAPPLY 
          {funExp=funExp,funTy=funTy,argExpList=argExpList,attributes=attributes,loc=loc}
        end
     | MVEXPORTCALLBACK {funExp, funTy, attributes, loc}
        =>
        let
          val funExp = substExp subst funExp
          val funTy = ATU.substitute subst funTy
        in
          MVEXPORTCALLBACK {funExp=funExp,funTy=funTy,attributes=attributes,loc=loc}
        end
     | MVTAGOF {ty, loc}
        =>
        let 
          val ty = ATU.substitute subst ty
        in
          MVTAGOF {ty=ty, loc=loc}
        end
     | MVSIZEOF {ty, loc}
        =>
        let 
          val ty = ATU.substitute subst ty
        in
          MVSIZEOF {ty=ty, loc=loc}
        end
     | MVINDEXOF {label, recordTy, loc}
        =>
        let 
          val recordTy = ATU.substitute subst recordTy
        in
          MVINDEXOF {label=label, recordTy=recordTy, loc=loc}
        end
     | MVCONSTANT _
        => mvexp
     | MVGLOBALSYMBOL _
        => mvexp
     | MVEXCEPTIONTAG _
        => mvexp
     | MVVAR {varInfo, loc}
        =>
        let 
          val varInfo = substVarInfo subst varInfo
        in
          MVVAR {varInfo=varInfo, loc=loc}
        end
     | MVGETFIELD {arrayExp, indexExp, elementTy, loc}
        =>
        let 
          val arrayExp = substExp subst arrayExp
          val indexExp = substExp subst indexExp
          val elementTy = ATU.substitute subst elementTy
        in
          MVGETFIELD 
          {arrayExp=arrayExp,indexExp=indexExp,elementTy=elementTy,loc=loc}
        end
     | MVSETFIELD {valueExp,arrayExp,indexExp,elementTy,loc}
        => 
        let 
          val valueExp = substExp subst valueExp
          val arrayExp = substExp subst arrayExp
          val indexExp = substExp subst indexExp
          val elementTy = ATU.substitute subst elementTy
        in
          MVSETFIELD 
          {
           valueExp=valueExp,
           arrayExp=arrayExp,
           indexExp=indexExp,
           elementTy=elementTy,
           loc=loc
           }
        end
     | MVSETTAIL {consExp,newTailExp,tailLabel,listTy,consRecordTy,loc}
        =>
        let 
          val consExp = substExp subst consExp
          val newTailExp = substExp subst newTailExp
          val listTy = ATU.substitute subst listTy
          val consRecordTy = ATU.substitute subst consRecordTy
        in
          MVSETTAIL
          {
           consExp=consExp,
           newTailExp=newTailExp,
           tailLabel=tailLabel,
           listTy=listTy,
           consRecordTy=consRecordTy,
           loc=loc
           }
        end
     | MVARRAY {sizeExp,initialValue,elementTy,isMutable,loc}
        =>
        let 
          val sizeExp = substExp subst sizeExp
          val initialValue = substExp subst initialValue
          val elementTy = ATU.substitute subst elementTy
        in
          MVARRAY 
          {sizeExp=sizeExp,initialValue=initialValue,elementTy=elementTy,isMutable=isMutable,loc=loc}
        end
     | MVCOPYARRAY {srcExp,srcIndexExp,dstExp,dstIndexExp,lengthExp,elementTy,loc}
        =>
        let
          val srcExp = substExp subst srcExp
          val srcIndexExp = substExp subst srcIndexExp
          val dstExp = substExp subst dstExp
          val dstIndexExp = substExp subst dstIndexExp
          val lengthExp = substExp subst lengthExp
          val elementTy = ATU.substitute subst elementTy
        in 
          MVCOPYARRAY 
          {srcExp=srcExp,
           srcIndexExp=srcIndexExp,
           dstExp=dstExp,
           dstIndexExp=dstIndexExp,
           lengthExp=lengthExp,
           elementTy=elementTy,
           loc=loc}
        end	      
     | MVPRIMAPPLY {primInfo={name,ty},argExpList,instTyList,loc}
        =>
        let 
          val ty = ATU.substitute subst ty
          val primInfo = {name=name,ty=ty}
          val argExpList = map (substExp subst) argExpList
          val instTyList = map (ATU.substitute subst) instTyList
        in
          MVPRIMAPPLY 
          {primInfo=primInfo,argExpList=argExpList,instTyList=instTyList,loc=loc}
        end
     | MVAPPM {funExp,funTy,argExpList,loc}
        =>
        let 
          val funExp = substExp subst funExp
          val funTy = ATU.substitute subst funTy
          val argExpList = map (substExp subst) argExpList
        in
          MVAPPM
          {funExp=funExp,funTy=funTy,argExpList=argExpList,loc=loc}
        end
     | MVLET {localDeclList,mainExp,loc} 
        =>
        let 
          val localDeclList = map (substDecl subst) localDeclList
          val mainExp = substExp subst mainExp
        in
          MVLET
          {localDeclList=localDeclList,mainExp=mainExp,loc=loc}
        end
     | MVMVALUES {expList,tyList,loc}
        =>
        let 
          val expList = map (substExp subst) expList
          val tyList = map (ATU.substitute subst) tyList
        in
          MVMVALUES 
          {expList=expList,tyList=tyList,loc=loc}
        end
     | MVRECORD {expList,recordTy,annotation,isMutable,loc}
        =>
        let 
          val expList = map (substExp subst) expList
          val recordTy = ATU.substitute subst recordTy
        in
          MVRECORD
          {
           expList=expList,
           recordTy=recordTy,
           annotation=annotation,
           isMutable=isMutable,
           loc=loc
           }
        end
     | MVSELECT {recordExp,indexExp,label,recordTy,resultTy,loc}
        =>
        let 
          val recordExp = substExp subst recordExp
          val indexExp = substExp subst indexExp
          val recordTy = ATU.substitute subst recordTy
          val resultTy = ATU.substitute subst resultTy
        in
          MVSELECT
          {recordExp=recordExp,indexExp=indexExp,label=label,recordTy=recordTy,resultTy=resultTy,loc=loc}
        end
     | MVMODIFY {recordExp,recordTy,indexExp,label,valueExp,valueTy,loc}
        =>
        let 
          val recordExp = substExp subst recordExp
          val recordTy = ATU.substitute subst recordTy
          val indexExp = substExp subst indexExp
          val valueExp = substExp subst valueExp
          val valueTy = ATU.substitute subst valueTy
        in
          MVMODIFY 
          {
           recordExp=recordExp,
           recordTy=recordTy,
           indexExp=indexExp,
           label=label,
           valueExp=valueExp,
           valueTy=valueTy,
           loc=loc
           }
        end
     | MVRAISE {argExp,resultTy,loc}
        =>
        let 
          val argExp = substExp subst argExp
          val resultTy = ATU.substitute subst resultTy
        in
          MVRAISE
          {argExp=argExp,resultTy=resultTy,loc=loc}
        end
      
     | MVHANDLE {exp,exnVar,handler,loc}
        =>
        let 
          val exp = substExp subst exp
          val exnVar = substVarInfo subst exnVar
          val handler = substExp subst handler
        in
          MVHANDLE
          {exp=exp,exnVar=exnVar,handler=handler,loc=loc}
        end
     | MVFNM {argVarList,funTy,bodyExp,annotation, loc}
        =>
        let
          val argVarList = map (substVarInfo subst) argVarList
          val funTy = ATU.substitute subst funTy
          val bodyExp = substExp subst bodyExp
        in
          MVFNM
          {
           argVarList=argVarList,
           funTy=funTy,
           bodyExp=bodyExp,
           annotation=annotation,
           loc=loc
           }
        end
     | MVPOLY {btvEnv,expTyWithoutTAbs,exp,loc}
        =>
        let 
          val btvEnv = ATU.substituteBtvEnv subst btvEnv
          val subst = BoundTypeVarID.Map.foldri (fn (key,_,subst) => 
                                   (#1 (BoundTypeVarID.Map.remove (subst,key)) handle _ => subst))
            subst btvEnv
          val expTyWithoutTAbs = ATU.substitute subst expTyWithoutTAbs
          val exp = substExp subst exp
        in
          MVPOLY
          {
           btvEnv=btvEnv,
           expTyWithoutTAbs=expTyWithoutTAbs,
           exp=exp,
           loc=loc
           }
        end
     | MVTAPP {exp,expTy,instTyList,loc}
        =>
        let 
          val exp = substExp subst exp
          val expTy = ATU.substitute subst expTy
          val instTyList = map (ATU.substitute subst) instTyList
        in
          MVTAPP
          {exp=exp,expTy=expTy,instTyList=instTyList,loc=loc}
        end
     | MVSWITCH {switchExp,expTy,branches,defaultExp,loc}
        =>
        let 
          val switchExp = substExp subst switchExp
          val expTy = ATU.substitute subst expTy
          val branches = map (fn {constant,exp} =>
                              {constant=substExp subst constant,
                               exp=substExp subst exp})
            branches
          val defaultExp = substExp subst defaultExp
        in
          MVSWITCH 
          {
           switchExp=switchExp,
           expTy=expTy,
           branches=branches,
           defaultExp=defaultExp,
           loc=loc
           }
        end
     | MVCAST {exp,expTy,targetTy,loc}
        => 
        let 
          val exp = substExp subst exp
          val expTy = ATU.substitute subst expTy
          val targetTy = ATU.substitute subst targetTy
        in
          MVCAST 
          {exp=exp,expTy=expTy,targetTy=targetTy,loc=loc}
        end

  and substDecl subst decl =
    case decl of
      MVVAL {boundVars, boundExp, loc} 
      => 
      let
        val boundVars = map (substVarInfo subst) boundVars
        val boundExp = substExp subst boundExp
      in
        MVVAL {boundVars=boundVars, boundExp=boundExp, loc=loc} 
      end
    | MVVALREC {recbindList, loc}
      =>
      let
        val recbindList = map (fn {boundVar, boundExp} => 
                               {boundVar = substVarInfo subst boundVar,
                                boundExp = substExp subst boundExp})
          recbindList
      in
        MVVALREC {recbindList=recbindList, loc=loc}
      end
*)
end
end
