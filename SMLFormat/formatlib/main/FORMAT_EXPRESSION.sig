(**
 *  Types and operations of represents format expressions.
 * @author YAMATODANI Kiyoshi
 * @version $Id: FORMAT_EXPRESSION.sig,v 1.4 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
signature FORMAT_EXPRESSION =
sig

  (***************************************************************************)

  include FORMAT_EXPRESSION_TYPES

  (***************************************************************************)

  (**
   * compare two priorities.
   * @params (left, right)
   * @param left a priority
   * @param right another priority
   * @return true if the <code>left</code> is higher priority than
   *     the <code>right</code>
   *)
  val isHigherThan : priority * priority -> bool

  (**
   * make a string representation of the assoc.
   * @params assoc
   * @param assoc a assoc
   * @return the string representation of the <code>assoc</code>
   *)
  val assocToString : assoc -> string

  (**
   * make a string representation of the priority.
   * @params priority
   * @param priority a priority
   * @return the string representation of the <code>priority</code>
   *)
  val priorityToString : priority -> string

  (**
   * make a string representation of the expression.
   * @params expression
   * @param expression a expression
   * @return the string representation of the <code>expression</code>
   *)
  val toString : expression -> string

  (**
   * parse format expression list.
   * <p>
   * Any character follows a back slash is interpreted as is.
   * Especially, a sequence of ['\', '"'] is interpreted as a character '"'.
   * </p>
   *)
  val parse
      : (char, 'a) StringCvt.reader -> (expression list, 'a) StringCvt.reader

  (***************************************************************************)

end
