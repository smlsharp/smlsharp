(**
 * x86 register allocation
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure FrameAllocation : FRAMEALLOCATION =
struct

  structure F = FrameLayout

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
                    sources = (filled + numBits, numBits, source)::sources,
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
          val loadCode =
              case source of
                F.REG reg => [F.MOVEREG (dstReg, reg)]
              | F.MEM mem => [F.LOAD (dstReg, mem)]
          val maskCode = [F.ANDBIT (dstReg, bitmask numBits)]
          val shiftCode =
              if offset = 0w0 then nil else [F.LSHIFT (dstReg, offset)]
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
   *    {filled:word, reg:reg, code:headerComposition list,
   *     bits:format list list} list
   *
   * after "headerComposition" is executed, composed frame bitmap is
   * held by "reg".
   *)
  fun composeBitmap loadReg accumReg bitmaps =
      let
        fun composeOne nil = nil
          | composeOne [src] = loadBitmap accumReg src
          | composeOne (src::srcs) =
            composeOne srcs @ loadBitmap loadReg src @
            [F.ORBIT (accumReg, loadReg)]
      in
        map (fn {filled, sources, bits} =>
                {filled = filled,
                 reg = accumReg,
                 code = composeOne sources,
                 bits = bits})
            bitmaps
      end

  end


  fun ceil (m, n) =
      (m + n - 0w1) - (m + n - 0w1) mod n

  fun allocSlots minAlign offset vars =
      foldl (fn ((id, {size,align,...}:F.format), (offset, alloc)) =>
                let
                  val offset = ceil (offset, align)
(*
                  val _ = print ("alloc: "^Word.fmt StringCvt.DEC offset^" = v"^Control.prettyPrint (LocalVarID.format_id id)^" (align="^Word.fmt StringCvt.DEC align^",size="^Word.fmt StringCvt.DEC size^")\n")
*)
                  val alloc = LocalVarID.Map.insert (alloc, id, offset)
                in
                  (ceil (offset + size, minAlign), alloc)
                end)
            (offset, LocalVarID.Map.empty)
            vars


