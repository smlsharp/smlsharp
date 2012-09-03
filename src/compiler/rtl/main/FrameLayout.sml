structure FrameLayout : sig

  val allocate :
      {
        preOffset: word,  (* offset of the beginning of a frame *)
        postOffset: word, (* offset of the end of frame *)
        frameAlign: int,  (* alignment of frame (same as generic alignment) *)
        wordSize: int,    (* the number of bytes in a word *)
        pointerSize: int, (* the number of bytes in a pointer *)
        frameHeaderOffset: int,  (* FRAMEINFO offset of frame header *)
        frameOffset:      (* translate offset in a frame to FRAMEINFO offset *)
          {frameSize: int, offset: int} -> int
      } ->
      RTL.cluster ->
      {
        (* size of the whole of frame *)
        frameSize: int,
        (* slotId -> offset from the beginning of frame *)
        slotIndex: int VarID.Map.map,
        (* frame initialization code to be inserted after CODEENTRY *)
        initCode: RTL.instruction list,
        (* frame bitmap code for COMPUTE_FRAME *)
        frameCode: RTL.var list -> RTL.instruction list
      }

end =
struct
  (*
   * See also nativeruntime/frame.h.
   *
   * Frame pointer points the address of memory holding previous frame pointer.
   * The next (in the direction of stack growing) word of the previous frame
   * pointer holds the frame header. If the header indicates that there is
   * an extra word, then the extra word appears at the next of the header.
   * The size of both the header and the extra word is same as the size of
   * pointers on the target platform.
   *
   * For example, on a 32-bit architecture whose the stack grows down
   * (x86 etc.),
   * [fp + 0] is previous frame pointer, and
   * [fp - 4] is the relative address of frame info word.
   * [fp - 8] is for the extra word of frame header.
   *
   * Frame Stack Chain:
   *                                     :          :
   *                                     |          |
   *                                     +==========+ current frame begin
   *                                     |          |
   *            +--------+               :          :
   *            | header |-------------->|frame info|
   *            +--------+               :          :
   *     fp --->|  prev  |               |          |
   *            +--|-----+               +==========+ current frame end
   *               |                     |          |
   *               |                     :          :
   *               |                     |          |
   *               |                     +==========+ previous frame begin
   *               |                     |          |
   *               |   +--------+        :          :
   *               |   | header |------->|frame info|
   *               |   +--------+        :          :
   *               +-->|  prev  |        |          |
   *                   +---|----+        +==========+ previous frame end
   *                       |             |          |
   *                       :             :          :
   *
   * header:
   *  31                            2   1     0
   * +--------------------------------+----+----+
   * |           info-offset          |next| gc |
   * +--------------------------------+----+----+
   * MSB                                      LSB
   *
   * info-offset holds the high 30 bit of the offset of frame info of this
   * frame from the frame pointer. Low 2 bit is always 0.
   * If info-offset is 0, this frame has no frame info and thus there is no
   * boxed or generic slot in this frame.
   * If the pointer size is larger than 32 bit, info-offset field is
   * expanded to the pointer size.
   *
   * If next bit is 1, the header has an extra word which holds the address
   * of previous ML frame. (this is used to skip C frames between two ML
   * frames due to callback functions.)
   *
   * gc bit is reserved for non-moving gc. It must be 0 for new frames.
   * If the root-set enumerator meets this frame during pointer enumeration,
   * the gc bit is set to 1.
   *
   * To make sure that we may use last 2 bits for the flags, the frame info
   * must be aligned at the address of multiple of 4.
   *
   * frame info:
   *  31                16 15                 0
   * +--------------------+--------------------+
   * |  num boxed slots   |  num bitmap bits   |
   * +--------------------+--------------------+
   *
   * The size of frame info is same as the size of pointers on the target
   * platform. If the pointer size is larger than 32 bit, then padding bits
   * must be added to the most significant side of the frame info.
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
   *   | +---------------+ [align in frameAlign] <---- pointed by the header
   *   | | frame info    |
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
   *)

  structure R = RTL

  datatype reg = REG1 | REG2

  type frameLayoutInfo =
      {
        preOffset: word,
        postOffset: word,
        frameAlign: int,
        wordSize: int,
        pointerSize: int,
        frameHeaderOffset: int,
        frameOffset: {frameSize: int, offset: int} -> int
      }

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


  (* FIXME: make target dependent more *)
  fun generateCode frameSize ({frameOffset, frameHeaderOffset, ...}
                              : frameLayoutInfo) clobRegs code =
      let
        fun frameInfoOffset off = frameOffset {frameSize=frameSize, offset=off}
        fun addr off = R.FRAMEINFO (frameInfoOffset off)
        fun reg r =
            case (r, clobRegs) of
              (REG1, r::_) => r
            | (REG2, _::r::_) => r
            | _ => raise Control.Bug "generateCode"
      in
        case code of
          LSHIFT (r1, w) =>
          R.LSHIFT (#ty (reg r1), R.REG (reg r1),
                    R.REF_ (R.REG (reg r1)),
                    R.CONST (R.UINT32 (Word32.fromInt (Word.toInt w))))
        | ORBIT (r1, r2) =>
          R.OR (#ty (reg r1), R.REG (reg r1),
                R.REF_ (R.REG (reg r1)), R.REF_ (R.REG (reg r2)))
        | ANDBIT (r1, w) =>
          R.AND (#ty (reg r1), R.REG (reg r1),
                 R.REF_ (R.REG (reg r1)), R.CONST (R.UINT32 w))
        | MOVE (r1, op1) =>
          R.MOVE (#ty (reg r1), R.REG (reg r1), op1)
        | SAVEREG (offset, r1) =>
          R.MOVE (#ty (reg r1),
                  R.MEM (#ty (reg r1), R.ADDR (addr offset)),
                  R.REF_ (R.REG (reg r1)))
        | SAVEIMM (offset, w) =>
          R.MOVE (R.Int32 R.U,
                  R.MEM (R.Int32 R.U, R.ADDR (addr offset)),
                  R.CONST (R.UINT32 w))
        | SETNULL offset =>
          R.MOVEADDR (R.Data,
                      R.MEM (R.Ptr R.Data, R.ADDR (addr offset)),
                      R.ABSADDR (R.NULL R.Data))
        | SAVEHEAD (SOME offset) =>
          R.MOVE (R.Int32 R.S,
                  R.MEM (R.Int32 R.S, R.ADDR (R.FRAMEINFO frameHeaderOffset)),
                  R.CONST (R.INT32 (Int32.fromInt (frameInfoOffset offset))))
        | SAVEHEAD NONE =>
          R.MOVE (R.Int32 R.S,
                  R.MEM (R.Int32 R.S, R.ADDR (R.FRAMEINFO frameHeaderOffset)),
                  R.CONST (R.INT32 0))
      end

  fun generateCodeList frameSize frameOffset clobRegs codeList =
      map (generateCode frameSize frameOffset clobRegs) codeList

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
                  val alloc = VarID.Map.insert (alloc, id,
                                                Word.toInt offset)
                in
                  (ceil (offset + size, minAlign), alloc)
                end)
            (offset, VarID.Map.empty)
            vars

  fun constructFrame ({preOffset, postOffset, frameAlign, wordSize,
                       pointerSize, ...} : frameLayoutInfo)
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
                      val vars = case BoundTypeVarID.Map.find (generic, tid) of
                                   SOME x => x | NONE => nil
                      val generic =
                          BoundTypeVarID.Map.insert
                            (generic, tid, (id,format)::vars)
                    in
                      (boxed, unboxed, generic)
                    end)
              (nil, nil, BoundTypeVarID.Map.empty)
              slots

        (* compose frame bitmap *)
        val bitmaps =
            map (fn {source,bits} =>
                    {source = source,
                     bits =
                       map (fn NONE => nil
                             | SOME tid =>
                               case BoundTypeVarID.Map.find (generic, tid) of
                                 SOME vars => vars
                               | NONE => nil)  (* unused tid *)
                           bits})
                frameBitmap

        val wordBits = wordSize * 0w8
        val bitmaps = bitmapPacking wordBits bitmaps
        val bitmaps = composeBitmap REG1 REG2 bitmaps

        val numBitmapBits =
            foldl (fn ({filled,...},z) => filled + z) 0w0 bitmaps
        val genericSlots =
            foldr (fn ({bits,...},z) => bits @ z) nil bitmaps

        (* allocate pad for pre-offset *)
        val offset = ceil (preOffset, maxAlign)
        val alloc = VarID.Map.empty

        (* allocate generic slots. *)
        val (offset, genericAlloc) =
            allocSlots maxAlign offset (List.concat (rev genericSlots))
        val alloc = VarID.Map.unionWith #2 (alloc, genericAlloc)

        (* put frame info *)
        val infoOffset = offset
        val offset = offset + Word.fromInt pointerSize

        (* allocate boxed slots. *)
        val (offset, boxedAlloc) = allocSlots 0w1 offset boxed
        val alloc = VarID.Map.unionWith #2 (alloc, boxedAlloc)
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
        val numBoxed = VarID.Map.numItems boxedAlloc
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
        val alloc = VarID.Map.unionWith #2 (alloc, unboxedAlloc)

        (* allocate pad for post-offset *)
        val offset = ceil (offset + postOffset, maxAlign)
        val frameSize = offset - preOffset - postOffset

        (* generate code for boxed slot initialization *)
        val nullSlots = VarID.Map.listItems boxedAlloc
                        @ VarID.Map.listItems genericAlloc

        val initCode =
            case nullSlots of
              nil => nil
            | _::_ => map SETNULL (ListSorter.sort Int.compare nullSlots)
      in
        {
          frameSize = Word.toInt frameSize,
          slotIndex = alloc,
          initCode = infoCode @ initCode,
          bitmapCode = bitmapCode
        }
      end

  local

    structure FormatOrd =
    struct
      type ord_key = RTL.format
      fun compareTag (R.UNBOXED, R.UNBOXED) = EQUAL
        | compareTag (R.UNBOXED, _) = LESS
        | compareTag (R.BOXED, R.UNBOXED) = GREATER
        | compareTag (R.BOXED, R.BOXED) = EQUAL
        | compareTag (R.BOXED, R.GENERIC _) = LESS
        | compareTag (R.GENERIC t1, R.GENERIC t2) =
          BoundTypeVarID.compare (t1, t2)
        | compareTag (R.GENERIC _, _) = GREATER
      fun compare ({size=size1, align=align1, tag=tag1}:RTL.format,
                   {size=size2, align=align2, tag=tag2}:RTL.format) =
          case Int.compare (size1, size2) of
            EQUAL => (case Int.compare (align1, align2) of
                        EQUAL => compareTag (tag1, tag2)
                      | x => x)
          | x => x
    end

    structure FormatMap = BinaryMapFn(FormatOrd)

    datatype vertex =
        V of {adjacencies: vertex VarID.Map.map ref,
              color: VarID.id option ref}

    fun newVertex () =
        V {adjacencies = ref VarID.Map.empty, color = ref NONE}

    fun touchSlot (fmtMap, {id, format}:RTL.slot) =
        case FormatMap.find (!fmtMap, format) of
          NONE =>
          let
            val vertex = newVertex ()
            val vertexMap = VarID.Map.singleton (id, vertex)
          in
            fmtMap := FormatMap.insert (!fmtMap, format, ref vertexMap);
            vertex
          end
        | SOME vertexMap =>
          case VarID.Map.find (!vertexMap, id) of
            SOME vertex => vertex
          | NONE =>
            let
              val vertex = newVertex ()
            in
              vertexMap := VarID.Map.insert (!vertexMap, id, vertex);
              vertex
            end

    fun interfere (fmtMap, slot1, slot2) =
        if FormatOrd.compare (#format slot1, #format slot2) <> EQUAL then ()
        else if #id slot1 = #id slot2 then (touchSlot (fmtMap, slot1); ())
        else
          let
            val vertex1 as V {adjacencies=adj1,...} = touchSlot (fmtMap, slot1)
            val vertex2 as V {adjacencies=adj2,...} = touchSlot (fmtMap, slot2)
          in
            adj1 := VarID.Map.insert (!adj1, #id slot2, vertex2);
            adj2 := VarID.Map.insert (!adj2, #id slot1, vertex1)
          end

    fun interfereSet (fmtMap, slots1, slots2) =
        RTLUtils.Slot.app
          (fn slot1 =>
              RTLUtils.Slot.app
                (fn slot2 => interfere (fmtMap, slot1, slot2))
                slots2)
          slots1

    fun selectColor (fmt, vertexMap) =
        let
          val maxColors =
              VarID.Map.foldl
                (fn (V {adjacencies,...}, z) =>
                    Int.max (VarID.Map.numItems (!adjacencies) + 1, z))
                0
                vertexMap
          val allColors =
              foldl (fn (x,z) => VarID.Map.insert (z, x, ()))
                    VarID.Map.empty
                    (List.tabulate (maxColors, fn _ => VarID.generate ()))
        in
          VarID.Map.map
            (fn V {adjacencies, color} =>
                let
                  val colors =
                      VarID.Map.foldl
                        (fn (V {color = ref NONE, ...}, z) => z
                          | (V {color = ref (SOME c), ...}, z) =>
                            if VarID.Map.inDomain (z, c)
                            then #1 (VarID.Map.remove (z, c))
                            else z)
                        allColors
                        (!adjacencies)
                in
                  case VarID.Map.firsti colors of
                    NONE => raise Control.Bug "selectColor"
                  | SOME (id,()) => (color := SOME id; {id=id, format=fmt})
                end)
            vertexMap
        end

    fun selectSlots fmtMap =
        FormatMap.foldli
          (fn (fmt, vertexMap, subst) =>
              VarID.Map.unionWith
                (fn _ => raise Control.Bug "selectSlots")
                (subst, selectColor (fmt, !vertexMap)))
          VarID.Map.empty
          fmtMap

    fun allSlots fmtMap =
        FormatMap.foldli
          (fn (fmt, vertexMap, subst) =>
              VarID.Map.foldli
                (fn (id, _, subst) =>
                    VarID.Map.insert (subst, id, {id=id, format=fmt}))
                subst
                (!vertexMap))
          VarID.Map.empty
          fmtMap

  in

  fun minimize graph =
      let
        val fmtMap = ref FormatMap.empty
      in
        RTLLiveness.foldBackwardSlot
          (fn (node, {liveIn, liveOut}, ()) =>
              let
                val {defs, uses} = RTLUtils.Slot.defuse node
                val liveOut_defs = RTLUtils.Slot.setUnion (defs, liveOut)
              in
                interfereSet (fmtMap, uses, liveIn);
                interfereSet (fmtMap, defs, liveOut_defs)
              end)
          ()
          (RTLLiveness.livenessSlot graph);
        if !Control.doFrameCompaction
        then selectSlots (!fmtMap)
        else allSlots (!fmtMap)
      end

  end (* local *)



  fun allocate frameInfo ({body, frameBitmap, ...}:R.cluster) =
      let
        (* gather slot usage *)
        val subst = minimize body
        val slots = RTLUtils.Slot.fromList (VarID.Map.listItems subst)

        val {frameSize, slotIndex, initCode, bitmapCode} =
            constructFrame frameInfo frameBitmap slots

        val slotIndex =
            VarID.Map.map
              (fn {id, format} =>
                  case VarID.Map.find (slotIndex, id) of
                    SOME x => x
                  | NONE => raise Control.Bug "allocate")
              subst

        val initCode =
            generateCodeList frameSize frameInfo nil initCode
        val frameCode =
            fn clobs => generateCodeList frameSize frameInfo clobs bitmapCode
      in
        {
          frameSize = frameSize,
          slotIndex = slotIndex,
          initCode = initCode,
          frameCode = frameCode
        }
      end

end
