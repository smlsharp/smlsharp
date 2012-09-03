(**
 * predefined type constructors and their data constructors.
 *
 * @copyright (c) 2006-2008, Tohoku University.
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @version $Id: PredefinedTypes.sml,v 1.2 2009/06/18 07:10:49 katsu Exp $
 *)
structure BuiltinContext : sig

  type context =
      {
        topTyConEnv: Types.topTyConEnv,
        topVarEnv: Types.topVarEnv,
        basicNameMap: NameMap.basicNameMap,
        topVarIDEnv: VarIDContext.topVarIDEnv,
        exceptionGlobalNameMap: string ExnTagID.Map.map,
        runtimeTyEnv : RuntimeTypes.ty TyConID.Map.map,
        interoperableKindMap : RuntimeTypes.interoperableKind TyConID.Map.map
      }

  val builtinContext : context
  val getTyCon : string -> Types.tyCon
  val getConPathInfo : string -> Types.conPathInfo
  val getExnPathInfo : string -> Types.exnPathInfo

end =
struct

  structure P = BuiltinPrimitive
  datatype decl = datatype BuiltinContextMaker.decl

  type context = BuiltinContextMaker.context

  val decls =
      [
       (* Having runtimeTy means that compiler deals with that types as
        * primitive types. In principle, types without runtimeTy are
        * compiled in the same way as user-defined data types.
        * "exn" and "exntag" are special case; exception support are
        * specially hard-coded in each compilation phase. *)

       ("bool",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = [
            {name="true", ty="bool", hasArg = false,
             tag = Constants.TAG_bool_true},
            {name="false", ty="bool", hasArg = false,
             tag = Constants.TAG_bool_false}
          ],
          runtimeTy = SOME RuntimeTypes.INTty,
          interoperable = RuntimeTypes.INTEROPERABLE
        }),

       ("int",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.INTty,
          interoperable = RuntimeTypes.INTEROPERABLE
        }),

       ("word",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.UINTty,
          interoperable = RuntimeTypes.INTEROPERABLE
        }),

       ("char",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.UCHARty,
          interoperable = RuntimeTypes.INTEROPERABLE
        }),

       (* In current implementation, "string" is used as both array and 
        * vector of "char". The only difference between array and vector
        * is runtime equality testing. In compiler internal, every string
        * value is dealt with as mutable except string constants. String
        * contants are immutable since they are placed at read-only data
        * section.
        * ToDo:  string should be an alias of "char vector." *)
       ("string",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.BOXEDty,
          interoperable = RuntimeTypes.EXPORT_ONLY
        }),

       ("real",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.DOUBLEty,
          interoperable = RuntimeTypes.INTEROPERABLE
        }),

       ("Real32.real",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.FLOATty,
          (* TODO: Due to lack of detail type information in backend phases,
           * we cannot distinct 32bit floats from 32bit integers. Fortunately
           * exporting float to C can be done in the same way as integers
           * on x86 ABI, however, importing cannot. For the time being,
           * we don't allow import floating point numbers. *)
          interoperable = RuntimeTypes.INTEROPERABLE_BUT_EXPORT_ONLY_ON_VM
        }),

       (* ref is compiled into an array with one element. *)
       ("ref",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [Types.NONEQ],
          constructors = [
            {name = "ref",
             ty = "['a.'a -> ('a) ref]",
             (* ref is treated specially; hasArg flag is not consulted *)
             hasArg = true,
             tag = Constants.TAG_ref_ref}
          ],
          runtimeTy = SOME RuntimeTypes.BOXEDty,
          interoperable = RuntimeTypes.EXPORT_ONLY
        }),

       ("list",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [Types.NONEQ],
          constructors = [
            {name="nil", ty="['a.('a) list]",
             hasArg = false, tag = Constants.TAG_list_nil},
            {name="::", ty="['a.'a * ('a) list -> ('a) list]",
             hasArg = true, tag = Constants.TAG_list_cons}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),

       (* In current implementation, "array" is used as both array and
        * vector. The only difference between array and vector is equality
        * testing. In compiler internal, every array value is dealt with as
        * mutable. *)
       ("array",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [Types.NONEQ],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.BOXEDty,
          interoperable = RuntimeTypes.EXPORT_ONLY
        }),

       ("IntInf.int",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.BOXEDty,
          interoperable = RuntimeTypes.EXPORT_ONLY
        }),

       (* "Word8.word" has same data representation as "char".
        * Currently we implement Word8Array and Word8Vector by "string" with
        * unsafe type cast. *)
       ("Word8.word",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.UCHARty,
          interoperable = RuntimeTypes.INTEROPERABLE
        }),