(*
 * Frame pointer is the address of memory holding previous frame pointer.
 * The previous (in the direction of stack growing) word of the frame
 * pointer holds the address of frame header.
 *
 * For example, on architecture whose the stack grows down (x86 etc.),
 * [ebp + 0] is previous frame pointer, and
 * [ebp + 4] is the address of frame header.
 *
 * If the address of frame header is NULL, then the frame has no header.
 * If the previous frame pointer is NULL, the chain of frames is
 * terminated here.
 *
 *                                     :          :
 *            +--------+               |          |
 *            |headaddr|-------------->+----------+
 *  ebp ----->+--------+               | boxed    |
 *            |  prev  |               |          |
 *            +--|-----+               |          |
 *               |                     |          |
 *               |                     :          :
 *               |
 *               |                     :          :
 *               |   +--------+        |          |
 *               |   |headaddr|------->+----------+
 *               +-->+--------+        | boxed    |
 *                   |  prev  |        |          |
 *                   +---|----+        |          |
 *                       |             |          |
 *                       |             :          :
 *                       :
 *                       |
 *                       v
 *                      NULL
 *
 *
 * Structure of Frame:
 *
 * addr
 *   | :               :
 *   | +---------------+ [align in maxAlign] <------- offset origin
 *   | | pre-offset    |
 *   | +===============+ ================== beginning of frame
 *   | |               |
 *   | +---------------+ [align in maxAlign]
 *   | | slots of tN   | generic slot 0 of tN
 *   | |  :            |   :
 *   | +---------------+ [align in maxAlign]
 *   | :               :
 *   | +---------------+ [align in maxAlign]
 *   | | slots of t1   | generic slot 0 of t1
 *   | :               :   :
 *   | +---------------+ [align in maxAlign]
 *   | | slots of t0   | generic slot 0 of t0
 *   | |               | generic slot 1 of t0
 *   | :               :   :
 *   | +---------------+ [align in maxAlign] <-------- [ebp]
 *   | | header        | header = (numBoxed, numBitmapBits)
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
 *   | +---------------+ [align in maxAlign]
 *   | :               :
 *   v
 *
 *  (header & 0xffff) is the number of bitmap bits.
 *  (header >> 16) is the number of pointers in boxed slots part.
 *)

  fun allocate {preOffset, postOffset, maxAlign, wordSize,
                tmpReg1, tmpReg2,
                frameBitmap:('reg,'addr) F.frameBitmap list,
                variables: F.format LocalVarID.Map.map} =
      let
        (* First, separate variables for each category.
         * "generic" is a map from tid to variables belonging to that tid. *)
        val (boxed, unboxed, generic) =
            LocalVarID.Map.foldri
              (fn (id, fmt as {tag,...}:F.format, (boxed,unboxed,generic)) =>
                  case tag of
                    F.BOXED => ((id,fmt)::boxed, unboxed, generic)
                  | F.UNBOXED => (boxed, (id,fmt)::unboxed, generic)
                  | F.GENERIC tid =>
                    let
                      val vars = case IEnv.find (generic, tid) of
                                   SOME x => x | NONE => nil
                      val generic = IEnv.insert (generic, tid, (id,fmt)::vars)
                    in
                      (boxed, unboxed, generic)
                    end)
              (nil, nil, IEnv.empty)
              variables

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
        val bitmaps = bitmapPacking wordBits bitmaps
        val bitmaps = composeBitmap tmpReg1 tmpReg2 bitmaps

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

        (* put frame header *)
        val headerOffset = offset
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
                       [F.SAVEIMM (offset, Word32.fromInt (length vars))]))
                  (offset, nil)
                  genericSlots

        (* put frame bitmaps. *)
        val (offset, bitmapCode) =
            foldl (fn ({reg,code,...}, (offset, bitmapCode)) =>
                      (offset + wordSize,
                       bitmapCode @ code @
                       [F.SAVEREG (offset, reg)]))
                  (offset, bitmapCode)
                  bitmaps

        (* allocate unboxed slots. *)
        val (offset, unboxedAlloc) = allocSlots 0w1 offset unboxed
        val alloc = LocalVarID.Map.unionWith #2 (alloc, unboxedAlloc)

        (* allocate pad for post-offset *)
        val offset = ceil (offset + postOffset, maxAlign)
        val frameSize = offset - preOffset - postOffset

        (* generate code for frame header *)
        (* FIXME: need overflow check *)
        val numBoxed = LocalVarID.Map.numItems boxedAlloc
        val header = Word32.orb (Word32.<< (Word32.fromInt numBoxed, 0w16),
                                 BasicTypes.WordToUInt32 numBitmapBits)

        val (headerOffset, headerCode) =
            if header = 0w0
            then (NONE, nil)
            else (SOME headerOffset, [F.SAVEIMM (headerOffset, header)])

        (* generate code for boxed slot initialization *)
        val nullSlots = LocalVarID.Map.listItems boxedAlloc
                        @ LocalVarID.Map.listItems genericAlloc

        val initCode =
            case nullSlots of
              nil => nil
            | _::_ => [F.SETNULL (ListSorter.sort Word.compare nullSlots)]

(*
        val _ = print "-------- alloc -------\n"
        val _ = LocalVarID.Map.appi (fn (k,v) => print ("v"^LocalVarID.toString k^": "^Word.fmt StringCvt.DEC v^"\n")) alloc
        val _ = print "----------------------\n"
        val _ = print ("frameSize = "^Word.fmt StringCvt.DEC frameSize^"\n")
        val _ = print ("headerOffset = "^(case headerOffset of NONE => "no" | SOME x => Word.fmt StringCvt.DEC x)^"\n")
*)
      in
        {
          frameSize = frameSize,
          variableOffsets = alloc,
          headerCode = headerCode @ bitmapCode @ initCode,
          headerOffset = headerOffset
        } : ('reg,'addr) F.frameLayout
      end

end
