(**
 * parser generator based on regular expression.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: REGEXPParserGenerator.sml,v 1.4 2006/02/28 16:11:01 kiyoshiy Exp $
 *)
structure REGEXPParserGenerator
  : sig

      (** regular expression *)
      datatype ('result, 'stream) regexp =
               Option of ('result, 'stream) regexp
             | Or of ('result, 'stream) regexp list
             | Repeat of ('result, 'stream) regexp
             | Sequence of ('result, 'stream) regexp list
             | Term of string * ('result, 'stream) ParserComb.parser

      (** generates from a regular expression a parser which accepts an input
       * matching with the regular expression. *)
      val toParser
          : bool
            -> ('result, 'stream) regexp
            -> ('result list, 'stream) ParserComb.parser

      (** translates a regular expression into a string. *)
      val toString
          : bool -> ('result, 'stream) regexp -> string

    end =
struct

  (***************************************************************************)

  structure PC = ParserComb

  (***************************************************************************)

  (**
   *  interleave elements of a list with separators.
   * @params separator list
   * @param separator the separator
   * @param list the list
   * @return the list interleaved with separators
   *)
  fun interleave separator [] = []
    | interleave separator strings =
      (rev
       (foldl
        (fn (string, strings) => string :: separator :: strings)
        [hd strings]
        (tl strings)))

  (***************************************************************************)

  datatype ('result, 'stream) regexp =
           Sequence of ('result, 'stream) regexp list
         | Or of ('result, 'stream) regexp list
         | Option of ('result, 'stream) regexp
         | Repeat of ('result, 'stream) regexp
         | Term of string * ('result, 'stream) PC.parser

  (***************************************************************************)

  local
    val MIN_PREC = ~1
    fun precOfRegex (Sequence _) = 1
      | precOfRegex (Or _) = 0
      | precOfRegex (Option _) = 3
      | precOfRegex (Repeat _) = 2
      | precOfRegex (Term _) = 4
  in
  fun toString isTokenMode regexp =
      let
        fun trans upperPrec regexp =
            let
              val prec = precOfRegex regexp
              val string = 
                  case regexp of
                    Sequence regexps =>
                    let val strings = map (trans prec)  regexps
                    in
                      if isTokenMode
                      then concat(interleave " " strings)
                      else concat(strings)
                    end
                  | Or regexps =>
                    let val sep = if isTokenMode then " | " else "|"
                    in concat (interleave sep (map (trans prec) regexps)) end
                  | Option regexp => trans prec regexp ^ "?"
                  | Repeat regexp => trans prec regexp ^ "+"
                  | Term (name, _) => name
            in
              if prec < upperPrec
              then "(" ^ string ^ ")"
              else string
            end
      in
        trans MIN_PREC regexp
      end
  end

  local
    fun concatListParser (left, right) =
        PC.seqWith
            (fn (leftResults, rightResults) => leftResults @ rightResults)
            (left, right)
  in
  fun toParser isTokenMode regexp =
      let
        fun trans (Sequence regexps) =
            foldr concatListParser (PC.result []) (map trans regexps)
          | trans (Or regexps) = PC.or' (map trans regexps)
          | trans (Option regexp) =
            PC.wrap(PC.option (trans regexp), fn opt => Option.getOpt(opt, []))
          | trans (Repeat regexp) =
            PC.wrap(PC.oneOrMore (trans regexp), List.concat)
          | trans (Term (_, parser)) =
            let val termParser = PC.wrap(parser, fn term => [term])
            in
              if isTokenMode
              then PC.skipBefore Char.isSpace termParser
              else termParser
            end
      in
        trans regexp
      end
  end

  (***************************************************************************)

end;
