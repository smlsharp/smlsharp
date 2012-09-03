(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @author SATO Hirohuki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SMLSharp_SQL_Prim =
struct

  structure Backend = SMLSharp_SQL_Backend

  datatype server = datatype SMLSharp.SQL.server
  datatype 'a conn = CONN of unit ptr * 'a
  datatype dbi = datatype SMLSharp.SQL.dbi
  datatype ('a,'b) db = DB of 'a * 'b dbi
  datatype ('a,'b) table = TABLE of (string * 'b dbi) * 'a
  datatype ('a,'b) row = ROW of (string * 'b dbi) * 'a
  datatype value = datatype SMLSharp.SQL.value
  datatype result = RESULT of unit ptr * int
  datatype 'a rel = REL of result * (result -> 'a)
  datatype 'a query = QUERY of string * 'a * (result -> 'a)
  datatype command = COMMAND of string

  exception Type of string
  exception Format = Backend.Format
  exception Exec of string
  exception Connect of string
  exception Link of string

  fun eof (RESULT (result, rowIndex)) =
      Backend.eof (result,rowIndex)

  fun next (RESULT (result, rowIndex)) =
      RESULT (result, rowIndex + 1)

  fun fetch (REL (result, fetchFn)) =
      if eof result
      then NONE
      else SOME (fetchFn result, REL (next result, fetchFn))

  fun closeConn (CONN (conn, _)) = Backend.closeConn conn

  fun closeRel (REL (RESULT (r, _), _)) =
      Backend.closeRel r

  fun eval (dbi, queryFn) (CONN (conn, witness)) =
      let
        val QUERY (query, witness, fetchFn) =
            queryFn (DB (witness, dbi))
        val r = Backend.execQuery (conn, query)
      in
        REL (RESULT (r, 0), fetchFn)
      end

  fun exec (dbi, commandFn) (CONN (conn, witness)) =
      let
        val COMMAND query =
            commandFn (DB (witness, dbi))
        val  r =  Backend.execQuery (conn, query)
      in
        closeRel (REL (RESULT (r, 0), fn x => x)); ()
      end

  fun subquery queryFn (db as DB (_, dbi)) =
      let
        val QUERY (query, queryWitness, fetchFn) = queryFn db
      in
        TABLE (("(" ^ query ^ ")", dbi), queryWitness)
      end

  fun exists queryFn (db as DB (_, dbi)) =
      let
        val QUERY (query, queryWitness, fetchFn) = queryFn db
      in
        VALUE (("(exists (" ^ query ^ "))", dbi), SOME true)
      end

  fun queryString queryFn (SERVER (_, _, witness)) =
      let
        val QUERY (query, witness, fetchFn) =
            queryFn (DB (witness, DBI))
      in
        query
      end

  fun commandString commandFn (SERVER (_, _, witness)) =
      let
        val COMMAND query =
            commandFn (DB (witness, DBI))
      in
        query
      end

  local
    type column = {colname: string, isnull: bool, typename: string}
    type sqlcolumn = {colname: string, isnull: bool,
		      typename: Backend.sqltype}
    type table = string * column list
    type schema = table list

    fun columnType ({isnull, typename, ...}:column) =
        typename ^ (if isnull then " option" else "")

    fun columnTypeSQL ({isnull, typename, ...}:sqlcolumn) =
        valOf (Backend.translateType typename) ^
	(if isnull then " option" else "")
	handle Option => raise Connect "The type is not supported"

    fun isSameName (col1:column) (col2:sqlcolumn) =
        #colname col1 = #colname col2

    fun isSameNameSQL (col1:sqlcolumn) (col2:column) =
	#colname col1 = #colname col2

    fun matchColumn ({colname=name1, isnull=isnull1, typename=ty1}:column,
                     {colname=name2, isnull=isnull2, typename=ty2}:sqlcolumn) =
        name1 = name2
        andalso isnull1 = isnull2
        andalso SOME ty1 = Backend.translateType ty2

    fun unifyColumns (tableName, expectColumns, actualColumns) =
        (
          app (fn expect =>
                  case List.find (isSameName expect) actualColumns of
                    NONE => raise Link ("column `" ^ #colname expect
                                        ^ "' of table `" ^ tableName
                                        ^ "' is not found.")
                  | SOME actual =>
                    if matchColumn (expect, actual) then ()
                    else raise Link ("type mismatch of column `"
                                     ^ #colname expect ^ "' of table `"
                                     ^ tableName ^ "': expected `"
                                     ^ columnType expect
                                     ^ "', but actual `"
                                     ^ columnTypeSQL actual ^ "'"))
              expectColumns;
          app (fn actual =>
                  case List.find (isSameNameSQL actual) expectColumns of
                    NONE =>
                    raise Link ("table `" ^ tableName ^ "' has column `"
                                ^ #colname actual ^ "' but not declared.")
                  | SOME _ => ())
              actualColumns
        )

    fun unifySchema (expectSchema, actualSchema) =
        app (fn (tableName, expectColumns) =>
                case List.find (fn (n,_) => n = tableName) actualSchema of
                  SOME (_, actualColumns) =>
                  unifyColumns (tableName, expectColumns, actualColumns)
                | NONE =>
                  raise Link ("table `" ^ tableName ^ "' is not found."))
            expectSchema

  in

  fun link (conn, schema) =
      unifySchema (schema, (Backend.getDatabaseSchema conn))
      handle Backend.Connect msg => raise Connect msg

  end (* local *)

  fun connect (SERVER (connInfo, schema, witness)) =
      let
        val conn = Backend.connect connInfo
            handle Backend.Connect msg => raise Connect msg
        val e = (link (conn, schema); NONE)
            handle e => SOME e
      in
        case e of
          NONE => CONN (conn, witness)
        | SOME e => (closeConn (CONN (conn, witness)); raise e)
      end

  fun Some (VALUE (x, y)) = VALUE (x, SOME y)

  val Null = VALUE (("NULL", DBI), NONE)

  fun concatDot ((x:string, y:'a), z:string) : string * 'a =
      (case x of "" => z | _ => x ^ "." ^ z, y)

  fun concatQuery (x:(string * 'a) list) : string =
      case x of nil => "" | (h,_)::t => h ^ concatQuery t

  local
    fun op1 (oper, (x1,i), w) =
        VALUE (("(" ^ oper ^ x1 ^ ")", i), w)
    fun op1post ((x1,i), oper, w) =
        VALUE (("(" ^ x1 ^ oper ^ ")", i), w)
    fun op2 ((x1,i1:'a dbi), oper2, (x2,i2:'a dbi), w) =
        VALUE (("(" ^ x1 ^ " " ^ oper2 ^ " " ^ x2 ^ ")", i1), w)
  in

  fun add_int (VALUE(x1, w1) : (int,'a) value,
               VALUE(x2, w2) : (int,'a) value)
              : (int,'a) value =
      op2 (x1, "+", x2, w1)
  fun add_word (VALUE(x1, w1) : (word,'a) value,
                VALUE(x2, w2) : (word,'a) value)
               : (word,'a) value =
      op2 (x1, "+", x2, w1)
  fun add_real (VALUE(x1, w1) : (real,'a) value,
                VALUE(x2, w2) : (real,'a) value)
               : (real,'a) value =
      op2 (x1, "+", x2, w1)
  fun add_intOption (VALUE(x1, w1) : (int option,'a) value,
                     VALUE(x2, w2) : (int option,'a) value)
                    : (int option,'a) value =
      op2 (x1, "+", x2, w1)
  fun add_wordOption (VALUE(x1, w1) : (word option,'a) value,
                      VALUE(x2, w2) : (word option,'a) value)
                     : (word option,'a) value =
      op2 (x1, "+", x2, w1)
  fun add_realOption (VALUE(x1, w1) : (real option,'a) value,
                      VALUE(x2, w2) : (real option,'a) value)
                     : (real option,'a) value =
      op2 (x1, "+", x2, w1)
  fun sub_int (VALUE(x1, w1) : (int,'a) value,
               VALUE(x2, w2) : (int,'a) value)
              : (int,'a) value =
      op2 (x1, "-", x2, w1)
  fun sub_word (VALUE(x1, w1) : (word,'a) value,
                VALUE(x2, w2) : (word,'a) value)
               : (word,'a) value =
      op2 (x1, "-", x2, w1)
  fun sub_real (VALUE(x1, w1) : (real,'a) value,
                VALUE(x2, w2) : (real,'a) value)
               : (real,'a) value =
      op2 (x1, "-", x2, w1)
  fun sub_intOption (VALUE(x1, w1) : (int option,'a) value,
                     VALUE(x2, w2) : (int option,'a) value)
                    : (int option,'a) value =
      op2 (x1, "-", x2, w1)
  fun sub_wordOption (VALUE(x1, w1) : (word option,'a) value,
                      VALUE(x2, w2) : (word option,'a) value)
                     : (word option,'a) value =
      op2 (x1, "-", x2, w1)
  fun sub_realOption (VALUE(x1, w1) : (real option,'a) value,
                      VALUE(x2, w2) : (real option,'a) value)
                     : (real option,'a) value =
      op2 (x1, "-", x2, w1)
  fun mul_int (VALUE(x1, w1) : (int,'a) value,
               VALUE(x2, w2) : (int,'a) value)
              : (int,'a) value =
      op2 (x1, "*", x2, w1)
  fun mul_word (VALUE(x1, w1) : (word,'a) value,
                VALUE(x2, w2) : (word,'a) value)
               : (word,'a) value =
      op2 (x1, "*", x2, w1)
  fun mul_real (VALUE(x1, w1) : (real,'a) value,
                VALUE(x2, w2) : (real,'a) value)
               : (real,'a) value =
      op2 (x1, "*", x2, w1)
  fun mul_intOption (VALUE(x1, w1) : (int option,'a) value,
                     VALUE(x2, w2) : (int option,'a) value)
                    : (int option,'a) value =
      op2 (x1, "*", x2, w1)
  fun mul_wordOption (VALUE(x1, w1) : (word option,'a) value,
                      VALUE(x2, w2) : (word option,'a) value)
                     : (word option,'a) value =
      op2 (x1, "*", x2, w1)
  fun mul_realOption (VALUE(x1, w1) : (real option,'a) value,
                      VALUE(x2, w2) : (real option,'a) value)
                     : (real option,'a) value =
      op2 (x1, "*", x2, w1)
  fun div_int (VALUE(x1, w1) : (int,'a) value,
               VALUE(x2, w2) : (int,'a) value)
              : (int,'a) value =
      op2 (x1, "/", x2, w1)
  fun div_word (VALUE(x1, w1) : (word,'a) value,
                VALUE(x2, w2) : (word,'a) value)
               : (word,'a) value =
      op2 (x1, "/", x2, w1)
  fun div_real (VALUE(x1, w1) : (real,'a) value,
                VALUE(x2, w2) : (real,'a) value)
               : (real,'a) value =
      op2 (x1, "/", x2, w1)
  fun div_intOption (VALUE(x1, w1) : (int option,'a) value,
                     VALUE(x2, w2) : (int option,'a) value)
                    : (int option,'a) value =
      op2 (x1, "/", x2, w1)
  fun div_wordOption (VALUE(x1, w1) : (word option,'a) value,
                      VALUE(x2, w2) : (word option,'a) value)
                     : (word option,'a) value =
      op2 (x1, "/", x2, w1)
  fun div_realOption (VALUE(x1, w1) : (real option,'a) value,
                      VALUE(x2, w2) : (real option,'a) value)
                     : (real option,'a) value =
      op2 (x1, "/", x2, w1)
  fun mod_int (VALUE(x1, w1) : (int,'a) value,
               VALUE(x2, w2) : (int,'a) value)
              : (int,'a) value =
      op2 (x1, "%", x2, w1)
  fun mod_word (VALUE(x1, w1) : (word,'a) value,
                VALUE(x2, w2) : (word,'a) value)
               : (word,'a) value =
      op2 (x1, "%", x2, w1)
  fun mod_intOption (VALUE(x1, w1) : (int option,'a) value,
                     VALUE(x2, w2) : (int option,'a) value)
                    : (int option,'a) value =
      op2 (x1, "%", x2, w1)
  fun mod_wordOption (VALUE(x1, w1) : (word option,'a) value,
                      VALUE(x2, w2) : (word option,'a) value)
                     : (word option,'a) value =
      op2 (x1, "%", x2, w1)
  fun neg_int (VALUE(x1, w1) : (int,'a) value)
              : (int,'a) value =
      op1 ("-", x1, w1)
  fun neg_real (VALUE(x1, w1) : (real,'a) value)
               : (real,'a) value =
      op1 ("-", x1, w1)
  fun neg_intOption (VALUE(x1, w1) : (int option,'a) value)
                    : (int option,'a) value =
      op1 ("-", x1, w1)
  fun neg_realOption (VALUE(x1, w1) : (real option,'a) value)
                     : (real option,'a) value =
      op1 ("-", x1, w1)
  fun abs_int (VALUE(x1, w1) : (int,'a) value)
              : (int,'a) value =
      op1 ("@", x1, w1)
  fun abs_real (VALUE(x1, w1) : (real,'a) value)
               : (real,'a) value =
      op1 ("@", x1, w1)
  fun abs_intOption (VALUE(x1, w1) : (int option,'a) value)
                    : (int option,'a) value =
      op1 ("@", x1, w1)
  fun abs_realOption (VALUE(x1, w1) : (real option,'a) value)
                     : (real option,'a) value =
      op1 ("@", x1, w1)
  fun lt_int (VALUE(x1, w1) : (int,'a) value,
              VALUE(x2, w2) : (int,'a) value)
             : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_word (VALUE(x1, w1) : (word,'a) value,
               VALUE(x2, w2) : (word,'a) value)
              : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_char (VALUE(x1, w1) : (char,'a) value,
               VALUE(x2, w2) : (char,'a) value)
              : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_string (VALUE(x1, w1) : (string,'a) value,
                 VALUE(x2, w2) : (string,'a) value)
                : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_real (VALUE(x1, w1) : (real,'a) value,
               VALUE(x2, w2) : (real,'a) value)
              : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_intOption (VALUE(x1, w1) : (int option,'a) value,
                    VALUE(x2, w2) : (int option,'a) value)
                   : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_wordOption (VALUE(x1, w1) : (word option,'a) value,
                     VALUE(x2, w2) : (word option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_charOption (VALUE(x1, w1) : (char option,'a) value,
                     VALUE(x2, w2) : (char option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_boolOption (VALUE(x1, w1) : (bool option,'a) value,
                     VALUE(x2, w2) : (bool option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_stringOption (VALUE(x1, w1) : (string option,'a) value,
                       VALUE(x2, w2) : (string option,'a) value)
                      : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_realOption (VALUE(x1, w1) : (real option,'a) value,
                     VALUE(x2, w2) : (real option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun le_int (VALUE(x1, w1) : (int,'a) value,
              VALUE(x2, w2) : (int,'a) value)
             : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_word (VALUE(x1, w1) : (word,'a) value,
               VALUE(x2, w2) : (word,'a) value)
              : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_char (VALUE(x1, w1) : (char,'a) value,
               VALUE(x2, w2) : (char,'a) value)
              : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_string (VALUE(x1, w1) : (string,'a) value,
                 VALUE(x2, w2) : (string,'a) value)
                : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_real (VALUE(x1, w1) : (real,'a) value,
               VALUE(x2, w2) : (real,'a) value)
              : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_intOption (VALUE(x1, w1) : (int option,'a) value,
                    VALUE(x2, w2) : (int option,'a) value)
                   : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_wordOption (VALUE(x1, w1) : (word option,'a) value,
                     VALUE(x2, w2) : (word option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_charOption (VALUE(x1, w1) : (char option,'a) value,
                     VALUE(x2, w2) : (char option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_boolOption (VALUE(x1, w1) : (bool option,'a) value,
                     VALUE(x2, w2) : (bool option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_stringOption (VALUE(x1, w1) : (string option,'a) value,
                       VALUE(x2, w2) : (string option,'a) value)
                      : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_realOption (VALUE(x1, w1) : (real option,'a) value,
                     VALUE(x2, w2) : (real option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun gt_int (VALUE(x1, w1) : (int,'a) value,
              VALUE(x2, w2) : (int,'a) value)
             : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_word (VALUE(x1, w1) : (word,'a) value,
               VALUE(x2, w2) : (word,'a) value)
              : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_char (VALUE(x1, w1) : (char,'a) value,
               VALUE(x2, w2) : (char,'a) value)
              : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_string (VALUE(x1, w1) : (string,'a) value,
                 VALUE(x2, w2) : (string,'a) value)
                : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_real (VALUE(x1, w1) : (real,'a) value,
               VALUE(x2, w2) : (real,'a) value)
              : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_intOption (VALUE(x1, w1) : (int option,'a) value,
                    VALUE(x2, w2) : (int option,'a) value)
                   : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_wordOption (VALUE(x1, w1) : (word option,'a) value,
                     VALUE(x2, w2) : (word option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_charOption (VALUE(x1, w1) : (char option,'a) value,
                     VALUE(x2, w2) : (char option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_boolOption (VALUE(x1, w1) : (bool option,'a) value,
                     VALUE(x2, w2) : (bool option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_stringOption (VALUE(x1, w1) : (string option,'a) value,
                       VALUE(x2, w2) : (string option,'a) value)
                      : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_realOption (VALUE(x1, w1) : (real option,'a) value,
                     VALUE(x2, w2) : (real option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun ge_int (VALUE(x1, w1) : (int,'a) value,
              VALUE(x2, w2) : (int,'a) value)
             : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_word (VALUE(x1, w1) : (word,'a) value,
               VALUE(x2, w2) : (word,'a) value)
              : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_char (VALUE(x1, w1) : (char,'a) value,
               VALUE(x2, w2) : (char,'a) value)
              : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_string (VALUE(x1, w1) : (string,'a) value,
                 VALUE(x2, w2) : (string,'a) value)
                : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_real (VALUE(x1, w1) : (real,'a) value,
               VALUE(x2, w2) : (real,'a) value)
              : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_intOption (VALUE(x1, w1) : (int option,'a) value,
                    VALUE(x2, w2) : (int option,'a) value)
                   : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_wordOption (VALUE(x1, w1) : (word option,'a) value,
                     VALUE(x2, w2) : (word option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_charOption (VALUE(x1, w1) : (char option,'a) value,
                     VALUE(x2, w2) : (char option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_boolOption (VALUE(x1, w1) : (bool option,'a) value,
                     VALUE(x2, w2) : (bool option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_stringOption (VALUE(x1, w1) : (string option,'a) value,
                       VALUE(x2, w2) : (string option,'a) value)
                      : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_realOption (VALUE(x1, w1) : (real option,'a) value,
                     VALUE(x2, w2) : (real option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)

  fun eq_int (VALUE(x1, w1) : (int,'a) value,
              VALUE(x2, w2) : (int,'a) value)
             : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_word (VALUE(x1, w1) : (word,'a) value,
               VALUE(x2, w2) : (word,'a) value)
              : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_char (VALUE(x1, w1) : (char,'a) value,
               VALUE(x2, w2) : (char,'a) value)
              : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_string (VALUE(x1, w1) : (string,'a) value,
                 VALUE(x2, w2) : (string,'a) value)
                : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_real (VALUE(x1, w1) : (real,'a) value,
               VALUE(x2, w2) : (real,'a) value)
              : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_intOption (VALUE(x1, w1) : (int option,'a) value,
                    VALUE(x2, w2) : (int option,'a) value)
                   : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_wordOption (VALUE(x1, w1) : (word option,'a) value,
                     VALUE(x2, w2) : (word option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_charOption (VALUE(x1, w1) : (char option,'a) value,
                     VALUE(x2, w2) : (char option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_boolOption (VALUE(x1, w1) : (bool option,'a) value,
                     VALUE(x2, w2) : (bool option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_stringOption (VALUE(x1, w1) : (string option,'a) value,
                       VALUE(x2, w2) : (string option,'a) value)
                      : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_realOption (VALUE(x1, w1) : (real option,'a) value,
                     VALUE(x2, w2) : (real option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)

  fun neq_int (VALUE(x1, w1) : (int,'a) value,
               VALUE(x2, w2) : (int,'a) value)
              : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_word (VALUE(x1, w1) : (word,'a) value,
                VALUE(x2, w2) : (word,'a) value)
               : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_char (VALUE(x1, w1) : (char,'a) value,
                VALUE(x2, w2) : (char,'a) value)
               : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_string (VALUE(x1, w1) : (string,'a) value,
                  VALUE(x2, w2) : (string,'a) value)
                 : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_real (VALUE(x1, w1) : (real,'a) value,
                VALUE(x2, w2) : (real,'a) value)
               : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_intOption (VALUE(x1, w1) : (int option,'a) value,
                     VALUE(x2, w2) : (int option,'a) value)
                    : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_wordOption (VALUE(x1, w1) : (word option,'a) value,
                      VALUE(x2, w2) : (word option,'a) value)
                     : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_charOption (VALUE(x1, w1) : (char option,'a) value,
                      VALUE(x2, w2) : (char option,'a) value)
                     : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_boolOption (VALUE(x1, w1) : (bool option,'a) value,
                      VALUE(x2, w2) : (bool option,'a) value)
                     : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_stringOption (VALUE(x1, w1) : (string option,'a) value,
                        VALUE(x2, w2) : (string option,'a) value)
                       : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_realOption (VALUE(x1, w1) : (real option,'a) value,
                      VALUE(x2, w2) : (real option,'a) value)
                     : (bool option,'a) value =
      op2 (x1, "<>", x2, SOME true)

  fun strcat (VALUE(x1, w1) : (string,'a) value,
              VALUE(x2, w2) : (string,'a) value)
             : (string,'a) value =
      op2 (x1, "||", x2, "")

  fun andAlso (VALUE(x1, w1) : (bool option, 'a) value,
               VALUE(x2, w2) : (bool option, 'a) value)
               : (bool option, 'a) value =
      op2 (x1, "and", x2, w1)

  fun orElse (VALUE(x1, w1) : (bool option, 'a) value,
              VALUE(x2, w2) : (bool option, 'a) value)
              : (bool option, 'a) value =
      op2 (x1, "or", x2, w1)

  fun not (VALUE(x1, w1) : (bool option, 'a) value) =
      op1 ("not", x1, w1)

  fun isNull (VALUE(x1, w1) : ('a option, 'a) value)
      : (bool option, 'a) value =
      op1post (x1, " is null", NONE)

  fun isNotNull (VALUE(x1, w1) : ('a option, 'a) value)
      : (bool option, 'a) value =
      op1post (x1, " is not null", NONE)

  end (* local *)

  local
    fun sqlInt x = Int.toString x
    fun sqlWord x = Word.fmt StringCvt.DEC x
    fun sqlReal x =
        String.translate (fn #"~" => "-" | x => str x)
                         (Real.fmt StringCvt.EXACT x)
    fun sqlString x =
        "'" ^ String.translate (fn #"'" => "''" | x => str x) x ^ "'"
    fun sqlChar x = sqlString (str x)
    fun sqlBool true = "t" | sqlBool false = "f"
    fun nullValue x = VALUE (("NULL", DBI), x)
  in

  fun toSQL_int (x:int) : (int, 'a) value =
      VALUE ((sqlInt x, DBI), x)
  fun toSQL_word (x:word) : (word, 'a) value =
      VALUE ((sqlWord x, DBI), x)
  fun toSQL_char (x:char) : (char, 'a) value =
      VALUE ((sqlChar x, DBI), x)
  fun toSQL_string (x:string) : (string, 'a) value =
      VALUE ((sqlString x, DBI), x)
  fun toSQL_real (x:real) : (real, 'a) value =
      VALUE ((sqlReal x, DBI), x)
  fun toSQL_intOption (x:int option) : (int option, 'a) value =
      case x of SOME y => VALUE ((sqlInt y, DBI), x) | NONE => nullValue x
  fun toSQL_wordOption (x:word option) : (word option, 'a) value =
      case x of SOME y => VALUE ((sqlWord y, DBI), x) | NONE => nullValue x
  fun toSQL_boolOption (x:bool option) : (bool option, 'a) value =
      case x of SOME y => VALUE ((sqlBool y, DBI), x) | NONE => nullValue x
  fun toSQL_charOption (x:char option) : (char option, 'a) value =
      case x of SOME y => VALUE ((sqlChar y, DBI), x) | NONE => nullValue x
  fun toSQL_stringOption (x:string option) : (string option, 'a) value =
      case x of SOME y => VALUE ((sqlString y, DBI), x) | NONE => nullValue x
  fun toSQL_realOption (x:real option) : (real option, 'a) value =
      case x of SOME y => VALUE ((sqlReal y, DBI), x) | NONE => nullValue x

  end (* local *)

  local

    fun nonnull (SOME x) = x
      | nonnull NONE = raise Format
  in

  fun fromSQL_int (col, RESULT (r, row), _:int) =
      nonnull (Backend.getInt (r, row, col))
  fun fromSQL_word (col, RESULT (r, row), _:word) =
      nonnull (Backend.getWord (r, row, col))
  fun fromSQL_char (col, RESULT (r, row), _:char) =
      nonnull (Backend.getChar (r, row, col))
  fun fromSQL_real (col, RESULT (r, row), _:real) =
      nonnull (Backend.getReal (r, row, col))
  fun fromSQL_intOption (col, RESULT (r, row), _:int option) =
      Backend.getInt (r, row, col)
  fun fromSQL_wordOption (col, RESULT (r, row), _:word option) =
      Backend.getWord (r, row, col)
  fun fromSQL_charOption (col, RESULT (r, row), _:char option) =
      Backend.getChar (r, row, col)
  fun fromSQL_boolOption (col, RESULT (r, row), _:bool option) =
      Backend.getBool (r, row, col)
  fun fromSQL_stringOption (col, RESULT (r, row), _:string option) =
      Backend.getString (r, row, col)
  fun fromSQL_realOption (col, RESULT (r, row), _:real option) =
      Backend.getReal (r, row, col)
  fun fromSQL_string (col, RESULT (r, row), _:string) =
      nonnull (Backend.getString (r, row, col))

  end (* local *)

(*
  fun fromSQL_int (col:int, r:result, _:int) : int =
      SMLSharp.SQLImpl.fromSQL_int (col, r)
  fun fromSQL_word (col:int, r:result, _:word) : word =
      SMLSharp.SQLImpl.fromSQL_word (col, r)
  fun fromSQL_char (col:int, r:result, _:char) : char =
      SMLSharp.SQLImpl.fromSQL_char (col, r)
  fun fromSQL_string (col:int, r:result, _:string) : string =
      SMLSharp.SQLImpl.fromSQL_string (col, r)
  fun fromSQL_real (col:int, r:result, _:real) : real =
      SMLSharp.SQLImpl.fromSQL_real (col, r)
  fun fromSQL_intOption (col:int, r:result, _:int option)
                        : int option =
      SMLSharp.SQLImpl.fromSQL_intOption (col, r)
  fun fromSQL_wordOption (col:int, r:result, _:word option)
                         : word option =
      SMLSharp.SQLImpl.fromSQL_wordOption (col, r)
  fun fromSQL_charOption (col:int, r:result, _:char option)
                         : char option =
      SMLSharp.SQLImpl.fromSQL_charOption (col, r)
  fun fromSQL_boolOption (col:int, r:result, _:bool option)
                         : bool option =
      SMLSharp.SQLImpl.fromSQL_boolOption (col, r)
  fun fromSQL_stringOption (col:int, r:result, _:string option)
                           : string option =
      SMLSharp.SQLImpl.fromSQL_stringOption (col, r)
  fun fromSQL_realOption (col:int, r:result, _:real option)
                         : real option =
      SMLSharp.SQLImpl.fromSQL_realOption (col, r)
*)

  fun default_int () : (int, 'a) value =
      VALUE (("DEFAULT", DBI), 0)
  fun default_word () : (word, 'a) value =
      VALUE (("DEFAULT", DBI), 0w0)
  fun default_char () : (char, 'a) value =
      VALUE (("DEFAULT", DBI), #"\000")
  fun default_string () : (string, 'a) value =
      VALUE (("DEFAULT", DBI), "")
  fun default_real () : (real, 'a) value =
      VALUE (("DEFAULT", DBI), 0.0)
  fun default_intOption () : (int option, 'a) value =
      VALUE (("DEFAULT", DBI), SOME 0)
  fun default_wordOption () : (word option, 'a) value =
      VALUE (("DEFAULT", DBI), SOME 0w0)
  fun default_charOption () : (char option, 'a) value =
      VALUE (("DEFAULT", DBI), SOME #"\000")
  fun default_boolOption () : (bool option, 'a) value =
      VALUE (("DEFAULT", DBI), SOME true)
  fun default_stringOption () : (string option, 'a) value =
      VALUE (("DEFAULT", DBI), SOME "")
  fun default_realOption () : (real option, 'a) value =
      VALUE (("DEFAULT", DBI), SOME 0.0)

end
