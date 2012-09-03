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

  fun allocate frameInfo ({body, frameBitmap, ...}:R.cluster) =
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

        val {frameSize, slotIndex, initCode, bitmapCode} =
            constructFrame frameInfo frameBitmap slots

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
