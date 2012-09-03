(**
 * @author UENO Katsuhiro
 * @version $Id: AtmarkTemplate.sml,v 1.4 2005/05/27 03:30:31 kiyoshiy Exp $
 *)
structure AtmarkTemplate :> ATMARK_TEMPLATE =
struct

  (***************************************************************************)

  fun format replaceLabel (input, output) =
      let
        fun outputLine src =
            let
              exception Bug
              open Substring

              val (plain, src) = splitl (fn x => x <> #"@") src
              val (label, src) = splitl (fn x => x <> #"@") (triml 1 src)
              val rep =
                  case first src of
                    SOME #"@" =>
                    if isEmpty label then SOME "@" else replaceLabel label
                  | NONE => NONE
                  | _ => raise Bug
            in
              case rep of
                NONE => TextIO.outputSubstr (output, span (plain, src))
              | SOME x =>
                (
                  TextIO.outputSubstr (output, plain) ;
                  TextIO.output (output, x) ;
                  outputLine (triml 1 src)
                )
            end

        fun nextLine stream =
            if TextIO.endOfStream stream
            then NONE
            else SOME (TextIO.inputLine stream)

        fun formatLoop NONE = ()
          | formatLoop (SOME line) =
            (outputLine (Substring.all line); formatLoop (nextLine input) )
      in
        formatLoop (nextLine input)
      end

  (***************************************************************************)

end