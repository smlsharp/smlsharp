(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: ExpressionInterpreter.sml,v 1.1 2005/11/08 02:15:49 kiyoshiy Exp $
 *)
structure ExpressionInterpreter =
struct

  (***************************************************************************)

  open BasicTypes
  structure CTX = Context
  structure CVP = CellValuePrinter
  structure FS = FrameStack
  structure I = Instructions
  structure RT = RuntimeTypes
  structure SS = Substring
  structure U = Utility

  (***************************************************************************)

  type context = CTX.context
  
  (***************************************************************************)

  exception Error of string

  (***************************************************************************)

  fun eval (context : context) currentFrame currentCodeRef argumentSS =
      case SS.tokens Char.isSpace argumentSS of
        [expressionSS] =>
        let
          val variableName = SS.string expressionSS
        in
          case variableName of
            "_ENV_" => FS.loadENVOfFrame currentFrame
          | _ =>
            let
              val slot =
                  case
                    NameSlotTable.getSlotOfName currentCodeRef variableName
                   of
                    NONE => raise Error ("not found variable:" ^ variableName)
                  | SOME index => index
            in
              FS.getSlotOfFrame currentFrame slot
            end
        end
      | _ => raise Error "parse error"

  (***************************************************************************)

end