(*
       ("Word8Array.array",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = NONE,
          interoperable = true
        }),
*)

       ("unit",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.INTty,
          interoperable = RuntimeTypes.UNINTEROPERABLE
          (* user must use "int" for FFI *)
        }),

       ("ptr",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [Types.NONEQ],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.POINTERty,
          interoperable = RuntimeTypes.INTEROPERABLE
        }),

       ("option",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [Types.NONEQ],
          constructors = [
            {name = "NONE", ty = "['a.('a) option]",
             hasArg = false, tag = Constants.TAG_option_NONE},
            {name = "SOME", ty = "['a.'a -> ('a) option]",
             hasArg = true, tag = Constants.TAG_option_SOME}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),

       ("SMLSharp.SMLFormat.assocDirection",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = [
             {name="Left", ty = "assocDirection", hasArg = false, tag = 0},
             {name="Right", ty = "assocDirection", hasArg = false, tag = 2},
             {name="Neutral", ty = "assocDirection", hasArg = false, tag = 1}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),

       ("SMLSharp.SMLFormat.priority",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = [
             {name="Preferred", ty = "int -> priority", hasArg = true, tag = 1},
             {name="Deferred", ty = "priority", hasArg = false, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),

       ("SMLSharp.SMLFormat.expression",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = [
            {name="Term", ty = "(int * string) -> expression",
             hasArg = true, tag = 5},
            {name = "Newline", ty = "expression",
             hasArg = false, tag = 3},
            {name = "Guard",
             ty = "({cut:bool,strength:int,\
                  \direction:SMLSharp.SMLFormat.assocDirection})\
                  \ option * (expression) list -> expression",
             hasArg = true, tag = 1},
            {name = "Indicator",
             ty = "{space:bool,\
                  \newline:({priority:SMLSharp.SMLFormat.priority})\
                  \        option} \
                  \-> expression",
             hasArg = true, tag = 2},
            {name = "StartOfIndent", ty = "int -> expression",
             hasArg = true, tag = 4},
            {name = "EndOfIndent", ty = "expression",
             hasArg = false, tag = 0}
          ],
          runtimeTy = NONE,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),

       (* compiler doesn't maintain datacon and constructorHasArgFlagList of
        * "exn". Both datacon and constructorHasArgFlagList should be always
        * empty. *)
       ("exn",
        TYPE {
          eqKind = Types.NONEQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.BOXEDty,
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),

       (* ToDo: In current implementation, exception tag is integer
        * which compiler assigns for each exception statically. This
        * violates The Definition of Standard ML, which describes that
        * exception tag is "generative." In order for compilance to the
        * Definition, exception tag should be allocated at runtime by
        * allocating a new record in order to use its address as a tag.
        * Hence, exntag is one of primitive types for compiler and its
        * runtimeTy should be BOXEDty.
        *
        * Native code backend deals with exception tag as BOXEDty, but
        * Yamatodani's backend cannot do that. For the time being, we
        * introduce EXNTAGty of runtimeTy as a hack of dealing with
        * this condition. *)
       ("SMLSharp.exntag",
        TYPE {
          eqKind = Types.EQ,
          tyvars = [],
          constructors = nil,
          runtimeTy = SOME RuntimeTypes.EXNTAGty,  (* ToDo: should be BOXED *)
          interoperable = RuntimeTypes.UNINTEROPERABLE
        }),

       ("Bind",
        EXCEPTION {ty = "exn", hasArg = false,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Bind,
                   extern = "sml_exn_Bind"}),
       ("Match",
        EXCEPTION {ty = "exn", hasArg = false,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Match,
                   extern = "sml_exn_Match"}),
       ("Subscript",
        EXCEPTION {ty = "exn", hasArg = false,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Subscript,
                   extern = "sml_exn_Subscript"}),
       ("Size",
        EXCEPTION {ty = "exn", hasArg = false,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Size,
                   extern = "sml_exn_Size"}),
       ("Overflow",
        EXCEPTION {ty = "exn", hasArg = false,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Overflow,
                   extern = "sml_exn_Overflow"}),
       ("Div",
        EXCEPTION {ty = "exn", hasArg = false,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Div,
                   extern = "sml_exn_Div"}),
       ("Domain",
        EXCEPTION {ty = "exn", hasArg = false,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Domain,
                   extern = "sml_exn_Domain"}),
       ("Fail",
        EXCEPTION {ty = "string -> exn",  hasArg = true,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Fail,
                   extern = "sml_exn_Fail"}),
       ("OS.SysErr",
        EXCEPTION {ty = "string * (int)option -> exn", hasArg = true,
                   tag = ExnTagID.fromInt Constants.TAG_exn_SysErr,
                   extern = "sml_exn_SysErr"}),
       ("SMLSharp.MatchCompBug",
        EXCEPTION {ty = "string -> exn", hasArg = true,
                   tag = ExnTagID.fromInt Constants.TAG_exn_MatchCompBug,
                   extern = "sml_exn_MatchCompBug"}),
       ("SMLSharp.SMLFormat.Formatter",
        EXCEPTION {ty = "string -> exn", hasArg = true,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Formatter,
                   extern = "sml_exn_Formatter"}),
       ("SMLSharp.Bootstrap",
        EXCEPTION {ty = "exn", hasArg = false,
                   tag = ExnTagID.fromInt Constants.TAG_exn_Bootstrap,
                   extern = "sml_exn_Bootstrap"}),

       ("+",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real,word,Word8.word}.\
               \'a * 'a -> 'a]",
          instances = [
            {instTy = "int", name = P.P (P.Int_add P.NoOverflowCheck)},
            {instTy = "IntInf.int", name = P.P P.IntInf_add},
            {instTy = "real", name = P.P P.Real_add},
            {instTy = "Real32.real", name = P.P P.Float_add},
            {instTy = "word", name = P.P P.Word_add},
            {instTy = "Word8.word", name = P.P P.Byte_add}
          ]
        }),

       ("-",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real,word,Word8.word}.\
               \'a * 'a -> 'a]",
          instances = [
            {instTy = "int", name = P.P (P.Int_sub P.NoOverflowCheck)},
            {instTy = "IntInf.int", name = P.P P.IntInf_sub},
            {instTy = "real", name = P.P P.Real_sub},
            {instTy = "Real32.real", name = P.P P.Float_sub},
            {instTy = "word", name = P.P P.Word_sub},
            {instTy = "Word8.word", name = P.P P.Byte_sub}
          ]
        }),

       ("*",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real,word,Word8.word}.'a * 'a -> 'a]",
          instances = [
            {instTy = "int", name = P.P (P.Int_mul P.NoOverflowCheck)},
            {instTy = "IntInf.int", name = P.P P.IntInf_mul},
            {instTy = "real", name = P.P P.Real_mul},
            {instTy = "Real32.real", name = P.P P.Float_mul},
            {instTy = "word", name = P.P P.Word_mul},
            {instTy = "Word8.word", name = P.P P.Byte_mul}
         ]
        }),

       ("div",
        OPRIM {
          ty = "['a#{int,IntInf.int,word,Word8.word}.'a * 'a -> 'a]",
          instances = [
            {instTy = "int", name = P.P (P.Int_div P.NoOverflowCheck)},
            {instTy = "IntInf.int", name = P.P P.IntInf_div},
            {instTy = "word", name = P.P P.Word_div},
            {instTy = "Word8.word", name = P.P P.Byte_div}
          ]
        }),

       ("mod",
        OPRIM {
          ty = "['a#{int,IntInf.int,word,Word8.word}.'a * 'a -> 'a]",
          instances = [
            {instTy = "int", name = P.P (P.Int_mod P.NoOverflowCheck)},
            {instTy = "IntInf.int", name = P.P P.IntInf_mod},
            {instTy = "word", name = P.P P.Word_mod},
            {instTy = "Word8.word", name = P.P P.Byte_mod}
          ]
        }),

       ("/",
        OPRIM {
          ty = "['a#{real,Real32.real}.'a * 'a -> 'a]",
          instances = [
            {instTy = "real", name = P.P P.Real_div},
            {instTy = "Real32.real", name = P.P P.Float_div}
          ]
        }),

       ("~",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real}.'a -> 'a]",
          instances = [
            {instTy = "int", name = P.P (P.Int_neg P.NoOverflowCheck)},
            {instTy = "IntInf.int", name = P.P P.IntInf_neg},
            {instTy = "real", name = P.P P.Real_neg},
            {instTy = "Real32.real", name = P.P P.Float_neg}
          ]
        }),

       ("abs",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real}.'a -> 'a]",
          instances = [
            {instTy = "int", name = P.P (P.Int_abs P.NoOverflowCheck)},
            {instTy = "IntInf.int", name = P.P P.IntInf_abs},
            {instTy = "real", name = P.P P.Real_abs},
            {instTy = "Real32.real", name = P.P P.Float_abs}
          ]
        }),

       ("<",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real,word,Word8.word,\
               \char,string}.'a * 'a -> bool]",
          instances = [
            {instTy = "int", name = P.P P.Int_lt},
            {instTy = "IntInf.int", name = P.P P.IntInf_lt},
            {instTy = "real", name = P.P P.Real_lt},
            {instTy = "Real32.real", name = P.P P.Float_lt},
            {instTy = "word", name = P.P P.Word_lt},
            {instTy = "Word8.word", name = P.P P.Byte_lt},
            {instTy = "char", name = P.P P.Char_lt},
            {instTy = "string", name = P.P P.String_lt}
          ]
        }),

       (">",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real,word,Word8.word,\
               \char,string}.'a * 'a -> bool]",
          instances = [
            {instTy = "int", name = P.P P.Int_gt},
            {instTy = "IntInf.int", name = P.P P.IntInf_gt},
            {instTy = "real", name = P.P P.Real_gt},
            {instTy = "Real32.real", name = P.P P.Float_gt},
            {instTy = "word", name = P.P P.Word_gt},
            {instTy = "Word8.word", name = P.P P.Byte_gt},
            {instTy = "char", name = P.P P.Char_gt},
            {instTy = "string", name = P.P P.String_gt}
         ]
        }),

       ("<=",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real,word,Word8.word,\
               \char,string}.'a * 'a -> bool]",
          instances = [
            {instTy = "int", name = P.P P.Int_lteq},
            {instTy = "IntInf.int", name = P.P P.IntInf_lteq},
            {instTy = "real", name = P.P P.Real_lteq},
            {instTy = "Real32.real", name = P.P P.Float_lteq},
            {instTy = "word", name = P.P P.Word_lteq},
            {instTy = "Word8.word", name = P.P P.Byte_lteq},
            {instTy = "char", name = P.P P.Char_lteq},
            {instTy = "string", name = P.P P.String_lteq}
          ]
        }),

       (">=",
        OPRIM {
          ty = "['a#{int,IntInf.int,real,Real32.real,word,Word8.word,\
               \char,string}.'a * 'a -> bool]",
          instances = [
            {instTy = "int", name = P.P P.Int_gteq},
            {instTy = "IntInf.int", name = P.P P.IntInf_gteq},
            {instTy = "real", name = P.P P.Real_gteq},
            {instTy = "Real32.real", name = P.P P.Float_gteq},
            {instTy = "word", name = P.P P.Word_gteq},
            {instTy = "Word8.word", name = P.P P.Byte_gteq},
            {instTy = "char", name = P.P P.Char_gteq},
            {instTy = "string", name = P.P P.String_gteq}
          ]
        }),

       ("!!",
        OPRIM {
          ty = "['a#{int,real,Real32.real,word,Word8.word,char}.\
               \('a) ptr -> 'a]",
          instances = [
            {instTy = "int", name = P.P P.Ptr_deref_int},
            {instTy = "real", name = P.P P.Ptr_deref_real},
            {instTy = "Real32.real", name = P.P P.Ptr_deref_float},
            {instTy = "word", name = P.P P.Ptr_deref_word},
            {instTy = "Word8.word", name = P.P P.Ptr_deref_byte},
            {instTy = "char", name = P.P P.Ptr_deref_char}
          ]
        }),

       (":=", PRIM (P.S P.Assign)),
       ("SMLSharp.PrimArray.array", PRIM (P.S P.Array_array)),
       ("SMLSharp.PrimArray.vector", PRIM (P.S P.Array_vector)),
       ("SMLSharp.PrimArray.sub_unsafe", PRIM (P.S P.Array_sub_unsafe)),
       ("SMLSharp.PrimArray.update_unsafe", PRIM (P.S P.Array_update_unsafe)),
       ("SMLSharp.PrimArray.copy_unsafe", PRIM (P.S P.Array_copy_unsafe)),
       ("=", PRIM (P.P P.PolyEqual)),
       (* ("ObjectEqual", PRIM (P.P P.ObjectEqual)), *)
       (* ("PointerEqual", PRIM (P.P P.PointerEqual)), *)
       ("SMLSharp.PrimArray.length", PRIM (P.P P.Array_length)),
       (* ("Byte_add", PRIM (P.P P.Byte_add)), *)
       (* ("Byte_div", PRIM (P.P P.Byte_div)), *)
       (* ("Byte_equal", PRIM (P.P P.Byte_equal)), *)
       ("Word8.fromInt", PRIM (P.P P.Byte_fromInt)),
       (* ("Byte_gt", PRIM (P.P P.Byte_gt)), *)
       (* ("Byte_gteq", PRIM (P.P P.Byte_gteq)), *)
       (* ("Byte_lt", PRIM (P.P P.Byte_lt)), *)
       (* ("Byte_lteq", PRIM (P.P P.Byte_lteq)), *)
       (* ("Byte_mod", PRIM (P.P P.Byte_mod)), *)
       (* ("Byte_mul", PRIM (P.P P.Byte_mul)), *)
       (* ("Byte_sub", PRIM (P.P P.Byte_sub)), *)
       ("Word8.toIntX", PRIM (P.P P.Byte_toIntX)),
       ("Char.chr_unsafe", PRIM (P.P P.Char_chr_unsafe)),
       (* ("Char_equal", PRIM (P.P P.Char_equal)), *)
       (* ("Char_gt", PRIM (P.P P.Char_gt)), *)
       (* ("Char_gteq", PRIM (P.P P.Char_gteq)), *)
       (* ("Char_lt", PRIM (P.P P.Char_lt)), *)
       (* ("Char_lteq", PRIM (P.P P.Char_lteq)), *)
       ("Char.ord", PRIM (P.P P.Char_ord)),
       (* ("Float_abs", PRIM (P.P P.Float_abs)), *)
       (* ("Float_add", PRIM (P.P P.Float_add)), *)
       (* ("Float_div", PRIM (P.P P.Float_div)), *)
       ("Real32.==", PRIM (P.P P.Float_equal)),
       ("Real32.fromInt", PRIM (P.P P.Float_fromInt)),
       ("Real32.fromReal", PRIM (P.P P.Float_fromReal)),
       (* ("Float_gt", PRIM (P.P P.Float_gt)), *)
       (* ("Float_gteq", PRIM (P.P P.Float_gteq)), *)
       (* ("Float_lt", PRIM (P.P P.Float_lt)), *)
       (* ("Float_lteq", PRIM (P.P P.Float_lteq)), *)
       (* ("Float_mul", PRIM (P.P P.Float_mul)), *)
       (* ("Float_neg", PRIM (P.P P.Float_neg)), *)
       (* ("Float_sub", PRIM (P.P P.Float_sub)), *)
       ("Real32.toReal", PRIM (P.P P.Float_toReal)),
       ("Real32.trunc_unsafe", PRIM (P.P (P.Float_trunc_unsafe P.NoOverflowCheck))),
       (* ("IntInf_abs", PRIM (P.P P.IntInf_abs)), *)
       (* ("IntInf_add", PRIM (P.P P.IntInf_add)), *)
       (* ("IntInf_div", PRIM (P.P P.IntInf_div)), *)
       (* ("IntInf_equal", PRIM (P.P P.IntInf_equal)), *)
       (* ("IntInf_gt", PRIM (P.P P.IntInf_gt)), *)
       (* ("IntInf_gteq", PRIM (P.P P.IntInf_gteq)), *)
       (* ("IntInf_lt", PRIM (P.P P.IntInf_lt)), *)
       (* ("IntInf_lteq", PRIM (P.P P.IntInf_lteq)), *)
       (* ("IntInf_mod", PRIM (P.P P.IntInf_mod)), *)
       (* ("IntInf_mul", PRIM (P.P P.IntInf_mul)), *)
       (* ("IntInf_neg", PRIM (P.P P.IntInf_neg)), *)
       (* ("IntInf_sub", PRIM (P.P P.IntInf_sub)), *)
       (* ("Int_abs", PRIM (P.P (P.Int_abs P.NoOverflowCheck))), *)
       (* ("Int_add", PRIM (P.P (P.Int_add P.NoOverflowCheck))), *)
       (* ("Int_div", PRIM (P.P (P.Int_div P.NoOverflowCheck))), *)
       (* ("Int_equal", PRIM (P.P P.Int_equal)), *)
       (* ("Int_gt", PRIM (P.P P.Int_gt)), *)
       (* ("Int_gteq", PRIM (P.P P.Int_gteq)), *)
       (* ("Int_lt", PRIM (P.P P.Int_lt)), *)
       (* ("Int_lteq", PRIM (P.P P.Int_lteq)), *)
       (* ("Int_mod", PRIM (P.P (P.Int_mod P.NoOverflowCheck))), *)
       (* ("Int_mul", PRIM (P.P (P.Int_mul P.NoOverflowCheck))), *)
       (* ("Int_neg", PRIM (P.P (P.Int_neg P.NoOverflowCheck))), *)
       ("Int.quot", PRIM (P.P (P.Int_quot P.NoOverflowCheck))),
       ("Int.rem", PRIM (P.P (P.Int_rem P.NoOverflowCheck))),
       (* ("Int_sub", PRIM (P.P (P.Int_sub P.NoOverflowCheck))), *)
       (* ("Ptr_deref_int", PRIM (P.P P.Ptr_deref_int)), *)
       (* ("Ptr_deref_real", PRIM (P.P P.Ptr_deref_real)), *)
       (* ("Ptr_deref_float", PRIM (P.P P.Ptr_deref_float)), *)
       (* ("Ptr_deref_word", PRIM (P.P P.Ptr_deref_word)), *)
       (* ("Ptr_deref_char", PRIM (P.P P.Ptr_deref_char)), *)
       (* ("Ptr_deref_byte", PRIM (P.P P.Ptr_deref_byte)), *)
       (* ("Real_abs", PRIM (P.P P.Real_abs)), *)
       (* ("Real_add", PRIM (P.P P.Real_add)), *)
       ("Real.==", PRIM (P.P P.Real_equal)),
       ("Real.fromInt", PRIM (P.P P.Real_fromInt)),
       (* ("Real_gt", PRIM (P.P P.Real_gt)), *)
       (* ("Real_gteq", PRIM (P.P P.Real_gteq)), *)
       (* ("Real_lt", PRIM (P.P P.Real_lt)), *)
       (* ("Real_lteq", PRIM (P.P P.Real_lteq)), *)
       (* ("Real_mul", PRIM (P.P P.Real_mul)), *)
       (* ("Real_neg", PRIM (P.P P.Real_neg)), *)
       (* ("Real_sub", PRIM (P.P P.Real_sub)), *)
       ("Real.trunc_unsafe", PRIM (P.P (P.Real_trunc_unsafe P.NoOverflowCheck))),
       ("SMLSharp.PrimString.array", PRIM (P.P P.String_array)),
       ("SMLSharp.PrimString.copy_unsafe", PRIM (P.P P.String_copy_unsafe)),
       (* ("String_equal", PRIM (P.P P.String_equal)), *)
       (* ("String_gt", PRIM (P.P P.String_gt)), *)
       (* ("String_gteq", PRIM (P.P P.String_gteq)), *)
       (* ("String_lt", PRIM (P.P P.String_lt)), *)
       (* ("String_lteq", PRIM (P.P P.String_lteq)), *)
       ("SMLSharp.PrimString.size", PRIM (P.P P.String_size)),
       ("SMLSharp.PrimString.sub_unsafe", PRIM (P.P P.String_sub_unsafe)),
       ("SMLSharp.PrimString.update_unsafe", PRIM (P.P P.String_update_unsafe)),
       ("SMLSharp.PrimString.vector", PRIM (P.P P.String_vector)),
       (* ("Word_add", PRIM (P.P P.Word_add)), *)
       ("Word.andb", PRIM (P.P P.Word_andb)),
       ("Word.~>>", PRIM (P.P P.Word_arshift)),
       (* ("Word_div", PRIM (P.P P.Word_div)), *)
       (* ("Word_equal", PRIM (P.P P.Word_equal)), *)
       ("Word.fromInt", PRIM (P.P P.Word_fromInt)),
       (* ("Word_gt", PRIM (P.P P.Word_gt)), *)
       (* ("Word_gteq", PRIM (P.P P.Word_gteq)), *)
       ("Word.<<", PRIM (P.P P.Word_lshift)),
       (* ("Word_lt", PRIM (P.P P.Word_lt)), *)
       (* ("Word_lteq", PRIM (P.P P.Word_lteq)), *)
       (* ("Word_mod", PRIM (P.P P.Word_mod)), *)
       (* ("Word_mul", PRIM (P.P P.Word_mul)), *)
       ("Word.notb", PRIM (P.P P.Word_notb)),
       ("Word.orb", PRIM (P.P P.Word_orb)),
       ("Word.>>", PRIM (P.P P.Word_rshift)),
       (* ("Word_sub", PRIM (P.P P.Word_sub)), *)
       ("Word.toIntX", PRIM (P.P P.Word_toIntX)),
       ("Word.xorb", PRIM (P.P P.Word_xorb)),

       (* placeholder for printer generator *)
       ("SMLSharp.printFormat",
        DUMMY {ty = "SMLSharp.SMLFormat.expression -> unit"}),
       ("SMLSharp.printFormatOfValBinding",
        DUMMY {ty = "string * SMLSharp.SMLFormat.expression\
                    \ * SMLSharp.SMLFormat.expression -> unit"}),
       ("_format_bool",
        DUMMY {ty = "bool -> SMLSharp.SMLFormat.expression"}),
       ("_format_int",
        DUMMY {ty = "int -> SMLSharp.SMLFormat.expression"}),
       ("_format_word",
        DUMMY {ty = "word -> SMLSharp.SMLFormat.expression"}),
       ("_format_char",
        DUMMY {ty = "char -> SMLSharp.SMLFormat.expression"}),
       ("_format_string",
        DUMMY {ty = "string -> SMLSharp.SMLFormat.expression"}),
       ("_format_real",
        DUMMY {ty = "real -> SMLSharp.SMLFormat.expression"}),
       ("Real32._format_real",
        DUMMY {ty = "Real32.real -> SMLSharp.SMLFormat.expression"}),
       ("_format_ref",
        DUMMY {ty = "['a.('a)ref -> SMLSharp.SMLFormat.expression]"}),
       ("_format_list",
        DUMMY {ty = "['a.('a)list -> SMLSharp.SMLFormat.expression]"}),
       ("_format_array",
        DUMMY {ty = "['a.('a)array -> SMLSharp.SMLFormat.expression]"}),
       ("IntInf._format_int",
        DUMMY {ty = "IntInf.int -> SMLSharp.SMLFormat.expression"}),
       ("Word8._format_word",
        DUMMY {ty = "Word8.word -> SMLSharp.SMLFormat.expression"}),
