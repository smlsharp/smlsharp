(**
 * This module includes types which SML# defines as built-in types.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: FormatExpressionTypes.sml,v 1.1 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
structure FormatExpressionTypes =
struct
  datatype priority = datatype SMLSharp.SMLFormat.priority
  datatype assocDirection = datatype SMLSharp.SMLFormat.assocDirection
  type assoc = {cut : bool, strength : int, direction : assocDirection}
  datatype expression = datatype SMLSharp.SMLFormat.expression
end
