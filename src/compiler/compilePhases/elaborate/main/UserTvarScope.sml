(**
 * determine the scope of user type variables.
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author UENO Katsuhiro
 *)
structure UserTvarScope =
struct
  structure A = Absyn
  structure S = AbsynSQL
  structure E = ElaborateError
  datatype loc = datatype Loc.loc

  type env = ElaborateTy.ftv
  val tyvarseqToSet = ElaborateTy.tyvarseqToSet
  val kindedTyvarseqToSet = ElaborateTy.kindedTyvarseqToSet
  val singleton = ElaborateTy.singleton
  val union = ElaborateTy.union
  val unionList = ElaborateTy.unionList
  val intersect = ElaborateTy.intersect
  val setMinus = ElaborateTy.setMinus
  val ftvKindedTyvarseq = ElaborateTy.ftvKindedTyvarseq
  val ftvTy = ElaborateTy.ftvTy
  val ftvTypbind = ElaborateTy.ftvTypbind
  val ftvDatbind = ElaborateTy.ftvDatbind

  val empty = Symbol.Map.empty

  fun ftvOpt ftvFn NONE = empty
    | ftvOpt ftvFn (SOME item) = ftvFn item

  fun ftvList ftvFn items =
      unionList (map ftvFn items)

  fun ftvFfiTy ffity =
      case ffity of
        A.FFITYVAR tyvar => singleton tyvar
      | A.FFITYRECORD (tyrows, loc) => ftvList ftvFfiTyrow tyrows
      | A.FFITYCON (tyseq, tycon, loc) => ftvOpt ftvFfiTyseq tyseq
      | A.FFITYTUPLE (tys, loc) => ftvList ftvFfiTy tys
      | A.FFITYFUN (attr, arg, ret, loc) => union (ftvFfiArg arg, ftvFfiRet ret)
      | A.FFITYPAREN (ty, loc) => ftvFfiTy ty

  and ftvFfiTyrow ((lab, ty, loc) : A.ffi_tyrow) =
      ftvFfiTy ty

  and ftvFfiTyseq ((tys, loc) : A.ffi_tyseq) =
      ftvList ftvFfiTy tys

  and ftvFfiArg ((tys1, tys2, loc) : A.ffi_arg) =
      union (ftvList ftvFfiTy tys1, ftvOpt (ftvList ftvFfiTy) tys2)

  and ftvFfiRet ((tys, loc) : A.ffi_ret) =
      ftvList ftvFfiTy tys

  fun ftvPat pat =
      case pat of
        A.PATWILD _ => empty
      | A.PATCONST _ => empty
      | A.PATID _ => empty
      | A.PATRECORD (patrows, flex, loc) => ftvList ftvPatrow patrows
      | A.PATTUPLE (pats, loc) => ftvList ftvPat pats
      | A.PATLIST (pats, loc) => ftvList ftvPat pats
      | A.PATPAREN (pat, loc) => ftvPat pat
      | A.PATAPP (pat1, pat2, loc) => union (ftvPat pat1, ftvPat pat2)
      | A.PATINFIX (pat1, vid, pat2, loc) => union (ftvPat pat1, ftvPat pat2)
      | A.PATTYPED (pat, ty, loc) => union (ftvPat pat, ftvTy ty)
      | A.PATAS (vid, ty, pat, loc) => union (ftvOpt ftvTy ty, ftvPat pat)

  and ftvPatrow patrow =
      case patrow of
        A.PATROW (lab, pat, loc) => ftvPat pat
      | A.PATROWVAR (vid, ty, pat, loc) =>
        union (ftvOpt ftvTy ty, ftvOpt ftvPat pat)

  fun ftvWithty ((typbinds, loc) : A.withty) =
      ftvList ftvTypbind typbinds

  fun ftvExbind exbind =
      case exbind of
        A.EXBIND (vid, ty, loc) => ftvOpt ftvTy ty
      | A.EXBINDREP _ => empty

  fun ftvSqlExp exp =
      case exp of
        S.EXP_EMBED (exp, loc) => ftvExp exp
      | S.CONST _ => empty
      | S.NULL _ => empty
      | S.TRUE _ => empty
      | S.FALSE _ => empty
      | S.COLUMN1 _ => empty
      | S.COLUMN2 _ => empty
      | S.KWEXP (prefix, kwexp, loc) => ftvSqlKwexp kwexp
      | S.EXP_SUBQUERY (prefix, query, loc) => ftvSqlQuery query
      | S.OP1 (oper, exp, loc) => ftvSqlExp exp
      | S.OP2 (oper, exp1, exp2, loc) => union (ftvSqlExp exp1, ftvSqlExp exp2)
      | S.ID _ => empty
      | S.PAREN (exp, loc) => ftvSqlExp exp
      | S.APP (exp1, exp2, loc) => union (ftvSqlExp exp1, ftvSqlExp exp2)
      | S.INFIX (exp1, vid, exp2, loc) => union (ftvSqlExp exp1, ftvSqlExp exp2)
      | S.CAST (vid, exp, loc) => ftvSqlExp exp
      | S.TUPLE (exps, loc) => ftvList ftvSqlExp exps

  and ftvSqlKwexp kwexp =
      case kwexp of
        S.EXISTS (query, loc) => ftvSqlQuery query

  and ftvSqlTable table =
      case table of
        S.TABLE _ => empty
      | S.TABLE_AS (table, lab, loc) => ftvSqlTable table
      | S.TABLE_INNER_JOIN (table1, inner, table2, exp, loc) =>
        union (union (ftvSqlTable table1, ftvSqlTable table2), ftvSqlExp exp)
      | S.TABLE_CROSS_JOIN (table1, table2, loc) =>
        union (ftvSqlTable table1, ftvSqlTable table2)
      | S.TABLE_NATURAL_JOIN (table1, table2, loc) =>
        union (ftvSqlTable table1, ftvSqlTable table2)
      | S.TABLE_SUBQUERY (prefix, query, loc) => ftvSqlQuery query
      | S.TABLE_PAREN (table, loc) => ftvSqlTable table

  and ftvSqlFrom from =
      case from of
        S.FROM (tables, loc) => ftvList ftvSqlTable tables
      | S.FROM_EMBED (exp, loc) => ftvExp exp

  and ftvSqlWhr whr =
      case whr of
        S.WHERE (exp, loc) => ftvSqlExp exp
      | S.WHERE_EMBED (exp, loc) => ftvExp exp

  and ftvSqlGroupby groupby =
      case groupby of
        S.GROUPBY (groupby, having, loc) =>
        union (ftvSqlGroupbyClause groupby, ftvOpt ftvSqlHavingClause having)

  and ftvSqlOrderby orderby =
      case orderby of
        S.ORDERBY (keys, loc) => ftvList ftvSqlOrderKey keys
      | S.ORDERBY_EMBED (exp, loc) => ftvExp exp

  and ftvSqlLimit limit =
      case limit of
        S.LIMIT (limit, offset, loc) =>
        union (ftvSqlLImitClause limit, ftvOpt ftvSqlLimitOffsetClause offset)
      | S.LIMIT_EMBED (exp, loc) => ftvExp exp

  and ftvSqlOffset offset =
      case offset of
        S.OFFSET (offset, fetch, loc) =>
        union (ftvSqlOffsetClause offset, ftvOpt ftvSqlFetchClause fetch)
      | S.OFFSET_EMBED (exp, loc) => ftvExp exp

  and ftvSqlSelect select =
      case select of
        S.SELECT (distinct, (rows, loc2), loc) => ftvList ftvSqlSelectRow rows
      | S.SELECT_EMBED (exp, loc) => ftvExp exp

  and ftvSqlQuery query =
      case query of
        S.QUERY (select, from, whr, groupby, orderby, offset, loc) =>
        unionList [ftvSqlSelect select,
                   ftvSqlFrom from,
                   ftvOpt ftvSqlWhr whr,
                   ftvOpt ftvSqlGroupby groupby,
                   ftvOpt ftvSqlOrderby orderby,
                   ftvOpt ftvSqlOffsetOrLimit offset]
      | S.QUERY_EMBED (exp, loc) => ftvExp exp

  and ftvSqlOffsetOrLimit clause =
      case clause of
        S.OFFSET_CLAUSE offset => ftvSqlOffset offset
      | S.LIMIT_CLAUSE limit => ftvSqlLimit limit

  and ftvSqlOrderKey ((exp, asc, loc) : A.exp S.order_key) =
      ftvSqlExp exp

  and ftvSqlSelectRow ((exp, lab, loc) : A.exp S.select_row) =
      ftvSqlExp exp

  and ftvSqlGroupbyClause ((exps, loc) : A.exp S.groupby_clause) =
      ftvList ftvSqlExp exps

  and ftvSqlHavingClause ((exp, loc) : A.exp S.having_clause) =
      ftvSqlExp exp

  and ftvSqlLImitClause ((exp, loc) : A.exp S.limit_clause) =
      ftvOpt ftvSqlExp exp

  and ftvSqlLimitOffsetClause ((exp, loc) : A.exp S.limit_offset_clause) =
      ftvSqlExp exp

  and ftvSqlOffsetClause ((exp, rows, loc) : A.exp S.offset_clause) =
      ftvSqlExp exp

  and ftvSqlFetchClause ((first, exp, rows, loc) : A.exp S.fetch_clause) =
      ftvOpt ftvSqlExp exp

  and ftvSqlInsertValue value =
      case value of
        S.VALUE exp => ftvSqlExp exp
      | S.DEFAULT _ => empty

  and ftvSqlInsertRow ((values, loc) : A.exp S.insert_row) =
      ftvList ftvSqlInsertValue values

  and ftvSqlInsertValues values =
      case values of
        S.INSERT_VALUES (rows, loc) => ftvList ftvSqlInsertRow rows
      | S.INSERT_VAR _ => empty
      | S.INSERT_SELECT query => ftvSqlQuery query

  and ftvSqlSetRow ((lab, exp, loc) : A.exp S.set_row) =
      ftvSqlExp exp

  and ftvSqlSet ((setrows, loc) : A.exp S.set) =
      ftvList ftvSqlSetRow setrows

  and ftvSqlCon con =
      case con of
        S.QRY query => ftvSqlQuery query
      | S.SEL select => ftvSqlSelect select
      | S.FRM from => ftvSqlFrom from
      | S.WHR whr => ftvSqlWhr whr
      | S.ORD orderby => ftvSqlOrderby orderby
      | S.OFF offset => ftvSqlOffset offset
      | S.LMT limit => ftvSqlLimit limit
      | S.INSERT_LABELED (table, labels, values, loc) =>
        ftvSqlInsertValues values
      | S.INSERT_NOLABEL (table, query, loc) => ftvSqlQuery query
      | S.UPDATE (table, set, whr, loc) =>
        union (ftvSqlSet set, ftvOpt ftvSqlWhr whr)
      | S.DELETE (table, whr, loc) => ftvOpt ftvSqlWhr whr
      | S.BEGIN _ => empty
      | S.COMMIT _ => empty
      | S.ROLLBACK _ => empty

  and ftvSqlStep step =
      case step of
        S.STEP (prefix, con, loc) => ftvSqlCon con
      | S.STEP_EMBED (exp, loc) => ftvExp exp

  and ftvSqlBody body =
      case body of
        S.CON (prefix, con, loc) => ftvSqlCon con
      | S.EXP exp => ftvSqlExp exp
      | S.SEQ (steps, loc) => ftvList ftvSqlStep steps
      | S.BODYPAREN (body, loc) => ftvSqlBody body

  and ftvSqlTop sqlexp =
      case sqlexp of
        S.SQLSERVER (exp, ty, loc) => union (ftvOpt ftvExp exp, ftvTy ty)
      | S.SQL (sql, loc) => ftvSqlBody sql
      | S.SQLFN (pat, sql, loc) => union (ftvPat pat, ftvSqlBody sql)

  and ftvExp exp =
      case exp of
        A.EXPCONST _ => empty
      | A.EXPID _ => empty
      | A.EXPRECORD (exprows, loc) => ftvList ftvExprow exprows
      | A.EXPSELECT _ => empty
      | A.EXPTUPLE (exps, loc) => ftvList ftvExp exps
      | A.EXPLIST (exps, loc) => ftvList ftvExp exps
      | A.EXPSEQ (exps, loc) => ftvList ftvExp exps
      | A.EXPLET (decs, (exps, loc1), loc) =>
        union (ftvList ftvDec decs, ftvList ftvExp exps)
      | A.EXPPAREN (exp, loc) => ftvExp exp
      | A.EXPAPP (exp1, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPINFIX (exp1, vid, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPTYPED (exp, ty, loc) => union (ftvExp exp, ftvTy ty)
      | A.EXPANDALSO (exp1, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPORELSE (exp1, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPHANDLE (exp, mrules, loc) =>
        union (ftvExp exp, ftvList ftvMrule mrules)
      | A.EXPRAISE (exp, loc) => ftvExp exp
      | A.EXPIF (exp1, exp2, exp3, loc) =>
        union (union (ftvExp exp1, ftvExp exp2), ftvExp exp3)
      | A.EXPWHILE (exp1, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPCASE (exp, mrules, loc) =>
        union (ftvExp exp, ftvList ftvMrule mrules)
      | A.EXPFN (mrules, loc) => ftvList ftvMrule mrules
      | A.EXPSIZEOF (ty, loc) => ftvTy ty
      | A.EXPRECORD_UPDATE (exp, exprows, loc) =>
        union (ftvExp exp, ftvList ftvExprow exprows)
      | A.EXPTUPLE_UPDATE (exp, exps, loc) =>
        union (ftvExp exp, ftvList ftvExp exps)
      | A.EXPIMPORT_NAME (name, ty, loc) => ftvFfiTy ty
      | A.EXPIMPORT_EXP (exp, ty, loc) => union (ftvExp exp, ftvFfiTy ty)
      | A.EXPSQL sqlexp => ftvSqlTop sqlexp
      | A.EXPFOREACH_DATA (vid, exp1, exp2, pat, exp3, exp4, loc) =>
        unionList [ftvExp exp1, ftvExp exp2, ftvPat pat,
                   ftvExp exp3, ftvExp exp4]
      | A.EXPFOREACH_ARRAY (vid, exp1, pat, exp2, exp3, loc) =>
        unionList [ftvExp exp1, ftvPat pat, ftvExp exp2, ftvExp exp3]
      | A.EXPJOIN (exp1, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPEXTEND (exp1, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPUPDATE1 (exp1, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPUPDATE2 (exp1, exp2, loc) => union (ftvExp exp1, ftvExp exp2)
      | A.EXPDYNAMIC_AS (exp, ty, loc) => union (ftvExp exp, ftvTy ty)
      | A.EXPDYNAMIC_OF (exp, ty, loc) => union (ftvExp exp, ftvTy ty)
      | A.EXPDYNAMICVIEW (exp, ty, loc) => union (ftvExp exp, ftvTy ty)
      | A.EXPDYNAMICNULL (ty, loc) => ftvTy ty
      | A.EXPDYNAMICTOP (ty, loc) => ftvTy ty
      | A.EXPDYNAMICCASE (exp, mrules, loc) =>
        union (ftvExp exp, ftvList ftvDynamicMrule mrules)
      | A.EXPREIFYTY (ty, loc) => ftvTy ty

  and ftvValbind valbind =
      case valbind of
        A.VALBIND (pat, exp, loc) => union (ftvPat pat, ftvExp exp)
      | A.VALREC (valbinds, loc) => ftvList ftvValbind valbinds

  and ftvValrecbind (pat, exp, loc) =
      union (ftvPat pat, ftvExp exp)

  and ftvDec dec =
      case dec of
        A.DECVAL _ => empty (* guard point *)
      | A.DECVALREC _ => empty (* guard point *)
      | A.DECFUN _ => empty (* guard point *)
      | A.DECTYPE (typbinds, loc) => ftvList ftvTypbind typbinds
      | A.DECDATATYPE (datbinds, withty, loc) =>
        union (ftvList ftvDatbind datbinds, ftvOpt ftvWithty withty)
      | A.DECDATATYPEREP _ => empty
      | A.DECABSTYPE (datbinds, withty, decs, loc) =>
        union (union (ftvList ftvDatbind datbinds, ftvOpt ftvWithty withty),
               ftvList ftvDec decs)
      | A.DECEXCEPTION (exbinds, loc) => ftvList ftvExbind exbinds
      | A.DECLOCAL (decs1, decs2, loc) =>
        union (ftvList ftvDec decs1, ftvList ftvDec decs2)
      | A.DECOPEN _ => empty
      | A.DECSEMICOLON _ => empty
      | A.DECINFIX _ => empty
      | A.DECINFIXR _ => empty
      | A.DECNONFIX _ => empty
      | A.DECDO (exp, loc) => ftvExp exp

  and ftvExprow exprow =
      case exprow of
        A.EXPROW (lab, exp, loc) => ftvExp exp
      | A.EXPROWVAR (vid, ty, loc) => ftvOpt ftvTy ty

  and ftvMrule ((pat, exp, loc) : A.mrule) =
      union (ftvPat pat, ftvExp exp)

  and ftvDynamicMrule ((exists, pat, exp, loc) : A.dynamic_mrule) =
      setMinus (union (ftvPat pat, ftvExp exp), kindedTyvarseqToSet exists)

  and ftvFrule ((pat, ty, exp, loc) : A.frule) =
      union (union (ftvPat pat, ftvOpt ftvTy ty), ftvExp exp)

  and ftvFvalbind ((frules, loc) : A.fvalbind) =
      ftvList ftvFrule frules

  fun decideScope ftvFn env (tyvarseq, items, loc) =
      let
        val explicitlyScoped = kindedTyvarseqToSet tyvarseq
        val _ =
            Symbol.Map.app
              (fn (tv as (_, (_, loc)), _) =>
                  UserErrorUtils.enqueueError
                    (LOC loc, E.UserTvarScopedAtOuterDecl tv))
              (intersect (explicitlyScoped, env))
        val unguarded1 = ftvKindedTyvarseq tyvarseq
        val unguarded2 = ftvList ftvFn items
        val unguarded = setMinus (union (unguarded1, unguarded2), env)
        val implicitlyScoped = setMinus (unguarded, explicitlyScoped)
        val tyvars = ElaborateTy.toKindedTyvars implicitlyScoped
        val tyvarseq = ElaborateTy.appendTyvarseq (tyvarseq, tyvars)
        val env = union (env, union (explicitlyScoped, implicitlyScoped))
      in
        (env, tyvarseq)
      end

  fun decideSqlExp env exp =
      case exp of
        S.EXP_EMBED (exp, loc) =>
        S.EXP_EMBED (decideExp env exp, loc)
      | S.CONST _ => exp
      | S.NULL _ => exp
      | S.TRUE _ => exp
      | S.FALSE _ => exp
      | S.COLUMN1 _ => exp
      | S.COLUMN2 _ => exp
      | S.KWEXP (prefix, kwexp, loc) =>
        S.KWEXP (prefix, decideSqlKwexp env kwexp, loc)
      | S.EXP_SUBQUERY (prefix, query, loc) =>
        S.EXP_SUBQUERY (prefix, decideSqlQuery env query, loc)
      | S.OP1 (oper, exp, loc) =>
        S.OP1 (oper, decideSqlExp env exp, loc)
      | S.OP2 (oper, exp1, exp2, loc) =>
        S.OP2 (oper, decideSqlExp env exp1, decideSqlExp env exp2, loc)
      | S.ID _ => exp
      | S.PAREN (exp, loc) =>
        S.PAREN (decideSqlExp env exp, loc)
      | S.APP (exp1, exp2, loc) =>
        S.APP (decideSqlExp env exp1, decideSqlExp env exp2, loc)
      | S.INFIX (exp1, vid, exp2, loc) =>
        S.INFIX (decideSqlExp env exp1, vid, decideSqlExp env exp2, loc)
      | S.CAST (vid, exp, loc) =>
        S.CAST (vid, decideSqlExp env exp, loc)
      | S.TUPLE (exps, loc) =>
        S.TUPLE (map (decideSqlExp env) exps, loc)

  and decideSqlKwexp env kwexp =
      case kwexp of
        S.EXISTS (query, loc) =>
        S.EXISTS (decideSqlQuery env query, loc)

  and decideSqlTable env table =
      case table of
        S.TABLE _ => table
      | S.TABLE_AS (table, lab, loc) =>
        S.TABLE_AS (decideSqlTable env table, lab, loc)
      | S.TABLE_INNER_JOIN (table1, inner, table2, exp, loc) =>
        S.TABLE_INNER_JOIN (decideSqlTable env table1,
                            inner,
                            decideSqlTable env table2,
                            decideSqlExp env exp,
                            loc)
      | S.TABLE_CROSS_JOIN (table1, table2, loc) =>
        S.TABLE_CROSS_JOIN (decideSqlTable env table1,
                            decideSqlTable env table2,
                            loc)
      | S.TABLE_NATURAL_JOIN (table1, table2, loc) =>
        S.TABLE_NATURAL_JOIN (decideSqlTable env table1,
                              decideSqlTable env table2,
                              loc)
      | S.TABLE_SUBQUERY (prefix, query, loc) =>
        S.TABLE_SUBQUERY (prefix, decideSqlQuery env query, loc)
      | S.TABLE_PAREN (table, loc) =>
        S.TABLE_PAREN (decideSqlTable env table, loc)

  and decideSqlFrom env from =
      case from of
        S.FROM (tables, loc) =>
        S.FROM (map (decideSqlTable env) tables, loc)
      | S.FROM_EMBED (exp, loc) =>
        S.FROM_EMBED (decideExp env exp, loc)

  and decideSqlWhr env whr =
      case whr of
        S.WHERE (exp, loc) =>
        S.WHERE (decideSqlExp env exp, loc)
      | S.WHERE_EMBED (exp, loc) =>
        S.WHERE_EMBED (decideExp env exp, loc)

  and decideSqlGroupby env groupby =
      case groupby of
        S.GROUPBY (groupby, having, loc) =>
        S.GROUPBY (decideSqlGroupbyClause env groupby,
                   Option.map (decideSqlHavingClause env) having,
                   loc)

  and decideSqlOrderby env orderby =
      case orderby of
        S.ORDERBY (keys, loc) =>
        S.ORDERBY (map (decideSqlOrderKey env) keys, loc)
      | S.ORDERBY_EMBED (exp, loc) =>
        S.ORDERBY_EMBED (decideExp env exp, loc)

  and decideSqlLimit env limit =
      case limit of
        S.LIMIT (limit, offset, loc) =>
        S.LIMIT (decideSqlLImitClause env limit,
                 Option.map (decideSqlLimitOffsetClause env) offset,
                 loc)
      | S.LIMIT_EMBED (exp, loc) =>
        S.LIMIT_EMBED (decideExp env exp, loc)

  and decideSqlOffset env offset =
      case offset of
        S.OFFSET (offset, fetch, loc) =>
        S.OFFSET (decideSqlOffsetClause env offset,
                  Option.map (decideSqlFetchClause env) fetch,
                  loc)
      | S.OFFSET_EMBED (exp, loc) =>
        S.OFFSET_EMBED (decideExp env exp, loc)

  and decideSqlSelect env select =
      case select of
        S.SELECT (distinct, (rows, loc2), loc) =>
        S.SELECT (distinct, (map (decideSqlSelectRow env) rows, loc2), loc)
      | S.SELECT_EMBED (exp, loc) =>
        S.SELECT_EMBED (decideExp env exp, loc)

  and decideSqlQuery env query =
      case query of
        S.QUERY (select, from, whr, groupby, orderby, offset, loc) =>
        S.QUERY (decideSqlSelect env select,
                 decideSqlFrom env from,
                 Option.map (decideSqlWhr env) whr,
                 Option.map (decideSqlGroupby env) groupby,
                 Option.map (decideSqlOrderby env) orderby,
                 Option.map (decideSqlOffsetOrLimit env) offset,
                 loc)
      | S.QUERY_EMBED (exp, loc) =>
        S.QUERY_EMBED (decideExp env exp, loc)

  and decideSqlOffsetOrLimit env clause =
      case clause of
        S.OFFSET_CLAUSE offset =>
        S.OFFSET_CLAUSE (decideSqlOffset env offset)
      | S.LIMIT_CLAUSE limit =>
        S.LIMIT_CLAUSE (decideSqlLimit env limit)

  and decideSqlOrderKey env (exp, asc, loc) : A.exp S.order_key =
      (decideSqlExp env exp, asc, loc)

  and decideSqlSelectRow env (exp, lab, loc) : A.exp S.select_row =
      (decideSqlExp env exp, lab, loc)

  and decideSqlGroupbyClause env (exps, loc) : A.exp S.groupby_clause =
      (map (decideSqlExp env) exps, loc)

  and decideSqlHavingClause env (exp, loc) : A.exp S.having_clause =
      (decideSqlExp env exp, loc)

  and decideSqlLImitClause env (exp, loc) : A.exp S.limit_clause =
      (Option.map (decideSqlExp env) exp, loc)

  and decideSqlLimitOffsetClause env (exp, loc) : A.exp S.limit_offset_clause =
      (decideSqlExp env exp, loc)

  and decideSqlOffsetClause env (exp, rows, loc) : A.exp S.offset_clause =
      (decideSqlExp env exp, rows, loc)

  and decideSqlFetchClause env (first, exp, rows, loc) : A.exp S.fetch_clause =
      (first, Option.map (decideSqlExp env) exp, rows, loc)

  and decideSqlInsertValue env value =
      case value of
        S.VALUE exp => S.VALUE (decideSqlExp env exp)
      | S.DEFAULT _ => value

  and decideSqlInsertRow env (values, loc) : A.exp S.insert_row =
      (map (decideSqlInsertValue env) values, loc)

  and decideSqlInsertValues env values =
      case values of
        S.INSERT_VALUES (rows, loc) =>
        S.INSERT_VALUES (map (decideSqlInsertRow env) rows, loc)
      | S.INSERT_VAR _ => values
      | S.INSERT_SELECT query =>
        S.INSERT_SELECT (decideSqlQuery env query)

  and decideSqlSetRow env (lab, exp, loc) : A.exp S.set_row =
      (lab, decideSqlExp env exp, loc)

  and decideSqlSet env (setrows, loc) : A.exp S.set =
      (map (decideSqlSetRow env) setrows, loc)

  and decideSqlCon env con =
      case con of
        S.QRY query =>
        S.QRY (decideSqlQuery env query)
      | S.SEL select =>
        S.SEL (decideSqlSelect env select)
      | S.FRM from =>
        S.FRM (decideSqlFrom env from)
      | S.WHR whr =>
        S.WHR (decideSqlWhr env whr)
      | S.ORD orderby =>
        S.ORD (decideSqlOrderby env orderby)
      | S.OFF offset =>
        S.OFF (decideSqlOffset env offset)
      | S.LMT limit =>
        S.LMT (decideSqlLimit env limit)
      | S.INSERT_LABELED (table, labels, values, loc) =>
        S.INSERT_LABELED
          (table, labels, decideSqlInsertValues env values, loc)
      | S.INSERT_NOLABEL (table, query, loc) =>
        S.INSERT_NOLABEL (table, decideSqlQuery env query, loc)
      | S.UPDATE (table, set, whr, loc) =>
        S.UPDATE (table,
                  decideSqlSet env set,
                  Option.map (decideSqlWhr env) whr,
                  loc)
      | S.DELETE (table, whr, loc) =>
        S.DELETE (table, Option.map (decideSqlWhr env) whr, loc)
      | S.BEGIN _ => con
      | S.COMMIT _ => con
      | S.ROLLBACK _ => con

  and decideSqlStep env step =
      case step of
        S.STEP (prefix, con, loc) =>
        S.STEP (prefix, decideSqlCon env con, loc)
      | S.STEP_EMBED (exp, loc) =>
        S.STEP_EMBED (decideExp env exp, loc)

  and decideSqlBody env body =
      case body of
        S.CON (prefix, con, loc) =>
        S.CON (prefix, decideSqlCon env con, loc)
      | S.EXP exp =>
        S.EXP (decideSqlExp env exp)
      | S.SEQ (steps, loc) =>
        S.SEQ (map (decideSqlStep env) steps, loc)
      | S.BODYPAREN (body, loc) =>
        S.BODYPAREN (decideSqlBody env body, loc)

  and decideSqlTop env sqlexp =
      case sqlexp of
        S.SQLSERVER (exp, ty, loc) =>
        S.SQLSERVER (Option.map (decideExp env) exp, ty, loc)
      | S.SQL (sql, loc) =>
        S.SQL (decideSqlBody env sql, loc)
      | S.SQLFN (pat, sql, loc) =>
        S.SQLFN (pat, decideSqlBody env sql, loc)

  and decideExp env exp =
      case exp of
        A.EXPCONST _ => exp
      | A.EXPID _ => exp
      | A.EXPRECORD (exprows, loc) =>
        A.EXPRECORD (map (decideExprow env) exprows, loc)
      | A.EXPSELECT _ => exp
      | A.EXPTUPLE (exps, loc) =>
        A.EXPTUPLE (map (decideExp env) exps, loc)
      | A.EXPLIST (exps, loc) =>
        A.EXPLIST (map (decideExp env) exps, loc)
      | A.EXPSEQ (exps, loc) =>
        A.EXPSEQ (map (decideExp env) exps, loc)
      | A.EXPLET (decs, (exps, loc1), loc) =>
        A.EXPLET
          (map (decideDec env) decs, (map (decideExp env) exps, loc1), loc)
      | A.EXPPAREN (exp, loc) =>
        A.EXPPAREN (decideExp env exp, loc)
      | A.EXPAPP (exp1, exp2, loc) =>
        A.EXPAPP (decideExp env exp1, decideExp env exp2, loc)
      | A.EXPINFIX (exp1, vid, exp2, loc) =>
        A.EXPINFIX (decideExp env exp1, vid, decideExp env exp2, loc)
      | A.EXPTYPED (exp, ty, loc) =>
        A.EXPTYPED (decideExp env exp, ty, loc)
      | A.EXPANDALSO (exp1, exp2, loc) =>
        A.EXPANDALSO (decideExp env exp1, decideExp env exp2, loc)
      | A.EXPORELSE (exp1, exp2, loc) =>
        A.EXPORELSE (decideExp env exp1, decideExp env exp2, loc)
      | A.EXPHANDLE (exp, mrules, loc) =>
        A.EXPHANDLE (decideExp env exp, map (decideMrule env) mrules, loc)
      | A.EXPRAISE (exp, loc) =>
        A.EXPRAISE (decideExp env exp, loc)
      | A.EXPIF (exp1, exp2, exp3, loc) =>
        A.EXPIF (decideExp env exp1,
                 decideExp env exp2,
                 decideExp env exp3,
                 loc)
      | A.EXPWHILE (exp1, exp2, loc) =>
        A.EXPWHILE (decideExp env exp1, decideExp env exp2, loc)
      | A.EXPCASE (exp, mrules, loc) =>
        A.EXPCASE (decideExp env exp, map (decideMrule env) mrules, loc)
      | A.EXPFN (mrules, loc) =>
        A.EXPFN (map (decideMrule env) mrules, loc)
      | A.EXPSIZEOF _ => exp
      | A.EXPRECORD_UPDATE (exp, exprows, loc) =>
        A.EXPRECORD_UPDATE (decideExp env exp,
                            map (decideExprow env) exprows,
                            loc)
      | A.EXPTUPLE_UPDATE (exp, exps, loc) =>
        A.EXPTUPLE_UPDATE (decideExp env exp, map (decideExp env) exps, loc)
      | A.EXPIMPORT_NAME _ => exp
      | A.EXPIMPORT_EXP (exp, ffity, loc) =>
        A.EXPIMPORT_EXP (decideExp env exp, ffity, loc)
      | A.EXPSQL sqlexp =>
        A.EXPSQL (decideSqlTop env sqlexp)
      | A.EXPFOREACH_DATA (vid, exp1, exp2, pat, exp3, exp4, loc) =>
        A.EXPFOREACH_DATA (vid,
                           decideExp env exp1,
                           decideExp env exp2,
                           pat,
                           decideExp env exp3,
                           decideExp env exp4,
                           loc)
      | A.EXPFOREACH_ARRAY (vid, exp1, pat, exp2, exp3, loc) =>
        A.EXPFOREACH_ARRAY (vid,
                            decideExp env exp1,
                            pat,
                            decideExp env exp2,
                            decideExp env exp3,
                            loc)
      | A.EXPJOIN (exp1, exp2, loc) =>
        A.EXPJOIN (decideExp env exp1, decideExp env exp2, loc)
      | A.EXPEXTEND (exp1, exp2, loc) =>
        A.EXPEXTEND (decideExp env exp1, decideExp env exp2, loc)
      | A.EXPUPDATE1 (exp1, exp2, loc) =>
        A.EXPUPDATE1 (decideExp env exp1, decideExp env exp2, loc)
      | A.EXPUPDATE2 (exp1, exp2, loc) =>
        A.EXPUPDATE2 (decideExp env exp1, decideExp env exp2, loc)
      | A.EXPDYNAMIC_AS (exp, ty, loc) =>
        A.EXPDYNAMIC_AS (decideExp env exp, ty, loc)
      | A.EXPDYNAMIC_OF (exp, ty, loc) =>
        A.EXPDYNAMIC_OF (decideExp env exp, ty, loc)
      | A.EXPDYNAMICVIEW (exp, ty, loc) =>
        A.EXPDYNAMICVIEW (decideExp env exp, ty, loc)
      | A.EXPDYNAMICNULL _ => exp
      | A.EXPDYNAMICTOP _ => exp
      | A.EXPDYNAMICCASE (exp, mrules, loc) =>
        A.EXPDYNAMICCASE (decideExp env exp,
                          map (decideDynamicMrule env) mrules,
                          loc)
      | A.EXPREIFYTY _ => exp

  and decideValbind env valbind =
      case valbind of
        A.VALBIND (pat, exp, loc) =>
        A.VALBIND (pat, decideExp env exp, loc)
      | A.VALREC (valbinds, loc) =>
        A.VALREC (map (decideValbind env) valbinds, loc)

  and decideValrecbind env (pat, exp, loc) =
      (pat, decideExp env exp, loc)

  and decideDec env dec =
      case dec of
        A.DECVAL (decl as (tyvarseq, valbinds, loc)) =>
        let
          val (env, tyvarseq) = decideScope ftvValbind env decl
        in
          A.DECVAL (tyvarseq, map (decideValbind env) valbinds, loc)
        end
      | A.DECVALREC (decl as (tyvarseq, valrecbinds, loc)) =>
        let
          val (env, tyvarseq) = decideScope ftvValrecbind env decl
        in
          A.DECVALREC (tyvarseq, map (decideValrecbind env) valrecbinds, loc)
        end
      | A.DECFUN (decl as (tyvars, fvalbinds, loc)) =>
        let
          val (env, tyvarseq) = decideScope ftvFvalbind env decl
        in
          A.DECFUN (tyvarseq, map (decideFvalbind env) fvalbinds, loc)
        end
      | A.DECTYPE _ => dec
      | A.DECDATATYPE _ => dec
      | A.DECDATATYPEREP _ => dec
      | A.DECABSTYPE (datbinds, withty, decs, loc) =>
        A.DECABSTYPE (datbinds, withty, map (decideDec env) decs, loc)
      | A.DECEXCEPTION _ => dec
      | A.DECLOCAL (decs1, decs2, loc) =>
        A.DECLOCAL
          (map (decideDec env) decs1, map (decideDec env) decs2, loc)
      | A.DECOPEN _ => dec
      | A.DECSEMICOLON _ => dec
      | A.DECINFIX _ => dec
      | A.DECINFIXR _ => dec
      | A.DECNONFIX _ => dec
      | A.DECDO (exp, loc) =>
        A.DECDO (decideExp env exp, loc)

  and decideExprow env exprow =
      case exprow of
        A.EXPROW (lab, exp, loc) =>
        A.EXPROW (lab, decideExp env exp, loc)
      | A.EXPROWVAR _ => exprow

  and decideMrule env (pat, exp, loc) : A.mrule =
      (pat, decideExp env exp, loc)

  and decideDynamicMrule env (exists, pat, exp, loc) : A.dynamic_mrule =
      (exists, pat, decideExp env exp, loc)

  and decideFrule env (pat, ty, exp, loc) : A.frule =
      (pat, ty, decideExp env exp, loc)

  and decideFvalbind env (frules, loc) : A.fvalbind =
      (map (decideFrule env) frules, loc)

  fun decideStrexp strexp =
      case strexp of
        A.STRBASIC (strdecs, loc) =>
        A.STRBASIC (map decideStrdec strdecs, loc)
      | A.STRID _ => strexp
      | A.STRCONSTRAINT (strexp, sigcon, loc) =>
        A.STRCONSTRAINT (decideStrexp strexp, sigcon, loc)
      | A.STRAPP (funid, funarg, loc) =>
        A.STRAPP (funid, Option.map decideFunarg funarg, loc)
      | A.STRLET (strdecs, strexp, loc) =>
        A.STRLET (map decideStrdec strdecs, decideStrexp strexp, loc)

  and decideStrdec strdec =
      case strdec of
        A.STRDEC dec =>
        A.STRDEC (decideDec empty dec)
      | A.STRUCTURE (strbinds, loc) =>
        A.STRUCTURE (map decideStrbind strbinds, loc)
      | A.STRLOCAL (strdecs1, strdecs2, loc) =>
        A.STRLOCAL (map decideStrdec strdecs1, map decideStrdec strdecs2, loc)
      | A.STRSEMICOLON _ => strdec

  and decideFunarg funarg =
      case funarg of
        A.FUNARG strexp =>
        A.FUNARG (decideStrexp strexp)
      | A.FUNARG_DEC (strdecs, loc) =>
        A.FUNARG_DEC (map decideStrdec strdecs, loc)

  and decideStrbind (strid, sigcon, strexp, loc) : A.strbind =
      (strid, sigcon, decideStrexp strexp, loc)

  fun decideFunbind (funid, param, sigcon, strexp, loc) : A.funbind =
      (funid, param, sigcon, decideStrexp strexp, loc)

  fun decideTopdec topdec =
      case topdec of
        A.TOPSTRDEC strdec =>
        A.TOPSTRDEC (decideStrdec strdec)
      | A.TOPSIGNATURE _ => topdec
      | A.TOPFUNCTOR (funbinds, loc) =>
        A.TOPFUNCTOR (map decideFunbind funbinds, loc)
      | A.TOPEXP (exp, loc) =>
        A.TOPEXP (decideExp empty exp, loc)

  fun decideTopdecs topdecs =
      map decideTopdec topdecs

  fun decideTop top =
      case top of
        A.TOPDEC (topdecs, loc) =>
        A.TOPDEC (decideTopdecs topdecs, loc)
      | A.USE _ => top
      | A.U_USE _ => top
      | A.TOPSEMICOLON _ => top

  fun decideTops tops =
      map decideTop tops

  fun decideCompileUnit ((interface, tops, loc) : A.compile_unit) =
      (interface, decideTops tops, loc)

end
