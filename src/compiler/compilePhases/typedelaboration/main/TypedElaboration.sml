(**
 * Typed Elaboration
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Hiroki Endo
 *)
structure TypedElaboration =
struct

  structure I = IDCalc

  fun Exp e (_:I.loc) = e : I.icexp

  fun Unit loc =
      I.ICCONSTANT (AbsynConst.UNITCONST, loc)

  fun String s loc =
      I.ICCONSTANT (AbsynConst.STRING s, loc)

  fun LabelString l =
      String (RecordLabel.toString l)

  fun App exp1 exp2 loc =
      I.ICAPPM (exp1 loc, [exp2 loc], loc)

  fun Tuple nil loc = Unit loc
    | Tuple [x] loc = x loc
    | Tuple exps loc =
      I.ICRECORD (RecordLabel.tupleList (map (fn e => e loc) exps), loc)

  fun Typed (exp, ty) loc =
      I.ICTYPED (exp loc, ty, loc)

  fun Nil loc =
      I.ICCON BuiltinTypes.nilICConInfo

  fun Cons (h, t) loc =
      I.ICAPPM (I.ICCON BuiltinTypes.consICConInfo, [Tuple [h, t] loc], loc)

  fun List exps =
      foldr (fn (exp, z) => Cons (exp, z)) Nil exps

  fun Fun_toy loc ty =
      Typed 
        (Exp (UserLevelPrimitive.SQL_icexp_toyServer loc),
         I.TYFUNM ([BuiltinTypes.unitITy], ty))

  fun eqTy (ty1, ty2) =
      NormalizeTy.equalTy
        (NormalizeTy.emptyTypIdEquiv, TvarID.Map.empty)
        (ty1, ty2)

  exception Unexpected

  fun listTy ty =
      case ty of
        I.TYCONSTRUCT {tfun, args = [argTy]} =>
        if eqTy (ty, I.TYCONSTRUCT {tfun = #tfun BuiltinTypes.listTstrInfo,
                                    args = [argTy]})
        then argTy
        else raise Unexpected
      | _ => raise Unexpected

  fun recordTy ty =
      case ty of
        I.TYRECORD {ifFlex,fields} => fields
      | _ => raise Unexpected

  fun compileSchema {tyFnExp, ty, loc} =
      let
        (* reify ty to SMLSharp_SQL_BackendTy.schema *)
        val dbTy =
            recordTy ty
            handle Unexpected =>
                   (UserErrorUtils.enqueueError
                      (loc, TypedElaborationError.InvalidSQLSchemaTy ty);
                    RecordLabel.Map.empty)
        val tableMap =
            RecordLabel.Map.mapi
              (fn (name, ty) =>
                  recordTy (listTy ty)
                  handle Unexpected =>
                         (UserErrorUtils.enqueueError
                            (loc, TypedElaborationError.InvalidSQLTableTy
                                    (name, ty));
                          RecordLabel.Map.empty))
              dbTy
        val tableList =
            RecordLabel.Map.listItemsi
              (RecordLabel.Map.map RecordLabel.Map.listItemsi tableMap)
        fun reifyColumn (colName, ty) =
            Tuple [LabelString colName, App (Exp tyFnExp) (Fun_toy loc ty)]
        fun reifyTable (tableName, columns) =
            Tuple [LabelString tableName, List (map reifyColumn columns)]
        fun reifySchema tables =
            List (map reifyTable tables)
      in
        Tuple [reifySchema tableList, Fun_toy loc ty] loc
      end

  fun compileExp icexp =
      case icexp of
        I.ICERROR  => icexp
      | I.ICCONSTANT _ => icexp
      | I.ICSIZEOF _ => icexp
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
      | I.ICINTERFACETYPED {icexp, path, ty, loc} =>
        I.ICINTERFACETYPED {icexp = compileExp icexp,
                            path = path,
                            ty = ty,
                            loc = loc}
      | I.ICAPPM (icexp, icexplist, loc) =>
        I.ICAPPM (compileExp icexp, map compileExp icexplist, loc)
      | I.ICAPPM_NOUNIFY (icexp, icexplist, loc) =>
        I.ICAPPM_NOUNIFY (compileExp icexp, map compileExp icexplist, loc)
      | I.ICLET (icdecList, icexp, loc) =>
        I.ICLET (map compileDecl icdecList, compileExp icexp, loc)
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
      | I.ICDYNAMICCASE (icexp, rules, loc) =>
        I.ICDYNAMICCASE (compileExp icexp,
                         map compileDynRule rules,
                         loc)
      | I.ICRECORD_UPDATE (icexp, fields, loc) =>
        I.ICRECORD_UPDATE (compileExp icexp,
                           map (fn (l, exp) => (l, compileExp exp)) fields,
                           loc)
      | I.ICRECORD_UPDATE2 (icexp, icexp2, loc) =>
        I.ICRECORD_UPDATE2 (compileExp icexp, compileExp icexp2, loc)
      | I.ICRECORD_SELECTOR _ => icexp
      | I.ICSELECT (label, icexp, loc) =>
        I.ICSELECT (label, compileExp icexp, loc)
      | I.ICSEQ (icexpList, loc) =>
        I.ICSEQ (map compileExp icexpList, loc)
      | I.ICFFIIMPORT (icexp, ty, loc) =>
        I.ICFFIIMPORT (compileFFIFun icexp, ty, loc)
      | I.ICSQLSCHEMA arg =>
        compileSchema arg
      | I.ICJOIN (bool, icexp1, icexp2, loc) =>
        I.ICJOIN (bool, compileExp icexp1, compileExp icexp2, loc)
      | I.ICDYNAMIC (icexp, ty, loc) =>
        I.ICDYNAMIC (compileExp icexp, ty, loc)
      | I.ICDYNAMICIS (icexp, ty, loc) =>
        I.ICDYNAMICIS (compileExp icexp, ty, loc)
      | I.ICDYNAMICNULL (ty, loc) => icexp
      | I.ICDYNAMICTOP (ty, loc) => icexp
      | I.ICDYNAMICVIEW (icexp, ty, loc) =>
        I.ICDYNAMICVIEW (compileExp icexp, ty, loc)
      | I.ICREIFYTY (ty, loc) => icexp

  and compileFFIFun ffiFun =
      case ffiFun of
        I.ICFFIFUN exp => I.ICFFIFUN (compileExp exp)
      | I.ICFFIEXTERN _ => ffiFun

  and compileRule {args: I.icpat list, body} =
      {args = args, body = compileExp body}

  and compileDynRule {tyvars, arg: I.icpat, body} =
      {tyvars = tyvars, arg = arg, body = compileExp body}

  and compileDecl icdecl =
      case icdecl of
        I.ICVAL (tvars, binds, loc) =>
        I.ICVAL (tvars,
                 map (fn (pat, exp) => (pat, compileExp exp)) binds,
                 loc)
      | I.ICVAL_OPAQUE_SIG {var, exp, ty, revealKey,  loc} =>
        I.ICVAL_OPAQUE_SIG 
          {var = var, exp = compileExp exp, ty = ty, revealKey = revealKey,  loc = loc}
      | I.ICVAL_TRANS_SIG {var, exp, ty, loc} =>
        I.ICVAL_TRANS_SIG  {var = var, exp = compileExp exp, ty = ty, loc = loc}
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
        val _ = UserErrorUtils.initializeErrorQueue ()
        val decls = map compileDecl decls
      in
        case UserErrorUtils.getErrors () of
          nil => decls
        | errors => raise UserError.UserErrors errors
      end

end
