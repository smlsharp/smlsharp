(**
 *  This module translates the symbols into a text representation which fits
 * within the specified column width.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PRETTYPRINTER.sig,v 1.3 2007/05/30 14:18:31 kiyoshiy Exp $
 *)
signature PRETTYPRINTER =
sig

  (***************************************************************************)

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
          priority : FormatExpression.priority
       }

  type environment = environmentEntry list

  datatype symbol =
           (** the term string literal *)
           Term of (int * string)

         | (** non terminal *)
           List of
           {
             (** the list of symbols *)
             symbols : symbol list,

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

  (***************************************************************************)

  (** the exception raised when the EndOfIndent with no matched
   * FormatIndicator is found.
   *)
  exception UnMatchEndOfIndent

  (**
   * the exception raised when the specified indent offset plus the current
   * indent is less than 0.
   * @params offset
   * @param offset the indent offset which causes the indent underflow.
   *)
  exception IndentUnderFlow of int

  (***************************************************************************)

  (**
   *  translates the symbol into a text representation which fits within the
   * specified column width.
   * <p>
   *  This function tries to insert newline characters so that the text can
   * fit within the specified column width, but it may exceed the specified
   * column width if the column width is too small.
   * </p>
   * @params parameter symbol
   * @param parameter parameters which control the printer
   * @param symbol the symbol to be translated.
   * @return the text representation of the symbol.
   *)
  val format : PrinterParameter.parameter list -> symbol -> string

  (***************************************************************************)

end

