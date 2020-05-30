(**
 * Translation of datatypes to record types.
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure DatatypeCompilation =
struct

  structure TC = TypedCalc
  structure TL = TypedLambda
  structure BT = BuiltinTypes
  structure T = Types
  structure E = EmitTypedLambda
  datatype tagged_layout = datatype RuntimeTypes.tagged_layout
  datatype layout = datatype RuntimeTypes.layout

  val errors = UserError.createQueue ()

  fun mapi f l =
      let
        fun loop (i, nil) = nil
          | loop (i, h::t) = f (i, h) :: loop (i + 1, t)
      in
        loop (1, l)
      end

  fun newVar ty =
      {path = [Symbol.generate ()],
       ty = ty,
       id = VarID.generate ()} : TL.varInfo

  fun ConTag const =
      TL.CONTAG (Word32.fromInt const)

  fun exnConTy exnCon =
      case exnCon of
        TC.EXN {ty,...} => ty
      | TC.EXEXN {ty,...} => ty

  fun extractLayout ty =
      case TyRevealTy.revealTy ty of
        T.CONSTRUCTty
          {tyCon = {dtyKind = T.DTY {rep = RuntimeTypes.DATA layout, ...}, ...},
           ...} =>
        layout
      | _ => raise Bug.Bug "extractLayout"

  fun decomposeDataconTy ty =
      case TypesBasics.derefTy ty of
        T.FUNMty ([argTy], retTy) => (SOME argTy, retTy)
      | T.CONSTRUCTty _ => (NONE, ty)
      | _ => raise Bug.Bug "decomposeDataconTy"

  fun lookupConTag (taggedLayout, path) =
      let
        val tagMap =
            case taggedLayout of
              TAGGED_TAGONLY {tagMap} => tagMap
            | TAGGED_RECORD {tagMap} => tagMap
            | TAGGED_OR_NULL {tagMap, nullName} => tagMap
        fun find i k nil = NONE
          | find i k (h::t) = if k = h then SOME i else find (i+1) k t
      in
        case find 0 (Symbol.symbolToString (Symbol.lastSymbol path)) tagMap of
          NONE => raise Bug.Bug ("dataconTag " ^ Symbol.longsymbolToString path)
        | SOME tag => tag
      end

  fun extractConTag (taggedLayout, exp) =
      case taggedLayout of
        TAGGED_TAGONLY _ => E.Cast (exp, BT.contagTy)
      | TAGGED_RECORD _ => E.SelectN (1, E.Cast (exp, E.tupleTy [BT.contagTy]))
      | TAGGED_OR_NULL {tagMap, nullName} =>
        let
          val vid = EmitTypedLambda.newId ()
          val nullName = [Symbol.mkSymbol nullName Loc.noloc]
        in
          E.Let ([(vid, exp)],
                 E.If (E.IsNull (E.Cast (exp, BT.boxedTy)),
                       E.ConTag (lookupConTag (taggedLayout, nullName)),
                       E.SelectN (1, E.Cast (exp, E.tupleTy [BT.contagTy]))))
        end

  fun composeTaggedCon (taggedLayout, conInfo, argExpOpt, retTy) =
      let
        val tagExp = E.ConTag (lookupConTag (taggedLayout, #path conInfo))
      in
        case argExpOpt of
          NONE => E.Cast (E.Tuple [tagExp], retTy)
        | SOME argExp => E.Cast (E.Tuple [tagExp, argExp], retTy)
      end

  fun extractTaggedConArg (conInfo:Types.conInfo, dataExp) argTy =
      E.SelectN (2, E.Cast (dataExp, E.tupleTy [BT.contagTy, argTy]))

  fun composeCon (conInfo:Types.conInfo, instTyList, argExpOpt) =
      let
        val conInstTy =
            case instTyList of
              NONE => TypesBasics.derefTy (#ty conInfo)
            | SOME tys => TypesBasics.tpappTy (#ty conInfo, tys)
        val (argTy, retTy) = decomposeDataconTy conInstTy
        val argExpOpt =
            case (argExpOpt, argTy) of
              (NONE, NONE) => NONE
            | (SOME argExp, SOME argTy) => SOME (E.Exp (argExp, argTy))
            | _ => raise Bug.Bug "composeCon"
      in
        case extractLayout retTy of
          LAYOUT_TAGGED (layout as TAGGED_RECORD _) =>
          composeTaggedCon (layout, conInfo, argExpOpt, retTy)
        | LAYOUT_TAGGED (layout as TAGGED_TAGONLY _) =>
          (
            case argExpOpt of
              SOME _ => raise Bug.Bug "composeCon: TAGGED_TAGONLY"
            | NONE =>
              E.Cast (E.ConTag (lookupConTag (layout, #path conInfo)), retTy)
          )
        | LAYOUT_TAGGED (layout as TAGGED_OR_NULL _) =>
          (
            case argExpOpt of
              NONE => E.Cast (E.Null, retTy)
            | SOME _ => composeTaggedCon (layout, conInfo, argExpOpt, retTy)
          )
        | LAYOUT_CHOICE {falseName} =>
          (
            case argExpOpt of
              SOME _ => raise Bug.Bug "composeCon: LAYOUT_CHOICE"
            | NONE =>
              E.Cast (if Symbol.eqSymbol (Symbol.lastSymbol (#path conInfo),
                                          Symbol.mkSymbol falseName Loc.noloc)
                      then E.ConTag 0 else E.ConTag 1,
                      retTy)
          )
        | LAYOUT_SINGLE =>
          (
            case argExpOpt of
              SOME _ => raise Bug.Bug "composeCon: LAYOUT_SINGLE"
            | NONE => E.Cast (E.Unit, retTy)
          )
        | LAYOUT_SINGLE_ARG {wrap} =>
          (
            case argExpOpt of
              NONE => raise Bug.Bug "composeCon: LAYOUT_SINGLE_ARG"
            | SOME exp =>
              if wrap
              then E.Cast (E.Tuple [exp], retTy)
              else E.Cast (exp, retTy)
          )
        | LAYOUT_ARG_OR_NULL {wrap} =>
          (
            case argExpOpt of
              NONE => E.Cast (E.Null, retTy)
            | SOME exp =>
              if wrap
              then E.Cast (E.Tuple [exp], retTy)
              else E.Cast (exp, retTy)
          )
        | LAYOUT_REF =>
          (
            case (argExpOpt, argTy) of
              (SOME argExp, SOME argTy) => E.Ref_alloc (argTy, argExp)
            | _ => raise Bug.Bug "composeCon: LAYOUT_REF"
          )
      end

  fun makeBranch argFn (NONE, branchExp, resultTy) =
      E.Exp (branchExp, resultTy)
    | makeBranch argFn (SOME argVar, branchExp, resultTy) =
      E.TLLet ([E.Bind (argVar, argFn (#ty argVar))],
               E.Exp (branchExp, resultTy))

  fun switchCon (dataExp, dataTy, ruleList, defaultExp, resultTy) =
      let
        val dataExp = E.Exp (dataExp, dataTy)
      in
        case extractLayout dataTy of
          LAYOUT_TAGGED layout =>
          let
            val dataVid = EmitTypedLambda.newId ()
            val dataVarExp = E.Var dataVid
          in
            E.Let ([(dataVid, dataExp)],
                   E.Switch
                     (extractConTag (layout, dataVarExp),
                      map
                        (fn (conInfo as {path, ...}, argVarOpt, exp) =>
                            (ConTag (lookupConTag (layout, path)),
                             makeBranch
                               (extractTaggedConArg (conInfo, dataVarExp))
                               (argVarOpt, exp, resultTy)))
                        ruleList,
                      E.Exp (defaultExp, resultTy)))
          end
        | LAYOUT_CHOICE {falseName} =>
          let
            val falseName = Symbol.mkSymbol falseName Loc.noloc
            val (conInfo, ifTrueExp, ifFalseExp) =
                case ruleList of
                  [(con1, NONE, exp1), (con2, NONE, exp2)] =>
                  if Symbol.eqSymbol (Symbol.lastSymbol (#path con1), falseName)
                  then (con1, exp2, exp1)
                  else (con1, exp1, exp2)
                | [(con1, NONE, exp1)] =>
                  if Symbol.eqSymbol (Symbol.lastSymbol (#path con1), falseName)
                  then (con1, defaultExp, exp1)
                  else (con1, exp1, defaultExp)
                | _ => raise Bug.Bug "switchCon: LAYOUT_CHOICE"
          in
            E.If (dataExp,
                  E.Exp (ifTrueExp, resultTy),
                  E.Exp (ifFalseExp, resultTy))
          end
        | LAYOUT_SINGLE =>
          (
            case ruleList of
              [(_, _, branchExp)] => E.Exp (branchExp, resultTy)
            | _ => raise Bug.Bug "switchCon: LAYOUT_SINGLE"
          )
        | LAYOUT_SINGLE_ARG {wrap} =>
          (
            case ruleList of
              [(_, argVar as SOME _, branchExp)] =>
              makeBranch
                (fn argTy =>
                    if wrap 
                    then E.SelectN (1, E.Cast (dataExp, E.tupleTy [argTy]))
                    else E.Cast (dataExp, argTy))
                (argVar, branchExp, resultTy)
            | _ => raise Bug.Bug "switchCon: LAYOUT_SINGLE_ARG"
          )
        | LAYOUT_ARG_OR_NULL {wrap} =>
          let
            val (conInfo, argVar, ifDataExp, ifNullExp) =
                case ruleList of
                  [(_, NONE, exp1), (con, SOME v, exp2)] =>
                  (con, SOME v, exp2, exp1)
                | [(con, SOME v, exp1), (_, NONE, exp2)] =>
                  (con, SOME v, exp1, exp2)
                | [(con, SOME v, exp1)] =>
                  (con, SOME v, exp1, defaultExp)
                | [(con, NONE, exp1)] =>
                  (con, NONE, defaultExp, exp1)
                | _ => raise Bug.Bug "switchArgOrNull"
            val dataVid = EmitTypedLambda.newId ()
          in
            E.Let
              ([(dataVid, dataExp)],
               E.If
                 (E.IsNull (E.Cast (E.Var dataVid, BT.boxedTy)),
                  E.Exp (ifNullExp, resultTy),
                  makeBranch
                    (fn argTy =>
                        if wrap
                        then E.SelectN (1, E.Cast (dataExp, E.tupleTy [argTy]))
                        else E.Cast (dataExp, argTy))
                    (argVar, ifDataExp, resultTy)))
          end
        | LAYOUT_REF =>
          (
            case ruleList of
              [(_, SOME argVar, branchExp)] =>
              E.TLLet
                ([E.Bind (argVar,
                          E.Ref_deref (#ty argVar, dataExp))],
                 E.Exp (branchExp, resultTy))
            | _ => raise Bug.Bug "compileExp: TPCASE: LAYOUT_ARGONLY"
          )
      end

  type env =
      {
        exnMap: TL.varInfo ExnID.Map.map,
        exExnMap: TL.exVarInfo LongsymbolEnv.map
      }

  val emptyEnv =
      {exnMap = ExnID.Map.empty, exExnMap = LongsymbolEnv.empty} : env

  fun newLocalExn (env:env, {path, ty, id}:Types.exnInfo) =
      let
        val vid = VarID.generate ()
        val varInfo = {path = path, ty = BT.exntagTy, id = vid} : TL.varInfo
      in
        ({exnMap = ExnID.Map.insert (#exnMap env, id, varInfo),
          exExnMap = #exExnMap env} : env,
         varInfo)
      end

  fun addExternExn (env:env, {path, ty}:Types.exExnInfo) =
      let
        val exVarInfo = {path = path, ty = BT.exntagTy} : TL.exVarInfo
      in
        ({exnMap = #exnMap env,
          exExnMap = LongsymbolEnv.insert (#exExnMap env, path, exVarInfo)}
         : env,
         exVarInfo)
      end

  fun findLocalExnTag ({exnMap, ...}:env, {id, ...}:Types.exnInfo) =
      ExnID.Map.find (exnMap, id)

  fun findExternExnTag ({exExnMap, ...}:env, {path,...}:Types.exExnInfo) =
      LongsymbolEnv.find (exExnMap, path)

  fun findExnTag (env, exnCon) =
      case exnCon of
        TC.EXN e =>
        (case findLocalExnTag (env, e) of
           SOME v => SOME (E.TLVar v)
         | NONE => NONE
        )
      | TC.EXEXN e =>
        (case findExternExnTag (env, e) of
           SOME v => SOME (E.ExVar v)
         | NONE => NONE
        )

  fun composeExn env (exnCon, argExpOpt, loc) =
      let
        val (argTy, _) = decomposeDataconTy (exnConTy exnCon)
        val argOpt =
            case (argExpOpt, argTy) of
              (NONE, NONE) => NONE
            | (SOME argExp, SOME argTy) => SOME (E.Exp (argExp, argTy))
            | _ => raise Bug.Bug "composeExn"
        val tagExp =
            case findExnTag (env, exnCon) of
              SOME tagExp => tagExp
            | NONE => raise Bug.Bug "composeExn: tag not found"
      in
        EmitTypedLambda.composeExn (tagExp, loc, argOpt)
      end

  fun switchExn env (exnExp, expTy, ruleList, defaultExp, resultTy) =
      let
        (* exception match must be performed by linear search. *)
        val exnVid = EmitTypedLambda.newId ()
        val tagVid = EmitTypedLambda.newId ()
      in
        E.Let
          ([(exnVid, E.Exp (exnExp, expTy)),
            (tagVid, EmitTypedLambda.extractExnTag (E.Var exnVid))],
           foldr
             (fn ((exnCon, argVarOpt, branchExp), elseExp) =>
                 let
                   val tagExp = case findExnTag (env, exnCon) of
                                  SOME tagExp => tagExp
                                | NONE => raise Bug.Bug "switchExn"
                 in
                   E.If (E.IdentityEqual (BT.exntagTy, E.Var tagVid, tagExp),
                         case argVarOpt of
                           NONE => E.Exp (branchExp, resultTy)
                         | SOME argVar =>
                           E.TLLet
                             ([E.Bind
                                 (argVar,
                                  E.extractExnArg (E.Var exnVid, #ty argVar))],
                              E.Exp (branchExp, resultTy)),
                         elseExp)
                 end)
             (E.Exp (defaultExp, resultTy))
             ruleList)
      end

  fun fixConst (const, ty, loc) =
      ConstantTypes.fixConst (const, ty, loc)
      handle e as ConstantError.TooLargeConstant =>
             (UserError.enqueueError errors (loc, e);
              TL.TLCONSTANT (TL.UNIT, loc)) (*dummy*)

  fun compileVarInfo ({id, path, ty, ...}:Types.varInfo) : TypedLambda.varInfo =
      {id = id, path = path, ty = ty}

  fun compileExp (env:env) rcexp =
      case rcexp of
        TC.TPFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        TL.TLFOREIGNAPPLY
          {funExp = compileExp env funExp,
           argExpList = map (compileExp env) argExpList,
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | TC.TPCALLBACKFN {attributes, resultTy, argVarList, bodyExp, loc} =>
        TL.TLCALLBACKFN
          {attributes = attributes,
           resultTy = resultTy,
           argVarList = map compileVarInfo argVarList,
           bodyExp = compileExp env bodyExp,
           loc = loc}
      | TC.TPSIZEOF (ty, loc) =>
        TL.TLSIZEOF {ty = ty, loc = loc}
      | TC.TPREIFYTY (ty, loc) =>
        TL.TLREIFYTY {ty = ty, loc = loc}
      | TC.TPCONSTANT {const, loc, ty} =>
        fixConst (const, ty, loc)
      | TC.TPFOREIGNSYMBOL {name, ty, loc} =>
        TL.TLFOREIGNSYMBOL {name=name, ty=ty, loc=loc}
      | TC.TPVAR varInfo =>
        TL.TLVAR (compileVarInfo varInfo, Loc.noloc)
      | TC.TPRECFUNVAR {var, arity} =>
        TL.TLVAR (compileVarInfo var, Loc.noloc)
      | TC.TPEXVAR exVarInfo =>
        TL.TLEXVAR (exVarInfo, Loc.noloc)
      | TC.TPOPRIMAPPLY {oprimOp, instTyList, argExp, loc} =>
        TL.TLOPRIMAPPLY
          {oprimOp = oprimOp,
           instTyList = instTyList,
           argExp = compileExp env argExp,
           loc = loc}
      | TC.TPPRIMAPPLY {primOp, instTyList, argExp, loc} =>
        PrimitiveTypedLambda.compile
          {primOp = primOp,
           instTyList = instTyList,
           argExp = compileExp env argExp,
           loc = loc}
      | TC.TPDATACONSTRUCT {con, instTyList, argExpOpt, loc} =>
        let
          val argExpOpt = Option.map (compileExp env) argExpOpt
        in
          EmitTypedLambda.emit loc (composeCon (con, instTyList, argExpOpt))
        end
      | TC.TPEXNCONSTRUCT {exn, argExpOpt, loc} =>
        let
          val argExpOpt = Option.map (compileExp env) argExpOpt
        in
          EmitTypedLambda.emit loc (composeExn env (exn, argExpOpt, loc))
        end
      | TC.TPEXNTAG {exnInfo, loc} =>
        (
          case findLocalExnTag (env, exnInfo) of
            NONE => raise Bug.Bug "compileExp: TPEXNTAG"
          | SOME var => TL.TLVAR (var, loc)
        )
      | TC.TPEXEXNTAG {exExnInfo, loc} =>
        (
          case findExternExnTag (env, exExnInfo) of
            NONE => raise Bug.Bug "compileExp: TPEXEXNTAG"
          | SOME var => TL.TLEXVAR (var, loc)
        )
      | TC.TPAPPM {funExp, funTy, argExpList, loc} =>
        let
          val argExpList = map (compileExp env) argExpList
        in
          TL.TLAPPM {funExp = compileExp env funExp,
                     funTy = funTy,
                     argExpList = argExpList,
                     loc = loc}
        end
      | TC.TPLET {decls, body, loc} =>
        let
          val (env, decls) = compileDeclList env decls
          val mainExp = compileExp env body
        in
          foldr
            (fn (dec, mainExp) =>
                TL.TLLET {decl = dec, body = mainExp, loc = loc})
            mainExp
            decls
        end
      | TC.TPMONOLET {binds, bodyExp, loc} =>
        foldr
          (fn ((var, exp), body) =>
              TL.TLLET {decl = TL.TLVAL {var = compileVarInfo var,
                                         exp = compileExp env exp,
                                         loc = loc},
                        body = body,
                        loc = loc})
          (compileExp env bodyExp)
          binds
      | TC.TPRECORD {fields, recordTy, loc} =>
        if RecordLabel.Map.isEmpty fields
        then EmitTypedLambda.emit loc (E.Cast (E.Null, recordTy))
        else TL.TLRECORD
               {fields = RecordLabel.Map.map (compileExp env) fields,
                recordTy = recordTy,
                loc = loc}
      | TC.TPSELECT {label, exp, expTy, resultTy, loc} =>
        TL.TLSELECT
          {recordExp = compileExp env exp,
           label = label,
           recordTy = expTy,
           resultTy = resultTy,
           loc = loc}
      | TC.TPMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
        (
          case TypesBasics.derefTy recordTy of
            T.RECORDty fieldTys =>
            let
              val v = newVar recordTy
              val fields =
                  RecordLabel.Map.mapi
                    (fn (label, ty) =>
                        TL.TLSELECT
                          {recordExp = TL.TLVAR (v, loc),
                           label = label,
                           recordTy = recordTy,
                           resultTy = ty,
                           loc = loc})
                    fieldTys
              val elementExp = compileExp env elementExp
              val fields = RecordLabel.Map.insert (fields, label, elementExp)
            in
              TL.TLLET
                {decl = TL.TLVAL {var = v,
                                  exp = compileExp env recordExp,
                                  loc = loc},
                 body = TL.TLRECORD {fields = fields,
                                     recordTy = recordTy,
                                     loc = loc},
                 loc = loc}
            end
          | _ =>
            TL.TLMODIFY
              {label = label,
               recordExp = compileExp env recordExp,
               recordTy = recordTy,
               elementExp = compileExp env elementExp,
               elementTy = elementTy,
               loc = loc}
        )
      | TC.TPRAISE {exp, ty, loc} =>
        TL.TLRAISE
          {exp = compileExp env exp,
           resultTy = ty,
           loc = loc}
      | TC.TPHANDLE {exp, exnVar, handler, resultTy, loc} =>
        TL.TLHANDLE
          {exp = compileExp env exp,
           exnVar = compileVarInfo exnVar,
           handler = compileExp env handler,
           resultTy = resultTy,
           loc = loc}
      | TC.TPSWITCH {exp, expTy, ruleList = TC.CONCASE ruleList,
                     defaultExp, ruleBodyTy, loc} =>
        let
          val exp = compileExp env exp
          val ruleList =
              map (fn {con, instTyList, argVarOpt, body} =>
                      (con,
                       Option.map compileVarInfo argVarOpt,
                       compileExp env body))
                  ruleList
          val defaultExp = compileExp env defaultExp
        in
          EmitTypedLambda.emit
            loc
            (switchCon (exp, expTy, ruleList, defaultExp, ruleBodyTy))
        end
      | TC.TPSWITCH {exp, expTy, ruleList = TC.EXNCASE ruleList,
                     defaultExp, ruleBodyTy, loc} =>
        let
          val exp = compileExp env exp
          val ruleList =
              map (fn {exn, argVarOpt, body} =>
                      (exn,
                       Option.map compileVarInfo argVarOpt,
                       compileExp env body))
                  ruleList
          val defaultExp = compileExp env defaultExp
        in
          EmitTypedLambda.emit
            loc
            (switchExn env (exp, expTy, ruleList, defaultExp, ruleBodyTy))
        end
      | TC.TPSWITCH {exp, expTy, ruleList = TC.CONSTCASE ruleList,
                     defaultExp, ruleBodyTy, loc} =>
        let
          val switchExp = compileExp env exp
          datatype t = S of TypedLambda.tlstring | C of TypedLambda.tlconst
          val branches =
              map (fn {const, ty, body} =>
                      {constant =
                         case fixConst (const, ty, loc) of
                           TL.TLCONSTANT (const, _) => C const
                         | TL.TLSTRING (string, _) => S string
                         | _ => raise Bug.Bug "compileExp: TPSWITCH",
                       exp = compileExp env body})
                  ruleList
          val defaultExp = compileExp env defaultExp
        in
          case branches of
            {constant = S (TL.INTINF _), exp = _}::_ =>
            SwitchCompile.compileIntInfSwitch
              {switchExp = switchExp,
               expTy = expTy,
               branches =
                  map (fn {constant = S (TL.INTINF s), exp} =>
                          {constant = s, exp = exp}
                        | _ => raise Bug.Bug "compileExp: TPSWITCH: INTINF")
                      branches,
               defaultExp = defaultExp,
               resultTy = ruleBodyTy,
               loc = loc}
          | {constant = S (TL.STRING _), exp = _}::_ =>
            SwitchCompile.compileStringSwitch
              {switchExp = switchExp,
               expTy = expTy,
               branches =
                  map (fn {constant = S (TL.STRING s), exp} =>
                          {constant = s, exp = exp}
                        | _ => raise Bug.Bug "compileExp: TPSWITCH: STRING")
                      branches,
               defaultExp = defaultExp,
               resultTy = ruleBodyTy,
               loc = loc}
          | {constant = C _, exp = _}::_ =>
            TL.TLSWITCH
              {exp = switchExp,
               expTy = expTy,
               branches = 
                  map (fn {constant = C const, exp} =>
                          {const = const, body = exp}
                        | _ => raise Bug.Bug "compileExp: TPSWITCH: C")
                      branches,
               defaultExp = defaultExp,
               resultTy = ruleBodyTy,
               loc = loc}
          | nil =>
            TL.TLSWITCH
              {exp = switchExp,
               expTy = expTy,
               branches = nil,
               defaultExp = defaultExp,
               resultTy = ruleBodyTy,
               loc = loc}
        end
      | TC.TPCATCH {catchLabel, argVarList, catchExp, tryExp, resultTy, loc} =>
        TL.TLCATCH
          {catchLabel = catchLabel,
           argVarList = map compileVarInfo argVarList,
           catchExp = compileExp env catchExp,
           tryExp = compileExp env tryExp,
           resultTy = resultTy,
           loc = loc}
      | TC.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
        TL.TLTHROW
          {catchLabel = catchLabel,
           argExpList = map (compileExp env) argExpList,
           resultTy = resultTy,
           loc = loc}
      | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} =>
        TL.TLFNM
          {argVarList = map compileVarInfo argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp env bodyExp,
           loc = loc}
      | TC.TPPOLY {btvEnv, constraints, expTyWithoutTAbs, exp, loc} =>
        TL.TLPOLY
          {btvEnv = btvEnv,
           constraints = constraints,
           expTyWithoutTAbs = expTyWithoutTAbs,
           exp = compileExp env exp,
           loc = loc}
      | TC.TPTAPP {exp, expTy, instTyList, loc} =>
        TL.TLTAPP
          {exp = compileExp env exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | TC.TPCAST ((rcexp, expTy), ty, loc) =>
        TL.TLCAST {exp = compileExp env rcexp, expTy = expTy, targetTy = ty,
                   cast = BuiltinPrimitive.TypeCast, loc = loc}
      | TC.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
        TL.TLDYNAMICEXISTTAPP
          {existInstMap = compileExp env existInstMap,
           exp = compileExp env exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | TC.TPFFIIMPORT _ =>
        raise Bug.Bug "compileExp: TPFFIIMPORT"
      | TC.TPJOIN _ =>
        raise Bug.Bug "compileExp: TPJOIN"
      | TC.TPDYNAMIC _ =>
        raise Bug.Bug "compileExp: TPDYNAMIC"
      | TC.TPDYNAMICIS _ =>
        raise Bug.Bug "compileExp: TPDYNAMICIS"
      | TC.TPDYNAMICNULL _ =>
        raise Bug.Bug "compileExp: TPDYNAMICNULL"
      | TC.TPDYNAMICTOP _ =>
        raise Bug.Bug "compileExp: TPDYNAMICTOP"
      | TC.TPDYNAMICVIEW _ =>
        raise Bug.Bug "compileExp: TPDYNAMICVIEW"
      | TC.TPDYNAMICCASE _ =>
        raise Bug.Bug "compileExp: TPDYNAMICCASE"
      | TC.TPCASEM _ =>
        raise Bug.Bug "compileExp: TPCASEM"
      | TC.TPERROR =>
        raise Bug.Bug "compileExp: TPERROR"

  and compileDecl env rcdecl =
      case rcdecl of
        TC.TPVAL ((var, exp), loc) =>
        (env,
         [TL.TLVAL {var = compileVarInfo var,
                    exp = compileExp env exp,
                    loc = loc}])
      | TC.TPVALREC (bindList, loc) =>
        (env,
         [TL.TLVALREC
            (map (fn {var, exp} =>
                     {var = compileVarInfo var,
                      exp = compileExp env exp})
                 bindList,
             loc)])
      | TC.TPVALPOLYREC {btvEnv, constraints, recbinds, loc} =>
        (env,
         [TL.TLVALPOLYREC
            {btvEnv = btvEnv,
             constraints = constraints,
             recbinds = map (fn {var, exp} =>
                                {var = compileVarInfo var,
                                 exp = compileExp env exp})
                            recbinds,
             loc = loc}])
      | TC.TPEXPORTVAR {var, exp} =>
        (env, [TL.TLEXPORTVAR
                 {weak = false,
                  var = var,
                  exp = compileExp env exp}])
      | TC.TPEXTERNVAR (exVarInfo, provider) =>
        (env, [TL.TLEXTERNVAR (exVarInfo, provider)])
      | TC.TPEXD (exnInfo as {path, ty, ...}, loc) =>
        let
          val (env, tagVar) = newLocalExn (env, exnInfo)
          val tagExp = EmitTypedLambda.allocExnTag
                         {builtin=false, path=path, ty=ty}
        in
          (env,
           [TL.TLVAL
              {var = tagVar,
               exp = EmitTypedLambda.emit loc tagExp,
               loc = loc}])
        end
      | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val (env, tagVar) = newLocalExn (env, exnInfo)
        in
          (env,
           [TL.TLVAL {var = tagVar,
                      exp = TL.TLVAR (compileVarInfo varInfo, loc),
                      loc = loc}])
        end
      | TC.TPEXPORTEXN (exnInfo as {path, ...}) =>
        (
          case findLocalExnTag (env, exnInfo) of
            NONE => raise Bug.Bug "compileDecl: TPEXPORTEXN"
          | SOME (var as {id, ty,...}) =>
            (* ohori: bug 184. the external name is "path" in exnInfo,
               which must be kept. *)
            (env, [TL.TLEXPORTVAR
                     {weak = false,
                      var = {path=path, ty=ty},
                      exp = TL.TLVAR (var, Loc.noloc)}])
        )
      | TC.TPEXTERNEXN (exExnInfo, provider) =>
        let
          val (env, tagVar) = addExternExn (env, exExnInfo)
        in
          (env, [TL.TLEXTERNVAR (tagVar, provider)])
        end
      | TC.TPBUILTINEXN (exExnInfo as {path, ty}) =>
        let
          val tagExp = EmitTypedLambda.allocExnTag
                         {builtin=true, path=path, ty=ty}
          val (env, _) = addExternExn (env, exExnInfo)
        in
          (env,
           [TL.TLEXPORTVAR
              {weak = true,
               var = {path = path, ty = BT.exntagTy},
               exp = EmitTypedLambda.emit Loc.noloc tagExp}])
        end
      | TC.TPFUNDECL _ =>
        raise Bug.Bug "compileDecl: TPFUNDECL"
      | TC.TPPOLYFUNDECL _ =>
        raise Bug.Bug "compileDecl: TPPOLYFUNDECL"

  and compileDeclList env nil = (env, nil)
    | compileDeclList env (decl::decls) =
      let
        val (env, decls1) = compileDecl env decl
        val (env, decls2) = compileDeclList env decls
      in
        (env, decls1 @ decls2)
      end

  fun compile decls =
      let
        val _ = UserError.clearQueue errors
        val (env, decls) = compileDeclList emptyEnv decls
      in
        case UserError.getErrors errors of
          [] => decls
        | errors => raise UserError.UserErrors errors
      end

end
