(**
 * predefined types and primitives for SQL.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure BuiltinContextSQL : sig

  val decls : (string * BuiltinContextMaker.decl) list

end =
struct

  structure P = BuiltinPrimitive
  datatype decl = datatype BuiltinContextMaker.decl
  datatype oprimInstance = datatype OPrimInstance.instance

  val decls =
      [
       ("_SQL.server",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ],
          constructors = [
            {name = "SERVER",
             ty = "['a.string * (string *\
                  \ ({colname:string,typename:string,isnull:bool}) list) list\
                  \ * 'a -> ('a)server]",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.conn",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ],
          constructors = [
            {name = "CONN", ty = "['a.(unit)ptr * 'a -> ('a)conn]",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.dbi",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ],
          constructors = [
            {name = "DBI", ty = "['a.('a)dbi]",
             hasArg = false, tag = 0}
          ],
          runtimeTy = SOME RuntimeTypes.INTty,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.db",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ, Types.NONEQ],
          constructors = [
            {name = "DB", ty = "['a,'b.'a * ('b)_SQL.dbi -> ('a,'b)db]",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.table",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ, Types.NONEQ],
          constructors = [
            {name = "TABLE",
             ty = "['a,'b.(string * ('b)_SQL.dbi) * 'a -> ('a,'b)table]",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.row",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ, Types.NONEQ],
          constructors = [
            {name = "ROW",
             ty = "['a,'b.(string * ('b)_SQL.dbi) * 'a -> ('a,'b)row]",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.value",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ, Types.NONEQ],
          constructors = [
            {name = "VALUE",
             ty = "['a,'b.(string * ('b)_SQL.dbi) * 'a -> ('a,'b)value]",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.result",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [],
          constructors = [
            {name = "RESULT",
             ty = "(unit)ptr * int -> result",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.rel",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ],
          constructors = [
            {name = "REL",
             ty = "['a._SQL.result * (_SQL.result -> 'a) -> ('a)rel]",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.query",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [Types.NONEQ],
          constructors = [
            {name = "QUERY",
             ty = "['a.string * 'a * (_SQL.result -> 'a) -> ('a)query]",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),
       ("_SQL.command",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [],
          constructors = [
            {name = "COMMAND",
             ty = "string -> command",
             hasArg = true, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),

       (* protect them from overriding by user. *)
       ("_SQL.bool", TYPEALIAS "bool"),
       ("_SQL.option", TYPEALIAS "option"),

       ("_SQL._format_server",
        DUMMY {ty = "['a.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('a)_SQL.server -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_conn",
        DUMMY {ty = "['a.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('a)_SQL.conn -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_dbi",
        DUMMY {ty = "['a.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('a)_SQL.dbi -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_db",
        DUMMY {ty = "['a,'b.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('b -> SMLSharp.SMLFormat.expression) \
                    \-> ('a,'b)_SQL.db -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_table",
        DUMMY {ty = "['a,'b.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('b -> SMLSharp.SMLFormat.expression) \
                    \-> ('a,'b)_SQL.table -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_row",
        DUMMY {ty = "['a,'b.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('b -> SMLSharp.SMLFormat.expression) \
                    \-> ('a,'b)_SQL.row -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_value",
        DUMMY {ty = "['a,'b.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('b -> SMLSharp.SMLFormat.expression) \
                    \-> ('a,'b)_SQL.value -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_result",
        DUMMY {ty = "_SQL.result -> SMLSharp.SMLFormat.expression"}),
       ("_SQL._format_rel",
        DUMMY {ty = "['a.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('a)_SQL.rel -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_query",
        DUMMY {ty = "['a.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('a)_SQL.query -> SMLSharp.SMLFormat.expression]"}),
       ("_SQL._format_command",
        DUMMY {ty = "_SQL.command -> SMLSharp.SMLFormat.expression"}),
       ("_SQL._format_bool",
        DUMMY {ty = "_SQL.bool -> SMLSharp.SMLFormat.expression"}),
       ("_SQL._format_option",
        DUMMY {ty = "['a.('a -> SMLSharp.SMLFormat.expression) \
                    \-> ('a)_SQL.option -> SMLSharp.SMLFormat.expression]"}),

       ("_SQL.concatDot",
        DUMMY {ty = "(string * 'a) * string -> string * 'a"}),
       ("_SQL.concatQuery",
        DUMMY {ty = "(string * 'a)list -> string"}),

       ("_SQL.eval",
        DUMMY {ty = "['a,'b,'c.\
                    \('a)_SQL.dbi * (('b,'a)_SQL.db -> ('c)_SQL.query)\
                    \ -> ('b)_SQL.conn\
                    \ -> ('c)_SQL.rel]"}),
       ("_SQL.exec",
        DUMMY {ty = "['a,'b.\
                    \('a)_SQL.dbi * (('b,'a)_SQL.db -> _SQL.command)\
                    \ -> ('b)_SQL.conn\
                    \ -> unit]"}),

       ("_SQL_toSQL",
        OPRIM {
          ty = "['a#{int,word,char,string,real,('b)option},\
               \'b#{int,word,char,bool,string,real},'c.\
               \'a -> ('a,'c)_SQL.value]",
          instances = [
            {instTyList = ["int","_"],
             instance=EXTERNVAR "_SQL.toSQL_int"},
            {instTyList = ["word","_"],
             instance=EXTERNVAR "_SQL.toSQL_word"},
            {instTyList = ["char","_"],
             instance=EXTERNVAR "_SQL.toSQL_char"},
            {instTyList = ["string","_"],
             instance=EXTERNVAR "_SQL.toSQL_string"},
            {instTyList = ["real","_"],
             instance=EXTERNVAR "_SQL.toSQL_real"},
            {instTyList = ["(int)option","int"],
             instance=EXTERNVAR "_SQL.toSQL_intOption"},
            {instTyList = ["(word)option","word"],
             instance=EXTERNVAR "_SQL.toSQL_wordOption"},
            {instTyList = ["(char)option","char"],
             instance=EXTERNVAR "_SQL.toSQL_charOption"},
            {instTyList = ["(bool)option","bool"],
             instance=EXTERNVAR "_SQL.toSQL_boolOption"},
            {instTyList = ["(string)option","string"],
             instance=EXTERNVAR "_SQL.toSQL_stringOption"},
            {instTyList = ["(real)option","real"],
             instance=EXTERNVAR "_SQL.toSQL_realOption"}
          ]
        }),

       ("_SQL.toSQL_int",
        DUMMY {ty = "int -> (int,unit)_SQL.value"}),
       ("_SQL.toSQL_word",
        DUMMY {ty = "word -> (word,unit)_SQL.value"}),
       ("_SQL.toSQL_char",
        DUMMY {ty = "char -> (char,unit)_SQL.value"}),
       ("_SQL.toSQL_string",
        DUMMY {ty = "string -> (string,unit)_SQL.value"}),
       ("_SQL.toSQL_real",
        DUMMY {ty = "real -> (real,unit)_SQL.value"}),
       ("_SQL.toSQL_intOption",
        DUMMY {ty = "(int)option\
                    \ -> ((int)option,unit)_SQL.value"}),
       ("_SQL.toSQL_wordOption",
        DUMMY {ty = "(word)option\
                    \ -> ((word)option,unit)_SQL.value"}),
       ("_SQL.toSQL_charOption",
        DUMMY {ty = "(char)option\
                    \ -> ((char)option,unit)_SQL.value"}),
       ("_SQL.toSQL_boolOption",
        DUMMY {ty = "(bool)option\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.toSQL_stringOption",
        DUMMY {ty = "(string)option\
                    \ -> ((string)option,unit)_SQL.value"}),
       ("_SQL.toSQL_realOption",
        DUMMY {ty = "(real)option\
                    \ -> ((real)option,unit)_SQL.value"}),

       ("_SQL_fromSQL",
        OPRIM {
          ty = "['a#{int,word,char,string,real,('b)option},\
               \'b#{int,word,char,bool,string,real}.\
               \int * _SQL.result * 'a -> 'a]",
          instances = [
            {instTyList = ["int","_"],
             instance=EXTERNVAR "_SQL.fromSQL_int"},
            {instTyList = ["word","_"],
             instance=EXTERNVAR "_SQL.fromSQL_word"},
            {instTyList = ["char","_"],
             instance=EXTERNVAR "_SQL.fromSQL_char"},
            {instTyList = ["string","_"],
             instance=EXTERNVAR "_SQL.fromSQL_string"},
            {instTyList = ["real","_"],
             instance=EXTERNVAR "_SQL.fromSQL_real"},
            {instTyList = ["(int)option","int"],
             instance=EXTERNVAR "_SQL.fromSQL_intOption"},
            {instTyList = ["(word)option","word"],
             instance=EXTERNVAR "_SQL.fromSQL_wordOption"},
            {instTyList = ["(char)option","char"],
             instance=EXTERNVAR "_SQL.fromSQL_charOption"},
            {instTyList = ["(bool)option","bool"],
             instance=EXTERNVAR "_SQL.fromSQL_boolOption"},
            {instTyList = ["(string)option","string"],
             instance=EXTERNVAR "_SQL.fromSQL_stringOption"},
            {instTyList = ["(real)option","real"],
             instance=EXTERNVAR "_SQL.fromSQL_realOption"}
          ]
        }),

       ("_SQL.fromSQL_int",
        DUMMY {ty = "int * _SQL.result * int -> int"}),
       ("_SQL.fromSQL_word",
        DUMMY {ty = "int * _SQL.result * word -> word"}),
       ("_SQL.fromSQL_char",
        DUMMY {ty = "int * _SQL.result * char -> char"}),
       ("_SQL.fromSQL_string",
        DUMMY {ty = "int * _SQL.result * string -> string"}),
       ("_SQL.fromSQL_real",
        DUMMY {ty = "int * _SQL.result * real -> real"}),
       ("_SQL.fromSQL_intOption",
        DUMMY {ty = "int * _SQL.result * (int)option -> (int)option"}),
       ("_SQL.fromSQL_wordOption",
        DUMMY {ty = "int * _SQL.result * (word)option -> (word)option"}),
       ("_SQL.fromSQL_charOption",
        DUMMY {ty = "int * _SQL.result * (char)option -> (char)option"}),
       ("_SQL.fromSQL_boolOption",
        DUMMY {ty = "int * _SQL.result * (bool)option -> (bool)option"}),
       ("_SQL.fromSQL_stringOption",
        DUMMY {ty = "int * _SQL.result * (string)option\
                    \ -> (string)option"}),
       ("_SQL.fromSQL_realOption",
        DUMMY {ty = "int * _SQL.result * (real)option -> (real)option"}),

       ("_SQL_default",
        OPRIM {
          ty = "['a#{int,word,char,string,real,('b)option},\
               \'b#{int,word,char,bool,string,real},'c.\
               \unit -> ('a,'c)_SQL.value]",
          instances = [
            {instTyList = ["int","_"],
             instance=EXTERNVAR "_SQL.default_int"},
            {instTyList = ["word","_"],
             instance=EXTERNVAR "_SQL.default_word"},
            {instTyList = ["char","_"],
             instance=EXTERNVAR "_SQL.default_char"},
            {instTyList = ["string","_"],
             instance=EXTERNVAR "_SQL.default_string"},
            {instTyList = ["real","_"],
             instance=EXTERNVAR "_SQL.default_real"},
            {instTyList = ["(int)option","int"],
             instance=EXTERNVAR "_SQL.default_intOption"},
            {instTyList = ["(word)option","word"],
             instance=EXTERNVAR "_SQL.default_wordOption"},
            {instTyList = ["(char)option","char"],
             instance=EXTERNVAR "_SQL.default_charOption"},
            {instTyList = ["(bool)option","bool"],
             instance=EXTERNVAR "_SQL.default_boolOption"},
            {instTyList = ["(string)option","string"],
             instance=EXTERNVAR "_SQL.default_stringOption"},
            {instTyList = ["(real)option","real"],
             instance=EXTERNVAR "_SQL.default_realOption"}
          ]
        }),

       ("_SQL.default_int",
        DUMMY {ty = "unit -> (int,unit)_SQL.value"}),
       ("_SQL.default_word",
        DUMMY {ty = "unit -> (word,unit)_SQL.value"}),
       ("_SQL.default_char",
        DUMMY {ty = "unit -> (char,unit)_SQL.value"}),
       ("_SQL.default_string",
        DUMMY {ty = "unit -> (string,unit)_SQL.value"}),
       ("_SQL.default_real",
        DUMMY {ty = "unit -> (real,unit)_SQL.value"}),
       ("_SQL.default_intOption",
        DUMMY {ty = "unit -> ((int)option,unit)_SQL.value"}),
       ("_SQL.default_wordOption",
        DUMMY {ty = "unit -> ((word)option,unit)_SQL.value"}),
       ("_SQL.default_charOption",
        DUMMY {ty = "unit -> ((char)option,unit)_SQL.value"}),
       ("_SQL.default_boolOption",
        DUMMY {ty = "unit -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.default_stringOption",
        DUMMY {ty = "unit -> ((string)option,unit)_SQL.value"}),
       ("_SQL.default_realOption",
        DUMMY {ty = "unit -> ((real)option,unit)_SQL.value"}),

       ("_SQL_add",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,real,('c)option},\
               \'c#{int,word,real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ('b,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.add_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.add_word"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.add_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.add_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.add_wordOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.add_realOption"}
           ]
        }),

       ("_SQL.add_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> (int,unit)_SQL.value"}),
       ("_SQL.add_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> (word,unit)_SQL.value"}),
       ("_SQL.add_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> (real,unit)_SQL.value"}),
       ("_SQL.add_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((int)option,unit)_SQL.value"}),
       ("_SQL.add_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((word)option,unit)_SQL.value"}),
       ("_SQL.add_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((real)option,unit)_SQL.value"}),

       ("_SQL_sub",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,real,('c)option},\
               \'c#{int,word,real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ('b,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.sub_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.sub_word"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.sub_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.sub_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.sub_wordOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.sub_realOption"}
          ]
        }),

       ("_SQL.sub_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> (int,unit)_SQL.value"}),
       ("_SQL.sub_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> (word,unit)_SQL.value"}),
       ("_SQL.sub_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> (real,unit)_SQL.value"}),
       ("_SQL.sub_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((int)option,unit)_SQL.value"}),
       ("_SQL.sub_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((word)option,unit)_SQL.value"}),
       ("_SQL.sub_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((real)option,unit)_SQL.value"}),

       ("_SQL_mul",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,real,('c)option},\
               \'c#{int,word,real}.\
               \('c,'a)_SQL.value\
               \ * ('c,'a)_SQL.value\
               \ -> ('c,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.mul_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.mul_word"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.mul_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.mul_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.mul_wordOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.mul_realOption"}
         ]
        }),

       ("_SQL.mul_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> (int,unit)_SQL.value"}),
       ("_SQL.mul_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> (word,unit)_SQL.value"}),
       ("_SQL.mul_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> (real,unit)_SQL.value"}),
       ("_SQL.mul_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((int)option,unit)_SQL.value"}),
       ("_SQL.mul_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((word)option,unit)_SQL.value"}),
       ("_SQL.mul_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((real)option,unit)_SQL.value"}),

       ("_SQL_div",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,('c)option},\
               \'c#{int,word}.\
               \('c,'a)_SQL.value\
               \ * ('c,'a)_SQL.value\
               \ -> ('c,'a)_SQL.value]",
          instances = [
            {instTyList = ["(int,unit)_SQL.value", "int", "_"],
             instance = EXTERNVAR "_SQL.div_int"},
            {instTyList = ["(word,unit)_SQL.value", "word", "_"],
             instance = EXTERNVAR "_SQL.div_word"},
            {instTyList = ["((int)option,unit)_SQL.value",
                           "(int)option", "int"],
             instance = EXTERNVAR "_SQL.div_intOption"},
            {instTyList = ["((word)option,unit)_SQL.value",
                           "(word)option", "word"],
             instance = EXTERNVAR "_SQL.div_wordOption"}
        ]
        }),

       ("_SQL.div_int",
        DUMMY {ty = "(int,unit)_SQL.value \
                    \ * (int,unit)_SQL.value\
                    \ -> (int,unit)_SQL.value"}),
       ("_SQL.div_word",
        DUMMY {ty = "(word,unit)_SQL.value \
                    \ * (word,unit)_SQL.value\
                    \ -> (word,unit)_SQL.value"}),
       ("_SQL.div_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value \
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((int)option,unit)_SQL.value"}),
       ("_SQL.div_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value \
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((word)option,unit)_SQL.value"}),

       ("_SQL_mod",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,('c)option},\
               \'c#{int,word}.\
               \('c,'a)_SQL.value\
               \ * ('c,'a)_SQL.value\
               \ -> ('c,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.mod_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.mod_word"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.mod_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.mod_wordOption"}
          ]
        }),

       ("_SQL.mod_int",
        DUMMY {ty = "(int,unit)_SQL.value \
                    \ * (int,unit)_SQL.value\
                    \ -> (int,unit)_SQL.value"}),
       ("_SQL.mod_word",
        DUMMY {ty = "(word,unit)_SQL.value \
                    \ * (word,unit)_SQL.value\
                    \ -> (word,unit)_SQL.value"}),
       ("_SQL.mod_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value \
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((int)option,unit)_SQL.value"}),
       ("_SQL.mod_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value \
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((word)option,unit)_SQL.value"}),

       ("_SQL_divr",
        OPRIM {
          ty = "['a,\
               \'b#{real,('c)option},\
               \'c#{real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ('b,'a)_SQL.value]",
          instances = [
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.div_real"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.div_realOption"}
        ]
        }),

       ("_SQL.div_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> (real,unit)_SQL.value"}),
       ("_SQL.div_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((real)option,unit)_SQL.value"}),

       ("_SQL_neg",
        OPRIM {
          ty = "['a,\
               \'b#{int,real,('c)option},\
               \'c#{int,real}.\
               \('b,'a)_SQL.value -> ('b,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.neg_int"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.neg_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.neg_intOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.neg_realOption"}
          ]
        }),

       ("_SQL.neg_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ -> (int,unit)_SQL.value"}),
       ("_SQL.neg_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ -> (real,unit)_SQL.value"}),
       ("_SQL.neg_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ -> ((int)option,unit)_SQL.value"}),
       ("_SQL.neg_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ -> ((real)option,unit)_SQL.value"}),

       ("_SQL_abs",
        OPRIM {
          ty = "['a,\
               \'b#{int,real,('c)option},\
               \'c#{int,real}.\
               \('b,'a)_SQL.value -> ('b,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.abs_int"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.abs_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.abs_intOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.abs_realOption"}
          ]
        }),

       ("_SQL.abs_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ -> (int,unit)_SQL.value"}),
       ("_SQL.abs_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ -> (real,unit)_SQL.value"}),
       ("_SQL.abs_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ -> ((int)option,unit)_SQL.value"}),
       ("_SQL.abs_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ -> ((real)option,unit)_SQL.value"}),

       ("_SQL_lt",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,char,string,real,('c)option},\
               \'c#{int,word,char,bool,string,real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ((bool)option,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.lt_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.lt_word"},
            {instTyList = ["char", "_"],
             instance = EXTERNVAR "_SQL.lt_char"},
            {instTyList = ["string", "_"],
             instance = EXTERNVAR "_SQL.lt_string"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.lt_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.lt_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.lt_wordOption"},
            {instTyList = ["(char)option", "char"],
             instance = EXTERNVAR "_SQL.lt_charOption"},
            {instTyList = ["(bool)option", "bool"],
             instance = EXTERNVAR "_SQL.lt_boolOption"},
            {instTyList = ["(string)option", "string"],
             instance = EXTERNVAR "_SQL.lt_stringOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.lt_realOption"}
           ]
        }),

       ("_SQL.lt_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_char",
        DUMMY {ty = "(char,unit)_SQL.value\
                    \ * (char,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_string",
        DUMMY {ty = "(string,unit)_SQL.value\
                    \ * (string,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_charOption",
        DUMMY {ty = "((char)option,unit)_SQL.value\
                    \ * ((char)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_boolOption",
        DUMMY {ty = "((bool)option,unit)_SQL.value\
                    \ * ((bool)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_stringOption",
        DUMMY {ty = "((string)option,unit)_SQL.value\
                    \ * ((string)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.lt_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),

       ("_SQL_gt",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,char,string,real,('c)option},\
               \'c#{int,word,char,bool,string,real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ((bool)option,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.gt_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.gt_word"},
            {instTyList = ["char", "_"],
             instance = EXTERNVAR "_SQL.gt_char"},
            {instTyList = ["string", "_"],
             instance = EXTERNVAR "_SQL.gt_string"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.gt_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.gt_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.gt_wordOption"},
            {instTyList = ["(char)option", "char"],
             instance = EXTERNVAR "_SQL.gt_charOption"},
            {instTyList = ["(bool)option", "bool"],
             instance = EXTERNVAR "_SQL.gt_boolOption"},
            {instTyList = ["(string)option", "string"],
             instance = EXTERNVAR "_SQL.gt_stringOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.gt_realOption"}
           ]
        }),

       ("_SQL.gt_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_char",
        DUMMY {ty = "(char,unit)_SQL.value\
                    \ * (char,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_string",
        DUMMY {ty = "(string,unit)_SQL.value\
                    \ * (string,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_charOption",
        DUMMY {ty = "((char)option,unit)_SQL.value\
                    \ * ((char)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_boolOption",
        DUMMY {ty = "((bool)option,unit)_SQL.value\
                    \ * ((bool)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_stringOption",
        DUMMY {ty = "((string)option,unit)_SQL.value\
                    \ * ((string)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.gt_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),

       ("_SQL_le",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,char,string,real,('c)option},\
               \'c#{int,word,char,bool,string,real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ((bool)option,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.le_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.le_word"},
            {instTyList = ["char", "_"],
             instance = EXTERNVAR "_SQL.le_char"},
            {instTyList = ["string", "_"],
             instance = EXTERNVAR "_SQL.le_string"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.le_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.le_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.le_wordOption"},
            {instTyList = ["(char)option", "char"],
             instance = EXTERNVAR "_SQL.le_charOption"},
            {instTyList = ["(bool)option", "bool"],
             instance = EXTERNVAR "_SQL.le_boolOption"},
            {instTyList = ["(string)option",
                           "string"],
             instance = EXTERNVAR "_SQL.le_stringOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.le_realOption"}
           ]
        }),

       ("_SQL.le_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_char",
        DUMMY {ty = "(char,unit)_SQL.value\
                    \ * (char,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_string",
        DUMMY {ty = "(string,unit)_SQL.value\
                    \ * (string,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_charOption",
        DUMMY {ty = "((char)option,unit)_SQL.value\
                    \ * ((char)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_boolOption",
        DUMMY {ty = "((bool)option,unit)_SQL.value\
                    \ * ((bool)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_stringOption",
        DUMMY {ty = "((string)option,unit)_SQL.value\
                    \ * ((string)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.le_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),

       ("_SQL_ge",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,char,string,real,('c)option},\
               \'c#{int,word,char,bool,string,real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ((bool)option,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.ge_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.ge_word"},
            {instTyList = ["char", "_"],
             instance = EXTERNVAR "_SQL.ge_char"},
            {instTyList = ["string", "_"],
             instance = EXTERNVAR "_SQL.ge_string"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.ge_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.ge_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.ge_wordOption"},
            {instTyList = ["(char)option", "char"],
             instance = EXTERNVAR "_SQL.ge_charOption"},
            {instTyList = ["(bool)option", "bool"],
             instance = EXTERNVAR "_SQL.ge_boolOption"},
            {instTyList = ["(string)option", "string"],
             instance = EXTERNVAR "_SQL.ge_stringOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.ge_realOption"}
           ]
        }),

       ("_SQL.ge_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_char",
        DUMMY {ty = "(char,unit)_SQL.value\
                    \ * (char,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_string",
        DUMMY {ty = "(string,unit)_SQL.value\
                    \ * (string,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_charOption",
        DUMMY {ty = "((char)option,unit)_SQL.value\
                    \ * ((char)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_boolOption",
        DUMMY {ty = "((bool)option,unit)_SQL.value\
                    \ * ((bool)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_stringOption",
        DUMMY {ty = "((string)option,unit)_SQL.value\
                    \ * ((string)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.ge_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),

       ("_SQL_eq",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,char,string,real,('c)option},\
               \'c#{int,word,char,bool,string,real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ((bool)option,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.eq_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.eq_word"},
            {instTyList = ["char", "_"],
             instance = EXTERNVAR "_SQL.eq_char"},
            {instTyList = ["string", "_"],
             instance = EXTERNVAR "_SQL.eq_string"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.eq_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.eq_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.eq_wordOption"},
            {instTyList = ["(char)option", "char"],
             instance = EXTERNVAR "_SQL.eq_charOption"},
            {instTyList = ["(bool)option", "bool"],
             instance = EXTERNVAR "_SQL.eq_boolOption"},
            {instTyList = ["(string)option", "string"],
             instance = EXTERNVAR "_SQL.eq_stringOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.eq_realOption"}
           ]
        }),

       ("_SQL.eq_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_char",
        DUMMY {ty = "(char,unit)_SQL.value\
                    \ * (char,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_string",
        DUMMY {ty = "(string,unit)_SQL.value\
                    \ * (string,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_charOption",
        DUMMY {ty = "((char)option,unit)_SQL.value\
                    \ * ((char)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_boolOption",
        DUMMY {ty = "((bool)option,unit)_SQL.value\
                    \ * ((bool)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_stringOption",
        DUMMY {ty = "((string)option,unit)_SQL.value\
                    \ * ((string)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.eq_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),

       ("_SQL_neq",
        OPRIM {
          ty = "['a,\
               \'b#{int,word,char,string,real,('c)option},\
               \'c#{int,word,char,bool,string,real}.\
               \('b,'a)_SQL.value\
               \ * ('b,'a)_SQL.value\
               \ -> ((bool)option,'a)_SQL.value]",
          instances = [
            {instTyList = ["int", "_"],
             instance = EXTERNVAR "_SQL.neq_int"},
            {instTyList = ["word", "_"],
             instance = EXTERNVAR "_SQL.neq_word"},
            {instTyList = ["char", "_"],
             instance = EXTERNVAR "_SQL.neq_char"},
            {instTyList = ["string", "_"],
             instance = EXTERNVAR "_SQL.neq_string"},
            {instTyList = ["real", "_"],
             instance = EXTERNVAR "_SQL.neq_real"},
            {instTyList = ["(int)option", "int"],
             instance = EXTERNVAR "_SQL.neq_intOption"},
            {instTyList = ["(word)option", "word"],
             instance = EXTERNVAR "_SQL.neq_wordOption"},
            {instTyList = ["(char)option", "char"],
             instance = EXTERNVAR "_SQL.neq_charOption"},
            {instTyList = ["(bool)option", "bool"],
             instance = EXTERNVAR "_SQL.neq_boolOption"},
            {instTyList = ["(string)option", "string"],
             instance = EXTERNVAR "_SQL.neq_stringOption"},
            {instTyList = ["(real)option", "real"],
             instance = EXTERNVAR "_SQL.neq_realOption"}
           ]
        }),

       ("_SQL.neq_int",
        DUMMY {ty = "(int,unit)_SQL.value\
                    \ * (int,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_word",
        DUMMY {ty = "(word,unit)_SQL.value\
                    \ * (word,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_char",
        DUMMY {ty = "(char,unit)_SQL.value\
                    \ * (char,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_string",
        DUMMY {ty = "(string,unit)_SQL.value\
                    \ * (string,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_real",
        DUMMY {ty = "(real,unit)_SQL.value\
                    \ * (real,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_intOption",
        DUMMY {ty = "((int)option,unit)_SQL.value\
                    \ * ((int)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_wordOption",
        DUMMY {ty = "((word)option,unit)_SQL.value\
                    \ * ((word)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_charOption",
        DUMMY {ty = "((char)option,unit)_SQL.value\
                    \ * ((char)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_boolOption",
        DUMMY {ty = "((bool)option,unit)_SQL.value\
                    \ * ((bool)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_stringOption",
        DUMMY {ty = "((string)option,unit)_SQL.value\
                    \ * ((string)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"}),
       ("_SQL.neq_realOption",
        DUMMY {ty = "((real)option,unit)_SQL.value\
                    \ * ((real)option,unit)_SQL.value\
                    \ -> ((bool)option,unit)_SQL.value"})
      ]

end
