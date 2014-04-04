(**
 * Utility functions for formatting terms using SMLFormat.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
(* ToDo:
 * This is a replacement of SmlppgUtil.ppg. After rewriting all formatters,
 * SmlppgUtil.ppg should be removed.
 *)

structure TermFormat :> sig

  type format = SMLFormat.FormatExpression.expression list
  type 'a formatter = 'a -> format

  (* due to restriction of SMLFormat, types of parameters for a formatter
   * must be of the form 'a list. *)
  type 'a formatParam = 'a list

  (*
   * formatting lists:
   *                         nil      one        many
   * formatEnclosedList      ()       (1)        (1, 2, 3, ..., n)
   * formatAppList           ()        1         (1, 2, 3, ..., n)
   * formatSeqList                     1         (1, 2, 3, ..., n)
   * formatOptionalList               (1)        (1, 2, 3, ..., n)
   * formatDeclList                   (1         (1,2,3,...,n
   * formatCaseList          ()       (1,)       (1,2,3,...,n,)
   * (basic formatter)                 1          1,2,3,...,n
   *)
  val formatEnclosedList
      : 'a formatter * format * format * format -> 'a list formatter
  val formatAppList
      : 'a formatter * format * format * format -> 'a list formatter
  val formatSeqList
      : 'a formatter * format * format * format -> 'a list formatter
  val formatOptionalList
      : 'a formatter * format * format * format -> 'a list formatter
  val formatDeclList
      : 'a formatter * format * format -> 'a list formatter
  val formatCaseList
      : 'a formatter * format * format * format -> 'a list formatter

  (*
   * formatting options:
   *                         NONE      SOME x
   * formatEnclosedOption    ()        (x)
   * formatOptinalOption               (x)
   * (basic formatter)                  x
   *)
  val formatEnclosedOption
      : ('a formatter * format * format) -> 'a option formatter
  val formatOptionalOption
      : ('a formatter * format * format) -> 'a option formatter

  (*
   * formatting maps:
   *                         empty    one          many
   * formatEnclosedMap       {}       {k1 = v1}    {k1 = v1, ..., kn = vn}
   *)
  val formatEnclosedMap
      : 'k formatter -> ('a -> ('k * 'v) list)
        -> 'v formatter * format * format * format * format
        -> 'a formatter

  val formatEnclosedSEnv
      : 'a formatter * format * format * format * format
        -> 'a SEnv.map formatter

  val formatEnclosedLabelEnv
      : 'a formatter * format * format * format * format
        -> 'a LabelEnv.map formatter

  val formatEnclosedSEnvPlain
      : 'a formatter * format * format -> 'a SEnv.map formatter

  val formatEnclosedSymbolEnvPlain
      : 'a formatter * format * format -> 'a SymbolEnv.map formatter


  (* formatting records and tuples *)
  val isTuple : 'a LabelEnv.map -> bool
  val formatRecordExp : 'a formatter -> 'a LabelEnv.map formatter
  val formatRecordTy : 'a formatter -> 'a LabelEnv.map formatter

  (* for fine-tuning *)
  val formatIfCons : format -> 'a list formatter

  (* for fine-tuning *)
  val formatIfList : format -> 'a list formatter

  (* for fine-tuning *)
  val formatIfNonEmpty : format -> 'a SEnv.map formatter

  (* for fine-tuning *)
  val formatIfEmpty : format -> 'a SEnv.map formatter

  (* for fine-tuning *)
  val formatIfNonEmptySymbolMap : format -> 'a SymbolEnv.map formatter

  (* for fine-tuning *)
  val formatIfEmptySymbolMap : format -> 'a SymbolEnv.map formatter

  val formatIfEmptyFormat : (format * format) -> format -> format

  (* formatting bound type variables *)
  type 'kind btvEnv'
  type 'kind btvEnv = 'kind btvEnv' formatParam
  val emptyBtvEnv : 'k btvEnv
  val makeBtvEnv : 'k BoundTypeVarID.Map.map -> 'k btvEnv
  val extendBtvEnv : 'k btvEnv -> 'k BoundTypeVarID.Map.map -> 'k btvEnv
  val extendBtvEnvWithOrder :
      'k btvEnv -> 'k BoundTypeVarID.Map.map * BoundTypeVarID.id list
      -> 'k btvEnv
  val formatBoundTyvar : (format -> 'k formatter) -> 'k btvEnv
                         -> BoundTypeVarID.id formatter
  val btvName : int -> string
  val formatBtvEnv : (format -> 'k formatter) -> 'k btvEnv ->
                     'k BoundTypeVarID.Map.map formatter
  val formatBtvEnvWithType : (format -> 'k formatter) -> 'k btvEnv ->
                     'k BoundTypeVarID.Map.map formatter
  val formatFreeTyvar : FreeTypeVarID.id formatter
  val ftvName : int -> string

  (* formatting constant literals *)
  val format_BigInt_dec_ML : BigInt.int -> format
(*
  val format_Int64_dec_ML : Int64.int -> format
*)
  val format_Int32_dec_ML : Int32.int -> format
  val format_int_dec_ML : int -> format
(*
  val format_Word64_hex_ML : Word64.word -> format
*)
  val format_Word32_hex_ML : Word32.word -> format
  val format_Word8_hex_ML : Word8.word -> format
  val format_word_hex_ML : word -> format
  val format_string_ML : string -> format
  val format_char_ML : char -> format

(*
  val format_Int64_dec_C : Int64.int -> format
*)
  val format_Int32_dec_C : Int32.int -> format
  val format_int_dec_C : int -> format
(*
  val format_Word64_hex_C : Word64.word -> format
*)
  val format_Word32_hex_C : Word32.word -> format
  val format_Word8_hex_C : Word8.word -> format
  val format_word_hex_C : word -> format
  val format_string_C : string -> format
  val format_char_C : char -> format

  (* combinators for writing formatters by hand *)
  structure FormatComb : sig
    type 'a fmt
    type ('a,'b) comb
    val begin_ : (format, 'n) comb -> 'n
    val end_ : ('r, 'r) comb
    val text : ('r, string -> ('r,'n) comb -> 'n) comb
    val space : ('r, ('r,'n) comb -> 'n) comb
    val dspace : ('r, ('r,'n) comb -> 'n) comb
    val newline : ('r, ('r,'n) comb -> 'n) comb
    val $ : ('r, format -> ('r,'n) comb -> 'n) comb
    val guard_ : ('r, SMLFormat.FormatExpression.assoc option
                      -> (('r,'c) comb -> 'c, 'n) comb -> 'n) comb
    val nest_ : ('r, int -> (('r,'c) comb -> 'c, 'n) comb -> 'n) comb

    val puts : (format, (unit, 'n) comb -> 'n) comb
    val int : int formatter
    val word : word formatter
    val string : string formatter
    val term : string -> format
    val list : 'a formatter -> 'a list formatter
    val assocList : 'k formatter * 'v formatter -> ('k * 'v) list formatter
    val record : (string * format) list formatter
    val tuple2 : 't1 formatter * 't2 formatter -> ('t1 * 't2) formatter
    val tuple3 : 't1 formatter * 't2 formatter * 't3 formatter
                 -> ('t1 * 't2 * 't3) formatter
    val tuple4 : 't1 formatter * 't2 formatter * 't3 formatter * 't4 formatter
                 -> ('t1 * 't2 * 't3 * 't4) formatter
  end

  (* for debug *)
  val formatFormat : format -> format
end =
struct
  (*
   * == Guideline for writing formatters for terms
   *
   * guard precedence for types:
   *  L9 { x ^ y }       annotation for types
   *  L8 { x y }         type application
   *  N5 {!N6 { x * y }} tuple type
   *  R4 { x -> y }      function type
   *
   * guard precedence for expressions:
   *  L9 { e }           special terms (if needed)
   *  L8 { x y }         function application
   *  L2 { x : y }       type annotation
   *  R1 { x => y }      abstraction, let, switch, handle, raise, binding
   *  "(" !N0 { x ")" }  cut
   *
   * - Precedence 0 is reserved for cut.
   * - Don't use guards immoderately; they easily corrupt the result.
   *   Basic storategies for putting guards are as follows:
   *   - Start a guard only at immediately after a left parenthesize.
   *   - End a guard only at immediately after (or before) a right parenthesize.
   *   - If a term may be surrounded by parenthesizes depending on
   *     associatibitity, put a guard with association surrounding the
   *     whole of the formatter for the term.
   *   - Putting guards at any other place is just for fine-tuning.
   * - Recommended space (and break) indicators are only +1 and +d.
   *   Any other space indicators are just for fine-tuning.
   *
   * == Templates
   *
   * Type annotation:
   *   L2{ FORMAT +1 ":" +d FORMAT }
   * Application:
   *   L8{ 2[ FORMAT +1 FORMAT ] }
   * Parenthesizes:
   *   "(" !N0{ FORMAT ")" }
   * Type Application:
   *   L8{ 2[ FORMAT instTys:optionalList(instTy)(+1 "{",",","}") ] }
   *)

  open SMLFormat.FormatExpression
  type format = expression list
  type 'a formatter = 'a -> format
  type 'a formatParam = 'a list

  val sp = Indicator {space=true, newline=SOME {priority=Preferred 1}}
  val dsp = Indicator {space=true, newline=SOME {priority=Deferred}}
  val cutAssoc = SOME {cut=true, strength=0, direction=Neutral}
  val tupleAssoc = SOME {cut=false, strength=5, direction=Neutral}
  val tupleInnerAssoc = SOME {cut=true, strength=6, direction=Neutral}
  fun term s = Term (size s, s)
  val commaSpace = [term ",", sp]
  val comma = [term ","]
  fun nest level l = StartOfIndent level :: l @ [EndOfIndent]

  (**** combinators for writing format expressions by hand ****)

  structure FormatComb =
  struct
    datatype 'a fmt = A of (format -> format) * (format -> 'a)
    type ('a,'b) comb = 'a fmt -> 'b
    fun begin_ k = k (A (fn t => t, fn exp => exp))
    fun end_ (A (fmt, last)) = last (fmt nil)
    fun text (A (fmt, last)) s k = k (A (fn t => fmt (term s :: t), last))
    fun space (A (fmt, last)) k = k (A (fn t => fmt (sp :: t), last))
    fun dspace (A (fmt, last)) k = k (A (fn t => fmt (dsp :: t), last))
    fun newline (A (fmt, last)) k = k (A (fn t => fmt (Newline :: t), last))
    fun $ (A (fmt, last)) exp k = k (A (fn t => fmt (exp @ t), last))
    fun guardEnd (A (fmt, last)) assoc result k =
        k (A (fn t => fmt (Guard (assoc, result) :: t), last))
    fun guard_ accum assoc k =
        k (A (fn t => t, guardEnd accum assoc))
    fun nestEnd (A (fmt, last)) level result k =
        k (A (fn t => fmt (nest level result @ t), last))
    fun nest_ accum level k =
        k (A (fn t => t, nestEnd accum level))
  end
  open FormatComb

  fun intersperse sep nil = nil
    | intersperse sep [x] = x
    | intersperse sep (h::t) = h @ sep @ intersperse sep t

  (**** formatters for basic types ****)
  fun formatEnclosedList (formatter, lparen, comma, rparen) elems =
      begin_
        $lparen
        guard_ cutAssoc
          $(intersperse (comma @ [sp]) (map formatter elems))
          $rparen
        end_
      end_
(*
  fun formatEnclosedList (formatter, lparen, comma, rparen) elems =
      begin_
        $lparen
          $(intersperse (comma @ [sp]) (map formatter elems))
        $rparen
      end_
*)

  fun formatAppList (formatter, lparen, comma, rparen) nil = lparen @ rparen
    | formatAppList (formatter, lparen, comma, rparen) [x] = formatter x
    | formatAppList args elems = formatEnclosedList args elems

  fun formatSeqList (formatter, lparen, comma, rparen) nil = nil
    | formatSeqList (formatter, lparen, comma, rparen) [x] = formatter x
    | formatSeqList args elems = formatEnclosedList args elems

  fun formatOptionalList (formatter, lparen, comma, rparen) nil = nil
    | formatOptionalList args elems = formatEnclosedList args elems

  fun formatDeclList (formatter, head, sep) nil = nil
    | formatDeclList (formatter, head, sep) (elem::elems) =
      head @ formatter elem
      @ List.concat (map (fn x => sep @ formatter x) elems)

  fun formatCaseList (formatter, head, sep, last) nil = head @ last
    | formatCaseList (formatter, head, sep, last) elems =
      head @ foldr (fn (x,z) => formatter x @ sep @ z) last elems

  fun formatEnclosedOption (formatter, lparen, rparen) NONE = lparen @ rparen
    | formatEnclosedOption (formatter, lparen, rparen) (SOME x) =
      lparen @ formatter x @ rparen

  fun formatOptionalOption (formatter, lparen, rparen) NONE = nil
    | formatOptionalOption (formatter, lparen, rparen) (SOME x) =
      lparen @ formatter x @ rparen

  fun keyValuePair (key, mapsto, value) =
      begin_
        guard_ NONE
          $key $mapsto nest_ 2 space $value end_
        end_
      end_

  fun formatEnclosedMap formatKey listItemsi
                        (format, lparen, comma, mapsto, rparen) map =
      formatEnclosedList
        (fn (key, value) =>
            keyValuePair (formatKey key, mapsto, format value),
         lparen, comma, rparen)
        (listItemsi map)

  fun formatEnclosedSEnv args map =
      formatEnclosedMap (fn x => [term x]) SEnv.listItemsi args map

  fun formatEnclosedLabelEnv args map =
      formatEnclosedMap (fn x => [term x]) LabelEnv.listItemsi args map

  fun formatEnclosedList (formatter, lparen, comma, rparen) elems =
      begin_
        $lparen
        guard_ cutAssoc
          $(intersperse (comma @ [sp]) (map formatter elems))
          $rparen
        end_
      end_

  fun formatEnclosedSEnvPlain (formatter, comma, mapsto) senv =
      formatDeclList
        (fn (string, value) =>
            begin_
              nest_ 1
                 $[term string]
                 $mapsto
                 $(formatter value)
              end_
            end_,
         comma,
         comma
        )
        (SEnv.listItemsi senv)

  fun formatEnclosedSymbolEnvPlain (formatter, comma, mapsto) senv =
      formatDeclList
        (fn (symbol, value) =>
            begin_
              nest_ 1
                 $(Symbol.format_symbol symbol)
                 $mapsto
                 $(formatter value)
              end_
            end_,
         comma,
         comma
        )
        (SymbolEnv.listItemsi senv)
     
  structure FormatComb =
  struct
    open FormatComb
    fun assocList (formatKey, formatValue) pairs =
        formatEnclosedMap
          formatKey (fn x => x)
          (formatValue, [term "{"], [term ","], [dsp,term "=>"], [term "}"])
          pairs
    fun record fields =
        formatEnclosedList
          (fn (key, value) => keyValuePair ([term key], [dsp,term "="], value),
           [term "{"], [term ","], [term "}"])
          fields
  end

  (**** formatter for records ****)

  fun isTuple smap =
      let
        val (n, result) =
            LabelEnv.foldli
              (fn (k,v,(n,z)) => (n + 1, z andalso k = Int.toString n))
              (1, true)
              smap
      in
        n > 2 andalso result
      end

  fun formatRecordExp formatter smap =
      if isTuple smap
      then formatEnclosedList
             (formatter, [term "("], [term ","], [term ")"])
             (LabelEnv.listItems smap)
      else formatEnclosedLabelEnv
             (formatter, [term "{"], [term ","], [dsp, term "="], [term "}"])
             smap

  fun formatRecordTy formatter smap =
      if isTuple smap
      then begin_ guard_ tupleAssoc guard_ tupleInnerAssoc
             $(LabelEnv.foldr
                 (fn (x, nil) => formatter x
                   | (x, z) => begin_
                                 $(formatter x) space text "*" dspace $z
                               end_)
                 nil
                 smap)
           end_ end_ end_
      else formatEnclosedLabelEnv
             (formatter, [term "{"], [term ","], [term ":"], [term "}"])
             smap

  (**** for fine-tuning ****)

  fun formatIfCons exp nil = nil
    | formatIfCons exp _ = exp

  (**** for fine-tuning ****)

  fun formatIfList exp nil = nil
    | formatIfList exp [_] = nil
    | formatIfList exp _ = exp

  (**** for fine-tuning ****)
  fun formatIfNonEmpty exp smap = 
      if SEnv.isEmpty(smap) then nil else exp

  (**** for fine-tuning ****)
  fun formatIfEmpty exp smap = 
      if SEnv.isEmpty(smap) then exp else nil

  (**** for fine-tuning ****)
  fun formatIfNonEmptySymbolMap exp smap = 
      if SymbolEnv.isEmpty(smap) then nil else exp

  (**** for fine-tuning ****)
  fun formatIfEmptySymbolMap exp smap = 
      if SymbolEnv.isEmpty(smap) then exp else nil

  fun formatIfEmptyFormat (emptyFormat, nonEmptyFormat) exp =
      if null(exp) then emptyFormat else nonEmptyFormat




  (**** formatting bound type variables ****)

  type 'kind btvEnv' =
       {
         base : int,
         env : (int * 'kind) BoundTypeVarID.Map.map
       }
  type 'kind btvEnv = 'kind btvEnv' formatParam

  val emptyBtvEnv' = {base=0, env=BoundTypeVarID.Map.empty} : 'kind btvEnv'
  val emptyBtvEnv = nil : 'kind btvEnv

  fun getBtvEnv nil = emptyBtvEnv'
    | getBtvEnv [btvEnv] = btvEnv
    | getBtvEnv _ =
      raise Bug.Bug "TermFormat.getBtvEnv: illgal btvEnv parameter"

  fun listItemsiWithOrder (map, order) =
      let
        fun loop (map, nil) = BoundTypeVarID.Map.listItemsi map
          | loop (map, h::t) =
            if BoundTypeVarID.Map.inDomain (map, h)
            then let val (map, v) = BoundTypeVarID.Map.remove (map, h)
                 in (h, v) :: loop (map, t) end
            else loop (map, t)
      in
        loop (map, order)
      end

  fun add ({base, env} : 'k btvEnv') (k, v) =
      {base = base + 1, env = BoundTypeVarID.Map.insert (env, k, (base, v))}

  fun extendBtvEnv env btvMap =
      [BoundTypeVarID.Map.foldli (fn (k, v, env) => add env (k, v))
                                 (getBtvEnv env) btvMap]

  fun makeBtvEnv btvMap = extendBtvEnv emptyBtvEnv btvMap

  fun extendBtvEnvWithOrder env pair =
      [foldl (fn (x, env) => add env x)
             (getBtvEnv env)
             (listItemsiWithOrder pair)]

  fun tvName base index =
       if index < 26 then str (chr (ord base + index))
       else tvName base (index div 26) ^ str (chr (ord base + index mod 26))
  fun btvName index = tvName #"a" index
  fun ftvName index = tvName #"A" index

  fun formatFreeTyvar ftvId =
      [term (ftvName (FreeTypeVarID.toInt ftvId))]

  datatype btvName = BOUND of int | FREE of BoundTypeVarID.id

  fun lookup env btvId =
      case BoundTypeVarID.Map.find (#env (getBtvEnv env), btvId) of
        SOME (nameIndex, kind) => (BOUND nameIndex, SOME kind)
      | NONE => (FREE btvId, NONE)

  fun formatBtv formatKind ((name, kind), btvId) =
      let
        val name =
            case name of
              BOUND i => btvName i
            | FREE id => "FREEBTV(" ^ BoundTypeVarID.toString id ^ ")"
        val nameFormat = [term name]
      in
        case kind of
          SOME kind => formatKind nameFormat kind
        | NONE => nameFormat
      end

  fun formatBtvWithType formatKind ((name, kind), btvId) =
      let
        val name =
            case name of
              BOUND i => btvName i ^ "(" ^ BoundTypeVarID.toString btvId ^ ")"
            | FREE id => "FREEBTV(" ^ BoundTypeVarID.toString id ^ ")"
        val nameFormat = [term name]
      in
        case kind of
          SOME kind => formatKind nameFormat kind
        | NONE => nameFormat
      end

  fun formatBoundTyvar formatKind env btvId =
      formatBtv formatKind (lookup env btvId, btvId)

  fun formatBoundTyvarWithType formatKind env btvId =
      formatBtvWithType formatKind (lookup env btvId, btvId)

  fun formatBtvEnv formatKind env btvEnv =
      let
        val tyvars =
            map (fn (id, kind) => ((#1 (lookup env id), SOME kind), id))
                (BoundTypeVarID.Map.listItemsi btvEnv)
        val tyvars =
            ListSorter.sort
              (fn (((BOUND i,_),_), ((BOUND j,_),_)) => Int.compare (i, j)
                | (((BOUND _,_),_), ((FREE _,_),_)) => LESS
                | (((FREE _,_),_), ((BOUND _,_),_)) => GREATER
                | (((FREE i,_),_), ((FREE j,_),_)) => BoundTypeVarID.compare (i, j))
              tyvars
      in
        SMLFormat.BasicFormatters.format_list
          (formatBtv formatKind, commaSpace)
          tyvars
(*
        SMLFormat.BasicFormatters.format_list
          (formatBtv formatKind, comma)
          tyvars
*)
      end

  fun formatBtvEnvWithType formatKind env btvEnv =
      let
        val tyvars =
            map (fn (id, kind) => ((#1 (lookup env id), SOME kind), id))
                (BoundTypeVarID.Map.listItemsi btvEnv)
        val tyvars =
            ListSorter.sort
              (fn (((BOUND i,_),_), ((BOUND j,_),_)) => Int.compare (i, j)
                | (((BOUND _,_),_), ((FREE _,_),_)) => LESS
                | (((FREE _,_),_), ((BOUND _,_),_)) => GREATER
                | (((FREE i,_),_), ((FREE j,_),_)) => BoundTypeVarID.compare (i, j))
              tyvars
      in
        SMLFormat.BasicFormatters.format_list
          (formatBtvWithType formatKind, commaSpace)
          tyvars
(*
        SMLFormat.BasicFormatters.format_list
          (formatBtvWithType formatKind, comma)
          tyvars
*)
      end

  (**** formatters for constant literals ****)

  fun cminus str =
      String.map (fn #"~" => #"-" | x => x) str
  fun prepend prefix str =
      if String.isPrefix "~" str
      then "~" ^ prefix ^ String.extract (str, 1, NONE)
      else prefix ^ str
  fun toLower str =
      String.map Char.toLower str

  fun format_dec_MLi fmt x =
      [term (fmt StringCvt.DEC x)]
  fun format_dec_MLw fmt x =
      [term (prepend "0w" (fmt StringCvt.DEC x))]
  fun format_dec_C fmt x =
      [term (cminus (fmt StringCvt.DEC x))]
  fun format_hex_MLi fmt x =
      [term (prepend "0x" (toLower (fmt StringCvt.HEX x)))]
  fun format_hex_MLw fmt x =
      [term (prepend "0wx" (toLower (fmt StringCvt.HEX x)))]
  fun format_hex_C fmt x =
      [term (cminus (prepend "0x" (toLower (fmt StringCvt.HEX x))))]

  fun format_BigInt_dec_ML x = format_dec_MLi BigInt.fmt x
(*
  fun format_Int64_dec_ML x = format_dec_MLi Int64.fmt x
*)
  fun format_Int32_dec_ML x = format_dec_MLi Int32.fmt x
  fun format_int_dec_ML x = format_dec_MLi Int.fmt x
(*
  fun format_Word64_hex_ML x = format_hex_MLw Word64.fmt x
*)
  fun format_Word32_hex_ML x = format_hex_MLw Word32.fmt x
  fun format_Word8_hex_ML x = format_hex_MLw Word8.fmt x
  fun format_word_hex_ML x = format_hex_MLw Word.fmt x
(*
  fun format_Int64_dec_C x = format_dec_C Int64.fmt x
*)
  fun format_Int32_dec_C x = format_dec_C Int32.fmt x
  fun format_int_dec_C x = format_dec_C Int.fmt x
(*
  fun format_Word64_hex_C x = format_hex_C Word64.fmt x
*)
  fun format_Word32_hex_C x = format_hex_C Word32.fmt x
  fun format_Word8_hex_C x = format_hex_C Word8.fmt x
  fun format_word_hex_C x = format_hex_C Word.fmt x

  fun right (s, n) = String.extract (s, size s - n, NONE)
  fun pad0 (s, n) = if size s > n then s else right ("0000" ^ s, n)
  fun oct3 i = pad0 (Int.fmt StringCvt.OCT i, 3)
  fun dec3 i = pad0 (Int.fmt StringCvt.DEC i, 3)
  fun hex4 i = pad0 (Int.fmt StringCvt.HEX i, 4)

  fun escapeML s =
      String.translate
        (fn #"\007" => "\\a"
          | #"\008" => "\\b"
          | #"\009" => "\\t"
          | #"\010" => "\\n"
          | #"\011" => "\\v"
          | #"\012" => "\\f"
          | #"\013" => "\\r"
          | #"\092" => "\\\\"
          | #"\034" => "\\\""
          | c => if ord c < 128 andalso Char.isPrint c then str c
                 else if ord c <= 999 then "\\" ^ dec3 (ord c)
                 else "\\u" ^ hex4 (ord c))
        s

  fun escapeC s =
      String.translate
        (fn #"\008" => "\\b"
          | #"\012" => "\\f"
          | #"\010" => "\\n"
          | #"\013" => "\\r"
          | #"\009" => "\\t"
          | #"\092" => "\\\\"
          | #"\034" => "\\\""
          | c => if ord c < 128 andalso Char.isPrint c then str c
                 else if ord c < 256 then "\\" ^ oct3 (ord c)
                 else "\\u" ^ hex4 (ord c))
        s

  fun format_string_ML s = [term ("\"" ^ escapeML s ^ "\"")]
  fun format_string_C s = [term ("\"" ^ escapeC s ^ "\"")]
  fun format_char_ML c = [term ("#\"" ^ escapeML (str c) ^ "\"")]
  fun format_char_C #"\034" = [term "'\"'"]
    | format_char_C c = [term ("'" ^ escapeC (str c) ^ "'")]

  structure FormatComb =
  struct
    open FormatComb
    val int = format_int_dec_ML
    val word = format_word_hex_ML
    val string = format_string_ML
    fun list f l = formatEnclosedList (f, [term "["], [term ","], [term "]"]) l
    fun tuple f l = formatEnclosedList (f, [term "("], [term ","], [term ")"]) l
    fun tuple2 (f1, f2) (x1, x2) =
        tuple (fn x => x) [f1 x1, f2 x2]
    fun tuple3 (f1, f2, f3) (x1, x2, x3) =
        tuple (fn x => x) [f1 x1, f2 x2, f3 x3]
    fun tuple4 (f1, f2, f3, f4) (x1, x2, x3, x4) =
        tuple (fn x => x) [f1 x1, f2 x2, f3 x3, f4 x4]
    fun puts (A (fmt, last)) k =
        k (A (fmt, fn t => TextIO.print (Bug.prettyPrint t ^ "\n")))
    val term = fn x => [term x]
  end

  (* for debug *)

  fun formatFormatExp exp =
      case exp of
        Term (n, s) =>
        dsp :: format_string_ML s
        @ (if size s = n then nil else [term ("(" ^ Int.toString n ^ ")")])
      | Newline => [dsp, term "\\n"]
      | Guard (assoc, exps) =>
        begin_
          space
          $(case assoc of
              NONE => nil
            | SOME {cut, strength, direction} =>
              [term ((if cut then "!" else "")
                     ^ (case direction of
                          Left => "L" | Right => "R" | Neutral => "N")
                     ^ Int.toString strength)])
          text "{"
          dspace
          guard_ NONE $(formatFormat exps) dspace text "}" end_
        end_
      | Indicator {space, newline} =>
        [dsp,
         term ((if space then "+" else "")
               ^ (case newline of
                    NONE => ""
                  | SOME {priority=Preferred n} => Int.toString n
                  | SOME {priority=Deferred} => "d"))]
      | StartOfIndent n =>
        [dsp, term (Int.toString n ^ "[")]
      | EndOfIndent => [dsp, term "]"]

  and formatFormat exps =
      case List.concat (map formatFormatExp exps) of
        h::t => t | nil => nil
end
