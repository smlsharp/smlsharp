(**
 * Utilities for parser.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: ParserUtil.sml,v 1.3 2004/11/06 16:15:03 kiyoshiy Exp $
 *)
structure ParserUtil =
struct

  (***************************************************************************)

  structure PositionMap :
    sig
      type pos = int
      type operations =
           {
             posToLocation : pos -> int * int,
             makeMessage : (string * pos * pos) -> string,
             onNewLine : int -> unit
           }
      val create : string -> operations
    end =
  struct

    type pos = int
    type operations =
         {
           posToLocation : pos -> int * int,
           makeMessage : (string * pos * pos) -> string,
           onNewLine : int -> unit
         }

    fun posToLocation (lineMap, lastNewLinePos, currentLineNumber) pos =
        let
          fun inRegion (_, (leftPos, rightPos)) =
              leftPos <= pos andalso pos <= rightPos
        in
          if !lastNewLinePos < pos
          then (!currentLineNumber, pos - !lastNewLinePos)
          else
            case List.find inRegion (!lineMap) of
              NONE => (~1, pos) (* ToDo : error message. *)
            | SOME(lineCount, (leftPos, _)) => (lineCount, pos - leftPos)
        end

    fun makeMessage fileName posToLocation (message, beginPos, endPos) =
        let
          val (beginLine, beginCol) = posToLocation beginPos
          val (endLine, endCol) = posToLocation endPos
        in
          String.concat 
              [
                fileName, ":",
                Int.toString beginLine, ".", Int.toString beginCol,
                "-",
                Int.toString endLine, ".", Int.toString endCol,
                " ",
                message,
                "\n"
              ]
        end

    fun onNewLine (lineMap, lastNewLinePos, currentLineNumber) pos =
        (
          lineMap :=
          (!currentLineNumber, (!lastNewLinePos + 1, pos))::(!lineMap);
          currentLineNumber := !currentLineNumber + 1;
          lastNewLinePos := pos
        )

    fun create fileName =
        let
          val lineMap = ref []
          val currentLineNumber = ref 1
          val lastNewLinePos = ref 0
          val posToLocation =
              posToLocation (lineMap, lastNewLinePos, currentLineNumber)
          val onNewLine =
              onNewLine (lineMap, lastNewLinePos, currentLineNumber)
        in
          {
            posToLocation = posToLocation,
            makeMessage = makeMessage fileName posToLocation,
            onNewLine = onNewLine
         }
        end
  end

  (***************************************************************************)

end