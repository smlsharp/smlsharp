(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure '_SQL' =
struct
  open '_SQL'

  fun concatDot ((x:string, y:'a), z:string) : string * 'a =
      (case x of "" => z | _ => x ^ "." ^ z, y)

  fun concatQuery (x:(string * 'a) list) : string =
      case x of nil => "" | (h,_)::t => h ^ concatQuery t

  val eval : 'a dbi * (('b,'a) db -> 'c query) -> 'b conn -> 'c rel =
      SMLSharp.SQLImpl.eval
  val exec : 'a dbi * (('b,'a) db -> command) -> 'b conn -> unit =
      SMLSharp.SQLImpl.exec

  local
    fun term s = SMLSharp.SMLFormat.Term (SMLSharp.PrimString.size s, s)
  in

  fun '_format_server' (f:'a -> SMLSharp.SMLFormat.expression)
                       (SERVER (x,_,_):'a server)
                       : SMLSharp.SMLFormat.expression =
    term ("\"" ^ String.toString x ^ "\"")
  fun '_format_db' (f:'a -> SMLSharp.SMLFormat.expression)
                   (g:'b -> SMLSharp.SMLFormat.expression)
                   (x:('a,'b) db)
                   : SMLSharp.SMLFormat.expression =
    term "<db>"
  fun '_format_dbi' (f:'a -> SMLSharp.SMLFormat.expression)
                    (x:'a dbi)
                    : SMLSharp.SMLFormat.expression =
    term "<dbi>"
  fun '_format_conn' (f:'a -> SMLSharp.SMLFormat.expression)
                     (x:'a conn)
                     : SMLSharp.SMLFormat.expression =
    term "<conn>"
  fun '_format_table' (f:'a -> SMLSharp.SMLFormat.expression)
                      (g:'b -> SMLSharp.SMLFormat.expression)
                      (TABLE ((x,_),_):('a,'b) table)
                      : SMLSharp.SMLFormat.expression =
    term x
  fun '_format_row' (f:'a -> SMLSharp.SMLFormat.expression)
                    (g:'b -> SMLSharp.SMLFormat.expression)
                    (ROW ((x,_),_):('a,'b) row)
                    : SMLSharp.SMLFormat.expression =
    term x
  fun '_format_value' (f:'a -> SMLSharp.SMLFormat.expression)
                      (g:'b -> SMLSharp.SMLFormat.expression)
                      (VALUE ((x,_),_):('a,'b) value)
                      : SMLSharp.SMLFormat.expression =
    term x
  fun '_format_query' (f:'a -> SMLSharp.SMLFormat.expression)
                      (QUERY (x,_,_):'a query)
                      : SMLSharp.SMLFormat.expression =
    term ("\"" ^ String.toString x ^ "\"")
  fun '_format_command' (COMMAND x : command) : SMLSharp.SMLFormat.expression =
    term ("\"" ^ String.toString x ^ "\"")
  fun '_format_rel' (f:'a -> SMLSharp.SMLFormat.expression)
                    (x:'a rel)
                    : SMLSharp.SMLFormat.expression =
    term "<rel>"
  fun '_format_result' (x:result) : SMLSharp.SMLFormat.expression =
    term "<result>"

  fun '_format_bool' (arg:bool) : SMLSharp.SMLFormat.expression =
    term (if arg then "true" else "false")

  end (* local *)

  local
    fun op1 (oper, (x1,i), w) =
        VALUE (("(" ^ oper ^ x1 ^ ")", i), w)
    fun op1post ((x1,i), oper, w) =
        VALUE (("(" ^ x1 ^ oper ^ ")", i), w)
    fun op2 ((x1,i1:'a dbi), oper2, (x2,i2:'a dbi), w) =
        VALUE (("(" ^ x1 ^ " " ^ oper2 ^ " " ^ x2 ^ ")", i1), w)
  in

  fun add_int (VALUE(x1, w1) : (int,unit) value,
               VALUE(x2, w2) : (int,unit) value)
              : (int,unit) value =
      op2 (x1, "+", x2, w1)
  fun add_word (VALUE(x1, w1) : (word,unit) value,
                VALUE(x2, w2) : (word,unit) value)
               : (word,unit) value =
      op2 (x1, "+", x2, w1)
  fun add_real (VALUE(x1, w1) : (real,unit) value,
                VALUE(x2, w2) : (real,unit) value)
               : (real,unit) value =
      op2 (x1, "+", x2, w1)
  fun add_intOption (VALUE(x1, w1) : (int option,unit) value,
                     VALUE(x2, w2) : (int option,unit) value)
                    : (int option,unit) value =
      op2 (x1, "+", x2, w1)
  fun add_wordOption (VALUE(x1, w1) : (word option,unit) value,
                      VALUE(x2, w2) : (word option,unit) value)
                     : (word option,unit) value =
      op2 (x1, "+", x2, w1)
  fun add_realOption (VALUE(x1, w1) : (real option,unit) value,
                      VALUE(x2, w2) : (real option,unit) value)
                     : (real option,unit) value =
      op2 (x1, "+", x2, w1)
  fun sub_int (VALUE(x1, w1) : (int,unit) value,
               VALUE(x2, w2) : (int,unit) value)
              : (int,unit) value =
      op2 (x1, "-", x2, w1)
  fun sub_word (VALUE(x1, w1) : (word,unit) value,
                VALUE(x2, w2) : (word,unit) value)
               : (word,unit) value =
      op2 (x1, "-", x2, w1)
  fun sub_real (VALUE(x1, w1) : (real,unit) value,
                VALUE(x2, w2) : (real,unit) value)
               : (real,unit) value =
      op2 (x1, "-", x2, w1)
  fun sub_intOption (VALUE(x1, w1) : (int option,unit) value,
                     VALUE(x2, w2) : (int option,unit) value)
                    : (int option,unit) value =
      op2 (x1, "-", x2, w1)
  fun sub_wordOption (VALUE(x1, w1) : (word option,unit) value,
                      VALUE(x2, w2) : (word option,unit) value)
                     : (word option,unit) value =
      op2 (x1, "-", x2, w1)
  fun sub_realOption (VALUE(x1, w1) : (real option,unit) value,
                      VALUE(x2, w2) : (real option,unit) value)
                     : (real option,unit) value =
      op2 (x1, "-", x2, w1)
  fun mul_int (VALUE(x1, w1) : (int,unit) value,
               VALUE(x2, w2) : (int,unit) value)
              : (int,unit) value =
      op2 (x1, "*", x2, w1)
  fun mul_word (VALUE(x1, w1) : (word,unit) value,
                VALUE(x2, w2) : (word,unit) value)
               : (word,unit) value =
      op2 (x1, "*", x2, w1)
  fun mul_real (VALUE(x1, w1) : (real,unit) value,
                VALUE(x2, w2) : (real,unit) value)
               : (real,unit) value =
      op2 (x1, "*", x2, w1)
  fun mul_intOption (VALUE(x1, w1) : (int option,unit) value,
                     VALUE(x2, w2) : (int option,unit) value)
                    : (int option,unit) value =
      op2 (x1, "*", x2, w1)
  fun mul_wordOption (VALUE(x1, w1) : (word option,unit) value,
                      VALUE(x2, w2) : (word option,unit) value)
                     : (word option,unit) value =
      op2 (x1, "*", x2, w1)
  fun mul_realOption (VALUE(x1, w1) : (real option,unit) value,
                      VALUE(x2, w2) : (real option,unit) value)
                     : (real option,unit) value =
      op2 (x1, "*", x2, w1)
  fun div_int (VALUE(x1, w1) : (int,unit) value,
               VALUE(x2, w2) : (int,unit) value)
              : (int,unit) value =
      op2 (x1, "/", x2, w1)
  fun div_word (VALUE(x1, w1) : (word,unit) value,
                VALUE(x2, w2) : (word,unit) value)
               : (word,unit) value =
      op2 (x1, "/", x2, w1)
  fun div_real (VALUE(x1, w1) : (real,unit) value,
                VALUE(x2, w2) : (real,unit) value)
               : (real,unit) value =
      op2 (x1, "/", x2, w1)
  fun div_intOption (VALUE(x1, w1) : (int option,unit) value,
                     VALUE(x2, w2) : (int option,unit) value)
                    : (int option,unit) value =
      op2 (x1, "/", x2, w1)
  fun div_wordOption (VALUE(x1, w1) : (word option,unit) value,
                      VALUE(x2, w2) : (word option,unit) value)
                     : (word option,unit) value =
      op2 (x1, "/", x2, w1)
  fun div_realOption (VALUE(x1, w1) : (real option,unit) value,
                      VALUE(x2, w2) : (real option,unit) value)
                     : (real option,unit) value =
      op2 (x1, "/", x2, w1)
  fun mod_int (VALUE(x1, w1) : (int,unit) value,
               VALUE(x2, w2) : (int,unit) value)
              : (int,unit) value =
      op2 (x1, "%", x2, w1)
  fun mod_word (VALUE(x1, w1) : (word,unit) value,
                VALUE(x2, w2) : (word,unit) value)
               : (word,unit) value =
      op2 (x1, "%", x2, w1)
  fun mod_intOption (VALUE(x1, w1) : (int option,unit) value,
                     VALUE(x2, w2) : (int option,unit) value)
                    : (int option,unit) value =
      op2 (x1, "%", x2, w1)
  fun mod_wordOption (VALUE(x1, w1) : (word option,unit) value,
                      VALUE(x2, w2) : (word option,unit) value)
                     : (word option,unit) value =
      op2 (x1, "%", x2, w1)
  fun neg_int (VALUE(x1, w1) : (int,unit) value)
              : (int,unit) value =
      op1 ("-", x1, w1)
  fun neg_real (VALUE(x1, w1) : (real,unit) value)
               : (real,unit) value =
      op1 ("-", x1, w1)
  fun neg_intOption (VALUE(x1, w1) : (int option,unit) value)
                    : (int option,unit) value =
      op1 ("-", x1, w1)
  fun neg_realOption (VALUE(x1, w1) : (real option,unit) value)
                     : (real option,unit) value =
      op1 ("-", x1, w1)
  fun abs_int (VALUE(x1, w1) : (int,unit) value)
              : (int,unit) value =
      op1 ("@", x1, w1)
  fun abs_real (VALUE(x1, w1) : (real,unit) value)
               : (real,unit) value =
      op1 ("@", x1, w1)
  fun abs_intOption (VALUE(x1, w1) : (int option,unit) value)
                    : (int option,unit) value =
      op1 ("@", x1, w1)
  fun abs_realOption (VALUE(x1, w1) : (real option,unit) value)
                     : (real option,unit) value =
      op1 ("@", x1, w1)
  fun lt_int (VALUE(x1, w1) : (int,unit) value,
              VALUE(x2, w2) : (int,unit) value)
             : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_word (VALUE(x1, w1) : (word,unit) value,
               VALUE(x2, w2) : (word,unit) value)
              : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_char (VALUE(x1, w1) : (char,unit) value,
               VALUE(x2, w2) : (char,unit) value)
              : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_string (VALUE(x1, w1) : (string,unit) value,
                 VALUE(x2, w2) : (string,unit) value)
                : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_real (VALUE(x1, w1) : (real,unit) value,
               VALUE(x2, w2) : (real,unit) value)
              : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_intOption (VALUE(x1, w1) : (int option,unit) value,
                    VALUE(x2, w2) : (int option,unit) value)
                   : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_wordOption (VALUE(x1, w1) : (word option,unit) value,
                     VALUE(x2, w2) : (word option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_charOption (VALUE(x1, w1) : (char option,unit) value,
                     VALUE(x2, w2) : (char option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_boolOption (VALUE(x1, w1) : (bool option,unit) value,
                     VALUE(x2, w2) : (bool option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_stringOption (VALUE(x1, w1) : (string option,unit) value,
                       VALUE(x2, w2) : (string option,unit) value)
                      : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun lt_realOption (VALUE(x1, w1) : (real option,unit) value,
                     VALUE(x2, w2) : (real option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<", x2, SOME true)
  fun le_int (VALUE(x1, w1) : (int,unit) value,
              VALUE(x2, w2) : (int,unit) value)
             : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_word (VALUE(x1, w1) : (word,unit) value,
               VALUE(x2, w2) : (word,unit) value)
              : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_char (VALUE(x1, w1) : (char,unit) value,
               VALUE(x2, w2) : (char,unit) value)
              : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_string (VALUE(x1, w1) : (string,unit) value,
                 VALUE(x2, w2) : (string,unit) value)
                : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_real (VALUE(x1, w1) : (real,unit) value,
               VALUE(x2, w2) : (real,unit) value)
              : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_intOption (VALUE(x1, w1) : (int option,unit) value,
                    VALUE(x2, w2) : (int option,unit) value)
                   : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_wordOption (VALUE(x1, w1) : (word option,unit) value,
                     VALUE(x2, w2) : (word option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_charOption (VALUE(x1, w1) : (char option,unit) value,
                     VALUE(x2, w2) : (char option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_boolOption (VALUE(x1, w1) : (bool option,unit) value,
                     VALUE(x2, w2) : (bool option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_stringOption (VALUE(x1, w1) : (string option,unit) value,
                       VALUE(x2, w2) : (string option,unit) value)
                      : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun le_realOption (VALUE(x1, w1) : (real option,unit) value,
                     VALUE(x2, w2) : (real option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<=", x2, SOME true)
  fun gt_int (VALUE(x1, w1) : (int,unit) value,
              VALUE(x2, w2) : (int,unit) value)
             : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_word (VALUE(x1, w1) : (word,unit) value,
               VALUE(x2, w2) : (word,unit) value)
              : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_char (VALUE(x1, w1) : (char,unit) value,
               VALUE(x2, w2) : (char,unit) value)
              : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_string (VALUE(x1, w1) : (string,unit) value,
                 VALUE(x2, w2) : (string,unit) value)
                : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_real (VALUE(x1, w1) : (real,unit) value,
               VALUE(x2, w2) : (real,unit) value)
              : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_intOption (VALUE(x1, w1) : (int option,unit) value,
                    VALUE(x2, w2) : (int option,unit) value)
                   : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_wordOption (VALUE(x1, w1) : (word option,unit) value,
                     VALUE(x2, w2) : (word option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_charOption (VALUE(x1, w1) : (char option,unit) value,
                     VALUE(x2, w2) : (char option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_boolOption (VALUE(x1, w1) : (bool option,unit) value,
                     VALUE(x2, w2) : (bool option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_stringOption (VALUE(x1, w1) : (string option,unit) value,
                       VALUE(x2, w2) : (string option,unit) value)
                      : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun gt_realOption (VALUE(x1, w1) : (real option,unit) value,
                     VALUE(x2, w2) : (real option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, ">", x2, SOME true)
  fun ge_int (VALUE(x1, w1) : (int,unit) value,
              VALUE(x2, w2) : (int,unit) value)
             : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_word (VALUE(x1, w1) : (word,unit) value,
               VALUE(x2, w2) : (word,unit) value)
              : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_char (VALUE(x1, w1) : (char,unit) value,
               VALUE(x2, w2) : (char,unit) value)
              : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_string (VALUE(x1, w1) : (string,unit) value,
                 VALUE(x2, w2) : (string,unit) value)
                : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_real (VALUE(x1, w1) : (real,unit) value,
               VALUE(x2, w2) : (real,unit) value)
              : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_intOption (VALUE(x1, w1) : (int option,unit) value,
                    VALUE(x2, w2) : (int option,unit) value)
                   : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_wordOption (VALUE(x1, w1) : (word option,unit) value,
                     VALUE(x2, w2) : (word option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_charOption (VALUE(x1, w1) : (char option,unit) value,
                     VALUE(x2, w2) : (char option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_boolOption (VALUE(x1, w1) : (bool option,unit) value,
                     VALUE(x2, w2) : (bool option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_stringOption (VALUE(x1, w1) : (string option,unit) value,
                       VALUE(x2, w2) : (string option,unit) value)
                      : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)
  fun ge_realOption (VALUE(x1, w1) : (real option,unit) value,
                     VALUE(x2, w2) : (real option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, ">=", x2, SOME true)

  fun eq_int (VALUE(x1, w1) : (int,unit) value,
              VALUE(x2, w2) : (int,unit) value)
             : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_word (VALUE(x1, w1) : (word,unit) value,
               VALUE(x2, w2) : (word,unit) value)
              : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_char (VALUE(x1, w1) : (char,unit) value,
               VALUE(x2, w2) : (char,unit) value)
              : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_string (VALUE(x1, w1) : (string,unit) value,
                 VALUE(x2, w2) : (string,unit) value)
                : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_real (VALUE(x1, w1) : (real,unit) value,
               VALUE(x2, w2) : (real,unit) value)
              : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_intOption (VALUE(x1, w1) : (int option,unit) value,
                    VALUE(x2, w2) : (int option,unit) value)
                   : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_wordOption (VALUE(x1, w1) : (word option,unit) value,
                     VALUE(x2, w2) : (word option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_charOption (VALUE(x1, w1) : (char option,unit) value,
                     VALUE(x2, w2) : (char option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_boolOption (VALUE(x1, w1) : (bool option,unit) value,
                     VALUE(x2, w2) : (bool option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_stringOption (VALUE(x1, w1) : (string option,unit) value,
                       VALUE(x2, w2) : (string option,unit) value)
                      : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)
  fun eq_realOption (VALUE(x1, w1) : (real option,unit) value,
                     VALUE(x2, w2) : (real option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "=", x2, SOME true)

  fun neq_int (VALUE(x1, w1) : (int,unit) value,
               VALUE(x2, w2) : (int,unit) value)
              : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_word (VALUE(x1, w1) : (word,unit) value,
                VALUE(x2, w2) : (word,unit) value)
               : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_char (VALUE(x1, w1) : (char,unit) value,
                VALUE(x2, w2) : (char,unit) value)
               : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_string (VALUE(x1, w1) : (string,unit) value,
                  VALUE(x2, w2) : (string,unit) value)
                 : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_real (VALUE(x1, w1) : (real,unit) value,
                VALUE(x2, w2) : (real,unit) value)
               : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_intOption (VALUE(x1, w1) : (int option,unit) value,
                     VALUE(x2, w2) : (int option,unit) value)
                    : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_wordOption (VALUE(x1, w1) : (word option,unit) value,
                      VALUE(x2, w2) : (word option,unit) value)
                     : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_charOption (VALUE(x1, w1) : (char option,unit) value,
                      VALUE(x2, w2) : (char option,unit) value)
                     : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_boolOption (VALUE(x1, w1) : (bool option,unit) value,
                      VALUE(x2, w2) : (bool option,unit) value)
                     : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_stringOption (VALUE(x1, w1) : (string option,unit) value,
                        VALUE(x2, w2) : (string option,unit) value)
                       : (bool option,unit) value =
      op2 (x1, "<>", x2, SOME true)
  fun neq_realOption (VALUE(x1, w1) : (real option,unit) value,
                      VALUE(x2, w2) : (real option,unit) value)
                     : (bool option,unit) value =
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

  fun isNull (VALUE(x1, w1) : ('a option, 'a) value) =
      op1post (x1, " is null", w1)

  fun isNotNull (VALUE(x1, w1) : ('a option, 'a) value) =
      op1post (x1, " is not null", w1)

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

  fun toSQL_int (x:int) : (int, unit) value =
      VALUE ((sqlInt x, DBI), x)
  fun toSQL_word (x:word) : (word, unit) value =
      VALUE ((sqlWord x, DBI), x)
  fun toSQL_char (x:char) : (char, unit) value =
      VALUE ((sqlChar x, DBI), x)
  fun toSQL_string (x:string) : (string, unit) value =
      VALUE ((sqlString x, DBI), x)
  fun toSQL_real (x:real) : (real, unit) value =
      VALUE ((sqlReal x, DBI), x)
  fun toSQL_intOption (x:int option) : (int option, unit) value =
      case x of SOME y => VALUE ((sqlInt y, DBI), x) | NONE => nullValue x
  fun toSQL_wordOption (x:word option) : (word option, unit) value =
      case x of SOME y => VALUE ((sqlWord y, DBI), x) | NONE => nullValue x
  fun toSQL_boolOption (x:bool option) : (bool option, unit) value =
      case x of SOME y => VALUE ((sqlBool y, DBI), x) | NONE => nullValue x
  fun toSQL_charOption (x:char option) : (char option, unit) value =
      case x of SOME y => VALUE ((sqlChar y, DBI), x) | NONE => nullValue x
  fun toSQL_stringOption (x:string option) : (string option, unit) value =
      case x of SOME y => VALUE ((sqlString y, DBI), x) | NONE => nullValue x
  fun toSQL_realOption (x:real option) : (real option, unit) value =
      case x of SOME y => VALUE ((sqlReal y, DBI), x) | NONE => nullValue x

  end (* local *)

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

  fun default_int () : (int, unit) value =
      VALUE (("DEFAULT", DBI), 0)
  fun default_word () : (word, unit) value =
      VALUE (("DEFAULT", DBI), 0w0)
  fun default_char () : (char, unit) value =
      VALUE (("DEFAULT", DBI), #"\000")
  fun default_string () : (string, unit) value =
      VALUE (("DEFAULT", DBI), "")
  fun default_real () : (real, unit) value =
      VALUE (("DEFAULT", DBI), 0.0)
  fun default_intOption () : (int option, unit) value =
      VALUE (("DEFAULT", DBI), SOME 0)
  fun default_wordOption () : (word option, unit) value =
      VALUE (("DEFAULT", DBI), SOME 0w0)
  fun default_charOption () : (char option, unit) value =
      VALUE (("DEFAULT", DBI), SOME #"\000")
  fun default_boolOption () : (bool option, unit) value =
      VALUE (("DEFAULT", DBI), SOME true)
  fun default_stringOption () : (string option, unit) value =
      VALUE (("DEFAULT", DBI), SOME "")
  fun default_realOption () : (real option, unit) value =
      VALUE (("DEFAULT", DBI), SOME 0.0)

  val op + = '_SQL_add'
  val op - = '_SQL_sub'
  val op * = '_SQL_mul'
  val op div = '_SQL_div'
  val op mod = '_SQL_mod'
  val op / = '_SQL_divr'
  val op ~ = '_SQL_neg'
  val op abs = '_SQL_abs'
  val op < = '_SQL_lt'
  val op <= = '_SQL_le'
  val op > = '_SQL_gt'
  val op >= = '_SQL_ge'
  val op == = '_SQL_eq'
  val op <> = '_SQL_neq'
  val op ^ = strcat
  val toSQL = '_SQL_toSQL'
  val fromSQL = '_SQL_fromSQL'

end
