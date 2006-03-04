(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CommandShellParser.sml,v 1.4 2006/02/28 16:11:01 kiyoshiy Exp $
 *)
local
  open BasicTypes
in
structure CommandShellParser
          : sig
              datatype ('result, 'stream) regexp =
                       Option of ('result, 'stream) regexp
                     | Or of ('result, 'stream) regexp list
                     | Repeat of ('result, 'stream) regexp
                     | Sequence of ('result, 'stream) regexp list
                     | Term of string * ('result, 'stream) ParserComb.parser

              datatype token =
                       Number of int
                     | SInt32 of BasicTypes.SInt32
                     | UInt32 of BasicTypes.UInt32
                     | Text of string

              (** raised when an input is rejected by parser. *)
              exception ParseError

              (* regular expressions for utility *)
              val RegexDirectoryName : (token, 'stream) regexp
              val RegexFileName : (token, 'stream) regexp
              val RegexLiteralText : string -> (token, 'stream) regexp
              val RegexNumber : (token, 'stream) regexp
              val RegexText : (token, 'stream) regexp

              (* utility parsers *)
              val parseNumber : (token, 'stream) ParserComb.parser
              val parseSInt32 : (token, 'stream) ParserComb.parser
              val parseText : (token, 'stream) ParserComb.parser
              val parseUInt32 : (token, 'stream) ParserComb.parser

              (** translates a regexp into a parser which produces a token
               * list from a stream matching the regexp. *)
              val parse
                  : (token, 'stream) regexp
                    -> (token list, 'stream) ParserComb.parser

              (** make a string from a regexp. *)
              val toString : (token, 'stream) regexp -> string

          end =
struct

  (***************************************************************************)

  structure PC = ParserComb
  structure RE = REGEXPParserGenerator

  (***************************************************************************)

  datatype token =
           UInt32 of UInt32
         | SInt32 of SInt32
         | Number of int
         | Text of string

  datatype regexp = datatype RE.regexp

  (***************************************************************************)

  exception ParseError

  (***************************************************************************)

  fun parseUInt32 getc stream =
      PC.or'
          [
            PC.seqWith
                #2
                (PC.string "0wx", PC.wrap(UInt32.scan StringCvt.HEX, UInt32)),
            PC.seqWith
                #2
                (PC.string "0w", PC.wrap(UInt32.scan StringCvt.DEC, UInt32))
          ]
          getc stream

  fun parseSInt32 getc stream =
      PC.wrap(SInt32.scan StringCvt.DEC, SInt32) getc stream

  fun parseNumber getc stream =
      PC.wrap
          (
            PC.or' [parseUInt32, parseSInt32],
            fn UInt32 uint32 => Number (UInt32ToInt uint32)
             | SInt32 sint32 => Number (SInt32ToInt sint32)
          )
          getc stream

  local
    fun parseQuotedText getc stream = 
        PC.seqWith
            #2
            (
              PC.char #"\"",
              PC.seqWith
                  #1
                  (
                    PC.zeroOrMore(PC.eatChar (fn ch => ch <> #"\"")),
                    PC.char #"\""
                  )
            )
            getc stream
    fun parseUnquotedText getc stream =
        PC.oneOrMore(PC.eatChar (not o Char.isSpace)) getc stream
  in
  fun parseText getc stream =
      PC.wrap
          (PC.or' [parseQuotedText, parseUnquotedText], Text o implode)
          getc stream
  end

  (********************)

  val RegexText = RE.Term("TEXT", parseText)
  val RegexFileName = RE.Term("FILE", parseText)
  val RegexDirectoryName = RE.Term("DIR", parseText)
  val RegexNumber = RE.Term("NUM", parseNumber)

  fun RegexLiteralText string =
      RE.Term
          (
            "\"" ^ string ^ "\"",
            PC.wrap(PC.string string, fn string => Text string)
          )

  (****************************************)

  fun parse regexp getc stream = (RE.toParser true regexp) getc stream

  fun toString regexp = RE.toString true regexp

  (***************************************************************************)

end (* structure *)

end (* local *)
