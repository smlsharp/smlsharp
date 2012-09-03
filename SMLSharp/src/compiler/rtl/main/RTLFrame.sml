structure RTLFrame : sig

  val allocate :
      {
        preOffset: word,  (* offset of the beginning of a frame *)
        postOffset: word, (* offset of the end of frame *)
        frameAlign: int,  (* alignment of frame (same as generic alignment) *)
        wordSize: int     (* the number of bytes in a word *)
      } ->
      RTL.cluster ->
      {
        cluster: RTL.cluster,
        (* size of the whole of frame *)
        frameSize: int,
        (* slotId -> offset from the beginning of frame*)
        slotIndex: int LocalVarID.Map.map
      }

end =
struct

  structure R = RTL

  datatype reg = REG1 | REG2

  (*%
   * @formatter(Word32.word) SmlppgUtil.format_word32
   *)
  datatype frameComposition =
      (*% @format(reg * w) "LSHIFT\t" reg ", " w *)
      LSHIFT of reg * word
    | (*% @format(reg * w) "ORBIT\t" reg ", " w *)
      ORBIT of reg * reg
    | (*% @format(reg * w) "ANDBIT\t" reg ", " w *)
      ANDBIT of reg * Word32.word
    | (*% @format(reg * w) "MOVEREG\t" reg ", " w*)
      MOVE of reg * R.operand            (* move *)
    | (*% @format(off * reg) "SAVEREG\t" "[sp + " off "], " reg *)
      SAVEREG of int * reg               (* offset, reg *)
    | (*% @format(off * imm) "SAVEIMM\t" "[sp + " off "], " imm *)
      SAVEIMM of int * Word32.word       (* offset, imm *)
    | (*% @format(off) "SETNULL\t" "[" off "]" *)
      SETNULL of int                     (* offset *)
    | (*% @format(off) "SAVEHEAD\t" off *)
      SAVEHEAD of int option


  (* FIXME: target dependent *)
  fun generateCode frameSize (subst, v1, v2) code =
      let
        val offsetBase = frameSize + 4
        fun frameOffset off = off - offsetBase
        fun addr off = R.FRAMEINFO (frameOffset off)
        fun reg REG1 = valOf v1 | reg REG2 = valOf v2
        fun single x = RTLEdit.unfocus (RTLEdit.singleton x)
      in
        case code of
          LSHIFT (r1, w) =>
          single (R.LSHIFT (#ty (reg r1), R.REG (reg r1),
                            R.REF_ (R.REG (reg r1)),
                            R.CONST (R.UINT32 (Word32.fromInt (Word.toInt w)))))
        | ORBIT (r1, r2) =>
          single (R.OR (#ty (reg r1), R.REG (reg r1),
                        R.REF_ (R.REG (reg r1)), R.REF_ (R.REG (reg r2))))
        | ANDBIT (r1, w) =>
          single (R.AND (#ty (reg r1), R.REG (reg r1),
                         R.REF_ (R.REG (reg r1)), R.CONST (R.UINT32 w)))
        | MOVE (r1, op1) =>
          let
            val graph = RTLEdit.singleton
                          (R.MOVE (#ty (reg r1), R.REG (reg r1), op1))
          in
            X86Subst.substitute
              (fn {id,...} => case LocalVarID.Map.find (subst, id) of
                                SOME v => SOME (R.REG v)
                              | NONE => NONE)
              (RTLEdit.unfocus graph)
          end
        | SAVEREG (offset, r1) =>
          single (R.MOVE (#ty (reg r1),
                          R.MEM (#ty (reg r1), R.ADDR (addr offset)),
                          R.REF_ (R.REG (reg r1))))
        | SAVEIMM (offset, w) =>
          single (R.MOVE (R.Int32 R.U,
                          R.MEM (R.Int32 R.U, R.ADDR (addr offset)),
                          R.CONST (R.UINT32 w)))
        | SETNULL offset =>
          single (R.MOVEADDR (R.Data,
                              R.MEM (R.Ptr R.Data, R.ADDR (addr offset)),
                              R.ABSADDR (R.NULL R.Data)))
        | SAVEHEAD (SOME offset) =>
          single (R.MOVE (R.Int32 R.U,
                          R.MEM (R.Int32 R.U, R.ADDR (R.FRAMEINFO ~4)),
                          R.CONST (R.INT32 (Int32.fromInt
                                              (frameOffset offset)))))
        | SAVEHEAD NONE =>
          single (R.MOVE (R.Int32 R.U,
                          R.MEM (R.Int32 R.U, R.ADDR (R.FRAMEINFO ~4)),
                          R.CONST (R.INT32 0)))
      end

  fun generateCodeList frameSize param codeList =
      let
        val focus =
            foldl
              (fn (i, focus) =>
                  let
                    val g = generateCode frameSize param i
                  in
                    RTLEdit.spliceBefore (focus, g)
                  end)
              (RTLEdit.singletonFirst R.ENTER)
              codeList
      in
        RTLEdit.unfocus focus
      end

  fun bitmapToWord32 bitList =
      foldl (fn (x,z) => Word32.orb (Word32.<< (z, 0w1), x)) 0w0 bitList

  (* pack the source of frameBitmaps into wordBits-bit bins.
   *
   * val bitmapPacking
   *  : word -> {source:frameBitmapSource, bits:format list list} ->
   *    {filled:word, sources:(word,word,frameBitmapSource) list,
   *     bits:format list list} list
   *
   * "sources" in the result means (bit offset, bit size, source).
   * "filled" in the result is equal to wordBits except last bitmap.
   *)
  fun bitmapPacking (wordBits:word) frameBitmaps =
      let
        val bitmaps =
            map (fn x as {bits,...} => (Word.fromInt (length bits), x))
                frameBitmaps

        (* first fit algorithm *)
        val bitmaps =
            ListSorter.sort (fn ((n1,_),(n2,_)) => Word.compare (n2,n1))
                            bitmaps

        fun pack (bitmap as (0w0, {source, bits}), bins) = bins
          | pack (bitmap as (numBits, {source, bits=srcBits}), bins) =
            case bins of
              nil => [{filled = numBits,
                       sources = [(0w0, numBits, source)],
                       bits = srcBits}]
            | (bin as {filled, sources, bits})::bins =>
              if filled + numBits <= wordBits
              then {filled = filled + numBits,
                    sources = (filled, numBits, source)::sources,
                    bits = bits @ srcBits} :: bins
              else bin :: pack (bitmap, bins)

        fun pad nil = nil
          | pad [bitmap] = [bitmap]
          | pad ({filled, sources, bits}::bitmaps) =
            {filled = wordBits,
             sources = sources,
             bits = bits @ List.tabulate (Word.toInt (wordBits - filled),
                                          fn _ => nil)}
            :: pad bitmaps
      in
        pad (foldl pack nil bitmaps)
      end

  local
    infix <<
    val op << = Word32.<<

    fun bitmask numBits = (0w1 << numBits) - 0w1

    fun loadBitmap dstReg (offset, numBits, source) =
        let
          val loadCode = [MOVE (dstReg, source)]
          val maskCode = [ANDBIT (dstReg, bitmask numBits)]
          val shiftCode =
              if offset = 0w0 then nil else [LSHIFT (dstReg, offset)]
        in
          loadCode @ maskCode @ shiftCode
        end
  in

  (* generate code to compose frame bitmaps.
   *
   * val composeBitmap
   *  : reg -> reg ->
   *    {filled:word, sources:(word,word,frameBitmapSource) list,
   *     bits:format list list} ->
   *    {filled:word, reg:reg, code:frameComposition list,
   *     bits:format list list} list
   *
   * after "frameComposition" is executed, composed frame bitmap is
   * held by "reg".
   *)
  fun composeBitmap loadReg accumReg bitmaps =
      let
        fun composeOne nil = nil
          | composeOne [src] = loadBitmap accumReg src
          | composeOne (src::srcs) =
            composeOne srcs @ loadBitmap loadReg src @
            [ORBIT (accumReg, loadReg)]
      in
        map (fn {filled, sources, bits} =>
                {filled = filled,
                 reg = accumReg,
                 code = composeOne sources,
                 bits = bits})
            bitmaps
      end

  end (* local *)

  fun ceil (m, n) =
      (m + n - 0w1) - (m + n - 0w1) mod n

  fun allocSlots minAlign offset vars =
      foldl (fn ((id, {size,align,...}:R.format), (offset, alloc)) =>
                let
                  val size = Word.fromInt size
                  val align = Word.fromInt align
                  val offset = ceil (offset, align)
(*
                  val _ = print ("alloc: "^Word.fmt StringCvt.DEC offset^" = v"^Control.prettyPrint (LocalVarID.format_id id)^" (align="^Word.fmt StringCvt.DEC align^",size="^Word.fmt StringCvt.DEC size^")\n")
*)
                  val alloc = LocalVarID.Map.insert (alloc, id,
                                                     Word.toInt offset)
                in
                  (ceil (offset + size, minAlign), alloc)
                end)
            (offset, LocalVarID.Map.empty)
            vars

  (*
   * Frame pointer points the address of memory holding previous frame pointer.
   * The next (in the direction of stack growing) word of the previous frame
   * pointer holds relative address of frame information word of current frame
   * from the frame pointer.
   *
   * For example, on architecture whose the stack grows down (x86 etc.),
   * [ebp + 0] is previous frame pointer, and
   * [ebp - 4] is the relative address of frame info word.
   *
   * If the relative address of the frame info is 0, then the frame has no
   * info. If the previous frame pointer is NULL, the chain of frames is
   * terminated here.
   *
   *                                     :          :
   *            +--------+               | generics |
   *            |infoaddr|-------------->+----------+
   *  ebp ----->+--------+               | info     | current frame
   *            |  prev  |               | boxed    |
   *            +--|-----+               | ...      |
   *               |                     |          |
   *               |                     :          :
   *               |
   *               |                     :          :
   *               |   +--------+        | generics |
   *               |   |infoaddr|------->+----------+
   *               +-->+--------+        | info     | previous frame
   *                   |  prev  |        | boxed    |
   *                   +---|----+        | ....     |
   *                       |             |          |
   *                       |             :          :
   *                       :
   *                       |
   *                       v
   *                      NULL
   *
   * infoaddr:
   *  31                            2    1    0
   * +--------------------------------+----+----+
   * |             address            |next| gc |
   * +--------------------------------+----+----+
   * MSB                                      LSB
   *
   * if next is 0, address & 0xfffffffc is the offset of frame info of
   * this frame from frame pointer.
   * if next is 1, address & 0xfffffffc is the absolute address of previous
   * ML frame pointer. (this is used in callback function entry for gc to
   * skip C frames between ML frames.)
   * gc bit is reserved for gc. mutator must set it to 0.
   *
   * To make sure that we may use last 2 bits for the flags, frameAlign must
   * be at least multiple of 4.
   *
   *
   * Structure of Frame:
   *
   * addr
   *   | :               :
   *   | +---------------+ [align in frameAlign] <------- offset origin
   *   | | pre-offset    |
   *   | +===============+ ================== beginning of frame
   *   | |               |
   *   | +---------------+ [align in frameAlign]
   *   | | slots of tN   | generic slot 0 of tN
   *   | |  :            |   :
   *   | +---------------+ [align in frameAlign]
   *   | :               :
   *   | +---------------+ [align in frameAlign]
   *   | | slots of t1   | generic slot 0 of t1
   *   | :               :   :
   *   | +---------------+ [align in frameAlign]
   *   | | slots of t0   | generic slot 0 of t0
   *   | |               | generic slot 1 of t0
   *   | :               :   :
   *   | +---------------+ [align in frameAlign]
   *   | | frame info    | info = (numBoxed, numBitmapBits)
   *   | +---------------+ [align in unsigned int]
   *   | |               |
   *   | +---------------+ [align in void*]
   *   | | boxed part    |
   *   | :               :
   *   | |               |
   *   | +---------------+ [align in void*]
   *   | |               |
   *   | +---------------+ [align in unsigned int]
   *   | | sizes         | number of slots of t0
   *   | |               | number of slots of t1
   *   | :               :   :
   *   | |               | number of slots of t(N-1)
   *   | +---------------+ [align in unsigned int]
   *   | | bitmaps       | bitmap of (t0-t31)
   *   | :               :   :
   *   | |               | bitmap of (t(N-32)-t(N-1))
   *   | +---------------+ [align in unsigned int]
   *   | | unboxed part  |
   *   | |               |
   *   | |               |
   *   | :               :
   *   | |               |
   *   | +===============+ ================== end of frame
   *   | | post-offset   |
   *   | +---------------+ [align in frameAlign]
   *   | :               :
   *   v
   *
   *  (info & 0xffff) is the number of bitmap bits.
   *  (info >> 16) is the number of pointers in boxed slots part.
   *)

  fun constructFrame {preOffset, postOffset, frameAlign, wordSize}
                     (frameBitmap : R.frameBitmap list)
                     (slots : RTLUtils.Slot.set) =
      let
        (* frameAlign must be multiple of 4. *)
        val _ = if frameAlign mod 4 = 0 then ()
                else raise Control.Bug "constructFrame: frameAlign"

        val maxAlign = Word.fromInt frameAlign
        val wordSize = Word.fromInt wordSize

        (* First, separate variables for each category.
         * "generic" is a map from tid to variables belonging to that tid. *)
        val (boxed, unboxed, generic) =
            RTLUtils.Slot.fold
              (fn ({id, format as {tag,...}}, (boxed,unboxed,generic)) =>
                  case tag of
                    R.BOXED => ((id,format)::boxed, unboxed, generic)
                  | R.UNBOXED => (boxed, (id,format)::unboxed, generic)
                  | R.GENERIC tid =>
                    let
                      val vars = case IEnv.find (generic, tid) of
                                   SOME x => x | NONE => nil
                      val generic =
                          IEnv.insert (generic, tid, (id,format)::vars)
                    in
                      (boxed, unboxed, generic)
                    end)
              (nil, nil, IEnv.empty)
              slots

(*
        val _ = print "======= begin allocate frame =======\n"
        fun f g x = Control.prettyPrint (g x)
        fun pv (k,v) = "v"^f LocalVarID.format_id k ^ ":"^f F.format_format v
        fun pl g nil = ""
          | pl g (h::t) = g h ^ "\n" ^ pl g t
        fun pm g x = IEnv.foldli (fn (k,v,z) => "t"^Int.toString k^":\n"^g v^z) "" x
        val _ = print "boxed:\n"
        val _ = print (pl pv boxed)
        val _ = print "unboxed:\n"
        val _ = print (pl pv unboxed)
        val _ = print "generic:\n"
        val _ = print (pm (pl pv) generic)
        val _ = print "- - - -\n"
*)

        (* compose frame bitmap *)
        val bitmaps =
            map (fn {source,bits} =>
                    {source = source,
                     bits = map (fn NONE => nil
                                  | SOME tid =>
                                    case IEnv.find (generic, tid) of
                                      SOME vars => vars
                                    | NONE => nil)  (* unused tid *)
                                bits})
                frameBitmap

        val wordBits = wordSize * 0w8
(*
open FormatByHand
val _ = putf (pl (pr [("source",R.format_operand o #source),
                      ("bits",pi o length o #bits)])) bitmaps
*)
        val bitmaps = bitmapPacking wordBits bitmaps
(*  
val _ = putf (pl (pr [("filled",pw o #filled),
                      ("sources",
                       pl (p3 (pw, pw, R.format_operand)) o #sources),
                      ("bits", pi o length o #bits)])) bitmaps
*)
        val bitmaps = composeBitmap REG1 REG2 bitmaps

        val numBitmapBits =
            foldl (fn ({filled,...},z) => filled + z) 0w0 bitmaps
        val genericSlots =
            foldr (fn ({bits,...},z) => bits @ z) nil bitmaps

(*
        val _ = print ("numBitmapBits: "^Word.fmt StringCvt.DEC numBitmapBits^"\n")
        val _ = print ("pre-offset: "^Word.fmt StringCvt.DEC preOffset^"\n")
*)

        (* allocate pad for pre-offset *)
        val offset = ceil (preOffset, maxAlign)
        val alloc = LocalVarID.Map.empty

        (* allocate generic slots. *)
        val (offset, genericAlloc) =
            allocSlots maxAlign offset (List.concat (rev genericSlots))
        val alloc = LocalVarID.Map.unionWith #2 (alloc, genericAlloc)

        (* put frame info *)
        val infoOffset = offset
        val offset = offset + wordSize

        (* allocate boxed slots. *)
        val (offset, boxedAlloc) = allocSlots 0w1 offset boxed
        val alloc = LocalVarID.Map.unionWith #2 (alloc, boxedAlloc)
        val offset = ceil (offset, wordSize)

        (* put the number of generic slots. *)
        val (offset, bitmapCode) =
            foldl (fn (vars, (offset, bitmapCode)) =>
                      (offset + wordSize,
                       bitmapCode @
                       [SAVEIMM (Word.toInt offset,
                                 Word32.fromInt (length vars))]))
                  (offset, nil)
                  genericSlots

        (* put frame bitmaps. *)
        val (offset, bitmapCode) =
            foldl (fn ({reg,code,...}, (offset, bitmapCode)) =>
                      (offset + wordSize,
                       bitmapCode @ code @
                       [SAVEREG (Word.toInt offset, reg)]))
                  (offset, bitmapCode)
                  bitmaps

        (* generate code for frame info *)
        (* FIXME: need overflow check *)
        val numBoxed = LocalVarID.Map.numItems boxedAlloc
        val info = Word32.orb (Word32.<< (Word32.fromInt numBoxed, 0w16),
                               BasicTypes.WordToUInt32 numBitmapBits)

        val (offset, infoCode) =
            if info = 0w0
            then (* no info is needed. abandon a slot for the info *)
              (infoOffset, [SAVEHEAD NONE])
            else (offset, [SAVEIMM (Word.toInt infoOffset, info),
                           SAVEHEAD (SOME (Word.toInt infoOffset))])

        (* allocate unboxed slots. *)
        val (offset, unboxedAlloc) = allocSlots 0w1 offset unboxed
        val alloc = LocalVarID.Map.unionWith #2 (alloc, unboxedAlloc)

        (* allocate pad for post-offset *)
        val offset = ceil (offset + postOffset, maxAlign)
        val frameSize = offset - preOffset - postOffset

        (* generate code for boxed slot initialization *)
        val nullSlots = LocalVarID.Map.listItems boxedAlloc
                        @ LocalVarID.Map.listItems genericAlloc

        val initCode =
            case nullSlots of
              nil => nil
            | _::_ => map SETNULL (ListSorter.sort Int.compare nullSlots)

(*
        val _ = print "-------- alloc -------\n"
        val _ = LocalVarID.Map.appi (fn (k,v) => print ("v"^LocalVarID.toString k^": "^Word.fmt StringCvt.DEC v^"\n")) alloc
        val _ = print "----------------------\n"
        val _ = print ("frameSize = "^Word.fmt StringCvt.DEC frameSize^"\n")
        val _ = print ("headerOffset = "^(case headerOffset of NONE => "no" | SOME x => Word.fmt StringCvt.DEC x)^"\n")
*)
      in
        {
          frameSize = Word.toInt frameSize,
          slotIndex = alloc,
          initCode = infoCode @ initCode,
          bitmapCode = bitmapCode
        }
      end

  fun allocate frameInfo
               ({clusterId, frameBitmap, baseLabel, body,
                 preFrameSize, postFrameSize, loc}:R.cluster) =
      let
        (* gather slot usage *)
        (* FIXME: liveness analysis *)
        val slots =
            RTLEdit.fold
              (fn (focus, z) =>
                  RTLEdit.foldForward
                    (fn (node, z) =>
                        let
                          val {defs, uses} = RTLUtils.Slot.defuse node
                          val z = RTLUtils.Slot.setUnion (z, defs)
                          val z = RTLUtils.Slot.setUnion (z, uses)
                        in
                          z
                        end)
                    z
                    focus)
              RTLUtils.Slot.emptySet
              (RTLEdit.annotate (body, ()))

(*
val _ = Control.ps "--alloc--"
val _ = Control.p RTLUtils.Slot.format_set slots
val _ = Control.ps "--"
*)

        val {frameSize, slotIndex, initCode, bitmapCode} =
            constructFrame frameInfo frameBitmap slots

        (* substitute COMPUTE_FRAME with frameCode *)
        val body =
            RTLEdit.extend
              (fn (RTLEdit.MIDDLE (R.COMPUTE_FRAME {uses, clobs=[v1,v2]})) =>
                  generateCodeList frameSize (uses, SOME v1, SOME v2) bitmapCode
                | (RTLEdit.MIDDLE insn) =>
                  RTLEdit.unfocus (RTLEdit.singleton insn)
                | (RTLEdit.FIRST (first as R.CODEENTRY _)) =>
                  let
                    val focus = RTLEdit.singletonFirst first
                    val g = generateCodeList frameSize
                                             (LocalVarID.Map.empty, NONE, NONE)
                                             initCode
                    val focus = RTLEdit.spliceBefore (focus, g)
                  in
                    RTLEdit.unfocus focus
                  end
                | (RTLEdit.FIRST first) =>
                  RTLEdit.unfocus (RTLEdit.singletonFirst first)
                | (RTLEdit.LAST last) =>
                  RTLEdit.unfocus (RTLEdit.singletonLast last))
              body

        val cluster =
            {clusterId = clusterId,
             frameBitmap = nil,
             baseLabel = baseLabel,
             body = body,
             preFrameSize = preFrameSize,
             postFrameSize = postFrameSize,
             loc = loc} : R.cluster
      in
        {
          cluster = cluster,
          frameSize = frameSize,
          slotIndex = slotIndex
        }
      end














(*



















        source =


          R.Int8 s => (R.Int32 s, R.REG {id=id, ty=R.Int32 s})



  fun mlParams (argTys:R.ty list, retTys:R.ty list) =
      #2 (preFrameOffset (length retTys * genericSize (), argTys))

 R.REF (transformArgInfo arg)
          | AI.EnvBitmap (arg, offset) =>
            R.MEM (R.ADDR (R.DISP
                             (R.INT32 (Int32.fromInt (Word.toIntX offset)),
                              R.BASE (#2 (transformArgInfo arg))))),
        bits = bits
      } : R.frameBitmap








  fun allocate {preOffset, postOffset, maxAlign, wordSize}
               {frameBitmap, preFrameAligned, graph} =






               {graph, index, preFrameOrigin, postFrameOrigin}





  val allocate
      : {
          preOffset: word,    (* pre-offset of a frame *)
          postOffset: word,   (* post-offset of a frame *)
          maxAlign: word,     (* maximum alignment *)
          wordSize: word,     (* number of bytes in a word *)
          tmpReg1: 'reg,      (* temporally register for bitmap calculuation *)
          tmpReg2: 'reg,
          frameBitmap: ('reg,'addr) FrameLayout.frameBitmap list,
          variables: FrameLayout.format LocalVarID.Map.map   (* varID->format *)
        }
        -> ('reg,'addr) FrameLayout.frameLayout



  fun allocate {frameBitmap, preFrameAligned, graph}
               {preOffset, postOffset, maxAlign, wordSize} =
      let

        (*
         * addr
         *  | :          :
         *  | +----------+ [align 16]  -----------------------------
         *  | :PostFrame : (need to allocate)                  ^
         *  | |          |                                     |
         *  | +==========+ [align 16]  preOffset = 0           |
         *  | | Frame    | (need to allocate)                  | need to alloc
         *  | |          |                                     |
         *  | +==========+ [align 12/16] postOffset = 12       |
         *  | | headaddr |                                     v
         *  | +----------+ 8/16 <---- ebp --------------------------
         *  | | push ebp |
         *  | +----------+ 4/16
         *  | | ret addr |
         *  | +==========+ [align 16]
         *  | | PreFrame | (allocated by caller)
         *  | :          :
         *  | +----------+ [align 16]
         *  | :          :
         *  v
         *)
        val {frameSize, variableOffsets, headerCode, headerOffset} =
            FrameAllocation.allocate {preOffset = preOffset,
                                      postOffset = postOffset,
                                      maxAlign = maxAlign,
                                      wordSize = wordSize,



      {graph = graph,
       index = index,
       preFrameOrigin = preFrameOrigin,
       postFrameOrigin = postFrameOrigin}
end

*)
end
