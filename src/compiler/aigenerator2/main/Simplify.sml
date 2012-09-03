(**
 * A-Normal simplifier
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: Simplify.sml,v 1.6 2008/08/06 17:23:39 ohori Exp $
 *
 * Simple A-Normal simplifier.
 *)
structure Simplify : sig

  (*
   * reduce unused or called-less-than-once ANMERGEPOINT.
   *)
  val reduceCluster : YAANormal.clusterDecl -> YAANormal.clusterDecl

end =
struct
local
  structure ID = VarID
in

  structure AN = YAANormal

  fun substMERGE substLabel decls andeclList =
      case andeclList of
        nil => nil
      | (h as AN.ANMERGE {label, ...}) :: t =>
        if ID.eq (substLabel, label) then decls else h::t
      | AN.ANHANDLE {try, exnVar, handler, labels, loc} :: t =>
        AN.ANHANDLE {try = substMERGE substLabel decls try,
                     exnVar = exnVar,
                     handler = substMERGE substLabel decls handler,
                     labels = labels,
                     loc = loc}
        :: substMERGE substLabel decls t
      | AN.ANSWITCH {value, valueTy, branches, default, loc} :: t =>
        let
          val newBranches =
              map (fn {constant, branch} =>
                      {constant = constant,
                       branch = substMERGE substLabel decls branch})
                  branches
          val newDefault = substMERGE substLabel decls default
        in
          AN.ANSWITCH {value = value,
                       valueTy = valueTy,
                       branches = newBranches,
                       default = newDefault,
                       loc = loc}
          :: substMERGE substLabel decls t
        end
      | h :: t =>
        h :: substMERGE substLabel decls t

  fun nextMERGEPOINT (l as AN.ANMERGEPOINT _::_) = l
    | nextMERGEPOINT (h::t) = nextMERGEPOINT t
    | nextMERGEPOINT nil = nil

  fun reduce counter dst andeclList =
      case andeclList of
        nil => (counter, rev dst)

      | (h as AN.ANMERGE {label, ...})::t =>
        let
          val counter =
              case ID.Map.find (counter, label) of
                SOME x => ID.Map.insert (counter, label, x + 1)
              | NONE => ID.Map.insert (counter, label, 1)
        in
          reduce counter (h::dst) (nextMERGEPOINT t)
        end

      | (h as AN.ANMERGEPOINT {label, leaveHandler, ...})::t =>
        (case ID.Map.find (counter, label) of
           NONE =>
           (* never MERGEed. eliminate this merge. *)
           reduce counter dst (nextMERGEPOINT t)
         | SOME x =>
           let
             val (counter, dst2) = reduce counter nil t
             val dst =
                 case leaveHandler of
                   (* keep this MERGEPOINT if leaveHandler exists. *)
                   SOME _ => rev (h::dst) @ dst2
                 | NONE =>
                   if x > 1
                   then rev (h::dst) @ dst2
                   else substMERGE label dst2 (rev dst)
           in
             (counter, dst)
           end)

      | AN.ANHANDLE {try, exnVar, handler, labels, loc} :: t =>
        let
          val (counter, newTry) = reduce counter nil try
          val (counter, newHandler) = reduce counter nil handler
          val newDecl = AN.ANHANDLE {try = newTry,
                                     exnVar = exnVar,
                                     handler = newHandler,
                                     labels = labels,
                                     loc = loc}
        in
          reduce counter (newDecl::dst) (nextMERGEPOINT t)
        end

      | AN.ANSWITCH {value, valueTy, branches, default, loc} :: t =>
        let
          val (counter, newBranches) =
              foldr
                (fn ({constant, branch}, (counter, branches)) =>
                    let
                      val (counter, newBranch) = reduce counter nil branch
                      val branch = {constant = constant, branch = newBranch}
                    in
                      (counter, branch::branches)
                    end)
                (counter, nil)
                branches
          val (counter, newDefault) = reduce counter nil default
          val newDecl = AN.ANSWITCH {value = value,
                                     valueTy = valueTy,
                                     branches = newBranches,
                                     default = newDefault,
                                     loc = loc}
        in
          reduce counter (newDecl::dst) (nextMERGEPOINT t)
        end

      | AN.ANVALCODE {codeList, loc} :: t =>
        let
          val newDecl =
              AN.ANVALCODE {codeList = map reduceCodeDecl codeList,
                            loc = loc}
        in
          reduce counter (newDecl::dst) t
        end

      | h::t =>
        reduce counter (h::dst) t

  and reduceCodeDecl ({codeId, argVarList, body, resultTyList,
                       loc}:AN.codeDecl) =
      let
        val (_, body) = reduce ID.Map.empty nil body
      in
        {
          codeId = codeId,
          argVarList = argVarList,
          body = body,
          resultTyList = resultTyList,
          loc = loc
        } : AN.codeDecl
      end

  fun reduceFunDecl ({codeId, argVarList, body, resultTyList,
                      ffiAttributes, loc}:AN.funDecl) =
      let
        val (_, body) = reduce ID.Map.empty nil body
      in
        {
          codeId = codeId,
          argVarList = argVarList,
          body = body,
          resultTyList = resultTyList,
          ffiAttributes = ffiAttributes,
          loc = loc
        } : AN.funDecl
      end

  fun reduceCluster ({clusterId, frameInfo, entryFunctions, hasClosureEnv,
                      loc}:AN.clusterDecl) =
      let
        val entryFunctions = map reduceFunDecl entryFunctions
      in
        {
          clusterId = clusterId,
          frameInfo = frameInfo,
          entryFunctions = entryFunctions,
          hasClosureEnv = hasClosureEnv,
          loc = loc
        } : AN.clusterDecl
      end

end
end
