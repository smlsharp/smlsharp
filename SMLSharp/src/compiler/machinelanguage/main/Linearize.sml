(**
 * Rearrange basic blocks for linear code emission.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: Linearize.sml,v 1.4 2008/08/06 17:23:40 ohori Exp $
 *)
structure Linearize : sig

  val linearize
      : 'target MachineLanguage.program -> 'target MachineLanguage.program

end =
struct

  structure ID = VarID
  structure M = MachineLanguage

(*
  local

    fun add (label, map) =
        case ID.Map.find (map, label) of
          SOME x => ID.Map.insert (map, label, x + 1)
        | NONE => ID.Map.insert (map, 1)

    fun someCons (SOME x, l) = x :: l
      | someCons (NONE, l) = l

  in

  fun countPredecessor blocks =
      foldl (fn ({continue, jump, ...}:M.basicBlock, edges) =>
                foldl add edges (someCons (continue, jump)))
            ID.Map.empty
            blocks

  end
*)

  fun 'a linearizeBody (context as {blockMap}) queue visited =
      case queue of
        nil => (nil, visited)
      | label::queue =>
        if ID.Set.member (visited, label)
        then linearizeBody context queue visited
        else
          let
            val {label, instructionList, continue, jump, loc}:'a M.basicBlock =
                case ID.Map.find (blockMap, label) of
                  SOME x => x
                | NONE => raise Control.Bug "linearizeBody"

            val visited = ID.Set.add (visited, label)

            val (continue, queue) =
                case continue of
                  NONE => (NONE, queue)
                | SOME nextLabel =>
                  if ID.Set.member (visited, nextLabel)
                  then (SOME nextLabel, queue @ [nextLabel])
                  else (NONE, nextLabel :: queue)

            val block =
                {
                  label = label,
                  instructionList = instructionList,
                  continue = continue,
                  jump = nil,
                  loc = loc
                } : 'a M.basicBlock

            val queue = queue @ jump
            val (blocks, visited) = linearizeBody context queue visited
          in
            (block::blocks, visited)
          end

  fun linearizeEntries context (entry::entries) visited =
      let
        val (blocks1, visited) = linearizeBody context [entry] visited
        val (blocks2, visited) = linearizeEntries context entries visited
      in
        (blocks1 @ blocks2, visited)
      end
    | linearizeEntries context nil visited = (nil, visited)

  fun linearizeCluster ({name, entries, registerDesc, frameInfo, body,
                         alignment, loc}:'a M.cluster) =
      let
        val blockMap =
            foldl (fn (block as {label, ...}, map) =>
                      ID.Map.insert (map, label, block))
                  ID.Map.empty
                  body

(*
        val predCount = countpredecessor body
*)

        val context = {blockMap = blockMap}

        val (newBody, visited) =
            linearizeEntries context entries ID.Set.empty

        (* export all basic blocks anyway *)
        val unreachables =
            List.mapPartial
              (fn {label, ...} =>
                  if ID.Set.member (visited, label)
                  then NONE else SOME label)
              body

        val newBody =
            case unreachables of
              nil => newBody
            | _ => newBody @ #1 (linearizeEntries context unreachables visited)
      in
        {
          name = name,
          entries = entries,
          registerDesc = registerDesc,
          frameInfo = frameInfo,
          alignment = alignment,
          body = newBody,
          loc = loc
        } : 'a M.cluster
      end

  fun linearize ({toplevel, clusters, constants,
                  unboxedGlobals, boxedGlobals}:'a M.program) =
      {
        toplevel = toplevel,
        clusters = map linearizeCluster clusters,
        constants = constants,
        unboxedGlobals = unboxedGlobals,
        boxedGlobals = boxedGlobals
      } : 'a M.program

end
