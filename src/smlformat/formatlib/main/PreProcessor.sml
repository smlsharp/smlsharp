(**
 *  This module translates FormatExpression.expression into
 * PreProcessedExpression.expression.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PreProcessor.sml,v 1.7 2010/02/09 07:53:18 katsu Exp $
 *)
structure PreProcessor =
struct

  (***************************************************************************)

  structure FE = FormatExpression
  structure PE = PreProcessedExpression

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
   * @params message
   * @param message the error message
   *)
  exception UnMatchEndOfIndent of string

  (***************************************************************************)

  (**
   * global shared information.
   * <p>
   * The context is passed from the beginning to the end of the format
   * expression list beyond guards.
   * </p>
   *)
  type context =
       {
         (** the current indent width. equals to sum of stack. *)
         totalIndent : int,
         (** stack of indent width. pushed by each scope *)
         indentStack : int list,
         (** for error message *)
         countOfEndOfIndent : int,
         (** the number of chars between adjacent newline indicators
            (maybe across start/end of guard. *)
         charsAfterNewline : int ref
       }

  (***************************************************************************)

  val MAX_PRIORITY = ~1
  (** the priority of the Newline format expression. *)
  val NEWLINE_PRIORITY = 0
  (** the highest priority that user can specify. *)
  val MAX_USER_PRIORITY = 1

  infix 6 ++
  (** addition of two integers.
   * This operator clamps the result to the maxInt if Overflow occurs. *)
  fun x ++ y = if SOME x = Int.maxInt then x
               else (x + y) handle Overflow => valOf Int.maxInt

  (**
   * shared information within a guard.
   * <p>
   * The environment is passed from the beginning to the end of the guard.
   * It is not shared between different guards.
   * </p>
   *)
  structure Environment =
  struct

    (*************************************************************************)

    (**
     * Environment has an entry for each priority.
     * <p>
     * For example, assume the following format expression.
     * <pre>
     * 1 "abc" 2 "def" 3 "ghi" 1 "jkl" 2 "mno"
     * </pre>
     * At the end of this expresssion, the entry of priority 2 has the
     * following field values.
     * <pre>
     *  {
     *    total = 6,
     *    max = 9,
     *    subTotal = 3,
     *      :
     *  }
     * </pre>
     * The 'total' field is used to calculate the 'max' field.
     * The 'max' field is used to calculate the number of columns required to
     * print the strings without inserting newlines at the indicators of this
     * priority.
     * The 'subTotal' field is used to as the initial 'total' field for
     * indicators of lower priority than this priority.
     * </p>
     *)
    type entry =
         {
           (** this entry records the counters for indicators of this
            * priority. *)
           priority : FE.priority,

           (** indicates whether to insert newlines at the positions of 
            * indicators of this priority. *)
           newline : bool ref,

           (** the number of characters after the last indicator whose priority
            * is higher than the priority of this entry. The indent width at
            * that indicator is included. *)
           total : int,

           (** the maximum of the number of characters between
            * indicators of the higer priority than this priority.
            * This is equal to the maximum number which the 'total' field of
            * this entry has reached ever. *)
           max : int,

           (** The number of characters after the last indicator of this
            * priority. The indent width at that indicator is included in
            * this value. This field is used as the initial value of the
            * 'total' field for the entries of the lower priority than this
            * entry.*)
           subTotal : int
         }

    type environment = (entry list * FE.priority)

    (*************************************************************************)

    (**
     * increments 'total' field of an entry. 
     * 'max' filed must be updated if necessary.
     *)
    fun addTotal increment (entry : entry) =
        let val newTotal = #total entry ++ increment
        in
          {
            priority = #priority entry,
            newline = #newline entry,
            total = newTotal,
            max = Int.max(#max entry, newTotal),
            subTotal = #subTotal entry
          } : entry
        end
    (**
     * reset 'total' field of an entry. 
     * 'max' filed must be updated if necessary.
     *)
    fun setTotal newTotal (entry : entry) = 
        {
          priority = #priority entry,
          newline = #newline entry,
          total = newTotal,
          max = Int.max(#max entry, newTotal),
          subTotal = #subTotal entry
        } : entry
    (**
     * increments 'subTotal' field of an entry. 
     *)
    fun addSubTotal increment (entry : entry) =
        {
          priority = #priority entry,
          newline = #newline entry,
          total = #total entry,
          max = #max entry,
          subTotal = #subTotal entry ++ increment
        } : entry
    (**
     * reset 'subTotal' field of an entry. 
     *)
    fun setSubTotal newSubTotal (entry : entry) = 
        {
          priority = #priority entry,
          newline = #newline entry,
          total = #total entry,
          max = #max entry,
          subTotal = newSubTotal
        } : entry

    (** create new environment
     * @return new environment. *)
    fun create () =
        (
          [
            {
              priority = FE.Preferred MAX_PRIORITY,
              newline = ref false,
              total = 0,
              max = 0,
              subTotal = 0
            }
          ],
          FE.Preferred MAX_PRIORITY
        )

    (**
     *  get or create the entry of the specified priority in the environment.
     * @params environment currentIndentWidth priority
     * @param environment the environment
     * @param currentIndentWidth width of the indent to be used as the initial
     *                         value of the subtotal of the new entry.
     * @param priority the priority of the entry to get or create.
     * @return the entry of the specified priority, or the new entry if it is
     *     not found.
     *)
    fun getEntry ((E, last) : environment) currentIndentWidth priority =
        let
          (**
           *  Search the entry of the specified priority.
           *  If not found, 'find' adds a new entry whose the 'total' and
           * 'max' field are copied from the entry of the least priority among
           * the entries of higher priority than the specified priority.
           * @params (entries, scanned, maxOfLower, higerEntry)
           * @param entries the entries to be scanned
           * @param scanned the already scanned entries
           * @param maxOfLower the maximum value among the values of 'max'
           *          fields of entries of lower priority than the specified
           *          priority.
           * @param higherEntry the entry whose priority is higher than the
           *          specified priority.
           * @return a pair of the entry for the specified entry and the
           *      environment which may not be equal to the initial env (E).
           *)
          fun find
              ((entry : entry) :: entries, scanned, maxOfLower, higherEntry) =
              if (#priority entry) = priority
              then (entry, E)
              else
                let
                  val newHigherEntry =
                      if
                        FE.isHigherThan (#priority entry, priority)
                        andalso
                        (higherEntry = NONE
                         orelse
                         FE.isHigherThan
                         (#priority (valOf higherEntry), #priority entry))
                      then SOME entry
                      else higherEntry
                  val newMaxOfLower =
                      if
                        FE.isHigherThan (priority, #priority entry) andalso
                        maxOfLower < #max entry
                      then #max entry
                      else maxOfLower
                in
                  find
                  (entries, entry :: scanned, newMaxOfLower, newHigherEntry)
                end

            | find ([], scanned, maxOfLower, SOME ({subTotal, ...} : entry)) =
              let
                val newMax = Int.max (maxOfLower, subTotal)
                val newEntry =
                    {
                      priority = priority,
                      newline = ref false,
                      total = subTotal,
                      max = newMax,
                      subTotal = currentIndentWidth
                    }
              in
                (newEntry, newEntry :: scanned)
              end

            | find ([], _, _, NONE) =
              raise
                Fail
                ("entry of the priority " ^
                 (FE.priorityToString priority) ^
                 " is not found.")
        in
          case find (E, [], 0, NONE)
           of (entry, newE) => (entry, (newE, last))
        end

    (**
     * apply the function to the entries in the environment.
     * @params function environment
     * @param function the function to apply
     * @param environment the environment
     * @return the list of return values by the application of the function
     *       to the entries of the environment.
     *)
    fun map f (E, last) = (List.map f E, last)

    (** remove the entry of the specified priority from the environment.
     * @params env priority
     * @param env the environment
     * @param priority the priority of the entry to remove
     * @return the removed entry(NONE if not found) and the new environment.
     *)
    fun removeEntry (E, last) priority =
        let
          fun find ([] : entry list, scanned) = (NONE, scanned)
            | find ((entry as {priority = p, ...}) :: entries, scanned) =
              if p = priority
              then (SOME entry, scanned @ entries)
              else find (entries, entry :: scanned)
        in
          case find (E, [])
           of (entryOpt, newE) => (entryOpt, (newE, last))
        end

    fun getEntries (E, _) = E
    fun getLastPriority ((_, last) : environment) = last
    fun setLastPriority ((E, _) : environment) last = (E, last) : environment

    fun entryToString {priority, newline, total, max, subTotal} =
        "{priority=" ^ FE.priorityToString priority
        ^ ",newline=" ^ Bool.toString (!newline)
        ^ ",total=" ^ Int.toString total
        ^ ",max=" ^ Int.toString max
        ^ ",subTotal=" ^ Int.toString subTotal
        ^ "}"
    fun toString (entries, priority) =
        "[" ^ String.concatWith "," (List.map entryToString entries)
        ^ "," ^ FE.priorityToString priority
        ^ "]"

  end
  structure E = Environment

  (***************************************************************************)

  (**
   * calculates the length of the string and updates environment.
   * <p>
   * <ul>
   *   <li>calculates the column width which is required to display the
   *      string representation of the expression in one line.</li>
   *   <li>updates the ENV by updating or inserting entries in the passed ENV.
   *     </li>
   * </ul>
   * </p>
   * @params parameter ENV context expression
   * @param parameter parameters to control the printer
   * @param ENV the environment which records counters for each newline
   *        priorities.
   * @param context the information about indents.
   * @param expression a format expression.
   * @return a triple-tuple:
   *       <ul>
   *         <li>updated ENV</li>
   *         <li>updated context</li>
   *         <li>the expression of PrettyPrinter.expression</li>
   *       </ul>
   *)
  fun calculate
      (parameter : PrinterParameter.parameterRecord)
      ENV
      (context : context)
      (FE.Term (columns, text)) =
      let
        val scanner = (E.addTotal columns) o (E.addSubTotal columns)
        val newENV = E.map scanner ENV
        val _ = #charsAfterNewline context :=
                !(#charsAfterNewline context) ++ columns
      in
        (newENV, context, PE.Term (columns, text))
      end

    | calculate parameter ENV context (FE.StartOfIndent indent) =
      (
        ENV,
        {
          totalIndent = (#totalIndent context) ++ indent,
          indentStack = indent :: (#indentStack context),
          countOfEndOfIndent = #countOfEndOfIndent context,
          charsAfterNewline = #charsAfterNewline context
        },
        PE.StartOfIndent indent
      )

    | calculate
      parameter
      ENV
      context
      (FE.Indicator {space, newline = SOME newline}) =
      let
        val textLen = if space then 1 else 0
        fun scanner (entry : E.entry) =
            let
              val (newTotal, newSubTotal) = 
                  if FE.isHigherThan (#priority newline, #priority entry)
                  then
                    (* updates entries for lower priorities than the current
                      indicator. *)
                    (
                      #totalIndent context,
                      #totalIndent context
                    )
                  else
                    (* treats this indicator as a whitespace for higher or
                      equal priorities than the current indicator. *)
                    (
                      (#total entry) ++ textLen,
                      if (#priority newline) = (#priority entry)
                      then #totalIndent context
                      else (#subTotal entry) ++ textLen
                    )
            in
              (* returns the entry of which the 'total' and 'subTotal' fields
               * are updated. *)
              ((E.setTotal newTotal) o (E.setSubTotal newSubTotal)) entry
            end
        val newENV = E.setLastPriority (E.map scanner ENV) (#priority newline)
        val newContext = 
            {
              totalIndent = #totalIndent context,
              indentStack = #indentStack context,
              countOfEndOfIndent = #countOfEndOfIndent context,
              charsAfterNewline = ref textLen
            }
      in
        case #priority newline of
          FE.Preferred _ =>
          let
            (* The current indent width is passed as the second argument.
               This will be ignored if a entry for this priority is already
              contained in the newENV. *)
            val (newENVEntry, newENV) =
                E.getEntry
                newENV
                (#totalIndent context)
                (#priority newline)
          in
            (
              newENV,
              newContext, 
              PE.Indicator {space = space, newline = #newline newENVEntry}
            )
          end
        | FE.Deferred =>
          (
            newENV,
            newContext,
            PE.DeferredIndicator
            {space = space, requiredColumns = #charsAfterNewline newContext}
          )
      end

    | calculate
      parameter ENV context (FE.Indicator {space, newline = NONE}) =
      if space
      then
        calculate
        parameter ENV context (FE.Term (1, #spaceString parameter))
      else
        calculate
        parameter ENV context (FE.Term (0, "")) (* exception ? *)

    | calculate parameter ENV context (FE.Guard (NONE, expressions)) =
      let
        val guard =
            FE.Indicator
                {
                  space = false,
                  newline = SOME {priority = FE.Preferred MAX_PRIORITY}
                }
        (* calculates for inner expressions.
         * A 'guard' indicator of MAX_PRIORITY is appended to the inner
         * expressions.
         * After the calculation, the sum of lengths of inner expressions is
         * obtained in the entry of this MAX_PRIORITY.
         *)
        val {
              ENV = innerENV,
              context = innerContext,
              result
            } =
            foldl
            (fn (expression, {ENV, context, result}) =>
                let
                  val (newENV, newContext, newExpression) =
                      calculate parameter ENV context expression
                in
                  {
                    ENV = newENV,
                    context = newContext,
                    result = newExpression :: result (* in reverse order *)
                  }
                end)
            {
              ENV = E.create (),
              context =
              {
                totalIndent = 0,
                indentStack = [0],
                countOfEndOfIndent = #countOfEndOfIndent context,
                charsAfterNewline = #charsAfterNewline context
              },
              result = []
            }
            (expressions @ [guard]) (* append guard *)

        (* separate the guard entry and the others *)
        val (guardEntry, innerENV) =
            E.removeEntry innerENV (FE.Preferred MAX_PRIORITY)

        (* add the total size of inner expressions to each entries of outer
          env.
          The total length of this list is stored in the total field of the
          guard. *)
        val totalSize = #total (valOf guardEntry)
        val scanner = (E.addTotal totalSize) o (E.addSubTotal totalSize)
        val newEnv = E.map scanner ENV

        (* translate ENVs of inner to formatEnvironment *)
        fun translateENVEntry (srcEntry : E.entry) =
            {
              requiredColumns = #max srcEntry,
              newline = #newline srcEntry,
              priority =
              case #priority srcEntry of
                FE.Preferred n => PE.Preferred n
              | FE.Deferred => PE.Deferred
            }
        val newExpression =
            PE.List
            {
              expressions = List.rev (tl result), (* remove the guard *)
              environment = E.getEntries (E.map translateENVEntry innerENV)
            }

      in
        (
          newEnv,
          {
            totalIndent = #totalIndent context,
            indentStack = #indentStack context,
            countOfEndOfIndent = #countOfEndOfIndent innerContext,
            charsAfterNewline = #charsAfterNewline innerContext
          },
          newExpression
        )
      end

    | calculate parameter ENV context (FE.Guard (SOME _, expressions)) =
      raise Fail "a bug: There is an assoc indicator unremoved."

    | calculate
      parameter
      ENV
      ({indentStack = [_], countOfEndOfIndent, ...} : context)
      FE.EndOfIndent =
      (* The indent stack contains only one element (= dummy element). *)
      raise
        UnMatchEndOfIndent
        ("unmatch EndOfIndent(" ^ Int.toString (countOfEndOfIndent + 1) ^ ")")

    | calculate
      parameter
      ENV
      ({indentStack = [], countOfEndOfIndent, ...} : context)
      FE.EndOfIndent =
      (* The indent stack contains no element.
         This case is impossible. It is a bug if occurs. *)
      raise
        UnMatchEndOfIndent
        ("unmatch EndOfIndent(" ^ Int.toString (countOfEndOfIndent + 1) ^ ")")

    | calculate
      parameter
      ENV
      {
        totalIndent,
        indentStack = topIndent :: remains,
        countOfEndOfIndent,
        charsAfterNewline
      }
      FE.EndOfIndent =
      (
        ENV,
        {
          totalIndent = totalIndent - topIndent,
          indentStack = remains,
          countOfEndOfIndent = countOfEndOfIndent + 1,
          charsAfterNewline = charsAfterNewline
        },
        PE.EndOfIndent
      )

    | calculate parameter ENV context FE.Newline =
      let
        fun scanner (entry : E.entry) =
            if #priority entry = FE.Preferred MAX_PRIORITY
            then
              (* change the 'total' field of the entry of MAX_PRIORITY to very
               * large number, so that, in formatted string, line is broken at
               * all newline indicators in all guards enclosing the current
               * guard. *)
              E.setTotal (valOf Int.maxInt) entry
            else
              if #priority entry = FE.Preferred NEWLINE_PRIORITY
              then
                entry
              else
                (* reset entries of all newline indicators of other priorities.
                 *)
                (E.setTotal (#totalIndent context)
                 o E.setSubTotal (#totalIndent context))
                    entry

        val newENV = E.map scanner ENV

        (* generates an entry of NEWLINE_PRIORITY if necessary. *)
        val (_, newENV) =
            E.getEntry
                newENV
                (#totalIndent context)
                (FE.Preferred NEWLINE_PRIORITY)

      in
        (newENV, context, PE.Indicator {space = false, newline = ref true})
      end

  (***************************************************************************)

  (**
   *  translates a FormatExpression.expression into a PrettyPrinter.expression.
   * @params parameter expression
   * @param parameter parameters which control the printer
   * @param expression a format expression
   * @return a PrettyPrinter.expression translated from the expression.
   *)
  fun preProcess parameter expression =
      let
        val initialENV = E.create ()
        val initialContext =
            {
              totalIndent = 0,
              indentStack = [0],
              countOfEndOfIndent = 0,
              charsAfterNewline = ref 0
            }
      in
        #3 (calculate parameter initialENV initialContext expression)
      end

  (***************************************************************************)

end;
