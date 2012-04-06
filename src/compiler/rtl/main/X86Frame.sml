(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86Frame : RTLFRAME =
struct

  structure R = RTL
  structure Emit = X86Emit

  fun sizeof ty = #size (X86Emit.formatOf ty)
  val maxAlign = #size X86Emit.formatOfGeneric

  fun frameOffset headerSize {frameSize, offset} =
      offset - (frameSize + headerSize)

  fun frameInfo headerSize =
      {preOffset = 0w0,
       postOffset = Word.fromInt (8 + headerSize),
       frameAlign = maxAlign,
       wordSize = sizeof (R.Int32 R.U),
       pointerSize = sizeof (R.Ptr R.Void),
       frameHeaderOffset = ~4,
       frameOffset = frameOffset headerSize}

  fun ceil (m, n) =
      (m + n - 1) - (m + n - 1) mod n

  fun allocateCluster (cluster as {clusterId, frameBitmap, baseLabel, body,
                                   preFrameSize, postFrameSize, numHeaderWords,
                                   loc}:R.cluster) =
      let
        (*
         * Structure of Frame:
         *
         * addr
         *  | :          :
         *  | +----------+ [align 16] ---------------------------
         *  | :PostFrame : (need to allocate)                ^
         *  | |          |                                   |
         *  | +==========+ [align 16]  preOffset = 0         |
         *  | | Frame    | (need to allocate)                | need to alloc
         *  | |          |                                   |
         *  | +==========+ postOffset = 12 or 16             |
         *  | | header   | (4 or 8 bytes)                    v
         *  | +----------+ 8/16 <---- ebp -----------------------
         *  | | push ebp |
         *  | +----------+ 4/16
         *  | | ret addr |
         *  | +==========+ [align 16] ---------------------------
         *  | | PreFrame | (allocated by caller)             ^
         *  | :          :                                   | preFrameSize
         *  | |          |                                   v
         *  | +----------+ [align 16] ---------------------------
         *  | :          :
         *  v
         *)
        val _ = if numHeaderWords = 1 orelse numHeaderWords = 2
                then ()
                else raise Control.Bug "allocateCluster: numHeaderWords"

        val headerSize = sizeof (R.Ptr R.Void) * numHeaderWords

        val {slotIndex, frameSize, initCode, frameCode} =
            FrameLayout.allocate (frameInfo headerSize) cluster

        (* substitute COMPUTE_FRAME with frameCode *)
        val body =
            RTLEdit.extend
              (fn (RTLEdit.MIDDLE (R.COMPUTE_FRAME {uses, clobs})) =>
                  let
                    val code = frameCode clobs
                    val focus = RTLEdit.singletonFirst R.ENTER
                    val focus = RTLEdit.insertBefore (focus, code)
                    val graph = RTLEdit.unfocus focus
                  in
                    X86Subst.substitute
                      (fn {id,...} => case VarID.Map.find (uses, id) of
                                        SOME v => SOME (R.REG v)
                                      | NONE => NONE)
                      graph
                  end
                | (RTLEdit.MIDDLE insn) =>
                  RTLEdit.unfocus (RTLEdit.singleton insn)
                | (RTLEdit.FIRST (first as R.CODEENTRY _)) =>
                  let
                    val focus = RTLEdit.singletonFirst first
                    val focus = RTLEdit.insertBefore (focus, initCode)
                  in
                    RTLEdit.unfocus focus
                  end
                | (RTLEdit.FIRST first) =>
                  RTLEdit.unfocus (RTLEdit.singletonFirst first)
                | (RTLEdit.LAST last) =>
                  RTLEdit.unfocus (RTLEdit.singletonLast last))
              body

        (*
         * addr
         *  | :           :
         *  | +-----------+     --------------------------- (aligned)
         *  | | POSTFRAME |                             ^
         *  | +-----------+     ------                  |
         *  | | frame     |       |                     | allocSize
         *  | +-----------+       | framePointerOffset  |
         *  | | header    |       v                     v
         *  | +-----------+ %ebp --------------------------
         *  | | push ebp  |       ^                  |
         *  | +-----------+       | systemSpaceSize  |
         *  | |return addr|       v                  | preFrameOrigin
         *  | +-----------+ ---------- (aligned)     |
         *  | | PREFRAME  |   ^ preFrameSize         |
         *  | |           |   v                      v
         *  | +-----------+ -------------------------------
         *  v :           :
         *)
        val systemSpaceSize =
            sizeof (R.Ptr R.Void) + sizeof (R.Ptr R.Code)
        val preFrameOrigin =
            systemSpaceSize + preFrameSize
        val framePointerOffset =
            frameSize + headerSize
        val allocSize =
            ceil (systemSpaceSize + framePointerOffset + postFrameSize,
                  maxAlign) - systemSpaceSize
        val postFrameOrigin =
            ~allocSize
        val slotIndex =
            VarID.Map.map (fn i => i - framePointerOffset) slotIndex

        val cluster =
            {
              clusterId = clusterId,
              frameBitmap = frameBitmap,
              baseLabel = baseLabel,
              body = body,
              preFrameSize = preFrameSize,
              postFrameSize = postFrameSize,
              numHeaderWords = numHeaderWords,
              loc = loc
            } : R.cluster

        val layout =
            {
              slotIndex = slotIndex,
              preFrameOrigin = preFrameOrigin,
              postFrameOrigin = postFrameOrigin,
              frameAllocSize = allocSize
            } : X86Emit.frameLayout
      in
        (R.CLUSTER cluster, ClusterID.Map.singleton (clusterId, layout))
      end

  fun allocate nil = (nil, ClusterID.Map.empty)
    | allocate (topdecl::topdecls) =
      let
        val (topdecl, envMap1) =
            case topdecl of
              R.CLUSTER cluster => allocateCluster cluster
            | R.TOPLEVEL _ => (topdecl, ClusterID.Map.empty)
            | R.DATA _ => (topdecl, ClusterID.Map.empty)
            | R.BSS _ => (topdecl, ClusterID.Map.empty)
            | R.X86GET_PC_THUNK_BX _ => (topdecl, ClusterID.Map.empty)
            | R.EXTERN _ => (topdecl, ClusterID.Map.empty)
        val (topdecls, envMap2) = allocate topdecls
      in
        (topdecl::topdecls, ClusterID.Map.unionWith #2 (envMap1, envMap2))
      end

end
