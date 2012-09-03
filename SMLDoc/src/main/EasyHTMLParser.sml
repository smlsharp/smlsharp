(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: EasyHTMLParser.sml,v 1.2 2004/10/20 03:18:39 kiyoshiy Exp $
 *)
structure EasyHTMLParser : EASY_HTML_PARSER =
struct

  (***************************************************************************)

  fun getBodyOfHTML onWarn text =
      let
        val textLength = String.size text
        fun findChar position char =
            if String.sub(text, position) = char
            then position
            else findChar (position + 1) char
        fun isPrefix [] position = true
          | isPrefix (char::chars) position =
            if char = Char.toUpper(String.sub(text, position))
            then isPrefix chars (position + 1)
            else false
        fun searchBodyStart position =
            if isPrefix [#"B", #"O", #"D", #"Y"] position
            then (findChar position #">") + 1
            else searchBodyStart ((findChar position #"<") + 1)
        fun searchBodyEnd position =
            if isPrefix [#"/", #"B", #"O", #"D", #"Y"] position
            then position - 1 (* position of "<" *)
            else searchBodyEnd ((findChar position #"<") + 1)
        val bodyStartPos =
            (searchBodyStart ((findChar 0 #"<") + 1)
             handle Subscript => (onWarn "start of body not found"; 0))
        val bodyEndPos =
            (searchBodyEnd (findChar bodyStartPos #"<")
             handle Subscript => (onWarn "end of body not found"; textLength))
      in
        String.substring(text, bodyStartPos, bodyEndPos - bodyStartPos)
      end
  
  (***************************************************************************)

end
