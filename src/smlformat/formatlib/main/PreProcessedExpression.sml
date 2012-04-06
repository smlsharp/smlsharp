(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: FORMAT_EXPRESSION_TYPES.sig,v 1.1 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
structure PreProcessedExpression =
struct

  (**
   * This is a duplication of FormatExpression.priority.
   *)
  datatype priority =
           (** preferred priority of the specified priority *)
           Preferred of int
         | (** deferred priority *)
           Deferred

  (**
   *  The entry which contains the information needed to decide to begin
   * newlines at the newline indicators.
   *  The preferred indicators of the same priority share a entry.
   *  Separate entries are generated for each deferred indicators.
   *)
  type environmentEntry =
       {
          (**
           * the number of columns required to print the text without inserting
           * newlines at the indicators of the priority.
           *)
          requiredColumns : int, 

          (**
           * indicates whether to begin a newline at the all indicators of
           * the priority
           *)
          newline : bool ref,

          (** the priority *)
          priority : priority
       }

  type environment = environmentEntry list

  datatype expression =
           (** the term string literal *)
           Term of (int * string)

         | (** non terminal *)
           List of
           {
             (** the list of expressions *)
             expressions : expression list,

             (**
              * the environment consisting of entries for preferred indicators.
              *)
             environment : environment
           }

         | (** the format indicators *)
           Indicator of
           {
             (** true if the space indicator is specified. *)
             space : bool,
             (** become true if a newline should begin at this indicator. *)
             newline : bool ref
           }

         | (** the format indicators with deferred newline priority *)
           DeferredIndicator of
           {
             (** true if the space indicator is specified. *)
             space : bool,
             (**
              * the number of columns required to print the text without
              * inserting newlines at this indicator.
              * NOTE: The type of this field is reference in order to keep
              * efficiency of implementation of the preprocessor.
              * The prettyprinter never modifies this fields.
              *)
             requiredColumns : int ref
           }

         | (** the width of indent. *)
           StartOfIndent of int

         | (** the end of indent scope *)
           EndOfIndent

  fun isHigherThan (_, Deferred) = true
    | isHigherThan (Deferred, _) = false
    | isHigherThan (Preferred left, Preferred right) = left < right

end;
