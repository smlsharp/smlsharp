(**
 * declartions of types which represent elements operated in the runtime.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RuntimeTypes.sml,v 1.21 2007/01/13 03:35:00 kiyoshiy Exp $
 *)
structure RuntimeTypes =
struct

  (***************************************************************************)

  local
    open BasicTypes
    structure E = Executable
    structure SD = SystemDef
  in

  (***************************************************************************)

  datatype blockType =
           RecordBlock
         | SingleArrayBlock
         | DoubleArrayBlock
         | StringBlock
         | RealBlock

  (**
   * This is not equal to Executable.executable in that instructions are in
   * serialized format.
   *)
  type executable =
       {
         byteOrder : SystemDefTypes.byteOrder,
         instructionsSize: UInt32,
         instructionsArray : Word8Array.array,
         locationTable : E.locationTable,
         nameSlotTable : E.nameSlotTable
       }

  val emptyLocationTable = 
      {
        locationsCount = 0w0,
        locations = [],
        fileNamesCount = 0w0,
        fileNameOffsets = [],
        fileNames = []
      } : E.locationTable

  val emptyNameSlotTable =
       {
         nameSlotsCount = 0w0,
         nameSlots = [],
         boundNamesCount = 0w0,
         boundNameOffsets = [],
         boundNames = []
       } : E.nameSlotTable

  val emptyExecutable =
      {
        byteOrder = SD.NativeByteOrder,
        instructionsSize = 0w0,
        instructionsArray = Word8Array.array (0, 0w0),
        locationTable = emptyLocationTable,
        nameSlotTable = emptyNameSlotTable
      } : executable

  type codeRef = {executable : executable, offset : UInt32}

  datatype cellValue =
	   Int of SInt32
         | Word of UInt32
         | Real of Real64
(*
         | Char of UInt32
*)
	 | Pointer of address
	 | CodeRef of codeRef
	 | Header of {size : UInt32, bitmap : UInt32, blockType : blockType}
         | String of Word8Array.array
         | UnInitialized (* used only by Heap.allocateBlankBlock *)

  withtype address = cellValue RawMemory.pointer

  (***************************************************************************)

  (** raised if a runtime error occurs. *)
  exception RuntimeError of string

  exception UnexpectedCellValue of string

  (***************************************************************************)

  fun blockTypeToString RecordBlock = "Record"
    | blockTypeToString SingleArrayBlock = "SingleArray"
    | blockTypeToString DoubleArrayBlock = "DoubleArray"
    | blockTypeToString StringBlock = "String"
    | blockTypeToString RealBlock = "Real"

  (** get the textual representation of a cellValue. *)
  fun cellValueToString (Int n) = "Int(" ^ (SInt32.toString n) ^ ")"
    | cellValueToString (Word w) =
      "Word(" ^ ("0wx" ^ (UInt32.fmt StringCvt.HEX w)) ^ ")"
    | cellValueToString (Real f) = "Real(" ^ (Real64.toString f) ^ ")"
(*
    | cellValueToString (Char w) =
      "Char(" ^ (Char.toString(Char.chr(UInt32ToInt w))) ^ ")"
*)
    | cellValueToString (Pointer address) =
      let
        val addressString = UInt32.toString(RawMemory.offset address)
        val valueString = cellValueToString(RawMemory.load address)
      in
        "Pointer(" ^ addressString ^ "=" ^ valueString ^ ")"
      end
    | cellValueToString (CodeRef{executable, offset}) = "Code(...)"
    | cellValueToString (Header{size, bitmap, blockType}) =
      "Header{size=" ^ (UInt32.toString size) ^ "," ^
      "bitmap=" ^ (UInt32.toString bitmap) ^ "," ^
      "blockType=" ^ (blockTypeToString blockType) ^ "}"
    | cellValueToString (String data) =
      "String(" ^
      String.toCString
      (implode
           (Word8Array.foldr
                (fn (byte, chars) => Char.chr(Word8.toInt byte) :: chars)
                []
                data)) ^
      ")"
    | cellValueToString UnInitialized = "UnInitialized"

  end

  (********************)

  (**
   * indicates a value is a pointer value which can be stored into a pointer
   * slot in a frame.
   * <p>
   * A value which may be stored in a frame slot is either Inr, Word, Char
   * or Pointer.
   * String, Real and others are not stored in a frame.
   * </p>
   *)
  fun isPointerValue (Pointer _) = true
    | isPointerValue _ = false

  (**
   * indicates a value is an atom value which can be stored into an atom 
   * slot in a frame.
   *)
  fun isAtomValue (Int _) = true
    | isAtomValue (Word _) = true
(*
    | isAtomValue (Char _) = true
*)
    | isAtomValue (Real _) = true 
    | isAtomValue (CodeRef _) = true (* return slot holds a code pointer. *)
    | isAtomValue _ = false

  (********************)

  fun Real64ToCellValues real = [Real real, Word 0w0]

  fun intOf message (Int int) = int
    | intOf message value =
      raise
        UnexpectedCellValue
        (message ^ ":expected a int, but found " ^ cellValueToString value)

  fun wordOf message (Word word) = word
    | wordOf message value =
      raise
        UnexpectedCellValue
        (message ^ ":expected a word, but found " ^ cellValueToString value)

  fun charOf message (Word char) = char
    | charOf message value =
      raise
        UnexpectedCellValue
        (message ^ ":expected a char, but found " ^ cellValueToString value)

  fun realOf message ([Real real, Word 0w0]) = real
    | realOf message cells =
      raise
        UnexpectedCellValue
            (message ^ 
             ":expected a real, but found " ^
             (concat
                  (map
                       (fn value => cellValueToString value ^ ",")
                       cells)))

  fun pointerOf message (Pointer address) = address
    | pointerOf message value =
      raise
        UnexpectedCellValue
        (message ^ ":expected a pointer, but found " ^ cellValueToString value)

  fun codeRefOf message (CodeRef codeRef) = codeRef
    | codeRefOf message value =
      raise
        UnexpectedCellValue
        (message ^ ":expected a code, but found " ^ cellValueToString value)

  (***************************************************************************)

end
