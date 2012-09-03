(**
 * @copyright (c) 2007, Tohoku University.
 * @author Isao Sasano
 * refactored by Atsushi Ohori
 * @version $Id: MultipleValueCalcPickler.sml,v 1.18 2008/03/18 06:20:50 bochao Exp $
 *)

structure MultipleValueCalcPickler =
struct
local
  structure P = Pickle
  structure T = Types
  structure MV = MultipleValueCalc
  structure CT = ConstantTerm
  structure CP = ConstantTermPickler
  structure AT = AnnotatedTypes
  structure AP = AnnotatedTypesPickler
  structure NP = NamePickler
  val dummyExp = MV.MVCONSTANT {value = CT.INT 0, loc = Loc.noloc}
  val dummyDecl = MV.MVVAL {boundVars = nil, boundExp = dummyExp, loc = Loc.noloc}
in

  val loc = NP.loc
  val ffiAttributes = AbsynPickler.ffiAttributes
  val ty = AP.ty
  val id = NP.id
  val varInfo = AP.varInfo
  val varInfoWithoutType = AP.varInfo
  val primInfo = AP.primInfo
  val annotationLabel = AP.annotationLabel
  val funStatus = AP.funStatus
  val btvEnv = AP.btvEnv
  val constant = CP.constant

  (* mvexp and mvdecl are defined mutual recursively. *)
  val (mvexpFunctions, mvexp) = P.makeNullPu dummyExp
  val (mvdeclFunctions, mvdecl) = P.makeNullPu dummyDecl

  local
    val newMVexp : MV.mvexp P.pu =
      let
        fun toInt (MV.MVFOREIGNAPPLY _) = 0
          | toInt (MV.MVEXPORTCALLBACK _) = 1
          | toInt (MV.MVSIZEOF _) = 2   
          | toInt (MV.MVCONSTANT _) = 3
          | toInt (MV.MVGLOBALSYMBOL _) = 4
          | toInt (MV.MVEXCEPTIONTAG _) = 5
          | toInt (MV.MVVAR _) = 6
          | toInt (MV.MVGETFIELD _) = 7
          | toInt (MV.MVSETFIELD _) = 8
          | toInt (MV.MVSETTAIL _) = 9
          | toInt (MV.MVARRAY _) = 10
          | toInt (MV.MVCOPYARRAY _) = 11
          | toInt (MV.MVPRIMAPPLY _) = 12
          | toInt (MV.MVAPPM _) = 13
          | toInt (MV.MVLET _) = 14
          | toInt (MV.MVMVALUES _) = 15
          | toInt (MV.MVRECORD _) = 16
          | toInt (MV.MVSELECT _) = 17
          | toInt (MV.MVMODIFY _) = 18
          | toInt (MV.MVRAISE _) = 19
          | toInt (MV.MVHANDLE _) = 20
          | toInt (MV.MVFNM _) = 21
          | toInt (MV.MVPOLY _) = 22
          | toInt (MV.MVTAPP _) = 23
          | toInt (MV.MVSWITCH _) = 24
          | toInt (MV.MVCAST _) = 25

        fun pu_MVFOREIGNAPPLY pu =
          P.con1
          MV.MVFOREIGNAPPLY
          (
           fn MV.MVFOREIGNAPPLY arg => arg
            | _ => raise Control.Bug "MVFOREIGNAPPLY expected : MultipleValueCalcPickler"
           )
          (
           P.conv
           ((fn (funExp, funTy, argExpList, attributes, loc) =>
             {funExp=funExp, funTy=funTy, argExpList=argExpList,
              attributes=attributes, loc=loc}),
            (fn {funExp, funTy, argExpList, attributes, loc} =>
             (funExp, funTy, argExpList, attributes, loc)))
           (P.tuple5 (mvexp, ty, P.list mvexp, ffiAttributes, loc))
          )

        fun pu_MVEXPORTCALLBACK pu =
          P.con1
          MV.MVEXPORTCALLBACK
          (
           fn MV.MVEXPORTCALLBACK arg => arg
            | _ => raise Control.Bug "MVEXPORTCALLBACK expected : MultipleValueCalcPickler"
          )
          (
           P.conv
            (fn (funExp, funTy, attributes, loc) => {funExp=funExp, funTy=funTy, attributes=attributes, loc=loc},
             fn {funExp, funTy, attributes, loc} => (funExp, funTy, attributes, loc))
           (P.tuple4 (mvexp, ty, ffiAttributes, loc))
          )

        fun pu_MVSIZEOF pu =
          P.con1
          MV.MVSIZEOF
          (
           fn MV.MVSIZEOF arg => arg
            | _ => raise Control.Bug "MVSIZEOF expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (ty, loc) => {ty=ty, loc=loc},
            fn {ty, loc} => (ty, loc))
           (P.tuple2 (ty, loc))
           )

        fun pu_MVCONSTANT pu =
          P.con1
          MV.MVCONSTANT
          (
           fn MV.MVCONSTANT arg => arg
            | _ => raise Control.Bug "MVCONSTANT expected : MultipleValueCalcPickler"
           )
          (
           P.conv
           (fn (value, loc) => {value=value, loc=loc},
            fn {value, loc} => (value, loc))
           (P.tuple2 (constant, loc))
          )

        fun pu_MVEXCEPTIONTAG pu =
          P.con1
          MV.MVEXCEPTIONTAG
          (
           fn MV.MVEXCEPTIONTAG arg => arg
            | _ => raise Control.Bug "MVEXCEPTIONTAG expected : MultipleValueCalcPickler"
           )
          (
           P.conv
           (fn (tagValue, displayName, loc) => {tagValue=tagValue, displayName=displayName, loc=loc},
            fn {tagValue, displayName, loc} => (tagValue, displayName, loc))
           (P.tuple3 (ExnTagID.pu_ID, P.string, loc))
           )

        fun pu_MVVAR pu =
          P.con1
          MV.MVVAR
          (
           fn MV.MVVAR arg => arg
            | _ => raise Control.Bug "MVVAR expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (varInfo, loc) => {varInfo=varInfo, loc=loc},
            fn {varInfo, loc} => (varInfo, loc))
           (P.tuple2 (varInfo, loc))
          )

        fun pu_MVGETFIELD pu =
          P.con1
          MV.MVGETFIELD
          (
           fn MV.MVGETFIELD arg => arg
            | _ => raise Control.Bug "MVGETFIELD expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (arrayExp, indexExp, elementTy, loc) =>
            {arrayExp=arrayExp,
             indexExp=indexExp,
             elementTy=elementTy,
             loc=loc},
            fn {arrayExp, indexExp, elementTy, loc} =>
            (arrayExp, indexExp, elementTy, loc))
           (P.tuple4 (mvexp, mvexp, ty, loc))
           )

        fun pu_MVSETFIELD pu =
          P.con1
          MV.MVSETFIELD
          (
           fn MV.MVSETFIELD arg => arg
            | _ => raise Control.Bug "MVSETFIELD expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (valueExp, arrayExp, indexExp, elementTy, loc) =>
            {valueExp=valueExp,
             arrayExp=arrayExp,
             indexExp=indexExp,
             elementTy=elementTy,
             loc=loc},
            fn {valueExp, arrayExp, indexExp, elementTy, loc} =>
            (valueExp, arrayExp, indexExp, elementTy, loc))
           (P.tuple5 (mvexp, mvexp, mvexp, ty, loc))
           )

        fun pu_MVSETTAIL pu =
          P.con1 
          MV.MVSETTAIL
          (
           fn MV.MVSETTAIL arg => arg
            | _ => raise Control.Bug "MVSETTAIL expected : MultipleValueCalcPickler"
          )
          (P.conv
           (fn (consExp, newTailExp, tailLabel, listTy, consRecordTy, loc) =>
            {consExp=consExp,
             newTailExp=newTailExp,
             tailLabel=tailLabel,
             listTy=listTy,
             consRecordTy=consRecordTy,
             loc=loc},
            fn {consExp, newTailExp, tailLabel, listTy, consRecordTy, loc} =>
            (consExp, newTailExp, tailLabel, listTy, consRecordTy, loc))
           (P.tuple6 (mvexp, mvexp, P.string, ty, ty, loc)))

        fun pu_MVARRAY pu =
          P.con1
          MV.MVARRAY
          (
           fn MV.MVARRAY arg => arg
            | _ => raise Control.Bug "MVARRAY expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (sizeExp, initialValue, elementTy, isMutable, loc) =>
            {sizeExp=sizeExp,
             initialValue=initialValue,
             elementTy=elementTy,
             isMutable = isMutable,
             loc=loc},
            fn {sizeExp, initialValue, elementTy, isMutable, loc} =>
            (sizeExp, initialValue, elementTy, isMutable, loc))
           (P.tuple5 (mvexp, mvexp, ty, P.bool, loc))
           )

        fun pu_MVCOPYARRAY pu =
          P.con1
          MV.MVCOPYARRAY
          (
           fn MV.MVCOPYARRAY arg => arg
            | _ => raise Control.Bug "MVCOPYARRAY expected : MultipleValueCalcPickler"
          )
          (P.conv
           (fn (srcExp,srcIndexExp,dstExp,dstIndexExp,lengthExp,elementTy,loc) =>
            {srcExp=srcExp,
             srcIndexExp=srcIndexExp,
             dstExp=dstExp,
             dstIndexExp=dstIndexExp,
             lengthExp=lengthExp,
             elementTy=elementTy,
             loc=loc},
            fn {srcExp,srcIndexExp,dstExp,dstIndexExp,lengthExp,elementTy,loc} =>
            (srcExp,srcIndexExp,dstExp,dstIndexExp,lengthExp,elementTy,loc))
           (P.tuple7 (mvexp,mvexp,mvexp,mvexp,mvexp,ty,loc)))

        fun pu_MVPRIMAPPLY pu =
          P.con1
          MV.MVPRIMAPPLY
          (
           fn MV.MVPRIMAPPLY arg => arg
            | _ => raise Control.Bug "MVPRIMAPPLY expected : MultipleValueCalcPickler"
           )
          (P.conv
           (fn (primInfo, argExpList, instTyList, loc) =>
            {primInfo=primInfo,
             argExpList=argExpList,
             instTyList=instTyList,
             loc=loc},
            fn {primInfo, argExpList, instTyList, loc} =>
            (primInfo, argExpList, instTyList, loc))
           (P.tuple4 (primInfo, P.list mvexp, P.list ty, loc)))

        fun pu_MVAPPM pu =
          P.con1
          MV.MVAPPM
          (
           fn MV.MVAPPM arg => arg
            | _ => raise Control.Bug "MVAPPM expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (funExp, funTy, argExpList, loc) =>
            {funExp=funExp,
             funTy=funTy,
             argExpList=argExpList,
             loc=loc},
            fn {funExp, funTy, argExpList, loc} => 
            (funExp, funTy, argExpList, loc))
           (P.tuple4 (mvexp, ty, P.list mvexp, loc))
           )

        fun pu_MVLET pu =
          P.con1
          MV.MVLET
          (
           fn MV.MVLET arg => arg
            | _ => raise Control.Bug "MVLET expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (localDeclList, mainExp, loc) =>
            {localDeclList=localDeclList,
             mainExp=mainExp,
             loc=loc},
            fn {localDeclList, mainExp, loc} =>
            (localDeclList, mainExp, loc))
           (P.tuple3 (P.list mvdecl, mvexp, loc))
           )

        fun pu_MVMVALUES pu =
          P.con1
          MV.MVMVALUES
          (
           fn MV.MVMVALUES arg => arg
            | _ => raise Control.Bug "MVMVALUES expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (expList, tyList, loc) =>
            {expList=expList,
             tyList=tyList,
             loc=loc},
            fn {expList, tyList, loc} =>
            (expList, tyList, loc))
           (P.tuple3 (P.list mvexp, P.list ty, loc))
           )

        fun pu_MVRECORD pu =
          P.con1
          MV.MVRECORD
          (
           fn MV.MVRECORD arg => arg
            | _ => raise Control.Bug "MVRECORD expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (expList, recordTy, annotation, isMutable, loc) =>
            {expList=expList,
             recordTy=recordTy,
             annotation=annotation,
             isMutable=isMutable,
             loc=loc},
            fn {expList, recordTy, annotation, isMutable, loc} =>
            (expList, recordTy, annotation, isMutable, loc))
           (P.tuple5 (P.list mvexp, ty, annotationLabel, P.bool, loc))
           )

        fun pu_MVSELECT pu =
          P.con1 
          MV.MVSELECT
          (
           fn MV.MVSELECT arg => arg
            | _ => raise Control.Bug "MVSELECT expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (recordExp, label, recordTy, resultTy, loc) =>
            {recordExp=recordExp,
             label=label,
             recordTy=recordTy,
             resultTy=resultTy,
             loc=loc},
            fn {recordExp, label, recordTy, resultTy, loc} =>
            (recordExp, label, recordTy, resultTy, loc))
           (P.tuple5 (mvexp, P.string, ty, ty, loc))
           )

        fun pu_MVMODIFY pu =
          P.con1
          MV.MVMODIFY
          (
           fn MV.MVMODIFY arg => arg
            | _ => raise Control.Bug "MVMODIFY expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (recordExp, recordTy, label, valueExp, valueTy, loc) =>
            {recordExp=recordExp,
             recordTy=recordTy,
             label=label,
             valueExp=valueExp,
             valueTy=valueTy,
             loc=loc},
            fn {recordExp, recordTy, label, valueExp, valueTy, loc} =>
            (recordExp, recordTy, label, valueExp, valueTy, loc))
           (P.tuple6 (mvexp, ty, P.string, mvexp, ty, loc))
           )

        fun pu_MVRAISE pu =
          P.con1
          MV.MVRAISE
          (
           fn MV.MVRAISE arg => arg
            | _ => raise Control.Bug "MVRAISE expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (argExp, resultTy, loc) =>
            {argExp=argExp,
             resultTy=resultTy,
             loc=loc},
            fn {argExp, resultTy, loc} =>
            (argExp, resultTy, loc))
           (P.tuple3 (mvexp, ty, loc))
           )

        fun pu_MVHANDLE pu =
          P.con1
          MV.MVHANDLE
          (
           fn MV.MVHANDLE arg => arg
            | _ => raise Control.Bug "MVHANDLE expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (exp, exnVar, handler, loc) =>
            {exp=exp,
             exnVar=exnVar,
             handler=handler,
             loc=loc},
            fn {exp, exnVar, handler, loc} =>
            (exp, exnVar, handler, loc))
           (P.tuple4 (mvexp, varInfo, mvexp, loc))
          )

        fun pu_MVFNM pu =
          P.con1
          MV.MVFNM
          (
           fn MV.MVFNM arg => arg
            | _ => raise Control.Bug "MVFNM expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (argVarList, 
                funTy, 
                bodyExp, 
                annotation, 
                loc) =>
            {argVarList=argVarList,
             funTy=funTy,
             bodyExp=bodyExp,
             annotation=annotation,
             loc=loc},
            fn {argVarList, 
                funTy, 
                bodyExp, 
                annotation, 
                loc} =>
            (argVarList, 
             funTy, 
             bodyExp, 
             annotation, 
             loc))
           (P.tuple5
            (P.list varInfo, 
             ty, 
             mvexp, 
             annotationLabel,
             loc))
           )

        fun pu_MVPOLY pu =
          P.con1
          MV.MVPOLY
          (
           fn MV.MVPOLY arg => arg
            | _ => raise Control.Bug "MVPOLY expected : MultipleValueCalcPickler"
           )
          (
           P.conv
           (fn (btvEnv, expTyWithoutTAbs, exp, loc) =>
            {btvEnv=btvEnv,
             expTyWithoutTAbs=expTyWithoutTAbs,
             exp=exp,
             loc=loc},
            fn {btvEnv, expTyWithoutTAbs, exp, loc} =>
              (btvEnv, expTyWithoutTAbs, exp, loc))
           (P.tuple4 (btvEnv, ty, mvexp, loc))
           )

        fun pu_MVTAPP pu =
          P.con1
          MV.MVTAPP
          (
           fn MV.MVTAPP arg => arg
            | _ => raise Control.Bug "MVTAPP expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (exp, expTy, instTyList, loc) =>
            {exp=exp,
             expTy=expTy,
             instTyList=instTyList,
             loc=loc},
            fn {exp, expTy, instTyList, loc} =>
            (exp, expTy, instTyList, loc))
           (P.tuple4 (mvexp, ty, P.list ty, loc))
           )

        fun pu_MVSWITCH pu =
          P.con1
          MV.MVSWITCH
          (
           fn MV.MVSWITCH arg => arg
            | _ => raise Control.Bug "MVSWITCH expected : MultipleValueCalcPickler"
           )
          (
           P.conv
           (fn (switchExp, expTy, branches, defaultExp, loc) =>
             {switchExp=switchExp,
              expTy=expTy,
              branches=branches,
              defaultExp=defaultExp,
              loc=loc},
            fn {switchExp, expTy, branches, defaultExp, loc} =>
             (switchExp, expTy, branches, defaultExp, loc))
           (P.tuple5 (mvexp, 
                      ty, 
                      P.list 
                      (P.conv (fn (constant, exp) =>
                               {constant=constant, exp=exp},
                               fn {constant, exp} =>
                               (constant, exp))
                       (P.tuple2 (mvexp, mvexp))),
                      mvexp,
                      loc))
           )
        fun pu_MVCAST pu =
          P.con1 
          MV.MVCAST
          (
           fn MV.MVCAST arg => arg
            | _ => raise Control.Bug "MVCAST expected : MultipleValueCalcPickler"
          )
          (
           P.conv
           (fn (exp, expTy, targetTy, loc) =>
            {exp=exp,
             expTy=expTy,
             targetTy=targetTy,
             loc=loc},
            fn {exp, expTy, targetTy, loc} =>
            (exp, expTy, targetTy, loc))
           (P.tuple4 (mvexp, ty, ty, loc))
          )

      in
        P.data
        (
         toInt,
         [
          pu_MVFOREIGNAPPLY,
          pu_MVEXPORTCALLBACK,
          pu_MVSIZEOF,
          pu_MVCONSTANT,
          pu_MVEXCEPTIONTAG,
          pu_MVVAR,
          pu_MVGETFIELD,
          pu_MVSETFIELD,
          pu_MVSETTAIL,
          pu_MVARRAY,
          pu_MVCOPYARRAY,
          pu_MVPRIMAPPLY,
          pu_MVAPPM,
          pu_MVLET,
          pu_MVMVALUES,
          pu_MVRECORD,
          pu_MVSELECT,
          pu_MVMODIFY,
          pu_MVRAISE,
          pu_MVHANDLE,
          pu_MVFNM,
          pu_MVPOLY,
          pu_MVTAPP,
          pu_MVSWITCH,
          pu_MVCAST
          ]
         )
      end

    val newMVdecl =
      let
        fun toInt (MV.MVVAL _) = 0
          | toInt (MV.MVVALREC _) = 1
          | toInt (MV.MVVALPOLYREC _) = 2

        fun pu_MVVAL pu = 
          P.con1
          MV.MVVAL
          (
           fn MV.MVVAL arg => arg
            | _ => raise Control.Bug "MVVAL expected : MultipleValueCalcPickler"
          )
          (P.conv
           (fn (boundVars, boundExp, loc) => 
            {boundVars=boundVars,
             boundExp=boundExp,
             loc=loc},
            fn {boundVars, boundExp, loc} => 
            (boundVars, boundExp, loc))
           (P.tuple3 (P.list varInfo, mvexp, loc)))

        fun pu_MVVALREC pu =
          P.con1
          MV.MVVALREC
          (
           fn MV.MVVALREC arg => arg
            | _ => raise Control.Bug "MVVALREC expected : MultipleValueCalcPickler"
           )
          (
           P.conv
           (fn (recbindList, loc) =>
            {recbindList=recbindList, loc=loc},
            fn {recbindList, loc} =>
            (recbindList, loc))
           (P.tuple2 
            (P.list
             (P.conv
              (fn (boundVar, boundExp) =>
               {boundVar=boundVar, boundExp=boundExp},
               fn {boundVar, boundExp} =>
               (boundVar, boundExp))
              (P.tuple2 (varInfo, mvexp))),
             loc))
           )

        fun pu_MVVALPOLYREC pu =
          P.con1
          MV.MVVALPOLYREC
          (
           fn MV.MVVALPOLYREC arg => arg
            | _ => raise Control.Bug "MVVALPOLYREC expected : MultipleValueCalcPickler"
           )
          (
           P.conv
           (fn (btvEnv, recbindList, loc) =>
            {btvEnv=btvEnv, recbindList=recbindList, loc=loc},
            fn {btvEnv, recbindList, loc} =>
            (btvEnv, recbindList, loc))
           (P.tuple3 
            (btvEnv,
             P.list
             (P.conv
              (fn (boundVar, boundExp) =>
               {boundVar=boundVar, boundExp=boundExp},
               fn {boundVar, boundExp} =>
               (boundVar, boundExp))
              (P.tuple2 (varInfo, mvexp))),
             loc))
           )
