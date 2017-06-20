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
  structure Errors = SMLSharp_SQL_Errors
  structure TimeStamp = SMLSharp_SQL_TimeStamp
  structure Decimal = SMLSharp_SQL_Decimal
  structure Float = SMLSharp_SQL_Float
  structure Ty = SMLSharp_SQL_BackendTy
  structure Ast = SMLSharp_SQL_Query
  structure List = List
  structure Option = Option
  structure Bool = Bool

  type timestamp = TimeStamp.timestamp
  type decimal = Decimal.decimal
  type float = Float.float

  type backend = SMLSharp_SQL_Backend.backend
  datatype 'a server = SERVER of Ty.schema * (unit -> 'a) * Backend.backend
  datatype 'a conn = CONN of Backend.conn_impl * (unit -> 'a)
  type res = Backend.res_impl
  datatype 'a cursor = CURSOR of (res * (res -> 'a)) option ref
  exception Toy

  fun toyServer () = raise Toy

  datatype ('toy, 'w) exp =
      EXPty of 'w Ast.exp_ast * 'toy
  datatype ('toy, 'w) whr =
      WHRty of 'w Ast.whr_ast * 'toy
  datatype ('toy, 'w) from =
      FROMty of 'w Ast.from_ast * (unit -> 'toy)
  datatype ('toy, 'w) orderby =
      ORDERBYty of 'w Ast.orderby_ast * 'toy
  datatype ('toy, 'w) offset =
      OFFSETty of 'w Ast.offset_ast * 'toy
  datatype ('toy, 'w) limit =
      LIMITty of 'w Ast.limit_ast * 'toy
  datatype ('src, 'toy, 'w) select =
      SELECTty of 'w Ast.select_ast * ('src -> 'toy) * (res -> 'toy)
  datatype ('toy, 'w) query =
      QUERYty of 'w Ast.query_ast * (unit -> 'toy) * (res -> 'toy)
  datatype ('toy, 'ret, 'w) command =
      COMMANDty of 'w Ast.command_ast * (unit -> 'toy) * (res -> 'ret)
  datatype ('toy, 'w) db =
      DBty of 'w Ast.db * (unit -> 'toy)

  fun closeRes (Backend.R r) =
      #closeRes r ()

  fun queryCommand (QUERYty (ast, toy, readFn)) =
      COMMANDty (Ast.QUERY_COMMAND ast, toy,
                 fn res => CURSOR (ref (SOME (res, readFn))))

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
          | Ty.DECIMAL => opt "decimal"
          | Ty.FLOAT => opt "float"
          | Ty.UNSUPPORTED x => "unsupported (" ^ x ^ ")"
        end

    fun unifyColumns (tableName, expectColumns, actualColumns) =
        (
          app (fn (expectName, expectTy) =>
                  case List.find (fn (x,_) => x = expectName) actualColumns of
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
                  case List.find (fn (x,_) => x = actualName) expectColumns of
                    NONE =>
                    raise Link ("table `" ^ tableName ^ "' has column `"
                                ^ actualName ^ "' but not declared.")
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

  fun connect (SERVER (schema, toy, Backend.BACKEND backend)) =
      let
        val conn = #connect backend ()
        val e = (link (conn, schema); NONE) handle e => SOME e
      in
        case e of
          NONE => CONN (conn, toy)
        | SOME e => (#closeConn conn (); raise e)
      end

  fun 'w sqleval cmd (CONN (conn, toy)) =
        let
          val db = Ast.DB : 'w Ast.db
          val COMMANDty (ast, toy, retFn) = cmd (DBty (db, toy))
          val s = SMLFormat.prettyPrint nil (Ast.format_command_ast ast)
          val r = #execQuery conn s
        in
          retFn r
        end

  fun 'w toy queryFn arg =
      let
        val db = Ast.DB : 'w Ast.db
        val QUERYty (_, toyFn, _) = queryFn (DBty (db, fn () => arg))
      in
        toyFn ()
      end

  fun 'w commandToString commandFn =
      let
        val db = Ast.DB : 'w Ast.db
        val COMMANDty (ast, _, _) = commandFn (DBty (db, toyServer))
      in
        SMLFormat.prettyPrint nil (Ast.format_command_ast ast)
      end

  fun closeConn (CONN (conn, _)) =
      #closeConn conn ()

  fun closeCursor (CURSOR (ref NONE)) =
      raise Errors.Exec "closed cursor"
    | closeCursor (CURSOR (r as ref (SOME (Backend.R res, _)))) =
      (r := NONE; #closeRes res ())

  fun fetch (CURSOR (ref NONE)) =
      raise Errors.Exec "closed cursor"
    | fetch (CURSOR (r as ref (SOME (b as Backend.R res, readFn)))) =
      if #fetch res () then SOME (hd (readFn b)) else NONE

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
  fun fromSQL_decimal (Backend.R r, i) = nonnull (#getDecimal r i)
  fun fromSQL_float (Backend.R r, i) = nonnull (#getFloat r i)
  fun fromSQL_intOption (Backend.R r, i) = #getInt r i
  fun fromSQL_intInfOption (Backend.R r, i) = #getIntInf r i
  fun fromSQL_wordOption (Backend.R r, i) = #getWord r i
  fun fromSQL_charOption (Backend.R r, i) = #getChar r i
  fun fromSQL_boolOption (Backend.R r, i) = #getBool r i
  fun fromSQL_stringOption (Backend.R r, i) = #getString r i
  fun fromSQL_realOption (Backend.R r, i) = #getReal r i
  fun fromSQL_real32Option (Backend.R r, i) = #getReal32 r i
  fun fromSQL_timestampOption (Backend.R r, i) = #getTimestamp r i
  fun fromSQL_decimalOption (Backend.R r, i) = #getDecimal r i
  fun fromSQL_floatOption (Backend.R r, i) = #getFloat r i

  fun ty_int _ = {ty = Ty.INT, nullable = false}
  fun ty_intInf _ = {ty = Ty.INTINF, nullable = false}
  fun ty_word _ = {ty = Ty.WORD, nullable = false}
  fun ty_char _ = {ty = Ty.CHAR, nullable = false}
  fun ty_bool _ = {ty = Ty.BOOL, nullable = false}
  fun ty_string _ = {ty = Ty.STRING, nullable = false}
  fun ty_real _ = {ty = Ty.REAL, nullable = false}
  fun ty_real32 _ = {ty = Ty.REAL32, nullable = false}
  fun ty_timestamp _ = {ty = Ty.TIMESTAMP, nullable = false}
  fun ty_decimal _ = {ty = Ty.DECIMAL, nullable = false}
  fun ty_float _ = {ty = Ty.FLOAT, nullable = false}
  fun ty_intOption _ = {ty = Ty.INT, nullable = true}
  fun ty_intInfOption _ = {ty = Ty.INTINF, nullable = true}
  fun ty_wordOption _ = {ty = Ty.WORD, nullable = true}
  fun ty_charOption _ = {ty = Ty.CHAR, nullable = true}
  fun ty_boolOption _ = {ty = Ty.BOOL, nullable = true}
  fun ty_stringOption _ = {ty = Ty.STRING, nullable = true}
  fun ty_realOption _ = {ty = Ty.REAL, nullable = true}
  fun ty_real32Option _ = {ty = Ty.REAL32, nullable = true}
  fun ty_timestampOption _ = {ty = Ty.TIMESTAMP, nullable = true}
  fun ty_decimalOption _ = {ty = Ty.DECIMAL, nullable = true}
  fun ty_floatOption _ = {ty = Ty.FLOAT, nullable = true}

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
  val compare_timestamp = TimeStamp.compare
  val compare_decimal = Decimal.compare
  val compare_float = Float.compare
  fun compare_intOption x = cmpOpt Int.compare x
  fun compare_intInfOption x = cmpOpt IntInf.compare x
  fun compare_wordOption x = cmpOpt Word.compare x
  fun compare_charOption x = cmpOpt Char.compare x
  fun compare_boolOption x = cmpOpt compare_bool x
  fun compare_stringOption x = cmpOpt String.compare x
  fun compare_realOption x = cmpOpt Real.compare x
  fun compare_real32Option x = cmpOpt Real32.compare x
  fun compare_timestampOption x = cmpOpt compare_timestamp x
  fun compare_decimalOption x = cmpOpt compare_decimal x
  fun compare_floatOption x = cmpOpt compare_float x

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

    type bool3 = bool option

    fun toBool3_bool (x : bool) = SOME x
    fun toBool3_bool3 (x : bool3) = x

    fun and3 (SOME false, _) = SOME false
      | and3 (_, SOME false) = SOME false
      | and3 (NONE, _) = NONE
      | and3 (_, NONE) = NONE
      | and3 (SOME true, SOME true) = SOME true

    fun or3 (SOME true, _) = SOME true
      | or3 (_, SOME true) = SOME true
      | or3 (NONE, _) = NONE
      | or3 (_, NONE) = NONE
      | or3 (SOME false, SOME false) = SOME false

    fun not3 (SOME true) = SOME false
      | not3 (SOME false) = SOME true
      | not3 NONE = NONE

    fun isTrue (SOME true) = true
      | isTrue _ = false

    fun isFalse (SOME false) = true
      | isFalse _ = false

    fun isUnknown NONE = true
      | isUnknown _ = false

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

  fun wrap_int x = Ast.INT x
  fun wrap_intInf x = Ast.INTINF x
  fun wrap_word x = Ast.WORD x
  fun wrap_char x = Ast.CHAR x
  fun wrap_bool x = Ast.BOOL x
  fun wrap_string x = Ast.STRING x
  fun wrap_real x = Ast.REAL x
  fun wrap_real32 x = Ast.REAL32 x
  fun unwrap_int x = case x of Ast.INT x => x | _ => raise Toy
  fun unwrap_intInf x = case x of Ast.INTINF x => x | _ => raise Toy
  fun unwrap_word x = case x of Ast.WORD x => x | _ => raise Toy
  fun unwrap_char x = case x of Ast.CHAR x => x | _ => raise Toy
  fun unwrap_bool x = case x of Ast.BOOL x => x | _ => raise Toy
  fun unwrap_string x = case x of Ast.STRING x => x | _ => raise Toy
  fun unwrap_real x = case x of Ast.REAL x => x | _ => raise Toy
  fun unwrap_real32 x = case x of Ast.REAL32 x => x | _ => raise Toy
  fun unwrap_intOption x = case x of Ast.INT x => SOME x | _ => raise Toy
  fun unwrap_intInfOption x = case x of Ast.INTINF x => SOME x | _ => raise Toy
  fun unwrap_wordOption x = case x of Ast.WORD x => SOME x | _ => raise Toy
  fun unwrap_charOption x = case x of Ast.CHAR x => SOME x | _ => raise Toy
  fun unwrap_boolOption x = case x of Ast.BOOL x => SOME x | _ => raise Toy
  fun unwrap_stringOption x = case x of Ast.STRING x => SOME x | _ => raise Toy
  fun unwrap_realOption x = case x of Ast.REAL x => SOME x | _ => raise Toy
  fun unwrap_real32Option x = case x of Ast.REAL32 x => SOME x | _ => raise Toy

  fun toSQL_int x = EXPty (Ast.CONST (Ast.INT x), fn _ => x)
  fun toSQL_intInf x = EXPty (Ast.CONST (Ast.INTINF x), fn _ => x)
  fun toSQL_word x = EXPty (Ast.CONST (Ast.WORD x), fn _ => x)
  fun toSQL_char x = EXPty (Ast.CONST (Ast.CHAR x), fn _ => x)
  fun toSQL_bool x = EXPty (Ast.CONST (Ast.BOOL x), fn _ => x)
  fun toSQL_string x = EXPty (Ast.CONST (Ast.STRING x), fn _ => x)
  fun toSQL_real x = EXPty (Ast.CONST (Ast.REAL x), fn _ => x)
  fun toSQL_real32 x = EXPty (Ast.CONST (Ast.REAL32 x), fn _ => x)
  fun toSQL_timestamp x = EXPty (Ast.CONST (Ast.TIMESTAMP x), fn _ => x)
  fun toSQL_decimal x = EXPty (Ast.CONST (Ast.DECIMAL x), fn _ => x)
  fun toSQL_float x = EXPty (Ast.CONST (Ast.FLOAT x), fn _ => x)
  fun toSQLopt ast (SOME x) = EXPty (Ast.CONST (ast x), fn _ => SOME x)
    | toSQLopt ast NONE = EXPty (Ast.LITERAL "NULL", fn _ => NONE)
  fun toSQL_intOption x = toSQLopt Ast.INT x
  fun toSQL_intInfOption x = toSQLopt Ast.INTINF x
  fun toSQL_wordOption x = toSQLopt Ast.WORD x
  fun toSQL_charOption x = toSQLopt Ast.CHAR x
  fun toSQL_boolOption x = toSQLopt Ast.BOOL x
  fun toSQL_stringOption x = toSQLopt Ast.STRING x
  fun toSQL_realOption x = toSQLopt Ast.REAL x
  fun toSQL_real32Option x = toSQLopt Ast.REAL32 x
  fun toSQL_timestampOption x = toSQLopt Ast.TIMESTAMP x
  fun toSQL_decimalOption x = toSQLopt Ast.DECIMAL x
  fun toSQL_floatOption x = toSQLopt Ast.FLOAT x

  fun op1 (ast, oper, f) (EXPty x) =
      EXPty (ast (oper, #1 x), fn c => f (#2 x c))
  fun op1opt (ast, oper, f) x =
      op1 (ast, oper, fn SOME x => SOME (f x) | NONE => NONE) x

  fun op2 (ast, oper, f) (EXPty x, EXPty y) =
      EXPty (ast (#1 x, oper, #1 y), fn c => f (#2 x c, #2 y c))
  fun op2opt (ast, oper, f) x =
      op2 (ast, oper, fn (SOME x, SOME y) => SOME (f (x, y)) | _ => NONE) x

  type ('a,'w) op1 = ('a,'w) exp -> ('a,'w) exp
  type ('a,'w) op2 = ('a,'w) exp * ('a,'w) exp -> ('a,'w) exp
  type ('a,'b,'w) cmpop =
       ('a -> 'b, 'w) exp * ('a -> 'b, 'w) exp -> ('a -> bool option, 'w) exp

  fun add x = op2 (Ast.ADDOP, "+", op +) x
  fun addOpt x = op2opt (Ast.ADDOP, "+", op +) x
  val add_int = add
  val add_intInf = add
  val add_word = add
  val add_real = add
  val add_real32 = add
  val add_intOption = addOpt
  val add_intInfOption = addOpt
  val add_wordOption = addOpt
  val add_realOption = addOpt
  val add_real32Option = addOpt

  fun sub x = op2 (Ast.ADDOP, "-", op -) x
  fun subOpt x = op2opt (Ast.ADDOP, "-", op -) x
  val sub_int = sub
  val sub_intInf = sub
  val sub_word = sub
  val sub_real = sub
  val sub_real32 = sub
  val sub_intOption = subOpt
  val sub_intInfOption = subOpt
  val sub_wordOption = subOpt
  val sub_realOption = subOpt
  val sub_real32Option = subOpt

  fun mul x = op2 (Ast.MULOP, "*", op *) x
  fun mulOpt x = op2opt (Ast.MULOP, "*", op *) x
  val mul_int = mul
  val mul_intInf = mul
  val mul_word = mul
  val mul_real = mul
  val mul_real32 = mul
  val mul_intOption = mulOpt
  val mul_intInfOption = mulOpt
  val mul_wordOption = mulOpt
  val mul_realOption = mulOpt
  val mul_real32Option = mulOpt

  fun divide x = op2 (Ast.MULOP, "/", op div) x
  fun divideOpt x = op2opt (Ast.MULOP, "/", op div) x
  fun divideR x = op2 (Ast.MULOP, "/", op /) x
  fun divideROpt x = op2opt (Ast.MULOP, "/", op /) x
  val div_int = divide
  val div_intInf = divide
  val div_word = divide
  val div_real = divideR
  val div_real32 = divideR
  val div_intOption = divideOpt
  val div_intInfOption = divideOpt
  val div_wordOption = divideOpt
  val div_realOption = divideROpt
  val div_real32Option = divideROpt

  fun realMod (x, y) = Real.realMod (x / y) * y
  fun real32Mod (x, y) = Real32.realMod (x / y) * y

  fun modulo x = op2 (Ast.MULOP, "%", op mod) x
  fun moduloOpt x = op2opt (Ast.MULOP, "%", op mod) x
  val mod_int = modulo
  val mod_intInf = modulo
  val mod_word = modulo
  fun mod_real x = op2 (Ast.MULOP, "%", realMod) x
  fun mod_real32 x = op2 (Ast.MULOP, "%", real32Mod) x
  val mod_intOption = moduloOpt
  val mod_intInfOption = moduloOpt
  val mod_wordOption = moduloOpt
  fun mod_realOption x = op2opt (Ast.MULOP, "%", realMod) x
  fun mod_real32Option x = op2opt (Ast.MULOP, "%", real32Mod) x

  fun neg x = op1 (Ast.UNARYOP, "-", op ~) x
  fun negOpt x = op1opt (Ast.UNARYOP, "-", op ~) x
  val neg_int = neg
  val neg_intInf = neg
  val neg_word = neg
  val neg_real = neg
  val neg_real32 = neg
  val neg_intOption = negOpt
  val neg_intInfOption = negOpt
  val neg_wordOption = negOpt
  val neg_realOption = negOpt
  val neg_real32Option = negOpt

  fun absolute (EXPty x) =
      EXPty (Ast.FUNCALL ("ABS", [#1 x]), fn c => abs (#2 x c))
  fun absoluteOpt (EXPty x) =
      EXPty (Ast.FUNCALL ("ABS", [#1 x]), fn c => Option.map abs (#2 x c))
  val abs_int = absolute
  val abs_intInf = absolute
  fun abs_word (EXPty x) = EXPty (Ast.FUNCALL ("ABS", [#1 x]), #2 x)
  val abs_real = absolute
  val abs_real32 = absolute
  val abs_intOption = absoluteOpt
  val abs_intInfOption = absoluteOpt
  fun abs_wordOption (EXPty x) = EXPty (Ast.FUNCALL ("ABS", [#1 x]), #2 x)
  val abs_realOption = absoluteOpt
  val abs_real32Option = absoluteOpt

  fun ltCmp cmp x = case cmp x of LESS => true | _ => false
  fun lt cmp x = op2 (Ast.CMPOP, "<", SOME o ltCmp cmp) x
  fun ltOpt cmp x = op2opt (Ast.CMPOP, "<", ltCmp cmp) x
  fun lt_int x = lt compare_int x
  fun lt_intInf x = lt compare_intInf x
  fun lt_word x = lt compare_word x
  fun lt_char x = lt compare_char x
  fun lt_bool x = lt compare_bool x
  fun lt_string x = lt compare_string x
  fun lt_real x = lt compare_real x
  fun lt_real32 x = lt compare_real32 x
  fun lt_timestamp x = lt compare_timestamp x
  fun lt_decimal x = lt compare_decimal x
  fun lt_float x = lt compare_float x
  fun lt_intOption x = ltOpt compare_int x
  fun lt_intInfOption x = ltOpt compare_intInf x
  fun lt_wordOption x = ltOpt compare_word x
  fun lt_charOption x = ltOpt compare_char x
  fun lt_boolOption x = ltOpt compare_bool x
  fun lt_stringOption x = ltOpt compare_string x
  fun lt_realOption x = ltOpt compare_real x
  fun lt_real32Option x = ltOpt compare_real32 x
  fun lt_timestampOption x = ltOpt compare_timestamp x
  fun lt_decimalOption x = ltOpt compare_decimal x
  fun lt_floatOption x = ltOpt compare_float x

  fun gtCmp cmp x = case cmp x of GREATER => true | _ => false
  fun gt cmp x = op2 (Ast.CMPOP, ">", SOME o gtCmp cmp) x
  fun gtOpt cmp x = op2opt (Ast.CMPOP, ">", gtCmp cmp) x
  fun gt_int x = gt compare_int x
  fun gt_intInf x = gt compare_intInf x
  fun gt_word x = gt compare_word x
  fun gt_char x = gt compare_char x
  fun gt_bool x = gt compare_bool x
  fun gt_string x = gt compare_string x
  fun gt_real x = gt compare_real x
  fun gt_real32 x = gt compare_real32 x
  fun gt_timestamp x = gt compare_timestamp x
  fun gt_decimal x = gt compare_decimal x
  fun gt_float x = gt compare_float x
  fun gt_intOption x = gtOpt compare_int x
  fun gt_intInfOption x = gtOpt compare_intInf x
  fun gt_wordOption x = gtOpt compare_word x
  fun gt_charOption x = gtOpt compare_char x
  fun gt_boolOption x = gtOpt compare_bool x
  fun gt_stringOption x = gtOpt compare_string x
  fun gt_realOption x = gtOpt compare_real x
  fun gt_real32Option x = gtOpt compare_real32 x
  fun gt_timestampOption x = gtOpt compare_timestamp x
  fun gt_decimalOption x = gtOpt compare_decimal x
  fun gt_floatOption x = gtOpt compare_float x

  fun leCmp cmp x = case cmp x of GREATER => false | _ => true
  fun le cmp x = op2 (Ast.CMPOP, "<=", SOME o leCmp cmp) x
  fun leOpt cmp x = op2opt (Ast.CMPOP, "<=", leCmp cmp) x
  fun le_int x = le compare_int x
  fun le_intInf x = le compare_intInf x
  fun le_word x = le compare_word x
  fun le_char x = le compare_char x
  fun le_bool x = le compare_bool x
  fun le_string x = le compare_string x
  fun le_real x = le compare_real x
  fun le_real32 x = le compare_real32 x
  fun le_timestamp x = le compare_timestamp x
  fun le_decimal x = le compare_decimal x
  fun le_float x = le compare_float x
  fun le_intOption x = leOpt compare_int x
  fun le_intInfOption x = leOpt compare_intInf x
  fun le_wordOption x = leOpt compare_word x
  fun le_charOption x = leOpt compare_char x
  fun le_boolOption x = leOpt compare_bool x
  fun le_stringOption x = leOpt compare_string x
  fun le_realOption x = leOpt compare_real x
  fun le_real32Option x = leOpt compare_real32 x
  fun le_timestampOption x = leOpt compare_timestamp x
  fun le_decimalOption x = leOpt compare_decimal x
  fun le_floatOption x = leOpt compare_float x

  fun geCmp cmp x = case cmp x of LESS => false | _ => true
  fun ge cmp x = op2 (Ast.CMPOP, ">=", SOME o geCmp cmp) x
  fun geOpt cmp x = op2opt (Ast.CMPOP, ">=", geCmp cmp) x
  fun ge_int x = ge compare_int x
  fun ge_intInf x = ge compare_intInf x
  fun ge_word x = ge compare_word x
  fun ge_char x = ge compare_char x
  fun ge_bool x = ge compare_bool x
  fun ge_string x = ge compare_string x
  fun ge_real x = ge compare_real x
  fun ge_real32 x = ge compare_real32 x
  fun ge_timestamp x = ge compare_timestamp x
  fun ge_decimal x = ge compare_decimal x
  fun ge_float x = ge compare_float x
  fun ge_intOption x = geOpt compare_int x
  fun ge_intInfOption x = geOpt compare_intInf x
  fun ge_wordOption x = geOpt compare_word x
  fun ge_charOption x = geOpt compare_char x
  fun ge_boolOption x = geOpt compare_bool x
  fun ge_stringOption x = geOpt compare_string x
  fun ge_realOption x = geOpt compare_real x
  fun ge_real32Option x = geOpt compare_real32 x
  fun ge_timestampOption x = geOpt compare_timestamp x
  fun ge_decimalOption x = geOpt compare_decimal x
  fun ge_floatOption x = geOpt compare_float x

  fun eqCmp cmp x = case cmp x of EQUAL => true | _ => false
  fun eq cmp x = op2 (Ast.CMPOP, "=", SOME o eqCmp cmp) x
  fun eqOpt cmp x = op2opt (Ast.CMPOP, "=", eqCmp cmp) x
  fun eq_int x = eq compare_int x
  fun eq_intInf x = eq compare_intInf x
  fun eq_word x = eq compare_word x
  fun eq_char x = eq compare_char x
  fun eq_bool x = eq compare_bool x
  fun eq_string x = eq compare_string x
  fun eq_real x = eq compare_real x
  fun eq_real32 x = eq compare_real32 x
  fun eq_timestamp x = eq compare_timestamp x
  fun eq_decimal x = eq compare_decimal x
  fun eq_float x = eq compare_float x
  fun eq_intOption x = eqOpt compare_int x
  fun eq_intInfOption x = eqOpt compare_intInf x
  fun eq_wordOption x = eqOpt compare_word x
  fun eq_charOption x = eqOpt compare_char x
  fun eq_boolOption x = eqOpt compare_bool x
  fun eq_stringOption x = eqOpt compare_string x
  fun eq_realOption x = eqOpt compare_real x
  fun eq_real32Option x = eqOpt compare_real32 x
  fun eq_timestampOption x = eqOpt compare_timestamp x
  fun eq_decimalOption x = eqOpt compare_decimal x
  fun eq_floatOption x = eqOpt compare_float x

  fun neqCmp cmp x = case cmp x of EQUAL => false | _ => true
  fun neq cmp x = op2 (Ast.CMPOP, "<>", SOME o neqCmp cmp) x
  fun neqOpt cmp x = op2opt (Ast.CMPOP, "<>", neqCmp cmp) x
  fun neq_int x = neq compare_int x
  fun neq_intInf x = neq compare_intInf x
  fun neq_word x = neq compare_word x
  fun neq_char x = neq compare_char x
  fun neq_bool x = neq compare_bool x
  fun neq_string x = neq compare_string x
  fun neq_real x = neq compare_real x
  fun neq_real32 x = neq compare_real32 x
  fun neq_timestamp x = neq compare_timestamp x
  fun neq_decimal x = neq compare_decimal x
  fun neq_float x = neq compare_float x
  fun neq_intOption x = neqOpt compare_int x
  fun neq_intInfOption x = neqOpt compare_intInf x
  fun neq_wordOption x = neqOpt compare_word x
  fun neq_charOption x = neqOpt compare_char x
  fun neq_boolOption x = neqOpt compare_bool x
  fun neq_stringOption x = neqOpt compare_string x
  fun neq_realOption x = neqOpt compare_real x
  fun neq_real32Option x = neqOpt compare_real32 x
  fun neq_timestampOption x = neqOpt compare_timestamp x
  fun neq_decimalOption x = neqOpt compare_decimal x
  fun neq_floatOption x = neqOpt compare_float x

  fun concat_string (EXPty x, EXPty y) =
      EXPty (Ast.FUNCALL ("CONCAT", [#1 x, #1 y]), fn c => #2 x c ^ #2 y c)
  fun concat_stringOption (EXPty x, EXPty y) =
      EXPty (Ast.FUNCALL ("CONCAT", [#1 x, #1 y]),
             fn c => case (#2 x c, #2 y c) of
                       (SOME x, SOME y) => SOME (x ^ y) | _ => NONE)

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
  end

  fun like_string x = op2 (Ast.CMPOP, "LIKE", SOME o matchLike) x
  fun like_stringOption x = op2opt (Ast.CMPOP, "LIKE", matchLike) x

  fun isnull (EXPty x, EXPty y) =
      EXPty (Ast.FUNCALL ("ISNULL", [#1 x, #1 y]),
             fn c => getOpt (#2 x c, #2 y c))

  type ('a,'b,'w) avgop = ('a -> 'b list, 'w) exp -> ('a -> real option, 'w) exp

  fun avgReal f nil = NONE
    | avgReal f l =
      let val l' = List.mapPartial f l
      in SOME (foldl (op +) 0.0 l' / real (length l'))
      end

  fun avg toReal (EXPty x) =
      EXPty (Ast.FUNCALL ("AVG", [#1 x]), fn c => avgReal toReal (#2 x c))
  fun avg_int x = avg (SOME o Real.fromInt) x
  fun avg_intInf x = avg (SOME o Real.fromLargeInt) x
  fun avg_word x = avg (SOME o Real.fromLargeInt o Word.toLargeInt) x
  fun avg_real x = avg SOME x
  fun avg_real32 x = avg (SOME o Real32.toLarge) x
  fun avg_intOption x = avg (Option.map Real.fromInt) x
  fun avg_intInfOption x = avg (Option.map Real.fromLargeInt) x
  fun avg_wordOption x = avg (Option.map (Real.fromLargeInt o Word.toLargeInt)) x
  fun avg_realOption x = avg (fn x => x) x
  fun avg_real32Option x = avg (Option.map Real32.toLarge) x

  structure Op =
  struct
    fun Some (EXPty (ast, toy)) = EXPty (ast, fn c => SOME (toy c))
    fun isnull (EXPty x, EXPty y) =
        EXPty (Ast.FUNCALL ("ISNULL", [#1 x, #1 y]),
               fn c => getOpt (#2 x c, #2 y c))
  end

end