(*
       ("Word8Array._format_array",
        DUMMY {ty = "Word8Array.array -> SMLSharp.SMLFormat.expression"}),
*)
(*
       ("_format_unit",
        DUMMY {ty = "unit -> SMLSharp.SMLFormat.expression"}),
*)
       ("_format_ptr",
        DUMMY {ty = "['a.('a)ptr -> SMLSharp.SMLFormat.expression]"}),
       ("_format_option",
        DUMMY {ty = "['a.('a)option -> SMLSharp.SMLFormat.expression]"}),
       ("SMLSharp.SMLFormat._format_assocDirection",
        DUMMY {ty = "SMLSharp.SMLFormat.assocDirection\
                    \ -> SMLSharp.SMLFormat.expression"}),
       ("SMLSharp.SMLFormat._format_priority",
        DUMMY {ty = "SMLSharp.SMLFormat.priority\
                    \ -> SMLSharp.SMLFormat.expression"}),
       ("SMLSharp.SMLFormat._format_expression",
        DUMMY {ty = "SMLSharp.SMLFormat.expression\
                    \ -> SMLSharp.SMLFormat.expression"}),
       ("_format_exn",
        DUMMY {ty = "exn -> SMLSharp.SMLFormat.expression"}),
       ("SMLSharp._format_exntag",
        DUMMY {ty = "SMLSharp.exntag -> SMLSharp.SMLFormat.expression"}),
       ("_format_exnRef",
        DUMMY {ty = "(exn -> SMLSharp.SMLFormat.expression) ref"})
     ]

  val builtinContext =
      foldl (fn (x,z) => BuiltinContextMaker.define z x)
            BuiltinContextMaker.emptyContext
            decls

  fun getTyCon name =
      BuiltinContextMaker.getTyCon (builtinContext, name)
  fun getConPathInfo name =
      BuiltinContextMaker.getConPathInfo (builtinContext, name)
  fun getExnPathInfo name =
      BuiltinContextMaker.getExnPathInfo (builtinContext, name)

end
