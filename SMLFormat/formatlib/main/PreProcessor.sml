(**
 *  This module translates FormatExpression.expression into
 * PrettyPrinter.symbol.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PreProcessor.sml,v 1.4 2007/06/01 01:04:34 kiyoshiy Exp $
 *)
structure PreProcessor :> PREPROCESSOR =
struct

  (***************************************************************************)

  structure FE = FormatExpression
  structure PP = PrettyPrinter
  structure Param = PrinterParameter

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

  type parameter =
       {
         spaceString : string,
         guardLeft : string,
         guardRight : string,
         maxDepthOfGuards : int option,
         maxWidthOfGuards : int option
       }

  (**
   * global shared information.
   * <p>
   * The context is passed from the beginning to the end of the format
   * expression list acrossing guards.
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
            (maybe acrossing start/end of guard. *)
         charsAfterNewline : int ref
       }

  (***************************************************************************)

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

    type entry =
         {
           (** this entry records the counters for indicators of this
            * priority. *)
           priority : FE.priority,

           (** indicates whether to insert newlines at the positions of these
            * indicators. *)
           newline : bool ref,

           (** the number of characters after the last indicator whose priority
            * is higher than the priority of this entry. The indent width at
            * that indicator is included. *)
           total : int,

           (** the maximum of the number of characters among those between
            * indicators of the higer priority than this priority. *)
           max : int,

           (** The number of characters after the last indicator of this
            * priority. The indent width at that indicator is included in
            * this value. This field is used as the initial value of the
            * 'total' field for the entries of the 'weaker' priority than this
            * entry.*)
           subTotal : int
         }

    type environment = entry list

    (*************************************************************************)

    (** create new environment
     * @return new environment. *)
    fun create () =
        [
          {
            priority = FE.Preferred 0,
            newline = ref false,
            total = 0,
            max = 0,
            subTotal = 0
          }
        ]

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
    fun getEntry E currentIndentWidth priority =
        let
          (**
           *  Search the entry of the specified priority.
           *  If not found, add new entry whose the 'total' and 'max' field are
           * copied from the entry of the least priority in the entries of the
           * higher priority than the specified priority.
           * @params (entries, scanned, maxOfLower, higerEntry)
           * @param entries the entries to be scanned
           * @param scanned the already scanned entries
           * @param maxOfLower the maximum value in the values of 'max' fields
           *     of entries of the lower priority than the specified priority.
           * @param higherEntry the entry whose priority is higher than the
           *          specified priority.
           * @return a pair of the entry for the specified entry and the
           *      environment which may not equal to the initial env (E).
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
          find (E, [], 0, NONE)
        end

    (**
     * apply the function to the entries in the environment.
     * @params function environment
     * @param function the function to apply
     * @param environment the environment
     * @return the list of return values by the application of the function
     *       to the entries of the environment.
     *)
    fun map f E = List.map f E

    (** remove the entry of the specified priority from the environment.
     * @params env priority
     * @param env the environment
     * @param priority the priority of the entry to remove
     * @return the removed entry(NONE if not found) and the new environment.
     *)
    fun removeEntry E priority =
        let
          fun find ([] : entry list, scanned) = (NONE, scanned)
            | find ((entry as {priority = p, ...}) :: entries, scanned) =
              if p = priority
              then (SOME entry, scanned @ entries)
              else find (entries, entry :: scanned)
        in
          find (E, [])
        end

  end

  (***************************************************************************)

  (**
   * calculates the length of the string and updates environment.
   * <p>
   * <ul>
   *   <li>calculates the column width which is required to display the
   *      text representation of the symbol in one line.</li>
   *   <li>updates the ENV by updates or insert entries in the passed ENV.</li>
   * </ul>
   * </p>
   * @params parameter ENV context symbol
   * @param parameter parameters which control the printer
   * @param ENV the environment which records counters for each newline
   *        priorities.
   * @param context the information about indents.
   * @param symbol a format expression.
   * @return a quad-tuple whose elements are:
   *       <ul>
   *         <li>updated ENV</li>
   *         <li>updated context</li>
   *         <li>the symbol of PrettyPrinter.symbol</li>
   *         <li>ENV entries for the Deferred priority generated until each
   *           FormatIndicator.</li>
   *       </ul>
   *)
  fun calculate
      (parameter : parameter)
      ENV
      (context : context)
      (FE.Term (columns, text)) =
      let
        fun scanner (entry : Environment.entry) =
            {
              priority = #priority entry,
              newline = #newline entry,
              total = (#total entry) + columns,
              max = #max entry,
              subTotal = (#subTotal entry) + columns
            }
        val newENV = Environment.map scanner ENV
        val _ = #charsAfterNewline context :=
                !(#charsAfterNewline context) + columns
      in
        (newENV, context, PP.Term (columns, text))
      end

    | calculate parameter ENV context (FE.StartOfIndent indent) =
      (
        ENV,
        {
          totalIndent = (#totalIndent context) + indent,
          indentStack = indent :: (#indentStack context),
          countOfEndOfIndent = #countOfEndOfIndent context,
          charsAfterNewline = #charsAfterNewline context
        },
        PP.StartOfIndent indent
      )

    | calculate
      parameter
      ENV
      context
      (FE.Indicator {space, newline = SOME newline}) =
      let
        val textLen = if space then 1 else 0
        fun scanner (entry : Environment.entry) =
            let
              val (newMax, newTotal, newSubTotal) = 
                  if FE.isHigherThan (#priority newline, #priority entry)
                  then
                    (* updates entries for lower priorities than the current
                      indicator. *)
                    (
                      Int.max (#total entry, #max entry),
                      #totalIndent context,
                      #totalIndent context
                    )
                  else
                    (* treats this indicator as a whitespace for higher or
                      equal priorities than the current indicator. *)
                    (
                      #max entry,
                      (#total entry) + textLen,
                      if (#priority newline) = (#priority entry)
                      then #totalIndent context
                      else (#subTotal entry) + textLen
                    )
            in
              (* returns the entry of which the 'total' and 'max' fields are
                updated. *)
              {
                priority = #priority entry,
                newline = #newline entry,
                total = newTotal,
                max = newMax,
                subTotal = newSubTotal
              }
            end
        val newENV = Environment.map scanner ENV

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
              contained in the newENV.
               If the priority of this indicator is deferred one, a new entry
              is always generated because any entry for deferred has been
              removed by the just above code. *)
            val (newENVEntry, newENV) =
                Environment.getEntry
                newENV
                (#totalIndent context)
                (#priority newline)
          in
            (
              newENV,
              newContext, 
              PP.Indicator {space = space, newline = #newline newENVEntry}
            )
          end
        | FE.Deferred =>
          (
            newENV,
            newContext,
            PP.DeferredIndicator
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

    | calculate parameter ENV context (FE.Guard (NONE, symbols)) =
      let
        val guard =
            FE.Indicator
            {space = false, newline = SOME {priority = FE.Preferred 0}}
        val {
              ENV = innerENV,
              context = innerContext,
              result
            } =
            foldl
            (fn (symbol, {ENV, context, result}) =>
                let
                  val (newENV, newContext, newSymbol) =
                      calculate parameter ENV context symbol
                in
                  {
                    ENV = newENV,
                    context = newContext,
                    result = newSymbol :: result (* in reverse order *)
                  }
                end)
            {
              ENV = Environment.create (),
              context =
              {
                totalIndent = 0,
                indentStack = [0],
                countOfEndOfIndent = #countOfEndOfIndent context,
                charsAfterNewline = #charsAfterNewline context
              },
              result = []
            }
            (symbols @ [guard]) (* append guard *)

        (* separate the guard entry and the others *)
        val (guardEntry, innerENV) =
            Environment.removeEntry innerENV (FE.Preferred 0)

        (* add the total size of inner symbols to each entries of outer env.
          The total length of this list is stored in the total field of the
          guard. *)
        val totalSize = #total (valOf guardEntry)
        fun scanner (entry : Environment.entry) =
            {
              priority = #priority entry,
              newline = #newline entry,
              total = (#total entry) + totalSize,
              max = #max entry,
              subTotal = #subTotal entry + totalSize
            }
        val newEnv = Environment.map scanner ENV

        (* translate ENVs of inner to formatEnvironment *)
        fun translateENVEntry (srcEntry : Environment.entry) =
            {
              requiredColumns = #max srcEntry,
              newline = #newline srcEntry,
              priority = #priority srcEntry
            }
        val newSymbol =
            PP.List
            {
              symbols = List.rev (tl result), (* remove the guard *)
              environment = Environment.map translateENVEntry innerENV
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
          newSymbol
        )
      end

    | calculate parameter ENV context (FE.Guard (SOME _, symbols)) =
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
        PP.EndOfIndent
      )

  (***************************************************************************)

  local
    val elision =
(*
        FE.Term (3, "...")
*)
        FE.Guard
            (
              NONE,
              [
                FE.Indicator
                    {space = true, newline = SOME{priority = FE.Deferred}},
                FE.Term (3, "...")
              ]
            )
  in
  fun cutOff (parameter : parameter) symbol =
      let
        val isCutOffDepth =
            case #maxDepthOfGuards parameter of
              NONE => (fn _ => false)
            | SOME depth => (fn d => depth <= d)
        fun keepSymbol (FE.StartOfIndent _) = true
          | keepSymbol FE.EndOfIndent = true
          | keepSymbol _ = false
        fun takeHead _ accum [] = List.rev accum
          | takeHead 0 accum symbols =
            (List.rev accum) @ elision :: (List.filter keepSymbol symbols)
          | takeHead w accum ((symbol as FE.Term _) :: symbols) =
            takeHead (w - 1) (symbol :: accum) symbols
          | takeHead w accum ((symbol as FE.Guard _) :: symbols) =
            takeHead (w - 1) (symbol :: accum) symbols
          | takeHead w accum (symbol :: symbols) =
            takeHead w (symbol :: accum) symbols
        fun visit depth (FE.Guard (enclosedAssocOpt, symbols)) =
            if isCutOffDepth depth
            then elision
            else
              let
                val symbols' = 
                    map
                        (visit (depth + 1)) 
                        (case #maxWidthOfGuards parameter of
                           NONE => symbols
                         | SOME width => takeHead width [] symbols)
              in
                FE.Guard (enclosedAssocOpt, symbols')
              end
          | visit depth symbol = symbol
      in
        visit 0 symbol
      end
  end

  (***************************************************************************)

  fun removeAssoc (parameter : parameter) symbol =
      let
        (**
         * compare two assocs.
         * <p>
         * The weakThan relation('<') on assocs is defined as follows:
         * <ul>
         *   <li>An < Bm if n < m (A,B is L,R or N)</li>
         *   <li>Ln < Nn</li>
         *   <li>Rn < Nn</li>
         *   <li>p < q, if p < r and r < q</li>
         * </ul>
         * </p>
         * @params (left, right)
         * @param left a assoc to be compared.
         * @param right another assoc to be compared.
         * @return true if left < right
         *)
        fun weakThan (left : FE.assoc, right : FE.assoc) =
            if #strength left < #strength right
            then true
            else
              if #strength left = #strength right 
              then
                case (#direction left, #direction right) of
                  (FE.Left, FE.Neutral) => true
                | (FE.Right, FE.Neutral) => true
                | _ => false
              else false

        (**
         * enclose symbols in a pair of parentheses.
         * @params symbols
         * @param symbols a list of format expressions
         * @return the symbols enclosed in a pair of parentheses.
         *)
        fun encloseSymbols symbols =
            [
              FE.Term (1, #guardLeft parameter),
              FE.StartOfIndent 1
(*
              FE.Indicator
              {
                space = false,
                newline =
                SOME {priority = FE.Preferred 1}
              }
*)
            ] @
            symbols @
            [
(*
              FE.EndOfIndent,
              FE.Indicator
              {
                space = false,
                newline =
                SOME {priority = FE.Preferred 1}
              },
*)
              FE.Term (1, #guardRight parameter),
              FE.EndOfIndent
            ]

        (**
         *  visit format expressions to remove assoc indicators and insert
         * parentheses if needed.
         * @params enclosingAssoc symbol
         * @param  enclosingAssoc the assoc of the assoc indicator
         *       which enclose this symbol.
         * @param symbol the format expression to be visited.
         * @return a symbol which contains no assoc indicator.
         *)
        fun visit
            enclosingAssoc
            (FE.Guard (enclosedAssocOpt, symbols)) =
            let
              (* the assoc to inherit to the (first) children *)
              val inheritToFirstAssoc as {cut, strength, direction} =
                  case enclosedAssocOpt of
                    NONE => enclosingAssoc
                  | SOME(enclosedAssoc) => enclosedAssoc
              (* the assoc to inherit to the other children *)
              val inheritToOtherAssoc = 
                  {cut = cut, strength = strength, direction = FE.Neutral}

              (**
               *  Visit the children with specified assoc to inherit.
               *
               *  To the first Term of Guard, <code>toFirstChild</code> is
               * inherited.  While the <code>toFirstChild</code> is inherited
               * also to the FormatIndicator/EndOfIndent children between the
               * head of list and the first Term/Guard, the inherited
               * assocs are not considered in these visit.
               *  To children after the first Term/Guard child,
               * <code>toOther</code> is inherited.
               *)
              fun visitList (toFirstChild, toOther) children =
                  let
                    fun scan _ [] visited = List.rev visited
                      | scan toInherit (head::others) visited =
                        let
                          val visited' = (visit toInherit head) :: visited
                        in
                          case head of
                            (* switch the assoc to pass to children. *)
                            FE.Guard _ => scan toOther others visited'
                          | FE.Term _ => scan toOther others visited'
                          | _ => scan toInherit others visited'
                        end
                  in
                    scan toFirstChild children []
                  end

              val newSymbols =
                  case direction of 
                    FE.Left =>
                    (* pass Ln to the left-most child Term/Guard,
                     * Nn to the other following it. *)
                    visitList
                    (inheritToFirstAssoc, inheritToOtherAssoc)
                    symbols

                  | FE.Right =>
                    (* pass Rn to the right-most child Term/Guard,
                     * Nn to the other following it. *)
                    List.rev
                    (visitList
                     (inheritToFirstAssoc, inheritToOtherAssoc)
                     (List.rev symbols))

                  | _ => List.map (visit inheritToFirstAssoc) symbols
            in
              case enclosedAssocOpt of
                NONE => FE.Guard (NONE, newSymbols)
              | SOME {cut = true, ...} => FE.Guard (NONE, newSymbols)
              | SOME enclosedAssoc =>
                if weakThan (enclosingAssoc, enclosedAssoc) orelse
                   enclosingAssoc = enclosedAssoc
                then FE.Guard (NONE, newSymbols)
                else FE.Guard (NONE, encloseSymbols newSymbols)
            end
          | visit enclosing symbol = symbol
      in
        visit {cut = true, strength = ~1, direction = FE.Neutral} symbol
      end
                 
  (***************************************************************************)

  (**
   *  translates a FormatExpression.expression into a PrettyPrinter.symbol.
   * @params parameter symbol
   * @param parameter parameters which control the printer
   * @param symbol a format expression
   * @return a PrettyPrinter.symbol translated from the symbol.
   *)
  fun preProcess parameterList =
      let
        val (
              spaceString,
              guardLeft,
              guardRight,
              maxDepthOfGuards,
              maxWidthOfGuards
            ) =
            List.foldl
                (fn (param, (space, left, right, depth, width)) =>
                  case param
                   of Param.Space s => (s, left, right, depth, width)
                    | Param.GuardLeft s => (space, s, right, depth, width)
                    | Param.GuardRight s => (space, left, s, depth, width)
                    | Param.MaxDepthOfGuards no =>
                      (space, left, right, no, width)
                    | Param.MaxWidthOfGuards no =>
                      (space, left, right, depth, no)
                    | _ => (space, left, right, depth, width))
                (
                  Param.defaultSpace,
                  Param.defaultGuardLeft,
                  Param.defaultGuardRight,
                  Param.defaultMaxDepthOfGuards,
                  Param.defaultMaxWidthOfGuards
                )
                parameterList

        val parameter =
            {
              spaceString = spaceString,
              guardLeft = guardLeft,
              guardRight = guardRight,
              maxDepthOfGuards = maxDepthOfGuards,
              maxWidthOfGuards = maxWidthOfGuards
            } : parameter
      in
        (* avoid to hold unnecessary references to format expression which can
         * be very large. *)
        #3
        o (fn symbol =>
              let
                val initialENV = Environment.create ()
                val initialContext =
                    {
                      totalIndent = 0,
                      indentStack = [0],
                      countOfEndOfIndent = 0,
                      charsAfterNewline = ref 0
                    }
              in
                calculate parameter initialENV initialContext symbol
              end)
        o (removeAssoc parameter)
        o (if isSome(maxDepthOfGuards) orelse isSome(maxWidthOfGuards)
           then cutOff parameter
           else (fn symbol => symbol))
      end

  (***************************************************************************)

end;

