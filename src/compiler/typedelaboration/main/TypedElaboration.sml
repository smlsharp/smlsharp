(**
 * Typed Elaboration
 *
 * @copyright (c) 2016, Tohoku University.
 * @author UENO Katsuhiro
 * @author Hiroki Endo
 *)
structure TypedElaboration =
struct

  structure I = IDCalc
  structure J = JSONData

  type json = I.icexp

  fun newVar loc =
      let
        val id = VarID.generate ()
      in
        {id = id,
         longsymbol = Symbol.mkLongsymbol ["$" ^ VarID.toString id] loc}
        : I.varInfo
      end

  fun String (str, loc) =
      I.ICCONSTANT (Absyn.STRING (str, loc))

  fun StringPat (str, loc) =
      I.ICPATCONSTANT (Absyn.STRING (str, loc))

  fun LabelAsString (label, loc) =
      String (RecordLabel.toString label, loc)

  fun LabelAsStringPat (label, loc) =
      StringPat (RecordLabel.toString label, loc)

  fun Nil loc =
      I.ICCON BuiltinTypes.nilICConInfo

  fun Pair (exp1, exp2, loc) =
      I.ICRECORD (RecordLabel.tupleList [exp1, exp2], loc)

  fun Cons (h, t, loc) =
      I.ICAPPM (I.ICCON BuiltinTypes.consICConInfo, [Pair (h, t, loc)], loc)

  fun List (exps, loc) =
      foldr (fn (exp, z) => Cons (exp, z, loc)) (Nil loc) exps

  fun Con1Pat (con, arg, loc) =
      I.ICPATCONSTRUCT {con = I.ICPATCON con, arg = arg, loc = loc}

  fun PairPat (pat1, pat2, loc) =
      I.ICPATRECORD {flex = false,
                     fields = RecordLabel.tupleList [pat1, pat2],
                     loc = loc}

  fun ListPat (nil, loc) = I.ICPATCON BuiltinTypes.nilICConInfo
    | ListPat (h::t, loc) = I.ICPATCONSTRUCT
                              {con = I.ICPATCON BuiltinTypes.consICConInfo,
                               arg = PairPat (h, ListPat (t, loc), loc),
                               loc = loc}

  exception NotRecordTy

  fun recordTyFields ty =
      case ty of
        I.TYRECORD fields => fields
      | _ =>
        if NormalizeTy.equalTy (NormalizeTy.emptyTypIdEquiv, TvarID.Map.empty)
                               (ty, BuiltinTypes.unitITy)
        then RecordLabel.Map.empty
        else raise NotRecordTy

  fun compileSchema {columnInfoFnExp, ty, loc} =
      let
        (*
         * compile
         *     {hoge: {fuga: int}}
         * to
         *     let
         *       val ($1 : int, $2) = columnInfo "fuga"
         *     in
         *       ([("hoge", [$2])], {hoge = {fuga = $1}})
         *     end
         *)
        val tableTys =
            recordTyFields ty
            handle NotRecordTy =>
                   (UserErrorUtils.enqueueError
                      (loc, TypedElaborationError.InvalidSQLSchemaTy ty);
                    RecordLabel.Map.empty)
        val schema =
            RecordLabel.Map.mapi
              (fn (name, ty) =>
                  recordTyFields ty
                  handle NotRecordTy =>
                         (UserErrorUtils.enqueueError
                            (loc,
                             TypedElaborationError.InvalidSQLTableTy (name, ty));
                          RecordLabel.Map.empty))
              tableTys
        val schema =
            RecordLabel.Map.map
              (RecordLabel.Map.map
                 (fn ty => {toyVar = newVar loc,
                            infoVar = newVar loc,
                            ty = ty}))
              schema
        val schema =
            RecordLabel.Map.listItemsi (RecordLabel.Map.map RecordLabel.Map.listItemsi schema)
        val binds =
            List.concat
              (map
                 (fn (_, fields) =>
                     map
                       (fn (label, {toyVar, infoVar, ty}) =>
                           (PairPat
                              (I.ICPATTYPED (I.ICPATVAR_TRANS toyVar, ty, loc),
                               I.ICPATVAR_TRANS infoVar,
                               loc),
                            I.ICAPPM (columnInfoFnExp,
                                      [LabelAsString (label, loc)], loc)))
                       fields)
                 schema)
        val toyExp =
            I.ICRECORD
              (map (fn (label, fields) =>
                       (label,
                        I.ICRECORD
                          (map (fn (l, {toyVar,...}) => (l, I.ICVAR toyVar))
                               fields,
                           loc)))
                   schema,
               loc)
        val infoExp =
            List
              (map (fn (tableName, fields) =>
                       Pair
                         (LabelAsString (tableName, loc),
                          List (map (fn (l, {infoVar,...}) => I.ICVAR infoVar)
                                    fields,
                                loc),
                          loc))
                   schema,
               loc)
      in
        I.ICLET ([I.ICVAL (nil, binds, loc)],
                 [Pair (infoExp, toyExp, loc)],
                 loc)
      end

  fun eqTy (x, y) = TypID.eq (I.tfunId x, I.tfunId y)

  fun jsonError (ty, loc) =
      (UserErrorUtils.enqueueError (loc, TypedElaborationError.InvalidJSONty ty);
       I.ICERROR)

  fun Case ({exnExp,...}) (exp1, pat, loc) exp2 =
      I.ICCASEM
        ([exp1],
         [{args = [pat], body = exp2},
          {args = [I.ICPATWILD loc], body = I.ICRAISE (exnExp, loc)}],
         PatternCalc.MATCH,
         loc)

  fun App (exp1, nil, loc) = exp1
    | App (exp1, h::t, loc) = App (I.ICAPPM (exp1, [h], loc), t, loc)

  fun Fn (expFn, loc) =
      let
        val v = newVar loc
      in
        I.ICFNM ([{args = [I.ICPATVAR_TRANS v], body = expFn v}], loc)
      end

  exception JsonTy

  fun recordFieldPat (l, loc) =
      ListPat (map (fn (l,_,v) =>
                       PairPat (LabelAsStringPat (l, loc), I.ICPATVAR_TRANS v, loc))
                   l,
               loc)

  fun coerceJson (jsonExp, ty, loc) =
      case ty of
        I.TYCONSTRUCT {tfun, args=[]} =>
        if eqTy (tfun, #tfun BuiltinTypes.intTstrInfo) then 
          (App (J.checkInt(), [jsonExp], loc), J.INTty())
        else if eqTy (tfun, #tfun BuiltinTypes.realTstrInfo) then 
          (App (J.checkReal(), [jsonExp], loc),J.REALty())
        else if eqTy (tfun, #tfun BuiltinTypes.stringTstrInfo) then 
          (App (J.checkString(), [jsonExp], loc), J.STRINGty())
        else if eqTy (tfun, #tfun BuiltinTypes.boolTstrInfo) then 
          (App (J.checkBool(), [jsonExp], loc), J.BOOLty())
        else if eqTy (tfun, J.nullTfun()) then 
          (App (J.checkNull(), [jsonExp], loc), J.NULLty())
        else if eqTy (tfun, #tfun BuiltinTypes.unitTstrInfo) then
          (App (J.checkRecord(), [jsonExp, Nil loc], loc),
           App (J.RECORDty(), [Nil loc], loc))
        else raise JsonTy
      | I.TYCONSTRUCT {tfun, args=[argTy]} =>
        if eqTy (tfun, #tfun BuiltinTypes.listTstrInfo) then 
          let
            val funExp = Fn (fn x => coerceJsonExp (I.ICVAR x, argTy, loc), loc)
            val jsonListExp = App (J.checkArray(), [jsonExp], loc)
          in
            (App (J.mapCoerce(), [funExp, jsonListExp], loc),
             App (J.ARRAYty(), [tyToJsonTy loc argTy], loc))
          end
        else if eqTy (tfun, J.dynTfun()) then
          case argTy of
            I.TYRECORD fields =>
            (let
               val funExp = Fn (fn x => coerceJsonExp (I.ICVAR x, argTy, loc), loc)
               val jsonTy = tyToJsonTy loc argTy
             in
               App (J.makeCoerce(), [jsonExp, jsonTy, funExp], loc)
             end,
             App (J.PARTIALRECORDty(),
                  [(RecordLabel.Map.foldri
                      (fn (label, exp, listexp) => 
                          Cons (Pair(LabelAsString (label, loc), exp, loc), listexp, loc))
                      (Nil loc)
                      (RecordLabel.Map.map (tyToJsonTy loc) fields))
                  ], 
                  loc)
            )
          | I.TYCONSTRUCT {tfun, args=[]} =>
            if eqTy (tfun, #tfun BuiltinTypes.unitTstrInfo) then
              let
                val viewRecordTy = I.TYRECORD RecordLabel.Map.empty
                val funExp = Fn (fn x => coerceJsonExp (I.ICVAR x, viewRecordTy, loc), loc)
                val jsonTy = tyToJsonTy loc viewRecordTy
              in
                (App (J.makeCoerce(), [jsonExp, jsonTy, funExp], loc),
                 App (J.PARTIALRECORDty(), [Nil loc], loc))
              end
            else if eqTy (tfun, J.voidTfun()) then
              (App (J.checkDyn(), [jsonExp], loc), J.DYNty())
            else raise JsonTy
          | _ => raise JsonTy
        else raise JsonTy
      | I.TYRECORD tyFields =>
        (let
           val labelsExp = List (map (fn (l,ty) => LabelAsString (l, loc)) (RecordLabel.Map.listItemsi tyFields), loc)
           val checkExp = App (J.checkRecord(), [jsonExp, labelsExp], loc)
           val l = map (fn (s, t) => (s, t, newVar loc)) (RecordLabel.Map.listItemsi tyFields)
           val patFields = 
               I.ICPATCONSTRUCT
                 {con = I.ICPATCON (J.OBJECTConInfo()), arg = recordFieldPat (l,loc), loc=loc}
           val body = 
               I.ICRECORD
                 (foldr (fn ((l,t,v),fields) => 
                            (l, coerceJsonExp (I.ICVAR v, t, loc))::fields)
                        nil
                        l,
                  loc)
           val caseExp = 
               I.ICCASEM
                 ([jsonExp],
                  [{args = [patFields], body = body},
                   {args = [I.ICPATWILD loc], body = I.ICRAISE (J.RuntimeTypeErrorExp(), loc)}],
                  PatternCalc.MATCH,
                  loc)
         in
           I.ICSEQ ([checkExp, caseExp], loc)
         end,
         App (J.RECORDty(), 
              [(RecordLabel.Map.foldri
                  (fn (label, exp, listexp) => 
                      Cons (Pair(LabelAsString (label, loc), exp, loc), listexp, loc))
                  (Nil loc)
                  (RecordLabel.Map.map (tyToJsonTy loc) tyFields))
              ], 
              loc)
        )
      | _ => raise JsonTy
  and tyToJsonTy loc ty = #2 (coerceJson (I.ICVAR (newVar loc), ty, loc))
  and coerceJsonExp (icexp, ty, loc) = #1 (coerceJson (icexp, ty, loc))

  fun elaborateJson (icexp, ty, loc) =
      let
        val jsonExp = App (J.getJson(), [icexp] , loc)
        val (viewExp, viewTy) = coerceJson (jsonExp, ty, loc)
        val checkExp = App (J.checkTy(), [jsonExp, viewTy] , loc)
      in
        I.ICSEQ ([checkExp, I.ICTYPED (viewExp, ty, loc)], loc)
      end
      handle JsonTy =>
             (UserErrorUtils.enqueueError
                (loc, TypedElaborationError.InvalidJSONty ty);
              I.ICERROR)

  fun compileExp icexp =
      case icexp of
        I.ICERROR  => icexp
      | I.ICCONSTANT _ => icexp
      | I.ICVAR _ => icexp
      | I.ICEXVAR _ => icexp
      | I.ICEXVAR_TOBETYPED _ => icexp
      | I.ICBUILTINVAR _ => icexp
      | I.ICCON _ => icexp
      | I.ICEXN _ => icexp
      | I.ICEXEXN _ => icexp
      | I.ICEXN_CONSTRUCTOR exnInfo => icexp
      | I.ICEXEXN_CONSTRUCTOR exnInfo => icexp
      | I.ICOPRIM oprimInfo => icexp
      | I.ICTYPED (icexp, ty, loc) =>
        I.ICTYPED (compileExp icexp, ty, loc)
      | I.ICSIGTYPED {icexp, ty, loc, revealKey} =>
        I.ICSIGTYPED {icexp = compileExp icexp,
                      ty = ty,
                      revealKey = revealKey,
                      loc = loc}
      | I.ICAPPM (icexp, icexplist, loc) =>
        I.ICAPPM (compileExp icexp, map compileExp icexplist, loc)
      | I.ICAPPM_NOUNIFY (icexp, icexplist, loc) =>
        I.ICAPPM_NOUNIFY (compileExp icexp, map compileExp icexplist, loc)
      | I.ICLET (icdecList, icexpList, loc) =>
        I.ICLET (map compileDecl icdecList, map compileExp icexpList, loc)
      | I.ICTYCAST (tycastList, icexp, loc) =>
        I.ICTYCAST (tycastList, compileExp icexp, loc)
      | I.ICRECORD (fields, loc) =>
        I.ICRECORD (map (fn (l, exp) => (l, compileExp exp)) fields, loc)
      | I.ICRAISE (icexp, loc) =>
        I.ICRAISE (compileExp icexp, loc)
      | I.ICHANDLE (icexp, handlers, loc) =>
        I.ICHANDLE (compileExp icexp,
                    map (fn (pat, exp) => (pat, compileExp exp)) handlers,
                    loc)
      | I.ICFNM (rules, loc) =>
        I.ICFNM (map compileRule rules, loc)
      | I.ICFNM1 (args, icexp, loc) =>
        I.ICFNM1 (args, compileExp icexp, loc)
      | I.ICFNM1_POLY (args, icexp, loc) =>
        I.ICFNM1_POLY (args, compileExp icexp, loc)
      | I.ICCASEM (icexpList, rules, caseKind, loc) =>
        I.ICCASEM (map compileExp icexpList,
                   map compileRule rules,
                   caseKind,
                   loc)
      | I.ICRECORD_UPDATE (icexp, fields, loc) =>
        I.ICRECORD_UPDATE (compileExp icexp,
                           map (fn (l, exp) => (l, compileExp exp)) fields,
                           loc)
      | I.ICRECORD_SELECTOR _ => icexp
      | I.ICSELECT (label, icexp, loc) =>
        I.ICSELECT (label, compileExp icexp, loc)
      | I.ICSEQ (icexpList, loc) =>
        I.ICSEQ (map compileExp icexpList, loc)
      | I.ICFFIIMPORT (icexp, ty, loc) =>
        I.ICFFIIMPORT (compileFFIFun icexp, ty, loc)
      | I.ICFFIAPPLY (cconv, funExp, args, retTy, loc) =>
        I.ICFFIAPPLY (cconv,
                      compileFFIFun funExp,
                      map compileFFIArg args,
                      retTy,
                      loc)
      | I.ICSQLSCHEMA arg =>
        compileSchema arg
      | I.ICSQLDBI (icpat, icexp, loc) =>
        I.ICSQLDBI (icpat, compileExp icexp, loc)
      | I.ICJOIN (icexp1, icexp2, loc) =>
        I.ICJOIN (compileExp icexp1, compileExp icexp2, loc)
      | I.ICJSON arg => elaborateJson arg

  and compileFFIArg ffiArg =
      case ffiArg of
        I.ICFFIARG (exp, ty, loc) =>
        I.ICFFIARG (compileExp exp, ty, loc)
      | I.ICFFIARGSIZEOF (ty, SOME exp, loc) =>
        I.ICFFIARGSIZEOF (ty, SOME (compileExp exp), loc)
      | I.ICFFIARGSIZEOF (ty, NONE, loc) =>
        I.ICFFIARGSIZEOF (ty, NONE, loc)

  and compileFFIFun ffiFun =
      case ffiFun of
        I.ICFFIFUN exp => I.ICFFIFUN (compileExp exp)
      | I.ICFFIEXTERN _ => ffiFun

  and compileRule {args: I.icpat list, body} =
      {args = args, body = compileExp body}

  and compileDecl icdecl =
      case icdecl of
        I.ICVAL (tvars, binds, loc) =>
        I.ICVAL (tvars,
                 map (fn (pat, exp) => (pat, compileExp exp)) binds,
                 loc)
      | I.ICDECFUN {guard, funbinds, loc} =>
        I.ICDECFUN {guard = guard,
                    funbinds = map (fn {funVarInfo, tyList, rules} =>
                                       {funVarInfo = funVarInfo,
                                        tyList = tyList,
                                        rules = map compileRule rules})
                                   funbinds,
                    loc = loc}
      | I.ICNONRECFUN {guard, funVarInfo, tyList, rules, loc} =>
        I.ICNONRECFUN {guard = guard,
                       funVarInfo = funVarInfo,
                       tyList = tyList,
                       rules = map compileRule rules,
                       loc = loc}
      | I.ICVALREC {guard, recbinds, loc} =>
        I.ICVALREC {guard = guard,
                    recbinds = map (fn ({varInfo, tyList, body}) =>
                                       {varInfo = varInfo,
                                        tyList = tyList,
                                        body = compileExp body})
                                   recbinds,
                    loc = loc}
      | I.ICVALPOLYREC (polyrecbinds, loc) =>
        I.ICVALPOLYREC
          (map (fn {varInfo, ty, body} =>
                   {varInfo = varInfo, ty = ty, body = compileExp body})
               polyrecbinds,
           loc)
      | I.ICEXND _ => icdecl
      | I.ICEXNTAGD _ => icdecl
      | I.ICEXPORTVAR _ => icdecl
      | I.ICEXPORTTYPECHECKEDVAR _ => icdecl
      | I.ICEXPORTFUNCTOR _ => icdecl
      | I.ICEXPORTEXN _ => icdecl
      | I.ICEXTERNVAR _ => icdecl
      | I.ICEXTERNEXN _ => icdecl
      | I.ICBUILTINEXN _ => icdecl
      | I.ICTYCASTDECL (tycastList, decls, loc) =>
        I.ICTYCASTDECL (tycastList, map compileDecl decls, loc)
      | I.ICOVERLOADDEF _ => icdecl

  fun elaborate decls =
      let
        val _ = J.initExternalDecls ()
        val _ = UserErrorUtils.initializeErrorQueue ()
        val decls = map compileDecl decls
        val externDecls = J.getExternDecls ()
      in
        case UserErrorUtils.getErrors () of
          nil => externDecls@decls
        | errors => raise UserError.UserErrors errors
      end
end
