(**
 *  Types and operations of represents format expressions.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: FORMAT_EXPRESSION.sig,v 1.4 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
signature FORMAT_EXPRESSION =
sig

  (***************************************************************************)

  (**
   * priority of newline indicators.
   *)
  datatype priority =
           (** preferred priority of the specified priority *)
           Preferred of int
         | (** deferred priority *)
           Deferred

  (**
   * direction of the associativity between elements in guards
   *)
  datatype assocDirection =
           (** indicates left associativity *)
           Left
         | (** indicates right associativity *)
           Right
         | (** indicates non-directional associativity *)
           Neutral

  (**
   * the associativity between elements in guards.
   *)
  type assoc =
       {
         (**
          * true if the inheritance of associativity from the upper guard
          * is cut.
          *) 
         cut : bool,
         (** the strength of the association. *)
         strength : int,
         (** the direction of the association. *)
         direction : assocDirection
       }

  (**
   * format expressions
   *)
  datatype expression =

           (** string literal.
            * The 'columns' is not always equal to the size of 'text'.
            * For example, a HTML code snip
            * "&lt;a ref=http://www.jaist.ac.jp&gt;JAIST&lt;/a&gt;" is encoded
            * as
            * Term(5, "&lt;a ref=http://www.jaist.ac.jp&gt;JAIST&lt;/a&gt;").
            * The 'columns' is 5 which is the length of the text 'JAIST' to be
            * displayed.
            * @params (columns, text)
            * @param columns the number of columns which the text occupies in
            *      the displayed form
            * @param text the text to be output which may include escape
            *       sequence to encode the form to be displayed
            *)
           Term of (int * string)

         | (** always break line here. *)
           Newline

         | (**
            * scope of indicator's priority (with assoc indicator)
            * @params (assoc, expressions)
            * @param assoc the associativity between the expressions
            * @param expressions the elements of the guard
            *)
           Guard of (assoc option) * (expression list)

         | (** format indicator *)
           Indicator of
           {
             (** true if a whitespace should be inserted here. *)
             space : bool,

             (** NONE if newline indicator is not specified. *)
             newline :
             {
               (** priority to insert a newline *)
               priority : priority
             }
             option
           }
         | (**
            * push a indent on the indent stack
            * @params width
            * @param width colums of indent
            *)
           StartOfIndent of int
         | (** pop a indent out of the indent stack *)
           EndOfIndent

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
