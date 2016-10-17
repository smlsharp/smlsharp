(**
 * ElaboratorSQL.sml
 * @copyright (c) 2009-2016, Tohoku University.
 * @author UENO Katsuhiro
 * @author ENDO Hiroki
 *)

structure ElaborateSQL =
struct

  structure EU = UserErrorUtils
  structure E = ElaborateErrorSQL

  structure A = Absyn
  structure S = AbsynSQL
  structure P = PatternCalc
  type loc = Loc.loc
  val noloc = Loc.noloc
  type symbol = Symbol.symbol
  type longsymbol = Symbol.longsymbol
  type exp = A.exp
  type pat = A.pat

  val mkLongsymbol = Symbol.mkLongsymbol

(*
  val SQLSchemaConName = mkLongsymbol ["SMLSharp_SQL_Prim", "SCHEMA"]
  val execFunName = mkLongsymbol ["SMLSharp_SQL_Prim", "exec"]
  val evalFunName = mkLongsymbol ["SMLSharp_SQL_Prim", "eval"]
  val sqlserverFunName = mkLongsymbol ["SMLSharp_SQL_Prim", "sqlserver"]
*)

  val columnInfoFunName = mkLongsymbol ["SMLSharp_SQL_Prim", "columnInfo"]

(*
  val columnInfoFunName = mkLongsymbol ["SQL", "columnInfo"]
  val fromSQLFunName = mkLongsymbol ["SMLSharp_SQL_Prim", "fromSQL"]
*)

  fun mapi f l =
      let fun loop f n nil = nil
            | loop f n (h::t) = f (n, h) :: loop f (n+1) t
      in loop f 0 l
      end

  (* FIXME: labels may include characters that are not allowed in SQL or ML *)
  fun labelToSQLName label =
      RecordLabel.toString label

  fun symbolToSQLName sym =
      labelToSQLName (RecordLabel.fromSymbol sym)

  (* FIXME: labels may include characters that are not allowed in ML vars *)
  fun labelToSymbol label loc =
      Symbol.mkSymbol (RecordLabel.toString label) loc

  fun primName s = mkLongsymbol ["SMLSharp_SQL_Prim", s]

