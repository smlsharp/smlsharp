(**
 * parser of CSV format.
 *
 * @author UENO Katsuhiro
 * @version $Id: CSVParser.sml,v 1.8 2007/09/20 09:05:53 matsu Exp $
 *)
structure CSVParser : CSVPARSER =
struct

  (***************************************************************************)

  structure SS = Substring
  structure SC = StringCvt

  (***************************************************************************)

  datatype fieldQuote = UNQUOTED | QUOTED
  type field = (string * fieldQuote) option
  type row = field list
  type table = row list
  type 'stream parser = 'stream -> table

  (***************************************************************************)

  fun createParser
          {
            delimiter = comma,
            quote = quote,
            escape = backslash,
            stripField = stripField,
            reader = reader
          } =
      let
        fun isSpace c = c = #" " orelse c = #"\009"

        val stripl =
            if stripField then SC.dropl isSpace reader else (fn x => x)
        val striprString =
            if stripField
            then (fn x : string => SS.string(SS.dropr isSpace (SS.full x)))
            else (fn x => x)

        fun concatField (field : field, ty : fieldQuote, cont : string) =
            if "" = cont
            then field
            else
              case field of
                NONE => SOME (cont, ty)
              | SOME (x, _) => SOME (concat [x, cont], ty)

        (* a field matches / *([^",]*("([^\\]|\\.)*")?)* */ *)

        fun scanUnquotedField (field : field, src) =
            let
              fun isFieldCont c =
                  c <> comma
                  andalso c <> quote
                  andalso c <> #"\r"
                  andalso c <> #"\n"

              val (f, src) = SC.splitl isFieldCont reader src
              val field = concatField (field, UNQUOTED, f)
            in
              (field, src)
            end

        fun scanQuotedField (field : field, src) =
            let
              fun isQuotedCont c =
                  c <> quote andalso c <> backslash andalso c <> #"\r"

              val (q, src) = SC.splitl isQuotedCont reader src
              val field = concatField (field, QUOTED, q)
            in
              case reader src of
                SOME(c, src) =>
                if c = backslash
                then
                  let
                    val field =
                        case reader src of
                          SOME(escaped, src) =>
                          concatField (field, QUOTED, Char.toString escaped)
                        | NONE => field
                  in scanQuotedField (field, src)
                  end
                else
                  if c = #"\r"
                  then
                    (* linebreaks in a field are always #"\n". *)
                    let
                      val src =
                          case reader src of
                          SOME (#"\n", src) => src
                        | _ => src
                      val field = concatField (field, QUOTED, "\n")
                    in scanQuotedField (field, src)
                    end
                  else
                    (field, src)
              | NONE => (field, src)
            end

        type state = table * row * field
        val initialState = (nil, nil, NONE)

        fun closeField (table, row, field : field) =
        let
          val field =
              case field of
                NONE => NONE
              | SOME (x, quote) => SOME (striprString x, quote)
        in (table, field :: row, NONE)
        end
          
        fun closeRow (table, row, field) = (rev row :: table, nil, NONE)

        fun closeTable (table, row, field) = rev table

        fun parse (state as (table, row, field), src) =
            case reader src of
              SOME (#"\n", src) =>
              parse (closeRow (closeField state), stripl src)
            | SOME (#"\r", src) =>
              let
                val src =
                    case reader src
                     of SOME (#"\n", src) => src | _ => src
              in parse (closeRow (closeField state), stripl src)
              end
            | NONE => closeTable (closeRow (closeField state))
            | SOME (x, src') =>
              if x = comma
              then parse (closeField state, src')
              else
                if x = quote
                then
                  let
                    val (field, src'') = scanQuotedField (field, stripl src')
                  in parse ((table, row, field), src'')
                  end
                else
                  let val (field, src) = scanUnquotedField (field, stripl src)
                  in parse ((table, row, field), src)
                  end
      in
        fn src => parse (initialState, src)
      end

  fun parse reader =
      let
        val parser = 
            createParser
                {
                  delimiter = #",",
                  quote = #"\"",
                  escape = #"\\",
                  stripField = true,
                  reader = reader
                }
      in parser
      end

  local
    val stringParser = parse Substring.getc
  in
  fun parseString string = stringParser (Substring.full string)
  end

  (***************************************************************************)

end
