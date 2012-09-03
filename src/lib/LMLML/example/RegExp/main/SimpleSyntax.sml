(*
 * Simple regular expression syntax
 * <pre>
 * char := c
 *       | "[" c+ "]"
 *       | "\" ... (escape char)
 * 
 * atomic := char
 *         | "^"
 *         | "$"
 *         | "."
 *         | "(" expression ")"
 * 
 * repetition := atomic ( "?" | "*" | "+" )?
 * 
 * sequence := repetition *
 * 
 * expression := sequence ( "|" sequence )*
 * </pre>
 *)
structure SimpleSyntax : REGEXP_PARSER =
  struct

    structure R = RegExpSyntax
    structure P = MBParserCombinator

    structure SC = StringCvt
    structure W8 = Word8
    structure C = MBChar

    exception Error


    fun makeDotMatch () =
        R.NonmatchSet
            (R.CharSet.addList
                 (R.CharSet.empty, explode (MBString.fromString "\000\n")))
    val dotMatch = ref (makeDotMatch ())
    fun makeMetaChars () = MBString.fromString "\\^$.[]|()*+?"
    val metaChars = ref (makeMetaChars())

    (* dotMatch must be rebuilt each time when default codec is changed. *)
    val _ =
        MultiByteString.addDefaultCodecChangeListener
            (fn _ =>
                (dotMatch := makeDotMatch (); metaChars := makeMetaChars()))

    fun isMeta c = C.contains (!metaChars) c

    val C = C.fromAsciiChar

    fun atomic reader stream =
        P.or'
            [
              P.wrap (P.char (C #"^"), fn _ => R.Begin),
              P.wrap (P.char (C #"$"), fn _ => R.End),
              P.wrap (P.char (C #"."), fn _ => !dotMatch),
              P.seqWith
                  #2
                  (
                    P.char (C #"("),
                    P.seqWith #1 (expression, P.char (C #")"))
                  ),
              P.wrap (P.eatChar (fn c => not(isMeta c)), R.Char)
            ]
            reader stream
    and repetition reader stream =
        P.seqWith
            (fn (re, NONE) => re | (re, SOME suffix) => suffix re)
            (
              atomic,
              P.option
                  (P.or'
                       [
                         P.seqWith #2 (P.char (C #"?"), P.result R.Option),
                         P.seqWith #2 (P.char (C #"*"), P.result R.Star),
                         P.seqWith #2 (P.char (C #"+"), P.result R.Plus)
                       ])
            )
            reader stream
    and sequence reader stream =
        P.wrap(P.zeroOrMore repetition, R.Concat) reader stream
    and expression reader stream =
        P.seqWith
            (fn (alt1, []) => alt1 | (alt1, alts) => R.Alt(alt1 :: alts))
            (
              sequence,
              P.zeroOrMore(P.seqWith #2 (P.char (C #"|"), sequence))
            )
            reader stream
    fun scan reader stream = expression reader stream

  end
