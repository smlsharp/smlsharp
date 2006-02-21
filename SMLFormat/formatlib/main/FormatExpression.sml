(**
 *  This module defines types which represents format expressions.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FormatExpression.sml,v 1.1 2006/02/07 12:51:52 kiyoshiy Exp $
 *)
structure FormatExpression : FORMAT_EXPRESSION =
struct

  (***************************************************************************)

  datatype priority =
           Preferred of int
         | Deferred

  datatype assocDirection = Left | Right | Neutral
  type assoc = {cut : bool, strength : int, direction : assocDirection}

  datatype expression =
           Term of (int * string)
         | Guard of (assoc option) * (expression list)
         | Indicator of
           {
             space : bool,
             newline :
             {
               priority : priority
             }
             option
           }
         | StartOfIndent of int
         | EndOfIndent

  (***************************************************************************)

  fun isHigherThan (_, Deferred) = true
    | isHigherThan (Deferred, _) = false
    | isHigherThan (Preferred left, Preferred right) = left < right

  fun assocToString {cut, strength, direction} =
      let
        val directionText = 
            case direction of Left => "L" | Right => "R" | Neutral => "N"
      in
        (if cut then "!" else "") ^ directionText ^ (Int.toString strength)
      end

  fun priorityToString (Preferred priority) = Int.toString priority
    | priorityToString Deferred = "d"

  fun toString (Term (columns, text)) = "\"" ^ text ^ "\""
    | toString (Guard(assocOpt, expressions)) =
      (case assocOpt of
         NONE => "{"
       | SOME assoc => (assocToString assoc) ^ "{") ^
      (concat (map (fn exp => (toString exp) ^ " ") expressions)) ^
      "}"
    | toString (Indicator{space, newline}) =
      (if space then "+" else "") ^
      (case newline of
         NONE => ""
       | SOME{priority} =>
         (priorityToString priority))
    | toString (StartOfIndent indent) =  Int.toString indent ^ "["
    | toString EndOfIndent = "]"

  (***************************************************************************)

end