structure AbsynFormatter =
struct
  structure A = Absyn
  structure S = AbsynSQL
  structure I = AbsynInterface
  structure P = PrintCalc

  fun mapOptionToList f NONE = nil
    | mapOptionToList f (SOME x) = [f x]

  fun printId (symbol, _) = P.ID symbol
  fun printLongid (strids, id, _) = P.LONGID (map printId strids, printId id)
  val printVid = printId
  val printLongvid = printLongid
  val printTycon = printId
  val printLongtycon = printLongid
  fun printLab (label, _) = P.LABEL label
  fun printTyvar (_, id) = P.TYVAR (printId id, nil)
  fun printTyvarseq NONE = nil
    | printTyvarseq (SOME (nil, _)) = [P.EMPTY]
    | printTyvarseq (SOME (tyvars, _)) = map printTyvar tyvars
  fun printOpLongvid (op1, longvid, _) = P.OPID (op1, printLongvid longvid)
  fun printRequirePath (path, _) = P.REQUIRE_PATH path

  fun printTy ty =
      case ty of
        A.TYVAR tyvar =>
        printTyvar tyvar
      | A.TYRECORD (rows, flex, _) =>
        P.EXPRECORD (map printTyrow rows, flex)
      | A.TYCON (args, tycon, _) =>
        P.TYCON (printTyseq args, printLongtycon tycon)
      | A.TYTUPLE (tys, _) =>
        P.TYTUPLE (map printTy tys)
      | A.TYFUN (ty1, ty2, _) =>
        P.TYFUN (printTy ty1, printTy ty2)
      | A.TYPAREN (ty, _) =>
        P.PAREN (printTy ty)
      | A.TYWILD _ =>
        P.PATWILD
      | A.TYVAR_FREE tyvar =>
        P.TYVAR_FREE (printKindedTyvar tyvar)
      | A.TYPOLY ((tyvars, _), ty, _) =>
        P.TYPOLY (map printKindedTyvar tyvars, printTy ty)

  and printKind kind =
      case kind of
        A.UNIV (props, _) =>
        map (P.KIND_ID o printId) props
      | A.REC (props, rows, _) =>
        map (P.KIND_ID o printId) props @ [P.KIND_RECORD (map printTyrow rows)]

  and printKindedTyvar (tyvar, kind, _) =
      P.TYVAR (printTyvar tyvar, getOpt (Option.map printKind kind, nil))

  and printTyrow (lab, ty, _) =
      P.TYROW (printLab lab, printTy ty)

  and printTyseq NONE = nil
    | printTyseq (SOME (nil, _)) = [P.EMPTY]
    | printTyseq (SOME (tys, _)) = map printTy tys

  fun printKindedTyvarseq NONE = nil
    | printKindedTyvarseq (SOME (nil, _)) = [P.EMPTY]
    | printKindedTyvarseq (SOME (tyvars, _)) = map printKindedTyvar tyvars

  fun printFfiAttr (attrs, _) =
      P.FFI_ATTR (map printId attrs)

  fun printFfiTy ty =
      case ty of
        A.FFITYVAR tyvar =>
        printTyvar tyvar
      | A.FFITYRECORD (rows, _) =>
        P.EXPRECORD (map printFfiTyrow rows, false)
      | A.FFITYCON (tys, tycon, _) =>
        P.TYCON (printFfiTyseq tys, printLongtycon tycon)
      | A.FFITYTUPLE (tys, _) =>
        P.TYTUPLE (map printFfiTy tys)
      | A.FFITYFUN (attr, arg, ret, _) =>
        P.FFITYFUN (Option.map printFfiAttr attr,
                    printFfiArg arg,
                    printFfiRet ret)
      | A.FFITYPAREN (ty, _) => P.PAREN (printFfiTy ty)

  and printFfiTyrow (lab, ty, _) =
      P.TYROW (printLab lab, printFfiTy ty)

  and printFfiTyseq NONE = nil
    | printFfiTyseq (SOME (nil, _)) = [P.EMPTY]
    | printFfiTyseq (SOME (tys, _)) = map printFfiTy tys

  and printFfiArg (argTys, vargTys, _) =
      P.FFI_ARG (map printFfiTy argTys, Option.map (map printFfiTy) vargTys)

  and printFfiRet (tys, _) =
      P.FFI_RET (map printFfiTy tys)

  fun printConstant const =
      case const of
        A.INT n => P.INT n
      | A.WORD n => P.WORD n
      | A.STRING s => P.STRING s
      | A.REAL s => P.REAL s
      | A.CHAR c => P.CHAR c
      | A.UNITCONST => P.EXPTUPLE nil

  val printStrid = printId
  val printSigid = printId
  val printFunid = printId
  val printLongstrid = printLongid
  fun printOpVid (op1, vid, _) = P.OPID (op1, printVid vid)

  fun printExistQuant NONE = nil
    | printExistQuant (SOME (nil, _)) = [P.EMPTY]
    | printExistQuant (SOME (tyvars, _)) = map printKindedTyvar tyvars

  fun printPat pat =
      case pat of
        A.PATWILD _ =>
        P.PATWILD
      | A.PATCONST (const, _) =>
        printConstant const
      | A.PATID vid =>
        printOpLongvid vid
      | A.PATRECORD (rows, flex, _) =>
        P.EXPRECORD (map printPatrow rows, flex)
      | A.PATTUPLE (pats, _) =>
        P.EXPTUPLE (map printPat pats)
      | A.PATLIST (pats, _) =>
        P.EXPLIST (map printPat pats)
      | A.PATPAREN (pat, _) =>
        P.PAREN (printPat pat)
      | A.PATAPP (pat1, pat2, _) =>
        P.EXPAPP (printPat pat1, printPat pat2)
      | A.PATINFIX (pat1, vid, pat2, _) =>
        P.EXPINFIX (printPat pat1, printVid vid, printPat pat2)
      | A.PATTYPED (pat, ty, _) =>
        P.EXPTYPED (printPat pat, printTy ty)
      | A.PATAS (vid, NONE, pat, _) =>
        P.PATAS (printOpVid vid, printPat pat)
      | A.PATAS (vid, SOME ty, pat, _) =>
        P.PATAS (P.EXPTYPED (printOpVid vid, printTy ty), printPat pat)

  and printPatrow patrow =
      case patrow of
        A.PATROW (lab, pat, _) =>
        P.EXPROW (printLab lab, printPat pat)
      | A.PATROWVAR (vid, NONE, NONE, _) =>
        printVid vid
      | A.PATROWVAR (vid, SOME ty, NONE, _) =>
        P.EXPTYPED (printVid vid, printTy ty)
      | A.PATROWVAR (vid, NONE, SOME pat, _) =>
        P.PATAS (printVid vid, printPat pat)
      | A.PATROWVAR (vid, SOME ty, SOME pat, _) =>
        P.PATAS (P.EXPTYPED (printVid vid, printTy ty), printPat pat)

  fun printExbind exbind =
      case exbind of
        A.EXBIND (vid, ty, _) =>
        P.CONBIND (printOpVid vid, Option.map printTy ty)
      | A.EXBINDREP (vid, longvid, _) =>
        P.VALBIND (printOpVid vid, printOpLongvid longvid)

  fun printTypbind (tyvarseq, tycon, ty, _) =
      P.TYPBIND (printTyvarseq tyvarseq,
                 printTycon tycon,
                 printTy ty)

  fun printConbind (vid, ty, _) =
      P.CONBIND (printOpVid vid, Option.map printTy ty)

  fun printDatbind (tyvarseq, tycon, conbinds, _) =
      P.DATBIND (printTyvarseq tyvarseq,
                 printTycon tycon,
                 map printConbind conbinds)

  fun printWithty (typbinds, _) =
      P.WITHTYPE (map printTypbind typbinds)

  fun printSqlTableSelector (vid, lab, _) =
      P.SQL_TABLE (printVid vid, printLab lab)

  fun printSqlAscDesc S.ASC = P.KEYWORD ["asc"]
    | printSqlAscDesc S.DESC = P.KEYWORD ["desc"]

  fun printSqlDistinctAll S.DISTINCT = P.KEYWORD ["distinct"]
    | printSqlDistinctAll S.ALL = P.KEYWORD ["all"]

  fun printSqlFirstNext S.FIRST = P.KEYWORD ["first"]
    | printSqlFirstNext S.NEXT = P.KEYWORD ["next"]

  fun printSqlRowRows S.ROW = P.KEYWORD ["row"]
    | printSqlRowRows S.ROWS = P.KEYWORD ["rows"]

  fun printSqlOp1 exp op1 =
      case op1 of
        S.IS_NULL => P.SQL_IS_NULL exp
      | S.IS_NOT_NULL => P.SQL_IS_NOT_NULL exp
      | S.IS_TRUE => P.SQL_IS_TRUE exp
      | S.IS_NOT_TRUE => P.SQL_IS_NOT_TRUE exp
      | S.IS_FALSE => P.SQL_IS_FALSE exp
      | S.IS_NOT_FALSE => P.SQL_IS_NOT_FALSE exp
      | S.IS_UNKNOWN => P.SQL_IS_UNKNOWN exp
      | S.IS_NOT_UNKNOWN => P.SQL_IS_NOT_UNKNOWN exp
      | S.NOT => P.SQL_NOT exp

  fun printSqlOp2 (exp1, exp2) op2 =
      case op2 of
        S.AND => P.SQL_AND (exp1, exp2)
      | S.OR => P.SQL_OR (exp1, exp2)

  fun printSqlInsertLabels (labs, _) =
      P.EXPTUPLE (map printLab labs)

  fun printExp exp =
      case exp of
        A.EXPCONST (const, _) =>
        printConstant const
      | A.EXPID vid =>
        printOpLongvid vid
      | A.EXPRECORD (rows, _) =>
        P.EXPRECORD (map printExprow rows, false)
      | A.EXPSELECT (lab, _) =>
        P.EXPSELECT (printLab lab)
      | A.EXPTUPLE (exps, _) =>
        P.EXPTUPLE (map printExp exps)
      | A.EXPLIST (exps, _) =>
        P.EXPLIST (map printExp exps)
      | A.EXPSEQ (exps, _) =>
        P.EXPSEQ (map printExp exps)
      | A.EXPLET (decs, (exps, _), _) =>
        P.EXPLET (map printDec decs, map printExp exps)
      | A.EXPPAREN (exp, _) =>
        P.PAREN (printExp exp)
      | A.EXPAPP (exp1, exp2, _) =>
        P.EXPAPP (printExp exp1, printExp exp2)
      | A.EXPINFIX (exp1, vid, exp2, _) =>
        P.EXPINFIX (printExp exp1, printVid vid, printExp exp2)
      | A.EXPTYPED (exp, ty, _) =>
        P.EXPTYPED (printExp exp, printTy ty)
      | A.EXPANDALSO (exp1, exp2, _) =>
        P.EXPANDALSO (printExp exp1, printExp exp2)
      | A.EXPORELSE (exp1, exp2, _) =>
        P.EXPORELSE (printExp exp1, printExp exp2)
      | A.EXPHANDLE (exp, mrules, _) =>
        P.EXPHANDLE (printExp exp, map printMrule mrules)
      | A.EXPRAISE (exp, _) =>
        P.EXPRAISE (printExp exp)
      | A.EXPIF (exp1, exp2, exp3, _) =>
        P.EXPIF (printExp exp1, printExp exp2, printExp exp3)
      | A.EXPWHILE (exp1, exp2, _) =>
        P.EXPWHILE (printExp exp1, printExp exp2)
      | A.EXPCASE (exp, mrules, _) =>
        P.EXPCASE (printExp exp, map printMrule mrules)
      | A.EXPFN (mrules, _) =>
        P.EXPFN (map printMrule mrules)
      | A.EXPSIZEOF (ty, _) =>
        P.EXPSIZEOF (printTy ty)
      | A.EXPRECORD_UPDATE (exp, exprows, _) =>
        P.EXPRECORD_UPDATE (printExp exp, map printExprow exprows)
      | A.EXPTUPLE_UPDATE (exp, exps, _) =>
        P.EXPTUPLE_UPDATE (printExp exp, map printExp exps)
      | A.EXPIMPORT_NAME ((name, _), ty, _) =>
        P.EXPIMPORT_NAME (P.STRING name, printFfiTy ty)
      | A.EXPIMPORT_EXP (exp, ffity, _) =>
        P.EXPIMPORT_EXP (printExp exp, printFfiTy ffity)
      | A.EXPSQL sqlexp =>
        printSqlTop sqlexp
      | A.EXPFOREACH_DATA (vid, exp1, exp2, pat, exp3, exp4, _) =>
        P.EXPFOREACH_DATA (printVid vid,
                           printExp exp1,
                           printExp exp2,
                           printPat pat,
                           printExp exp3,
                           printExp exp4)
      | A.EXPFOREACH_ARRAY (vid, exp1, pat, exp2, exp3, _) =>
        P.EXPFOREACH_ARRAY (printVid vid,
                            printExp exp1,
                            printPat pat,
                            printExp exp2,
                            printExp exp3)
      | A.EXPJOIN (exp1, exp2, _) =>
        P.EXPJOIN (printExp exp1, printExp exp2)
      | A.EXPEXTEND (exp1, exp2, _) =>
        P.EXPEXTEND (printExp exp1, printExp exp2)
      | A.EXPUPDATE1 (exp1, exp2, _) =>
        P.EXPUPDATE1 (printExp exp1, printExp exp2)
      | A.EXPUPDATE2 (exp1, exp2, _) =>
        P.EXPUPDATE2 (printExp exp1, printExp exp2)
      | A.EXPDYNAMIC_AS (exp, ty, _) =>
        P.EXPDYNAMIC_AS (printExp exp, printTy ty)
      | A.EXPDYNAMIC_OF (exp, ty, _) =>
        P.EXPDYNAMIC_OF (printExp exp, printTy ty)
      | A.EXPDYNAMICVIEW (exp, ty, _) =>
        P.EXPDYNAMICVIEW (printExp exp, printTy ty)
      | A.EXPDYNAMICNULL (ty, _) =>
        P.EXPDYNAMICNULL (printTy ty)
      | A.EXPDYNAMICTOP (ty, _) =>
        P.EXPDYNAMICTOP (printTy ty)
      | A.EXPDYNAMICCASE (exp, mrules, _) =>
        P.EXPDYNAMICCASE (printExp exp, map printDynamicMrule mrules)
      | A.EXPREIFYTY (ty, _) =>
        P.EXPREIFYTY (printTy ty)

  and printExprow exprow =
      case exprow of
        A.EXPROW (lab, exp, _) => P.EXPROW (printLab lab, printExp exp)
      | A.EXPROWVAR (vid, NONE, _) => printVid vid
      | A.EXPROWVAR (vid, SOME ty, _) => P.EXPTYPED (printVid vid, printTy ty)

  and printValbind valbind =
      case valbind of
        A.VALBIND (pat, exp, _) => P.VALBIND (printPat pat, printExp exp)
      | A.VALREC (valbinds, _) => P.VALREC (map printValbind valbinds)

  and printDec dec =
      case dec of
        A.DECVAL (tyvars, valbinds, _) =>
        P.DECVAL (printKindedTyvarseq tyvars, map printValbind valbinds)
      | A.DECVALREC (tyvars, valbinds, _) =>
        P.DECVALREC (printKindedTyvarseq tyvars, map printValrecbind valbinds)
      | A.DECFUN (tyvars, fvalbinds, _) =>
        P.DECFUN (printKindedTyvarseq tyvars, map printFvalbind fvalbinds)
      | A.DECTYPE (typbinds, _) =>
        P.DECTYPE (map printTypbind typbinds)
      | A.DECDATATYPE (datbinds, withty, _) =>
        P.DECDATATYPE (map printDatbind datbinds, Option.map printWithty withty)
      | A.DECDATATYPEREP (tycon, longtycon, _) =>
        P.DECDATATYPEREP (printTycon tycon, printLongtycon longtycon)
      | A.DECABSTYPE (datbinds, withty, decs, _) =>
        P.DECABSTYPE (map printDatbind datbinds,
                      Option.map printWithty withty,
                      map printDec decs)
      | A.DECEXCEPTION (exbinds, _) =>
        P.DECEXCEPTION (map printExbind exbinds)
      | A.DECLOCAL (decs1, decs2, _) =>
        P.DECLOCAL (map printDec decs1, map printDec decs2)
      | A.DECOPEN (strids, _) =>
        P.DECOPEN (map printLongstrid strids)
      | A.DECSEMICOLON _ =>
        P.SEMICOLON
      | A.DECINFIX (prec, vids, _) =>
        P.DECINFIX (Option.map P.STRING prec, map printVid vids)
      | A.DECINFIXR (prec, vids, _) =>
        P.DECINFIXR (Option.map P.STRING prec, map printVid vids)
      | A.DECNONFIX (vids, _) =>
        P.DECNONFIX (map printVid vids)
      | A.DECDO (exp, _) =>
        P.DECDO (printExp exp)

  and printMrule (pat, exp, _) =
      P.MRULE (printPat pat, printExp exp)

  and printDynamicMrule (exists, pat, exp, _) =
      P.DYNAMIC_MRULE (printExistQuant exists, printPat pat, printExp exp)

  and printFrule (pat, ty, exp, _) =
      P.FRULE (printPat pat, Option.map printTy ty, printExp exp)

  and printValrecbind (pat, exp, _) =
      P.VALBIND (printPat pat, printExp exp)

  and printFvalbind (frules, _) =
      P.FVALBIND (map printFrule frules)

  and printSqlExp exp =
      case exp of
        S.EXP_EMBED (exp, _) =>
        P.SQL_EMBED (printExp exp)
      | S.CONST (const, _) =>
        printConstant const
      | S.NULL _ =>
        P.KEYWORD ["null"]
      | S.TRUE _ =>
        P.KEYWORD ["true"]
      | S.FALSE _ =>
        P.KEYWORD ["false"]
      | S.COLUMN1 (lab, _) =>
        P.SQL_COLUMN1 (printLab lab)
      | S.COLUMN2 (lab1, lab2, _) =>
        P.SQL_COLUMN2 (printLab lab1, printLab lab2)
      | S.KWEXP (sql, kwexp, _) =>
        P.SQLPREFIX (sql, printSqlKwexp kwexp)
      | S.EXP_SUBQUERY (sql, query, _) =>
        P.PAREN (P.SQLPREFIX (sql, printSqlQuery query))
      | S.OP1 (op1, exp, _) =>
        printSqlOp1 (printSqlExp exp) op1
      | S.OP2 (op2, exp1, exp2, _) =>
        printSqlOp2 (printSqlExp exp1, printSqlExp exp2) op2
      | S.ID vid =>
        printOpLongvid vid
      | S.PAREN (exp, _) =>
        P.PAREN (printSqlExp exp)
      | S.APP (exp1, exp2, _) =>
        P.EXPAPP (printSqlExp exp1, printSqlExp exp2)
      | S.INFIX (exp1, vid, exp2, _) =>
        P.EXPINFIX (printSqlExp exp1, printVid vid, printSqlExp exp2)
      | S.CAST (vid, exp, _) =>
        P.SQL_CAST (printVid vid, printSqlExp exp)
      | S.TUPLE (exps, _) =>
        P.EXPTUPLE (map printSqlExp exps)

  and printSqlKwexp kwexp =
      case kwexp of
        S.EXISTS (query, _) =>
        P.SQL_EXISTS (printSqlQuery query)

  and printSqlTable table =
      case table of
        S.TABLE table =>
        printSqlTableSelector table
      | S.TABLE_AS (table, lab, _) =>
        P.SQL_TABLE_AS (printSqlTable table, printLab lab)
      | S.TABLE_INNER_JOIN (table1, inner, table2, exp, _) =>
        P.SQL_TABLE_INNER_JOIN (printSqlTable table1,
                                inner,
                                printSqlTable table2,
                                printSqlExp exp)
      | S.TABLE_CROSS_JOIN (table1, table2, _) =>
        P.SQL_TABLE_CROSS_JOIN (printSqlTable table1, printSqlTable table2)
      | S.TABLE_NATURAL_JOIN (table1, table2, _) =>
        P.SQL_TABLE_NATURAL_JOIN (printSqlTable table1, printSqlTable table2)
      | S.TABLE_SUBQUERY (sql, query, _) =>
        P.PAREN (P.SQLPREFIX (sql, printSqlQuery query))
      | S.TABLE_PAREN (table, _) =>
        P.PAREN (printSqlTable table)

  and printSqlFrom from =
      case from of
        S.FROM (tables, _) =>
        P.SQL_FROM (map printSqlTable tables)
      | S.FROM_EMBED (exp, _) =>
        P.SQL_CLAUSE_EMBED (P.KEYWORD ["from"], printExp exp)

  and printSqlWhr whr =
      case whr of
        S.WHERE (exp, _) =>
        P.SQL_WHERE (printSqlExp exp)
      | S.WHERE_EMBED (exp, _) =>
        P.SQL_CLAUSE_EMBED (P.KEYWORD ["where"], printExp exp)

  and printSqlGroupby (S.GROUPBY (groupby, having, _)) =
      P.SQL_SUBCLAUSE
        (printSqlGroupbyClause groupby,
         Option.map printSqlHavingClause having)

  and printSqlOrderby orderby =
      case orderby of
        S.ORDERBY (keys, _) =>
        P.SQL_ORDERBY (map printSqlOrderKey keys)
      | S.ORDERBY_EMBED (exp, _) =>
        P.SQL_CLAUSE_EMBED (P.KEYWORD ["order", "by"], printExp exp)

  and printSqlLimit limit =
      case limit of
        S.LIMIT (limit, offset, _) =>
        P.SQL_SUBCLAUSE
          (printSqlLimitClause limit,
           Option.map printSqlLimitOffsetClause offset)
      | S.LIMIT_EMBED (exp, _) =>
        P.SQL_CLAUSE_EMBED (P.KEYWORD ["limit"], printExp exp)

  and printSqlOffset offset =
      case offset of
        S.OFFSET (offset, fetch, _) =>
        P.SQL_SUBCLAUSE
          (printSqlOffsetClause offset,
           Option.map printSqlFetchClause fetch)
      | S.OFFSET_EMBED (exp, _) =>
        P.SQL_CLAUSE_EMBED (P.KEYWORD ["offset"], printExp exp)

  and printSqlSelect select =
      case select of
        S.SELECT (distinct, (rows, _), _) =>
        P.SQL_SELECT
          (Option.map printSqlDistinctAll distinct,
           map printSqlSelectRow rows)
      | S.SELECT_EMBED (exp, _) =>
        P.SQL_CLAUSE_EMBED (P.KEYWORD ["select"], printExp exp)

  and printSqlQuery query =
      case query of
        S.QUERY (select, from, whr, groupby, orderby, offset, _) =>
        P.SQL_QUERY
          (printSqlSelect select,
           printSqlFrom from,
           mapOptionToList printSqlWhr whr
           @ mapOptionToList printSqlGroupby groupby
           @ mapOptionToList printSqlOrderby orderby
           @ mapOptionToList printSqlOffsetOrLimit offset)
      | S.QUERY_EMBED (exp, _) =>
        P.SQL_CLAUSE_EMBED (P.KEYWORD ["select"], printExp exp)

  and printSqlOffsetOrLimit offset =
      case offset of
        S.OFFSET_CLAUSE offset => printSqlOffset offset
      | S.LIMIT_CLAUSE limit => printSqlLimit limit

  and printSqlOrderKey (exp, asc, _) =
      P.SQL_ORDER_KEY (printSqlExp exp, Option.map printSqlAscDesc asc)

  and printSqlSelectRow (exp, lab, _) =
      P.SQL_SELECT_ROW (printSqlExp exp, Option.map printLab lab)

  and printSqlGroupbyClause (exps, _) =
      P.SQL_GROUPBY (map printSqlExp exps)

  and printSqlHavingClause (exp, _) =
      P.SQL_HAVING (printSqlExp exp)

  and printSqlLimitClause (exp, _) =
      P.SQL_LIMIT (Option.map printSqlExp exp)

  and printSqlLimitOffsetClause (exp, _) =
      P.SQL_LIMIT_OFFSET (printSqlExp exp)

  and printSqlOffsetClause (exp, rows, _) =
      P.SQL_OFFSET (printSqlExp exp, printSqlRowRows rows)

  and printSqlFetchClause (first, exp, rows, _) =
      P.SQL_FETCH (printSqlFirstNext first,
               Option.map printSqlExp exp,
               printSqlRowRows rows)

  and printSqlInsertValue value =
      case value of
        S.VALUE exp => printSqlExp exp
      | S.DEFAULT _ => P.KEYWORD ["default"]

  and printSqlInsertRow (values, _) =
      P.EXPTUPLE (map printSqlInsertValue values)

  and printSqlInsertValues values =
      case values of
        S.INSERT_VALUES (rows, _) =>
        P.SQL_VALUES (map printSqlInsertRow rows)
      | S.INSERT_VAR (vid, _) =>
        P.SQL_VALUES [printOpLongvid vid]
      | S.INSERT_SELECT query =>
        printSqlQuery query

  and printSqlSetRow (lab, exp, _) =
      P.EXPROW (printLab lab, printSqlExp exp)

  and printSqlSet (rows, _) =
      P.SQL_SET (map printSqlSetRow rows)

  and printSqlCon con =
      case con of
        S.QRY query =>
        printSqlQuery query
      | S.SEL select =>
        printSqlSelect select
      | S.FRM from =>
        printSqlFrom from
      | S.WHR whr =>
        printSqlWhr whr
      | S.ORD orderby =>
        printSqlOrderby orderby
      | S.OFF offset =>
        printSqlOffset offset
      | S.LMT limit =>
        printSqlLimit limit
      | S.INSERT_LABELED (table, labels, values, _) =>
        P.SQL_INSERT_LABELED (printSqlTableSelector table,
                              printSqlInsertLabels labels,
                              printSqlInsertValues values)
      | S.INSERT_NOLABEL (table, query, _) =>
        P.SQL_INSERT_NOLABEL (printSqlTableSelector table,
                              printSqlQuery query)
      | S.UPDATE (table, set, whr, _) =>
        P.SQL_UPDATE (printSqlTableSelector table,
                      printSqlSet set,
                      Option.map printSqlWhr whr)
      | S.DELETE (table, whr, _) =>
        P.SQL_DELETE (printSqlTableSelector table, Option.map printSqlWhr whr)
      | S.BEGIN _ =>
        P.KEYWORD ["begin"]
      | S.COMMIT _ =>
        P.KEYWORD ["commit"]
      | S.ROLLBACK _ =>
        P.KEYWORD ["rollback"]

  and printSqlStep step =
      case step of
        S.STEP (sql, con, _) =>
        P.SQLPREFIX (sql, printSqlCon con)
      | S.STEP_EMBED (exp, _) =>
        P.SQL_STEP_EMBED (printExp exp)

  and printSqlBody body =
      case body of
        S.CON (sql, con, _) =>
        P.SQLPREFIX (sql, printSqlCon con)
      | S.EXP exp =>
        printSqlExp exp
      | S.SEQ (steps, _) =>
        P.EXPSEQ (map printSqlStep steps)
      | S.BODYPAREN (body, _) =>
        P.PAREN (printSqlBody body)

  and printSqlTop top =
      case top of
        S.SQLSERVER (exp, ty, _) =>
        P.SQLSERVER (Option.map printExp exp, printTy ty)
      | S.SQL (body, _) =>
        P.SQLPREFIX (true, printSqlBody body)
      | S.SQLFN (pat, body, _) =>
        P.SQLFN (printPat pat, printSqlBody body)

  fun printValdesc (vid, ty, _) =
      P.VALDESC (printVid vid, printTy ty)

  fun printTypdesc (tyvarseq, tycon, _) =
      P.TYPDESC (printTyvarseq tyvarseq, printTycon tycon)

  fun printCondesc (vid, ty, _) =
      P.CONBIND (printVid vid, Option.map printTy ty)

  fun printDatdesc (tyvarseq, tycon, condescs, _) =
      P.DATBIND (printTyvarseq tyvarseq,
                 printTycon tycon,
                 map printCondesc condescs)

  fun printExdesc (vid, ty, _) =
      P.CONBIND (printVid vid, Option.map printTy ty)

  fun printWheretype (tyvarseq, longtycon, ty, _) =
      P.TYPBIND (printTyvarseq tyvarseq, printLongtycon longtycon, printTy ty)

  fun printSpec spec =
      case spec of
        A.SPECVAL (valdescs, _) =>
        P.DECVAL (nil, map printValdesc valdescs)
      | A.SPECTYPE (typdescs, _) =>
        P.DECTYPE (map printTypdesc typdescs)
      | A.SPECTYPBIND (typbinds, _) =>
        P.DECTYPE (map printTypbind typbinds)
      | A.SPECEQTYPE (typdescs, _) =>
        P.SPECEQTYPE (map printTypdesc typdescs)
      | A.SPECDATATYPE (datdescs, _) =>
        P.DECDATATYPE (map printDatdesc datdescs, NONE)
      | A.SPECDATATYPEREP (tycon, longtycon, _) =>
        P.DECDATATYPEREP (printTycon tycon, printLongtycon longtycon)
      | A.SPECEXCEPTION (exdescs, _) =>
        P.DECEXCEPTION (map printExdesc exdescs)
      | A.SPECSTRUCTURE (strdescs, _) =>
        P.STRUCTURE (map printStrdesc strdescs)
      | A.SPECINCLUDE (sigexp, _) =>
        P.SPECINCLUDE [printSigexp sigexp]
      | A.SPECINCLUDE_ID (sigids, _) =>
        P.SPECINCLUDE (map printSigid sigids)
      | A.SPECSHARINGTYPE (specs, longtycons, _) =>
        P.SPECSHARINGTYPE (map printSpec specs, map printLongtycon longtycons)
      | A.SPECSHARING (specs, longstrids, _) =>
        P.SPECSHARING (map printSpec specs, map printLongstrid longstrids)
      | A.SPECSEMICOLON _ =>
        P.SEMICOLON

  and printSigexp sigexp =
      case sigexp of
        A.SIGBASIC (specs, _) =>
        P.SIGBASIC (map printSpec specs)
      | A.SIGID sigid =>
        printSigid sigid
      | A.SIGWHERE (sigexp, wheretypes, _) =>
        P.SIGWHERE (printSigexp sigexp, map printWheretype wheretypes)

  and printStrdesc (strid, sigexp, _) =
      P.VALDESC (printStrid strid, printSigexp sigexp)

  fun printSigbind (sigid, sigexp, _) =
      P.VALBIND (printSigid sigid, printSigexp sigexp)

  fun printSigconstraint (sigop, sigexp, _) =
      case sigop of
        A.TRANSPARENT => P.TRANSPARENT (printSigexp sigexp)
      | A.OPAQUE => P.OPAQUE (printSigexp sigexp)

  fun printStrexp strexp =
      case strexp of
        A.STRBASIC (strdecs, _) =>
        P.STRBASIC (map printStrdec strdecs)
      | A.STRID strid =>
        printLongstrid strid
      | A.STRCONSTRAINT (strexp, sigcon, _) =>
        P.STRCONSTRAINT (printStrexp strexp, printSigconstraint sigcon)
      | A.STRAPP (funid, funarg, _) =>
        P.STRAPP (printFunid funid, getOpt (Option.map printFunArg funarg, nil))
      | A.STRLET (strdecs, strexp, _) =>
        P.EXPLET (map printStrdec strdecs, [printStrexp strexp])

  and printStrdec strdec =
      case strdec of
        A.STRDEC dec =>
        printDec dec
      | A.STRUCTURE (strbinds, _) =>
        P.STRUCTURE (map printStrbind strbinds)
      | A.STRLOCAL (strdecs1, strdecs2, _) =>
        P.DECLOCAL (map printStrdec strdecs1, map printStrdec strdecs2)
      | A.STRSEMICOLON _ =>
        P.SEMICOLON

  and printFunArg funarg =
      case funarg of
        A.FUNARG strexp =>
        [printStrexp strexp]
      | A.FUNARG_DEC (strdecs, _) =>
        map printStrdec strdecs

  and printStrbind (strid, sigcon, strexp, _) =
      P.STRBIND (printStrid strid,
                 Option.map printSigconstraint sigcon,
                 printStrexp strexp)

  and printFunParam funparam =
      case funparam of
        A.FUNPARAM (strid, sigexp, _) =>
        [P.STRCONSTRAINT (printStrid strid, P.TRANSPARENT (printSigexp sigexp))]
      | A.FUNPARAM_SPEC (specs, _) =>
        map printSpec specs

  fun printFunbind (funid, funparam, sigcon, strexp, _) =
      P.FUNBIND ((printFunid funid,
                  getOpt (Option.map printFunParam funparam, nil)),
                 Option.map printSigconstraint sigcon,
                 printStrexp strexp)

  fun printSigdec (sigbinds, _) =
      P.SIGNATURE (map printSigbind sigbinds)

  fun printTopdec topdec =
      case topdec of
        A.TOPSTRDEC strdec =>
        printStrdec strdec
      | A.TOPSIGNATURE sigdec =>
        printSigdec sigdec
      | A.TOPFUNCTOR (funbinds, _) =>
        P.FUNCTOR (map printFunbind funbinds)
      | A.TOPEXP (exp, _) =>
        printExp exp

  fun printTop top =
      case top of
        A.TOPDEC (topdecs, _) =>
        map printTopdec topdecs
      | A.USE (path, _) =>
        [P.USE (printRequirePath path)]
      | A.U_USE (path, _) =>
        [P.U_USE (printRequirePath path)]
      | A.TOPSEMICOLON _ =>
        [P.SEMICOLON]

  fun printInterface (path, _) =
      P.INTERFACE (printRequirePath path)

  fun printCompileUnit (interface, tops, _) =
      mapOptionToList printInterface interface
      @ List.concat (map printTop tops)

  fun printAbsyn absyn =
      case absyn of
        A.UNIT unit => P.TOPDECS (printCompileUnit unit)
      | A.EOF _ => P.KEYWORD ["EOF"]

  fun printOpaqueImpl impl =
      case impl of
        I.IMPL_TY tycon => printLongtycon tycon
      | I.IMPL_TUPLE _ => P.KEYWORD ["*"]
      | I.IMPL_RECORD _ => P.EXPRECORD (nil, false)
      | I.IMPL_FUNC _ => P.KEYWORD ["->"]

  fun printOverloadInstance inst =
      case inst of
        I.INST_OVERLOAD ovcase =>
        printOverloadCase ovcase
      | I.INST_LONGVID vid =>
        printLongvid vid
      | I.INST_PAREN (inst, _) =>
        P.PAREN (printOverloadInstance inst)

  and printOverloadMrule (ty, inst, _) =
      P.MRULE (printTy ty, printOverloadInstance inst)

  and printOverloadCase (tyvar, ty, mrules, _) =
      P.EXPCASE (P.OVERLOAD_IN (printTyvar tyvar, printTy ty),
                 map printOverloadMrule mrules)

  fun printIvalbind valbind =
      case valbind of
        I.VAL_EXTERN (vid, ty, _) =>
        P.VALDESC (printVid vid, printTy ty)
      | I.VAL_ALIAS (vid, longvid, _) =>
        P.VALBIND (printVid vid, printLongvid longvid)
      | I.VAL_BUILTIN (vid1, vid2, ty, _) =>
        P.VALBIND (printVid vid1, P.BUILTIN_VAL (printVid vid2, printTy ty))
      | I.VAL_OVERLOAD (vid, ovcase, _) =>
        P.VALBIND (printVid vid, printOverloadCase ovcase)

  fun printItypdesc (tyvarseq, tycon, impl, _) =
      P.ITYPDESC (printTyvarseq tyvarseq,
                  printTycon tycon,
                  printOpaqueImpl impl)

  fun printItypbind typbind =
      case typbind of
        I.TYPBIND typbind =>
        printTypbind typbind
      | I.TYPDESC typdesc =>
        printItypdesc typdesc

  fun printIdec dec =
      case dec of
        I.DECVAL (tyvarseq, valbinds, _) =>
        P.DECVAL (printKindedTyvarseq tyvarseq, [printIvalbind valbinds])
      | I.DECTYPE (typbinds, _) =>
        P.DECTYPE (map printItypbind typbinds)
      | I.DECEQTYPE (typdescs, _) =>
        P.SPECEQTYPE (map printItypdesc typdescs)
      | I.DECDATATYPE (datbinds, withty, _) =>
        P.DECDATATYPE (map printDatbind datbinds, Option.map printWithty withty)
      | I.DECDATATYPEREP (tycon, longtycon, _) =>
        P.DECDATATYPEREP (printTycon tycon, printLongtycon longtycon)
      | I.DECTYPEBUILTIN (tycon1, tycon2, _) =>
        P.DECDATATYPEREP (printTycon tycon1,
                          P.BUILTIN_DATATYPE (printTycon tycon2))
      | I.DECEXCEPTION (exbinds, _) =>
        P.DECEXCEPTION (map printExbind exbinds)
      | I.DECSTRUCTURE (strbind, _) =>
        P.STRUCTURE ([printIstrbind strbind])
      | I.DECSEMICOLON _ =>
        P.SEMICOLON

  and printIstrexp strexp =
      case strexp of
        I.STRBASIC (decs, _) =>
        P.STRBASIC (map printIdec decs)
      | I.STRID strid =>
        printLongstrid strid
      | I.STRAPP (funid, longstrid, _) =>
        P.STRAPP (printFunid funid, [printLongstrid longstrid])

  and printIstrbind (strid, strexp, _) =
      P.VALBIND (printStrid strid, printIstrexp strexp)

  fun printIfunbind (funid, funparam, strexp, _) =
      P.FUNBIND ((printFunid funid,
                  getOpt (Option.map printFunParam funparam, nil)),
                 NONE,
                 printIstrexp strexp)

  fun printItopdec topdec =
      case topdec of
        I.TOPDEC dec =>
        printIdec dec
      | I.TOPFUNCTOR (funbind, _) =>
        P.FUNCTOR [printIfunbind funbind]
      | I.TOPINFIX (prec, vids, _) =>
        P.DECINFIX (Option.map P.STRING prec, map printVid vids)
      | I.TOPINFIXR (prec, vids, _) =>
        P.DECINFIXR (Option.map P.STRING prec, map printVid vids)
      | I.TOPNONFIX (vids, _) =>
        P.DECNONFIX (map printVid vids)

  fun printIrequire require =
      case require of
        I.REQUIRE (path, props, _) =>
        P.REQUIRE (printRequirePath path, map printId props)
      | I.REQUIRE_LOCAL (path, props, _) =>
        P.REQUIRE_LOCAL (printRequirePath path, map printId props)
      | I.USE_LOCAL (path, _) =>
        P.USE_LOCAL (printRequirePath path)
      | I.REQSEMICOLON _ =>
        P.SEMICOLON

  fun printIncludeDec dec =
      case dec of
        I.INCLUDE (path, _) =>
        P.SPECINCLUDE [printRequirePath path]
      | I.INCSEMICOLON _ =>
        P.SEMICOLON

  fun printIsigdec dec =
      case dec of
        I.SIGNATURE (sigbinds, _) =>
        P.SIGNATURE (map printSigbind sigbinds)
      | I.SIGSEMICOLON _ =>
        P.SEMICOLON

  fun printItop top =
      case top of
        I.INTERFACE (requires, topdecs, _) =>
        P.TOPDECS (map printIrequire requires @ map printItopdec topdecs)
      | I.INCLUDES (includes, sigdecs, _) =>
        P.TOPDECS (map printIncludeDec includes @ map printIsigdec sigdecs)

  fun format_tyvar x = P.format_exp (printTyvar x)
  fun format_ty x = P.format_exp (printTy x)
  fun format_constant x = P.format_exp (printConstant x)
  fun format_sigdec x = P.format_exp (printSigdec x)
  fun format_topdec x = P.format_exp (printTopdec x)
  fun format_absyn x = P.format_exp (printAbsyn x)
  fun format_itopdec x = P.format_exp (printItopdec x)

end
