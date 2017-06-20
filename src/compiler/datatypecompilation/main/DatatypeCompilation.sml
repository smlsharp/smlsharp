(**
 * Translation of datatypes to record types.
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure DatatypeCompilation : sig

  val compile : RecordCalc.rcdecl list -> TypedLambda.tldecl list

end =
struct

  structure RC = RecordCalc
  structure TC = TypedCalc
  structure TL = TypedLambda
  structure CT = ConstantTerm
  structure BT = BuiltinTypes
  structure T = Types
  structure E = EmitTypedLambda
  datatype taggedLayout = datatype DatatypeLayout.taggedLayout
  datatype layout = datatype DatatypeLayout.layout

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
      CT.CONTAG (Word32.fromInt const)

  fun exnConTy exnCon =
      case exnCon of
        RC.EXN {ty,...} => ty
      | RC.EXEXN {ty,...} => ty

  fun extractTyCon ty =
      case TypesBasics.derefTy ty of
        T.CONSTRUCTty {tyCon, args} => tyCon
      | _ => raise Bug.Bug "extractTyCon"

  fun unwrapLet (TL.TLLET {localDecl, mainExp, loc}) =
      let
        val (decls, mainExp) = unwrapLet mainExp
      in
        (E.Decl (localDecl, loc) :: decls, mainExp)
      end
    | unwrapLet mainExp = (nil, mainExp)

  fun explodeRecordExp exp =
      let
        val expTy =
            case exp of
              E.Exp (_, ty) => ty
            | E.Cast (_, ty) => ty
            | _ => raise Bug.Bug "explodeRecordExp"
        val fieldTys =
            case TypesBasics.derefTy expTy of
              T.RECORDty fieldTys => fieldTys
            | _ => raise Bug.Bug "explodeRecordExp: not a record"
      in
        case exp of
          E.Exp (TL.TLRECORD {isMutable = false, fields, recordTy, ...}, _) =>
          (nil,
           map (fn (label, exp) =>
                   E.Exp (exp, case RecordLabel.Map.find (fieldTys, label) of
                                 SOME ty => ty
                               | NONE => raise Bug.Bug "explodeRecordExp"))
               (RecordLabel.Map.listItemsi fields))
        | _ =>
          let
            val vid = EmitTypedLambda.newId ()
          in
            ([(vid, exp)],
             map (fn (label, ty) => E.Select (label, E.Var vid))
                 (RecordLabel.Map.listItemsi fieldTys))
          end
      end

  fun explodeRecordTy recordTy =
      case TypesBasics.derefTy recordTy of
        T.RECORDty fields => ListPair.unzip (RecordLabel.Map.listItemsi fields)
      | ty => raise Bug.Bug "explodeRecordTy"

  fun decomposeDataconTy ty =
      case TypesBasics.derefTy ty of
        T.FUNMty ([argTy], retTy) => (SOME argTy, retTy)
      | T.CONSTRUCTty _ => (NONE, ty)
      | _ => raise Bug.Bug "decomposeDataconTy"

  fun dataconArgTy ({ty, ...}:RecordCalc.conInfo) =
      case TypesBasics.derefTy ty of
        T.POLYty {boundtvars, constraints, body} =>
        (case TypesBasics.derefTy body of
           T.FUNMty ([argTy], retTy) => argTy
         | _ => raise Bug.Bug "dataconArgTy")
      | T.FUNMty ([argTy], retTy) => argTy
      | _ => raise Bug.Bug "dataconArgTy"

  fun lookupConTag (taggedLayout, path) =
      let
        val tagMap =
            case taggedLayout of
              TAGGED_TAGONLY {tagMap} => tagMap
            | TAGGED_RECORD {tagMap} => tagMap
            | TAGGED_OR_NULL {tagMap, nullName} => tagMap
      in
        case SymbolEnv.find (tagMap, Symbol.lastSymbol path) of
          NONE => raise Bug.Bug ("dataconTag " ^ Symbol.longsymbolToString path)
        | SOME tag => tag : int
      end

  fun extractConTag (taggedLayout, exp) =
      case taggedLayout of
        TAGGED_TAGONLY _ => E.Cast (exp, BT.contagTy)
      | TAGGED_RECORD _ => E.SelectN (1, E.Cast (exp, E.tupleTy [BT.contagTy]))
      | TAGGED_OR_NULL {tagMap, nullName} =>
        let
          val vid = EmitTypedLambda.newId ()
        in
          E.Let ([(vid, exp)],
                 E.If (E.IsNull (E.Cast (exp, BT.boxedTy)),
                       E.ConTag (lookupConTag (taggedLayout, [nullName])),
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

  fun extractTaggedConArg (conInfo:RecordCalc.conInfo, dataExp) argTy =
      E.SelectN (2, E.Cast (dataExp, E.tupleTy [BT.contagTy, argTy]))

  fun composeCon (conInfo:RC.conInfo, instTyList, argExpOpt) =
      let
        val conInstTy = TypesBasics.tpappTy (#ty conInfo, instTyList)
        val (argTy, retTy) = decomposeDataconTy conInstTy
        val argExpOpt =
            case (argExpOpt, argTy) of
              (NONE, NONE) => NONE
            | (SOME argExp, SOME argTy) => SOME (E.Exp (argExp, argTy))
            | _ => raise Bug.Bug "composeCon"
        val layout = DatatypeLayout.datatypeLayout (extractTyCon retTy)
      in
        case layout of
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
                                          falseName)
                      then E.ConTag 0 else E.ConTag 1,
                      retTy)
          )
        | LAYOUT_SINGLE =>
          (
            case argExpOpt of
              SOME _ => raise Bug.Bug "composeCon: LAYOUT_SINGLE"
            | NONE => E.Cast (E.ConTag 0, retTy)
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
        val tyCon = extractTyCon dataTy
        val layout = DatatypeLayout.datatypeLayout tyCon
        val dataExp = E.Exp (dataExp, dataTy)
      in
        case layout of
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
            | _ => raise Bug.Bug "compileExp: RCCASE: LAYOUT_ARGONLY"
          )
      end

  type env =
      {
        exnMap: TL.varInfo ExnID.Map.map,
        exExnMap: TL.exVarInfo LongsymbolEnv.map
      }

  val emptyEnv =
      {exnMap = ExnID.Map.empty, exExnMap = LongsymbolEnv.empty} : env

  fun newLocalExn (env:env, {path, ty, id}:RC.exnInfo) =
      let
        val vid = VarID.generate ()
        val varInfo = {path = path, ty = BT.exntagTy, id = vid} : TL.varInfo
      in
        ({exnMap = ExnID.Map.insert (#exnMap env, id, varInfo),
          exExnMap = #exExnMap env} : env,
         varInfo)
      end

  fun addExternExn (env:env, {path, ty}:RC.exExnInfo) =
      let
        val exVarInfo = {path = path, ty = BT.exntagTy} : TL.exVarInfo
      in
        ({exnMap = #exnMap env,
          exExnMap = LongsymbolEnv.insert (#exExnMap env, path, exVarInfo)} : env,
         exVarInfo)
      end

  fun findLocalExnTag ({exnMap, ...}:env, {id, ...}:RC.exnInfo) =
      ExnID.Map.find (exnMap, id)

  fun findExternExnTag ({exExnMap, ...}:env, {path,...}:RC.exExnInfo) =
      LongsymbolEnv.find (exExnMap, path)

  fun findExnTag (env, exnCon) =
      case exnCon of
        RC.EXN e =>
        (case findLocalExnTag (env, e) of
           SOME v => SOME (E.TLVar v)
         | NONE => NONE
        )
      | RC.EXEXN e =>
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
      ConstantTerm.fixConst
        {constTerm = fn c =>
                        TL.TLCONSTANT {const = c,
                                       ty = ConstantTerm.typeOf c,
                                       loc = loc},
         tupleTerm =
           fn fields =>
              TL.TLRECORD
                {isMutable = false,
                 fields = RecordLabel.tupleMap (map #1 fields),
                 recordTy = T.RECORDty (RecordLabel.tupleMap (map #2 fields)),
                 loc = loc},
         conTerm =
           fn {con, instTyList, arg} =>
              EmitTypedLambda.emit loc (composeCon (con, instTyList, arg)),
         fnTerm =
           fn (ty1,(exp,ty2)) => TL.TLFNM {argVarList = [newVar ty1],
                                           bodyTy = ty2,
                                           bodyExp = exp,
                                           loc = loc}}
        (const, ty)
      handle e as ConstantTerm.TooLargeConstant =>
             (UserError.enqueueError errors (loc, e);
              TL.TLCONSTANT {const=ConstantTerm.UNIT, ty=ty, loc=loc}) (*dummy*)

  fun compileExp (env:env) rcexp =
      case rcexp of
        RC.RCFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        TL.TLFOREIGNAPPLY
          {funExp = compileExp env funExp,
           argExpList = map (compileExp env) argExpList,
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | RC.RCCALLBACKFN {attributes, resultTy, argVarList, bodyExp, loc} =>
        TL.TLCALLBACKFN
          {attributes = attributes,
           resultTy = resultTy,
           argVarList = argVarList,
           bodyExp = compileExp env bodyExp,
           loc = loc}
      | RC.RCSIZEOF (ty, loc) =>
        TL.TLSIZEOF {ty=ty, loc=loc}
      | RC.RCTYPEOF (ty, loc) => raise Bug.Bug "RCTYPEOF in DatatypeCompilation"
      | RC.RCREIFYTY (ty, loc) => raise Bug.Bug "RCREIFYTY in DatatypeCompilation"
      | RC.RCTAGOF (ty, loc) =>
        TL.TLTAGOF {ty=ty, loc=loc}
      | RC.RCINDEXOF (label, recordTy, loc) =>
        TL.TLINDEXOF {label=label, recordTy=recordTy, loc=loc}
      | RC.RCCONSTANT {const, loc, ty} =>
        fixConst (const, ty, loc)
      | RC.RCFOREIGNSYMBOL {name, ty, loc} =>
        TL.TLFOREIGNSYMBOL {name=name, ty=ty, loc=loc}
      | RC.RCVAR varInfo =>
        TL.TLVAR {varInfo = varInfo, loc = Loc.noloc}
      | RC.RCEXVAR exVarInfo =>
        TL.TLEXVAR {exVarInfo = exVarInfo, loc = Loc.noloc}
      | RC.RCPRIMAPPLY {primOp={primitive, ty}, instTyList, argExp, loc} =>
        let
          val argExp = compileExp env argExp
          val (argTy, retTy) =
              case TypesBasics.tpappTy (ty, instTyList) of
                T.FUNMty ([argTy], retTy) => (argTy, retTy)
              | _ => raise Bug.Bug "RCPRIMAPPLY: not a function"
          val (decls, argExp) = unwrapLet argExp
          val argExp = E.Exp (argExp, argTy)
          val primTy = PrimitiveTypedLambda.toPrimTy ty
          val (binds, argExps) =
              case #argTyList primTy of
                nil => (nil, nil)
              | _::nil => (nil, [argExp])
              | _::_::_ => explodeRecordExp argExp
          val exp =
              E.Let (binds,
                     PrimitiveTypedLambda.compile
                       {primitive = primitive,
                        primTy = primTy,
                        instTyList = instTyList,
                        resultTy = retTy,
                        argExpList = argExps,
                        loc = loc})
        in
          EmitTypedLambda.emit loc (E.TLLet (decls, exp))
        end
      | RC.RCDATACONSTRUCT {con, instTyList, argExpOpt, argTyOpt, loc} =>
        let
          val argExpOpt = Option.map (compileExp env) argExpOpt
        in
          EmitTypedLambda.emit loc (composeCon (con, instTyList, argExpOpt))
        end
      | RC.RCEXNCONSTRUCT {exn, instTyList=nil, argExpOpt, loc} =>
        let
          val argExpOpt = Option.map (compileExp env) argExpOpt
        in
          EmitTypedLambda.emit loc (composeExn env (exn, argExpOpt, loc))
        end
      | RC.RCEXNCONSTRUCT {exn, instTyList=_::_, argExpOpt, loc} =>
        raise Bug.Bug "compileExp: RCEXNCONSTRUCT"
      | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} =>
        (
          case findLocalExnTag (env, exnInfo) of
            NONE => raise Bug.Bug "compileExp: RCEXN_CONSTRUCTOR"
          | SOME var => TL.TLVAR {varInfo = var, loc = loc}
        )
      | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
        (
          case findExternExnTag (env, exExnInfo) of
            NONE => raise Bug.Bug "compileExp: RCEXEXN_CONSTRUCTOR"
          | SOME var => TL.TLEXVAR {exVarInfo = var, loc = loc}
        )
      | RC.RCAPPM {funExp, funTy, argExpList, loc} =>
        let
          val argExpList = map (compileExp env) argExpList
        in
          TL.TLAPPM {funExp = compileExp env funExp,
                     funTy = funTy,
                     argExpList = argExpList,
                     loc = loc}
        end
      | RC.RCMONOLET {binds, bodyExp, loc} =>
        foldr
          (fn ((var, exp), mainExp) =>
              TL.TLLET
                {localDecl = TL.TLVAL {boundVar = var,
                                       boundExp = compileExp env exp,
                                       loc = loc},
                 mainExp = mainExp,
                 loc = loc})
          (compileExp env bodyExp)
          binds
      | RC.RCLET {decls, body=[rcexp], tys, loc} =>
        let
          val (env, decls) = compileDeclList env decls
          val mainExp = compileExp env rcexp
        in
          foldr
            (fn (dec, mainExp) =>
                TL.TLLET {localDecl = dec, mainExp = mainExp, loc = loc})
            mainExp
            decls
        end
      | RC.RCLET {decls, body, tys, loc} =>
        compileExp env (RC.RCLET {decls = decls,
                                  body = [RC.RCSEQ {expList = body,
                                                    expTyList = tys,
                                                    loc = loc}],
                                  tys = [List.last tys],
                                  loc = loc})
      | RC.RCRECORD {fields, recordTy, loc} =>
        if RecordLabel.Map.isEmpty fields
        then EmitTypedLambda.emit loc (E.Cast (E.Null, recordTy))
        else TL.TLRECORD
               {isMutable = false,
                fields = RecordLabel.Map.map (compileExp env) fields,
                recordTy = recordTy,
                loc = loc}
      | RC.RCSELECT {indexExp, label, exp, expTy, resultTy, loc} =>
        TL.TLSELECT
          {recordExp = compileExp env exp,
           indexExp = compileExp env indexExp,
           label = label,
           recordTy = expTy,
           resultTy = resultTy,
           loc = loc}
      | RC.RCMODIFY {indexExp, label, recordExp, recordTy, elementExp,
                     elementTy, loc} =>
        TL.TLMODIFY
          {indexExp = compileExp env indexExp,
           label = label,
           recordExp = compileExp env recordExp,
           recordTy = recordTy,
           valueExp = compileExp env elementExp,
           valueTy = elementTy,
           loc = loc}
      | RC.RCRAISE {exp, ty, loc} =>
        TL.TLRAISE
          {argExp = compileExp env exp,
           resultTy = ty,
           loc = loc}
      | RC.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        TL.TLHANDLE
          {exp = compileExp env exp,
           exnVar = exnVar,
           handler = compileExp env handler,
           resultTy = resultTy,
           loc = loc}
      | RC.RCCASE {exp, expTy, ruleList, defaultExp, resultTy, loc} =>
        let
          val exp = compileExp env exp
          val ruleList = map (fn (conInfo, argVar, exp) =>
                                 (conInfo, argVar, compileExp env exp))
                             ruleList
          val defaultExp = compileExp env defaultExp
        in
          EmitTypedLambda.emit
            loc
            (switchCon (exp, expTy, ruleList, defaultExp, resultTy))
        end
      | RC.RCEXNCASE {exp, expTy, ruleList, defaultExp, resultTy, loc} =>
        let
          val exp = compileExp env exp
          val ruleList = map (fn (exnCon, argVar, exp) =>
                                 (exnCon, argVar, compileExp env exp))
                             ruleList
          val defaultExp = compileExp env defaultExp
        in
          EmitTypedLambda.emit
            loc
            (switchExn env (exp, expTy, ruleList, defaultExp, resultTy))
        end
      | RC.RCSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
        let
          val switchExp = compileExp env switchExp
          val branches =
              map (fn (c, e) =>
                      case fixConst (c, expTy, loc) of
                        TL.TLCONSTANT {const, ...} =>
                        {constant = const, exp = compileExp env e}
                      | _ => raise Bug.Bug "compileExp: RCSWITCH")
                  branches
          val defaultExp = compileExp env defaultExp
        in
          case branches of
            {constant = CT.INTINF _, exp = _}::_ =>
            SwitchCompile.compileIntInfSwitch
              {switchExp = switchExp,
               expTy = expTy,
               branches = branches,
               defaultExp = defaultExp,
               resultTy = resultTy,
               loc = loc}
          | {constant = CT.STRING _, exp = _}::_ =>
            SwitchCompile.compileStringSwitch
              {switchExp = switchExp,
               expTy = expTy,
               branches = branches,
               defaultExp = defaultExp,
               resultTy = resultTy,
               loc = loc}
          | _ =>
            TL.TLSWITCH
              {switchExp = switchExp,
               expTy = expTy,
               branches = branches,
               defaultExp = defaultExp,
               resultTy = resultTy,
               loc = loc}
        end
      | RC.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
        TL.TLFNM
          {argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp env bodyExp,
           loc = loc}
      | RC.RCPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
        TL.TLPOLY
          {btvEnv = btvEnv,
           expTyWithoutTAbs = T.FUNMty (map #ty argVarList, bodyTy),
           exp = TL.TLFNM {argVarList = argVarList,
                           bodyTy = bodyTy,
                           bodyExp = compileExp env bodyExp,
                           loc = loc},
           loc = loc}
      | RC.RCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        TL.TLPOLY
          {btvEnv = btvEnv,
           expTyWithoutTAbs = expTyWithoutTAbs,
           exp = compileExp env exp,
           loc = loc}
      | RC.RCTAPP {exp, expTy, instTyList, loc} =>
        TL.TLTAPP
          {exp = compileExp env exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | RC.RCSEQ {expList, expTyList, loc} =>
        let
          val exps = ListPair.zipEq (map (compileExp env) expList, expTyList)
        in
          case rev exps of
            nil => raise Bug.Bug "compileExp: RCLET"
          | [exp] => #1 exp
          | lastExp::exps =>
            foldl
              (fn ((exp, ty), mainExp) =>
                   TL.TLLET {localDecl = TL.TLVAL {boundVar = newVar ty,
                                                   boundExp = exp,
                                                   loc = loc},
                             mainExp = mainExp,
                             loc = loc})
              (#1 lastExp)
              exps
        end
      | RC.RCCAST ((rcexp, expTy), ty, loc) =>
        TL.TLCAST {exp = compileExp env rcexp, expTy = expTy, targetTy = ty,
                   cast = BuiltinPrimitive.TypeCast, loc = loc}
      | RC.RCOPRIMAPPLY _ =>
        raise Bug.Bug "compileExp: RCOPRIMAPPLY"
      | RC.RCFFI exp =>
        raise Bug.Bug "RCFFI"
      | RC.RCJOIN _ =>
        raise Bug.Bug "compileExp: RCJOIN"
      | RC.RCJSON _ =>
        raise Bug.Bug "compileExp: RCJSON"
      | RC.RCFOREACH _ =>
        raise Bug.Bug "compileExp: RCFOREACH"
      | RC.RCFOREACHDATA _ =>
        raise Bug.Bug "compileExp: RCFOREACH"

  and compileDecl env rcdecl =
      case rcdecl of
        RC.RCVAL (bindList, loc) =>
        (env,
         map (fn (v, e) =>
                 TL.TLVAL {boundVar = v,
                           boundExp = compileExp env e,
                           loc = loc})
             bindList)
      | RC.RCVALREC (bindList, loc) =>
        (env,
         [TL.TLVALREC
            {recbindList = map (fn {var, expTy, exp} =>
                                   {boundVar = var,
                                    boundExp = compileExp env exp})
                               bindList,
             loc = loc}])
      | RC.RCVALPOLYREC (btvEnv, bindList, loc) =>
        raise Bug.Bug "compileExp: RCVALPOLYREC"
      | RC.RCEXPORTVAR {path, id, ty} =>
        (env, [TL.TLEXPORTVAR
                 {weak = false,
                  exVarInfo = {path=path, ty=ty},
                  exp = TL.TLVAR {varInfo = {path=path, ty=ty, id=id},
                                  loc = Loc.noloc},
                  loc = Loc.noloc}])
      | RC.RCEXTERNVAR exVarInfo =>
        (env, [TL.TLEXTERNVAR (exVarInfo, Loc.noloc)])
      | RC.RCEXD (exnBinds, loc) =>
        let
          fun compileExBind env nil = (env, nil)
            | compileExBind env ({exnInfo as {path, ty, ...}, loc}::binds) =
              let
                val (env, tagVar) = newLocalExn (env, exnInfo)
                val (env, decls) = compileExBind env binds
                val tagExp = EmitTypedLambda.allocExnTag
                               {builtin=false, path=path, ty=ty}
              in
                (env,
                 TL.TLVAL
                   {boundVar = tagVar,
                    boundExp = EmitTypedLambda.emit loc tagExp,
                    loc = loc}
                 :: decls)
              end
        in
          compileExBind env exnBinds
        end
      | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val (env, tagVar) = newLocalExn (env, exnInfo)
        in
          (env,
           [TL.TLVAL {boundVar = tagVar,
                      boundExp = TL.TLVAR {varInfo = varInfo, loc = loc},
                      loc = loc}])
        end
      | RC.RCEXPORTEXN (exnInfo as {path, ...}) =>
        (
          case findLocalExnTag (env, exnInfo) of
            NONE => raise Bug.Bug "compileDecl: RCEXPORTEXN"
          | SOME (var as {id, ty,...}) =>
            (* ohori: bug 184. the external name is "path" in exnInfo,
               which must be kept. *)
            (env, [TL.TLEXPORTVAR
                     {weak = false,
                      exVarInfo = {path=path, ty=ty},
                      exp = TL.TLVAR {varInfo = var, loc = Loc.noloc},
                      loc = Loc.noloc}])
        )
      | RC.RCEXTERNEXN exExnInfo =>
        let
          val (env, tagVar) = addExternExn (env, exExnInfo)
        in
          (env, [TL.TLEXTERNVAR (tagVar, Loc.noloc)])
        end
      | RC.RCBUILTINEXN (exExnInfo as {path, ty}) =>
        let
          val tagExp = EmitTypedLambda.allocExnTag
                         {builtin=true, path=path, ty=ty}
          val (env, _) = addExternExn (env, exExnInfo)
        in
          (env,
           [TL.TLEXPORTVAR
              {weak = true,
               exVarInfo = {path = path, ty = BT.exntagTy},
               exp = EmitTypedLambda.emit Loc.noloc tagExp,
               loc = Loc.noloc}])
        end

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
