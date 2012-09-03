(*
 * minimum (or dummy) definitions for system-required functions which
 * defined as DUMMY in BuiltinContext.
 * Since the compiler assumes that these functions are provided in specific
 * types and doesn't check types them, it is recommended to write type
 * annotations explicitly to every function declaration.
 *)
(*
./smlsharp_build --prelude=./sql_minimum.sml
*)

(* for debug use *)
val print = _import "print" : string -> unit

local
  fun term s = SMLSharp.SMLFormat.Term (SMLSharp.PrimString.size s, s)
in

structure SMLSharp = struct open SMLSharp
  fun printFormat (exp:SMLSharp.SMLFormat.expression) : unit =
      let
        open SMLSharp.SMLFormat
        fun prList [] = ()
          | prList (e :: es) =
            (pr e; prList es)
        and pr exp =
            case exp of
              Term (int, string) => print string
            | Newline => print "\n"
            | Guard (assocOpt, exps) => prList exps
            | Indicator {space, newline} => if space then print " " else ()
            | StartOfIndent int => ()
            | EndOfIndent => ()
      in
        pr exp
      end
  fun printFormatOfValBinding (name:string,
                               valExp:SMLSharp.SMLFormat.expression,
                               tyExp:SMLSharp.SMLFormat.expression) : unit =
    let
      open SMLSharp.SMLFormat
      val space = Indicator {space = true, newline = NONE}
    in
      printFormat
        (Guard (NONE,
           [Term (3, "val"), space,
            Term (SMLSharp.PrimString.size name, name),
            space, Term (1, "="), space,
            valExp, space, Term (2, ": "), tyExp]))
    end
end

structure SMLSharp = struct open SMLSharp
  structure SMLFormat = struct open SMLFormat
    fun '_format_assocDirection' (arg:assocDirection) : expression =
        term "<assocDirection>"
    fun '_format_priority' (arg:priority) : expression =
        term "<priority>"
    fun '_format_expression' (arg:expression) : expression =
        term "<expression>"
  end
end

fun '_format_bool' (arg:bool) : SMLSharp.SMLFormat.expression =
    term (if arg then "true" else "false")
fun '_format_int' (arg:int) : SMLSharp.SMLFormat.expression =
    term "<int>"
fun '_format_word' (arg:word) : SMLSharp.SMLFormat.expression =
    term "<word>"
fun '_format_char' (arg:char) : SMLSharp.SMLFormat.expression =
    term (SMLSharp.PrimString.vector (1, arg))
fun '_format_string' (arg:string) : SMLSharp.SMLFormat.expression =
    term arg
fun '_format_real' (arg:real) : SMLSharp.SMLFormat.expression =
    term "<real>"

structure Real32 = struct open Real32
  fun '_format_real' (arg:Real32.real) : SMLSharp.SMLFormat.expression =
      term "<float>"
end

