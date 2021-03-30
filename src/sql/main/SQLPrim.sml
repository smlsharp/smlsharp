(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @author SATO Hirohuki
 * @copyright (C) 2021 SML# Development Team.
 *)

structure SMLSharp_SQL_Prim =
struct

  structure Backend = SMLSharp_SQL_Backend
  structure Errors = SMLSharp_SQL_Errors
  structure TimeStamp = SMLSharp_SQL_TimeStamp
  structure Numeric = SMLSharp_SQL_Numeric
  structure Ty = SMLSharp_SQL_BackendTy
  structure Ast = SMLSharp_SQL_Query
  structure List = List
  structure Option = Option
  structure Bool = Bool

  datatype bool3 = True | False | Unknown
  type numeric = Numeric.num
  type decimal = numeric
  type timestamp = TimeStamp.timestamp

  type backend = SMLSharp_SQL_Backend.backend
  datatype 'a server = SERVER of Ty.schema * (unit -> 'a) * Backend.backend
  datatype 'a conn = CONN of (Backend.conn_impl * (unit -> 'a)) option ref
  type res = Backend.res_impl
  datatype 'a cursor = CURSOR of (res * (res -> 'a list) option) option ref
  exception Toy

  fun toyServer () = raise Toy

  datatype ('toy, 'w) exp =
      EXPty of 'w Ast.exp_ast * 'toy
  datatype ('toy, 'w) whr =
      WHRty of 'w Ast.whr_ast * 'toy
  datatype ('toy, 'w) from =
      FROMty of 'w Ast.from_ast * ({} -> 'toy)
  datatype ('toy, 'w) orderby =
      ORDERBYty of 'w Ast.orderby_ast * 'toy
  datatype ('toy, 'w) offset =
      OFFSETty of 'w Ast.limit_ast * 'toy
  datatype ('toy, 'w) limit =
      LIMITty of 'w Ast.limit_ast * 'toy
  datatype ('src, 'toy, 'w) select =
      SELECTty of 'w Ast.select_ast * ('src -> 'toy) * (res -> 'toy)
  datatype ('toy, 'w) query =
      QUERYty of 'w Ast.query_ast * ({} -> 'toy) * (res -> 'toy)
  datatype ('toy, 'w) command =
      COMMANDty of 'w Ast.command_ast * ({} -> 'toy) * (res -> 'toy)
  datatype ('toy, 'w) db =
      DBty of 'w Ast.db * (unit -> 'toy)

  fun closeRes (Backend.R r) =
      #closeRes r ()

  fun closeCommand (r as Backend.R res) =
      if #fetch res () then closeCommand r else #closeRes res ()

  fun dummyCursor _ = CURSOR (ref NONE)

  fun newCursor readFn res = CURSOR (ref (SOME (res, SOME readFn)))

  fun queryCommand (QUERYty (ast, toy, readFn)) =
      COMMANDty (Ast.QUERY_COMMAND ast, dummyCursor, newCursor readFn)

  fun sqlserver_string (desc, (schema, toy)) =
      SERVER (schema, toy, Backend.default desc)

  fun sqlserver_backend (backend, (schema, toy)) =
      SERVER (schema, toy, backend)

  local
    exception Link = Errors.Link

    fun typename ({nullable, ty}:Ty.schema_column) =
        let
          fun opt x = if nullable then x ^ " option" else x
        in
          case ty of
            Ty.INT => opt "int"
          | Ty.INTINF => opt "intInf"
          | Ty.WORD => opt "word"
          | Ty.CHAR => opt "char"
          | Ty.STRING => opt "string"
          | Ty.REAL => opt "real"
          | Ty.REAL32 => opt "real32"
          | Ty.BOOL => opt "bool"
          | Ty.TIMESTAMP => opt "timestamp"
          | Ty.NUMERIC => opt "numeric"
          | Ty.UNSUPPORTED x => "unsupported (" ^ x ^ ")"
        end

    fun createTableCommand conn (tableName, columns) =
        let
          val columns =
              map (fn (id, t as {ty, nullable}) =>
                      case #columnTypeName conn ty of
                        "" => raise Link ("cannot create table `"
                                          ^ tableName ^ "': type `"
                                          ^ typename t ^ "' is not supported")
                      | ty => (id, {ty = ty, nullable = nullable}))
                columns
          val ast = Ast.CREATE_TABLE (tableName, columns)
        in
          SMLFormat.prettyPrint nil (Ast.format_command_ast () ast)
        end

    fun equalName y (x, _) =
        CharVector.map Char.toLower x = CharVector.map Char.toLower y

    fun unifyColumns (tableName, expectColumns, actualColumns) =
        (
          app (fn (expectName, expectTy) =>
                  case List.find (equalName expectName) actualColumns of
                    NONE => raise Link ("column `" ^ expectName
                                        ^ "' of table `" ^ tableName
                                        ^ "' is not found.")
                  | SOME (actualName, actualTy) =>
                    if expectTy = actualTy then ()
                    else raise Link ("type mismatch of column `"
                                     ^ expectName ^ "' of table `"
                                     ^ tableName ^ "': expected `"
                                     ^ typename expectTy
                                     ^ "', but actual `"
                                     ^ typename actualTy ^ "'"))
              expectColumns;
          app (fn (actualName, actualTy) =>
                  case List.find (equalName actualName) expectColumns of
                    NONE =>
                    raise Link ("table `" ^ tableName ^ "' has column `"
                                ^ actualName ^ "' but not declared.")
                  | SOME _ => ())
              actualColumns
        )

    fun unifySchema (expectSchema, actualSchema) =
        List.filter
          (fn (tableName, expectColumns) =>
              case List.find (equalName tableName) actualSchema of
                SOME (_, actualColumns) =>
                (unifyColumns (tableName, expectColumns, actualColumns); false)
              | NONE => true)
          expectSchema
  in

  fun link (conn:Backend.conn_impl, schema) =
      case unifySchema (schema, (#getDatabaseSchema conn ())) of
        nil => ()
      | [(tableName, _)] =>
        raise Link ("table `" ^ tableName ^ "' is not found.")
      | tables =>
        raise Link ("tables "
                    ^ String.concatWith
                        ", "
                        (map (fn (s,_) => "`" ^ s ^ "'") tables)
                    ^ " are not found.")

  fun linkAndCreate (conn:Backend.conn_impl, schema) =
      case unifySchema (schema, (#getDatabaseSchema conn ())) of
        nil => ()
      | tables =>
        let
          val commands = map (createTableCommand conn) tables
        in
          app (fn cmd => closeCommand (#execQuery conn cmd)) commands
        end

  end (* local *)

  fun connect' link (SERVER (schema, toy, Backend.BACKEND backend)) =
      let
        val conn = #connect backend ()
        val e = (link (conn, schema); NONE) handle e => SOME e
      in
        case e of
          NONE => CONN (ref (SOME (conn, toy)))
        | SOME e => (#closeConn conn (); raise e)
      end

  fun connect x = connect' link x
  fun connectAndCreate x = connect' linkAndCreate x

  fun 'w sqleval cmd (CONN (ref NONE)) =
      raise Errors.Exec "closed connection"
    | sqleval cmd (CONN (ref (SOME (conn, toy)))) =
        let
          val db = Ast.DB : 'w Ast.db
          val COMMANDty (ast, toy, retFn) = cmd (DBty (db, toy))
          val s = SMLFormat.prettyPrint nil (Ast.format_command_ast () ast)
          val r = #execQuery conn s
        in
          retFn r
        end

  fun 'w toy queryFn arg =
      let
        val db = Ast.DB : 'w Ast.db
        val QUERYty (_, toyFn, _) = queryFn (DBty (db, fn () => arg))
      in
        toyFn {}
      end

  fun 'w commandToString commandFn =
      let
        val db = Ast.DB : 'w Ast.db
        val COMMANDty (ast, _, _) = commandFn (DBty (db, toyServer))
      in
        SMLFormat.prettyPrint nil (Ast.format_command_ast () ast)
      end

  fun 'w queryToString queryFn =
      let
        val db = Ast.DB : 'w Ast.db
        val QUERYty (ast, _, _) = queryFn (DBty (db, toyServer))
      in
        SMLFormat.prettyPrint nil (Ast.format_query_ast () ast)
      end

  fun expToString (EXPty (ast, _)) =
      SMLFormat.prettyPrint nil (Ast.format_exp_ast () ast)

  fun closeConn (CONN (ref NONE)) =
      raise Errors.Connect "closed connection"
    | closeConn (CONN (r as ref (SOME (conn, _)))) =
      (r := NONE; #closeConn conn ())

  fun closeCursor (CURSOR (ref NONE)) =
      raise Errors.Exec "closed cursor"
    | closeCursor (CURSOR (r as ref (SOME (Backend.R res, _)))) =
      (r := NONE; #closeRes res ())

  fun fetch (CURSOR (ref NONE)) =
      raise Errors.Exec "closed cursor"
    | fetch (CURSOR (ref (SOME (b, NONE)))) = NONE
    | fetch (CURSOR (r as ref (SOME (b as Backend.R res, SOME readFn)))) =
      if #fetch res ()
      then SOME (hd (readFn b))
      else (r := SOME (b, NONE); NONE)

  fun fetchAll c =
      let
        fun loop l = case fetch c of NONE => l | SOME x => loop (x::l)
        val result = loop nil
      in
        closeCursor c;
        rev result
      end

  fun nonnull (SOME x) = x
    | nonnull NONE = raise Errors.Format

  fun fromSQL_int (Backend.R r, i) = nonnull (#getInt r i)
  fun fromSQL_intInf (Backend.R r, i) = nonnull (#getIntInf r i)
  fun fromSQL_word (Backend.R r, i) = nonnull (#getWord r i)
  fun fromSQL_char (Backend.R r, i) = nonnull (#getChar r i)
  fun fromSQL_bool (Backend.R r, i) = nonnull (#getBool r i)
  fun fromSQL_string (Backend.R r, i) = nonnull (#getString r i)
  fun fromSQL_real (Backend.R r, i) = nonnull (#getReal r i)
  fun fromSQL_real32 (Backend.R r, i) = nonnull (#getReal32 r i)
  fun fromSQL_timestamp (Backend.R r, i) = nonnull (#getTimestamp r i)
  fun fromSQL_numeric (Backend.R r, i) = nonnull (#getNumeric r i)
  fun fromSQL_intOption (Backend.R r, i) = #getInt r i
  fun fromSQL_intInfOption (Backend.R r, i) = #getIntInf r i
  fun fromSQL_wordOption (Backend.R r, i) = #getWord r i
  fun fromSQL_charOption (Backend.R r, i) = #getChar r i
  fun fromSQL_boolOption (Backend.R r, i) = #getBool r i
  fun fromSQL_stringOption (Backend.R r, i) = #getString r i
  fun fromSQL_realOption (Backend.R r, i) = #getReal r i
  fun fromSQL_real32Option (Backend.R r, i) = #getReal32 r i
  fun fromSQL_timestampOption (Backend.R r, i) = #getTimestamp r i
  fun fromSQL_numericOption (Backend.R r, i) = #getNumeric r i

  fun ty_int _ = {ty = Ty.INT, nullable = false}
  fun ty_intInf _ = {ty = Ty.INTINF, nullable = false}
  fun ty_word _ = {ty = Ty.WORD, nullable = false}
  fun ty_char _ = {ty = Ty.CHAR, nullable = false}
  fun ty_bool _ = {ty = Ty.BOOL, nullable = false}
  fun ty_string _ = {ty = Ty.STRING, nullable = false}
  fun ty_real _ = {ty = Ty.REAL, nullable = false}
  fun ty_real32 _ = {ty = Ty.REAL32, nullable = false}
  fun ty_timestamp _ = {ty = Ty.TIMESTAMP, nullable = false}
  fun ty_numeric _ = {ty = Ty.NUMERIC, nullable = false}
  fun ty_intOption _ = {ty = Ty.INT, nullable = true}
  fun ty_intInfOption _ = {ty = Ty.INTINF, nullable = true}
  fun ty_wordOption _ = {ty = Ty.WORD, nullable = true}
  fun ty_charOption _ = {ty = Ty.CHAR, nullable = true}
  fun ty_boolOption _ = {ty = Ty.BOOL, nullable = true}
  fun ty_stringOption _ = {ty = Ty.STRING, nullable = true}
  fun ty_realOption _ = {ty = Ty.REAL, nullable = true}
  fun ty_real32Option _ = {ty = Ty.REAL32, nullable = true}
  fun ty_timestampOption _ = {ty = Ty.TIMESTAMP, nullable = true}
  fun ty_numericOption _ = {ty = Ty.NUMERIC, nullable = true}

  fun cmpOpt f (NONE, NONE) = EQUAL
    | cmpOpt f (NONE, SOME _) = GREATER
    | cmpOpt f (SOME _, NONE) = LESS
    | cmpOpt f (SOME x, SOME y) = f (x, y)

  val compare_int = Int.compare
  val compare_intInf = IntInf.compare
  val compare_word = Word.compare
  val compare_char = Char.compare
  fun compare_bool (false, false) = EQUAL
    | compare_bool (true, false) = GREATER
    | compare_bool (false, true) = LESS
    | compare_bool (true, true) = EQUAL
  val compare_string = String.compare
  val compare_real = Real.compare
  val compare_real32 = Real32.compare
  val compare_timestamp = SMLSharp_SQL_TimeStamp.compare
(*
  val compare_timestamp = TimeStamp.compare
*)
  val compare_numeric = Numeric.compare
  fun compare_intOption x = cmpOpt Int.compare x
  fun compare_intInfOption x = cmpOpt IntInf.compare x
  fun compare_wordOption x = cmpOpt Word.compare x
  fun compare_charOption x = cmpOpt Char.compare x
  fun compare_boolOption x = cmpOpt compare_bool x
  fun compare_stringOption x = cmpOpt String.compare x
  fun compare_realOption x = cmpOpt Real.compare x
  fun compare_real32Option x = cmpOpt Real32.compare x
  fun compare_timestampOption x = cmpOpt compare_timestamp x
  fun compare_numericOption x = cmpOpt compare_numeric x

  structure General2 =
  struct
    fun reverseOrder EQUAL = EQUAL
      | reverseOrder LESS = GREATER
      | reverseOrder GREATER = LESS

    fun comparePair (f, g) ((x1, y1), (x2, y2)) =
        case f (x1, x2) of
          EQUAL => g (y1, y2)
        | x => x
  end

  structure Bool3 =
  struct

    datatype bool3 = datatype bool3

    fun fromBool true = True
      | fromBool false = False

    fun isTrue True = true
      | isTrue _ = false

    fun is (x:bool3) y = if x = y then True else False

    fun and3 (False, _) = False
      | and3 (_, False) = False
      | and3 (Unknown, _) = Unknown
      | and3 (_, Unknown) = Unknown
      | and3 (True, True) = True

    fun or3 (True, _) = True
      | or3 (_, True) = True
      | or3 (Unknown, _) = Unknown
      | or3 (_, Unknown) = Unknown
      | or3 (False, False) = False

    fun not3 True = False
      | not3 False = True
      | not3 Unknown = Unknown

  end

  structure List2 =
  struct

    fun onlyOne [{1=x}] = x
      | onlyOne _ = raise Toy

    fun isNotEmpty nil = false
      | isNotEmpty (_::_) = true

    fun prod (left, right) =
        List.concat
          (map (fn l as (_, x) => map (fn r as (_, y) => ((l, r), (x, y)))
                                      right)
               left)

    fun join f (left, right) =
        map (fn (x, pair) => (x, f pair)) (prod (left, right))

    fun nub cmp nil = nil
      | nub cmp (h::t) =
        h :: nub cmp (List.filter (fn x => cmp (h, x) <> EQUAL) t)

    fun sortBy mapFn orderFn l =
        let
          fun merge cmp x nil = x
            | merge cmp nil x = x
            | merge cmp (l1 as h1::t1) (l2 as h2::t2) =
              case cmp (h1, h2) of
                LESS => h1 :: merge cmp t1 l2
              | GREATER => h2 :: merge cmp l1 t2
              | EQUAL => h1 :: h2 :: merge cmp t1 t2
          fun mergeLists cmp nil = nil
            | mergeLists cmp [x] = [x]
            | mergeLists cmp (x1::x2::t) = merge cmp x1 x2 :: mergeLists cmp t
          fun mergeSort cmp nil = nil
            | mergeSort cmp [x] = x
            | mergeSort cmp l = mergeSort cmp (mergeLists cmp l)
          fun sort cmp l =
              mergeSort cmp (map (fn x => [x]) l)
        in
          (map #2)
            ((sort (fn (x,y) => orderFn (#1 x, #1 y)))
               (map (fn x => (mapFn x, x)) l))
        end

    fun groupBy mapFn orderFn l =
        let
          fun quot f nil = nil
            | quot f (h::t) =
              let val (s, rest) = List.partition (fn x => f (h, x) = EQUAL) t
              in (h :: s) :: quot f rest
              end
        in
          (map (map #2))
            ((quot (fn ((x,_),(y,_)) => orderFn (x, y)))
               (map (fn x => (mapFn x, x)) l))
        end

  end

  fun toSQL_int x = Ast.INT x
  fun toSQL_intInf x = Ast.INTINF x
  fun toSQL_word x = Ast.WORD x
  fun toSQL_char x = Ast.CHAR x
  fun toSQL_bool x = Ast.BOOL x
  fun toSQL_string x = Ast.STRING x
  fun toSQL_real x = Ast.REAL x
  fun toSQL_real32 x = Ast.REAL32 x
  fun toSQL_timestamp x = Ast.TIMESTAMP x
  fun toSQL_numeric x = Ast.NUMERIC x
  fun toSQLopt ast (SOME x) = ast x
    | toSQLopt ast NONE = Ast.NULL
  fun toSQL_intOption x = toSQLopt Ast.INT x
  fun toSQL_intInfOption x = toSQLopt Ast.INTINF x
  fun toSQL_wordOption x = toSQLopt Ast.WORD x
  fun toSQL_charOption x = toSQLopt Ast.CHAR x
  fun toSQL_boolOption x = toSQLopt Ast.BOOL x
  fun toSQL_stringOption x = toSQLopt Ast.STRING x
  fun toSQL_realOption x = toSQLopt Ast.REAL x
  fun toSQL_real32Option x = toSQLopt Ast.REAL32 x
  fun toSQL_timestampOption x = toSQLopt Ast.TIMESTAMP x
  fun toSQL_numericOption x = toSQLopt Ast.NUMERIC x

  fun op1opt f (SOME x) = SOME (f x)
    | op1opt f NONE = NONE
  fun op2opt f (SOME x, SOME y) = SOME (f (x, y))
    | op2opt f _ = NONE
  fun cmpopt f (SOME x, SOME y) = f (x, y)
    | cmpopt f _ = Unknown

  fun add_intOption x = op2opt (op +) x
  fun add_intInfOption x = op2opt (op +) x
  fun add_wordOption x = op2opt (op +) x
  fun add_realOption x = op2opt (op +) x
  fun add_real32Option x = op2opt (op +) x
  fun add_numericOption x = op2opt Numeric.+ x

  fun sub_intOption x = op2opt (op -) x
  fun sub_intInfOption x = op2opt (op -) x
  fun sub_wordOption x = op2opt (op -) x
  fun sub_realOption x = op2opt (op -) x
  fun sub_real32Option x = op2opt (op -) x
  fun sub_numericOption x = op2opt Numeric.- x

  fun mul_intOption x = op2opt (op *) x
  fun mul_intInfOption x = op2opt (op *) x
  fun mul_wordOption x = op2opt (op *) x
  fun mul_realOption x = op2opt (op *) x
  fun mul_real32Option x = op2opt (op *) x
  fun mul_numericOption x = op2opt Numeric.* x

  fun div_intOption x = op2opt Int.quot x
  fun div_intInfOption x = op2opt IntInf.quot x
  fun div_wordOption x = op2opt Word.div x
  fun div_realOption x = op2opt Real./ x
  fun div_real32Option x = op2opt Real32./ x
  fun div_numericOption x = op2opt Numeric.quot x

  fun mod_real (x, y) = Real.realMod (x / y) * y
  fun mod_real32 (x, y) = Real32.realMod (x / y) * y
  fun mod_intOption x = op2opt Int.rem x
  fun mod_intInfOption x = op2opt IntInf.rem x
  fun mod_wordOption x = op2opt Word.mod x
  fun mod_realOption x = op2opt mod_real x
  fun mod_real32Option x = op2opt mod_real32 x
  fun mod_numericOption x = op2opt Numeric.rem x

  fun neg_intOption x = op1opt Int.~ x
  fun neg_intInfOption x = op1opt IntInf.~ x
  fun neg_wordOption x = op1opt Word.~ x
  fun neg_realOption x = op1opt Real.~ x
  fun neg_real32Option x = op1opt Real32.~ x
  fun neg_numericOption x = op1opt Numeric.~ x

  fun abs_word x = x : word
  fun abs_intOption x = op1opt Int.abs x
  fun abs_intInfOption x = op1opt IntInf.abs x
  fun abs_wordOption x = op1opt (fn x => x) x
  fun abs_realOption x = op1opt Real.abs x
  fun abs_real32Option x = op1opt Real32.abs x
  fun abs_numericOption x = op1opt Numeric.abs x

  fun lt cmp x = case cmp x of LESS => Bool3.True | _ => Bool3.False
  fun lt_int x = lt compare_int x
  fun lt_intInf x = lt compare_intInf x
  fun lt_word x = lt compare_word x
  fun lt_char x = lt compare_char x
  fun lt_bool x = lt compare_bool x
  fun lt_string x = lt compare_string x
  fun lt_real x = lt compare_real x
  fun lt_real32 x = lt compare_real32 x
  fun lt_timestamp x = lt compare_timestamp x
  fun lt_numeric x = lt compare_numeric x
  fun lt_intOption x = cmpopt (lt compare_int) x
  fun lt_intInfOption x = cmpopt (lt compare_intInf) x
  fun lt_wordOption x = cmpopt (lt compare_word) x
  fun lt_charOption x = cmpopt (lt compare_char) x
  fun lt_boolOption x = cmpopt (lt compare_bool) x
  fun lt_stringOption x = cmpopt (lt compare_string) x
  fun lt_realOption x = cmpopt (lt compare_real) x
  fun lt_real32Option x = cmpopt (lt compare_real32) x
  fun lt_timestampOption x = cmpopt (lt compare_timestamp) x
  fun lt_numericOption x = cmpopt (lt compare_numeric) x

  fun gt cmp x = case cmp x of GREATER => Bool3.True | _ => Bool3.False
  fun gt_int x = gt compare_int x
  fun gt_intInf x = gt compare_intInf x
  fun gt_word x = gt compare_word x
  fun gt_char x = gt compare_char x
  fun gt_bool x = gt compare_bool x
  fun gt_string x = gt compare_string x
  fun gt_real x = gt compare_real x
  fun gt_real32 x = gt compare_real32 x
  fun gt_timestamp x = gt compare_timestamp x
  fun gt_numeric x = gt compare_numeric x
  fun gt_intOption x = cmpopt (gt compare_int) x
  fun gt_intInfOption x = cmpopt (gt compare_intInf) x
  fun gt_wordOption x = cmpopt (gt compare_word) x
  fun gt_charOption x = cmpopt (gt compare_char) x
  fun gt_boolOption x = cmpopt (gt compare_bool) x
  fun gt_stringOption x = cmpopt (gt compare_string) x
  fun gt_realOption x = cmpopt (gt compare_real) x
  fun gt_real32Option x = cmpopt (gt compare_real32) x
  fun gt_timestampOption x = cmpopt (gt compare_timestamp) x
  fun gt_numericOption x = cmpopt (gt compare_numeric) x

  fun le cmp x = case cmp x of GREATER => Bool3.False | _ => Bool3.True
  fun le_int x = le compare_int x
  fun le_intInf x = le compare_intInf x
  fun le_word x = le compare_word x
  fun le_char x = le compare_char x
  fun le_bool x = le compare_bool x
  fun le_string x = le compare_string x
  fun le_real x = le compare_real x
  fun le_real32 x = le compare_real32 x
  fun le_timestamp x = le compare_timestamp x
  fun le_numeric x = le compare_numeric x
  fun le_intOption x = cmpopt (le compare_int) x
  fun le_intInfOption x = cmpopt (le compare_intInf) x
  fun le_wordOption x = cmpopt (le compare_word) x
  fun le_charOption x = cmpopt (le compare_char) x
  fun le_boolOption x = cmpopt (le compare_bool) x
  fun le_stringOption x = cmpopt (le compare_string) x
  fun le_realOption x = cmpopt (le compare_real) x
  fun le_real32Option x = cmpopt (le compare_real32) x
  fun le_timestampOption x = cmpopt (le compare_timestamp) x
  fun le_numericOption x = cmpopt (le compare_numeric) x

  fun ge cmp x = case cmp x of LESS => Bool3.False | _ => Bool3.True
  fun ge_int x = ge compare_int x
  fun ge_intInf x = ge compare_intInf x
  fun ge_word x = ge compare_word x
  fun ge_char x = ge compare_char x
  fun ge_bool x = ge compare_bool x
  fun ge_string x = ge compare_string x
  fun ge_real x = ge compare_real x
  fun ge_real32 x = ge compare_real32 x
  fun ge_timestamp x = ge compare_timestamp x
  fun ge_numeric x = ge compare_numeric x
  fun ge_intOption x = cmpopt (ge compare_int) x
  fun ge_intInfOption x = cmpopt (ge compare_intInf) x
  fun ge_wordOption x = cmpopt (ge compare_word) x
  fun ge_charOption x = cmpopt (ge compare_char) x
  fun ge_boolOption x = cmpopt (ge compare_bool) x
  fun ge_stringOption x = cmpopt (ge compare_string) x
  fun ge_realOption x = cmpopt (ge compare_real) x
  fun ge_real32Option x = cmpopt (ge compare_real32) x
  fun ge_timestampOption x = cmpopt (ge compare_timestamp) x
  fun ge_numericOption x = cmpopt (ge compare_numeric) x

  fun eq cmp x = case cmp x of EQUAL => Bool3.True | _ => Bool3.False
  fun eq_int x = eq compare_int x
  fun eq_intInf x = eq compare_intInf x
  fun eq_word x = eq compare_word x
  fun eq_char x = eq compare_char x
  fun eq_bool x = eq compare_bool x
  fun eq_string x = eq compare_string x
  fun eq_real x = eq compare_real x
  fun eq_real32 x = eq compare_real32 x
  fun eq_timestamp x = eq compare_timestamp x
  fun eq_numeric x = eq compare_numeric x
  fun eq_intOption x = cmpopt (eq compare_int) x
  fun eq_intInfOption x = cmpopt (eq compare_intInf) x
  fun eq_wordOption x = cmpopt (eq compare_word) x
  fun eq_charOption x = cmpopt (eq compare_char) x
  fun eq_boolOption x = cmpopt (eq compare_bool) x
  fun eq_stringOption x = cmpopt (eq compare_string) x
  fun eq_realOption x = cmpopt (eq compare_real) x
  fun eq_real32Option x = cmpopt (eq compare_real32) x
  fun eq_timestampOption x = cmpopt (eq compare_timestamp) x
  fun eq_numericOption x = cmpopt (eq compare_numeric) x

  fun neq cmp x = case cmp x of EQUAL => Bool3.False | _ => Bool3.True
  fun neq_int x = neq compare_int x
  fun neq_intInf x = neq compare_intInf x
  fun neq_word x = neq compare_word x
  fun neq_char x = neq compare_char x
  fun neq_bool x = neq compare_bool x
  fun neq_string x = neq compare_string x
  fun neq_real x = neq compare_real x
  fun neq_real32 x = neq compare_real32 x
  fun neq_timestamp x = neq compare_timestamp x
  fun neq_numeric x = neq compare_numeric x
  fun neq_intOption x = cmpopt (neq compare_int) x
  fun neq_intInfOption x = cmpopt (neq compare_intInf) x
  fun neq_wordOption x = cmpopt (neq compare_word) x
  fun neq_charOption x = cmpopt (neq compare_char) x
  fun neq_boolOption x = cmpopt (neq compare_bool) x
  fun neq_stringOption x = cmpopt (neq compare_string) x
  fun neq_realOption x = cmpopt (neq compare_real) x
  fun neq_real32Option x = cmpopt (neq compare_real32) x
  fun neq_timestampOption x = cmpopt (neq compare_timestamp) x
  fun neq_numericOption x = cmpopt (neq compare_numeric) x

  fun concat_stringOption x = op2opt String.^ x

  local
    fun match nil = false
      | match ((p,s)::t) =
        case (Substring.getc p, Substring.getc s) of
          (SOME (#"%", p2), SOME (c, s2)) => match ((p2,s)::(p,s2)::t)
        | (SOME (#"%", p2), NONE) => match ((p2,s)::t)
        | (SOME (#"_", p2), SOME (c, s2)) => match ((p2,s2)::t)
        | (SOME (#"_", _), NONE) => match t
        | (SOME (c, p2), SOME (c2, s2)) =>
          match (if c = c2 then (p2,s2)::t else t)
        | (SOME _, NONE) => match t
        | (NONE, SOME _) => match t
        | (NONE, NONE) => true
  in
  fun matchLike (x, y) = match [(Substring.full y, Substring.full x)]
  fun matchLike3 x = Bool3.fromBool (matchLike x)
  end
  fun like_string x = matchLike3 x
  fun like_stringOption x = cmpopt matchLike3 x

  fun nullif cmp (SOME x, SOME y) =
      (case cmp (x, y) of EQUAL => NONE | _ => SOME x)
    | nullif cmp (x, _) = x
  fun nullif_intOption x = nullif compare_int x
  fun nullif_intInfOption x = nullif compare_intInf x
  fun nullif_wordOption x = nullif compare_word x
  fun nullif_charOption x = nullif compare_char x
  fun nullif_boolOption x = nullif compare_bool x
  fun nullif_stringOption x = nullif compare_string x
  fun nullif_realOption x = nullif compare_real x
  fun nullif_real32Option x = nullif compare_real32 x
  fun nullif_timestampOption x = nullif compare_timestamp x
  fun nullif_numericOption x = nullif compare_numeric x

  fun coalesce (SOME x, y) = x
    | coalesce (NONE, y) = y
  fun coalesce' (SOME x, _) = SOME x
    | coalesce' (NONE, y) = y

  fun avg toNum nil = NONE
    | avg toNum l =
      SOME (Numeric.quot
              (foldl (fn (x,z) => Numeric.+ (toNum x, z)) (Numeric.fromInt 0) l,
               Numeric.fromInt (length l)))
  fun avgOpt toNum l = avg toNum (List.mapPartial (fn x => x) l)
  fun avg_int x = avg Numeric.fromInt x
  fun avg_intInf x = avg Numeric.fromLargeInt x
  fun avg_word x = avg (Numeric.fromLargeInt o Word.toLargeInt) x
  fun avg_real x = avg Numeric.fromLargeReal x
  fun avg_real32 x = avg (Numeric.fromLargeReal o Real32.toLarge) x
  fun avg_numeric x = avg (fn x => x) x
  fun avg_intOption x = avgOpt Numeric.fromInt x
  fun avg_intInfOption x = avgOpt Numeric.fromLargeInt x
  fun avg_wordOption x = avgOpt (Numeric.fromLargeInt o Word.toLargeInt) x
  fun avg_realOption x = avgOpt Numeric.fromLargeReal x
  fun avg_real32Option x = avgOpt (Numeric.fromLargeReal o Real32.toLarge) x
  fun avg_numericOption x = avgOpt (fn x => x) x

  fun sum add zero nil = NONE
    | sum add zero l = SOME (foldl add zero l)
  fun sumOpt add zero l = sum add zero (List.mapPartial (fn x => x) l)
  fun sum_int x = sum Int.+ 0 x
  fun sum_intInf x = sum IntInf.+ 0 x
  fun sum_word x = sum Word.+ 0w0 x
  fun sum_real x = sum Real.+ 0.0 x
  fun sum_real32 x = sum Real32.+ 0.0 x
  fun sum_numeric x = sum Numeric.+ (Numeric.fromInt 0) x
  fun sum_intOption x = sumOpt Int.+ 0 x
  fun sum_intInfOption x = sumOpt IntInf.+ 0 x
  fun sum_wordOption x = sumOpt Word.+ 0w0 x
  fun sum_realOption x = sumOpt Real.+ 0.0 x
  fun sum_real32Option x = sumOpt Real32.+ 0.0 x
  fun sum_numericOption x = sumOpt Numeric.+ (Numeric.fromInt 0) x

  fun max compare nil = NONE
    | max compare (h::t) =
      SOME (foldl (fn (x,z) => case compare (x,z) of GREATER => x | _ => z) h t)
  fun maxOpt compare l = max compare (List.mapPartial (fn x => x) l)
  fun max_int x = max compare_int x
  fun max_intInf x = max compare_intInf x
  fun max_word x = max compare_word x
  fun max_char x = max compare_char x
  fun max_bool x = max compare_bool x
  fun max_string x = max compare_string x
  fun max_real x = max compare_real x
  fun max_real32 x = max compare_real32 x
  fun max_timestamp x = max compare_timestamp x
  fun max_numeric x = max compare_numeric x
  fun max_intOption x = maxOpt compare_int x
  fun max_intInfOption x = maxOpt compare_intInf x
  fun max_wordOption x = maxOpt compare_word x
  fun max_charOption x = maxOpt compare_char x
  fun max_boolOption x = maxOpt compare_bool x
  fun max_stringOption x = maxOpt compare_string x
  fun max_realOption x = maxOpt compare_real x
  fun max_real32Option x = maxOpt compare_real32 x
  fun max_timestampOption x = maxOpt compare_timestamp x
  fun max_numericOption x = maxOpt compare_numeric x

  fun min compare nil = NONE
    | min compare (h::t) =
      SOME (foldl (fn (x, z) => case compare (x, z) of LESS => x | _ => z) h t)
  fun minOpt compare l = min compare (List.mapPartial (fn x => x) l)
  fun min_int x = min compare_int x
  fun min_intInf x = min compare_intInf x
  fun min_word x = min compare_word x
  fun min_char x = min compare_char x
  fun min_bool x = min compare_bool x
  fun min_string x = min compare_string x
  fun min_real x = min compare_real x
  fun min_real32 x = min compare_real32 x
  fun min_timestamp x = min compare_timestamp x
  fun min_numeric x = min compare_numeric x
  fun min_intOption x = minOpt compare_int x
  fun min_intInfOption x = minOpt compare_intInf x
  fun min_wordOption x = minOpt compare_word x
  fun min_charOption x = minOpt compare_char x
  fun min_boolOption x = minOpt compare_bool x
  fun min_stringOption x = minOpt compare_string x
  fun min_realOption x = minOpt compare_real x
  fun min_real32Option x = minOpt compare_real32 x
  fun min_timestampOption x = minOpt compare_timestamp x
  fun min_numericOption x = minOpt compare_numeric x

  fun count l = length l
  fun count_option l = length (List.mapPartial (fn x => x) l)

  fun NumOpt f (SOME x) = SOME (f x) | NumOpt f NONE = NONE
  fun Num_int x = SOME (Numeric.fromInt x)
  fun Num_intInf x = SOME (Numeric.fromLargeInt x)
  fun Num_word x = SOME (Numeric.fromLargeInt (Word.toLargeInt x))
  fun Num_real x = SOME (Numeric.fromLargeReal x)
  fun Num_real32 x = SOME (Numeric.fromLargeReal (Real32.toLarge x))
  fun Num_numeric x = SOME x
  fun Num_intOption x = NumOpt Numeric.fromInt x
  fun Num_intInfOption x = NumOpt Numeric.fromLargeInt x
  fun Num_wordOption x = NumOpt (Numeric.fromLargeInt o Word.toLargeInt) x
  fun Num_realOption x = NumOpt (Numeric.fromLargeReal) x
  fun Num_real32Option x = NumOpt (Numeric.fromLargeReal o Real32.toLarge) x
  fun Num_numericOption x = x

  val Some = SOME
  fun Part l = List.mapPartial (fn x => x) l

  structure Op =
  struct
    val coalesce = coalesce
    val coalesce' = coalesce'
    val Some = Some
    val Part = Part
  end

end
