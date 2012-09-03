(**
 *
 * @author YAMATODNI Kiyoshi
 * @version $Id: ConstantTable.sml,v 1.3 2007/09/20 09:05:53 matsu Exp $
 *)
structure ConstantTable :> CONSTANT_TABLE =
struct

  (***************************************************************************)

  structure PC = ParserComb
  structure U = Utility

  (***************************************************************************)

  datatype constant =
           Int of int
         | Word of word
         | String of string
         | Char of char
         | Real of real

  type spec =
       {
         bindName : string,
         constant : constant
       }

  (***************************************************************************)

  exception ParseError of int

  (***************************************************************************)

  (**
   *  The least index of primitivies
   *  This value may be changed in future when some reserve primitives are
   * introduced.
   *)
  val initialConstantIndex = 0

  fun parseConstant (string, quoted) =
      if CSVParser.QUOTED = quoted
      then String string
      else
        (* ToDo : parse char constant. *)
        case
          PC.or'
              [
                PC.wrap (Int.scan StringCvt.DEC, fn int => Int int),
                PC.wrap (Word.scan StringCvt.HEX, fn word => Word word),
                PC.wrap (Real.scan, fn real => Real real)
              ]
              Substring.getc
              (Substring.full string)
         of
          SOME (constant, remain) => constant
        | NONE => raise Fail "invalid constant"

  fun input filename =
      let
        val input = TextIO.getInstream (TextIO.openIn(filename))
        val CSV =
            CSVParser.parse (U.skipCommentParser TextIO.StreamIO.input1) input
        val _ = TextIO.StreamIO.closeIn input

        fun parse (line, {lineno, index, dst}) =
            case line : CSVParser.field list of
              [SOME (name, _), SOME valueField] =>
              {
                lineno = lineno + 1,
                index = index,
                dst =
                {
                  bindName = name,
                  constant = parseConstant valueField
                } :: dst
              }
            | [NONE] => {lineno = lineno, index = index, dst = dst}
            | _ => raise (ParseError lineno)
      in
        rev
        (#dst
         (foldl
           parse {lineno = 1, index = initialConstantIndex, dst = nil} CSV))
      end

  fun constantToSMLString constant =
      case constant of
        Int int => Int.toString int
      | Word word => "0wx" ^ (Word.fmt StringCvt.HEX word)
      | String string => "\"" ^ String.toString string ^ "\""
      | Char char => "#\"" ^ Char.toString char ^ "\""
      | Real real => Real.toString (Real.abs real)

  local
    fun sign signInt = if signInt < 0 then "-" else ""
  in
  fun constantToCString constant =
      case constant of
        Int int => (sign int) ^ (Int.toString (Int.abs int))
      | Word word => "0x" ^ (Word.fmt StringCvt.HEX word)
      | String string => "\"" ^ String.toCString string ^ "\""
      | Char char => "'" ^ Char.toCString char ^ "'"
      | Real real => (sign (Real.sign real)) ^ (Real.toString (Real.abs real))
  end

  fun constantToCTypeName constant =
      case constant of
        Int _ => "int"
      | Word _ => "unsigned int"
      | String _ => "char*"
      | Char _ => "char"
      | Real _ => "double"

  fun join s ("", s2) = s2
    | join s (s1, s2) = s1 ^ s ^ s2

  fun constantsSML spec =
      let
        fun format (dst, nil) = dst
          | format (dst, {bindName, constant} :: t) =
            let
              val code =
                  "val " ^ bindName ^ " = " ^ constantToSMLString constant
            in
              format (join "\n" (dst, code), t)
            end
      in
        format ("", spec)
      end

  fun constantsC (spec : spec list) =
      let
        fun format (dst, nil : spec list) = dst
          | format (dst, {bindName, constant} :: t) =
            let
              val code =
                  "const " 
                  ^ constantToCTypeName constant
                  ^ " " ^ bindName ^ " = "
                  ^ constantToCString constant
                  ^ ";"
            in
              format (join "\n" (dst, code), t)
            end
      in
        format ("", spec)
      end

  fun formatTemplate (spec, inFilename, outFilename) =
      let
        val infile = TextIO.openIn inFilename
        val outfile = TextIO.openOut outFilename
        fun replaceLabel x =
            case Substring.string x of
              "SMLConstants" => SOME (constantsSML spec)
            | "CConstants" => SOME (constantsC spec)
            | _ => NONE
      in
        AtmarkTemplate.format replaceLabel (infile, outfile) ;
        TextIO.closeOut outfile ;
        TextIO.closeIn infile
      end

  fun generateFiles inputFile outputFiles =
      let
        val spec = input inputFile
      in
        foldl
            (fn (filename, _) =>
                formatTemplate (spec, filename ^ ".in", filename))
            ()
            outputFiles
      end

  (***************************************************************************)

end
