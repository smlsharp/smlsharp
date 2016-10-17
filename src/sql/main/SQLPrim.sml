(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @author SATO Hirohuki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SMLSharp_SQL_Prim =
struct

  nonfix div mod

  structure Backend = SMLSharp_SQL_Backend
  structure Errors = SMLSharp_SQL_Errors
  structure TimeStamp = SMLSharp_SQL_TimeStamp
  structure Decimal = SMLSharp_SQL_Decimal
  structure Float = SMLSharp_SQL_Float

  exception Format = Errors.Format
  exception Exec = Errors.Exec
  exception Connect = Errors.Connect
  exception Link = Errors.Link
  exception InvalidCommand

  datatype backend = datatype Backend.backend
  datatype 'a schema = SCHEMA of SMLSharp_SQL_Backend.schema * (unit -> 'a)
  datatype 'a server = SERVER of backend * 'a schema
  datatype 'a conn = CONN of Backend.conn_impl * (unit -> 'a)
  datatype 'a db = DB of unit -> 'a
  datatype 'a rows =
      FETCHED of 'a * 'a rel
    | RES of Backend.res_impl * (Backend.res_impl -> 'a)
    | EOR
    | CLOSED
  withtype 'a rel = 'a rows ref
  datatype res_impl = datatype Backend.res_impl
  type timestamp = TimeStamp.timestamp
  type decimal = Decimal.decimal
  type float = Float.float

  open SMLSharp_SQL_Query

  datatype qconst =
      CONST_INT of int
    | CONST_WORD of word
    | CONST_REAL of real
    | CONST_STRING of string
    | CONST_CHAR of char

  fun constToExp qconst =
      case qconst of
        CONST_INT x => INT x
      | CONST_WORD x => WORD x
      | CONST_REAL x => REAL x
      | CONST_STRING x => STRING x
      | CONST_CHAR x => CHAR x

  datatype 'w dbi = DBI
  type ('a,'w) toy = 'w dbi -> 'a
  type ('a,'b) selector = ('a -> 'b) * string
  type ('a,'w) raw_row = (string * qexp) list * ('a,'w) toy

  datatype ('a,'w) db' = DB' of 'w dbi * ('a,'w) toy
  datatype ('a,'w) table = TABLE of string * ('a,'w) toy
  datatype ('a,'w) row = ROW of string option * ('a,'w) toy
  datatype ('a,'w) value' = V of qexp * ('a,'w) toy
  datatype ('a,'w) value = VALUE of ('a,'w) value' | CONST of qconst * 'a
  type 'w bool_value = (bool option, 'w) value
  datatype 'a query = QUERY of qtable5 * (res_impl -> 'a) * (unit -> 'a)

  fun readValue (VALUE (V x)) = x
    | readValue (CONST (q, x)) = (constToExp q, fn DBI => x)

  fun sqlserver_string (desc, schema) =
      SERVER (Backend.default desc, schema)

  fun sqlserver_backend (x, schema) =
      SERVER (x, schema)

  fun fetch (ref EOR) = NONE
    | fetch (ref CLOSED) = raise Exec "closed relation"
    | fetch (ref (FETCHED x)) = SOME x
    | fetch (r as ref (RES (R res, fetchFn))) =
      case #fetch res () of
        NONE =>
        (r := EOR;
         #closeRel res ();
         NONE)
      | SOME res =>
        let
          val row = fetchFn res
          val ret = (row, ref (RES (res, fetchFn)))
        in
          r := FETCHED ret;
          SOME ret
        end

  fun closeConn (CONN (conn, _)) = #closeConn conn ()

  fun closeRel (ref EOR) = ()
    | closeRel (ref CLOSED) = ()
    | closeRel (ref (FETCHED (_, rel))) = closeRel rel
    | closeRel (r as ref (RES (R res, _))) =
      (r := CLOSED; #closeRel res ())

  fun unline s = CharVector.map (fn c => if Char.isSpace c then #" " else c) s

  fun eval sqlFn (CONN (conn, toy)) =
      let
        val QUERY (q, recv, _) = sqlFn (DB toy)
        val query = SMLFormat.prettyPrint nil (format_query q)
        val r = #execQuery conn (unline query)
      in
        ref (RES (r, recv))
      end

  fun exec sqlFn (CONN (conn, toy)) =
      let
        val q = sqlFn (DB toy)
        val command = SMLFormat.prettyPrint nil (format_command q)
        val R r = #execQuery conn (unline command)
        val () = #closeRel r ()
      in
        ()
      end

  val dummyDB = DB (fn () => raise InvalidCommand)

  fun queryString sqlFn =
      let
        val QUERY (q, recv, _) = sqlFn dummyDB
      in
        SMLFormat.prettyPrint nil (format_query q)
      end

  fun commandString sqlFn =
      SMLFormat.prettyPrint nil (format_command (sqlFn dummyDB))

  local
    fun typename ({nullable, ty, ...}:Backend.schema_column) =
        let
          fun opt x = if nullable then x ^ " option" else x
        in
          case ty of
            SMLSharp_SQL_BackendTy.INT => opt "int"
          | SMLSharp_SQL_BackendTy.INTINF => opt "intInf"
          | SMLSharp_SQL_BackendTy.WORD => opt "word"
          | SMLSharp_SQL_BackendTy.CHAR => opt "char"
          | SMLSharp_SQL_BackendTy.STRING => opt "string"
          | SMLSharp_SQL_BackendTy.REAL => opt "real"
          | SMLSharp_SQL_BackendTy.REAL32 => opt "real32"
          | SMLSharp_SQL_BackendTy.BOOL => opt "bool"
          | SMLSharp_SQL_BackendTy.TIMESTAMP => opt "timestamp"
          | SMLSharp_SQL_BackendTy.DECIMAL => opt "decimal"
          | SMLSharp_SQL_BackendTy.FLOAT => opt "float"
          | SMLSharp_SQL_BackendTy.UNSUPPORTED x => "unsupported (" ^ x ^ ")"
        end

    fun unifyColumns (tableName, expectColumns, actualColumns) =
        (
          app (fn expect =>
                  case List.find (fn x => #colname x = #colname expect)
                       actualColumns of
                    NONE => raise Link ("column `" ^ #colname expect
                                        ^ "' of table `" ^ tableName
                                        ^ "' is not found.")
                  | SOME actual =>
                    if expect = actual then ()
                    else raise Link ("type mismatch of column `"
                                     ^ #colname expect ^ "' of table `"
                                     ^ tableName ^ "': expected `"
                                     ^ typename expect
                                     ^ "', but actual `"
                                     ^ typename actual ^ "'"))
              expectColumns;
          app (fn actual =>
                  case List.find (fn x => #colname x = #colname actual)
                       expectColumns of
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

  fun link (conn:Backend.conn_impl, schema) =
      unifySchema (schema, (#getDatabaseSchema conn ()))

  end (* local *)

  fun connect (SERVER (BACKEND backend, SCHEMA (schema, toy))) =
      let
        val conn = #connect backend ()
        val e = (link (conn, schema); NONE)
            handle e => SOME e
      in
        case e of
          NONE => CONN (conn, toy)
        | SOME e => (closeConn (CONN (conn, toy)); raise e)
      end

  fun Some v =
      case readValue v of (q, toy) => VALUE (V (q, SOME o toy))

  val Null =
      VALUE (V (NULL, fn _ => NONE))

  local
    datatype ty = datatype SMLSharp_SQL_BackendTy.ty
  in
  fun columnInfo_int colname =
      (fn () => 0, {colname = colname, ty = INT, nullable = false})
      : (unit -> int) * Backend.schema_column
  fun columnInfo_intInf colname =
      (fn () => 0, {colname = colname, ty = INTINF, nullable = false})
      : (unit -> intInf) * Backend.schema_column
  fun columnInfo_word colname =
      (fn () => 0w0, {colname = colname, ty = WORD, nullable = false})
      : (unit -> word) * Backend.schema_column
  fun columnInfo_char colname =
      (fn () => #"\000", {colname = colname, ty = CHAR, nullable = false})
      : (unit -> char) * Backend.schema_column
  fun columnInfo_string colname =
      (fn () => "", {colname = colname, ty = STRING, nullable = false})
      : (unit -> string) * Backend.schema_column
  fun columnInfo_real colname =
      (fn () => 0.0, {colname = colname, ty = REAL, nullable = false})
      : (unit -> real) * Backend.schema_column
  fun columnInfo_real32 colname =
      (fn () => 0.0, {colname = colname, ty = REAL32, nullable = false})
      : (unit -> real32) * Backend.schema_column
  fun columnInfo_timestamp colname =
      (fn () => TimeStamp.fromString "",
       {colname = colname, ty = TIMESTAMP, nullable = false})
      : (unit -> timestamp) * Backend.schema_column
  fun columnInfo_decimal colname =
      (fn () => Decimal.fromString "",
       {colname = colname, ty = DECIMAL, nullable = false})
      : (unit -> decimal) * Backend.schema_column
  fun columnInfo_float colname =
      (fn () => Float.fromString "",
       {colname = colname, ty = FLOAT, nullable = false})
      : (unit -> float) * Backend.schema_column
  fun columnInfo_int_option colname =
      (fn () => NONE, {colname = colname, ty = INT, nullable = true})
      : (unit -> int option) * Backend.schema_column
  fun columnInfo_intInf_option colname =
      (fn () => NONE, {colname = colname, ty = INTINF, nullable = true})
      : (unit -> intInf option) * Backend.schema_column
  fun columnInfo_word_option colname =
      (fn () => NONE, {colname = colname, ty = WORD, nullable = true})
      : (unit -> word option) * Backend.schema_column
  fun columnInfo_char_option colname =
      (fn () => NONE, {colname = colname, ty = CHAR, nullable = true})
      : (unit -> char option) * Backend.schema_column
  fun columnInfo_string_option colname =
      (fn () => NONE, {colname = colname, ty = STRING, nullable = true})
      : (unit -> string option) * Backend.schema_column
  fun columnInfo_real_option colname =
      (fn () => NONE, {colname = colname, ty = REAL, nullable = true})
      : (unit -> real option) * Backend.schema_column
  fun columnInfo_real32_option colname =
      (fn () => NONE, {colname = colname, ty = REAL32, nullable = true})
      : (unit -> real32 option) * Backend.schema_column
  fun columnInfo_timestamp_option colname =
      (fn () => NONE, {colname = colname, ty = TIMESTAMP, nullable = true})
      : (unit -> timestamp option) * Backend.schema_column
  fun columnInfo_decimal_option colname =
      (fn () => NONE, {colname = colname, ty = DECIMAL, nullable = true})
      : (unit -> decimal option) * Backend.schema_column
  fun columnInfo_float_option colname =
      (fn () => NONE, {colname = colname, ty = FLOAT, nullable = true})
      : (unit -> float option) * Backend.schema_column
  end (* local *)

  fun unify (x:('a,'w)toy, y:('a,'w)toy) = x
  fun falsify _ = NONE : bool option
  fun forceBool (x:bool option) = x
  fun pair (toy1, toy2) : ('a*'b,'w) toy = fn x => (toy1 x, toy2 x)
  fun snd toy : ('a,'w) toy = fn w => case toy w of (t1, t2) => t2

  fun op1 (oper, (q1, t1)) =
      VALUE (V (UNARYOP (oper, q1), t1))
  fun op2 ((q1, t1), con, oper, (q2, t2)) =
      VALUE (V (con (q1, oper, q2), unify (t1, t2)))
  fun cmpop ((q1, t1), oper, (q2, t2)) =
      VALUE (V (CMPOP (q1, oper, q2), falsify o unify (t1, t2)))
  fun logicop ((q1, t1), con, (q2, t2)) =
      VALUE (V (con (q1, q2), falsify o unify (t1, t2)))
  fun pred (con, (q1, t1)) =
      VALUE (V (con q1, falsify o t1))

  fun add (v1, v2) = op2 (readValue v1, ADDOP, "+", readValue v2)
  fun sub (v1, v2) = op2 (readValue v1, ADDOP, "-", readValue v2)
  fun mul (v1, v2) = op2 (readValue v1, ADDOP, "*", readValue v2)
  fun div (v1, v2) = op2 (readValue v1, ADDOP, "/", readValue v2)
  fun mod (v1, v2) = op2 (readValue v1, ADDOP, "%", readValue v2)
  fun neg v = op1 ("-", readValue v)
  fun abs v = op1 ("@", readValue v)
  fun lt (v1, v2) = cmpop (readValue v1, "<", readValue v2)
  fun le (v1, v2) = cmpop (readValue v1, "<=", readValue v2)
  fun gt (v1, v2) = cmpop (readValue v1, ">", readValue v2)
  fun ge (v1, v2) = cmpop (readValue v1, ">=", readValue v2)
  fun eq (v1, v2) = cmpop (readValue v1, "=", readValue v2)
  fun neq (v1, v2) = cmpop (readValue v1, "<>", readValue v2)
  fun strcat (v1, v2) = op2 (readValue v1, ADDOP, "||", readValue v2)
  fun andAlso (v1, v2) = logicop (readValue v1, AND, readValue v2)
  fun orElse (v1, v2) = logicop (readValue v1, OR, readValue v2)
  fun not (v : 'w bool_value) = pred (NOT, readValue v)
  fun isNull v = pred (ISNULL, readValue v)
  fun isNotNull v = pred (ISNOTNULL, readValue v)
  fun like (v1, v2) = cmpop (readValue v1, "like", readValue v2)
  fun like_string (v1, v2 : (string,'w) value) = like (v1, v2)
  fun like_stringOption (v1, v2 : (string option,'w) value) = like (v1, v2)

  fun exists queryFn (db as DB' (w, toy)) =
      let
        val QUERY (q, _, _) = queryFn (DB (fn () => toy w))
      in
        VALUE (V (EXISTS q, falsify o toy))
      end

  fun toSQL_int x = VALUE (V (INT x, fn _ => x))
  fun toSQL_intInf x = VALUE (V (INTINF x, fn _ => x))
  fun toSQL_word x = VALUE (V (WORD x, fn _ => x))
  fun toSQL_char x = VALUE (V (CHAR x, fn _ => x))
  fun toSQL_string x = VALUE (V (STRING x, fn _ => x))
  fun toSQL_real x = VALUE (V (REAL x, fn _ => x))
  fun toSQL_real32 x = VALUE (V (REAL32 x, fn _ => x))
  fun toSQL_timestamp x = VALUE (V (TIMESTAMP x, fn _ => x))
  fun toSQL_decimal x = VALUE (V (DECIMAL x, fn _ => x))
  fun toSQL_float x = VALUE (V (FLOAT x, fn _ => x))

  fun option con (SOME x) = con x
    | option con NONE = NULL

  fun toSQL_intOption x = VALUE (V (option INT x, fn _ => x))
  fun toSQL_intInfOption x = VALUE (V (option INTINF x, fn _ => x))
  fun toSQL_wordOption x = VALUE (V (option WORD x, fn _ => x))
  fun toSQL_charOption x = VALUE (V (option CHAR x, fn _ => x))
  fun toSQL_stringOption x = VALUE (V (option STRING x, fn _ => x))
  fun toSQL_realOption x = VALUE (V (option REAL x, fn _ => x))
  fun toSQL_real32Option x = VALUE (V (option REAL32 x, fn _ => x))
  fun toSQL_timestampOption x = VALUE (V (option TIMESTAMP x, fn _ => x))
  fun toSQL_decimalOption x = VALUE (V (option DECIMAL x, fn _ => x))
  fun toSQL_floatOption x = VALUE (V (option FLOAT x, fn _ => x))

  fun nonnull (SOME x) = x
    | nonnull NONE = raise Format

  fun fromSQL_int (col, R r, _:(int,'w)toy) = nonnull (#getInt r col)
  fun fromSQL_intInf (col, R r, _:(intInf,'w)toy) = nonnull (#getIntInf r col)
  fun fromSQL_word (col, R r, _:(word,'w)toy) = nonnull (#getWord r col)
  fun fromSQL_char (col, R r, _:(char,'w)toy) = nonnull (#getChar r col)
  fun fromSQL_real (col, R r, _:(real,'w)toy) = nonnull (#getReal r col)
  fun fromSQL_real32 (col, R r, _:(real32,'w)toy) = nonnull (#getReal32 r col)
  fun fromSQL_string (col, R r, _:(string,'w)toy) = nonnull (#getString r col)
  fun fromSQL_timestamp (col, R r, _:(TimeStamp.timestamp,'w)toy) =
      nonnull (#getTimestamp r col)
  fun fromSQL_decimal (col, R r, _:(decimal,'w)toy) =
      nonnull (#getDecimal r col)
  fun fromSQL_float (col, R r, _:(float,'w)toy) =
      nonnull (#getFloat r col)
  fun fromSQL_intOption (col, R r, _:(int option,'w)toy) =
      #getInt r col
  fun fromSQL_intInfOption (col, R r, _:(intInf option,'w)toy) =
      #getIntInf r col
  fun fromSQL_wordOption (col, R r, _:(word option,'w)toy) =
      #getWord r col
  fun fromSQL_charOption (col, R r, _:(char option,'w)toy) =
      #getChar r col
  fun fromSQL_stringOption (col, R r, _:(string option,'w)toy) =
      #getString r col
  fun fromSQL_realOption (col, R r, _:(real option,'w)toy) =
      #getReal r col
  fun fromSQL_real32Option (col, R r, _:(real32 option,'w)toy) =
      #getReal32 r col
  fun fromSQL_timestampOption (col, R r, _:(TimeStamp.timestamp option,'w)toy) =
      #getTimestamp r col
  fun fromSQL_decimalOption (col, R r, _:(decimal option,'w)toy) =
      #getDecimal r col
  fun fromSQL_floatOption (col, R r, _:(float option,'w)toy) =
      #getFloat r col

  fun openDB (_:'w -> unit, DB toy) =
      DB' (DBI:'w dbi, fn _:'w dbi => toy ())

  fun getValue (ROW (id, toy), (selector, colname)) =
      VALUE (V (COLUMN (id, colname), selector o toy))

  fun boolQuery v = case readValue v of (q,toy) => (forceBool o toy; q)

  fun getTable (DB' (_, toy), (selector, name)) =
      TABLE (name, selector o toy)

  fun getDefault (TABLE (_, toy), (selector, name)) =
      VALUE (V (DEFAULT, selector o toy))

  datatype ('a,'b,'w) table1 = TABLE1 of qtable1 * ('a,'w) toy * 'b
  datatype ('a,'b,'w) table2 = TABLE2 of qtable2 * ('a,'w) toy * 'b
  datatype ('a,'b,'w) table3 = TABLE3 of qtable3 * ('a,'w) toy * 'b
  datatype ('a,'b,'w) table4 = TABLE4 of qtable4 * ('a,'w) toy * 'b
  datatype ('a,'w) table5 = TABLE5 of qtable5 * ('a,'w) toy

  fun useTable (TABLE (id, toy)) =
      TABLE1 (ID id, toy, ROW (SOME id, toy))

  fun aliasTable (TABLE1 (q, toy, view), name) =
      TABLE1 (AS (q, name), toy, ROW (SOME name, toy))

  fun crossJoin (TABLE1 (q1, toy1, view1), TABLE1 (q2, toy2, view2)) =
      TABLE1 (CROSSJOIN (q1, q2), pair (toy1, toy2), (view1, view2))

  fun innerJoin (TABLE1 (q1, toy1, view1), TABLE1 (q2, toy2, view2), condFn) =
      TABLE1 (INNERJOIN (q1, q2, boolQuery (condFn (view1, view2))),
              pair (toy1, toy2), (view1, view2))

  fun naturalJoin (TABLE1 (q1, toy1, view1), TABLE1 (q2, toy2, view2), join) =
      TABLE1 (NATURALJOIN (q1, q2),
              fn x => join (toy1 x, toy2 x),
              (view1, view2))

  fun dummyJoin (TABLE1 (q1, toy1, view1)) =
      TABLE1 (q1, fn x => (toy1 x, ()), view1)

  fun subquery (queryFn, DB' (w, toy), name) =
      let
        val QUERY (q, _, toy) = queryFn (DB (fn () => toy w))
        val toy = fn DBI => toy ()
      in
        TABLE1 (SUBQUERY (q, name), toy, ROW (SOME name, toy))
      end

  fun sourceTable (TABLE1 (q1, toy1, view1)) =
      TABLE2 (FROM q1, toy1, view1)

  fun useDual () =
      TABLE2 (FROM_DUAL, fn _ => (), ())

  fun chooseRows (TABLE2 (q1, toy1, view1), whereFn) =
      TABLE3 (WHERE (q1, SOME (boolQuery (whereFn view1))), toy1, view1)

  fun chooseAll (TABLE2 (q1, toy1, view1)) =
      TABLE3 (WHERE (q1, NONE), toy1, view1)

  fun mapTable (TABLE3 (q1, toy1, view1), mapFn) =
      let
        val (selectList, toy2) = mapFn view1
      in
        TABLE4 (SELECT {select = selectList, from = q1, orderBy = nil},
                pair (toy1, toy2), (view1, ROW (NONE, toy2)))
      end

  local
    fun sortTable asc (TABLE4 (SELECT select, toy1, view), sortFn) =
        let
          val order = {key = #1 (readValue (sortFn view)), asc = asc}
        in
          TABLE4 (SELECT (select # {orderBy = order :: #orderBy select}),
                  toy1, view)
        end
  in
  fun sortTableAsc x = sortTable true x
  fun sortTableDesc x = sortTable false x
  end (* local *)

  fun selectDistinct (TABLE4 (q1, toy, view1)) =
      TABLE5 (SELECT_DISTINCT q1, snd toy)

  fun selectAll (TABLE4 (q1, toy, view1)) =
      TABLE5 (SELECT_ALL q1, snd toy)

  fun selectDefault (TABLE4 (q1, toy, view1)) =
      TABLE5 (SELECT_DEFAULT q1, snd toy)

  fun readRow (TABLE5 (q1, toy1)) = toy1

  fun makeQuery (TABLE5 (q, toy), recvFn) =
      let
        val _ = [toy, fn _ => recvFn (raise InvalidCommand)]
      in
        fn DB' (w, _) =>
           QUERY (q, recvFn, fn () => toy w)
      end

  fun deleteRows (TABLE3 (q1 as WHERE (q2, _), toy1, view1)) =
      let
        val _ =
            case q2 of
              FROM (ID _) => ()
            | FROM (AS (ID _, _)) => ()
            | _ => raise InvalidCommand
      in
        fn DB' (w, _) => (fn () => toy1 w; DELETE q1)
      end

  fun updateRows (TABLE3 (WHERE (q1, q2), toy1, view1), setFn) =
      let
        val (updatee, from) =
            case q1 of
              FROM (t as ID _) => (t, NONE)
            | FROM (t as AS (ID _, _)) => (t, NONE)
            | FROM (CROSSJOIN (t as ID _, s)) => (t, SOME s)
            | FROM (CROSSJOIN (t as (AS (ID _, _)), s)) => (t, SOME s)
            | _ => raise InvalidCommand
        val orig = (fn (x,_) => x) o toy1
        val (setList, toy) = setFn (view1, orig)
        val (labels, values) = ListPair.unzip setList
        val result = unify (orig, toy)
      in
        fn DB' (w, _) =>
           (fn () => result w;
            UPDATE {table = updatee,
                    labels = labels,
                    values = values,
                    from = from,
                    whereCond = q2})
      end

  fun insertRows (TABLE (q1, toy1), rows : ('a,'w) raw_row list) =
      let
        val (ql, toys) = ListPair.unzip rows
        val labels = case ql of h::_ => map #1 h | nil => nil
        val _ = if List.all (fn i => map #1 i = labels) ql
                then () else raise InvalidCommand
        val result = fn x => map (fn toy => toy x) (toy1::toys)
      in
        fn DB' (w, _) =>
           (fn () => result w;
            INSERT {into = q1, labels = labels, values = map (map #2) ql})
      end

  val beginTransaction = fn DB' _ => BEGIN
  val commitTransaction = fn DB' _ => COMMIT
  val rollbackTransaction = fn DB' _ => ROLLBACK

end
