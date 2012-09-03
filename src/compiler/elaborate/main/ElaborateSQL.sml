(**
 * ElaboratorSQL.sml
 * @copyright (c) 2009, 2010, Tohoku University.
 * @author UENO Katsuhiro
 * @author ENDO Hiroki
 *)

structure ElaborateSQL : sig

  val elaborateExp : {elabExp: Absyn.exp -> PatternCalc.plexp,
                      elabPat: Absyn.pat -> PatternCalc.plpat}
                     -> (Absyn.exp, Absyn.pat, Absyn.ty) AbsynSQL.exp
                     -> PatternCalc.plexp

end =
struct
  structure A = Absyn
  structure S = AbsynSQL
  structure P = PatternCalc

  val SQLDBConName = ["SMLSharp_SQL_Prim", "DB"]
  val SQLDBIConName = ["SMLSharp", "SQL", "DBI"]
  val SQLTableConName = ["SMLSharp_SQL_Prim", "TABLE"]
  val SQLRowConName = ["SMLSharp_SQL_Prim", "ROW"]
  val SQLValueConName = ["SMLSharp_SQL_Prim", "VALUE"]
  val SQLQueryConName = ["SMLSharp_SQL_Prim", "QUERY"]
  val SQLCommandConName = ["SMLSharp_SQL_Prim", "COMMAND"]
  val SQLResultConName = ["SMLSharp_SQL_Prim", "RESULT"]
  (* NOTE: even bool and option are builtin names, user may override them
   * in interactive mode. Currently, if user overrides these types, SQL
   * feature does not work. *)
  val boolTyName = ["bool"]
  val optionTyName = ["option"]
  val SQLValueTyName = ["SMLSharp", "SQL", "value"]
  val concatDotFunName = ["SMLSharp_SQL_Prim", "concatDot"]
  val concatQueryFunName = ["SMLSharp_SQL_Prim", "concatQuery"]
  val execFunName = ["SMLSharp_SQL_Prim", "exec"]
  val evalFunName = ["SMLSharp_SQL_Prim", "eval"]
  val fromSQLFunName = ["SMLSharp_SQL_Prim", "fromSQL"]
  val defaultFunName = ["SMLSharp_SQL_Prim", "default"]

  val listToTuple = Utils.listToTuple
  val emptyTvars = nil : P.scopedTvars

  fun mapi f l =
      let fun loop f n nil = nil
            | loop f n (h::t) = f (n, h) :: loop f (n+1) t
      in loop f 0 l
      end

  fun varPat (NONE, loc) = P.PLPATWILD loc
    | varPat (SOME x, loc) = P.PLPATID ([x], loc)

  fun pairPat (pat1, pat2, loc) =
      P.PLPATRECORD (false, [("1", pat1), ("2", pat2)], loc)

  fun pairVarPat (var1, var2, loc) =
      pairPat (P.PLPATID ([var1], loc), P.PLPATID ([var2], loc), loc)

  fun stringDBIPat (stringVar, dbiVar, loc) =
      case dbiVar of
        NONE => P.PLPATID ([stringVar], loc)
      | SOME dbiVar =>
        P.PLPATLAYERED
          (stringVar, NONE,
           pairPat (P.PLPATWILD loc, P.PLPATID ([dbiVar], loc), loc),
           loc)

  fun tablePat (nameVar, dbiVar, witnessVar, loc) =
      P.PLPATCONSTRUCT
        (P.PLPATID (SQLTableConName, loc),
         pairPat (stringDBIPat (nameVar, dbiVar, loc),
                  P.PLPATID ([witnessVar], loc),
                  loc),
         loc)

  fun boolOptionTy loc =
      A.TYCONSTRUCT ([A.TYCONSTRUCT (nil, boolTyName, loc)],
                     optionTyName, loc)

  fun valuePat (queryVar, witnessVar, witnessTy, loc) =
      P.PLPATCONSTRUCT
        (P.PLPATID (SQLValueConName, loc),
         pairPat (P.PLPATID ([queryVar], loc),
                  case witnessTy of
                    NONE => varPat (witnessVar, loc)
                  | SOME ty => P.PLPATTYPED (varPat (witnessVar, loc), ty, loc),
                  loc),
         loc)

  fun fnExp (var, exp, loc) =
      P.PLFNM ([([varPat (var, loc)], exp)], loc)

  fun appExp (funName, arg, loc) =
      P.PLAPPM (P.PLVAR (funName, loc), [arg], loc)

  fun caseExp (exp, pat, bodyExp, loc) =
      P.PLCASEM ([exp], [([pat], bodyExp)], P.MATCH, loc)

  fun intCon (n, loc) =
      P.PLCONSTANT (A.INT ({radix=StringCvt.DEC, digits=Int.toString n}, loc),
                    loc)

  fun rawStringCon (s, loc) =
      P.PLCONSTANT (A.STRING (s, loc), loc)

  fun unitCon loc =
      P.PLCONSTANT (A.UNITCONST loc, loc)

  fun pairCon (exp1, exp2, loc) =
      P.PLRECORD ([("1", exp1), ("2", exp2)], loc)

  fun stringDBICon (s, dbiVar, loc) =
      pairCon (rawStringCon (s, loc), P.PLVAR ([dbiVar], loc), loc)

  fun stringCon (s, loc) =
      pairCon (rawStringCon (s, loc), P.PLVAR (SQLDBIConName, loc), loc)

  fun rowCon (rowName, dbiVar, witnessVar, loc) =
      appExp (SQLRowConName,
              pairCon (stringDBICon (rowName, dbiVar, loc),
                       P.PLVAR ([witnessVar], loc), loc),
              loc)
  fun makeList (elemList, loc) = 
      let
        fun folder (x, y) =
            P.PLAPPM
              (P.PLVAR(["::"], loc),
               [P.PLRECORD(listToTuple [x, y], loc)],
               loc)
        val plexp = foldr folder (P.PLVAR(["nil"], loc)) elemList
      in
        plexp
      end

  fun queryCon (resultVar, returnExp, witnessExp, queryStrings, loc) =
      appExp (SQLQueryConName,
              P.PLRECORD
                (listToTuple 
                   [appExp (concatQueryFunName,
                            makeList (queryStrings, loc), loc),
                    witnessExp,
                    P.PLFNM
                      ([([P.PLPATID ([resultVar], loc)], returnExp)],
                       loc)], loc), loc)
      
  fun commandCon (queryStrings, loc) =
      appExp (SQLCommandConName,
              appExp (concatQueryFunName, makeList (queryStrings, loc), loc),
              loc)

  fun a_fieldPat (label, var, loc) =
      A.PATRECORD
        {ifFlex = true,
         fields = [A.PATROWPAT (label, A.PATID {opPrefix = true, id = [var],
                                                loc = loc}, loc)],
         loc = loc}

  fun a_dbPat (label, witnessVar, dbiVar, loc) =
      A.PATAPPLY ([A.PATID {opPrefix = true, id = SQLDBConName, loc = loc},
                   A.PATTUPLE
                     ([a_fieldPat (label, witnessVar, loc),
                       A.PATID {opPrefix = true, id = [dbiVar], loc = loc}],
                      loc)], loc)

  fun a_rowPat (nameVar, label, witnessVar, loc) =
      A.PATAPPLY ([A.PATID {opPrefix = true, id = SQLRowConName, loc = loc},
                   A.PATTUPLE
                     ([A.PATID {opPrefix=true, id=[nameVar], loc=loc},
                       a_fieldPat (label, witnessVar, loc)],
                      loc)], loc)

  fun a_caseExp (exp, pat, bodyExp, loc) =
      A.EXPCASE (exp, [(pat, bodyExp)], loc)

  fun a_appExp (funName, argExp, loc) =
      A.EXPAPP ([A.EXPID (funName, loc), argExp], loc)

  fun a_pairExp (exp1, exp2, loc) =
      A.EXPTUPLE ([exp1, exp2], loc)

  fun a_stringCon (s, loc) =
      A.EXPCONSTANT (A.STRING (s, loc), loc)

  fun a_StringDBICon (s, dbiVar, loc) =
      a_pairExp (a_stringCon (s, loc), A.EXPID ([dbiVar], loc), loc)

  fun a_tableCon (rowName, witnessVar, dbiVar, loc) =
      a_appExp (SQLTableConName,
                a_pairExp (a_StringDBICon (rowName, dbiVar, loc),
                           A.EXPID ([witnessVar], loc), loc),
                loc)

  fun a_columnCon (tableNameVar, columnName, witnessVar, loc) =
      a_appExp (SQLValueConName,
                a_pairExp
                  (a_appExp
                     (concatDotFunName,
                      a_pairExp (A.EXPID ([tableNameVar], loc),
                                 a_stringCon ("\"" ^ columnName ^ "\"", loc),
                                 loc),
                      loc),
                   A.EXPID ([witnessVar], loc),
                   loc),
                loc)

  fun join s nil = nil
    | join s [x] = x
    | join s (h::t) = h @ [s] @ join s t

  fun asList (nil, loc) = nil
    | asList ([(l, e)], loc) = [e, stringCon (" AS \"" ^ l ^ "\"", loc)]
    | asList ((l, e)::t, loc) =
      e :: stringCon (" AS \"" ^ l ^ "\", ", loc) :: asList (t, loc)

  fun bindsToDecls (nil, loc) = nil
    | bindsToDecls (binds, loc) = [P.PDVAL (emptyTvars, binds, loc)]

  fun substSQLexp f exp =
      case exp of
        A.EXPCONSTANT (constant,loc) => A.EXPCONSTANT (constant,loc)
      | A.EXPGLOBALSYMBOL (name,kind,loc) => A.EXPGLOBALSYMBOL (name,kind,loc)
      | A.EXPID (string,loc) => A.EXPID (string,loc)
      | A.EXPOPID (string,loc) => A.EXPOPID (string,loc)
      | A.EXPRECORD (fields,loc) =>
        A.EXPRECORD (map (fn (l,e) => (l, substSQLexp f e)) fields, loc)
      | A.EXPRECORD_UPDATE (exp,fields,loc) =>
        A.EXPRECORD_UPDATE (substSQLexp f exp,
                            map (fn (l,e) => (l, substSQLexp f e)) fields,
                            loc)
      | A.EXPRECORD_SELECTOR (string,loc) => A.EXPRECORD_SELECTOR (string,loc)
      | A.EXPTUPLE (expList,loc) => A.EXPTUPLE (map (substSQLexp f) expList,loc)
      | A.EXPLIST (expList,loc) => A.EXPLIST (map (substSQLexp f) expList,loc)
      | A.EXPSEQ (expList,loc) => A.EXPSEQ (map (substSQLexp f) expList,loc)
      | A.EXPAPP (expList,loc) => A.EXPAPP (map (substSQLexp f) expList,loc)
      | A.EXPTYPED (exp,ty,loc) => A.EXPTYPED (substSQLexp f exp,ty,loc)
      | A.EXPCONJUNCTION (exp1,exp2,loc) =>
        A.EXPCONJUNCTION (substSQLexp f exp1, substSQLexp f exp2, loc)
      | A.EXPDISJUNCTION (exp1,exp2,loc) =>
        A.EXPDISJUNCTION (substSQLexp f exp1, substSQLexp f exp2, loc)
      | A.EXPHANDLE (exp1, rules,loc) =>
        A.EXPHANDLE (substSQLexp f exp1, substSQLmatches f rules, loc)
      | A.EXPRAISE (exp,loc) => A.EXPRAISE (substSQLexp f exp,loc)
      | A.EXPIF (exp1,exp2,exp3,loc) =>
        A.EXPIF (substSQLexp f exp1, substSQLexp f exp2, substSQLexp f exp3,
                 loc)
      | A.EXPWHILE (exp1,exp2,loc) =>
        A.EXPWHILE (substSQLexp f exp1, substSQLexp f exp2, loc)
      | A.EXPCASE (exp1, rules, loc) =>
        A.EXPCASE (substSQLexp f exp1, substSQLmatches f rules, loc)
      | A.EXPFN (rules,loc) => A.EXPFN (substSQLmatches f rules, loc)
      | A.EXPLET (decList,expList,loc) =>
        A.EXPLET (map (substSQLdec f) decList,
                  map (substSQLexp f) expList, loc)
      | A.EXPCAST (exp,loc) => A.EXPCAST (substSQLexp f exp, loc)
      | A.EXPFFIIMPORT (exp,ty,loc) => A.EXPFFIIMPORT (substSQLexp f exp,ty,loc)
      | A.EXPFFIEXPORT (exp,ty,loc) => A.EXPFFIEXPORT (substSQLexp f exp,ty,loc)
      | A.EXPFFIAPPLY (attrs,exp,args,ty,loc) =>
        A.EXPFFIAPPLY (attrs, substSQLexp f exp, map (substSQLffiArg f) args,
                       ty, loc)
      | A.EXPSQL (S.SQLFIELDSELECT (label, exp, loc), _) =>
        f (label, substSQLexp f exp, loc)
      | A.EXPSQL (S.SQLSERVER (str, schema, loc), loc2) =>
        A.EXPSQL (S.SQLSERVER (map (fn (x, y) => (x, substSQLexp f y)) str,
                               schema, loc), loc2)
      | A.EXPSQL (S.SQLFN _, _) => exp
      | A.EXPSQL (S.SQLEXEC _, _) => exp
      | A.EXPSQL (S.SQLEVAL _, _) => exp

  and substSQLmatches f rules =
      map (fn (p,e) => (p, substSQLexp f e)) rules

  and substSQLffiArg f ffiArg =
      case ffiArg of
        A.FFIARG (exp, ty, loc) => A.FFIARG (substSQLexp f exp, ty, loc)
      | A.FFIARGSIZEOF (ty, expOpt, loc) =>
        A.FFIARGSIZEOF (ty, Option.map (substSQLexp f) expOpt, loc)

  and substSQLdec f dec =
      case dec of
        A.DECVAL (kindedTvarList, rules, loc) =>
        A.DECVAL (kindedTvarList, substSQLmatches f rules, loc)
      | A.DECREC (kindedTvarList, rules, loc) =>
        A.DECREC (kindedTvarList, substSQLmatches f rules, loc)
      | A.DECFUN (kindedTvarList, rules, loc) =>
        A.DECFUN (kindedTvarList,
                  map (map (fn (p,t,e) => (p,t,substSQLexp f e))) rules,
                  loc)
      | A.DECTYPE _ => dec
      | A.DECDATATYPE _ => dec
      | A.DECABSTYPE (datbindList, typbindList, decList, loc) =>
        A.DECABSTYPE (datbindList, typbindList,
                      map (substSQLdec f) decList, loc)
      | A.DECOPEN _ => dec
      | A.DECREPLICATEDAT _ => dec
      | A.DECEXN _ => dec
      | A.DECLOCAL (decList1, decList2, loc) =>
        A.DECLOCAL (map (substSQLdec f) decList1,
                    map (substSQLdec f) decList2, loc)
      | A.DECINFIX _ => dec
      | A.DECINFIXR _ => dec
      | A.DECNONFIX _ => dec

  fun selectTable (label, exp, loc) =
      a_caseExp (exp, a_dbPat (label, "_sql_w_", "_sql_i_", loc),
                 a_tableCon (label, "_sql_w_", "_sql_i_", loc), loc)

  fun selectColumn (label, exp, loc) =
      a_caseExp (exp, a_rowPat ("_sql_n_", label, "_sql_w_", loc),
                 a_columnCon ("_sql_n_", label, "_sql_w_", loc), loc)

  fun elabSQLExp_From elabExp exp =
      elabExp (substSQLexp selectTable exp)

  fun elabSQLExp elabExp exp =
      elabExp (substSQLexp selectColumn exp)

  fun elabFromList elabExp fromClause loc =
      let
        val _ = UserErrorUtils.checkNameDuplication
                  #1 fromClause loc
                  ElaborateErrorSQL.DuplicateSQLTuple

        (*
         * FROM e1 as x1, ..., en as xn
         * ==>
         * (decls) val (tableName_1, x_1) =
         *             case e_1 of TABLE (t as (_,i),w) =>
         *                         (t, ROW (("x_1", i), w))
         *         and ...
         *         and (tableName_n, x_n) =
         *             case e_n of TABLE (t as (_,i),w) =>
         *                         (t, ROW (("x_n", i), w))
         * (query) tableName_1 ^ " AS x_1, " ^ ... ^ ", "
         *         ^ tableName_n ^ " AS x_n"
         *)
        val fromList =
            map (fn (id, exp) =>
                    {id = id, exp = elabSQLExp_From elabExp exp,
                     tableNameVar = "_sql_" ^ id ^ "_tabname_"})
                fromClause
        val fromBinds =
            map (fn {id, exp, tableNameVar} =>
                    (pairVarPat (tableNameVar, id, loc),
                     caseExp
                       (exp,
                        tablePat ("_sql_t_", SOME "_sql_i_", "_sql_w_", loc),
                        pairCon (P.PLVAR (["_sql_t_"], loc),
                                 rowCon (id, "_sql_i_", "_sql_w_", loc), loc),
                        loc)))
                fromList
        val fromQuery =
            asList (map (fn {id, tableNameVar, ...} =>
                            (id, P.PLVAR ([tableNameVar], loc)))
                        fromList, loc)
      in
        (bindsToDecls (fromBinds, loc), fromQuery)
      end

  fun elabFromClause elabExp fromClause loc =
      let
        val (fromDecls, fromQuery) = elabFromList elabExp fromClause loc
        val fromQuery =
            case fromQuery of
              nil => fromQuery
            | _::_ => stringCon (" FROM ", loc) :: fromQuery
      in
        (fromDecls, fromQuery)
      end

  fun elabWhereClause elabExp NONE loc = (nil, nil)
    | elabWhereClause elabExp (SOME exp) loc =
      let
        (*
         * WHERE exp
         * ==>
         * (decls) val VALUE (_sql_where_, _ : bool) = exp
         * (query) " WHERE " ^ _sql_where_
         *)
        val whereVar = "_sql_where_"
        val wherebinds =
            [(valuePat (whereVar, NONE, SOME (boolOptionTy loc), loc),
              elabSQLExp elabExp exp)]
        val whereQuery =
            [stringCon (" WHERE ", loc), P.PLVAR ([whereVar], loc)]
      in
        (bindsToDecls (wherebinds, loc), whereQuery)
      end

  fun elabSelectList elabExp dbiVar selectLabels selectListExps selectName loc =
      let
        val _ = UserErrorUtils.checkNameDuplication
                  (fn x => x) selectLabels loc
                  ElaborateErrorSQL.DuplicateSQLSelectLabel

        (*
         * SELECT e_1 as l_1, ..., e_n as l_n into r
         * ==>
         * (decls) val VALUE (q_1, w_1) = e_1
         *         and ...
         *         and VALUE (q_n, w_n) = e_n
         *         val w = {l_1 = w_1, ..., l_n = w_n}
         *         val r = ROW (("", dbi), w)
         *         query r = {{l_1 = w_1, ..., l_n = w_n}}
         * (witness) {l_1 = w_1, ..., l_n = w_n}
         * (query) "SELECT " ^ q_1 ^ " AS l_1, " ^ ... ^ ", "
         *                   ^ q_n ^ " AS l_n"
         * (ret) {l_1 = fromSQL(##l_1 r), ..., l_n = fromSQL(##l_n r)}
         *)
        val selectList =
            ListPair.map
              (fn (label, exp) =>
                  {exp = elabSQLExp elabExp exp,
                   label = label,
                   queryVar = "_sql_select_" ^ label ^ "_",
                   witnessVar = "_sql_select_" ^ label ^ "_witness_"})
              (selectLabels, selectListExps)
        val selectBinds =
            map (fn {exp, label, queryVar, witnessVar} =>
                    (valuePat (queryVar, SOME witnessVar, NONE, loc), exp))
                selectList
        val selectResult =
            map (fn {label, witnessVar, ...} =>
                    (label, P.PLVAR ([witnessVar], loc)))
                selectList
        val resultWitnessVar = "_sql_witness_"
        val resultWitnessExp = P.PLVAR ([resultWitnessVar], loc)
        val queryResultVar = "_sql_result_"
        val queryResultExp = P.PLVAR ([queryResultVar], loc)
        val resultWitnessBinds =
            [(P.PLPATID ([resultWitnessVar], loc),
              P.PLRECORD (selectResult, loc))]
        val resultRowBinds =
            case selectName of
              NONE => nil
            | SOME var => [(P.PLPATID ([var], loc),
                            rowCon ("", dbiVar, resultWitnessVar, loc))]
        val selectReturnFields =
            mapi (fn (i, {label, ...}) =>
                     (label,
                      appExp
                        (fromSQLFunName,
                         P.PLRECORD
                           (listToTuple
                              [intCon (i, loc),
                               queryResultExp,
                               P.PLSELECT (label, resultWitnessExp, loc)],
                            loc), loc)))
                  selectList
        val selectReturnExp =
            P.PLRECORD (selectReturnFields, loc)
        val selectQuery =
            stringCon ("SELECT ", loc) ::
            asList (map (fn {queryVar, label, ...} =>
                            (label, P.PLVAR ([queryVar], loc)))
                        selectList, loc)
        val selectDecls =
            bindsToDecls (selectBinds, loc)
            @ bindsToDecls (resultWitnessBinds, loc)
            @ bindsToDecls (resultRowBinds, loc)
      in
        {selectDecls = selectDecls,
         selectQuery = selectQuery,
         queryResultVar = queryResultVar,
         resultWitnessExp = resultWitnessExp,
         selectReturnExp = selectReturnExp}
      end

  fun elabOrderByClause elabExp orderByClause loc =
      let
        (*
         * ORDER BY exp_1, ..., exp_n
         * ==>
         * (decls) val VALUE (q_1, _) = exp_1
         *         and ...
         *         and VALUE (q_n, _) = exp_n
         * (query) " ORDER BY " ^ q_1 ^ ", " ^ ... ^ ", " ^ q_n
         *)
        val orderByList =
            mapi (fn (i, {keyExp, orderAsc}) =>
                     {exp = elabSQLExp elabExp keyExp,
                      order = if orderAsc then " ASC" else " DESC",
                      queryVar = "_sql_orderby_" ^ Int.toString i ^ "_"})
                 orderByClause
        val orderByBinds =
            map (fn {exp, order, queryVar} =>
                    (valuePat (queryVar, NONE, NONE, loc), exp))
                orderByList
        val orderByQuery =
            join (stringCon (", ", loc))
                 (map (fn {order, queryVar, ...} =>
                          [P.PLVAR ([queryVar], loc), stringCon (order, loc)])
                      orderByList)
        val orderByQuery =
            case orderByQuery of
              nil => orderByQuery
            | _::_ => stringCon (" ORDER BY ", loc) :: orderByQuery
      in
        (bindsToDecls (orderByBinds, loc), orderByQuery)
      end

  fun elaborateCommand elabExp dbiVar sql =
      case sql of
        S.SQLSELECT {selectListExps, selectLabels, selectName,
                     fromClause, whereClause, orderByClause, loc} =>
        let
          val _ = UserErrorUtils.checkNameDuplication
                    (fn x => x)
                    ((case selectName of SOME x => [x] | NONE => [])
                     @ map #1 fromClause)
                    loc
                    ElaborateErrorSQL.DuplicateSQLTuple

          val selectRecordLabels =
              case selectLabels of
                SOME labels => labels
              | NONE => List.tabulate (length selectListExps,
                                       fn x => Int.toString (x + 1))

          val {selectDecls, selectQuery, queryResultVar, resultWitnessExp,
               selectReturnExp} =
              elabSelectList elabExp dbiVar
                             selectRecordLabels selectListExps selectName loc
          val (fromDecls, fromQuery) =
              elabFromClause elabExp fromClause loc
          val (whereDecls, whereQuery) =
              elabWhereClause elabExp whereClause loc
          val (orderByDecls, orderByQuery) =
              elabOrderByClause elabExp orderByClause loc
        in
          P.PLLET
            (fromDecls @ whereDecls @ selectDecls @ orderByDecls,
             [queryCon (queryResultVar, selectReturnExp,
                        resultWitnessExp,
                        selectQuery @ fromQuery @ whereQuery @ orderByQuery,
                        loc)],
             loc)
        end

      | S.SQLINSERT {table=(dbVar, tableLabel), insertRows, insertLabels,
                     loc} =>
        let
          val _ = UserErrorUtils.checkNameDuplication
                    (fn x => x) insertLabels loc
                    ElaborateErrorSQL.DuplicateSQLInsertLabel

          (*
           * INSERT INTO #db.t (l_1, ..., l_n) VALUES (e_1, ..., e_n)
           * ==>
           * (decls) val TABLE (_tabname_, _tab_witness_) =
           *             case db of DB ({t=w,...},i) => TABLE ((t,i),w)
           *         val VALUE (q_1, w_1) = e_1
           *         and ...
           *         and VALUE (q_n, w_n) = e_n
           *         val witness = [_tab_witness_, {l_1 = w_1, ..., l_n = w_n}]
           * (query) "INSERT INTO " ^ _tabname_ ^ " (l_1, " ^ ... ^ ", l_n)"
           *         ^ " VALUES (" ^ q_1 ^ ", " ^ ... ^ ", " ^ q_n ^ ")"
           *)
          val tableNameVar = "_sql_insert_tabname_"
          val tableWitnessVar = "_sql_insert_witness_"
          val tableNameExp = P.PLVAR ([tableNameVar], loc)
          val tableWitnessExp = P.PLVAR ([tableWitnessVar], loc)

          val tableExp =
              elabExp (selectTable (tableLabel, A.EXPID ([dbVar], loc), loc))
          val tableBinds =
              [(tablePat (tableNameVar, NONE, tableWitnessVar, loc), tableExp)]

          val insertLists =
              mapi
                (fn (rowIndex, row) =>
                    let
                      val index = Int.toString rowIndex
                    in
                      ListPair.mapEq
                        (fn (label, exp) =>
                            {label = label,
                             exp =
                               case exp of
                                 SOME exp => elabSQLExp elabExp exp
                               | NONE => appExp (defaultFunName,
                                                 unitCon loc, loc),
                             queryVar =
                               "_sql_insert_" ^ label ^ "_" ^ index ^ "_",
                             witnessVar =
                               "_sql_insert_" ^ label ^ "_" ^ index
                               ^ "_witness_"})
                        (insertLabels, row)
                      handle ListPair.UnequalLengths =>
                             (UserErrorUtils.enqueueError
                                (loc, ElaborateErrorSQL.NumberOfSQLInsertLabel);
                              nil)
                    end)
                insertRows
          val insertBinds =
              List.concat
                (map (map (fn {label, exp, queryVar, witnessVar} =>
                              (valuePat (queryVar, SOME witnessVar,
                                         NONE, loc),
                               exp)))
                     insertLists)
          val rowWitnessExps =
              map (fn row =>
                      P.PLRECORD (map (fn {label, witnessVar, ...} =>
                                          (label, P.PLVAR ([witnessVar], loc)))
                                      row, loc))
                  insertLists
          val witnessExp =
              makeList (tableWitnessExp :: rowWitnessExps, loc)
          val witnessBinds =
              [(P.PLPATWILD loc, witnessExp)]

          val join = join (stringCon (", ", loc))
          val insertQuery =
              stringDBICon ("INSERT INTO ", dbiVar, loc) ::
              tableNameExp ::
              stringCon (" (", loc) ::
              join (map (fn label => [stringCon (label, loc)]) insertLabels) @
              (stringCon (") VALUES ", loc) ::
               join (map (fn row =>
                             stringCon ("(", loc) ::
                             join (map (fn {queryVar, ...} =>
                                           [P.PLVAR ([queryVar], loc)])
                                       row) @
                             [stringCon (")", loc)])
                         insertLists))
        in
          P.PLLET
            (bindsToDecls (tableBinds, loc) @
             bindsToDecls (insertBinds, loc) @
             bindsToDecls (witnessBinds, loc),
             [commandCon (insertQuery, loc)],
             loc)
        end

      | S.SQLUPDATE {table=(dbVar, tableLabel), tableName, setListExps,
                     setLabels, fromClause, whereClause, loc} =>
        let
          val _ = UserErrorUtils.checkNameDuplication
                    (fn x => x) setLabels loc
                    ElaborateErrorSQL.DuplicateSQLSetLabel

          (*
           * UPDATE #db.t AS x SET (l_1, ..., l_n) = (e_1, ..., e_n)
           * ==>
           * (decls) val TABLE (_tabname_ as (_,_dbi_), _tab_witness_) =
           *             case db of DB ({t=w,...},i) => TABLE ((t,i),w)
           *         val x = ROW (("x", _dbi_), _tab_witness_)
           *         val VALUE (q_1, w_1) = e_1
           *         and ...
           *         and VALUE (q_n, w_n) = e_n
           *         val witness = [_tab_witness_, {l_1 = w_1, ..., l_n = w_n}]
           * (query) "UPDATE " ^ _tabname_ ^ " AS x "
           *         ^ "SET (l_1, " ^ ... ^ ", l_n)" ^ " = " ^
           *         ^ "(" ^ q_1 ^ ", " ^ ... ^ ", " ^ q_n ^ ")"
           *)

          val tableNameVar = "_sql_update_tabname_"
          val tableWitnessVar = "_sql_update_witness_"
          val tableDBIVar = "_sql_update_dbi_"
          val tableNameExp = P.PLVAR ([tableNameVar], loc)
          val tableWitnessExp = P.PLVAR ([tableWitnessVar], loc)
          val tableName =
              case tableName of NONE => "it" | SOME x => x

          val tableExp =
              elabExp (selectTable (tableLabel, A.EXPID ([dbVar], loc), loc))
          val tableBinds =
              [(tablePat (tableNameVar, SOME tableDBIVar, tableWitnessVar, loc),
                tableExp)]

          val rowBinds =
              [(P.PLPATID ([tableName], loc),
                rowCon (tableName, tableDBIVar, tableWitnessVar, loc))]
          val tableDecls =
              bindsToDecls (tableBinds, loc) @
              bindsToDecls (rowBinds, loc)

          val setList =
              ListPair.mapEq
                (fn (label, exp) =>
                    {label = label,
                     exp = elabSQLExp elabExp exp,
                     queryVar = "_sql_update_" ^ label ^ "_",
                     witnessVar = "_sql_update_" ^ label ^ "_witness_"})
                (setLabels, setListExps)
              handle ListPair.UnequalLengths =>
                     (UserErrorUtils.enqueueError
                        (loc, ElaborateErrorSQL.NumberOfSQLSetLabel);
                      nil)
          val setBinds =
              map (fn {label, exp, queryVar, witnessVar} =>
                      (valuePat (queryVar, SOME witnessVar, NONE, loc), exp))
                  setList
          val setWitnessExp =
              P.PLRECORD (map (fn {label, witnessVar, ...} =>
                                  (label, P.PLVAR ([witnessVar], loc)))
                              setList, loc)

          val witnessExp =
              P.PLRECORD_UPDATE
                (tableWitnessExp,
                 map (fn {label, witnessVar, ...} =>
                         (label, P.PLVAR ([witnessVar], loc)))
                     setList,
                 loc)
          val witnessBinds =
              [(P.PLPATWILD loc, witnessExp)]

          val (fromDecls, fromQuery) =
              elabFromClause elabExp fromClause loc
          val (whereDecls, whereQuery) =
              elabWhereClause elabExp whereClause loc

          val join = join (stringCon (", ", loc))
          val updateQuery =
              stringDBICon ("UPDATE ", dbiVar, loc) ::
              tableNameExp ::
              stringCon (" AS \"" ^ tableName ^ "\" SET (" , loc) ::
              join (map (fn label => [stringCon (label, loc)]) setLabels) @
              (stringCon (") = (", loc) ::
               join (map (fn {queryVar, ...} => [P.PLVAR ([queryVar], loc)])
                         setList) @
               [stringCon (")", loc)]) @
              fromQuery @
              whereQuery
        in
          P.PLLET
            (tableDecls @ fromDecls @ whereDecls @
             bindsToDecls (setBinds, loc) @
             bindsToDecls (witnessBinds, loc),
             [commandCon (updateQuery, loc)],
             loc)
        end

      | S.SQLDELETE {table=(dbVar, tableLabel), tableName, whereClause, loc} =>
        let
          (*
           * DELETE FROM #db.t AS x
           * ==>
           * (decls) val (_tabname_, x) =
           *             case #db.t of TABLE (t as (_,i),w) =>
           *                           (t, ROW (("x", i), w))
           * (query) "DELETE FROM " ^ _tabname_ ^ " AS x"
           *)
          val tableNameVar = "_sql_delete_tabname_"
          val tableWitnessVar = "_sql_delete_witness_"
          val tableNameExp = P.PLVAR ([tableNameVar], loc)
          val tableWitnessExp = P.PLVAR ([tableWitnessVar], loc)

          val tableName =
              case tableName of NONE => "it" | SOME x => x
          val tableExp =
              selectTable (tableLabel, A.EXPID ([dbVar], loc), loc)

          val (fromDecls, fromQuery) =
              elabFromClause elabExp [(tableName, tableExp)] loc
          val (whereDecls, whereQuery) =
              elabWhereClause elabExp whereClause loc
        in
          P.PLLET
            (fromDecls @ whereDecls,
             [commandCon (stringDBICon ("DELETE", dbiVar, loc)
                          :: fromQuery @ whereQuery,
                          loc)],
             loc)
        end

      | S.SQLBEGIN loc =>
        commandCon ([stringDBICon ("BEGIN", dbiVar, loc)], loc)
      | S.SQLCOMMIT loc =>
        commandCon ([stringDBICon ("COMMIT", dbiVar, loc)], loc)
      | S.SQLROLLBACK loc =>
        commandCon ([stringDBICon ("ROLLBACK", dbiVar, loc)], loc)

  fun elaborateExp {elabExp, elabPat}
                   (sqlexp : (A.exp,A.pat,A.ty) S.exp) =
      case sqlexp of
        S.SQLFIELDSELECT (label, exp, loc) =>
        elabExp (selectColumn (label, exp, loc))
      | S.SQLFN (pat, sql, loc) =>
        let
          val dbiVar = "_sqlfn_dbi_"
        in
          P.PLFNM
            ([([P.PLPATLAYERED (dbiVar, NONE, elabPat pat, loc)],
               caseExp
                 (P.PLVAR ([dbiVar], loc),
                  P.PLPATCONSTRUCT
                    (P.PLPATID (SQLDBConName, loc),
                     pairPat (P.PLPATWILD loc, P.PLPATID ([dbiVar], loc), loc),
                     loc),
                    elaborateCommand elabExp dbiVar sql,
                    loc))],
             loc)
        end
      | S.SQLEXEC (exp, loc) =>
        let
          val dbiVar = ["_sqlexec_dbi_"]
        in
          P.PLSQLDBI
            (P.PLPATID (dbiVar, loc),
             appExp (execFunName,
                     pairCon (P.PLVAR (dbiVar, loc), elabExp exp, loc),
                     loc),
             loc)
        end
      | S.SQLEVAL (exp, loc) =>
        let
          val dbiVar = ["_sqlexec_dbi_"]
        in
          P.PLSQLDBI
            (P.PLPATID (dbiVar, loc),
             appExp (evalFunName,
                     pairCon (P.PLVAR (dbiVar, loc), elabExp exp, loc),
                     loc),
             loc)
        end
      | S.SQLSERVER (strs, schema, loc) =>
        let
          val _ = UserErrorUtils.checkNameDuplication
                    #1 strs loc
                    ElaborateErrorSQL.DuplicateSQLRecordLabel
          fun isAvailableLabel s =
              s = "" orelse
              s = "dbname" orelse
              s = "host" orelse
              s = "hostaddr" orelse
              s = "port" orelse
              s = "user" orelse
              s = "password" orelse
              s = "connect_timeout" orelse
              s = "options" orelse
              s = "tty" orelse
              s = "sslmode" orelse
              s = "requiressl" orelse
              s = "krbsrvname" orelse
              s = "gsslib" orelse
              s = "service"
          val strs =
              map (fn (l,v) =>
                      if (isAvailableLabel l)
                      then (l, elabExp v)
                      else raise ElaborateErrorSQL.NotAvailableSQLKeyword l)
                  strs
        in
          P.PLSQLSERVER (strs, schema, loc)
        end

end