(*
  fun primName s = mkLongsymbol ["SQL", s]
*)

  fun Embed x (_:P.loc) = x

  fun PatVar var (_:P.loc) =
      P.PLPATID [var]

  fun PatVar' var loc =
      P.PLPATID [var loc]

  fun PatWild loc =
      P.PLPATWILD loc

  fun PatRecord nil loc =
      P.PLPATCONSTANT (A.UNITCONST loc)
    | PatRecord fields loc =
      P.PLPATRECORD
        (false, map (fn (label, pat) => (label, pat loc)) fields, loc)

  fun PatTuple pats =
      PatRecord (RecordLabel.tupleList pats)

  fun PatAs (var, pat) loc =
      P.PLPATLAYERED (var, NONE, pat loc, loc)

  fun PatCon (name, [pat]) loc =
      P.PLPATCONSTRUCT (P.PLPATID (name loc), pat loc, loc)
    | PatCon (name, pats) loc =
      P.PLPATCONSTRUCT (P.PLPATID (name loc), PatTuple pats loc, loc)

  fun PatTyped (pat, ty) loc =
      P.PLPATTYPED (pat loc, ty loc, loc)

  fun Int n loc =
      P.PLCONSTANT
        (A.INT ({radix = StringCvt.DEC, digits = Int.toString n}, loc))

  fun String s loc =
      P.PLCONSTANT (A.STRING (s, loc))

  fun Var var (_:P.loc) =
      P.PLVAR [var]

  fun ExVar longid loc =
      P.PLVAR (primName longid loc)

  fun Record nil loc =
      P.PLCONSTANT (A.UNITCONST loc)
    | Record fields loc =
      P.PLRECORD (map (fn (label, exp) => (label, exp loc)) fields, loc)

  fun Tuple exps =
      Record (RecordLabel.tupleList exps)

  fun Select (label, exp) loc =
      P.PLSELECT (label, exp loc, loc)

  fun Selector label loc =
      P.PLRECORD_SELECTOR (label, loc)

  fun Modify exp1 fields loc =
      P.PLRECORD_UPDATE
        (exp1 loc, map (fn (label, exp) => (label, exp loc)) fields, loc)

  fun Call (name, [exp]) loc =
      P.PLAPPM (P.PLVAR (primName name loc), [exp loc], loc)
    | Call (name, exps) loc =
      P.PLAPPM (P.PLVAR (primName name loc), [Tuple exps loc], loc)

  fun Fn (pat, exp) loc =
      P.PLFNM ([([pat loc], exp loc)], loc)

  fun App (exp1, exp2) loc =
      P.PLAPPM (exp1 loc, [exp2 loc], loc)

  fun FnV bodyFn =
      let
        val v = Symbol.generate ()
      in
        Fn (PatVar v, bodyFn (Var v))
      end

  fun Case1 (exp, pat1, exp1) loc =
      P.PLCASEM ([exp loc], [([pat1 loc], exp1 loc)], P.MATCH, loc)

  (* use "case" instead of "let" to avoid type generalization. *)
  fun Let nil body = body
    | Let ((pat, exp)::t) body = Case1 (exp, pat, Let t body)

  fun Cons (exp1, exp2) loc =
      P.PLAPPM
        (P.PLVAR (mkLongsymbol ["::"] loc), [Tuple [exp1, exp2] loc], loc)

  fun Nil loc =
      P.PLVAR (mkLongsymbol ["nil"] loc)

  fun List exps =
      foldr Cons Nil exps

  fun newTvar prefix =
      ({symbol = Symbol.generateWithPrefix prefix, eq = A.NONEQ}, A.UNIV)
      : A.kindedTvar

  fun Tyvar ((t,_):A.kindedTvar) loc =
      A.TYID (t, loc)

  fun Join (exp1, exp2) loc =
      P.PLJOIN (exp1 loc, exp2 loc, loc)


  datatype view =
      TABLE
    | AS of view * Symbol.symbol
    | JOIN of view * view
    | NATURALJOIN of view * view

  datatype view2 =
      MAP of view * RecordLabel.label list

  fun viewNames view =
      case view of
        TABLE => nil
      | AS (view, var) => var :: viewNames view
      | JOIN (view1, view2) => viewNames view1 @ viewNames view2
      | NATURALJOIN (view1, view2) => viewNames view1 @ viewNames view2

  fun viewToPat view =
      case view of
        TABLE => PatWild
      | AS (view, var) => PatVar var
      | JOIN (view1, view2) => PatTuple [viewToPat view1, viewToPat view2]
      | NATURALJOIN (view1, view2) =>
        PatTuple [viewToPat view1, viewToPat view2]

  fun isNatural view =
      case view of
        TABLE => true
      | AS (view, _) => isNatural view
      | JOIN _ => false
      | NATURALJOIN _ => true

  fun selector label =
      Tuple [Selector label, String (labelToSQLName label)]

  (* openDB : ('w -> unit) * 'a db -> ('a,'w) db' *)
  fun openDB (t, exp) =
      Call ("openDB", [Fn (PatTyped (PatWild, Tyvar t), Record nil), exp])

  (* readRow : ('a,'w) table5 -> ('a,'w) toy *)
  fun readRow exp =
      Call ("readRow", [exp])

  (* getValue : ('a,'w) row * ('a,'b) selector -> ('b,'w) value *)
  fun getValue (exp, label) =
      Call ("getValue", [exp, selector label])

  (* readValue : ('a,'w) value -> qexp * ('a,'w) toy *)
  fun readValue exp =
      Call ("readValue", [exp])

  (* getTable : ('a,'w) db' * ('a,'b) selector -> ('b,'w) table *)
  fun getTable (exp, label) =
      Call ("getTable", [exp, selector label])

  (* getDefault : ('a,'w) table * ('a,'b option) selector
                  -> ('b option,'w) value *)
  fun getDefault (exp, label) =
      Call ("getDefault", [exp, selector label])

  (* useTable : ('a,'w) table -> ('a, ('a,'w) row, 'w) table1 *)
  fun useTable exp =
      (Call ("useTable", [exp]), TABLE)

  (* aliasTable : ('a,'b,'w) table1 -> ('a,('a,'w) row,'w) table1 *)
  fun aliasTable ((exp, view), var) =
      (Call ("aliasTable", [exp, String (symbolToSQLName var)]), AS (view, var))

  fun useTableAs (exp, NONE) = useTable exp
    | useTableAs (exp, SOME var) = aliasTable (useTable exp, var)

  (* crossJoin : ('a,'b,'w) table1 * ('c,'d,'w) table1
                 -> ('a * 'c, 'b * 'd, 'w) table1 *)
  fun crossJoin ((exp1, view1), (exp2, view2)) =
      (Call ("crossJoin", [exp1, exp2]), JOIN (view1, view2))

  (* innerJoin : ('a,'b,'w) table1 * ('c,'d,'w) table1 *
                 ('b * 'd -> 'w bool_value)
                 -> ('a * 'c, 'b * 'd, 'w) table1 *)
  fun innerJoin ((exp1, view1), (exp2, view2), condExp) =
      let
        val view = JOIN (view1, view2)
      in
        (Call ("innerJoin", [exp1, exp2, Fn (viewToPat view, condExp)]), view)
      end

  (* naturalJoin : ('a,'b,'w) table1 * ('c,'d,'w) table1 * ('a * 'c -> 'e)
                   -> ('e, 'b * 'd, 'w) table1 *)
  fun naturalJoin ((exp1, view1), (exp2, view2)) =
      let
        val x = Symbol.generate ()
        val y = Symbol.generate ()
        val join = Fn (PatTuple [PatVar x, PatVar y], Join (Var x, Var y))
      in
        (Call ("naturalJoin", [exp1, exp2, join]), NATURALJOIN (view1, view2))
      end

  (* dummyJoin : ('a,'b,'w) table1 -> ('a * unit, 'b, 'w) table1 *)
  fun dummyJoin (exp, view) =
      (Call ("dummyJoin", [exp]), view)

  (* subquery : ('a db -> 'b query) * ('a,'w) db' * string
                -> ('b,('b,'w) row,'w) table1 *)
  fun subquery (exp1, exp2, var) =
      (Call ("subquery", [exp1, exp2, String (symbolToSQLName var)]),
       AS (TABLE, var))

  (* sourceTable : ('a,'b,'w) table1 -> ('a,'b,'w) table2 *)
  fun sourceTable (exp, view) =
      (Call ("sourceTable", [exp]), view)

  (* useDual : unit -> (unit, unit, 'a) table2 *)
  fun useDual () =
      (Call ("useDual", []), TABLE)

  (* chooseRows : ('a,'b,'w) table2 * ('b -> 'w bool_value)
                  -> ('a,'b,'w) table3 *)
  fun chooseRows condExp (exp, view) =
      (Call ("chooseRows", [exp, Fn (viewToPat view, condExp)]), view)

  (* chooseAll : ('a,'b,'w) table2 -> ('a,'b,'w) table3 *)
  fun chooseAll (exp, view) =
      (Call ("chooseAll", [exp]), view)

  (* mapTable : ('a,'b,'w) table3 * ('b -> ('c,'w) raw_row)
                -> ('a * 'c, 'b * ('c,'w) row, 'w) table4 *)
  fun mapTable (mapExp, selectLabels) (exp, view) =
      (Call ("mapTable", [exp, Fn (viewToPat view, mapExp)]),
       MAP (view, selectLabels))

  fun view2ToMatch (MAP (view, labels), exp) =
      let
        val x = Symbol.generate ()
      in
        (PatTuple [viewToPat view, PatVar x],
         Let (map (fn l => (PatVar' (labelToSymbol l), getValue (Var x, l)))
                  labels)
             exp)
      end

  (* sortTableAsc : ('a,'b,'w) table4 * ('b -> ('c,'w) value)
                    -> ('a,'b,'w) table4 *)
  fun sortTableAsc keyExp (exp, view) =
      (Call ("sortTableAsc", [exp, Fn (view2ToMatch (view, keyExp))]), view)

  (* sortTableDesc : ('a,'b,'w) table4 * ('b -> ('c,'w) value)
                     -> ('a,'b,'w) table4 *)
  fun sortTableDesc keyExp (exp, view) =
      (Call ("sortTableDesc", [exp, Fn (view2ToMatch (view, keyExp))]), view)

  (* selectDistinct : ('a*'b,'c,'w) table4 -> ('b,'w) table5 *)
  fun selectDistinct (exp, view) =
      Call ("selectDistinct", [exp])

  (* selectAll : ('a*'b,'c,'w) table4 -> ('b,'w) table5 *)
  fun selectAll (exp, view) =
      Call ("selectAll", [exp])

  (* selectDefault : ('a*'b,'c,'w) table4 -> ('b,'w) table5 *)
  fun selectDefault (exp, view) =
      Call ("selectDefault", [exp])

  (* makeQuery : ('a,'w) table5 * (SMLSharp_SQL_Backend.res_impl -> 'a)
                 -> ('d,'w) db' -> ('a,'w) query *)
  fun makeQuery (exp, recvFn) =
      let
        val arg = Symbol.generate ()
      in
        Call ("makeQuery", [exp, Fn (PatVar arg, recvFn (Var arg))])
      end

  (* deleteRows : ('a,'b,'w) table3 -> ('d,'w) db' -> 'w command *)
  fun deleteRows (exp, view) =
      Call ("deleteRows", [exp])

  (* updateRows : ('a * 'b, 'c, 'w) table3 * ('c * 'a toy -> ('a,'w) raw_row)
                  -> ('d,'w) db' -> 'w command *)
  fun updateRows (defaultVar, setExp) (exp, view) =
      Call ("updateRows",
            [exp, Fn (PatTuple [viewToPat view, PatVar defaultVar], setExp)])

  (* insertRows : ('a,'w) table * ('a,'w) raw_row list
                  -> ('d,'w) db' -> 'w command *)
  fun insertRows (exp, valuesExp) =
      Call ("insertRows", [exp, valuesExp])

  (* beginTransaction : ('d,'w) db' -> 'w command *)
  fun beginTransaction () =
      ExVar "beginTransaction"

  (* commitTransaction : ('d,'w) db' -> 'w command *)
  fun commitTransaction () =
      ExVar "commitTransaction"

  (* rollbackTransaction : ('d,'w) db' -> 'w command *)
  fun rollbackTransaction () =
      ExVar "rollbackTransaction"

  (* fromSQL : int * res_impl * (unit -> 'a) -> 'a *)
  fun fromSQL (index, res, label, toy) =
      Call ("fromSQL",
            [Int index, res, FnV (fn x => Select (label, App (toy, x)))])

  fun elabFrom (env as {elabExp, db}) from =
      case from of
        S.SQLTABLE (db, label, var) =>
        useTableAs (getTable (Var db, label), var)
      | S.SQLEXP (exp, var) =>
        subquery (Embed (elabExp exp), db, var)
      | S.SQLINNERJOIN (from1, from2, sqlexp) =>
        innerJoin (elabFrom env from1,
                   elabFrom env from2,
                   Embed (elabExp sqlexp))
      | S.SQLCROSSJOIN (from1, from2) =>
        crossJoin (elabFrom env from1, elabFrom env from2)
      | S.SQLNATURALJOIN (from1, from2, loc) =>
        let
          val expview1 as (_, view1) = elabFrom env from1
          val expview2 as (_, view2) = elabFrom env from2
        in
          if isNatural view1 andalso isNatural view2
          then ()
          else EU.enqueueError (loc, E.UnnaturalNaturalJoin);
          naturalJoin (elabFrom env from1, elabFrom env from2)
        end
      | S.SQLAS (from, var, loc) =>
        let
          val expview as (_, view) = elabFrom env from
        in
          if isNatural view
          then ()
          else EU.enqueueError (loc, E.OnlyNaturalJoinCanBeNamed var);
          aliasTable (expview, var)
        end

  fun elabFromList env nil = NONE
    | elabFromList env [from] = SOME (elabFrom env from)
    | elabFromList env (from1::t) =
      SOME (foldl (fn (from, z) => crossJoin (elabFrom env from, z))
                  (elabFrom env from1)
                  t)

  fun makeRecord con loc fields =
      let
        val fields =
            map (fn (label, exp) =>
                    {label = label,
                     query = Symbol.generate (),
                     toy = Symbol.generate (),
                     exp = exp})
                fields
      in
        Let
          (map (fn {query,toy,exp,...} =>
                   (PatTuple [PatVar query, PatVar toy], readValue exp))
               fields)
          (Tuple
             [List (map (fn {label,query,...} =>
                            Tuple [String (labelToSQLName label), Var query])
                        fields),
              FnV (fn x =>
                      con x (map (fn {label,toy,...} =>
                                     (label, App (Var toy, x)))
                                 fields))])
      end

  fun elabWhere {elabExp,db} NONE = chooseAll
    | elabWhere {elabExp,db} (SOME exp) = chooseRows (Embed (elabExp exp))

  fun elabCommand (env as {elabExp, db}) sql =
      case sql of
        S.SQLSELECT {distinct, selectListExps, selectLabels,
                     fromClause, whereClause, orderByClause, loc} =>
        let
          val selectList =
              case selectLabels of
                NONE => RecordLabel.tupleList selectListExps
              | SOME labels =>
                (EU.checkRecordLabelDuplication
                   (fn x => x)
                   labels
                   loc
                   E.DuplicateSQLSelectLabel;
                 ListPair.zipEq (labels, selectListExps)
                 handle ListPair.UnequalLengths =>
                        raise Bug.Bug "elabCommand: SQLSELECT")
          val selectList =
              map (fn (label, exp) => (label, Embed (elabExp exp))) selectList
          val fromClause =
              case elabFromList env fromClause of
                NONE => useDual ()
              | SOME expview =>
                let
                  val _ = EU.checkSymbolDuplication
                            (fn x => x)
                            (viewNames (#2 expview))
                            E.DuplicateSQLTuple
                in
                  sourceTable expview
                end
          val selectFromWhere =
              mapTable
                (makeRecord (fn _ => Record) loc selectList,
                 map #1 selectList)
                (elabWhere env whereClause fromClause)
(*
          val row = case selectName of
                      NONE => Symbol.generate ()
                    | SOME x => x
*)
          val result = Symbol.generate ()
        in
          Let
            [(PatVar result,
              (case distinct of
                 NONE => selectDefault
               | SOME true => selectDistinct
               | SOME false => selectAll)
                (foldr
                   (fn ({keyExp, orderAsc}, z) =>
                       (if orderAsc then sortTableAsc else sortTableDesc)
                         (Embed (elabExp keyExp))
                         z)
                   selectFromWhere
                   orderByClause))]
            (makeQuery
               (Var result,
                fn res =>
                   Record
                     (mapi
                        (fn (i,(l,_)) =>
                            (l, fromSQL (i, res, l, readRow (Var result))))
                        selectList)))
        end
      | S.SQLINSERT {table=(dbVar, tableLabel), insertValues, insertLabels,
                     loc} =>
        let
          val _ = EU.checkRecordLabelDuplication
                    (fn x => x)
                    insertLabels
                    loc
                    E.DuplicateSQLInsertLabel
          val into = getTable (Var dbVar, tableLabel)
          val table = Symbol.generate ()
          val rows =
              map (fn row =>
                      map (fn (l, NONE) => (l, getDefault (Var table, l))
                            | (l, SOME e) => (l, Embed (elabExp e)))
                          (ListPair.zipEq (insertLabels, row)))
                  insertValues
              handle ListPair.UnequalLengths =>
                     (EU.enqueueError (loc, E.NumberOfSQLInsertLabel); nil)
        in
          Let
            [(PatVar table, getTable (Var dbVar, tableLabel))]
            (insertRows
               (Var table, List (map (makeRecord (fn _ => Record) loc) rows)))
        end
      | S.SQLUPDATE {table=(dbVar, tableLabel), tableName, setListExps,
                     setLabels, fromClause, whereClause, loc} =>
        let
          val updatee = getTable (Var dbVar, tableLabel)
          val updateeVar = Symbol.generate ()
          val expview1 = useTableAs ((Var updateeVar), tableName)
          val _ = EU.checkRecordLabelDuplication
                    (fn x => x)
                    setLabels
                    loc
                    E.DuplicateSQLSetLabel
          val set = ListPair.mapEq
                      (fn (l, SOME exp) => (l, Embed (elabExp exp))
                        | (l, NONE) => (l, getDefault (Var updateeVar, l)))
                      (setLabels, setListExps)
                    handle ListPair.UnequalLengths =>
                           (EU.enqueueError (loc, E.NumberOfSQLSetLabel); nil)
          val expview =
              case elabFromList env fromClause of
                NONE => dummyJoin expview1
              | SOME expview2 => crossJoin (expview1, expview2)
          val _ = EU.checkSymbolDuplication
                    (fn x => x)
                    (viewNames (#2 expview))
                    E.DuplicateSQLTuple
          val orig = Symbol.generate ()
        in
          Let [(PatVar updateeVar, updatee)]
              (updateRows
                 (orig, makeRecord (fn x => Modify (App (Var orig, x))) loc set)
                 ((elabWhere env whereClause)
                    (sourceTable expview)))
        end
      | S.SQLDELETE {table=(dbVar, tableLabel), tableName, whereClause, loc} =>
        deleteRows
          ((elabWhere env whereClause)
             (sourceTable
                (useTableAs
                   (getTable (Var dbVar, tableLabel), tableName))))
      | S.SQLBEGIN loc =>
        beginTransaction ()
      | S.SQLCOMMIT loc =>
        commitTransaction ()
      | S.SQLROLLBACK loc =>
        rollbackTransaction ()

  fun elaborateExp {elabExp, elabPat} (sqlexp : (A.exp,A.pat,A.ty) S.exp) =
      case sqlexp of
        S.SQLFIELDSELECT (label, exp, loc) =>
        getValue (Embed (elabExp exp), label) loc
      | S.SQLFN (pat, sql, loc) =>
        let
          val t = newTvar "_sql'"
          val db = Symbol.generate ()
          val db' = Symbol.generate ()
          val exp =
              Case1 (openDB (t, Var db),
                     PatAs (db', Embed (elabPat pat)),
                     App (elabCommand {elabExp = elabExp, db = Var db'} sql,
                          Var db'))
          val x = Symbol.generate ()
        in
          Fn (PatVar db,
              Embed (P.PLLET
                       ([P.PDVAL ([t], [(P.PLPATID [x], exp loc)], loc)],
                        [P.PLVAR [x]],
                        loc)))
             loc
        end
      | S.SQLEXEC (exp, loc) =>
        Call ("exec", [Embed (elabExp exp)]) loc
      | S.SQLEVAL (exp, loc) =>
        Call ("eval", [Embed (elabExp exp)]) loc
      | S.SQLSERVER (exp, schema, loc) =>
        Call ("sqlserver",
             [Embed (elabExp exp),
              Call ("SCHEMA",
                    [Embed
                       (P.PLSQLSCHEMA
                          {columnInfoFnExp = P.PLVAR (columnInfoFunName loc),
                           ty = schema,
                           loc = loc})])])
             loc

end
