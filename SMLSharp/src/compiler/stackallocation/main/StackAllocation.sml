(**
 * Stack allocation.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: StackAllocation.sml,v 1.6 2008/08/06 17:23:40 ohori Exp $
 *)
structure StackAllocation (*: STACKALLOCATION *) =
struct

  structure M = MachineLanguage
  type hoge = VMMnemonic.instruction list

  fun isSubset (map1, map2) =
      LocalVarID.Map.foldli (fn (k, v, z) =>
                        z andalso
                        case LocalVarID.Map.find (map2, k) of
                          SOME _ => true | NONE => false)
                    true
                    map1

  fun minusMap (map1, map2) =
      LocalVarID.Map.foldli (fn (k, v, map) =>
                        case LocalVarID.Map.find (map2, k) of
                          SOME _ => map
                        | NONE => LocalVarID.Map.insert (map, k, v))
                    LocalVarID.Map.empty
                    map1

  fun addVars vars map =
      foldl (fn (var as {id, ...}:M.varInfo, map) =>
                LocalVarID.Map.insert (map, id, var))
            map vars

  fun minusVars vars map =
      minusMap (map, addVars vars LocalVarID.Map.empty)

  fun usedef ({instructionList, ...}:hoge M.basicBlock) =
      foldr
        (fn (insn, (useSet, defSet)) =>
            case insn of
              M.Spill {dst, src} => (useSet, defSet)      (* ignore it *)
            | M.Code {use, def, code, ...} =>
              let
                val defSet = addVars def defSet
                val useSet = addVars use (minusVars def useSet)
              in
                (useSet, defSet)
              end)
        (LocalVarID.Map.empty, LocalVarID.Map.empty)
        instructionList

  fun propagateLive insnList live =
      foldr
        (fn (insn, (insns, live)) =>
            case insn of
              M.Spill {dst, src} => (insns, live)         (* ignore it *)
            | M.Code {use, def, ...} =>
              let
                val next = addVars use (minusVars def live)
              in
                ({liveIn = next, liveOut = live, insn = insn}::insns, next)
              end)
        (nil, live)
        insnList


(*
let
val _ = print (Control.prettyPrint (MachineLanguage.format_instruction VMCodeFormatter.formatInsnList insn) ^ "\n");
val x as (useSet, defSet) =

in
  print "\nUSE: ";
  LocalVarID.Map.app (fn v => print (" " ^ Control.prettyPrint (M.format_varInfo v))) useSet;
  print "\nDEF: ";
  LocalVarID.Map.app (fn v => print (" " ^ Control.prettyPrint (M.format_varInfo v))) defSet;
  print "\n";
  x
end
*)

  fun liveness (blocks : hoge M.basicBlock list) =
      let
        fun add map from to =
            case LocalVarID.Map.find (map, to) of
              NONE => LocalVarID.Map.insert (map, to, [from])
            | SOME l => LocalVarID.Map.insert (map, to, from::l)

        fun get map to =
            case LocalVarID.Map.find (map, to) of
              SOME l => l | NONE => nil

        datatype analysis =
            X of {use: M.varInfo LocalVarID.Map.map,
                  def: M.varInfo LocalVarID.Map.map,
                  liveIn: M.varInfo LocalVarID.Map.map ref,
                  liveOut: M.varInfo LocalVarID.Map.map ref,
                  (* edges: (live in * predecessor) list *)
                  edges: (M.varInfo LocalVarID.Map.map ref * analysis) list ref}

        val (predMap, graph) =
            foldl
              (fn (block as {label, continue, jump, ...}, (edges, graph)) =>
                  let
                    val succ = case continue of
                                 SOME x => x :: jump | NONE => jump
                    val (use, def) = usedef block
                    val node =
                        X {use = use,
                           def = def,
                           liveIn = ref use,
                           liveOut = ref LocalVarID.Map.empty,
                           edges = ref nil}  (* initialized later *)
                  in
                    (foldl (fn (to, edges) => add edges label to) edges succ,
                     LocalVarID.Map.insert (graph, label, node))
                  end)
              (LocalVarID.Map.empty, LocalVarID.Map.empty)
              blocks

        val _ =
            LocalVarID.Map.appi
              (fn (label, X {use, def, liveIn, liveOut, edges}) =>
                  edges :=
                    map (fn l => (liveIn, valOf (LocalVarID.Map.find (graph, l))))
                        (get predMap label))
              graph

        val workSet =
            LocalVarID.Map.foldr (fn (X {edges = ref l, ...}, z) => l @ z)
                         nil graph

        fun loop nil = ()
          | loop ((ref succLiveIn, node)::workSet) =
            let
              val X {use, def, liveIn as ref oldIn, liveOut as ref oldOut,
                     edges = ref edges} = node

              val newOut = LocalVarID.Map.unionWith #1 (succLiveIn, oldOut)
              val newIn  = LocalVarID.Map.unionWith #1 (use, minusMap (newOut, def))
              val _ = liveOut := newOut
              val _ = liveIn := newIn
              val workSet =
                  if isSubset (newIn, oldIn)
                  then workSet
                  else edges @ workSet
            in
              loop workSet
            end
      in
        loop workSet;
        map (fn block as {label, instructionList, ...} =>
                let
                  val X {liveIn=ref liveIn, liveOut=ref liveOut, ...} =
                      valOf (LocalVarID.Map.find (graph, label))
                  val (insns, propedLive) =
                      propagateLive instructionList liveOut
(*
                  (* assert *)
                  val _ =
                      if map LocalVarID.toString (LocalVarID.Map.listKeys liveIn)
                         = map LocalVarID.toString (LocalVarID.Map.listKeys propedLive)
                      then ()
                      else raise Control.Bug "hoge"
*)
                in
                  {block = block, insnList = insns}
                end)
            blocks
      end
      handle Option => raise Control.Bug "liveness: Option"



