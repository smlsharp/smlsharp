(**
 * A-Normal call analysis
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: CallAnalysis.sml,v 1.8 2008/08/06 17:23:39 ohori Exp $
 *
 * This phase analyzes ANormal code to provide sufficient information
 * to replace LOCALCALLs with JUMPs and construct clean CFG.
 *)
structure CallAnalysis : sig

  datatype routine =
       EntryFunction of YAANormal.funDecl
     | Code of YAANormal.codeDecl
     | Continue of YAANormal.id

  type routineInfo =
      {
        label: YAANormal.id,
        routine: routine,
        (* number of non-tail local calls *)
        callCount: int,
        (* number of tail local calls except self tail call *)
        tailCallCount: int,
        (* number of self recursive tail local calls *)
        selfCallCount: int,
        (* initial available handlers; NONE = outside handler is enabled *)
        handlers: YAANormal.id option list
      }

  (*
   * routineInfo list is ordered in preorder depth-first order.
   *)
  val analyze : YAANormal.clusterDecl -> routineInfo list

end =
struct
local
  structure ID = VarID
in

  structure AN = YAANormal

  datatype routine =
       EntryFunction of AN.funDecl
     | Code of AN.codeDecl
     | Continue of AN.id

  type routineInfo =
      {
        label: AN.id,
        routine: routine,
        callCount: int,
        tailCallCount: int,
        selfCallCount: int,
        handlers: AN.id option list
      }

  fun getLabel (EntryFunction {codeId, ...}) = codeId
    | getLabel (Code {codeId, ...}) = codeId
    | getLabel (Continue label) = label

  fun isHead (EntryFunction _) = true
    | isHead (Code _) = true
    | isHead _ = false

  fun isCode (Code _) = true
    | isCode _ = false

  fun isContinue (Continue _) = true
    | isContinue _ = false

  (*********************************************************************)

  datatype call =
      Call of               (* ANLOCALCALL *)
      {to: AN.id, return: AN.id, handler: AN.id option}
    | Jump of AN.id         (* ANTAILLOCALCALL *)
    | UnknownCall of
      {knownDestinations: AN.id list ref, return: AN.id, handler: AN.id option}
    | UnknownJump of AN.id list ref
    | Return of AN.id list ref

  structure IDOptSet =
    BinarySetFn(
      struct
        type ord_key = ID.id option
        fun compare (NONE, NONE) = EQUAL
          | compare (NONE, SOME _) = LESS
          | compare (SOME _, NONE) = GREATER
          | compare (SOME x, SOME y) = ID.compare (x, y)
      end
    )

  local

    fun add (map, k, v) =
        case ID.Map.find (map, k) of
          SOME s => ID.Map.insert (map, k, ID.Set.add (s, v))
        | NONE => ID.Map.insert (map, k, ID.Set.singleton v)

    fun get (map, k) =
        case ID.Map.find (map, k) of
          SOME s => s
        | NONE => ID.Set.empty

    fun addOpt (map, k, v) =
        case ID.Map.find (map, k) of
          SOME s => ID.Map.insert (map, k, IDOptSet.add (s, v))
        | NONE => ID.Map.insert (map, k, IDOptSet.singleton v)

    fun getOpt (map, k) =
        case ID.Map.find (map, k) of
          SOME s => s
        | NONE => IDOptSet.empty

  in

  (*
   * compute possible destinations of each UnknownCall and UnknownJump
   *)
  fun resolveUnknownCalls routines =
      let
        val l = map #1 routines
        val codeLabels = map getLabel (List.filter isCode l)
        val headLabels = map getLabel (List.filter isHead l)
      in
        map
          (fn (routine, calls) =>
              (routine,
               foldr
                 (fn (call, z) =>
                     case call of
                       UnknownCall {knownDestinations, return, handler} =>
                       (* may call arbitrary code *)
                       (
                         knownDestinations := codeLabels;
                         map (fn to => Call {to = to,
                                             return = return,
                                             handler = handler})
                             codeLabels
                         @ z
                       )
                     | UnknownJump knownDestinations =>
                       (* may go to arbitrary code or function *)
                       (
                         knownDestinations := headLabels;
                         map Jump headLabels @ z
                       )
                     | _ => call :: z)
                 nil
                 calls))
          routines
      end

  (*
   * compute possible destinations of each Return.
   *
   * Note that if A local-calls B and B tail-local-calls C,
   * then C must local-return to A, not B.
   *)
  fun resolveReturn routines =
      let
        val (workSet, edges, returnSet) =
            foldl
              (fn ((routine, calls), z) =>
                  let
                    val from = getLabel routine
                  in
                    foldl
                      (fn (call, z as (works, edges, set)) =>
                          case call of
                            Call {to, return, ...} =>
                            (works, edges, add (set, to, return))
                          | Jump to =>
                            ((from, to) :: works, add (edges, from, to), set)
                          | _ => z)
                      z
                      calls
                  end)
              (nil, ID.Map.empty, ID.Map.empty)
              routines

        fun loop nil returnSet = returnSet
          | loop ((from, to)::workSet) returnSet =
            let
              val set1 = get (returnSet, from)
              val set2 = get (returnSet, to)
              val newSet = ID.Set.union (set1, set2)
              val returnSet = ID.Map.insert (returnSet, to, newSet)
              val workSet =
                  if ID.Set.isSubset (newSet, set2)
                  then workSet
                  else ID.Set.foldl (fn (x,z) => (to, x)::z)
                                    workSet
                                    (get (edges, to))
            in
              loop workSet returnSet
            end

        val returnSet = loop workSet returnSet

        val contLabels =
            map getLabel (List.filter isContinue (map #1 routines))
      in
        map
          (fn (routine, calls) =>
              let
                val label = getLabel routine
              in
                (routine,
                 foldr
                   (fn (call, z) =>
                       case call of
                         Return knownDestinations =>
                         let
                           val dests =
                               case ID.Map.find (returnSet, label) of
                                 SOME set => ID.Set.listItems set
                               | NONE => contLabels
                         in
                           case dests of
                             nil =>
                             raise Control.Bug
                                       ("resolveReturn: no position to return:\
                                        \ LOCALRETURN in "^ID.toString label)
                           | _ => ();
                           knownDestinations := dests;
                           map Jump dests @ z
                         end
                       | _ => call :: z)
                   nil
                   calls)
              end)
          routines
      end

  (*
   * compute possible initial handler set of each routine.
   *)
  fun analyzeHandler routines =
      let
        val (workSet, edges, handlerSet) =
            foldl
              (fn ((routine, calls), (work, edges, set)) =>
                  let
                    val from = getLabel routine

                    (* entryFunction may be called from outside. *)
                    val set =
                        case routine of
                          EntryFunction _ => addOpt (set, from, NONE)
                        | _ => set
                  in
                    foldl
                      (fn (Call {to, handler, ...}, (works, edges, set)) =>
                          (works,
                           add (edges, from, to),
                           addOpt (set, to, handler))
                        | (_, z) => z)
                      (work, edges, set)
                      calls
                  end)
              (nil, ID.Map.empty, ID.Map.empty)
              routines

        (*
         * Actually there is no cycle in local-call relations, but
         * we calculate fixpoint to keep the algorithm simple.
         *)
        fun loop nil handlerSet = handlerSet
          | loop ((from, to)::workSet) handlerSet =
            let
              val set1 = getOpt (handlerSet, from)
              val set2 = getOpt (handlerSet, to)
              val newSet = IDOptSet.union (set1, set2)
              val handlerSet = ID.Map.insert (handlerSet, to, newSet)
              val workSet =
                  if IDOptSet.isSubset (newSet, set2)
                  then workSet
                  else ID.Set.foldl (fn (x,z) => (to, x)::z)
                                    workSet
                                    (get (edges, to))
            in
              loop workSet handlerSet
            end
      in
        loop workSet handlerSet
      end

  (*
   * compute local-call statistics
   *)
  fun analyzeCall routines =
      let
        fun inc (map, k) =
            case ID.Map.find (map, k) of
              SOME x => ID.Map.insert (map, k, x + 1)
            | NONE => ID.Map.insert (map, k, 1)

        fun get (map, k) =
            case ID.Map.find (map, k) of SOME x => x | NONE => 0

        val handlerMap = analyzeHandler routines

        val (callCount, selfCount, jumpCount) =
            foldl
              (fn ((routine, calls), z) =>
                  let
                    val label = getLabel routine
                  in
                    foldl
                      (fn (Call {to, return, ...}, (calls, selfs, jumps)) =>
                          (inc (calls, to), selfs, jumps)
                        | (Jump to, (calls, selfs, jumps)) =>
                          if ID.eq (label, to)
                          then (calls, inc (selfs, to), jumps)
                          else (calls, selfs, inc (jumps, to))
                        | (x, z) => z)
                      z
                      calls
                  end)
              (ID.Map.empty, ID.Map.empty, ID.Map.empty)
              routines
      in
        map
          (fn (routine, call) =>
              let
                val label = getLabel routine
              in
                {
                  label = label,
                  routine = routine,
                  callCount = get (callCount, label),
                  selfCallCount = get (selfCount, label),
                  tailCallCount = get (jumpCount, label),
                  handlers = IDOptSet.listItems (getOpt (handlerMap, label))
                } : routineInfo
              end)
          routines
      end

  end  (* local *)

  (*********************************************************************)

  (*
   * FIXME: we should make effort to determine destinations as much as
   *        possible even if funLabel is not a constant.
   *)
  fun analyzeExp handlerLabel anexp =
      case anexp of
        AN.ANVALUE _ => (nil, nil)
      | AN.ANCONST _ => (nil, nil)
      | AN.ANFOREIGNAPPLY _ => (nil, nil)
      | AN.ANCALLBACKCLOSURE _ => (nil, nil)
      | AN.ANENVACC _ => (nil, nil)
      | AN.ANGETFIELD _ => (nil, nil)
      | AN.ANARRAY _ => (nil, nil)
      | AN.ANPRIMAPPLY _ => (nil, nil)
      | AN.ANAPPLY _ => (nil, nil)
      | AN.ANCALL _ => (nil, nil)
      | AN.ANRECCALL _ => (nil, nil)

      | AN.ANLOCALCALL {codeLabel = AN.ANLOCALCODE label,
                        knownDestinations, returnLabel, ...} =>
        (
          knownDestinations := [label];
          ([(Continue returnLabel, nil)],
           [Call {to = label, return = returnLabel, handler = handlerLabel}])
        )
      | AN.ANLOCALCALL {codeLabel, knownDestinations, returnLabel, ...} =>
        ([(Continue returnLabel, nil)],
         [UnknownCall {knownDestinations = knownDestinations,
                       return = returnLabel,
                       handler = handlerLabel}])

      | AN.ANRECORD _ => (nil, nil)
      | AN.ANSELECT _ => (nil, nil)
      | AN.ANCLOSURE _ => (nil, nil)
      | AN.ANRECCLOSURE _ => (nil, nil)
      | AN.ANMODIFY _ => (nil, nil)

  fun analyzeDecl handlerLabel andecl =
      case andecl of
        AN.ANSETFIELD _ => (nil, nil)
      | AN.ANSETTAIL _ => (nil, nil)
      | AN.ANCOPYARRAY _ => (nil, nil)
      | AN.ANTAILAPPLY _ => (nil, nil)
      | AN.ANTAILCALL _ => (nil, nil)
      | AN.ANTAILRECCALL _ => (nil, nil)
      | AN.ANRETURN _ => (nil, nil)
      | AN.ANVAL {exp, ...} => analyzeExp handlerLabel exp
      | AN.ANVALCODE {codeList, loc} =>
        (analyzeCodeDeclList codeList, nil)

      | AN.ANTAILLOCALCALL {codeLabel = AN.ANLOCALCODE label,
                            knownDestinations, ...} =>
        (
          knownDestinations := [label];
          (nil, [Jump label])
        )
      | AN.ANTAILLOCALCALL {codeLabel, knownDestinations, ...} =>
        (nil, [UnknownJump knownDestinations])

      | AN.ANLOCALRETURN {knownDestinations, ...} =>
        (nil, [Return knownDestinations])

      | AN.ANMERGE _ => (nil, nil)
      | AN.ANMERGEPOINT _ => (nil, nil)
      | AN.ANRAISE _ => (nil, nil)
      | AN.ANHANDLE {try, exnVar, handler=handlerCode,
                     labels={handlerLabel=newHandlerLabel,...}, loc} =>
        let
          val (routines1, calls1) = analyzeDeclList (SOME newHandlerLabel) try
          val (routines2, calls2) = analyzeDeclList handlerLabel handlerCode
        in
          (routines1 @ routines2, calls1 @ calls2)
        end
      | AN.ANSWITCH {value, valueTy, branches, default, loc} =>
        foldr
          (fn ({branch, ...}, (routines, calls)) =>
              let
                val (routines2, calls2) = analyzeDeclList handlerLabel branch
              in
                (routines2 @ routines, calls2 @ calls)
              end)
          (analyzeDeclList handlerLabel default)
          branches

  and analyzeDeclList handlerLabel (andecl::andeclList) =
      let
        val (routines1, calls1) = analyzeDecl handlerLabel andecl
        val (routines2, calls2) = analyzeDeclList handlerLabel andeclList
      in
        (routines1 @ routines2, calls1 @ calls2)
      end
    | analyzeDeclList handlerLabel nil = (nil, nil)

  and analyzeCodeDecl (codeDecl as {body, ...} : AN.codeDecl) =
      let
        val (routines, calls) = analyzeDeclList NONE body
      in
        (Code codeDecl, calls) :: routines
      end

  and analyzeCodeDeclList l =
      foldr (fn (x, z) => analyzeCodeDecl x @ z) nil l

  and analyzeFunDecl con (funDecl as {body, ...}:AN.funDecl) =
      let
        val (routines, calls) = analyzeDeclList NONE body
      in
        (con funDecl, calls) :: routines
      end

  fun analyzeFunDeclList con l =
      foldr (fn (x, z) => analyzeFunDecl con x @ z) nil l

  (*********************************************************************)

  fun analyze ({entryFunctions, ...}:AN.clusterDecl) =
      let
(*
val _ = print "\nCallAnalysis.analyze:\n"
*)
        val routines = analyzeFunDeclList EntryFunction entryFunctions
        val routines = resolveUnknownCalls routines
        val routines = resolveReturn routines
        val routines = analyzeCall routines
      in
(*
        app
          (fn {label, routine, callCount, tailCallCount, selfCallCount} =>
              (
                print ("label: "^ID.toString label^"\n");
                print ("routine: "^
                       (case routine of
                        | EntryFunction {codeId, ...} => "Entry "^ID.toString codeId^"\n"
                        | Code {codeId, ...} => "Code "^ID.toString codeId^"\n"
                        | Continue x => "Continue "^ID.toString x^"\n"));
                print ("callCount: "^Int.toString callCount^"\n");
                print ("tailCallCount: "^Int.toString tailCallCount^"\n");
                print ("selfCallCount: "^Int.toString selfCallCount^"\n")
              ))
          routines;
        print "--\n";
*)
          routines
      end

end
end
