(* -*- sml -*- *)
(**
 * syntax for the IML.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure AbsynSQL =
struct

  type loc = AbsynTy.loc

  (*% @formatter(AbsynTy.lab) AbsynTyFormatter.format_lab *)
  type lab = AbsynTy.lab

  (*% @formatter(AbsynTy.vid) AbsynTyFormatter.format_vid *)
  type vid = AbsynTy.vid

  (*% @formatter(AbsynTy.op_longvid) AbsynTyFormatter.format_op_longvid *)
  type op_longvid = AbsynTy.op_longvid

  (*% *)
  type table_selector =
      (*%
       * @format(vid * lab * loc)
       * "#" vid "." lab
       *)
      vid * lab * loc

  (*% *)
  datatype asc_desc =
      (*% @format "asc" *)
      ASC
    | (*% @format "desc" *)
      DESC

  (*% *)
  datatype distinct_all =
      (*% @format "distinct" *)
      DISTINCT
    | (*% @format "all" *)
      ALL

  (*% *)
  datatype first_next =
      (*% @format "first" *)
      FIRST
    | (*% @format "next" *)
      NEXT

  (*% *)
  datatype row_rows =
      (*% @format "row" *)
      ROW
    | (*% @format "rows" *)
      ROWS

  (*% @params(exp) *)
  datatype op1 =
      (*%
       * @format
       * !N0{ exp +1 "IS" +d "NULL" }
       *)
      IS_NULL
    | (*%
       * @format
       * !N0{ exp +1 "IS" +d "TRUE" }
       *)
      IS_NOT_NULL
    | (*%
       * @format
       * !N0{ exp +1 "IS" +d "TRUE" }
       *)
      IS_TRUE
    | (*%
       * @format
       * !N0{ exp +1 "IS" +d "NOT" +d "TRUE"}
       *)
      IS_NOT_TRUE
    | (*%
       * @format
       * !N0{ exp +1 "IS" +d "FALSE" }
       *)
      IS_FALSE
    | (*%
       * @format
       * !N0{ exp +1 "IS" +d "NOT" +d "FALSE" }
       *)
      IS_NOT_FALSE
    | (*%
       * @format
       * !N0{ exp +1 "IS" +d "UNKNOWN" }
       *)
      IS_UNKNOWN
    | (*%
       * @format
       * !N0{ exp +1 "IS" +d "NOT" +d "UNKNOWN" }
       *)
      IS_NOT_UNKNOWN
    | (*%
       * @format
       * !N0{ "NOT" +1 exp }
       *)
      NOT

  (*% @params(exp1, exp2) *)
  datatype op2 =
      (*%
       * @format
       * !N0{ exp1 +1 "and" +d exp2 }
       *)
      AND
    | (*%
       * @format
       * !N0{ exp1 +1 "or" +d exp2 }
       *)
      OR

  (*%
   * @formatter(AbsynConst.constant) AbsynConstFormatter.format_constant
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   * @formatter(ifcons) AbsynFormatterUtils.ifcons
   *)
  datatype 'exp exp =
      (*%
       * @format(exp * loc)
       * !N0{ "(..." 2[1] exp 1 ")" }
       *)
      EXP_EMBED of 'exp * loc
    | (*%
       * @format(const * loc)
       * const
       *)
      CONST of AbsynConst.constant * loc
    | (*%
       * @format
       * "NULL"
       *)
      NULL of loc
    | (*%
       * @format
       * "TRUE"
       *)
      TRUE of loc
    | (*%
       * @format
       * "FALSE"
       *)
      FALSE of loc
    | (*%
       * @format(lab * loc)
       * "#." lab
       *)
      COLUMN1 of lab * loc
    | (*%
       * @format(lab1 * lab2 * loc)
       * "#" lab1 "." lab2
       *)
      COLUMN2 of lab * lab * loc
    | (*%
       * @format(sql * e exp * loc)
       * !N0{ sql:iftrue()("_sql" +1,) exp(e) }
       *)
      KWEXP of bool * 'exp kwexp * loc
    | (*%
       * @format(sql * exp query * loc)
       * "(" !N0{ sql:iftrue()("_sql" +1,) query(exp) } ")"
       *)
      EXP_SUBQUERY of bool * 'exp query * loc
    | (*%
       * @format(op1 * e exp * loc)
       * op1()(exp(e))
       *)
      OP1 of op1 * 'exp exp * loc
    | (*%
       * @format(op2 * e1 exp1 * e2 exp2 * loc)
       * op2()(exp1(e1), exp2(e2))
       *)
      OP2 of op2 * 'exp exp * 'exp exp * loc
    | (*%
       * @format(vid)
       * vid
       *)
      ID of op_longvid
    | (*%
       * @format(e exp * loc)
       * "(" !N0{ exp(e) } ")"
       *)
      PAREN of 'exp exp * loc
    | (*%
       * @format(e1 exp1 * e2 exp2 * loc)
       * L9{ exp1(e1) 2[+1] exp2(e2) }
       *)
      APP of 'exp exp * 'exp exp * loc
    | (*%
       * @format(e1 exp1 * vid * e2 exp2 * loc)
       * N9{ exp1(e1) 2[+1] vid 2[+2] exp2(e2) }
       *)
      INFIX of 'exp exp * vid * 'exp exp * loc
    | (*%
       * @format(vid * e exp * loc)
       * L9{ "(" vid ")" 2[1] exp(e) }
       *)
      CAST of vid * 'exp exp * loc
    | (*%
       * @format(e exp exps * loc)
       * "(" !N0{ exps(exp(e))("," +1) } ")"
       *)
      TUPLE of 'exp exp list * loc

  and 'exp kwexp =
      (*%
       * @format(exp query * loc)
       * !N0{ "exists(" 2[1] query(exp) 1 ")" }
       *)
      EXISTS of 'exp query * loc

  and 'exp table =
      (*%
       * @format(selector)
       * selector
       *)
      TABLE of table_selector
    | (*%
       * @format(e table * lab * loc)
       * L6{ table(e) +1 "as" +d lab }
       *)
      TABLE_AS of 'exp table * lab * loc
    | (*%
       * @format(e1 table1 * inner * e2 table2 * e3 exp3 * loc)
       * L2{
       *   table1(e1)
       *   +1
       *   !N0{ inner:iftrue()("inner" +d,) "join" +1 table2(e2) }
       *   +1
       *   !N0{ "on" +d exp3(e3) }
       * }
       *)
      TABLE_INNER_JOIN of 'exp table * bool * 'exp table * 'exp exp * loc
    | (*%
       * @format(e1 table1 * e2 table2 * loc)
       * L2{
       *   table1(e1)
       *   +1
       *   !N0{ "cross" +d "join" +1 table2(e2) }
       * }
       *)
      TABLE_CROSS_JOIN of 'exp table * 'exp table * loc
    | (*%
       * @format(e1 table1 * e2 table2 * loc)
       * L2{
       *   table1(e1)
       *   +1
       *   !N0{ "natural" +d "join" +1 table2(e2) }
       * }
       *)
      TABLE_NATURAL_JOIN of 'exp table * 'exp table * loc
    | (*%
       * @format(sql * e query * loc)
       * "(" !N0{ sql:iftrue()("_sql" +1,) query(e) } ")"
       *)
      TABLE_SUBQUERY of bool * 'exp query * loc
    | (*%
       * @format(e table * loc)
       * "(" !N0{ table(e) } ")"
       *)
      TABLE_PAREN of 'exp table * loc

  and 'exp from =
      (*%
       * @format(e table tables * loc)
       * !N0{ "from" 2[+1] tables(table(e))("," 2[+1]) }
       *)
      FROM of 'exp table list * loc
    | (*%
       * @format(exp * loc)
       * !N0{ "from" d "...(" 2[1] exp 1 ")" }
       *)
      FROM_EMBED of 'exp * loc

  and 'exp whr =
      (*%
       * @format(e exp * loc)
       * !N0{ "where" 2[+1] exp(e) }
       *)
      WHERE of 'exp exp * loc
    | (*%
       * @format(exp * loc)
       * !N0{ "where" d "...(" 2[1] exp 1 ")" }
       *)
      WHERE_EMBED of 'exp * loc

  and 'exp groupby =
      (*%
       * @format(e groupby * e having havingOpt * loc)
       * !N0{ groupby(e) havingOpt:ifsome()(+1,) havingOpt(having(e)) }
       *)
      GROUPBY of 'exp groupby_clause * 'exp having_clause option * loc

  and 'exp orderby =
      (*%
       * @format(e key keys * loc)
       * !N0{ "order" +d "by" 2[+1] keys(key(e))("," 2[+1]) }
       *)
      ORDERBY of 'exp order_key list * loc
    | (*%
       * @format(exp * loc)
       * !N0{ "order" +d "by" d "...(" 2[1] exp 1 ")" }
       *)
      ORDERBY_EMBED of 'exp * loc

  and 'exp limit =
      (*%
       * @format(e limit * e offset offsetOpt * loc)
       * !N0{ limit(e) offsetOpt:ifsome()(+1,) offsetOpt(offset(e)) }
       *)
      LIMIT of 'exp limit_clause * 'exp limit_offset_clause option * loc
    | (*%
       * @format(exp * loc)
       * !N0{ "limit" d "...(" 2[1] exp 1 ")" }
       *)
      LIMIT_EMBED of 'exp * loc

  and 'exp offset =
      (*%
       * @format(e offset * e fetch fetchOpt * loc)
       * !N0{ offset(e) fetchOpt:ifsome()(+1,) fetchOpt(fetch(e)) }
       *)
      OFFSET of 'exp offset_clause * 'exp fetch_clause option * loc
    | (*%
       * @format(exp * loc)
       * !N0{ "offset" d "...(" 2[1] exp 1 ")" }
       *)
      OFFSET_EMBED of 'exp * loc

  and 'exp select =
      (*%
       * @format(distinct distinctOpt * (e row rows * loc1) * loc2)
       * !N0{
       *   "select"
       *   distinctOpt:ifsome()(+d,)
       *   distinctOpt(distinct)
       *   rows:ifcons()(2[+1],)
       *   rows(row(e))("," 2[+1])
       * }
       *)
      SELECT of distinct_all option * ('exp select_row list * loc) * loc
    | (*%
       * @format(exp * loc)
       * !N0{ "select" d "...(" 2[1] exp 1 ")" }
       *)
      SELECT_EMBED of 'exp * loc

  and 'exp query =
      (*%
       * @format(e1 select
       *         * e2 from
       *         * e3 whr whrOpt
       *         * e4 groupby groupbyOpt
       *         * e5 orderby orderbyOpt
       *         * e6 offset offsetOpt
       *         * loc)
       * !N0{
       *   select(e1)
       *   +1 from(e2)
       *   whrOpt:ifsome()(+1,)
       *   whrOpt(whr(e3))
       *   groupbyOpt:ifsome()(+1,)
       *   groupbyOpt(groupby(e4))
       *   orderbyOpt:ifsome()(+1,)
       *   orderbyOpt(orderby(e5))
       *   offsetOpt:ifsome()(+1,)
       *   offsetOpt(offset(e6))
       * }
       *)
      QUERY of 'exp select
               * 'exp from
               * 'exp whr option
               * 'exp groupby option
               * 'exp orderby option
               * 'exp offset_or_limit option
               * loc
    | (*%
       * @format(exp * loc)
       * !N0{ "select" d "...(" 2[1] exp 1 ")" }
       *)
      QUERY_EMBED of 'exp * loc

  and 'exp offset_or_limit =
      (*%
       * @format(e limit)
       * limit(e)
       *)
      LIMIT_CLAUSE of 'exp limit
    | (*%
       * @format(e offset)
       * offset(e)
       *)
      OFFSET_CLAUSE of 'exp offset

  withtype 'exp order_key =
      (*%
       * @format(e exp * asc ascOpt * loc)
       * !N0{ exp(e) ascOpt:ifsome()(+1,) ascOpt(asc) }
       *)
      'exp exp * asc_desc option * loc

  and 'exp select_row =
      (*%
       * @format(e exp * lab labOpt * loc)
       * !N0{ exp(e) labOpt:ifsome()(+1 "as" +d labOpt(lab),) }
       *)
      'exp exp * lab option * loc

  and 'exp groupby_clause =
      (*%
       * @format(e exp exps * loc)
       * !N0{ "group" +d "by" 2[+1] exps(exp(e))("," 2[+1]) }
       *)
      'exp exp list * loc

  and 'exp having_clause =
      (*%
       * @format(e exp * loc)
       * !N0{ "having" 2[+1] exp(e) }
       *)
      'exp exp * loc

  and 'exp limit_clause =
      (*%
       * @format(e exp expOpt * loc)
       * !N0{ "limit" expOpt:ifsome()(2[+1] expOpt(exp(e)), +d "all") }
       *)
      'exp exp option * loc

  and 'exp limit_offset_clause =
      (*%
       * @format(e exp * loc)
       * !N0{ "offset" 2[+1] exp(e) }
       *)
      'exp exp * loc

  and 'exp offset_clause =
      (*%
       * @format(e exp * rows * loc)
       * !N0{ "offset" 2[+1] exp(e) 2[+1] rows }
       *)
      'exp exp * row_rows * loc

  and 'exp fetch_clause =
      (*%
       * @format(first * e exp expOpt * rows * loc)
       * !N0{
       *   "fetch"
       *   +d first
       *   expOpt:ifsome()(2[+1] expOpt(exp(e)) 2[+1], +d)
       *   rows
       *   +d "only"
       * }
       *)
      first_next * 'exp exp option * row_rows * loc

  (*% *)
  datatype 'exp insert_value =
      (*%
       * @format(e exp)
       * exp(e)
       *)
      VALUE of 'exp exp
    | (*%
       * @format(loc)
       * "default"
       *)
      DEFAULT of loc

  (*% *)
  type 'exp insert_row =
      (*%
       * @format(e value values * loc)
       * "(" !N0{ values(value(e))("," +1) } ")"
       *)
      'exp insert_value list * loc

  (*% *)
  datatype 'exp insert_values =
      (*%
       * @format(e row rows * loc)
       * !N0{ "values" 2[+1] rows(row(e))("," 2[+1]) }
       *)
      INSERT_VALUES of 'exp insert_row list * loc
    | (*%
       * @format(vid * loc)
       * !N0{ "values" 2[+1] vid }
       *)
      INSERT_VAR of op_longvid * loc
    | (*%
       * @format(e query)
       * query(e)
       *)
      INSERT_SELECT of 'exp query

  (*% *)
  type insert_labels =
      (*%
       * @format(lab labs * loc)
       * "(" !N0{ labs(lab)("," +1) } ")"
       *)
      lab list * loc

  (*% *)
  type 'exp set_row =
      (*%
       * @format(lab * e exp * loc)
       * !N0{ lab +d "=" 2[+1] exp(e) }
       *)
      lab * 'exp exp * loc

  (*% *)
  type 'exp set =
      (*%
       * @format(e row rows * loc)
       * !N0{ "set" 2[+1] rows(row(e))("," 2[+1]) }
       *)
      'exp set_row list * loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   *)
  datatype 'exp con =
      (*%
       * @format(e query)
       * query(e)
       *)
      QRY of 'exp query
    | (*%
       * @format(e select)
       * select(e)
       *)
      SEL of 'exp select
    | (*%
       * @format(e from)
       * from(e)
       *)
      FRM of 'exp from
    | (*%
       * @format(e whr)
       * whr(e)
       *)
      WHR of 'exp whr
    | (*%
       * @format(e orderby)
       * orderby(e)
       *)
      ORD of 'exp orderby
    | (*%
       * @format(e offset)
       * offset(e)
       *)
      OFF of 'exp offset
    | (*%
       * @format(e limit)
       * limit(e)
       *)
      LMT of 'exp limit
    | (*%
       * @format(table * labels * e values * loc)
       * !N0{
       *   !N0{ "insert" +d "into" 2[+1] table 2[+1] labels }
       *   +1
       *   values(e)
       * }
       *)
      INSERT_LABELED of table_selector
                        * insert_labels
                        * 'exp insert_values
                        * loc
    | (*%
       * @format(table * e query * loc)
       * !N0{
       *   !N0{ "insert" +d "into" 2[+1] table }
       *   +1
       *   query(e)
       * }
       *)
      INSERT_NOLABEL of table_selector * 'exp query * loc
    | (*%
       * @format(table * e1 set * e2 whr whrOpt * loc)
       * !N0{
       *   !N0{ "update" 2[+1] table }
       *   +1
       *   set(e1)
       *   whrOpt:ifsome()(+1,)
       *   whrOpt(whr(e2))
       * }
       *)
      UPDATE of table_selector * 'exp set * 'exp whr option * loc
    | (*%
       * @format(table * e whr whrOpt * loc)
       * !N0{
       *   !N0{ "delete" 2[+1] table }
       *   whrOpt:ifsome()(+1,)
       *   whrOpt(whr(e))
       * }
       *)
      DELETE of table_selector * 'exp whr option * loc
    | (*%
       * @format(loc)
       * "begin"
       *)
      BEGIN of loc
    | (*%
       * @format(loc)
       * "commit"
       *)
      COMMIT of loc
    | (*%
       * @format(loc)
       * "rollback"
       *)
      ROLLBACK of loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   *)
  datatype 'exp step =
      (*%
       * @format(prefix * exp con * loc)
       * !N0{ prefix:iftrue()("_sql" +1,) con(exp) }
       *)
      STEP of bool * 'exp con * loc
    | (*%
       * @format(exp * loc)
       * "...(" !N0{ exp } ")"
       *)
      STEP_EMBED of 'exp * loc

  (*%
   * @formatter(iftrue) AbsynFormatterUtils.iftrue
   *)
  datatype 'exp body =
      (*%
       * @format(prefix * e con * loc)
       * !N0{ prefix:iftrue()("_sql" +1,) con(e) }
       *)
      CON of bool * 'exp con * loc
    | (*%
       * @format(e exp)
       * exp(e)
       *)
      EXP of 'exp exp
    | (*%
       * @format(e step steps * loc)
       * !N0{ steps(step(e))(";" + 1) }
       *)
      SEQ of 'exp step list * loc
    | (*%
       * @format(e body * loc)
       * "(" !N0{ body(e) } ")"
       *)
      BODYPAREN of 'exp body * loc

  (*%
   * @formatter(ifsome) AbsynFormatterUtils.ifsome
   *)
  datatype ('exp, 'pat, 'ty) top =
      (*%
       * @format(exp expOpt * ty * loc)
       * L6{
       *   "_sqlserver"
       *   expOpt:ifsome()(2[+1],)
       *   expOpt(exp)
       *   2[+1] ":" +d ty
       * }
       *)
      SQLSERVER of 'exp option * 'ty * loc
    | (*%
       * @format(pat * exp body * loc)
       * R2{ "_sql" +d !N0{ pat +d "=>" +1 body(exp) } }
       *)
      SQLFN of 'pat * 'exp body * loc
    | (*%
       * @format(exp body * loc)
       * !N0{ "_sql" +1 body(exp) }
       *)
      SQL of 'exp body * loc

end
