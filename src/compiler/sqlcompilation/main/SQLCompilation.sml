(**
 * SQL compilation.
 *
 * @copyright (c) 2014, Tohoku University.
 * @author UENO Katsuhiro
 * @author Hiroki Endo
 *)
structure SQLCompilation : sig

  val compile : IDCalc.topdecl -> IDCalc.topdecl

end =
struct

  structure I = IDCalc

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

  fun Nil loc =
      I.ICCON BuiltinTypes.nilICConInfo

  fun Pair (exp1, exp2, loc) =
      I.ICRECORD ([("1", exp1), ("2", exp2)], loc)

  fun Cons (h, t, loc) =
      I.ICAPPM (I.ICCON BuiltinTypes.consICConInfo, [Pair (h, t, loc)], loc)

  fun List (exps, loc) =
      foldr (fn (exp, z) => Cons (exp, z, loc)) (Nil loc) exps

  fun PairPat (pat1, pat2, loc) =
      I.ICPATRECORD {flex = false,
                     fields = [("1", pat1), ("2", pat2)],
                     loc = loc}

  exception NotRecordTy

  fun recordTyFields ty =
      case ty of
        I.TYRECORD fields => fields
      | _ =>
        if NormalizeTy.equalTy (NormalizeTy.emptyTypIdEquiv, TvarID.Map.empty)
                               (ty, BuiltinTypes.unitITy)
        then LabelEnv.empty
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
                      (loc, SQLCompileError.InvalidSQLSchemaTy ty);
                    LabelEnv.empty)
        val schema =
            LabelEnv.mapi
              (fn (name, ty) =>
                  recordTyFields ty
                  handle NotRecordTy =>
                         (UserErrorUtils.enqueueError
                            (loc,
                             SQLCompileError.InvalidSQLTableTy (name, ty));
                          LabelEnv.empty))
              tableTys
        val schema =
            LabelEnv.map
              (LabelEnv.map
                 (fn ty => {toyVar = newVar loc,
                            infoVar = newVar loc,
                            ty = ty}))
              schema
        val schema =
            LabelEnv.listItemsi (LabelEnv.map LabelEnv.listItemsi schema)
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
                                      [String (label, loc)], loc)))
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
                         (String (tableName, loc),
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
      | I.ICTYCASTDECL (tycastList, decls, loc) =>
        I.ICTYCASTDECL (tycastList, map compileDecl decls, loc)
      | I.ICOVERLOADDEF _ => icdecl

  fun compile decls =
      let
        val _ = UserErrorUtils.initializeErrorQueue ()
        val decls = map compileDecl decls
      in
        case UserErrorUtils.getErrors () of
          nil => decls
        | errors => raise UserError.UserErrors errors
      end

end