(*
        fun pu_MVFUNCTOR pu =
          P.con1
          MV.MVFUNCTOR
          (
           fn MV.MVFUNCTOR arg => arg
            | _ => raise Control.Bug "MVFUNCTOR expected : MultipleValueCalcPickler"
           )
          (
           P.conv
               (fn (name, formalAbstractTypeIDSet, formalVarIDSet, formalExnIDSet, 
                    generativeExnIDSet, generativeVarIDSet,bodyCode) =>
                   {name = name, 
                    formalAbstractTypeIDSet = formalAbstractTypeIDSet,
                    formalVarIDSet = formalVarIDSet, 
                    formalExnIDSet = formalExnIDSet, 
                    generativeExnIDSet = generativeExnIDSet, 
                    generativeVarIDSet = generativeVarIDSet,
                    bodyCode = bodyCode},
                fn {name, formalAbstractTypeIDSet, formalVarIDSet, formalExnIDSet, 
                    generativeExnIDSet, generativeVarIDSet, bodyCode} =>
                   (name, formalAbstractTypeIDSet, formalVarIDSet, formalExnIDSet, 
                    generativeExnIDSet, generativeVarIDSet, bodyCode))
               (P.tuple7
                    (P.string, 
                     NamePickler.TyConIDSet, 
                     NamePickler.ExternalVarIDSet,
                     NamePickler.ExnTagIDSet,
                     NamePickler.ExnTagIDSet,
                     NamePickler.ExternalVarIDSet,
                     P.list mvdecl))
           )

        fun pu_MVLINKFUNCTOR pu =
          P.con1
          MV.MVLINKFUNCTOR
          (
           fn MV.MVLINKFUNCTOR arg => arg
            | _ => raise Control.Bug "MVLINKFUNCTOR expected : MultipleValueCalcPickler"
           )
          (
           P.conv
               (fn (name, actualArgName, typeResolutionTable, exnTagResolutionTable, 
                    externalVarIDResolutionTable, refreshedExceptionTagTable, refreshedExternalVarIDTable, 
                    loc) =>
                   {name = name, 
                    actualArgName = actualArgName, 
                    typeResolutionTable = typeResolutionTable, 
                    exnTagResolutionTable = exnTagResolutionTable, 
                    externalVarIDResolutionTable = externalVarIDResolutionTable, 
                    refreshedExceptionTagTable = refreshedExceptionTagTable, 
                    refreshedExternalVarIDTable = refreshedExternalVarIDTable, 
                    loc = loc},
                fn {name, actualArgName, typeResolutionTable, exnTagResolutionTable, 
                    externalVarIDResolutionTable, refreshedExceptionTagTable, refreshedExternalVarIDTable, 
                    loc} =>
                   (name, actualArgName, typeResolutionTable, exnTagResolutionTable, 
                    externalVarIDResolutionTable, refreshedExceptionTagTable, refreshedExternalVarIDTable, 
                    loc))
               (P.tuple8
                    (P.string, 
                     P.string, 
                     NamePickler.TyConIDMap AP.tyBindInfo,
                     NamePickler.ExnTagIDMap ExnTagID.pu_globalID,
                     NamePickler.ExternalVarIDMap ExternalVarID.pu_globalID,
                     NamePickler.ExnTagIDMap ExnTagID.pu_globalID,
                     NamePickler.ExternalVarIDMap ExternalVarID.pu_globalID,
                     loc
                     ))
           )
*)
      in
        P.data
        (toInt,
         [
          pu_MVVAL,
          pu_MVVALREC,
          pu_MVVALPOLYREC
          ]
         )
      end
  in
    val _ = P.updateNullPu mvexpFunctions newMVexp
    val _ = P.updateNullPu mvdeclFunctions newMVdecl
  end
end
end
