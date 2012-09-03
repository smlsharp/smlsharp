(**
 * pickler for typedlambda 
 * @author Liu Bochao
 * @version $Id: TypedLambdaPickler.sml,v 1.10 2007/02/28 15:31:26 katsu Exp $
 *)
structure TypedLambdaPickler =
struct

  (***************************************************************************)

  structure P = Pickle
  structure T = Types
  structure TL = TypedLambda
  (***************************************************************************)
  
  val loc = NamePickler.loc
  val ty = TypesPickler.ty
  val tyCon = TypesPickler.tyCon
  val id = TypesPickler.id
  val varIdInfo = TypesPickler.varIdInfo
  val valIdent = TypesPickler.valIdent
  val primInfo = TypesPickler.primInfo
  val btvKind = TypesPickler.btvKind
  val btvEnv = TypesPickler.btvEnv
  val constant = ConstantTermPickler.constant
  val callingConvention = AbsynPickler.callingConvention

  val (tlexpFunctions, tlexp) = P.makeNullPu (TL.TLGETGLOBAL ("", T.ATOMty, Loc.noloc))
  val (tldeclFunctions, tldecl) = P.makeNullPu (TL.TLEMPTY Loc.noloc)

  local
    val newTlexp : TL.tlexp P.pu =
        let
          fun toInt (TL.TLAPPM _) = 0
            | toInt (TL.TLARRAY _) = 1
            | toInt (TL.TLCONSTANT _) = 2
            | toInt (TL.TLCAST _) = 3
            | toInt (TL.TLEXCEPTIONTAG _) = 4
            | toInt (TL.TLFOREIGNAPPLY _) = 5
            | toInt (TL.TLFNM _) = 6
            | toInt (TL.TLGETFIELD _) = 7
            | toInt (TL.TLGETGLOBAL _) = 8
            | toInt (TL.TLGETGLOBALVALUE _) = 9
            | toInt (TL.TLHANDLE _) = 10
            | toInt (TL.TLINITARRAY _) = 11
            | toInt (TL.TLLET _) = 12
            | toInt (TL.TLMODIFY _) = 13
            | toInt (TL.TLMONOLET _) = 14
            | toInt (TL.TLOFFSET _) = 15
            | toInt (TL.TLPRIMAPPLY _) = 16
            | toInt (TL.TLRECORD _) = 17
            | toInt (TL.TLRAISE _) = 18
            | toInt (TL.TLPOLY _) = 19
            | toInt (TL.TLSELECT _) = 20
            | toInt (TL.TLSETGLOBALVALUE _) = 21
            | toInt (TL.TLSEQ _) = 22
            | toInt (TL.TLSETFIELD _) = 23
            | toInt (TL.TLSWITCH _) = 24
            | toInt (TL.TLTAPP _) = 25
            | toInt (TL.TLVAR _) = 26
            | toInt (TL.TLEXPORTCALLBACK _) = 27
            | toInt (TL.TLSIZEOF _) = 28

          fun pu_TLAPPM pu = 
              let
                val funExp_funTy_argExpList_loc =
                    P.tuple4
                      (tlexp, ty, P.list tlexp, loc)
              in
                P.con1 
                  TL.TLAPPM 
                  (fn TL.TLAPPM arg => arg)
                  (P.conv
                     (fn (funExp, funTy, argExpList, loc) => 
                         {funExp = funExp, funTy = funTy, argExpList = argExpList, loc = loc},
                         fn {funExp = funExp, funTy = funTy, argExpList = argExpList, loc = loc} =>
                            (funExp, funTy, argExpList, loc))
                     funExp_funTy_argExpList_loc)
              end

          fun pu_TLARRAY pu =
              let
                val sizeExp_initialValue_elementTy_resultTy_loc =
                    P.tuple5(tlexp, tlexp, ty, ty, loc)
              in
                P.con1
                  TL.TLARRAY
                  (fn TL.TLARRAY arg => arg)
                  (P.conv
                     ((fn (sizeExp, initialValue, elementTy, resultTy, loc) =>
                          {sizeExp = sizeExp, 
                           initialValue = initialValue,
                           elementTy = elementTy,
                           resultTy = resultTy,
                           loc = loc}),
                      (fn {sizeExp, initialValue, elementTy, resultTy, loc} => 
                          (sizeExp, initialValue, elementTy, resultTy, loc)))
                     sizeExp_initialValue_elementTy_resultTy_loc)
              end

          fun pu_TLCONSTANT pu =
              P.con1
                TL.TLCONSTANT
                (fn TL.TLCONSTANT arg => arg)
                (P.conv
                 ((fn (value,loc) => {value = value, loc = loc}),
                  (fn {value, loc} => (value,loc)))
                 (P.tuple2(constant,loc)))

          fun pu_TLEXCEPTIONTAG pu =
              P.con1
                  TL.TLEXCEPTIONTAG
                  (fn TL.TLEXCEPTIONTAG arg => arg)
                  (P.conv
                   ((fn (tagValue, loc) => {tagValue = tagValue, loc = loc},
                     (fn {tagValue, loc} => (tagValue,loc))))
                   (P.tuple2(P.int,loc)))
                                           
          fun pu_TLCAST pu =
              P.con1
                TL.TLCAST
                (fn TL.TLCAST arg => arg)
                (P.conv
                   ((fn (exp, targetTy, loc) =>
                        {exp = exp,
                         targetTy = targetTy,
                         loc = loc}),
                    (fn {exp, targetTy, loc} => (exp, targetTy, loc)))
                   (P.tuple3(tlexp, ty, loc)))

          fun pu_TLFOREIGNAPPLY pu =
              let
                val funExp_funTy_instTyList_argExpList_argTyList_convention_loc =
                    P.tuple7(tlexp, ty, P.list ty, P.list tlexp, P.list ty, callingConvention, loc)
              in
                P.con1 
                  TL.TLFOREIGNAPPLY
                  (fn TL.TLFOREIGNAPPLY arg => arg)
                  (P.conv
                     ((fn (funExp, funTy, instTyList, argExpList, argTyList, convention, loc) =>
                          {funExp = funExp, 
                           funTy = funTy,
                           instTyList = instTyList,
                           argExpList = argExpList, 
                           argTyList = argTyList,
                           convention = convention,
                           loc = loc}),
                      (fn {funExp, funTy, instTyList, argExpList, argTyList, convention, loc} =>
                          (funExp, funTy, instTyList, argExpList, argTyList, convention, loc)))
                     funExp_funTy_instTyList_argExpList_argTyList_convention_loc)
              end

          fun pu_TLEXPORTCALLBACK pu =
              let
                val funExp_instTyList_argTyList_resultTy_loc =
                    P.tuple5(tlexp, P.list ty, P.list ty, ty, loc)
              in
                P.con1 
                  TL.TLEXPORTCALLBACK
                  (fn TL.TLEXPORTCALLBACK arg => arg)
                  (P.conv
                     ((fn (funExp, instTyList, argTyList, resultTy, loc) =>
                          {funExp = funExp, 
                           instTyList = instTyList,
                           argTyList = argTyList,
                           resultTy = resultTy,
                           loc = loc}),
                      (fn {funExp, instTyList, argTyList, resultTy, loc} =>
                          (funExp, instTyList, argTyList, resultTy, loc)))
                     funExp_instTyList_argTyList_resultTy_loc)
              end

          fun pu_TLSIZEOF pu = 
              let
                val ty_loc =
                    P.tuple2(ty, loc)
              in
                P.con1
                  TL.TLSIZEOF
                  (fn TL.TLSIZEOF arg => arg)
                  (P.conv
                     ((fn (ty, loc) => {ty = ty, loc = loc}),
                      (fn {ty, loc} => (ty, loc)))
                     ty_loc)
              end

          fun pu_TLFNM pu =
              let
                val argVarList_bodyTy_bodyExp_loc = 
                    P.tuple4(P.list varIdInfo, ty, tlexp, loc)
              in
                P.con1 
                  TL.TLFNM
                  (fn TL.TLFNM arg => arg)
                  (P.conv
                     ((fn (argVarList, bodyTy, bodyExp, loc) =>
                          {argVarList = argVarList, 
                           bodyTy = bodyTy, 
                           bodyExp = bodyExp,
                           loc = loc}),
                      (fn {argVarList, bodyTy, bodyExp, loc} =>
                          (argVarList, bodyTy, bodyExp, loc)))
                     argVarList_bodyTy_bodyExp_loc)
              end

          fun pu_TLGETFIELD pu =
              let
                val arrayExp_indexExp_elementTy_loc =
                    P.tuple4(tlexp,tlexp,ty,loc)
              in
                P.con1
                  TL.TLGETFIELD
                  (fn TL.TLGETFIELD arg => arg)
                  (P.conv
                     ((fn (arrayExp,  indexExp, elementTy, loc) =>
                          {arrayExp = arrayExp, 
                           indexExp = indexExp, 
                           elementTy = elementTy, 
                           loc = loc}),
                      (fn {arrayExp, indexExp, elementTy, loc} =>
                          (arrayExp,  indexExp, elementTy, loc)))
                     arrayExp_indexExp_elementTy_loc)
              end

          fun pu_TLGETGLOBAL pu = 
              P.con1
                TL.TLGETGLOBAL
                (fn TL.TLGETGLOBAL arg => arg)
                (P.tuple3 (P.string, ty, loc))

          fun pu_TLGETGLOBALVALUE pu =
              let
                val arrayIndex_offset_ty_loc = 
                    P.tuple4(P.word32, P.int, ty, loc)
              in
                P.con1
                  TL.TLGETGLOBALVALUE
                  (fn TL.TLGETGLOBALVALUE arg => arg)
                  (P.conv
                     ((fn (arrayIndex, offset, ty, loc) =>
                          {arrayIndex = arrayIndex, 
                           offset = offset, 
                           ty = ty, 
                           loc = loc}),
                      (fn {arrayIndex, offset, ty, loc} =>
                          (arrayIndex, offset, ty, loc)))
                     arrayIndex_offset_ty_loc)
              end
                
          fun pu_TLHANDLE pu =
              P.con1
                TL.TLHANDLE
                (fn TL.TLHANDLE arg => arg)
                (P.conv 
                   ((fn (exp, exnVar, handler, loc) =>
                        {exp = exp, 
                         exnVar = exnVar, 
                         handler = handler,
                         loc = loc}),
                    (fn {exp, exnVar, handler, loc} =>
                        (exp, exnVar, handler, loc))
                    )
                   (P.tuple4(tlexp, varIdInfo, tlexp, loc)))

          fun pu_TLINITARRAY pu =
              let
                val arrayIndex_size_elemeTy_loc = 
                    P.tuple4(P.word32, P.int, ty, loc)
              in
                P.con1
                  TL.TLINITARRAY
                  (fn TL.TLINITARRAY arg => arg)
                  (P.conv
                     ((fn (arrayIndex, size, elemTy, loc) =>
                          {arrayIndex = arrayIndex,
                           size = size, 
                           elemTy = elemTy, 
                           loc = loc}),
                      (fn {arrayIndex, size, elemTy, loc} =>
                          (arrayIndex, size, elemTy, loc)))
                     arrayIndex_size_elemeTy_loc)
              end

          fun pu_TLLET pu =
              let
                val localDeclList_mainExpList_mainExpTyList_loc =
                    P.tuple4(P.list tldecl, P.list tlexp, P.list ty, loc)
              in
                P.con1
                  TL.TLLET
                  (fn TL.TLLET arg => arg)
                  (P.conv
                     ((fn (localDeclList, mainExpList, mainExpTyList, loc) =>
                          {localDeclList = localDeclList,
                           mainExpList = mainExpList,
                           mainExpTyList = mainExpTyList, 
                           loc = loc}),
                      (fn {localDeclList, mainExpList, mainExpTyList, loc} =>
                          (localDeclList, mainExpList, mainExpTyList, loc)))
                     localDeclList_mainExpList_mainExpTyList_loc)
              end

          fun pu_TLMODIFY pu =
              let
                val recordExp_recordTy_indexExp_elementExp_elementTy_loc =
                    P.tuple6(tlexp, ty, tlexp, tlexp, ty , loc)
              in
                P.con1
                  TL.TLMODIFY
                  (fn TL.TLMODIFY arg => arg)
                  (P.conv
                     ((fn (recordExp, recordTy, indexExp, elementExp,elementTy, loc) =>
                          {recordExp = recordExp,
                           recordTy = recordTy,
                           indexExp = indexExp,
                           elementExp = elementExp,
                           elementTy = elementTy,
                           loc = loc}),
                      (fn {recordExp, recordTy, indexExp, elementExp, elementTy, loc} =>
                          (recordExp, recordTy, indexExp, elementExp, elementTy, loc)))
                     recordExp_recordTy_indexExp_elementExp_elementTy_loc)
              end

          fun pu_TLMONOLET pu = 
              let
                val binds_bodyExp_loc = 
                    P.tuple3(P.list (P.tuple2(varIdInfo, tlexp)), tlexp, loc)
              in
                P.con1 
                  TL.TLMONOLET
                  (fn TL.TLMONOLET arg => arg)
                  (P.conv
                     ((fn (binds, bodyExp, loc) =>
                          {binds = binds,
                           bodyExp =  bodyExp,
                           loc = loc}),
                      (fn {binds, bodyExp, loc} =>
                          (binds, bodyExp, loc)))
                     binds_bodyExp_loc)
              end

          fun pu_TLOFFSET pu =
              P.con1
              TL.TLOFFSET
              (fn TL.TLOFFSET arg => arg)
              (P.conv
               ((fn (recordTy, label, loc) =>
                    {recordTy = recordTy,
                     label = label, 
                     loc = loc}),
                (fn {recordTy, label, loc} =>
                    (recordTy, label, loc)))
               (P.tuple3(ty, P.string, loc)))

          fun pu_TLPRIMAPPLY pu =
              let
                val primOp_instTyList_argExpList_loc = 
                    P.tuple4(primInfo, P.list ty, P.list tlexp, loc)
              in
                P.con1
                  TL.TLPRIMAPPLY
                  (fn TL.TLPRIMAPPLY arg => arg)
                  (P.conv
                     ((fn (primOp, instTyList, argExpList, loc) =>
                          {primOp = primOp, 
                           instTyList = instTyList,
                           argExpList = argExpList,
                           loc = loc}),
                      (fn {primOp, instTyList, argExpList, loc} =>
                          (primOp, instTyList, argExpList, loc)))
                     primOp_instTyList_argExpList_loc)
              end
                
          fun pu_TLRECORD pu = 
              let
                val expList_internalTy_externalTy_loc = 
                    P.tuple4(P.list tlexp, ty, P.option ty, loc)
              in
                P.con1
                  TL.TLRECORD
                  (fn TL.TLRECORD arg => arg)
                  (P.conv
                     ((fn (expList, internalTy, externalTy, loc) =>
                          {expList = expList, 
                           internalTy = internalTy, 
                           externalTy = externalTy, 
                           loc = loc}),
                      (fn {expList, internalTy, externalTy, loc} =>
                          (expList, internalTy, externalTy, loc)))
                     expList_internalTy_externalTy_loc)
              end
                
          fun pu_TLRAISE pu = 
              P.con1
                TL.TLRAISE
                (fn TL.TLRAISE arg => arg)
                (P.conv
                 ((fn (argExp, resultTy, loc) =>
                      {argExp = argExp, resultTy = resultTy , loc = loc}),
                  (fn {argExp, resultTy , loc} =>
                      (argExp, resultTy, loc)))
                 (P.tuple3(tlexp, ty, loc)))
               
          fun pu_TLPOLY pu =
              P.con1
                TL.TLPOLY
                (fn TL.TLPOLY arg => arg)
                (P.conv
                 ((fn (btvEnv, expTyWithoutTAbs, exp, loc) =>
                      {btvEnv = btvEnv, 
                       expTyWithoutTAbs = expTyWithoutTAbs,
                       exp = exp, 
                       loc = loc}),
                  (fn {btvEnv, expTyWithoutTAbs, exp, loc} =>
                      (btvEnv, expTyWithoutTAbs, exp, loc)))
                 (P.tuple4(btvEnv, ty, tlexp, loc)))
                
          fun pu_TLSELECT pu =
              P.con1
                TL.TLSELECT
                (fn TL.TLSELECT arg => arg)
                (P.conv
                 ((fn (recordExp, indexExp, recordTy, loc) =>
                      {recordExp = recordExp, 
                       indexExp = indexExp, 
                       recordTy = recordTy,
                       loc = loc}),
                  (fn {recordExp, indexExp, recordTy, loc} =>
                      (recordExp, indexExp, recordTy, loc)))
                 (P.tuple4(tlexp,tlexp, ty, loc)))

          fun pu_TLSETGLOBALVALUE pu =
              P.con1
                TL.TLSETGLOBALVALUE
                (fn TL.TLSETGLOBALVALUE arg => arg)
                (P.conv
                 ((fn (arrayIndex, offset, valueExp, ty, loc) =>
                      {arrayIndex = arrayIndex, 
                       offset = offset,
                       valueExp = valueExp,
                       ty = ty,
                       loc =  loc}),
                  (fn {arrayIndex, offset, valueExp, ty, loc} =>
                      (arrayIndex, offset, valueExp, ty, loc)))
                 (P.tuple5(P.word32, P.int, tlexp, ty, loc)))

          fun pu_TLSEQ pu =
              P.con1
                TL.TLSEQ
                (fn TL.TLSEQ arg => arg)
                (P.conv
                 ((fn (expList, expTyList, loc) =>
                      {expList = expList, expTyList = expTyList, loc = loc}),
                  (fn {expList, expTyList, loc} =>
                      (expList, expTyList, loc)))
                 (P.tuple3(P.list tlexp, P.list ty, loc)))

          fun pu_TLSETFIELD pu =
              P.con1
                TL.TLSETFIELD
                (fn TL.TLSETFIELD arg => arg)
                (P.conv
                 ((fn (valueExp, arrayExp, indexExp, elementTy, loc) =>
                      {valueExp = valueExp, 
                       arrayExp = arrayExp, 
                       indexExp = indexExp, 
                       elementTy = elementTy, 
                       loc = loc}),
                  (fn {valueExp, arrayExp, indexExp, elementTy, loc} =>
                      (valueExp, arrayExp, indexExp, elementTy, loc)))
                 (P.tuple5(tlexp, tlexp, tlexp, ty, loc)))

          fun pu_TLSWITCH pu =
              let
                  val branch =
                      P.conv
                      ((fn (constant,exp) => {constant = constant,exp = exp}),
                       (fn {constant, exp} => (constant, exp)))
                      (P.tuple2(tlexp, tlexp))
                val switchExp_expTy_branches_defaultExp_loc = 
                    P.tuple5(tlexp, ty, P.list branch, tlexp, loc)
              in
                P.con1
                  TL.TLSWITCH 
                  (fn TL.TLSWITCH arg => arg)
                  (P.conv
                     ((fn (switchExp, expTy, branches, defaultExp, loc) =>
                          {switchExp = switchExp, 
                           expTy = expTy,
                           branches = branches,
                           defaultExp = defaultExp,
                           loc = loc}),
                      (fn {switchExp, expTy, branches, defaultExp, loc} =>
                          (switchExp, expTy, branches, defaultExp, loc)))
                     switchExp_expTy_branches_defaultExp_loc)
              end
                
          fun pu_TLTAPP pu =
              P.con1
                TL.TLTAPP
                (fn TL.TLTAPP arg => arg)
                (P.conv
                 ((fn (exp, expTy, instTyList, loc) =>
                      {exp = exp , expTy = expTy, instTyList = instTyList, loc = loc}),
                  (fn {exp, expTy, instTyList, loc} =>
                      (exp, expTy, instTyList, loc)))
                 (P.tuple4(tlexp, ty, P.list ty, loc)))

          fun pu_TLVAR pu = 
              P.con1
                TL.TLVAR
                (fn TL.TLVAR arg => arg)
                (P.conv
                   ((fn (varInfo, loc) => {varInfo = varInfo, loc = loc}),
                    (fn {varInfo, loc} => (varInfo, loc)))
                   (P.tuple2(varIdInfo,loc)))
        in
          P.data
            (
             toInt,
             [ (* CAUTION: if 'pu_XXXty' is the n-th element of this list,
                * 'toInt XXXty' must return n. *)
              pu_TLAPPM (* 0 *),
              pu_TLARRAY (* 1 *),
              pu_TLCONSTANT (* 2 *),
              pu_TLCAST (* 3 *),
              pu_TLEXCEPTIONTAG (* 4 *),
              pu_TLFOREIGNAPPLY (* 5 *),
              pu_TLFNM (* 6 *),
              pu_TLGETFIELD (* 7 *),
              pu_TLGETGLOBAL (* 8 *),
              pu_TLGETGLOBALVALUE (* 9 *),
              pu_TLHANDLE (* 10 *),
              pu_TLINITARRAY (* 11 *),
              pu_TLLET (* 12 *),
              pu_TLMODIFY (* 13 *),
              pu_TLMONOLET (* 14 *),
              pu_TLOFFSET (* 15 *),
              pu_TLPRIMAPPLY (* 16 *),
              pu_TLRECORD (* 17 *),
              pu_TLRAISE (* 18 *),
              pu_TLPOLY (* 19 *),
              pu_TLSELECT (* 20 *),
              pu_TLSETGLOBALVALUE (* 21 *),
              pu_TLSEQ (* 22 *),
              pu_TLSETFIELD (* 23 *),
              pu_TLSWITCH (* 24 *),
              pu_TLTAPP (* 25 *),
              pu_TLVAR (* 26 *),
              pu_TLEXPORTCALLBACK (* 27 *),
              pu_TLSIZEOF (* 28 *)
              ]
             )
        end
    val newTldecl : TL.tldecl P.pu =
        let
          fun toInt (TL.TLVAL _) = 0
            | toInt (TL.TLVALREC _) = 1
            | toInt (TL.TLVALPOLYREC _) = 2
            | toInt (TL.TLLOCALDEC _) = 3
            | toInt (TL.TLSETGLOBAL _) = 4
            | toInt (TL.TLEMPTY _) = 5

          fun pu_TLVAL pu =
              P.con1
                TL.TLVAL
                (fn TL.TLVAL arg => arg)
                (P.conv
                   ((fn (binds, loc) =>
                        let
                          val bindList = 
                              map (fn (boundValIdent,boundExp) =>
                                      {boundValIdent = boundValIdent,  boundExp =  boundExp})
                                  binds
                        in
                          {bindList = bindList, loc = loc}
                        end),
                    (fn {bindList, loc} =>
                        let
                          val binds = 
                              map (fn {boundValIdent,  boundExp} =>
                                      (boundValIdent,boundExp))
                                  bindList
                        in
                          (binds, loc)
                        end))
                   (P.tuple2 (P.list(P.tuple2(valIdent, tlexp)), loc)))

          fun pu_TLVALREC pu =
              P.con1
                TL.TLVALREC
                (fn TL.TLVALREC arg => arg)
                (P.conv
                   ((fn (recbinds, loc) =>
                        let
                          val recbindList = 
                              map (fn (boundVar, boundTy, boundExp) =>
                                      {boundVar = boundVar,
                                       boundTy = boundTy,
                                       boundExp = boundExp})
                                  recbinds
                        in
                          {recbindList = recbindList, loc = loc}
                        end),
                    (fn {recbindList, loc} =>
                        let
                          val recbinds = 
                              map (fn {boundVar, boundTy, boundExp} =>
                                      (boundVar, boundTy, boundExp))
                                  recbindList
                        in
                          (recbinds, loc)
                        end))
                   (P.tuple2 (P.list(P.tuple3(varIdInfo, ty, tlexp)), loc)))

          fun pu_TLVALPOLYREC pu =
              P.con1
                TL.TLVALPOLYREC
                (fn TL.TLVALPOLYREC arg => arg)
                (P.conv
                   ((fn (btvEnv, indexVars, recbinds, loc) =>
                        let
                          val recbindList = 
                              map (fn (boundVar, boundTy, boundExp) =>
                                      {boundVar = boundVar,
                                       boundTy = boundTy,
                                       boundExp = boundExp})
                                  recbinds
                        in
                          {btvEnv = btvEnv, 
                           indexVars = indexVars, 
                           recbindList = recbindList, 
                           loc = loc}
                        end),
                    (fn {btvEnv, indexVars, recbindList, loc} =>
                        let
                          val recbinds = 
                              map (fn {boundVar, boundTy, boundExp} =>
                                      (boundVar, boundTy, boundExp))
                                  recbindList
                        in
                          (btvEnv, indexVars, recbinds, loc)
                        end))
                   (P.tuple4 (btvEnv, 
                              P.list varIdInfo, 
                              P.list(P.tuple3(varIdInfo, ty, tlexp)), 
                              loc)))

          fun pu_TLLOCALDEC pu =
              P.con1
                TL.TLLOCALDEC
                (fn TL.TLLOCALDEC arg => arg)
                (P.conv
                 ((fn (localDeclList, mainDeclList, loc) =>
                      {localDeclList = localDeclList,
                       mainDeclList = mainDeclList,
                       loc = loc}),
                  (fn {localDeclList, mainDeclList, loc} =>
                      (localDeclList, mainDeclList, loc)))
                 (P.tuple3(P.list tldecl, P.list tldecl, loc)))

          fun pu_TLSETGLOBAL pu =
              P.con1
                TL.TLSETGLOBAL
                (fn TL.TLSETGLOBAL arg => arg)
                (P.tuple3(P.string, tlexp, loc))

          fun pu_TLEMPTY pu =
              P.con1 TL.TLEMPTY (fn TL.TLEMPTY arg => arg) loc
        in
          P.data
            (
             toInt,
             [ (* CAUTION: if 'pu_XXXty' is the n-th element of this list,
                * 'toInt XXXty' must return n. *)
              pu_TLVAL, (* 0 *)
              pu_TLVALREC, (* 1 *)
              pu_TLVALPOLYREC, (* 2 *)
              pu_TLLOCALDEC, (* 3 *)
              pu_TLSETGLOBAL, (* 4 *)
              pu_TLEMPTY (* 5 *)
              ]
             )

        end
  in
    val _ = P.updateNullPu tlexpFunctions newTlexp 
    val _ = P.updateNullPu tldeclFunctions newTldecl 
  end
end
