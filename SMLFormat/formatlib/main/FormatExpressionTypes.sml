(**
 *  This module defines types which represents format expressions.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: FormatExpressionTypes.sml,v 1.1 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
structure FormatExpressionTypes =
struct

  (***************************************************************************)

  datatype priority =
           Preferred of int
         | Deferred

  datatype assocDirection = Left | Right | Neutral
  type assoc = {cut : bool, strength : int, direction : assocDirection}

  datatype expression =
           Term of (int * string)
         | Newline
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

end;