(*
  type context =
      {
        registerDesc: M.registerDesc,
        alloc: M.entity LocalVarID.Map.map,
        count: int
      }

  fun coerceTy Move (context:context) varList ents =
      foldr
        (fn ({ty, ...}, varEnt, moves) =>
            case ty of
              M.REG class =>
              let
                val {registers, ...} =
                    List.nth (#classes (#registerDesc context)) class
                    handle Subscript => raise Control.Bug "coerceTy: REG"
                val reg =
                    (* FIXME: this is kludge. *)
                    Last.last registers
                    handle Empty => raise Control.Bug "coerceTy: REG 2"
              in
                Move (varEnt, A.REGISTER (class, reg)) :: forces
              end
            | M.VAR _ => moves
            | M.ALLOCED ent => Move (varEnt, ent) :: forces)
        nil
        (varList, ents)

  val coerceUse = coerceTy (fn (v,e) => M.Move {src = v, dst = e})
  val coerceDef = coerceTy (fn (v,e) => M.Move {src = e, dst = v})

  fun getRegisterClass ty =
      case ty of
        M.VAR x => x
      | M.REG x => x
      | M.STK x => x
      | M.ALLOCED (M.REGISTER (x, _)) => x
      | M.ALLOCED (M.STACK (x, _)) => x
      | M.ALLOCED (M.ARG (x, _)) => x

  fun allocVar (context as {alloc, count, ...}:context)
               (var as {id, displayName, ty}:M.varInfo) =
      case LocalVarID.Map.find (alloc, id) of
        SOME ent => (context, ent)
      | NONE =>
        let
          val class = getRegisterClass ty
          val ent = M.STACK (class, count)
          val count = count + 1
          val alloc = LocalVarID.Map.insert (alloc, id, ent)
        in
          ({
             registerDesc = #registerDesc context,
             alloc = alloc,
             count = count
           } : context,
           ent)
        end

  fun allocVarList context (Var::VarList) =
      let
        val (context, Var) = allocVar context Var
        val (context, Vars) = allocVarList context VarList
      in
        (context, Var :: Vars)
      end
    | allocVarList context nil = (context, nil)

  fun replaceTy ({id, displayName, ty}:M.varInfo, newTy) =
      {id = id, displayName = displayName, ty = newTy} : M.varInfo

*)

  type context =
      {
        registerClasses: M.registerClassDesc vector,
        alloc: M.varInfo LocalVarID.Map.map,    (* varInfo#id -> allocated varInfo *)
        handlerVar: (M.registerClassId * M.slotId) option, (* for HANDLER *)
        count: M.slotId                 (* stack frame slot ID counter *)
      }


  fun registerClass ({registerClasses, ...}:context) classId =
      Vector.sub (registerClasses, classId)
      handle Subscript =>
             raise Control.Bug ("registerClass: undefined register class : "^
                                Int.toString classId)

  fun liveRegisters context liveVars =
      LocalVarID.Map.foldli
        (fn (id, var, z) =>
            let
              val {id, ty, ...} =
                  case LocalVarID.Map.find (#alloc context, id) of
                    SOME var => var | NONE => var
            in
              case ty of
                M.ALLOCED (M.REGISTER (class, reg)) =>
                let
                  val classDesc = registerClass context class
                in
                  case WEnv.find (#interference classDesc, reg) of
                    NONE => WSet.add (z, reg)
                  | SOME regs => foldl (fn (r,z) => WSet.add (z,r))
                                       (WSet.add (z,reg)) regs
                end
              | _ => z
            end)
        WSet.empty
        liveVars

  fun makeFrameInfo (context as {registerClasses, alloc, handlerVar, count}
                     :context) =
      let
        val handler =
            case handlerVar of
              NONE => nil
            | SOME (classId, slotId) =>
              [{class = Vector.sub (registerClasses, classId),
                slotIds = [slotId]}]

        fun add map classId slotId =
            case IEnv.find (map, classId) of
              SOME x => IEnv.insert (map, classId, WSet.add (x, slotId))
            | NONE => IEnv.insert (map, classId, WSet.singleton slotId)

        fun toFrameInfo map =
            IEnv.foldri
              (fn (classId, slotSet, z) =>
                  {class = Vector.sub (registerClasses, classId),
                   slotIds = WSet.listItems slotSet} :: z)
              nil map

        val {boxed, unboxed, generic, free} =
            LocalVarID.Map.foldl
              (fn ({ty = M.ALLOCED (M.STACK (classId, slotId)), ...},
                   {boxed, unboxed, generic, free}) =>
                  (case #tag (Vector.sub (registerClasses, classId)) of
                     M.BOXED =>
                     {boxed = add boxed classId slotId,
                      unboxed = unboxed,
                      generic = generic,
                      free = free}
                   | M.UNBOXED =>
                     {boxed = boxed,
                      unboxed = add unboxed classId slotId,
                      generic = generic,
                      free = free}
                   | M.GENERIC _ =>
                     {boxed = boxed,
                      unboxed = unboxed,
                      generic = add generic classId slotId,
                      free = free}
                   | M.FREEGENERIC _ =>
                     {boxed = boxed,
                      unboxed = unboxed,
                      generic = generic,
                      free = add free classId slotId})
                | (_, z) => z)
              {boxed = IEnv.empty,
               unboxed = IEnv.empty,
               generic = IEnv.empty,
               free = IEnv.empty}
              alloc
      in
        {
          handler = handler,
          boxed = toFrameInfo boxed,
          unboxed = toFrameInfo unboxed,
          generic = toFrameInfo generic,
          freeGeneric = toFrameInfo free
        } : M.frameInfo
      end
      handle Subscript =>
             raise Control.Bug "makeFrameInfo: undefined register class"

  fun addAlloc (context as {alloc, ...}:context) (varInfo as {id,...}) count =
      {
        registerClasses = #registerClasses context,
        alloc = LocalVarID.Map.insert (alloc, id, varInfo),
        handlerVar = #handlerVar context,
        count = count
      } : context

  fun allocHandler (context as {count, handlerVar, ...}:context) live
                   ({id, displayName, ...}:M.varInfo) class =
      let
        val (handlerVar, count) =
            case handlerVar of
              NONE => (SOME (class, count), count + 0w1)
            | SOME (handlerClass, handlerSlotId) =>
              if class = handlerClass then (handlerVar, count)
              else raise Control.Bug "allocHandler"

        val varInfo =
            {
              id = id,
              displayName = displayName,
              ty = M.ALLOCED (M.HANDLER class)
            } : M.varInfo
      in
        (addAlloc context varInfo count,
         LocalVarID.Map.insert (live, id, varInfo),
         varInfo)
      end

  fun allocRegister (context as {alloc, ...}:context) live
                    ({id, displayName, ...}:M.varInfo) entity =
      let
        val varInfo =
            {
              id = id,
              displayName = displayName,
              ty = M.ALLOCED entity
            } : M.varInfo
      in
        (addAlloc context varInfo (#count context),
         LocalVarID.Map.insert (live, id, varInfo),
         varInfo)
      end

  fun allocStack (context as {count, alloc, ...}:context) live
                 ({id, displayName, ...}:M.varInfo) class =
      let
        val varInfo =
            {
              id = id,
              displayName = displayName,
              ty = M.ALLOCED (M.STACK (class, count))
            } : M.varInfo
      in
        (addAlloc context varInfo (count + 0w1),
         LocalVarID.Map.insert (live, id, varInfo),
         varInfo)
      end

  fun allocVars context live nil = (context, nil)
    | allocVars (context as {alloc, ...}:context) live
                ((var as {id, ty, ...}:M.varInfo)::varList) =
      let
        val allocedVar = LocalVarID.Map.find (alloc, id)

        val (context, live, varInfo) =
            case allocedVar of
              SOME (allocedVar as {ty = M.ALLOCED ent, ...}) =>
              let
                val unifiable =
                    case (ent, ty) of
                      (ent, M.ALLOCED ent2) => ent = ent2
                    | (M.REGISTER (class,_), M.REG class2) => class = class2
                    | (M.REGISTER (class,_), M.VAR class2) => class = class2
                    | (M.STACK (class,_), M.STK class2) => class = class2
                    | (M.STACK (class,_), M.VAR class2) => class = class2
                    | _ => false

                val _ =
                    if unifiable then ()
                    else raise Control.Bug "FIXME: allocVars: move"
              in
                (context, live, allocedVar)
              end
            | SOME _ =>
              raise Control.Bug "allocedVar"
            | NONE =>
              case ty of
                M.ALLOCED (M.HANDLER class) =>
                allocHandler context live var class
              | M.ALLOCED ent =>
                (addAlloc context var (#count context),
                 LocalVarID.Map.insert (live, id, var), var)
              | M.REG class =>
                let
                  (* FIXME: need to construct interference graph *)
                  val liveRegs = liveRegisters context live
                  val candidates = #registers (registerClass context class)
                  val entity =
                      case List.find (fn x => not (WSet.member (liveRegs, x)))
                                     candidates of
                        SOME x => M.REGISTER (class, x)
                      | NONE => raise Control.Bug "allocVars: no free reg"
                in
                  allocRegister context live var entity
                end
              | M.STK class => allocStack context live var class
              | M.VAR class => allocStack context live var class

        val (context, vars) = allocVars context live varList
      in
        (context, varInfo :: vars)
      end

  fun allocInsn context insn =
      case insn of
        {insn = M.Spill _, ...} =>
        (context, nil)   (* ignore previous spills *)
      | {insn = M.Code {code, use, def, clob, kind, loc}, liveIn, liveOut} =>
        let
          val (context, use) = allocVars context liveIn use
          val (context, def) = allocVars context liveOut def
        in
          (context,
           [
             M.Code {code = code,
                     use = use,
                     def = def,
                     clob = clob,
                     kind = kind,
                     loc = loc}
           ])
        end

  fun allocInsnList context (insn::insnList) =
      let
        val (context, insn) = allocInsn context insn
        val (context, insns) = allocInsnList context insnList
      in
        (context, insn @ insns)
      end
    | allocInsnList context nil = (context, nil)

  fun allocBlock context ({block:hoge M.basicBlock, insnList}) =
      let
        val (context, insns) = allocInsnList context insnList
      in
        (context,
         {
           label = #label block,
           instructionList = insns,
           continue = #continue block,
           jump = #jump block,
           loc = #loc block
         } : hoge M.basicBlock)
      end

  fun allocBlockList context (block::blockList) =
      let
        val (context, block) = allocBlock context block
        val (context, blocks) = allocBlockList context blockList
      in
        (context, block::blocks)
      end
    | allocBlockList context nil = (context, nil)

  fun allocCluster ({name, registerDesc, frameInfo, entries, body,
                     alignment, loc}:hoge M.cluster) =
      let
        val body = liveness body

(*
        val _ = print "Liveness Analysis:\n"
        val _ = print (Control.prettyPrint
                           (M.format_clusterWithLiveness
                                VMCodeFormatter.formatInsnList
                                {name = name, body = body}))
        val _ = print "\n"
*)

        val context =
            {
              registerClasses = Vector.fromList (#classes registerDesc),
              alloc = LocalVarID.Map.empty,
              handlerVar = NONE,
              count = 0w0
            } : context

        val (context, body) = allocBlockList context body

        val frameInfo = makeFrameInfo context
      in
        {
          name = name,
          entries = entries,
          registerDesc = registerDesc,
          frameInfo = frameInfo,
          alignment = alignment,
          body = body,
          loc = loc
        } : hoge M.cluster
      end

  fun allocate ({toplevel, clusters, constants,
                 unboxedGlobals, boxedGlobals}:hoge M.program) =
      {
        toplevel = toplevel,
        clusters = map allocCluster clusters,
        constants = constants,
        unboxedGlobals = unboxedGlobals,
        boxedGlobals = boxedGlobals
      }

end
