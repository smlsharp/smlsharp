(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SMLSharp = struct open SMLSharp
  structure SQLImpl : sig

    exception Type of string
    exception Format
    exception Exec of string
    exception Connect of string
    exception Link of string

    val debug_verbose : bool ref

    val connect : 'a '_SQL'.server -> 'a '_SQL'.conn
    val eval : 'a '_SQL'.dbi * (('b, 'a) '_SQL'.db -> 'c '_SQL'.query)
               -> 'b '_SQL'.conn -> 'c '_SQL'.rel
    val exec : 'a '_SQL'.dbi * (('b, 'a) '_SQL'.db -> '_SQL'.command)
               -> 'b '_SQL'.conn -> unit
    val fetch : 'a '_SQL'.rel -> ('a * 'a '_SQL'.rel) option
    val closeConn : 'a '_SQL'.conn -> unit
    val closeRel : 'a '_SQL'.rel -> unit

    val subquery : (('a,'b) '_SQL'.db -> 'c '_SQL'.query)
                   -> ('a,'b) '_SQL'.db -> ('c,'b) '_SQL'.table
    val exists : (('a,'b) '_SQL'.db -> 'c '_SQL'.query)
                 -> ('a,'b) '_SQL'.db -> (bool option, 'b) '_SQL'.value

    val queryString : (('a,'b) '_SQL'.db -> 'c '_SQL'.query)
                      -> 'a '_SQL'.server -> string
    val commandString : (('a,'b) '_SQL'.db -> '_SQL'.command)
                        -> 'a '_SQL'.server -> string

    val fromSQL_int : int * '_SQL'.result -> int
    val fromSQL_word : int * '_SQL'.result -> word
    val fromSQL_char : int * '_SQL'.result -> char
    val fromSQL_string : int * '_SQL'.result -> string
    val fromSQL_real : int * '_SQL'.result -> real
    val fromSQL_intOption : int * '_SQL'.result -> int option
    val fromSQL_wordOption : int * '_SQL'.result -> word option
    val fromSQL_charOption : int * '_SQL'.result -> char option
    val fromSQL_boolOption : int * '_SQL'.result -> bool option
    val fromSQL_stringOption : int * '_SQL'.result -> string option
    val fromSQL_realOption : int * '_SQL'.result -> real option

    val Some : ('a, 'b) '_SQL'.value
               -> ('a option, 'b) '_SQL'.value
    val Null : ('a option, 'b) '_SQL'.value

  end =
  struct
    exception Type of string
    exception Format = PGSQL.Format
    exception Exec of string
    exception Connect of string
    exception Link of string

    fun eof ('_SQL'.RESULT (result, rowIndex)) =
        rowIndex >= PGSQL.PQntuples () result
    fun next ('_SQL'.RESULT (result, rowIndex)) =
        '_SQL'.RESULT (result, rowIndex + 1)

    fun fetch ('_SQL'.REL (result, fetchFn)) =
        if eof result
        then NONE
        else SOME (fetchFn result, '_SQL'.REL (next result, fetchFn))

    val debug_verbose = ref false

    fun execQuery (conn, queryString) =
        let
          val _ = if !debug_verbose
                  then TextIO.output (TextIO.stdErr, queryString ^ "\n")
                  else ()
          val r = PGSQL.PQexec () (conn, queryString)
          val s = if r = NULL
                  then PGSQL.PGRES_FATAL_ERROR
                  else PGSQL.PQresultStatus () r
        in
          if s = PGSQL.PGRES_COMMAND_OK orelse s = PGSQL.PGRES_TUPLES_OK
          then r
          else raise Exec (if r = NULL then "NULL"
                           else (PGSQL.PQclear () r;
                                 PGSQL.getErrorMessage conn))
        end

    fun eval (dbi, queryFn) ('_SQL'.CONN (conn, witness)) =
        let
          val '_SQL'.QUERY (query, witness, fetchFn) =
              queryFn ('_SQL'.DB (witness, dbi))
          val r = execQuery (conn, query)
        in
          '_SQL'.REL ('_SQL'.RESULT (r, 0), fetchFn)
        end

    fun exec (dbi, commandFn) ('_SQL'.CONN (conn, witness)) =
        let
          val '_SQL'.COMMAND query =
              commandFn ('_SQL'.DB (witness, dbi))
          val r = execQuery (conn, query)
        in
          PGSQL.PQclear () r; ()
        end

    fun closeConn ('_SQL'.CONN (conn, _)) =
        (PGSQL.PQfinish () conn; ())

    fun closeRel ('_SQL'.REL ('_SQL'.RESULT (r, _), _)) =
        (PGSQL.PQclear () r; ())

    fun subquery queryFn (db as '_SQL'.DB (_, dbi)) =
        let
          val '_SQL'.QUERY (query, queryWitness, fetchFn) = queryFn db
        in
          '_SQL'.TABLE (("(" ^ query ^ ")", dbi), queryWitness)
        end

    fun exists queryFn (db as '_SQL'.DB (_, dbi)) =
        let
          val '_SQL'.QUERY (query, queryWitness, fetchFn) = queryFn db
        in
          '_SQL'.VALUE (("(exists (" ^ query ^ "))", dbi), SOME true)
        end

    fun queryString queryFn ('_SQL'.SERVER (_, _, witness)) =
        let
          val '_SQL'.QUERY (query, witness, fetchFn) =
              queryFn ('_SQL'.DB (witness, '_SQL'.DBI))
        in
          query
        end

    fun commandString commandFn ('_SQL'.SERVER (_, _, witness)) =
        let
          val '_SQL'.COMMAND query =
              commandFn ('_SQL'.DB (witness, '_SQL'.DBI))
        in
          query
        end

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

      fun readInt x = Int.fromString x
      fun readWord x = StringCvt.scanString (Word.scan StringCvt.DEC) x
      fun readReal x = Real.fromString x
      fun readString (x:string) = SOME x
      fun readChar x = SOME (String.sub (x, 0)) handle Subscript => NONE
      fun readBool x = case x of "t" => SOME true | "T" => SOME true
                               | "f" => SOME false | "F" => SOME false
                               | _ => Bool.fromString x

      fun nonnull (SOME x) = x
        | nonnull NONE = raise PGSQL.Format
    in

    fun fromSQL_int (col, '_SQL'.RESULT (r, row)) =
        nonnull (PGSQL.getValue readInt (r, row, col))
    fun fromSQL_word (col, '_SQL'.RESULT (r, row)) =
        nonnull (PGSQL.getValue readWord (r, row, col))
    fun fromSQL_char (col, '_SQL'.RESULT (r, row)) =
        nonnull (PGSQL.getValue readChar (r, row, col))
    fun fromSQL_string (col, '_SQL'.RESULT (r, row)) =
        nonnull (PGSQL.getValue readString (r, row, col))
    fun fromSQL_real (col, '_SQL'.RESULT (r, row)) =
        nonnull (PGSQL.getValue readReal (r, row, col))
    fun fromSQL_intOption (col, '_SQL'.RESULT (r, row)) =
        PGSQL.getValue readInt (r, row, col)
    fun fromSQL_wordOption (col, '_SQL'.RESULT (r, row)) =
        PGSQL.getValue readWord (r, row, col)
    fun fromSQL_charOption (col, '_SQL'.RESULT (r, row)) =
        PGSQL.getValue readChar (r, row, col)
    fun fromSQL_boolOption (col, '_SQL'.RESULT (r, row)) =
        PGSQL.getValue readBool (r, row, col)
    fun fromSQL_stringOption (col, '_SQL'.RESULT (r, row)) =
        PGSQL.getValue readString (r, row, col)
    fun fromSQL_realOption (col, '_SQL'.RESULT (r, row)) =
        PGSQL.getValue readReal (r, row, col)

    end (* local *)

    local
      fun evalQuery query conn =
          let
            val conn = '_SQL'.CONN (conn, ())
            val rel as '_SQL'.REL ('_SQL'.RESULT (r,_), fetchFn) =
                eval ('_SQL'.DBI, query) conn
            val tuples =
                List.tabulate (PGSQL.PQntuples () r,
                               fn i => fetchFn ('_SQL'.RESULT (r, i)))
          in
            closeRel rel; tuples
          end
          handle Exec msg => raise Connect ("Exec: " ^ msg)

      fun getDatabaseSchema conn =
          let
            val query =
                fn '_SQL'.DB _ =>
                   '_SQL'.QUERY
                     ("SELECT pg_class.relname, pg_class.oid \
                      \FROM pg_namespace, pg_class \
                      \WHERE pg_namespace.oid = pg_class.relnamespace \
                      \AND pg_namespace.nspname = 'public' \
                      \AND pg_class.relkind = 'r' \
                      \ORDER BY pg_class.relname",
                      {relname="", oid=""},
                      fn r => {relname = fromSQL_string (0, r),
                               oid = fromSQL_string (1, r)})
            val relOIDList = evalQuery query conn
          in
            map (fn {relname, oid} =>
                    let
                      val query =
                          fn '_SQL'.DB _ =>
                             '_SQL'.QUERY
                               ("SELECT pg_attribute.attname, \
                                \pg_attribute.attnotnull,pg_type.typname \
                                \FROM pg_class, pg_attribute, pg_type \
                                \WHERE pg_class.oid = " ^ oid ^ " \
                                \AND pg_class.oid = pg_attribute.attrelid \
                                \AND pg_attribute.attnum > 0 \
                                \AND pg_attribute.atttypid = pg_type.oid \
                                \ORDER BY pg_attribute.attname",
                                {colname="", isnull=true, typename=""},
                                fn r =>
                                   {colname = fromSQL_string (0, r),
                                    isnull =
                                      not (valOf (fromSQL_boolOption (1, r)))
                                      handle Option => true,
                                    typename = fromSQL_string (2, r)})
                    in
                      (relname, evalQuery query conn)
                    end)
                relOIDList
          end

      fun translateType dbTypeName =
          case dbTypeName of
            "int4" => SOME "int"
          | "float4" => SOME "float"
          | "float8" => SOME "real"
          | "text" => SOME "string"
          | "varchar" => SOME "string"
          | "bool" => SOME "bool"
          | _ => NONE

      fun delete f (h::t) =
          if f h then (SOME h, t)
          else let val (x, t) = delete f t in (x, h::t) end
        | delete f nil = (NONE, nil)

      fun printColumn tableName colname =
          "column `" ^ colname ^ "' of table `" ^ tableName ^ "'"
      fun printMLType isnull typename =
          typename ^ (if isnull then " option" else "")
      fun printDBType isnull typename =
          typename ^ (if isnull then "" else " not null")

      fun unifyColumns (tableName, annotation, actual) =
          let
            val rest =
                foldl
                  (fn ({colname, isnull, typename}, actual) =>
                      case delete (fn {colname=name,...} => colname = name)
                                  actual of
                        (SOME {isnull=isnull2, typename=typename2, ...},
                         actual) =>
                        if isnull = isnull2
                           andalso SOME typename = translateType typename2
                        then actual
                        else raise Link ("type mismatch of "
                                         ^ printColumn tableName colname
                                         ^ ": expected `"
                                         ^ printMLType isnull typename
                                         ^ "', but actual `"
                                         ^ printDBType isnull2 typename2
                                         ^ "'")
                      | (NONE, actual) =>
                        raise Link (printColumn tableName colname
                                    ^ " is not found."))
                  actual
                  annotation
          in
            case rest of
              {colname,...}::t =>
              raise Link ("table `" ^ tableName ^ "' has\
                          \ column `" ^ colname ^ "' but not declared.")
            | nil => ()
          end

      fun unifySchema (annotation, actual) =
          List.app
            (fn (tableName, columns) =>
                case List.find (fn (name,_) => tableName = name) actual of
                  SOME (_, columns2) =>
                  unifyColumns (tableName, columns, columns2)
                | NONE =>
                  raise Link ("table `" ^ tableName ^ "' is not found."))
            annotation

    in

    fun link (conn, schema) =
        unifySchema (schema, getDatabaseSchema conn)

    end (* local *)

    fun connect ('_SQL'.SERVER (connInfo, schema, witness)) =
        let
          val conn = PGSQL.PQconnectdb () connInfo
        in
          if conn = NULL orelse PGSQL.PQstatus () conn <> PGSQL.CONNECTION_OK
          then raise Connect (if conn = NULL then "NULL"
                              else PGSQL.getErrorMessage conn)
          else
            let
              val e = (link (conn, schema); NONE) handle e => SOME e
            in
              case e of
                NONE => '_SQL'.CONN (conn, witness)
              | SOME e => (PGSQL.PQfinish () conn; raise e)
            end
        end

    fun Some ('_SQL'.VALUE (x, y)) = '_SQL'.VALUE (x, SOME y)
    val Null = '_SQL'.VALUE (("NULL", '_SQL'.DBI), NONE)

  end
end
