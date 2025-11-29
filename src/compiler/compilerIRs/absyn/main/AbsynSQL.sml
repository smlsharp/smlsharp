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
  type lab = AbsynTy.lab
  type vid = AbsynTy.vid
  type op_longvid = AbsynTy.op_longvid

  type table_selector =
      vid * lab * loc

  datatype asc_desc =
      ASC
    | DESC

  datatype distinct_all =
      DISTINCT
    | ALL

  datatype first_next =
      FIRST
    | NEXT

  datatype row_rows =
      ROW
    | ROWS

  datatype op1 =
      IS_NULL
    | IS_NOT_NULL
    | IS_TRUE
    | IS_NOT_TRUE
    | IS_FALSE
    | IS_NOT_FALSE
    | IS_UNKNOWN
    | IS_NOT_UNKNOWN
    | NOT

  datatype op2 =
      AND
    | OR

  datatype 'exp exp =
      EXP_EMBED of 'exp * loc
    | CONST of AbsynConst.constant * loc
    | NULL of loc
    | TRUE of loc
    | FALSE of loc
    | COLUMN1 of lab * loc
    | COLUMN2 of lab * lab * loc
    | KWEXP of bool * 'exp kwexp * loc
    | EXP_SUBQUERY of bool * 'exp query * loc
    | OP1 of op1 * 'exp exp * loc
    | OP2 of op2 * 'exp exp * 'exp exp * loc
    | ID of op_longvid
    | PAREN of 'exp exp * loc
    | APP of 'exp exp * 'exp exp * loc
    | INFIX of 'exp exp * vid * 'exp exp * loc
    | CAST of vid * 'exp exp * loc
    | TUPLE of 'exp exp list * loc

  and 'exp kwexp =
      EXISTS of 'exp query * loc

  and 'exp table =
      TABLE of table_selector
    | TABLE_AS of 'exp table * lab * loc
    | TABLE_INNER_JOIN of 'exp table * bool * 'exp table * 'exp exp * loc
    | TABLE_CROSS_JOIN of 'exp table * 'exp table * loc
    | TABLE_NATURAL_JOIN of 'exp table * 'exp table * loc
    | TABLE_SUBQUERY of bool * 'exp query * loc
    | TABLE_PAREN of 'exp table * loc

  and 'exp from =
      FROM of 'exp table list * loc
    | FROM_EMBED of 'exp * loc

  and 'exp whr =
      WHERE of 'exp exp * loc
    | WHERE_EMBED of 'exp * loc

  and 'exp groupby =
      GROUPBY of 'exp groupby_clause * 'exp having_clause option * loc

  and 'exp orderby =
      ORDERBY of 'exp order_key list * loc
    | ORDERBY_EMBED of 'exp * loc

  and 'exp limit =
      LIMIT of 'exp limit_clause * 'exp limit_offset_clause option * loc
    | LIMIT_EMBED of 'exp * loc

  and 'exp offset =
      OFFSET of 'exp offset_clause * 'exp fetch_clause option * loc
    | OFFSET_EMBED of 'exp * loc

  and 'exp select =
      SELECT of distinct_all option * ('exp select_row list * loc) * loc
    | SELECT_EMBED of 'exp * loc

  and 'exp query =
      QUERY of 'exp select
               * 'exp from
               * 'exp whr option
               * 'exp groupby option
               * 'exp orderby option
               * 'exp offset_or_limit option
               * loc
    | QUERY_EMBED of 'exp * loc

  and 'exp offset_or_limit =
      LIMIT_CLAUSE of 'exp limit
    | OFFSET_CLAUSE of 'exp offset

  withtype 'exp order_key =
      'exp exp * asc_desc option * loc

  and 'exp select_row =
      'exp exp * lab option * loc

  and 'exp groupby_clause =
      'exp exp list * loc

  and 'exp having_clause =
      'exp exp * loc

  and 'exp limit_clause =
      'exp exp option * loc

  and 'exp limit_offset_clause =
      'exp exp * loc

  and 'exp offset_clause =
      'exp exp * row_rows * loc

  and 'exp fetch_clause =
      first_next * 'exp exp option * row_rows * loc

  datatype 'exp insert_value =
      VALUE of 'exp exp
    | DEFAULT of loc

  type 'exp insert_row =
      'exp insert_value list * loc

  datatype 'exp insert_values =
      INSERT_VALUES of 'exp insert_row list * loc
    | INSERT_VAR of op_longvid * loc
    | INSERT_SELECT of 'exp query

  type insert_labels =
      lab list * loc

  type 'exp set_row =
      lab * 'exp exp * loc

  type 'exp set =
      'exp set_row list * loc

  datatype 'exp con =
      QRY of 'exp query
    | SEL of 'exp select
    | FRM of 'exp from
    | WHR of 'exp whr
    | ORD of 'exp orderby
    | OFF of 'exp offset
    | LMT of 'exp limit
    | INSERT_LABELED of table_selector
                        * insert_labels
                        * 'exp insert_values
                        * loc
    | INSERT_NOLABEL of table_selector * 'exp query * loc
    | UPDATE of table_selector * 'exp set * 'exp whr option * loc
    | DELETE of table_selector * 'exp whr option * loc
    | BEGIN of loc
    | COMMIT of loc
    | ROLLBACK of loc

  datatype 'exp step =
      STEP of bool * 'exp con * loc
    | STEP_EMBED of 'exp * loc

  datatype 'exp body =
      CON of bool * 'exp con * loc
    | EXP of 'exp exp
    | SEQ of 'exp step list * loc
    | BODYPAREN of 'exp body * loc

  datatype ('exp, 'pat, 'ty) top =
      SQLSERVER of 'exp option * 'ty * loc
    | SQLFN of 'pat * 'exp body * loc
    | SQL of 'exp body * loc

end
