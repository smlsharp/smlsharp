(**
 *  This module translates the expressions into a text representation which fits
 * within the specified column width.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PrettyPrinter.sml,v 1.5 2008/02/28 13:08:30 kiyoshiy Exp $
 *)
structure PrettyPrinter =
struct

  (***************************************************************************)

  structure FE = FormatExpression
  structure PE = PreProcessedExpression
  structure PP = PrinterParameter

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
   *  translates the expression into a text representation which fits within
   * the specified column width.
   * <p>
   *  This function tries to insert newline characters so that the text can
   * fit within the specified column width, but it may exceed the specified
   * column width if the column width is too small.
   * </p>
   * @params parameter expression
   * @param parameter parameters which control the printer
   * @param expression the expression to be translated.
   * @return the text representation of the expression.
   *)
  fun format (parameters : PP.parameterRecord) =
    let
      val initialCols = #columns parameters
      val spaceString = #spaceString parameters
      val newlineString = #newlineString parameters
      val cutOverTail = #cutOverTail parameters

      datatype line =
               Unclosed of string
             | Closed of string
             | Truncated of string

      type context =
           {
             (** the number of remaining columns. *)
             cols : int,
             (** line list in reversed order. *)
             lines : line list,
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
                (List.tabulate (newIndentSize, fn _ => spaceString))
            end

      (** creates a string of specified number of whitespaces.
       * @params size
       * @param size the number of whitespace characters
       * @return a string consisted of the <code>size</code> whitespaces.
       *)
      fun makeIndent size =
          String.concat (List.tabulate (size, fn _ => spaceString))

      fun checkOverTail ifNotOver string =
          let
            val sizeOfString = size string
          in
            if cutOverTail andalso initialCols < sizeOfString
            then
              Truncated
                  (if initialCols < 2 orelse sizeOfString < 2
                   then ".."
                   else String.substring (string, 0, initialCols - 2) ^ "..")
            else ifNotOver string
          end
      fun appendToLine text (Unclosed line :: lines') =
          let val str = line ^ text
          in (checkOverTail Unclosed str) :: lines'
          end
        | appendToLine text (lines as (Truncated _ :: _)) = lines
        | appendToLine text lines = (Unclosed text) :: lines
      fun closeLine (Unclosed line :: lines) =
          (checkOverTail Closed line) :: lines
        | closeLine (Truncated line :: lines) = (Closed line) :: lines
        | closeLine lines = (Closed "") :: lines
      fun linesToString ({lines, ...} : context) =
          let
            val strings =
                map
                    (fn (Closed s) => s ^ newlineString
                      | (Truncated s) => s ^ newlineString
                      | (Unclosed s) => s)
                    (List.rev lines) (* lines are in reversed order. *)
          in
            String.concat strings
          end

      fun visit canMultiline (context : context) (PE.Term (columns, text)) =
          {
            cols = (#cols context) - columns,
            lines = appendToLine text (#lines context),
            indentString = #indentString context,
            indentWidth = #indentWidth context,
            indentStack = #indentStack context
          }

        | visit
          canMultiline
          context
          (PE.List
           {
             expressions,
             environment = unsortedEnvironment
           }) =
          let

            (*
              sort environment entries in descending order of the priority
            *)
            val environment =
                sort
                (fn (left, right) =>
                    PE.isHigherThan (#priority left, #priority right))
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

            val newContext =
                foldl
                    (fn (expression, context) =>
                        visit allPreferredMultiLined context expression)
                    {
                      cols = #cols context,
                      lines = #lines context,
                      indentString =
                          makeIndent (initialCols - (#cols context)),
                      indentWidth = (initialCols - (#cols context)),
                      indentStack = []
                    }
                    expressions

          in
            {
              cols = #cols newContext, (* from newContext *)
              lines = #lines newContext,
              indentString = #indentString context,
              indentWidth = #indentWidth context,
              indentStack = #indentStack context
            }
          end

        | visit canMultiline context (PE.StartOfIndent indent) =
          let
            val newIndentStack = indent :: (#indentStack context)
            val newIndentWidth = #indentWidth context + indent
            val newIndentString =
                extendIndent
                (#indentString context) (#indentWidth context) indent
          in
            {
              cols = #cols context,
              lines = #lines context,
              indentString = newIndentString,
              indentWidth = newIndentWidth,
              indentStack = newIndentStack
            }
          end

        | visit canMultiline context (PE.Indicator {space, newline}) =
          if ! newline
          then
            let
              val newCols = initialCols - (#indentWidth context)
            in
              {
                cols = newCols,
                lines =
                    appendToLine
                        (#indentString context) (closeLine (#lines context)),
                indentString = #indentString context,
                indentWidth = #indentWidth context,
                indentStack = #indentStack context
              }
            end
          else
            if space
            then visit canMultiline context (PE.Term (1, spaceString))
            else context

        | visit
          canMultiline context (PE.DeferredIndicator{space, requiredColumns}) =
          if canMultiline andalso (#cols context) < (!requiredColumns) 
          then
            let
              val newCols = initialCols - (#indentWidth context)
            in
              {
                cols = newCols,
                lines =
                    appendToLine
                        (#indentString context) (closeLine (#lines context)),
                indentString = #indentString context,
                indentWidth = #indentWidth context,
                indentStack = #indentStack context
              }
            end
          else
            if space
            then visit canMultiline context (PE.Term (1, spaceString))
            else context

        | visit _ context PE.EndOfIndent =
          case #indentStack context
           of [] => raise UnMatchEndOfIndent
            | (indent :: newIndentStack) =>
              let
                val newIndentString =
                    extendIndent
                    (#indentString context) (#indentWidth context) (~indent)
                val newIndentWidth = #indentWidth context - indent
              in
                {
                  cols = #cols context,
                  lines = #lines context,
                  indentString = newIndentString,
                  indentWidth = newIndentWidth,
                  indentStack = newIndentStack
                }
              end
    in
      linesToString
      o (visit
             true
             {
               cols = initialCols,
               lines = [],
               indentString = "",
               indentWidth = 0,
               indentStack = []
            })
    end

  (***************************************************************************)

end