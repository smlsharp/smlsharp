(**
 * heap implementation.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Heap.sml,v 1.23 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure Heap :> HEAP =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure RM = RawMemory
  structure C = Counter

  (***************************************************************************)

  type address = cellValue RM.pointer

  type rootTracer = cellValue -> cellValue

  type rootSet = rootTracer -> unit

  type heap =
       {
         reservep : cellValue RawMemory.pointer,
         frombp : cellValue RawMemory.pointer ref,
         fromep : cellValue RawMemory.pointer ref,
         tobp : cellValue RawMemory.pointer ref,
         toep : cellValue RawMemory.pointer ref,
         freebp : cellValue RawMemory.pointer ref,
         rootSets : rootSet IEnv.map ref
       }

  and bitmap = UInt32

  (***************************************************************************)

  exception Error of string

  val WORDS_OF_HEADER = 0w1 : UInt32
  val MAX_RECORD_BLOCK_SIZE = 0w32 : UInt32

  val traceGC = ref false

  fun toString 
      (h as {reservep, frombp, fromep, tobp, toep, freebp, rootSets} : heap) =
      "{" ^
        "reservep=" ^ RM.toString reservep ^ "," ^
        "frombp=" ^ RM.toString (!frombp) ^ "," ^
        "fromep=" ^ RM.toString (!fromep) ^ "," ^
        "tobp=" ^ RM.toString (!tobp) ^ "," ^
        "toep=" ^ RM.toString (!toep) ^ "," ^
        "freebp=" ^ RM.toString (!freebp) ^
      "}"

  val C.CounterSet heapCounterSet =
      #addSet C.root ("Heap", C.ORDER_OF_ADDITION)
  val C.CounterSet GCCounterSet =
      #addSet heapCounterSet ("GC", C.ORDER_OF_ADDITION)
  val C.AccumulationCounter GCCounter =
      #addAccumulation GCCounterSet "GC"
  val C.CounterSet accessCounterSet =
      #addSet heapCounterSet ("Access", C.ORDER_OF_ADDITION)
  val C.AccumulationCounter getFieldCounter =
      #addAccumulation accessCounterSet "getField"
  val C.AccumulationCounter setFieldCounter =
      #addAccumulation accessCounterSet "setField"
  val C.CounterSet blockCounterSet =
      #addSet heapCounterSet ("blockAllocation", C.ORDER_OF_ADDITION)
  val C.AccumulationCounter blockAllocationCounter =
      #addAccumulation blockCounterSet "number of allocation"
  val C.AccumulationCounter blockSizeCounter =
      #addAccumulation blockCounterSet "total of block size"

  local
    val nextRootSetKeyRef = ref 0
    fun getNextRootSetKey () =
        !nextRootSetKeyRef before nextRootSetKeyRef := (!nextRootSetKeyRef) + 1
  in
  fun addRootSetToMap rootSetsRef rootSet =
      let val key = getNextRootSetKey ()
      in rootSetsRef := IEnv.insert (!rootSetsRef, key, rootSet); key end
  fun addRootSet ({rootSets, ...} : heap) rootSet =
      addRootSetToMap rootSets rootSet
  fun removeRootSet ({rootSets, ...} : heap) key =
      (IEnv.remove (!rootSets, key); ())
  end

  (**
   * initialize a heap.
   * <p>
   * A memory area of the specified number of words is allocated.
   * The memory area is arranged as following:
   * <ul>
   * <li>1 word : an empty block consisting of only a block header.</li>
   * <li>areaSize words : the one phase.</li>
   * <li>areaSize words : another phase.</li>
   * </p>
   *)
  fun initialize {memory, memorySize, rootSets} =
      let
        val reserveAreaSize = 0w1 : UInt32
        val areaSize = (memorySize - reserveAreaSize) div 0w2

        val reservep = memory
        val frombp = RM.advance (memory, reserveAreaSize)
        val fromep = RM.advance (frombp, areaSize - 0w1)
        val tobp = RM.advance (fromep, 0w1)
        val toep = RM.advance (tobp, areaSize - 0w1)
        val freebp = frombp

        (* set up reserve area *)
        val _ =
            RM.store
            (
              reservep,
              Header{bitmap = 0w0, size = 0w0, blockType = RecordBlock}
            )
        val rootSetMapRef = ref IEnv.empty
        val _ = List.app (ignore o addRootSetToMap rootSetMapRef) rootSets
      in
        {
          reservep = reservep,
          frombp = ref frombp,
          fromep = ref fromep,
          tobp = ref tobp,
          toep = ref toep,
          freebp = ref freebp,
          rootSets = rootSetMapRef
        } : heap
      end

  fun castHeader _ address =
      let
        val cellValue = RM.load address
      in
        case cellValue of
          Header(header) => header
        | _ =>
          raise
            Error
                ("expects Header, but cell at " ^ (RM.toString address) ^
                 " is " ^ (cellValueToString cellValue))
      end

  fun checkPointerInFromArea ({frombp, fromep, ...} : heap) address =
      if RM.<=(!frombp, address) andalso RM.<=(address, !fromep)
      then ()
      else
        raise
          Error ("address " ^ RM.toString address ^ " is in not from area.")

  fun checkFieldIndex h address index =
      let val {size, bitmap, blockType} = castHeader h address
      in
        if size <= index
        then
          raise
            Error
                ("block pointed by " ^ RM.toString address ^
                 " has " ^ UInt32.toString size ^ " words, " ^
                 " but access offset " ^ UInt32.toString index ^"\n")
        else ()
      end

  fun getBitmap h address =
      let val {bitmap, ...} = castHeader h address in bitmap end
  fun setBitmap h (address,bitmap) =
      let 
        val {size,blockType, ...} = castHeader h address
      in
        RM.store (address,Header {bitmap=bitmap,size=size,blockType=blockType})
      end

  fun getSize h address =
      let val {size, ...} = castHeader h address in size end
  fun getBlockType h address =
      let val {blockType, ...} = castHeader h address in blockType end

  local
    fun failPointerExpect (block, index, bitmap, value) = 
        raise
          Error
              ("pointer expects at index " ^ UInt32.toString index
               ^ " of " ^ cellValueToString block
               ^ ", but " ^ cellValueToString value
               ^ ", bitmap = " ^ UInt32.toString bitmap)
    fun failNonPointerExpect (block, index, bitmap, value) =
        raise
          Error
              ("non pointer expects at index " ^ UInt32.toString index
               ^ " of " ^ cellValueToString block
               ^ ", but " ^ cellValueToString value
               ^ ", bitmap = " ^ UInt32.toString bitmap)
    fun getBitOfIndex bitmap index = 
        UInt32.andb (UInt32.>>(bitmap, UInt32ToWord index), 0w1 : UInt32)
  in
  fun assertValidValue (h : heap) (value as (Pointer address)) =
      if #reservep h = address
      then value
      else (checkPointerInFromArea h address; value)
    | assertValidValue h value = value

  fun assertValidFieldValue (h : heap) (address, index : UInt32, value) =
      case castHeader h address of
        {blockType = RecordBlock, bitmap, ...} =>
        (case getBitOfIndex bitmap index of
           0w0 => 
           if isPointerValue value
           then failNonPointerExpect (RM.load address, index, bitmap, value)
           else ()
         | _ =>
           if isPointerValue value
           then ()
           else failPointerExpect (RM.load address, index, bitmap, value))
      | {blockType = SingleArrayBlock, bitmap, ...} =>
        if 0w1 = bitmap
        then
          if isPointerValue value
          then ()
          else failPointerExpect (RM.load address, index, bitmap, value)
        else
          if isPointerValue value
          then failNonPointerExpect (RM.load address, index, bitmap, value)
          else ()
      | {blockType = DoubleArrayBlock, bitmap, ...} =>
        if 0w1 = bitmap
        then
          if isPointerValue value
          then ()
          else failPointerExpect (RM.load address, index, bitmap, value)
        else
          if isPointerValue value
          then failNonPointerExpect (RM.load address, index, bitmap, value)
          else ()
      | _ => () (* ToDo : check for String block and Float block. *)

  end

  fun getField (h : heap) (address, index) =
      (
        checkFieldIndex h address index;

        #inc getFieldCounter ();

        let val value = RM.load(RM.advance(address, index + WORDS_OF_HEADER))
        in assertValidFieldValue h (address, index, value); value
        end
      )

  fun getFields (h : heap) (address, start, fieldCount) =
      if 0w0 = fieldCount
      then []
      else
        (
          checkFieldIndex h address (start + fieldCount - 0w1);

          #inc getFieldCounter ();

          List.tabulate
              (
                UInt32ToInt fieldCount,
                fn i =>
                   let
                     val index = start + (IntToUInt32 i)
                     val value =
                         RM.load(RM.advance (address, index + WORDS_OF_HEADER))
                   in assertValidFieldValue h (address, index, value); value
                   end
              )
        )

  fun setField (h : heap) (address, index , value) =
      (
        checkFieldIndex h address index;
        checkPointerInFromArea h address;
        assertValidFieldValue h (address, index, value);
        #inc setFieldCounter ();
       
        RM.store
            (
              RM.advance(address, index + WORDS_OF_HEADER),
              assertValidValue h value
            )
      )
  fun setFields (h : heap) (address, index , values) =
      (
        checkFieldIndex
            h address (index + IntToUInt32 (List.length values) - 0w1);
        checkPointerInFromArea h address;
        foldl 
            (fn (value, index) =>
                (
                  assertValidFieldValue h (address, index, value);
                  #inc setFieldCounter ();
                  RM.store
                      (
                        RM.advance(address, index + WORDS_OF_HEADER),
                        assertValidValue h value
                      );
                  index + 0w1
                ))
            index
            values;
        ()
      )

(*
  fun putFields (h : heap) (address, []) = ()
    | putFields (h : heap) (address, fieldValues) = 
      (
        checkPointerInFromArea h address;
        checkFieldIndex 
            h address (IntToUInt32(List.length fieldValues) - 0w1);

        #add setFieldCounter (List.length fieldValues);

        foldl
            (fn(value, index) =>
               let
                 val size = case value of Real _ => 0w2 | _ => 0w1
               in
                 (
                  assertValidFieldValue h (address, index, value);
                  RM.store
                      (
                       RM.advance(address, WORDS_OF_HEADER + index),
                       assertValidValue h value
                      );
                  index + size
                 )
               end
            )
            0w0
            fieldValues;
        ()
      )
*)

  fun invokeGC
      (h as {reservep, frombp, fromep, tobp, toep, freebp, rootSets} : heap) =
      let
        fun trace message = if !traceGC then print message else ()

        val _ = trace ("***** Before GC *****" ^ toString h ^ "\n")
        val _ = #inc GCCounter ()

        (* move a block in 'from' area pointed by address to 'to' area *)
        fun moveTo srcAddress =
            let
              val _ =
                  trace("begin move block at " ^ RM.toString srcAddress ^ "\n")
              val words = WORDS_OF_HEADER + (getSize h srcAddress)
              val destAddress = !freebp
              val nextFreeBp = RM.advance(!freebp, words)
            in
                (* copy block to the free area. *)
                List.tabulate
                (
                  UInt32ToInt words,
                  fn index => 
                     RM.store
                     (
                       RM.advance(destAddress, IntToUInt32 index),
                       RM.load(RM.advance(srcAddress, IntToUInt32 index))
                     ));
                (* write a forward pointer into the first field of the 'from'
                 * block. *)
                RM.store
                (
                  RM.advance(srcAddress, WORDS_OF_HEADER),
                  Pointer(destAddress)
                );
                destAddress before freebp := nextFreeBp
            end

        (*
         * If the address points object in 'from' area, move it to 'to' area
         * and return that new address.
         * If address points a block in 'from' area containing a forward
         * pointer, return that forward pointer.
         * Otherwise, return the address.
         *)
        fun forward (Pointer address) =
            (
             trace ("forward BlockRef(" ^ (RM.toString address) ^ ")\n");
             (if RM.<= (!frombp, address) andalso RM.<= (address, !fromep)
              then
                (* the address points to a block in the 'from' area *)
                case RM.load(RM.advance(address, WORDS_OF_HEADER)) of
                  Pointer(maybeForward) =>
                  if
                    RM.<= (!tobp, maybeForward) andalso
                    RM.<= (maybeForward, !toep)
                  then
                    (*
                     * If the first field of the block pointed by the address
                     * is a pointer to 'to' area, the maybeFoward is a forward
                     * pointer.
                     *)
                    Pointer(maybeForward)
                  else Pointer(moveTo address)
                | _ => Pointer(moveTo address)
              else
                (* if address points to 'to' area or atom area *)
                Pointer(address))
             before trace ("end forwarding\n")
            )
          | forward value = value

        val _ = freebp := (!tobp)
        (* update roots *)
        val _ =
            let fun traceRoot root = forward root
            in IEnv.app (fn rootSet => rootSet traceRoot) (!rootSets) end
        val _ = trace ("rootsets have been updated.\n")

        (* update reserve area *)
        (* nothing *)

        (* scan 'to' area and update pointer cell which points forward
         * pointer in 'from' area *)
        fun scanfrom scan =
            (
              trace ("begin scan block at " ^ (RM.toString scan) ^ "\n");
              if RM.< (scan, !freebp)
              then
                let
                  val fields = getSize h scan
                  val firstFieldPointer = RM.advance (scan, WORDS_OF_HEADER)
                  val nextBlockPointer = RM.advance (firstFieldPointer, fields)
                in
                  (
                    RM.map
                        (firstFieldPointer, nextBlockPointer)
                        (fn pointer =>
                            RM.store(pointer, forward (RM.load pointer)));
                    scanfrom nextBlockPointer
                  )
                end
              else ()
            )
        val _ = scanfrom (!tobp)

        (* switch 'from' area and 'to' area *)
        val (tmpbp, tmpep) = (!frombp, !fromep)
        val _ = frombp := !tobp
        val _ = fromep := !toep
        val _ = tobp := tmpbp
        val _ = toep := tmpep

        val _ = trace ("***** Finish GC *****\n")
      in
        ()
      end

  local
  fun allocate
          (h as {fromep, freebp, ...} : heap)
          (header as Header{bitmap, size, blockType}) =
      if 0w0 = size
      then #reservep h
      else
        if blockType = RecordBlock andalso MAX_RECORD_BLOCK_SIZE < size 
        then 
          raise
             Error
             ("too large record block size: " ^ Int.toString(UInt32ToInt size))
        else
          let val requiredWords = WORDS_OF_HEADER + size
          in
            #inc blockAllocationCounter ();
            #add blockSizeCounter (UInt32.toInt requiredWords);

            if RM.<= (RM.advance(!freebp, requiredWords), !fromep)
            then
              let val newFreeBp = RM.advance(!freebp, requiredWords)
              in
                RM.store (!freebp, header);
                (!freebp) before freebp := newFreeBp
              end
            else
              let val _ = invokeGC h
              in
                if RM.< (!fromep, RM.advance(!freebp, requiredWords))
                then raise Error "heap exhausted"
                else allocate h header
              end
          end
  in

  fun allocateBlock
          (h as {fromep, freebp, ...} : heap) {bitmap, size, blockType} =
      allocate
          h
          (Header{bitmap = bitmap, size = size, blockType = blockType})

  fun allocateBlankBlock h {size,blockType} =
      let
        val blockAddress = 
            allocateBlock h {bitmap = 0w0, size = size, blockType = blockType}
        val _ =
            List.tabulate
            (
              UInt32ToInt size,
              fn index =>
                 RM.store 
                 (
                   RM.advance
                       (blockAddress,(IntToUInt32 index) + WORDS_OF_HEADER),
                   UnInitialized
                 )
            )
      in
        blockAddress
      end 

  fun copyBlock h (srcAddress,destAddress) =
      let
        val cells = UInt32ToInt ((getSize h srcAddress) + WORDS_OF_HEADER)
        val _ =
            List.tabulate
                (
                 cells,
                 fn index =>
                    RM.store 
                        (
                          RM.advance(destAddress,(IntToUInt32 index)),
                          RM.load(RM.advance(srcAddress,(IntToUInt32 index)))
                        )
                )
      in
        ()
      end

  end

  fun getEmptyBlockAddress (h : heap) = #reservep h

  (***************************************************************************)

end
