(**
 * @copyright (c) 2006, Tohoku University.
 *)
local
  open RuntimeTypes
  open BasicTypes
  structure C = Constants
  structure H = Heap
  structure RE = RuntimeErrors
in
(**
 * functions to manipulate data structures defined in the source language.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SourceLanguageDatatypes.sml,v 1.12 2006/02/28 16:11:13 kiyoshiy Exp $
 *)
structure SourceLanguageDatatypes =
struct

  (***************************************************************************)

  local
    val stringLengthINDEX = 0w1 : UInt32
    val stringDataINDEX = 0w0 : UInt32
  in
  fun allocateStringBlock heap (byteArray, stringLength) =
      let
        val blockAddress =
            H.allocateBlock
                heap {bitmap = 0w0, size = 0w2, blockType = StringBlock}
        val _ =
            H.setField heap (blockAddress, stringDataINDEX, String byteArray)
        val _ =
            H.setField
                heap (blockAddress, stringLengthINDEX, Word stringLength)
      in blockAddress end

  fun allocateStringBlockFromVector heap (byteVector, stringLength) =
      let
        val byteArray = Word8Array.array (UInt32ToInt stringLength, 0w0)
        val _ =
            Word8Array.copyVec
                {src = byteVector, si = 0, dst = byteArray, di = 0, len = NONE}
      in
        allocateStringBlock heap (byteArray, stringLength)
      end

  fun expandStringBlock heap (Pointer block) =
      let
        val data = H.getField heap (block, stringDataINDEX)
        val length =
            wordOf
                "length in string block"
                (H.getField heap (block, stringLengthINDEX))
      in
        case data of
          String array => (array, length)
        | _ => raise RE.InvalidCode "expandStringBlock: string block expected."
      end
    | expandStringBlock heap value =
      raise
        RE.InvalidCode ("expandStringBlock found " ^ cellValueToString value)

  end (* local *)

  (**
   * convert a string into a CellValue.
   * @params heap string
   * @param heap heap
   * @param string the string
   * @return a runtime value which represents the string.
   *)
  fun stringToValue heap string =
      let
        val (array, length) = StringToUInt8Array string
        val blockAddress = allocateStringBlock heap (array, length)
      in Pointer blockAddress end

  (**
   * converts a runtime value which represents a string to a string.
   *)
  fun valueToString heap (stringAddress as Pointer _) = 
      UInt8ArrayToString (expandStringBlock heap stringAddress)
    | valueToString heap _ =
      raise RE.InvalidCode "valueToString: string block expected."

  (********************)

  fun allocateRealBlock heap value =
      let
        val cellValues = Real64ToCellValues value
        val blockAddress =
            H.allocateBlock
                heap {bitmap = 0w0, size = 0w2, blockType = RealBlock}
        val _ = H.setFields heap (blockAddress, 0w0, cellValues)
      in blockAddress
      end

  fun expandRealBlock heap (Pointer block) =
      let
        val cellValues = H.getFields heap (block, 0w0, 0w2)
      in
        realOf "expandRealBlock" cellValues
      end
    | expandRealBlock heap value =
      raise
        RE.InvalidCode ("expandRealBlock found " ^ cellValueToString value)

  (********************)

  (**
   * convert an unit into a CellValue.
   * @params heap unit
   * @param heap heap
   * @param unit the unit
   * @return a runtime value which represents the unit.
   *)
  fun unitToValue heap () =
      let
        val block = 
            H.allocateBlock
                heap {bitmap = 0w0, size = 0w0, blockType = RecordBlock}
      in Pointer block
      end

  (********************)

  (**
   * convert an Option.option value into a CellValue.
   * @params heap option
   * @param heap heap
   * @param option the option to be converted.
   * @return a pointer to a block which represents the option.
   *)
  fun optionToValue heap NONE =
      let
        val blockAddress =
            H.allocateBlock
                heap {bitmap = 0w0, size = 0w1, blockType = RecordBlock}
      in
        H.setField
            heap (blockAddress, 0w0, Int (IntToSInt32 C.TAG_option_NONE));
        Pointer blockAddress
      end
    | optionToValue heap (SOME value) =
      let
        val bitmap = if isPointerValue value then 0w2 else 0w0 : UInt32

        val valueRef = ref value
        val key =
            H.addRootSet heap (fn tracer => valueRef := tracer (!valueRef))

        val blockAddress =
            H.allocateBlock
                heap {bitmap = bitmap, size = 0w2, blockType = RecordBlock}

        val _ = H.removeRootSet heap key
        val fieldValues = [Int(IntToSInt32 C.TAG_option_SOME), !valueRef]
      in
        H.setFields heap (blockAddress, 0w0, fieldValues);
        Pointer blockAddress
      end

  (**
   * converts a runtime value which represents an Option.option to an option.
   *)
  fun valueToOption heap (Pointer block) =
      case H.getField heap (block, 0w0) of
        Int tagValue =>
        let val tagValue = SInt32ToInt tagValue
        in
          if C.TAG_option_NONE = tagValue
          then NONE
          else
            if C.TAG_option_SOME = tagValue
            then
              let
                val element = H.getField heap (block, 0w1)
              in SOME element
              end
            else 
              raise
                RE.InvalidCode
                    ("valueToOption expects option tag, but found "
                     ^ Int.toString tagValue)
        end

  (********************)

  (**
   * converts a block which represents a tuple into a list of elements.
   *)
  fun valueToTupleElements heap (Pointer block) =
      H.getFields heap (block, 0w0, H.getSize heap block)

  (**
   * convert a list of elements into a runtime value representing a tuple.
   * @params heap bitmap list
   * @param heap heap
   * @param bitmap the bitmap to be used when allocating a block.
   * @param list the elements to be stored in the block
   * @return a pointer to a block which represents a tuple
   *)
  fun tupleElementsToValue heap bitmap elements =
      let
        val elementsRef = ref elements
        val key =
            H.addRootSet
                heap
                (fn tracer =>
                    elementsRef
                    := (map (fn element => tracer element) (!elementsRef)))

        val blockAddress =
            H.allocateBlock
                heap
                {
                  bitmap = bitmap,
                  size = IntToUInt32(List.length elements),
                  blockType = RecordBlock
                }

        val _ = H.removeRootSet heap key
      in
        H.setFields heap (blockAddress, 0w0, !elementsRef);
        Pointer blockAddress
      end

  (********************)

  (**
   * convert a bool into a CellValue.
   * @params heap bool
   * @param heap heap
   * @param bool the value to be converted.
   * @return a runtime value 
   *)
  fun boolToValue heap true = Int(IntToSInt32 C.TAG_bool_true)
    | boolToValue heap false = Int(IntToSInt32 C.TAG_bool_false)

  (********************)

  (**
   * converts a runtime value to a list.
   *)
  fun valueToList heap (Pointer block) =
      let
        fun scan block list =
            case H.getField heap (block, 0w0) of
              Int tagValue =>
              let val tagValue = SInt32ToInt tagValue
              in
                if C.TAG_list_nil = tagValue
                then List.rev list
                else
                  if C.TAG_list_cons = tagValue
                  then
                    let
                      val [element, tail] = H.getFields heap (block, 0w1, 0w2)
                    in scan (pointerOf "valueToList" tail) (element :: list)
                    end
                  else 
                    raise
                      RE.InvalidCode
                          ("valueToList expects list tag, but found "
                           ^ Int.toString tagValue)
              end
      in scan block []
      end

  (**
   * convert a list into a CellValue.
   * @params heap elementToValue list
   * @param heap heap
   * @param  elementToValue a function which converts an element of the list
   *                      to a CellValue.
   * @param list the list to be converted.
   * @return a pointer to a block which represents the list.
   *)
  fun listToValue heap elementToValue list =
      let
        val nilBlockAddress =
            H.allocateBlock
                heap {bitmap = 0w0, size = 0w1, blockType = RecordBlock}
        val _ = 
            H.setField
                heap (nilBlockAddress, 0w0, Int (IntToSInt32 C.TAG_list_nil))
        val nilBlock = Pointer nilBlockAddress

        fun accum (element, result) =
            let
              val elementsRef = ref [result]
              val key =
                  H.addRootSet
                      heap
                      (fn tracer => elementsRef := map tracer (!elementsRef))

              val elementValue = elementToValue element
              val _ = elementsRef := elementValue :: (!elementsRef)
              val bitmap =
                  if isPointerValue elementValue then 0w6 else 0w4 : UInt32

              val blockAddress =
                  H.allocateBlock
                      heap
                      {bitmap = bitmap, size = 0w3, blockType = RecordBlock}

              val _ = H.removeRootSet heap key
              val fieldValues =
                  Int(IntToSInt32 C.TAG_list_cons) :: (!elementsRef)
            in
              H.setFields heap (blockAddress, 0w0, fieldValues);
              Pointer blockAddress
            end
        val result = foldr accum nilBlock list
      in
        result
      end

  (********************)

  fun exnToValue heap (OS.SysErr(message, syserrorOpt)) =
      let
        val elementsRef = ref []
        val key =
            H.addRootSet
                heap
                (fn tracer => elementsRef := map tracer (!elementsRef))

        (* push to elements list in the reverse order. *)
        val syserrorOptValue =
            optionToValue
                heap
                (Option.map
                     (fn syserror => Int(IntToSInt32 syserror)) syserrorOpt)
        val _ = elementsRef := syserrorOptValue :: (!elementsRef)

        val messageValue = stringToValue heap message
        val _ = elementsRef := messageValue :: (!elementsRef)

        val bitmap = 0w6 : UInt32
        val blockAddress =
            H.allocateBlock
                heap
                {bitmap = bitmap, size = 0w3, blockType = RecordBlock}

        val _ = H.removeRootSet heap key
        val fieldValues =
            Int(IntToSInt32 C.TAG_exn_SysErr) :: (!elementsRef)
      in
        H.setFields heap (blockAddress, 0w0, fieldValues);
        Pointer blockAddress
      end

  (********************)

  local
    val executableMapRef = ref (IEnv.empty : executable IEnv.map)
    val nextExecutableHandleRef = ref (0w0 : UInt32)
  in
    fun addExecutable executable =
        let
          val executableHandle = !nextExecutableHandleRef
          val _ = nextExecutableHandleRef := (executableHandle + 0w1)
        in
          executableMapRef
          := IEnv.insert
                 (!executableMapRef, UInt32ToInt executableHandle, executable);
          executableHandle
        end
    fun getExecutableOfHandle executableHandle =
        IEnv.find (!executableMapRef, UInt32ToInt executableHandle)
  end

end (* structure *)
end (* local *)