fun '_format_ref' (f:'a -> SMLSharp.SMLFormat.expression)
                  (arg:'a ref)
                  : SMLSharp.SMLFormat.expression =
    term "<ref>"
fun '_format_list' (f:'a -> SMLSharp.SMLFormat.expression)
                   (arg:'a list)
                   : SMLSharp.SMLFormat.expression =
    let
      val space = SMLSharp.SMLFormat.Indicator {space = true, newline = NONE}
      fun join l nil = l
        | join l [x] = f x :: l
        | join l (h::t) = f h :: term "," :: space :: join l t
    in
      SMLSharp.SMLFormat.Guard (NONE, term "[" :: join [term "]"] arg)
    end
fun '_format_array' (f:'a -> SMLSharp.SMLFormat.expression)
                    (arg:'a array)
                    : SMLSharp.SMLFormat.expression =
    term "<array>"

structure IntInf = struct open IntInf
  fun '_format_int' (arg:int) : SMLSharp.SMLFormat.expression =
      term "<intinf>"
end
structure Word8 = struct open Word8
  fun '_format_word' (arg:word) : SMLSharp.SMLFormat.expression =
      term "<word8>"
end

fun '_format_ptr' (f:'a -> SMLSharp.SMLFormat.expression)
                  (arg:'a ptr)
                  : SMLSharp.SMLFormat.expression =
    term "<ptr>"
fun '_format_option' (f:'a -> SMLSharp.SMLFormat.expression)
                     (arg:'a option)
                     : SMLSharp.SMLFormat.expression =
    let
      open SMLSharp.SMLFormat
      val space = Indicator {space = true, newline = NONE}
    in
      case arg of
        NONE => term "NONE"
      | SOME x => Guard (SOME {strength = 10, cut = false, direction = Left},
                         [term "SOME", space, f x])
    end

fun '_format_sqlserver' (f:'a -> SMLSharp.SMLFormat.expression)
                        (arg:'a sqlserver)
                        : SMLSharp.SMLFormat.expression =
    term "<sqlserver>"
fun '_format_sqlconn' (f:'a -> SMLSharp.SMLFormat.expression)
                      (arg:'a sqlconn)
                      : SMLSharp.SMLFormat.expression =
    term "<sqlconn>"
fun '_format_sqltable' (f:'a -> SMLSharp.SMLFormat.expression)
                       (g:'b -> SMLSharp.SMLFormat.expression)
                       (arg:('a,'b) sqltable)
                       : SMLSharp.SMLFormat.expression =
    term "<sqltable>"
fun '_format_sqlquery' (f:'a -> SMLSharp.SMLFormat.expression)
                       (g:'b -> SMLSharp.SMLFormat.expression)
                       (arg:('a,'b) sqlquery)
                       : SMLSharp.SMLFormat.expression =
    term "<sqlquery>"
fun '_format_sqlcommand' (f:'a -> SMLSharp.SMLFormat.expression)
                         (g:'b -> SMLSharp.SMLFormat.expression)
                         (arg:('a,'b) sqlcommand) 
                         : SMLSharp.SMLFormat.expression =
    term "<sqlcommand>"
fun '_format_sqlrel' (f:'a -> SMLSharp.SMLFormat.expression)
                     (arg:'a sqlrel)
                     : SMLSharp.SMLFormat.expression =
    term "<sqlrel>"
fun '_format_sqlvalue' (f:'a -> SMLSharp.SMLFormat.expression)
                       (g:'b -> SMLSharp.SMLFormat.expression)
                       (arg:('a,'b) sqlvalue)
                       : SMLSharp.SMLFormat.expression =
    term "<sqlvalue>"
fun '_format_sqlQueryResult' (f:'a -> SMLSharp.SMLFormat.expression)
                             (arg:'a sqlQueryResult)
                             : SMLSharp.SMLFormat.expression =
    term "<sqlQueryResult>"

fun '_format_exn' (arg:exn) : SMLSharp.SMLFormat.expression =
    term "<exn>"

structure SMLSharp = struct open SMLSharp
  fun '_format_exntag' (arg:exntag) : SMLSharp.SMLFormat.expression =
      term "<exnarg>"
end
fun '_format_exnRef' (arg:(exn -> SMLSharp.SMLFormat.expression) ref)
                     : SMLSharp.SMLFormat.expression =
    term "<exnRef>"

fun '_getSQLValue_int' (arg:int sqlQueryResult) : int =
    0
fun '_getSQLValue_word' (arg:word sqlQueryResult) : word =
    0w0
fun '_getSQLValue_char' (arg:char sqlQueryResult) : char =
    #"c"
fun '_getSQLValue_bool' (arg:bool sqlQueryResult) : bool =
    true
fun '_getSQLValue_string' (arg:string sqlQueryResult) : string =
    "s"
fun '_getSQLValue_real' (arg:real sqlQueryResult) : real =
    0.0
fun '_getSQLValue_intOption' (arg:int option sqlQueryResult) : int option =
    NONE
fun '_getSQLValue_wordOption' (arg:word option sqlQueryResult) : word option =
    NONE
fun '_getSQLValue_charOption' (arg:char option sqlQueryResult) : char option =
    NONE
fun '_getSQLValue_boolOption' (arg:bool option sqlQueryResult) : bool option =
    NONE
fun '_getSQLValue_stringOption' (arg:string option sqlQueryResult)
                                : string option =
    NONE
fun '_getSQLValue_realOption' (arg:real option sqlQueryResult) : real option =
    NONE
fun '_toSQLString_int' (arg:int) : string =
    "0"
fun '_toSQLString_word' (arg:word) : string =
    "0"
fun '_toSQLString_char' (arg:char) : string =
    "'c'"
fun '_toSQLString_bool' (arg:bool) : string =
    if arg then "true" else "false"
fun '_toSQLString_string' (arg:string) : string =
    "'s'"
fun '_toSQLString_real' (arg:real) : string =
    "0.0"
fun '_toSQLString_intOption' (arg:int option) : string =
    case arg of NONE => "NULL" | SOME x => '_toSQLString_int' x
fun '_toSQLString_wordOption' (arg:word option) : string =
    case arg of NONE => "NULL" | SOME x => '_toSQLString_word' x
fun '_toSQLString_charOption' (arg:char option) : string =
    case arg of NONE => "NULL" | SOME x => '_toSQLString_char' x
fun '_toSQLString_boolOption' (arg:bool option) : string =
    case arg of NONE => "NULL" | SOME x => '_toSQLString_bool' x
fun '_toSQLString_stringOption' (arg:string option) : string =
    case arg of NONE => "NULL" | SOME x => '_toSQLString_string' x
fun '_toSQLString_realOption' (arg:real option) : string =
    case arg of NONE => "NULL" | SOME x => '_toSQLString_real' x

val op ^ = _import "String_concat2" : string * string -> string
infix ^

structure '_SQL' =
struct
  open '_SQL'
  val toSQL = '_SQL_toSQL'
  val fromSQL = '_SQL_fromSQL'

  fun concatDot (x:string,y:string):string =
      case x of "" => y | _ => x ^ "." ^ y

  fun concatQuery (x:string list) : string =
      case x of nil => "" | h::t => h ^ concatQuery t

  fun '_format_server' (f:'a -> SMLSharp.SMLFormat.expression)
                       (x:'a server)
                       : SMLSharp.SMLFormat.expression =
    term "<server>"
  fun '_format_db' (f:'a -> SMLSharp.SMLFormat.expression)
                   (x:'a db)
                   : SMLSharp.SMLFormat.expression =
    term "<db>"
  fun '_format_table' (f:'a -> SMLSharp.SMLFormat.expression)
                      (x:'a table)
                      : SMLSharp.SMLFormat.expression =
    term "<table>"
  fun '_format_row' (f:'a -> SMLSharp.SMLFormat.expression)
                    (x:'a row)
                    : SMLSharp.SMLFormat.expression =
    term "<row>"
  fun '_format_value' (f:'a -> SMLSharp.SMLFormat.expression)
                      (x:'a value)
                      : SMLSharp.SMLFormat.expression =
    term "<value>"
  fun '_format_rel' (f:'a -> SMLSharp.SMLFormat.expression)
                    (x:'a rel)
                    : SMLSharp.SMLFormat.expression =
    term "<rel>"
  fun '_format_result' (f:'a -> SMLSharp.SMLFormat.expression)
                       (x:'a result)
                       : SMLSharp.SMLFormat.expression =
    term "<result>"
  fun '_format_bool' (arg:bool) : SMLSharp.SMLFormat.expression =
    term (if arg then "true" else "false")

  local
    fun op1 (oper, x1, w) =
        VALUE ("(" ^ oper ^ x1 ^ ")", w)
    fun op2 (x1, op2, x2, w) =
        VALUE (concatQuery ["(" ^ x1 ^ " " ^ op2 ^ " " ^ x2 ^ ")"], w)
  in

  fun add_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
              : int value =
      op2 (x1, "+", x2, w1)
  fun add_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
               : word value =
      op2 (x1, "+", x2, w1)
  fun add_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
               : real value =
      op2 (x1, "+", x2, w1)
  fun add_intOption (VALUE(x1, w1) : int option value,
                     VALUE(x2, w2) : int option value)
                    : int option value =
      op2 (x1, "+", x2, w1)
  fun add_wordOption (VALUE(x1, w1) : word option value,
                      VALUE(x2, w2) : word option value)
                     : word option value =
      op2 (x1, "+", x2, w1)
  fun add_realOption (VALUE(x1, w1) : real option value,
                      VALUE(x2, w2) : real option value)
                     : real option value =
      op2 (x1, "+", x2, w1)
  fun sub_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
              : int value =
      op2 (x1, "-", x2, w1)
  fun sub_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
               : word value =
      op2 (x1, "-", x2, w1)
  fun sub_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
               : real value =
      op2 (x1, "-", x2, w1)
  fun sub_intOption (VALUE(x1, w1) : int option value,
                     VALUE(x2, w2) : int option value)
                    : int option value =
      op2 (x1, "-", x2, w1)
  fun sub_wordOption (VALUE(x1, w1) : word option value,
                      VALUE(x2, w2) : word option value)
                     : word option value =
      op2 (x1, "-", x2, w1)
  fun sub_realOption (VALUE(x1, w1) : real option value,
                      VALUE(x2, w2) : real option value)
                     : real option value =
      op2 (x1, "-", x2, w1)
  fun mul_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
              : int value =
      op2 (x1, "*", x2, w1)
  fun mul_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
               : word value =
      op2 (x1, "*", x2, w1)
  fun mul_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
               : real value =
      op2 (x1, "*", x2, w1)
  fun mul_intOption (VALUE(x1, w1) : int option value,
                     VALUE(x2, w2) : int option value)
                    : int option value =
      op2 (x1, "*", x2, w1)
  fun mul_wordOption (VALUE(x1, w1) : word option value,
                      VALUE(x2, w2) : word option value)
                     : word option value =
      op2 (x1, "*", x2, w1)
  fun mul_realOption (VALUE(x1, w1) : real option value,
                      VALUE(x2, w2) : real option value)
                     : real option value =
      op2 (x1, "*", x2, w1)
  fun div_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
              : int value =
      op2 (x1, "/", x2, w1)
  fun div_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
               : word value =
      op2 (x1, "/", x2, w1)
  fun div_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
               : real value =
      op2 (x1, "/", x2, w1)
  fun div_intOption (VALUE(x1, w1) : int option value,
                     VALUE(x2, w2) : int option value)
                    : int option value =
      op2 (x1, "/", x2, w1)
  fun div_wordOption (VALUE(x1, w1) : word option value,
                      VALUE(x2, w2) : word option value)
                     : word option value =
      op2 (x1, "/", x2, w1)
  fun div_realOption (VALUE(x1, w1) : real option value,
                      VALUE(x2, w2) : real option value)
                     : real option value =
      op2 (x1, "/", x2, w1)
  fun mod_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
              : int value =
      op2 (x1, "%", x2, w1)
  fun mod_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
               : word value =
      op2 (x1, "%", x2, w1)
  fun mod_intOption (VALUE(x1, w1) : int option value,
                     VALUE(x2, w2) : int option value)
                    : int option value =
      op2 (x1, "%", x2, w1)
  fun mod_wordOption (VALUE(x1, w1) : word option value,
                      VALUE(x2, w2) : word option value)
                     : word option value =
      op2 (x1, "%", x2, w1)
  fun neg_int (VALUE(x1, w1) : int value) : int value =
      op1 ("-", x1, w1)
  fun neg_real (VALUE(x1, w1) : real value) : real value =
      op1 ("-", x1, w1)
  fun neg_intOption (VALUE(x1, w1) : int option value) : int option value =
      op1 ("-", x1, w1)
  fun neg_realOption (VALUE(x1, w1) : real option value) : real option value =
      op1 ("-", x1, w1)
  fun lt_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
             : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
              : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_char (VALUE(x1, w1) : char value, VALUE(x2, w2) : char value)
              : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_string (VALUE(x1, w1) : string value, VALUE(x2, w2) : string value)
                : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
              : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_intOption (VALUE(x1, w1) : int option value,
                    VALUE(x2, w2) : int option value)
                   : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_wordOption (VALUE(x1, w1) : word option value,
                     VALUE(x2, w2) : word option value)
                    : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_charOption (VALUE(x1, w1) : char option value,
                     VALUE(x2, w2) : char option value)
                    : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_boolOption (VALUE(x1, w1) : bool option value,
                     VALUE(x2, w2) : bool option value)
                    : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_stringOption (VALUE(x1, w1) : string option value,
                       VALUE(x2, w2) : string option value)
                      : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun lt_realOption (VALUE(x1, w1) : real option value,
                     VALUE(x2, w2) : real option value)
                    : bool option value =
      op2 (x1, "<", x2, SOME true)
  fun le_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
             : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
              : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_char (VALUE(x1, w1) : char value, VALUE(x2, w2) : char value)
              : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_string (VALUE(x1, w1) : string value, VALUE(x2, w2) : string value)
                : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
              : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_intOption (VALUE(x1, w1) : int option value,
                    VALUE(x2, w2) : int option value)
                   : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_wordOption (VALUE(x1, w1) : word option value,
                     VALUE(x2, w2) : word option value)
                    : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_charOption (VALUE(x1, w1) : char option value,
                     VALUE(x2, w2) : char option value)
                    : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_boolOption (VALUE(x1, w1) : bool option value,
                     VALUE(x2, w2) : bool option value)
                    : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_stringOption (VALUE(x1, w1) : string option value,
                       VALUE(x2, w2) : string option value)
                      : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun le_realOption (VALUE(x1, w1) : real option value,
                     VALUE(x2, w2) : real option value)
                    : bool option value =
      op2 (x1, "<=", x2, SOME true)
  fun gt_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
             : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
              : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_char (VALUE(x1, w1) : char value, VALUE(x2, w2) : char value)
              : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_string (VALUE(x1, w1) : string value, VALUE(x2, w2) : string value)
                : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
              : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_intOption (VALUE(x1, w1) : int option value,
                    VALUE(x2, w2) : int option value)
                   : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_wordOption (VALUE(x1, w1) : word option value,
                     VALUE(x2, w2) : word option value)
                    : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_charOption (VALUE(x1, w1) : char option value,
                     VALUE(x2, w2) : char option value)
                    : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_boolOption (VALUE(x1, w1) : bool option value,
                     VALUE(x2, w2) : bool option value)
                    : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_stringOption (VALUE(x1, w1) : string option value,
                       VALUE(x2, w2) : string option value)
                      : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun gt_realOption (VALUE(x1, w1) : real option value,
                     VALUE(x2, w2) : real option value)
                    : bool option value =
      op2 (x1, ">", x2, SOME true)
  fun ge_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
             : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
              : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_char (VALUE(x1, w1) : char value, VALUE(x2, w2) : char value)
              : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_string (VALUE(x1, w1) : string value, VALUE(x2, w2) : string value)
                : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
              : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_intOption (VALUE(x1, w1) : int option value,
                    VALUE(x2, w2) : int option value)
                   : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_wordOption (VALUE(x1, w1) : word option value,
                     VALUE(x2, w2) : word option value)
                    : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_charOption (VALUE(x1, w1) : char option value,
                     VALUE(x2, w2) : char option value)
                    : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_boolOption (VALUE(x1, w1) : bool option value,
                     VALUE(x2, w2) : bool option value)
                    : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_stringOption (VALUE(x1, w1) : string option value,
                       VALUE(x2, w2) : string option value)
                      : bool option value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_realOption (VALUE(x1, w1) : real option value,
                     VALUE(x2, w2) : real option value)
                    : bool option value =
      op2 (x1, ">=", x2, SOME true)

  fun eq_int (VALUE(x1, w1) : int value, VALUE(x2, w2) : int value)
             : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_word (VALUE(x1, w1) : word value, VALUE(x2, w2) : word value)
              : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_char (VALUE(x1, w1) : char value, VALUE(x2, w2) : char value)
              : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_string (VALUE(x1, w1) : string value, VALUE(x2, w2) : string value)
                : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_real (VALUE(x1, w1) : real value, VALUE(x2, w2) : real value)
              : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_intOption (VALUE(x1, w1) : int option value,
                    VALUE(x2, w2) : int option value)
                   : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_wordOption (VALUE(x1, w1) : word option value,
                     VALUE(x2, w2) : word option value)
                    : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_charOption (VALUE(x1, w1) : char option value,
                     VALUE(x2, w2) : char option value)
                    : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_boolOption (VALUE(x1, w1) : bool option value,
                     VALUE(x2, w2) : bool option value)
                    : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_stringOption (VALUE(x1, w1) : string option value,
                       VALUE(x2, w2) : string option value)
                      : bool option value =
      op2 (x1, "==", x2, SOME true)
  fun eq_realOption (VALUE(x1, w1) : real option value,
                     VALUE(x2, w2) : real option value)
                    : bool option value =
      op2 (x1, "==", x2, SOME true)

  end (* local *)

  val op < = '_SQL_lt'
  val op <= = '_SQL_le'
  val op > = '_SQL_gt'
  val op >= = '_SQL_ge'
  val op == = '_SQL_eq'

(*
  fun toSQL_int (x:int) : int value = VALUE (Int.toString x, x)
  fun toSQL_word (x:word) : word value = VALUE (Word.toString x, x)
  fun toSQL_char (x:char) : char value = VALUE (Char.toString x, x)
*)
  fun toSQL_int (x:int) : int value = VALUE ("", x)
  fun toSQL_word (x:word) : word value = VALUE ("", x)
  fun toSQL_char (x:char) : char value = VALUE ("", x)
  fun toSQL_string (x:string) : string value = VALUE ("", x)
  fun toSQL_real (x:real) : real value = VALUE ("", x)
  fun toSQL_intOption (x:int option) : int option value =
      case x of SOME x => VALUE ("", x) | NONE => VALUE ("NULL", x)
  fun toSQL_wordOption (x:word option) : word option value =
      case x of SOME x => VALUE ("", x) | NONE => VALUE ("NULL", x)
  fun toSQL_boolOption (x:bool option) : bool option value =
      case x of SOME true => VALUE ("t", x)
              | SOME false => VALUE ("f", x)
              | NONE => VALUE ("NULL", x)
  fun toSQL_charOption (x:char option) : char option value =
      case x of SOME x => VALUE ("", x) | NONE => VALUE ("NULL", x)
  fun toSQL_stringOption (x:string option) : string option value =
      case x of SOME x => VALUE ("", x) | NONE => VALUE ("NULL", x)
  fun toSQL_realOption (x:real option) : real option value =
      case x of SOME x => VALUE ("", x) | NONE => VALUE ("NULL", x)

  fun fromSQL_int (n:int, r:unit ptr, _:int) : int = 0
  fun fromSQL_word (n:int, r:unit ptr, _:word) : word = 0w0
  fun fromSQL_char (n:int, r:unit ptr, _:char) : char = #"0"
  fun fromSQL_string (n:int, r:unit ptr, _:string) : string = ""
  fun fromSQL_real (n:int, r:unit ptr, _:real) : real = 0.0
  fun fromSQL_intOption (n:int, r:unit ptr, _:int option) : int option = NONE
  fun fromSQL_wordOption (n:int, r:unit ptr, _:word option) : word option = NONE
  fun fromSQL_charOption (n:int, r:unit ptr, _:char option) : char option = NONE
  fun fromSQL_boolOption (n:int, r:unit ptr, _:bool option) : bool option = NONE
  fun fromSQL_stringOption (n:int, r:unit ptr, _:string option) : string option = NONE
  fun fromSQL_realOption (n:int, r:unit ptr, _:real option) : real option = NONE

end

structure SQL = '_SQL'

end (* local *)


(* sample SQL query

_sql db =>
select #person.name as name, #person.age as age
from #db.people as person
where #person.age > 10
order by #person.age;

*)






