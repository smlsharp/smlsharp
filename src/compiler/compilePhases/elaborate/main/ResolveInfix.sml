(**
 * @copyright (C) 2025 SML# Development Team.
 * @author Katsuhiro Ueno
 *)
structure ResolveInfix =
struct
  structure A = Absyn
  structure S = AbsynSQL
  structure F = Fixity
  structure E = ElaborateError

  type env = (Fixity.fixity * Absyn.loc) Symbol.Map.map

  fun extendEnv (env1 : env, env2 : env) : env =
      Symbol.Map.unionWith #2 (env1, env2)

  val emptyEnv = Symbol.Map.empty : env

  fun resolveList resolve env items =
      CompileUtils.compileList
        {extend = extendEnv, accum = extendEnv, empty = emptyEnv}
        resolve
        env
        items

  fun resolveFixity con loc NONE = con 0
    | resolveFixity con loc (SOME "0") = con 0
    | resolveFixity con loc (SOME "1") = con 1
    | resolveFixity con loc (SOME "2") = con 2
    | resolveFixity con loc (SOME "3") = con 3
    | resolveFixity con loc (SOME "4") = con 4
    | resolveFixity con loc (SOME "5") = con 5
    | resolveFixity con loc (SOME "6") = con 6
    | resolveFixity con loc (SOME "7") = con 7
    | resolveFixity con loc (SOME "8") = con 8
    | resolveFixity con loc (SOME "9") = con 9
    | resolveFixity con loc (SOME n) =
      (UserErrorUtils.enqueueError (Loc.LOC loc, E.InvalidFixityPrecedence);
       con (getOpt (Int.fromString n, 0)))

  fun makeEnv fixity vids =
      foldl
        (fn ((id, loc), env) => Symbol.Map.insert (env, id, (fixity, loc)))
        emptyEnv
        vids

  fun sqlEnv env loc =
      let
        val env =
            Symbol.Map.insert (env, Symbol.intern "like", (F.INFIX 5, loc))
        val env =
            Symbol.Map.insert (env, Symbol.intern "||", (F.INFIX 5, loc))
        val env =
            Symbol.Map.insert (env, Symbol.intern "%", (F.INFIX 7, loc))
        val env =
            Symbol.Map.insert (env, Symbol.intern "mod", (F.NONFIX, loc))
      in
        env
      end

  fun fixityError getId error =
      let
        fun idOf exp =
            case getId exp of
              NONE => raise Bug.Bug "fixityError"
            | SOME (id, _) => id
      in
        case error of
          F.BeginWithInfix (exp, loc) =>
          UserErrorUtils.enqueueError
            (Loc.LOC loc, E.BeginWithInfixID (idOf exp))
        | F.EndWithInfix (exp, loc) =>
          UserErrorUtils.enqueueError
            (Loc.LOC loc, E.EndWithInfixID (idOf exp))
        | F.Conflict ((left, loc1), (right, loc2)) =>
          UserErrorUtils.enqueueError
            (Loc.LOC (Loc.mergeRange (loc1, loc2)),
             E.InvalidOpAssociativity (idOf left, idOf right))
      end

  fun find env NONE = F.NONFIX
    | find env (SOME (symbol, _)) =
      case Symbol.Map.find (env, symbol) of
        NONE => F.NONFIX
      | SOME (fixity, loc) => fixity

  fun mustBeNonfix env NONE = ()
    | mustBeNonfix env (id as SOME (symbol, loc)) =
      case find env id of
        F.NONFIX => ()
      | F.INFIX _ =>
        UserErrorUtils.enqueueError
          (Loc.LOC loc, E.BeginWithInfixID symbol)
      | F.INFIXR _ =>
        UserErrorUtils.enqueueError
          (Loc.LOC loc, E.BeginWithInfixID symbol)

  fun patVid (A.PATID (false, (nil, id, _), _)) = SOME id
    | patVid _ = NONE

  fun expVid (A.EXPID (false, (nil, id, _), _)) = SOME id
    | expVid _ = NONE

  fun sqlexpVid (S.ID (false, (nil, id, _), _)) = SOME id
    | sqlexpVid _ = NONE

  fun patToTerm env pat =
      (find env (patVid pat), pat, AbsynUtils.patLoc pat)

  fun expToTerm env exp =
      (find env (expVid exp), exp, AbsynUtils.expLoc exp)

  fun sqlexpToTerm env exp =
      (find env (sqlexpVid exp), exp, AbsynUtils.sqlExpLoc exp)

  fun patappSpine (A.PATAPP (pat1, pat2, _)) r = patappSpine pat1 (pat2 :: r)
    | patappSpine pat r = pat :: r

  fun expappSpine (A.EXPAPP (exp1, exp2, _)) r = expappSpine exp1 (exp2 :: r)
    | expappSpine exp r = exp :: r

  fun sqlappSpine (S.APP (exp1, exp2, _)) r = sqlappSpine exp1 (exp2 :: r)
    | sqlappSpine exp r = exp :: r

  fun fexpSpine (F.APP (exp1, exp2, _)) r = fexpSpine exp1 (exp2 :: r)
    | fexpSpine exp r = exp :: r

  fun resolvePatFexp env exp =
      case exp of
        F.TERM (pat as A.PATID (false, (nil, id, _), _), _) => pat
      | F.TERM (pat, _) =>
        resolvePat env pat
      | F.APP (exp1, exp2, loc) =>
        A.PATAPP (resolvePatFexp env exp1, resolvePatFexp env exp2, loc)
      | F.OP2 (F.TERM (A.PATID (false, (nil, id, _), _), _),
               (exp1, exp2),
               loc) =>
        A.PATINFIX (resolvePatFexp env exp1, id, resolvePatFexp env exp2, loc)
      | F.OP2 _ => raise Bug.Bug "resolvePatFexp"

  and resolvePat env pat =
      case pat of
        A.PATWILD _ => pat
      | A.PATCONST _ => pat
      | A.PATID _ => (mustBeNonfix env (patVid pat); pat)
      | A.PATRECORD (patrows, flex, loc) =>
        A.PATRECORD (map (resolvePatrow env) patrows, flex, loc)
      | A.PATTUPLE (pats, loc) =>
        A.PATTUPLE (map (resolvePat env) pats, loc)
      | A.PATLIST (pats, loc) =>
        A.PATLIST (map (resolvePat env) pats, loc)
      | A.PATPAREN (pat, loc) =>
        A.PATPAREN (resolvePat env pat, loc)
      | A.PATAPP (pat1, pat2, loc) =>
        let
          val terms = map (patToTerm env) (patappSpine pat1 [pat2])
        in
          resolvePatFexp env (Fixity.parse (fixityError patVid) terms)
        end
      | A.PATINFIX (pat1, vid, pat2, loc) =>
        A.PATINFIX (resolvePat env pat1, vid, resolvePat env pat2, loc)
      | A.PATTYPED (pat, ty, loc) =>
        A.PATTYPED (resolvePat env pat, ty, loc)
      | A.PATAS (vid, ty, pat, loc) =>
        A.PATAS (vid, ty, resolvePat env pat, loc)

  and resolvePatrow env patrow =
      case patrow of
        A.PATROW (lab, pat, loc) =>
        A.PATROW (lab, resolvePat env pat, loc)
      | A.PATROWVAR (vid, ty, pat, loc) =>
        A.PATROWVAR (vid, ty, Option.map (resolvePat env) pat, loc)

  fun resolveSqlFexpApp env head nil = head
    | resolveSqlFexpApp env head (exp :: exps) =
      let
        val exp = resolveSqlFexp env exp
        val loc1 = AbsynUtils.sqlExpLoc head
        val loc2 = AbsynUtils.sqlExpLoc exp
        val loc = Loc.mergeRange (loc1, loc2)
      in
        resolveSqlFexpApp env (S.APP (head, exp, loc)) exps
      end

  and resolveSqlFexpSpine env exps =
      case exps of
        F.TERM (S.PAREN (S.ID (false, (nil, id, _), _), _), loc)
        :: (exps as _ :: _) =>
        let
          val exp = resolveSqlFexpSpine env exps
        in
          S.CAST (id, exp, Loc.mergeRange (loc, AbsynUtils.sqlExpLoc exp))
        end
      | exp :: exps =>
        resolveSqlFexpApp env (resolveSqlFexp env exp) exps
      | nil =>
        raise Bug.Bug "resolveSqlFexpSpine"

  and resolveSqlFexp env exp =
      case exp of
        F.TERM (exp, _) =>
        resolveSqlExp env exp
      | F.APP (exp1, exp2, loc) =>
        resolveSqlFexpSpine env (fexpSpine exp1 [exp2])
      | F.OP2 (F.TERM (S.ID (false, (nil, id, _), _), _), (exp1, exp2), loc) =>
        S.INFIX (resolveSqlFexp env exp1, id, resolveSqlFexp env exp2, loc)
      | F.OP2 _ => raise Bug.Bug "resolveSqlFexp"

  and resolveSqlExp env exp =
      case exp of
        S.EXP_EMBED (exp, loc) =>
        S.EXP_EMBED (resolveExp env exp, loc)
      | S.CONST _ => exp
      | S.NULL _ => exp
      | S.TRUE _ => exp
      | S.FALSE _ => exp
      | S.COLUMN1 _ => exp
      | S.COLUMN2 _ => exp
      | S.KWEXP (prefix, kwexp, loc) =>
        S.KWEXP (prefix, resolveSqlKwexp env kwexp, loc)
      | S.EXP_SUBQUERY (prefix, query, loc) =>
        S.EXP_SUBQUERY (prefix, resolveSqlQuery env query, loc)
      | S.OP1 (oper, exp, loc) =>
        S.OP1 (oper, resolveSqlExp env exp, loc)
      | S.OP2 (oper, exp1, exp2, loc) =>
        S.OP2 (oper, resolveSqlExp env exp1, resolveSqlExp env exp2, loc)
      | S.ID _ => (mustBeNonfix env (sqlexpVid exp); exp)
      | S.PAREN (exp, loc) =>
        S.PAREN (resolveSqlExp env exp, loc)
      | S.APP (exp1, exp2, loc) =>
        let
          val terms = map (sqlexpToTerm env) (sqlappSpine exp1 [exp2])
        in
          resolveSqlFexp env (Fixity.parse (fixityError sqlexpVid) terms)
        end
      | S.INFIX (exp1, vid, exp2, loc) =>
        S.INFIX (resolveSqlExp env exp1, vid, resolveSqlExp env exp2, loc)
      | S.CAST (vid, exp, loc) =>
        S.CAST (vid, resolveSqlExp env exp, loc)
      | S.TUPLE (exps, loc) =>
        S.TUPLE (map (resolveSqlExp env) exps, loc)

  and resolveSqlKwexp env kwexp =
      case kwexp of
        S.EXISTS (query, loc) =>
        S.EXISTS (resolveSqlQuery env query, loc)

  and resolveSqlTable env table =
      case table of
        S.TABLE _ => table
      | S.TABLE_AS (table, lab, loc) =>
        S.TABLE_AS (resolveSqlTable env table, lab, loc)
      | S.TABLE_INNER_JOIN (table1, inner, table2, exp, loc) =>
        S.TABLE_INNER_JOIN (resolveSqlTable env table1,
                            inner,
                            resolveSqlTable env table2,
                            resolveSqlExp env exp,
                            loc)
      | S.TABLE_CROSS_JOIN (table1, table2, loc) =>
        S.TABLE_CROSS_JOIN (resolveSqlTable env table1,
                            resolveSqlTable env table2,
                            loc)
      | S.TABLE_NATURAL_JOIN (table1, table2, loc) =>
        S.TABLE_NATURAL_JOIN (resolveSqlTable env table1,
                              resolveSqlTable env table2,
                              loc)
      | S.TABLE_SUBQUERY (prefix, query, loc) =>
        S.TABLE_SUBQUERY (prefix, resolveSqlQuery env query, loc)
      | S.TABLE_PAREN (table, loc) =>
        S.TABLE_PAREN (resolveSqlTable env table, loc)

  and resolveSqlFrom env from =
      case from of
        S.FROM (tables, loc) =>
        S.FROM (map (resolveSqlTable env) tables, loc)
      | S.FROM_EMBED (exp, loc) =>
        S.FROM_EMBED (resolveExp env exp, loc)

  and resolveSqlWhr env whr =
      case whr of
        S.WHERE (exp, loc) =>
        S.WHERE (resolveSqlExp env exp, loc)
      | S.WHERE_EMBED (exp, loc) =>
        S.WHERE_EMBED (resolveExp env exp, loc)

  and resolveSqlGroupby env groupby =
      case groupby of
        S.GROUPBY (groupby, having, loc) =>
        S.GROUPBY (resolveSqlGroupbyClause env groupby,
                   Option.map (resolveSqlHavingClause env) having,
                   loc)

  and resolveSqlOrderby env orderby =
      case orderby of
        S.ORDERBY (keys, loc) =>
        S.ORDERBY (map (resolveSqlOrderKey env) keys, loc)
      | S.ORDERBY_EMBED (exp, loc) =>
        S.ORDERBY_EMBED (resolveExp env exp, loc)

  and resolveSqlLimit env limit =
      case limit of
        S.LIMIT (limit, offset, loc) =>
        S.LIMIT (resolveSqlLImitClause env limit,
                 Option.map (resolveSqlLimitOffsetClause env) offset,
                 loc)
      | S.LIMIT_EMBED (exp, loc) =>
        S.LIMIT_EMBED (resolveExp env exp, loc)

  and resolveSqlOffset env offset =
      case offset of
        S.OFFSET (offset, fetch, loc) =>
        S.OFFSET (resolveSqlOffsetClause env offset,
                  Option.map (resolveSqlFetchClause env) fetch,
                  loc)
      | S.OFFSET_EMBED (exp, loc) =>
        S.OFFSET_EMBED (resolveExp env exp, loc)

  and resolveSqlSelect env select =
      case select of
        S.SELECT (distinct, (rows, loc2), loc) =>
        S.SELECT (distinct, (map (resolveSqlSelectRow env) rows, loc2), loc)
      | S.SELECT_EMBED (exp, loc) =>
        S.SELECT_EMBED (resolveExp env exp, loc)

  and resolveSqlQuery env query =
      case query of
        S.QUERY (select, from, whr, groupby, orderby, offset, loc) =>
        S.QUERY (resolveSqlSelect env select,
                 resolveSqlFrom env from,
                 Option.map (resolveSqlWhr env) whr,
                 Option.map (resolveSqlGroupby env) groupby,
                 Option.map (resolveSqlOrderby env) orderby,
                 Option.map (resolveSqlOffsetOrLimit env) offset,
                 loc)
      | S.QUERY_EMBED (exp, loc) =>
        S.QUERY_EMBED (resolveExp env exp, loc)

  and resolveSqlOffsetOrLimit env clause =
      case clause of
        S.OFFSET_CLAUSE offset =>
        S.OFFSET_CLAUSE (resolveSqlOffset env offset)
      | S.LIMIT_CLAUSE limit =>
        S.LIMIT_CLAUSE (resolveSqlLimit env limit)

  and resolveSqlOrderKey env (exp, asc, loc) : A.exp S.order_key =
      (resolveSqlExp env exp, asc, loc)

  and resolveSqlSelectRow env (exp, lab, loc) : A.exp S.select_row =
      (resolveSqlExp env exp, lab, loc)

  and resolveSqlGroupbyClause env (exps, loc) : A.exp S.groupby_clause =
      (map (resolveSqlExp env) exps, loc)

  and resolveSqlHavingClause env (exp, loc) : A.exp S.having_clause =
      (resolveSqlExp env exp, loc)

  and resolveSqlLImitClause env (exp, loc) : A.exp S.limit_clause =
      (Option.map (resolveSqlExp env) exp, loc)

  and resolveSqlLimitOffsetClause env (exp, loc) : A.exp S.limit_offset_clause =
      (resolveSqlExp env exp, loc)

  and resolveSqlOffsetClause env (exp, rows, loc) : A.exp S.offset_clause =
      (resolveSqlExp env exp, rows, loc)

  and resolveSqlFetchClause env (first, exp, rows, loc) : A.exp S.fetch_clause =
      (first, Option.map (resolveSqlExp env) exp, rows, loc)

  and resolveSqlInsertValue env value =
      case value of
        S.VALUE exp => S.VALUE (resolveSqlExp env exp)
      | S.DEFAULT _ => value

  and resolveSqlInsertRow env (values, loc) : A.exp S.insert_row =
      (map (resolveSqlInsertValue env) values, loc)

  and resolveSqlInsertValues env values =
      case values of
        S.INSERT_VALUES (rows, loc) =>
        S.INSERT_VALUES (map (resolveSqlInsertRow env) rows, loc)
      | S.INSERT_VAR ((false, (nil, id, _), _), _) =>
        (mustBeNonfix env (SOME id); values)
      | S.INSERT_VAR _ => values
      | S.INSERT_SELECT query =>
        S.INSERT_SELECT (resolveSqlQuery env query)

  and resolveSqlSetRow env (lab, exp, loc) : A.exp S.set_row =
      (lab, resolveSqlExp env exp, loc)

  and resolveSqlSet env (setrows, loc) : A.exp S.set =
      (map (resolveSqlSetRow env) setrows, loc)

  and resolveSqlCon env con =
      case con of
        S.QRY query =>
        S.QRY (resolveSqlQuery env query)
      | S.SEL select =>
        S.SEL (resolveSqlSelect env select)
      | S.FRM from =>
        S.FRM (resolveSqlFrom env from)
      | S.WHR whr =>
        S.WHR (resolveSqlWhr env whr)
      | S.ORD orderby =>
        S.ORD (resolveSqlOrderby env orderby)
      | S.OFF offset =>
        S.OFF (resolveSqlOffset env offset)
      | S.LMT limit =>
        S.LMT (resolveSqlLimit env limit)
      | S.INSERT_LABELED (table, labels, values, loc) =>
        S.INSERT_LABELED (table, labels, resolveSqlInsertValues env values, loc)
      | S.INSERT_NOLABEL (table, query, loc) =>
        S.INSERT_NOLABEL (table, resolveSqlQuery env query, loc)
      | S.UPDATE (table, set, whr, loc) =>
        S.UPDATE (table,
                  resolveSqlSet env set,
                  Option.map (resolveSqlWhr env) whr,
                  loc)
      | S.DELETE (table, whr, loc) =>
        S.DELETE (table, Option.map (resolveSqlWhr env) whr, loc)
      | S.BEGIN _ => con
      | S.COMMIT _ => con
      | S.ROLLBACK _ => con

  and resolveSqlStep env step =
      case step of
        S.STEP (prefix, con, loc) =>
        S.STEP (prefix, resolveSqlCon env con, loc)
      | S.STEP_EMBED (exp, loc) =>
        S.STEP_EMBED (resolveExp env exp, loc)

  and resolveSqlBody env body =
      case body of
        S.CON (prefix, con, loc) =>
        S.CON (prefix, resolveSqlCon env con, loc)
      | S.EXP exp =>
        S.EXP (resolveSqlExp env exp)
      | S.SEQ (steps, loc) =>
        S.SEQ (map (resolveSqlStep env) steps, loc)
      | S.BODYPAREN (body, loc) =>
        S.BODYPAREN (resolveSqlBody env body, loc)

  and resolveSqlTop env sqlexp =
      case sqlexp of
        S.SQLSERVER (exp, ty, loc) =>
        S.SQLSERVER (Option.map (resolveExp env) exp, ty, loc)
      | S.SQL (sql, loc) =>
        S.SQL (resolveSqlBody (sqlEnv env loc) sql, loc)
      | S.SQLFN (pat, sql, loc) =>
        S.SQLFN (resolvePat env pat, resolveSqlBody (sqlEnv env loc) sql, loc)

  and resolveExpFexp env exp =
      case exp of
        F.TERM (exp as A.EXPID (false, (nil, id, _), _), _) => exp
      | F.TERM (exp, _) =>
        resolveExp env exp
      | F.APP (exp1, exp2, loc) =>
        A.EXPAPP (resolveExpFexp env exp1, resolveExpFexp env exp2, loc)
      | F.OP2 (F.TERM (A.EXPID (false, (nil, id, _), _), _),
               (exp1, exp2),
               loc) =>
        A.EXPINFIX (resolveExpFexp env exp1, id, resolveExpFexp env exp2, loc)
      | F.OP2 _ => raise Bug.Bug "resolveExpFexp"

  and resolveExp env exp =
      case exp of
        A.EXPCONST _ => exp
      | A.EXPID _ => (mustBeNonfix env (expVid exp); exp)
      | A.EXPRECORD (exprows, loc) =>
        A.EXPRECORD (map (resolveExprow env) exprows, loc)
      | A.EXPSELECT _ => exp
      | A.EXPTUPLE (exps, loc) =>
        A.EXPTUPLE (map (resolveExp env) exps, loc)
      | A.EXPLIST (exps, loc) =>
        A.EXPLIST (map (resolveExp env) exps, loc)
      | A.EXPSEQ (exps, loc) =>
        A.EXPSEQ (map (resolveExp env) exps, loc)
      | A.EXPLET (decs, (exps, loc1), loc) =>
        let
          val (ret, decs) = resolveDecs env decs
          val env = extendEnv (env, ret)
          val exps = map (resolveExp env) exps
        in
          A.EXPLET (decs, (exps, loc1), loc)
        end
      | A.EXPPAREN (exp, loc) =>
        A.EXPPAREN (resolveExp env exp, loc)
      | A.EXPAPP (exp1, exp2, loc) =>
        let
          val terms = map (expToTerm env) (expappSpine exp1 [exp2])
        in
          resolveExpFexp env (Fixity.parse (fixityError expVid) terms)
        end
      | A.EXPINFIX (exp1, vid, exp2, loc) =>
        A.EXPINFIX (resolveExp env exp1, vid, resolveExp env exp2, loc)
      | A.EXPTYPED (exp, ty, loc) =>
        A.EXPTYPED (resolveExp env exp, ty, loc)
      | A.EXPANDALSO (exp1, exp2, loc) =>
        A.EXPANDALSO (resolveExp env exp1, resolveExp env exp2, loc)
      | A.EXPORELSE (exp1, exp2, loc) =>
        A.EXPORELSE (resolveExp env exp1, resolveExp env exp2, loc)
      | A.EXPHANDLE (exp, mrules, loc) =>
        A.EXPHANDLE (resolveExp env exp, map (resolveMrule env) mrules, loc)
      | A.EXPRAISE (exp, loc) =>
        A.EXPRAISE (resolveExp env exp, loc)
      | A.EXPIF (exp1, exp2, exp3, loc) =>
        A.EXPIF (resolveExp env exp1,
                 resolveExp env exp2,
                 resolveExp env exp3,
                 loc)
      | A.EXPWHILE (exp1, exp2, loc) =>
        A.EXPWHILE (resolveExp env exp1, resolveExp env exp2, loc)
      | A.EXPCASE (exp, mrules, loc) =>
        A.EXPCASE (resolveExp env exp, map (resolveMrule env) mrules, loc)
      | A.EXPFN (mrules, loc) =>
        A.EXPFN (map (resolveMrule env) mrules, loc)
      | A.EXPSIZEOF _ => exp
      | A.EXPRECORD_UPDATE (exp, exprows, loc) =>
        A.EXPRECORD_UPDATE (resolveExp env exp,
                            map (resolveExprow env) exprows,
                            loc)
      | A.EXPTUPLE_UPDATE (exp, exps, loc) =>
        A.EXPTUPLE_UPDATE (resolveExp env exp, map (resolveExp env) exps, loc)
      | A.EXPIMPORT_NAME _ => exp
      | A.EXPIMPORT_EXP (exp, ffity, loc) =>
        A.EXPIMPORT_EXP (resolveExp env exp, ffity, loc)
      | A.EXPSQL sqlexp =>
        A.EXPSQL (resolveSqlTop env sqlexp)
      | A.EXPFOREACH_DATA (vid, exp1, exp2, pat, exp3, exp4, loc) =>
        A.EXPFOREACH_DATA (vid,
                           resolveExp env exp1,
                           resolveExp env exp2,
                           resolvePat env pat,
                           resolveExp env exp3,
                           resolveExp env exp4,
                           loc)
      | A.EXPFOREACH_ARRAY (vid, exp1, pat, exp2, exp3, loc) =>
        A.EXPFOREACH_ARRAY (vid,
                            resolveExp env exp1,
                            resolvePat env pat,
                            resolveExp env exp2,
                            resolveExp env exp3,
                            loc)
      | A.EXPJOIN (exp1, exp2, loc) =>
        A.EXPJOIN (resolveExp env exp1, resolveExp env exp2, loc)
      | A.EXPEXTEND (exp1, exp2, loc) =>
        A.EXPEXTEND (resolveExp env exp1, resolveExp env exp2, loc)
      | A.EXPUPDATE1 (exp1, exp2, loc) =>
        A.EXPUPDATE1 (resolveExp env exp1, resolveExp env exp2, loc)
      | A.EXPUPDATE2 (exp1, exp2, loc) =>
        A.EXPUPDATE2 (resolveExp env exp1, resolveExp env exp2, loc)
      | A.EXPDYNAMIC_AS (exp, ty, loc) =>
        A.EXPDYNAMIC_AS (resolveExp env exp, ty, loc)
      | A.EXPDYNAMIC_OF (exp, ty, loc) =>
        A.EXPDYNAMIC_OF (resolveExp env exp, ty, loc)
      | A.EXPDYNAMICVIEW (exp, ty, loc) =>
        A.EXPDYNAMICVIEW (resolveExp env exp, ty, loc)
      | A.EXPDYNAMICNULL _ => exp
      | A.EXPDYNAMICTOP _ => exp
      | A.EXPDYNAMICCASE (exp, mrules, loc) =>
        A.EXPDYNAMICCASE (resolveExp env exp,
                          map (resolveDynamicMrule env) mrules,
                          loc)
      | A.EXPREIFYTY _ => exp

  and resolveValbind env valbind =
      case valbind of
        A.VALBIND (pat, exp, loc) =>
        A.VALBIND (resolvePat env pat, resolveExp env exp, loc)
      | A.VALREC (valbinds, loc) =>
        A.VALREC (map (resolveValbind env) valbinds, loc)

  and resolveValrecbind env (pat, exp, loc) =
      (resolvePat env pat, resolveExp env exp, loc)

  and resolveDec env dec =
      case dec of
        A.DECVAL (tyvars, valbinds, loc) =>
        (emptyEnv, A.DECVAL (tyvars, map (resolveValbind env) valbinds, loc))
      | A.DECVALREC (tyvars, valbinds, loc) =>
        (emptyEnv,
         A.DECVALREC (tyvars, map (resolveValrecbind env) valbinds, loc))
      | A.DECFUN (tyvars, fvalbinds, loc) =>
        (emptyEnv, A.DECFUN (tyvars, map (resolveFvalbind env) fvalbinds, loc))
      | A.DECTYPE _ => (emptyEnv, dec)
      | A.DECDATATYPE _ => (emptyEnv, dec)
      | A.DECDATATYPEREP _ => (emptyEnv, dec)
      | A.DECABSTYPE (datbinds, withty, decs, loc) =>
        (emptyEnv,
         A.DECABSTYPE (datbinds, withty, #2 (resolveDecs env decs), loc))
      | A.DECEXCEPTION _ => (emptyEnv, dec)
      | A.DECLOCAL (decs1, decs2, loc) =>
        let
          val (ret1, decs1) = resolveDecs env decs1
          val env = extendEnv (env, ret1)
          val (ret2, decs2) = resolveDecs env decs2
        in
          (ret2, A.DECLOCAL (decs1, decs2, loc))
        end
      | A.DECOPEN _ => (emptyEnv, dec)
      | A.DECSEMICOLON _ => (emptyEnv, dec)
      | A.DECINFIX (prec, vids, loc) =>
        (makeEnv (resolveFixity F.INFIX loc prec) vids, dec)
      | A.DECINFIXR (prec, vids, loc) =>
        (makeEnv (resolveFixity F.INFIXR loc prec) vids, dec)
      | A.DECNONFIX (vids, loc) =>
        (makeEnv F.NONFIX vids, dec)
      | A.DECDO (exp, loc) =>
        (emptyEnv, A.DECDO (resolveExp env exp, loc))
      | A.DECPOLYREC (pvalbinds, loc) =>
        (emptyEnv, A.DECPOLYREC (map (resolvePvalbind env) pvalbinds, loc))

  and resolveDecs env decs =
      resolveList resolveDec env decs

  and resolveExprow env exprow =
      case exprow of
        A.EXPROW (lab, exp, loc) =>
        A.EXPROW (lab, resolveExp env exp, loc)
      | A.EXPROWVAR _ => exprow

  and resolveMrule env (pat, exp, loc) : A.mrule =
      (resolvePat env pat, resolveExp env exp, loc)

  and resolveDynamicMrule env (exists, pat, exp, loc) : A.dynamic_mrule =
      (exists, resolvePat env pat, resolveExp env exp, loc)

  and resolveFrule env (pat, ty, exp, loc) : A.frule =
      (resolvePat env pat, ty, resolveExp env exp, loc)

  and resolveFvalbind env (frules, loc) : A.fvalbind =
      (map (resolveFrule env) frules, loc)

  and resolvePvalbind env (vid, ty, exp, loc) : A.pvalbind =
      (vid, ty, resolveExp env exp, loc)

  and resolveStrexp env strexp =
      case strexp of
        A.STRBASIC (strdecs, loc) =>
        A.STRBASIC (#2 (resolveStrdecs env strdecs), loc)
      | A.STRID _ => strexp
      | A.STRCONSTRAINT (strexp, sigcon, loc) =>
        A.STRCONSTRAINT (resolveStrexp env strexp, sigcon, loc)
      | A.STRAPP (funid, funarg, loc) =>
        A.STRAPP (funid, Option.map (resolveFunarg env) funarg, loc)
      | A.STRLET (strdecs, strexp, loc) =>
        let
          val (ret, strdecs) = resolveStrdecs env strdecs
          val env = extendEnv (env, ret)
          val strexp = resolveStrexp env strexp
        in
          A.STRLET (strdecs, strexp, loc)
        end

  and resolveStrdec env strdec =
      case strdec of
        A.STRDEC dec =>
        let
          val (ret, dec) = resolveDec env dec
        in
          (ret, A.STRDEC dec)
        end
      | A.STRUCTURE (strbinds, loc) =>
        (emptyEnv, A.STRUCTURE (map (resolveStrbind env) strbinds, loc))
      | A.STRLOCAL (strdecs1, strdecs2, loc) =>
        let
          val (ret1, strdecs1) = resolveStrdecs env strdecs1
          val env = extendEnv (env, ret1)
          val (ret2, strdecs2) = resolveStrdecs env strdecs2
        in
          (ret2, A.STRLOCAL (strdecs1, strdecs2, loc))
        end
      | A.STRSEMICOLON _ =>
        (emptyEnv, strdec)

  and resolveStrdecs env strdecs =
      resolveList resolveStrdec env strdecs

  and resolveFunarg env funarg =
      case funarg of
        A.FUNARG strexp =>
        A.FUNARG (resolveStrexp env strexp)
      | A.FUNARG_DEC (strdecs, loc) =>
        A.FUNARG_DEC (#2 (resolveStrdecs env strdecs), loc)

  and resolveStrbind env (strid, sigcon, strexp, loc) : A.strbind =
      (strid, sigcon, resolveStrexp env strexp, loc)

  fun resolveFunbind env (funid, param, sigcon, strexp, loc) : A.funbind =
      (funid, param, sigcon, resolveStrexp env strexp, loc)

  fun resolveTopdec env topdec =
      case topdec of
        A.TOPSTRDEC strdec =>
        let
          val (ret, strdec) = resolveStrdec env strdec
        in
          (ret, A.TOPSTRDEC strdec)
        end
      | A.TOPSIGNATURE _ =>
        (emptyEnv, topdec)
      | A.TOPFUNCTOR (funbinds, loc) =>
        (emptyEnv, A.TOPFUNCTOR (map (resolveFunbind env) funbinds, loc))
      | A.TOPEXP (exp, loc) =>
        (emptyEnv, A.TOPEXP (resolveExp env exp, loc))

  fun resolveTopdecs env topdecs =
      resolveList resolveTopdec env topdecs

  fun resolveTop env top =
      case top of
        A.TOPDEC (topdecs, loc) =>
        let
          val (ret, topdecs) = resolveTopdecs env topdecs
        in
          (ret, A.TOPDEC (topdecs, loc))
        end
      | A.USE _ => (emptyEnv, top)
      | A.U_USE _ => (emptyEnv, top)
      | A.TOPSEMICOLON _ => (emptyEnv, top)

  fun resolveTops env tops =
      resolveList resolveTop env tops

  fun resolveCompileUnit env ((interface, tops, loc) : A.compile_unit) =
      let
        val (ret, tops) = resolveTops env tops
      in
        (ret, (interface, tops, loc))
      end

end
