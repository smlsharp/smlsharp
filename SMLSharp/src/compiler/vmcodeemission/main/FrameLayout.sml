(**
 * stack frame layout.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: FrameLayout.sml,v 1.5 2008/01/23 08:20:07 katsu Exp $
 *)
structure FrameLayout : sig

  val makeFrame
      : {
          frameInfo: MachineLanguage.frameInfo,
          frameSizeAlign: word,
          wordSize: word
        }
        -> MachineLanguage.stackFrameLayout

end =
struct

  structure M = MachineLanguage

  fun mapi f base (h::t) = f (base, h) :: mapi f (base + 0w1) t
    | mapi f base nil = nil

  structure FreeGenericOrd : ORD_KEY =
  struct
    type ord_key = M.entity * word

    fun compare2 ((x1, y1), (x2, y2)) =
        case Int.compare (x1, x2) of
          EQUAL => Word.compare (y1, y2)
        | x => x

    fun compareEnt (M.REGISTER x1, M.REGISTER x2) = compare2 (x1, x2)
      | compareEnt (M.REGISTER _, _) = GREATER
      | compareEnt (M.STACK _, M.REGISTER _) = LESS
      | compareEnt (M.STACK x1, M.STACK x2) = compare2 (x1, x2)
      | compareEnt (M.STACK _, M.HANDLER _) = GREATER
      | compareEnt (M.HANDLER x1, M.HANDLER x2) = Int.compare (x1, x2)
      | compareEnt (M.HANDLER _, _) = LESS

    fun compare ((ent1, off1), (ent2, off2)) =
        case compareEnt (ent1, ent2) of
          EQUAL => Word.compare (off1, off2)
        | x => x
  end

  structure FreeGenericMap = BinaryMapFn(FreeGenericOrd)

  val numBits = 0w8    (* number of bits of 1 byte *)

  datatype bitmap =
      BIT of M.entity
    | BITMAP of {entity: M.entity, offset: word, size: word}

  fun checkSameSize slots =
      case slots of
        nil => 0w0
      | ({size=x, slotId=_}::t) =>
        if List.all (fn {size,...} => x = size) t then x
        else raise Control.Bug "checkSameSize"

  fun padSize (offset, align) =
      (align - 0w1) - (offset + align - 0w1) mod align

  fun makePart lastAlign (({class={size,align,...}, slotIds}:M.frameAlloc)::t) =
      let
        (* ASSERT: size = 0 (mod align) *)
        val _ = if size mod align = 0w0 then ()
                else raise Control.Bug "makePart: not aligned itself"

        val ({align=align2, offset}, slots) = makePart lastAlign t
        val totalSize = Word.fromInt (length slotIds) * size
        val newOffset = padSize (totalSize mod align2 + (align2 - offset),
                                 align2)

(*
        val _ = print ("align2="^Word.fmt StringCvt.DEC align2
                       ^" align="^Word.fmt StringCvt.DEC align
                       ^" newOffset="^Word.fmt StringCvt.DEC newOffset
                       ^" offset="^Word.fmt StringCvt.DEC offset
                       ^" totalSize="^Word.fmt StringCvt.DEC totalSize
                       ^"\n")
*)

        (* ASSERT: for all n \in N,
         *         align2 * n + newOffset = 0 (mod align) *)
        val _ =
            if align2 mod align = 0w0 andalso newOffset mod align = 0w0 then ()
            else raise Control.Bug
                           ("makePart: not aligned without pad: "
                            ^"align2="^Word.fmt StringCvt.DEC align2
                            ^" align="^Word.fmt StringCvt.DEC align
                            ^" newOffset="^Word.fmt StringCvt.DEC newOffset
                            ^" offset="^Word.fmt StringCvt.DEC offset
                            ^" totalSize="^Word.fmt StringCvt.DEC totalSize)
      in
        ({align = align2, offset = newOffset},
         map (fn x => {size=size, slotId=x}) slotIds @ slots)
      end
    | makePart lastAlign nil = (lastAlign, nil)

  fun sortFreeGeneric frameAllocs =
      let
        val freeGenericMap =
            foldl
              (fn (alloc as {class={tag, ...}, slotIds}:M.frameAlloc, z) =>
                  case tag of
                    M.FREEGENERIC {entity, offset, bit} =>
                    let
                      val key = (entity, offset)
                    in
                      case FreeGenericMap.find (z, key) of
                       NONE => FreeGenericMap.insert (z, key, [(bit,alloc)])
                     | SOME l => FreeGenericMap.insert (z, key, (bit,alloc)::l)
                    end
                  | _ =>
                    raise Control.Bug "sortFreeGeneric: not FREEGENERIC")
              FreeGenericMap.empty
              frameAllocs
      in
        FreeGenericMap.foldri
          (fn ((entity, offset), bitAllocs, z) =>
              let
                val maxBit =
                    foldl (fn ((b,_),z) => Word.max (b,z)) 0w0 bitAllocs
                val bitMap =
                    foldl
                      (fn ((bit, alloc), map) =>
                          case WEnv.find (map, bit) of
                            NONE => WEnv.insert (map, bit, alloc)
                          | SOME l => raise Control.Bug
                                            "sortFreeGeneric: doubly alloced")
                      WEnv.empty
                      bitAllocs
              in
                {
                  entity = entity,
                  offset = offset,
                  allocs = List.tabulate
                             (Word.toIntX maxBit + 1,
                              fn x => WEnv.find (bitMap, Word.fromInt x))
                } :: z
              end)
          nil
          freeGenericMap
      end

  fun arrangeSlots {headSize, slots, trailerAlign} =
      let
