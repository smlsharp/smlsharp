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

  datatype ty = datatype SMLSharp_SQL_BackendTy.ty

  datatype backend = datatype Backend.backend
  datatype 'a schema = SCHEMA of Backend.schema * 'a
  datatype 'a server = SERVER of backend * 'a schema
  datatype 'a conn = CONN of Backend.conn_impl * 'a
  datatype 'a rows = 
      FETCHED of 'a * 'a rel
    | RES of Backend.res_impl * (Backend.res_impl -> 'a)
    | EOR
    | CLOSED
  withtype 'a rel = 'a rows ref
  datatype dbi = datatype SMLSharp_Builtin.SQL.dbi
  datatype ('a,'b) db = DB of 'a * 'b dbi
  datatype ('a,'b) table = TABLE of (string * 'b dbi) * 'a
  datatype ('a,'b) row = ROW of (string * 'b dbi) * 'a 
  datatype value = datatype SMLSharp_Builtin.SQL.value
  datatype res_impl = datatype Backend.res_impl
  datatype 'a query = QUERY of string * 'a * (res_impl -> 'a)
  datatype command = COMMAND of string
  type timestamp = TimeStamp.timestamp
  type decimal = Decimal.decimal
  type float = Float.float

  exception Format = Errors.Format
  exception Exec = Errors.Exec
  exception Connect = Errors.Connect
  exception Link = Errors.Link

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

  fun eval (dbi, queryFn) (CONN (conn, witness)) =
      let
        val QUERY (query, witness, fetchFn) =
            queryFn (DB (witness, dbi))
        val r = #execQuery conn query
      in
        ref (RES (r, fetchFn))
      end

  fun exec (dbi, commandFn) (CONN (conn, witness)) =
      let
        val COMMAND query =
            commandFn (DB (witness, dbi))
        val R r = #execQuery conn query
        val () = #closeRel r ()
      in
        ()
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

  fun queryString queryFn (SERVER (_, SCHEMA (_, witness))) =
      let
        val QUERY (query, witness, fetchFn) =
            queryFn (DB (witness, DBI))
      in
        query
      end

  fun commandString commandFn (SERVER (_, SCHEMA (_, witness))) =
      let
        val COMMAND query =
            commandFn (DB (witness, DBI))
      in
        query
      end

  local
    fun typename ({nullable, ty, ...}:Backend.schema_column) =
        let
          fun opt x = if nullable then x ^ " option" else x
        in
          case ty of
            SMLSharp_SQL_BackendTy.INT => opt "int"
          | SMLSharp_SQL_BackendTy.INTINF => opt "intinf"
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

  fun connect (SERVER (BACKEND backend, SCHEMA (schema, witness))) =
      let
        val conn = #connect backend ()
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

  fun columnInfo_int colname =
      (0, {colname = colname, ty = INT, nullable = false})
      : int * Backend.schema_column 
  fun columnInfo_intInf colname =
      (0, {colname = colname, ty = INTINF, nullable = false})
      : IntInf.int * Backend.schema_column
  fun columnInfo_word colname =
      (0w0, {colname = colname, ty = WORD, nullable = false})
      : word * Backend.schema_column
  fun columnInfo_char colname =
      (#"\000", {colname = colname, ty = CHAR, nullable = false})
      : char * Backend.schema_column
  fun columnInfo_string colname =
      ("", {colname = colname, ty = STRING, nullable = false})
      : string * Backend.schema_column
  fun columnInfo_real colname =
      (0.0, {colname = colname, ty = REAL, nullable = false})
      : real * Backend.schema_column
  fun columnInfo_real32 colname =
      (0.0, {colname = colname, ty = REAL32, nullable = false})
      : Real32.real * Backend.schema_column
  fun columnInfo_bool colname =
      (false, {colname = colname, ty = BOOL, nullable = false})
      : bool * Backend.schema_column
  fun columnInfo_timestamp colname =
      (TimeStamp.fromString "",
       {colname = colname, ty = TIMESTAMP, nullable = false})
      : timestamp * Backend.schema_column
  fun columnInfo_decimal colname =
      (Decimal.fromString "",
       {colname = colname, ty = DECIMAL, nullable = false})
      : decimal * Backend.schema_column
  fun columnInfo_float colname =
      (Float.fromString "",
       {colname = colname, ty = FLOAT, nullable = false})
      : float * Backend.schema_column
  fun columnInfo_int_option colname =
      (NONE, {colname = colname, ty = INT, nullable = true})
      : int option * Backend.schema_column
  fun columnInfo_intInf_option colname =
      (NONE, {colname = colname, ty = INTINF, nullable = true})
      : IntInf.int option * Backend.schema_column
  fun columnInfo_word_option colname =
      (NONE, {colname = colname, ty = WORD, nullable = true})
      : word option * Backend.schema_column
  fun columnInfo_char_option colname =
      (NONE, {colname = colname, ty = CHAR, nullable = true})
      : char option * Backend.schema_column
  fun columnInfo_string_option colname =
      (NONE, {colname = colname, ty = STRING, nullable = true})
      : string option * Backend.schema_column
  fun columnInfo_real_option colname =
      (NONE, {colname = colname, ty = REAL, nullable = true})
      : real option * Backend.schema_column
  fun columnInfo_real32_option colname =
      (NONE, {colname = colname, ty = REAL32, nullable = true})
      : Real32.real option * Backend.schema_column
  fun columnInfo_bool_option colname =
      (NONE, {colname = colname, ty = BOOL, nullable = true})
      : bool option * Backend.schema_column
  fun columnInfo_timestamp_option colname =
      (NONE, {colname = colname, ty = TIMESTAMP, nullable = true})
      : timestamp option * Backend.schema_column
  fun columnInfo_decimal_option colname =
      (NONE, {colname = colname, ty = DECIMAL, nullable = true})
      : decimal option * Backend.schema_column
  fun columnInfo_float_option colname =
      (NONE, {colname = colname, ty = FLOAT, nullable = true})
      : float option * Backend.schema_column

  local
    fun op1 (oper, (x1,i), w) =
        VALUE (("(" ^ oper ^ x1 ^ ")", i), w)
    fun op1post ((x1,i), oper, w) =
        VALUE (("(" ^ x1 ^ oper ^ ")", i), w)
    fun op2 ((x1,i1:'a dbi), oper2, (x2,i2:'a dbi), w) =
        VALUE (("(" ^ x1 ^ " " ^ oper2 ^ " " ^ x2 ^ ")", i1), w)
  in

  fun add (VALUE(x1, w1) : ('b,'a) value,
           VALUE(x2, w2) : ('b,'a) value)
          : ('b,'a) value =
      op2 (x1, "+", x2, w1)
  fun sub (VALUE(x1, w1) : ('b,'a) value,
           VALUE(x2, w2) : ('b,'a) value)
          : ('b,'a) value =
      op2 (x1, "-", x2, w1)
  fun mul (VALUE(x1, w1) : ('b,'a) value,
           VALUE(x2, w2) : ('b,'a) value)
          : ('b,'a) value =
      op2 (x1, "*", x2, w1)
  fun div (VALUE(x1, w1) : ('b,'a) value,
           VALUE(x2, w2) : ('b,'a) value)
          : ('b,'a) value =
      op2 (x1, "/", x2, w1)
  fun mod (VALUE(x1, w1) : ('b,'a) value,
           VALUE(x2, w2) : ('b,'a) value)
          : ('b,'a) value =
      op2 (x1, "%", x2, w1)
  fun neg (VALUE(x1, w1) : ('b,'a) value)
          : ('b,'a) value =
      op1 ("-", x1, w1)
  fun abs (VALUE(x1, w1) : ('b,'a) value)
          : ('b,'a) value =
      op1 ("@", x1, w1)
  fun lt (VALUE(x1, w1) : ('b,'a) value,
          VALUE(x2, w2) : ('b,'a) value)
         : (bool option,'a) value =
      op2 (x1, "<", x2, SOME true)
  fun le (VALUE(x1, w1) : ('b,'a) value,
          VALUE(x2, w2) : ('b,'a) value)
         : (bool option,'a) value =
      op2 (x1, "<=", x2, SOME true)
  fun gt (VALUE(x1, w1) : ('b,'a) value,
          VALUE(x2, w2) : ('b,'a) value)
         : (bool option,'a) value =
      op2 (x1, ">", x2, SOME true)
  fun ge (VALUE(x1, w1) : ('b,'a) value,
          VALUE(x2, w2) : ('b,'a) value)
         : (bool option,'a) value =
      op2 (x1, ">=", x2, SOME true)
  fun eq (VALUE(x1, w1) : ('b,'a) value,
          VALUE(x2, w2) : ('b,'a) value)
         : (bool option,'a) value =
      op2 (x1, "=", x2, SOME true)
  fun neq (VALUE(x1, w1) : ('b,'a) value,
           VALUE(x2, w2) : ('b,'a) value)
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

  local
    fun likeOp (VALUE (x1, w1), VALUE (x2, w2)) = 
        op2 (x1, "like", x2, SOME true) : (bool option, 'a) value
    type ('a,'b) t = ('a,'b) value * ('a,'b) value -> (bool option,'b) value
  in
  val likeString : (string, 'a) t = likeOp
  val likeStringOption : (string option, 'a) t = likeOp
  end (* local *)

  end (* local *)

  local
    fun sqlInt x =
        CharVector.map (fn #"~" => #"-" | c => c) (Int.toString x)
    fun sqlIntInf x =
        CharVector.map (fn #"~" => #"-" | c => c) (IntInf.toString x)
    fun sqlWord x = Word.fmt StringCvt.DEC x
    fun sqlReal x =
        CharVector.map (fn #"~" => #"-" | c => c) (Real.fmt StringCvt.EXACT x)
    fun sqlString x =
        "'" ^ String.translate (fn #"'" => "''" | x => str x) x ^ "'"
    fun sqlChar x = sqlString (str x)
    fun sqlBool true = "t" | sqlBool false = "f"
    fun nullValue x = VALUE (("NULL", DBI), x)
    fun sqlTimestamp x = TimeStamp.toString x
  in

  fun toSQL_int (x:int) : (int, 'a) value =
      VALUE ((sqlInt x, DBI), x)
  fun toSQL_intInf (x:IntInf.int) : (IntInf.int, 'a) value =
      VALUE ((sqlIntInf x, DBI), x)
  fun toSQL_word (x:word) : (word, 'a) value =
      VALUE ((sqlWord x, DBI), x)
  fun toSQL_char (x:char) : (char, 'a) value =
      VALUE ((sqlChar x, DBI), x)
  fun toSQL_string (x:string) : (string, 'a) value =
      VALUE ((sqlString x, DBI), x)
  fun toSQL_real (x:real) : (real, 'a) value =
      VALUE ((sqlReal x, DBI), x)
  fun toSQL_timestamp (x:TimeStamp.timestamp) : (TimeStamp.timestamp, 'a) value =
      VALUE ((sqlTimestamp x, DBI), x)
  fun toSQL_decimal (x:decimal) : (decimal, 'a) value =
      VALUE ((Decimal.toString x, DBI), x)
  fun toSQL_float (x:float) : (float, 'a) value =
      VALUE ((Float.toString x, DBI), x)
  fun toSQL_intOption (x:int option) : (int option, 'a) value =
      case x of SOME y => VALUE ((sqlInt y, DBI), x) | NONE => nullValue x
  fun toSQL_intInfOption (x:IntInf.int option) : (IntInf.int option, 'a) value =
      case x of SOME y => VALUE ((sqlIntInf y, DBI), x) | NONE => nullValue x
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
  fun toSQL_timestampOption (x:TimeStamp.timestamp option) : (TimeStamp.timestamp option, 'a) value =
      case x of SOME y => VALUE ((sqlTimestamp y, DBI), x) | NONE => nullValue x
  fun toSQL_decimalOption (x:decimal option) : (decimal option, 'a) value =
      case x of SOME y => VALUE ((Decimal.toString y, DBI), x)
              | NONE => nullValue x
  fun toSQL_floatOption (x:float option) : (float option, 'a) value =
      case x of SOME y => VALUE ((Float.toString y, DBI), x)
              | NONE => nullValue x

  end (* local *)

  local

    fun nonnull (SOME x) = x
      | nonnull NONE = raise Format
  in

  fun fromSQL_int (col, R r, _:int) =
      nonnull (#getInt r col)
  fun fromSQL_intInf (col, R r, _:IntInf.int) =
      nonnull (#getIntInf r col)
  fun fromSQL_word (col, R r, _:word) =
      nonnull (#getWord r col)
  fun fromSQL_char (col, R r, _:char) =
      nonnull (#getChar r col)
  fun fromSQL_real (col, R r, _:real) =
      nonnull (#getReal r col)
  fun fromSQL_string (col, R r, _:string) =
      nonnull (#getString r col)
  fun fromSQL_timestamp (col, R r, _:TimeStamp.timestamp) =
      nonnull (#getTimestamp r col)
  fun fromSQL_decimal (col, R r, _:decimal) =
      nonnull (#getDecimal r col)
  fun fromSQL_float (col, R r, _:float) =
      nonnull (#getFloat r col)
  fun fromSQL_intOption (col, R r, _:int option) =
      #getInt r col
  fun fromSQL_intInfOption (col, R r, _:IntInf.int option) =
      #getIntInf r col
  fun fromSQL_wordOption (col, R r, _:word option) =
      #getWord r col
  fun fromSQL_charOption (col, R r, _:char option) =
      #getChar r col
  fun fromSQL_boolOption (col, R r, _:bool option) =
      #getBool r col
  fun fromSQL_stringOption (col, R r, _:string option) =
      #getString r col
  fun fromSQL_realOption (col, R r, _:real option) =
      #getReal r col
  fun fromSQL_timestampOption (col, R r, _:TimeStamp.timestamp option) =
      #getTimestamp r col
  fun fromSQL_decimalOption (col, R r, _:decimal option) =
      #getDecimal r col
  fun fromSQL_floatOption (col, R r, _:float option) =
      #getFloat r col

  end (* local *)

(*
  fun fromSQL_int (col:int, r:result, _:int) : int =
      SMLSharp_Builtin.SQLImpl.fromSQL_int (col, r)
  fun fromSQL_word (col:int, r:result, _:word) : word =
      SMLSharp_Builtin.SQLImpl.fromSQL_word (col, r)
  fun fromSQL_char (col:int, r:result, _:char) : char =
      SMLSharp_Builtin.SQLImpl.fromSQL_char (col, r)
  fun fromSQL_string (col:int, r:result, _:string) : string =
      SMLSharp_Builtin.SQLImpl.fromSQL_string (col, r)
  fun fromSQL_real (col:int, r:result, _:real) : real =
      SMLSharp_Builtin.SQLImpl.fromSQL_real (col, r)
  fun fromSQL_intOption (col:int, r:result, _:int option)
                        : int option =
      SMLSharp_Builtin.SQLImpl.fromSQL_intOption (col, r)
  fun fromSQL_wordOption (col:int, r:result, _:word option)
                         : word option =
      SMLSharp_Builtin.SQLImpl.fromSQL_wordOption (col, r)
  fun fromSQL_charOption (col:int, r:result, _:char option)
                         : char option =
      SMLSharp_Builtin.SQLImpl.fromSQL_charOption (col, r)
  fun fromSQL_boolOption (col:int, r:result, _:bool option)
                         : bool option =
      SMLSharp_Builtin.SQLImpl.fromSQL_boolOption (col, r)
  fun fromSQL_stringOption (col:int, r:result, _:string option)
                           : string option =
      SMLSharp_Builtin.SQLImpl.fromSQL_stringOption (col, r)
  fun fromSQL_realOption (col:int, r:result, _:real option)
                         : real option =
      SMLSharp_Builtin.SQLImpl.fromSQL_realOption (col, r)
*)

  fun default_int () : (int, 'a) value =
      VALUE (("DEFAULT", DBI), 0)
  fun default_intInf () : (IntInf.int, 'a) value =
      VALUE (("DEFAULT", DBI), 0)
  fun default_word () : (word, 'a) value =
      VALUE (("DEFAULT", DBI), 0w0)
  fun default_char () : (char, 'a) value =
      VALUE (("DEFAULT", DBI), #"\000")
  fun default_string () : (string, 'a) value =
      VALUE (("DEFAULT", DBI), "")
  fun default_real () : (real, 'a) value =
      VALUE (("DEFAULT", DBI), 0.0)
  fun default_timestamp () : (TimeStamp.timestamp, 'a) value =
      VALUE (("DEFAULT", DBI), TimeStamp.defaultTimestamp)
  fun default_intOption () : (int option, 'a) value =
      VALUE (("DEFAULT", DBI), SOME 0)
  fun default_intInfOption () : (IntInf.int option, 'a) value =
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
  fun default_timestampOption () : (TimeStamp.timestamp option, 'a) value =
      VALUE (("DEFAULT", DBI), SOME TimeStamp.defaultTimestamp)

end
