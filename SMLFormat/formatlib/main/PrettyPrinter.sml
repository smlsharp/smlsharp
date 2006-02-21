(**
 *  This module translates the symbols into a text representation which fits
 * within the specified column width.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PrettyPrinter.sml,v 1.1 2006/02/07 12:51:52 kiyoshiy Exp $
 *)
structure PrettyPrinter :> PRETTYPRINTER =
struct

  (***************************************************************************)

  structure FE = FormatExpression

  (***************************************************************************)

  type environmentEntry =
       {
         requiredColumns : int, 
         newline : bool ref,
         priority : FE.priority
       }

  type environment = environmentEntry list

  datatype symbol =
           Term of (int * string)
         | List of
           {
             symbols : symbol list,
             environment : environment
           }
         | Indicator of {space : bool, newline : bool ref}
         | DeferredIndicator of {space : bool, requiredColumns : int ref}
         | StartOfIndent of int
         | EndOfIndent

  (***************************************************************************)

  (**
   * raised when any error occurs.
   * @params message
   * @param message the error message
   *)
  exception Fail of string

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
   * sorts a list
   * @params comparator list
   * @param comparator a function which compares two elements in the list.
   *       When applied to (left, right), it must return true if left < right.
   * @param list the list to be sorted.
   * @return the sorted list
   *)
  fun sort isBefore list =
    let
      fun insert (element, []) = [element]
        | insert (element, (head :: tail)) =
          if isBefore (element, head)
          then (element :: head :: tail)
          else head :: (insert (element, tail))
    in
      foldl insert [] list
    end

  (****************************************)

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
  fun format (parameter : PrinterParameter.printerParameter) symbol =
    let
      type context =
           {
             cols : int,
             indentString : string,
             indentWidth : int,
             indentStack : int list
           }

      (**
       * extends or shrink a indent
       * @params indentString currentIndentWidth diff
       * @param indentString a string of seqeunce of whitespaces.
       * @param currentIndentWidth the current indent width
       * @param diff the number of charactes by which extend or shrink
       *          the indent.
       * @return the indent text which is extended by diff characters
       *    if diff > 0, or shrinked by diff characters if diff < 0.
       * @exception IndentUnderFlow when addition of the size of indent and
       *         the diff is less than 0.
       *)
      fun extendIndent (indentString : string) currentIndentWidth diff =
          if 0 = diff
          then indentString
          else
            let val newIndentSize = currentIndentWidth + diff
            in
              if newIndentSize < 0 then
                raise IndentUnderFlow diff
              else
                String.concat
                (List.tabulate (newIndentSize, fn _ => #spaceString parameter))
            end

      (** creates a string of specified number of whitespaces.
       * @params size
       * @param size the number of whitespace characters
       * @return a string consisted of the <code>size</code> whitespaces.
       *)
      fun makeIndent size =
          String.concat (List.tabulate (size, fn _ => #spaceString parameter))

      val initialCols = #columns parameter

      fun visit canMultiline (context : context) (Term (columns, text)) =
          (
            text,
            {
              cols = (#cols context) - columns,
              indentString = #indentString context,
              indentWidth = #indentWidth context,
              indentStack = #indentStack context
            }
          )

        | visit
          canMultiline
          context
          (List
           {
             symbols,
             environment = unsortedEnvironment
           }) =
          let

            (*
              sort environment entries in descending order of the priority
            *)
            val environment =
                sort
                (fn (left, right) =>
                    FE.isHigherThan (#priority left, #priority right))
                unsortedEnvironment

            (*
                Decide whether to begin a new line at preferred indicators.
                Decisions are made for the higher priority before for the
               lower priority. ( The 'environment' has been sorted in
               descending order by the above code. )
                The result 'allPreferredMultiLined' is true if newlines begin
               at the all preferred indicators.
             *)
            val allPreferredMultiLined =
                foldl
                (fn ({requiredColumns, newline, priority, ...}, multilined) =>
                    (* the 'multilined' is true if newlines begin at the all
                      preferred indicators in the enclosing guards and the
                      higher preferred indicators in this guard. *)
                    (
                      newline :=
                      (multilined andalso (#cols context) < requiredColumns);
                      ! newline
                    ))
                canMultiline environment

            (*
              translates symbols into their text representation.
              the resut 'strings' contains text representations in reverse
             order.
              and the new context after translation of the last symbol.
            *)
            val (strings, newContext) =
                foldl
                (fn (symbol, (strings, context)) =>
                    let
                      val (string, newContext) =
                          visit allPreferredMultiLined context symbol
                    in
                      (string :: strings, newContext)
                    end)
                (
                   [],
                   {
                     cols = #cols context,
                     indentString = makeIndent (initialCols - (#cols context)),
                     indentWidth = (initialCols - (#cols context)),
                     indentStack = []
                   }
                )
                symbols

            val string = String.concat (List.rev strings)
          in
            (
              string,
              {
                cols = #cols newContext, (* from newContext *)
                indentString = #indentString context,
                indentWidth = #indentWidth context,
                indentStack = #indentStack context
              }
            )
          end

        | visit canMultiline context (StartOfIndent indent) =
          let
            val newIndentStack = indent :: (#indentStack context)
            val newIndentWidth = #indentWidth context + indent
            val newIndentString =
                extendIndent
                (#indentString context) (#indentWidth context) indent
          in
            (
              "",
              {
                cols = #cols context,
                indentString = newIndentString,
                indentWidth = newIndentWidth,
                indentStack = newIndentStack
              }
            )
          end

        | visit canMultiline context (Indicator {space, newline}) =
          if ! newline
          then
            let
              val newCols = initialCols - (#indentWidth context)
            in
              (
                (#newlineString parameter) ^ (#indentString context),
                {
                  cols = newCols,
                  indentString = #indentString context,
                  indentWidth = #indentWidth context,
                  indentStack = #indentStack context
                }
              )
            end
          else
            if space
            then visit canMultiline context (Term (1, #spaceString parameter))
            else ("", context)

        | visit
          canMultiline context (DeferredIndicator {space, requiredColumns}) =
          if canMultiline andalso (#cols context) < (!requiredColumns) 
          then
            let
              val newCols = initialCols - (#indentWidth context)
            in
              (
                (#newlineString parameter) ^ (#indentString context),
                {
                  cols = newCols,
                  indentString = #indentString context,
                  indentWidth = #indentWidth context,
                  indentStack = #indentStack context
                }
              )
            end
          else
            if space
            then visit canMultiline context (Term (1, #spaceString parameter))
            else ("", context)

        | visit _ context EndOfIndent =
          case #indentStack context
           of [] => raise UnMatchEndOfIndent
            | (indent :: newIndentStack) =>
              let
                val newIndentString =
                    extendIndent
                    (#indentString context) (#indentWidth context) (~indent)
                val newIndentWidth = #indentWidth context - indent
              in
                (
                  "",
                  {
                    cols = #cols context,
                    indentString = newIndentString,
                    indentWidth = newIndentWidth,
                    indentStack = newIndentStack
                  }
                )
              end

      val (formatted, _) =
          visit
          true
          {
            cols = initialCols,
            indentString = "",
            indentWidth = 0,
            indentStack = []
          }
          symbol
          handle UnMatchEndOfIndent => raise Fail "unmatched EndOfIndent"
               | IndentUnderFlow indent =>
                 raise Fail ("indent underflow(" ^ Int.toString indent ^ ")")
    in
      formatted
    end

end