(*
        val _ = print ("align="^Word.fmt StringCvt.DEC (#align trailerAlign)
                       ^" offset="^Word.fmt StringCvt.DEC (#offset trailerAlign)
                       ^" headSize="^Word.fmt StringCvt.DEC headSize
                       ^"\n")
        val _ =
            app (fn {size,align,slotId} =>
                    print ("size="^Word.fmt StringCvt.DEC size
                           ^" align="^Word.fmt StringCvt.DEC align
                           ^" slotId="^Word.fmt StringCvt.DEC slotId
                           ^"\n"))
                slots
*)

        (* FIXME: calculate minimum frame *)
        fun arrange offset ({size, align, slotId}::slots) =
            let
              val offset = offset + padSize (offset, align)
              val {slots, trailerOffset} = arrange (offset + size) slots
            in
              {slots = {size = size, offset = offset, slotId = slotId} :: slots,
               trailerOffset = trailerOffset}
            end
          | arrange offset nil =
            let
              val {align, offset=alignOffset} = trailerAlign
              val pad = padSize (offset mod align + (align - alignOffset),
                                 align)
            in
              {slots = nil, trailerOffset = offset + pad}
            end
      in
        arrange headSize slots
      end

  fun arrangeFrame {wordSize, frameSizeAlign,
                    numBitmapBits, unboxedSlots,
                    boxedAlign, numBoxedSlots} =
      let
        val wordBits = numBits * wordSize
        val numBitmapWords = (numBitmapBits + wordBits - 0w1) div wordBits
        val bitmapPartSize = numBitmapBits * wordSize
                             + numBitmapWords * wordSize

        fun arrange {headerSize, maxOffset, maxBoxed, maxBitmapBits} =
            if numBoxedSlots > maxBoxed orelse numBitmapBits > maxBitmapBits
            then NONE
            else
              let
                val ar = arrangeSlots {headSize = headerSize + bitmapPartSize,
                                       slots = unboxedSlots,
                                       trailerAlign = boxedAlign}
              in
                if #trailerOffset ar > maxOffset then NONE else SOME ar
              end
      in
        (*
         * -----------------------------------
         * header                           ^
         * ----                             |
         * numBitmapBits * sizeof(word)     |
         * ----                             |
         * numBitmapWords * sizeof(word)    | frameSize
         * ----                             | (must be multiple of
         * unboxedSlots                     |  frameSizeAlign)
         * ---- <-- aligned in align        |
         * boxedSize                        |
         * ----                             |
         * genericSize                      v
         * -----------------------------------
         *)
        (*
         * two words header:
         *    MSB                                       LSB
         *    +---------------------+---------------------+
         *  0 |   boxedPartOffset   |     flags (0w0)     |
         *    +---------------------+---------------------+
         *  4 |    numBoxedSlots    |    numBitmapBits    |
         *    +---------------------+---------------------+
         *     31                 16 15                  0
         *)
        case arrange {headerSize = 0w8,
                      maxOffset = 0w65535,
                      maxBoxed = 0w65535,
                      maxBitmapBits = 0w65535} of
          SOME {slots, trailerOffset = boxedPartOffset} =>
          {
            header = [
              {offset = 0w0,
               value = [{shift = 0w16, value = boxedPartOffset},
                        {shift = 0w0,  value = 0w0}]},
              {offset = 0w4,
               value = [{shift = 0w16, value = numBoxedSlots},
                        {shift = 0w0,  value = numBitmapBits}]}
            ],
            numGenericOffset = 0w8,
            bitmapOffset = 0w8 + numBitmapBits * wordSize,
            unboxedSlots = slots,
            boxedPartOffset = boxedPartOffset
          }
        | NONE =>
          raise Control.Bug "arrangeFrame: stack frame too large"
      end

  (* bitmap is sorted in ascending order of (wordIndex, bitIndex) *)
  fun composeBitmap wordSize base bitmap =
      let
        val wordBits = wordSize * numBits

        fun load (BIT ent) 0w0 reg = (nil, ent)
          | load (BIT ent) sh reg =
            ([M.RSHIFT {dst = reg, arg = ent, shift = sh}], reg)
          | load (BITMAP {entity, offset, ...}) 0w0 reg =
            ([M.LOAD {dst = reg, block = entity, offset = offset}], reg)
          | load (BITMAP {entity, offset, ...}) sh reg =
            ([M.LOAD {dst = reg, block = entity, offset = offset},
              M.RSHIFT {dst = reg, arg = reg, shift = sh}], reg)

(*
        fun load (BIT ent) = VAR ent
          | load (BITMAP {entity, offset, ...}) =
            LOAD {entity = entity, offset = offset}
*)

        fun bitmapSize (BIT _) = 0w1
          | bitmapSize (BITMAP {size, ...}) = size

        fun split i l (bitmap :: bitmaps) =
            let
              val sz = bitmapSize bitmap
            in
              if i + sz < wordBits then
                split (i + sz) ((sz, 0w0, bitmap)::l) bitmaps
              else if i + sz = wordBits then
                ((sz, 0w0, bitmap)::l) :: split 0w0 nil bitmaps
              else if sz > wordBits then
                raise Fail "composeBitmap: bitmap too large"
              else (* i + sz > wordBits, sz <= wordBits *)
                ((sz, 0w0, bitmap)::l)
                :: split (i + sz - wordBits)
                         [(i + sz - wordBits, wordBits - i, bitmap)]
                         bitmaps
            end
          | split i nil nil = nil
          | split i l nil = [l]

        val bitmaps = split 0w0 nil bitmap
      in
        fn (reg1, reg2) =>
           let
             fun compose1 i NONE nil = nil
               | compose1 i (SOME ent) nil =
                 [M.SAVE {offset = i, arg = ent}]
               | compose1 i NONE ((size, shift, bitmap)::l) =
                 let
                   val (code, ent) = load bitmap shift reg1
                 in
                   code @ compose1 i (SOME ent) l
                 end
               | compose1 i (SOME ent) ((size, shift, bitmap)::l) =
                 let
                   val (code, ent2) = load bitmap shift reg2
                 in
                   M.LSHIFT {dst = reg1, arg = ent, shift = size} ::
                   code @
                   [M.MASK {dst = reg2, arg = ent2, numBits = size},
                    M.ORB {dst = reg1, arg1 = reg1, arg2 = reg2}] @
                   compose1 i (SOME reg1) l
                 end

(*
        fun split i l (bitmap :: bitmaps) =
            let
              val sz = bitmapSize bitmap
            in
              if i + sz < wordBits then
                split (i + sz) ((sz, load bitmap)::l) bitmaps
              else if i + sz = wordBits then
                ((sz, load bitmap)::l) :: split 0w0 nil bitmaps
              else if sz > wordBits then
                raise Fail "composeBitmap: bitmap too large"
              else (* i + sz > wordBits, sz <= wordBits *)
                ((sz, load bitmap)::l)
                :: split (i + sz - wordBits)
                         [(i + sz - wordBits,
                           RSHIFT (load bitmap, wordBits - i))]
                         bitmaps
            end
          | split i nil nil = nil
          | split i l nil = [l]

        fun compose1 NONE nil = NOP
          | compose1 (SOME exp) nil = exp
          | compose1 NONE ((size, exp)::l) = compose1 (SOME exp) l
          | compose1 (SOME exp) ((size, exp2)::l) =
            compose1 (SOME (ORB (LSHIFT (exp, size), MASK (exp2, size)))) l
*)

             fun compose i nil = nil
               | compose i (bitmap::bitmaps) =
                 compose1 i NONE bitmap @ compose (i + wordSize) bitmaps
           in
             compose base bitmaps
           end
      end

  fun makeFrame {frameInfo as {handler, boxed, unboxed, generic, freeGeneric}
                           : M.frameInfo,
                 wordSize,
                 frameSizeAlign} =
      let
(*
        val _ = print "makeFrame\n"
        val _ = print (Control.prettyPrint (M.format_frameInfo frameInfo)^"\n")
*)

        val lastAlign = {align = frameSizeAlign, offset = 0w0}

        val (align, bitmap, numGenerics, freeGenericSlots) =
            foldr
              (fn ({entity, offset, allocs}, (align, bitmap, nums, slots)) =>
(*(
print (Control.prettyPrint (M.format_entity entity) ^ " : " ^
       Word.fmt StringCvt.DEC offset ^ " : " ^
       Int.toString(length allocs)^"\n");
*)
                  let
                    val nums2 =
                        map (fn SOME {slotIds, ...} => length slotIds
                              | NONE => 0)
                            allocs
                    val (align, slots2) =
                        makePart align (List.mapPartial (fn x => x) allocs)
                  in
                    (align,
                     BITMAP {entity = entity, offset = offset,
                             size = Word.fromInt (length allocs)} :: bitmap,
                     nums2 @ nums,
                     slots2 @ slots)
                  end)
              (lastAlign, nil, nil, nil)
              (sortFreeGeneric freeGeneric)

        val (align, genericSlots) = makePart align generic
        val genericSlots = genericSlots @ freeGenericSlots
        val (bitmap, numGenerics) =
            foldr
              (fn ({class={tag=M.GENERIC ent, ...}, slotIds}, (bitmap, nums)) =>
                  (BIT ent :: bitmap, length slotIds :: nums)
                | _ => raise Control.Bug "makeFrame: generic")
              (bitmap, numGenerics)
              generic

        val (align, boxedSlots) = makePart align boxed

        (* ASSERT: all generic slots must have same size *)
        val sizeGeneric = checkSameSize genericSlots
        (* ASSERT: all boxed slots must have same size *)
        val sizeBoxed = checkSameSize boxedSlots

        val unboxedSlots =
            foldr
              (fn (alloc as {class={size, align, ...}, slotIds}, slots) =>
                  map (fn x => {size = size, align = align, slotId = x})
                      slotIds
                  @ slots)
              nil
              unboxed

        val numBoxedSlots = Word.fromInt (length boxedSlots)
        val numGenericSlots = Word.fromInt (length genericSlots)
        val boxedPartSize = sizeBoxed * numBoxedSlots
        val genericPartSize = sizeGeneric * numGenericSlots

        val layout =
            arrangeFrame {wordSize = wordSize,
                          frameSizeAlign = frameSizeAlign,
                          numBitmapBits = Word.fromInt (length numGenerics),
                          unboxedSlots = unboxedSlots,
                          boxedAlign = align,
                          numBoxedSlots = numBoxedSlots}

        val totalSize =
            #boxedPartOffset layout + boxedPartSize + genericPartSize

        val initNumGeneric =
            mapi
              (fn (i, x) =>
                  {offset = #numGenericOffset layout + i * wordSize,
                   value = [{shift = 0w0, value = Word.fromInt x}]})
              0w0
              numGenerics

        val initBitmap =
            composeBitmap wordSize (#bitmapOffset layout) bitmap

        val slotAlloc =
            foldl
              (fn ({size, offset, slotId}, map) =>
                  WEnv.insert (map, slotId, offset))
              WEnv.empty
              (#unboxedSlots layout)

        val (_, rinitPointers, slotAlloc) =
            foldl
              (fn ({size, slotId}, (offset, inits, map)) =>
                  (offset + size,
                   offset :: inits,
                   WEnv.insert (map, slotId, offset)))
              (#boxedPartOffset layout, nil, slotAlloc)
              (boxedSlots @ genericSlots)
      in
        {
          slotAlloc = slotAlloc,
          initHeader = #header layout @ initNumGeneric,
          initBitmap = initBitmap,
          initPointers = rev rinitPointers,
          frameSize = totalSize
        }
      end

end
