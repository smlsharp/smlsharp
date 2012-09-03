(**
 * interface to COM Automation.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_Automation =
struct

  (****************************************)

  structure Finalizable = SMLSharp.Finalizable
  structure FLOB = SMLSharp.FLOB
  structure NDT = NativeDataTransporter
  structure OLEString = UTF16LECodec.String
  structure UM = UnmanagedMemory
  structure Int8 = Int32 (* FIXME : We should have Int8. *)

  structure BS = OLE_BufferStream
  structure COM = OLE_COM
  structure Decimal = OLE_Decimal
  structure E = OLE_Error
  structure W = OLE_Win32

  open OLE_DataConverter

  (****************************************)

  type TypeInfo =
       {
         addRef : unit -> W.ULONG,
         release : unit -> W.ULONG,
         getDocumentation
         : unit
           -> (
                (** name *) OLEString.string
              * (** description *) OLEString.string
              ),
         this : UM.address Finalizable.finalizable
       }

  type 'a safearray = 'a OLE_SafeArray.safearray

  datatype variant =
           EMPTY
         | NULL
         | I2 of Int32.int
         | I4 of Int32.int
         | R4 of Real32.real
         | R8 of Real64.real
         | BSTR of OLEString.string
         | DISPATCH of Dispatch
         | ERROR of Int32.int
         | BOOL of bool
         | VARIANT of variant
         | UNKNOWN of COM.Unknown
         | DECIMAL of Decimal.decimal
         | I1 of Int8.int
         | UI1 of Word8.word
         | UI2 of Word32.word
         | UI4 of Word32.word
         | I8 of IntInf.int
         | UI8 of IntInf.int
         | INT of Int32.int
         | UINT of Word32.word

         | BYREF of variant
         | BYREFOUT of variant ref

         | I2ARRAY of Int32.int safearray
         | I4ARRAY of Int32.int safearray
         | R4ARRAY of Real32.real safearray
         | R8ARRAY of Real64.real safearray
         | BSTRARRAY of OLEString.string safearray
         | DISPATCHARRAY of Dispatch safearray
         | ERRORARRAY of Int32.int safearray
         | BOOLARRAY of bool safearray
         | VARIANTARRAY of variant safearray
         | UNKNOWNARRAY of COM.Unknown safearray
         | DECIMALARRAY of Decimal.decimal safearray
         | I1ARRAY of Int8.int safearray
         | UI1ARRAY of Word8.word safearray
         | UI2ARRAY of Word32.word safearray
         | UI4ARRAY of Word32.word safearray
         | I8ARRAY of IntInf.int safearray
         | UI8ARRAY of IntInf.int safearray
         | INTARRAY of Int32.int safearray
         | UINTARRAY of Word32.word safearray

  withtype Dispatch =
           {
             addRef : unit -> W.ULONG,
             release : unit -> W.ULONG,
             invoke : OLEString.string -> variant list -> variant option,
             invokeByDISPID : W.DISPID -> variant list -> variant option,
             get : OLEString.string -> variant list -> variant,
             getByDISPID : W.DISPID -> variant list -> variant,
             set : OLEString.string -> variant list -> variant -> unit,
             setByDISPID : W.DISPID -> variant list -> variant -> unit,
             setRef : OLEString.string -> variant list -> variant -> unit,
             setRefByDISPID : W.DISPID -> variant list -> variant -> unit,
             getTypeInfo : unit -> TypeInfo,
             this : UM.address Finalizable.finalizable
           }

  type EnumVARIANT =
       {
         addRef : unit -> W.ULONG,
         release : unit -> W.ULONG,
         next : int -> variant list,
         skip : int -> unit,
         reset : unit -> unit,
         clone : unit -> UM.address, (* enum *)
         this : UM.address Finalizable.finalizable
       }

  (****************************************)

  fun UMSubWord word = UM.subWord (UM.wordToAddress word)
  fun UMImport (bstr, bytelen) = UM.import (UM.wordToAddress bstr, bytelen)

  (****************************************)
  (* IDispatch *)

  fun BSTRToOLESTR bstr =
      case Word.toInt(W.SysStringByteLen bstr) 
       of 0 => OLEString.implode []
        | bytelen =>
          let
            val bytes = UMImport (bstr, bytelen)
            val olestr = OLEString.bytesToMBS bytes
          in
            olestr
          end

  fun OLESTRToBSTR olestr =
      let
        val bytes = OLEString.MBSToBytes olestr
        val bstr =
            W.SysAllocStringByteLen
                (bytes, Word.fromInt(Word8Vector.length bytes))
      in
        bstr
      end

  fun tagOfArray elementTag = Word.orb(W.VT_ARRAY, elementTag)

  fun tagOfVariant EMPTY = W.VT_EMPTY
    | tagOfVariant NULL = W.VT_NULL
    | tagOfVariant (I2 _) = W.VT_I2
    | tagOfVariant (I4 _) = W.VT_I4
    | tagOfVariant (R4 _) = W.VT_R4
    | tagOfVariant (R8 _) = W.VT_R8
    | tagOfVariant (BSTR _) = W.VT_BSTR
    | tagOfVariant (DISPATCH _) = W.VT_DISPATCH
    | tagOfVariant (ERROR _) = W.VT_ERROR
    | tagOfVariant (BOOL _) = W.VT_BOOL
    | tagOfVariant (VARIANT _) = W.VT_VARIANT
    | tagOfVariant (UNKNOWN _) = W.VT_UNKNOWN
    | tagOfVariant (DECIMAL _) = W.VT_DECIMAL
    | tagOfVariant (I1 _) = W.VT_I1
    | tagOfVariant (UI1 _) = W.VT_UI1
    | tagOfVariant (UI2 _) = W.VT_UI2
    | tagOfVariant (UI4 _) = W.VT_UI4
    | tagOfVariant (I8 _) = W.VT_I8
    | tagOfVariant (UI8 _) = W.VT_UI8
    | tagOfVariant (INT _) = W.VT_INT
    | tagOfVariant (UINT _) = W.VT_UINT

    | tagOfVariant (BYREF v) = Word.orb(W.VT_BYREF, tagOfVariant v)
(* BYREFOUT is not necessary to be handled here,
 * because BYREFOUT should not appear in other variant.
    | tagOfVariant (BYREFOUT v) = Word.orb(W.VT_BYREF, tagOfVariant v)
*)

    | tagOfVariant (I2ARRAY v) = tagOfArray W.VT_I2
    | tagOfVariant (I4ARRAY v) = tagOfArray W.VT_I4
    | tagOfVariant (R4ARRAY v) = tagOfArray W.VT_R4
    | tagOfVariant (R8ARRAY v) = tagOfArray W.VT_R8
    | tagOfVariant (BSTRARRAY v) = tagOfArray W.VT_BSTR
    | tagOfVariant (DISPATCHARRAY v) = tagOfArray W.VT_DISPATCH
    | tagOfVariant (ERRORARRAY v) = tagOfArray W.VT_ERROR
    | tagOfVariant (BOOLARRAY v) = tagOfArray W.VT_BOOL
    | tagOfVariant (VARIANTARRAY v) = tagOfArray W.VT_VARIANT
    | tagOfVariant (UNKNOWNARRAY v) = tagOfArray W.VT_UNKNOWN
    | tagOfVariant (DECIMALARRAY v) = tagOfArray W.VT_DECIMAL
    | tagOfVariant (I1ARRAY v) = tagOfArray W.VT_I1
    | tagOfVariant (UI1ARRAY v) = tagOfArray W.VT_UI1
    | tagOfVariant (UI2ARRAY v) = tagOfArray W.VT_UI2
    | tagOfVariant (UI4ARRAY v) = tagOfArray W.VT_UI4
    | tagOfVariant (I8ARRAY v) = tagOfArray W.VT_I8
    | tagOfVariant (UI8ARRAY v) = tagOfArray W.VT_UI8
    | tagOfVariant (INTARRAY v) = tagOfArray W.VT_INT
    | tagOfVariant (UINTARRAY v) = tagOfArray W.VT_UINT
    | tagOfVariant _ = raise Fail "BUG:OLE.tagOfVariant"

  local
    fun objectToString obj =
        "0x"
        ^ Word.toString(UM.addressToWord(Finalizable.getValue (#this obj)))
  in
  fun variantToString EMPTY = "EMPTY"
    | variantToString NULL = "NULL"
    | variantToString (I2 v) = "I2(" ^ Int32.toString v ^ ")"
    | variantToString (I4 v) = "I4(" ^ Int32.toString v ^ ")"
    | variantToString (R4 v) = "R4(" ^ Real32.toString v ^ ")"
    | variantToString (R8 v) = "R8(" ^ Real64.toString v ^ ")"
    | variantToString (BSTR v) = "BSTR(" ^ OLEString.toString v ^ ")"
    | variantToString (DISPATCH v) = "DISPATCH(" ^ objectToString v ^ ")"
    | variantToString (ERROR v) = "ERROR(" ^ Int32.toString v ^ ")"
    | variantToString (BOOL v) = "BOOL(" ^ Bool.toString v ^ ")"
    | variantToString (VARIANT v) = "VARIANT(" ^ variantToString v ^ ")"
    | variantToString (UNKNOWN v) = "UNKNOWN(" ^ objectToString v ^ ")"
    | variantToString (DECIMAL v) = "DECIMAL(" ^ Decimal.toString v ^ ")"
    | variantToString (I1 v) = "I1(" ^ Int8.toString v ^ ")"
    | variantToString (UI1 v) = "UI1(" ^ Word8.toString v ^ ")"
    | variantToString (UI2 v) = "UI2(" ^ Word32.toString v ^ ")"
    | variantToString (UI4 v) = "UI4(" ^ Word32.toString v ^ ")"
    | variantToString (I8 v) = "I8(" ^ IntInf.toString v ^ ")"
    | variantToString (UI8 v) = "UI8(" ^ IntInf.toString v ^ ")"
    | variantToString (INT v) = "INT(" ^ Int32.toString v ^ ")"
    | variantToString (UINT v) = "UINT(" ^ Word32.toString v ^ ")"

    | variantToString (BYREF v) = "BYREF(" ^ variantToString v ^ ")"
    | variantToString (BYREFOUT v) = "BYREFOUT(" ^ variantToString (!v) ^ ")"

    | variantToString (I2ARRAY v) = "I2ARRAY(...)"
    | variantToString (I4ARRAY v) = "I4ARRAY(...)"
    | variantToString (R4ARRAY v) = "R4ARRAY(...)"
    | variantToString (R8ARRAY v) = "R8ARRAY(...)"
    | variantToString (BSTRARRAY v) = "BSTRARRAY(...)"
    | variantToString (DISPATCHARRAY v) = "DISPATCHARRAY(...)"
    | variantToString (ERRORARRAY v) = "ERRORARRAY(...)"
    | variantToString (BOOLARRAY v) = "BOOLARRAY(...)"
    | variantToString (VARIANTARRAY v) = "VARIANTARRAY(...)"
    | variantToString (UNKNOWNARRAY v) = "UNKNOWNARRAY(...)"
    | variantToString (DECIMALARRAY v) = "DECIMALARRAY(...)"
    | variantToString (I1ARRAY v) = "I1ARRAY(...)"
    | variantToString (UI1ARRAY v) = "UI1ARRAY(...)"
    | variantToString (UI2ARRAY v) = "UI2ARRAY(...)"
    | variantToString (UI4ARRAY v) = "UI4ARRAY(...)"
    | variantToString (I8ARRAY v) = "I8ARRAY(...)"
    | variantToString (UI8ARRAY v) = "UI8ARRAY(...)"
    | variantToString (INTARRAY v) = "INTARRAY(...)"
    | variantToString (UINTARRAY v) = "UINTARRAY(...)"
  end

  val WordsOfVariant = W.SIZEOF_VARIANT div (Word.wordSize div 8)
  val BytesOfWord = Word.wordSize div 8
  val productOfInts = List.foldl (op * ) 1

  val NullDispatch =
      {
        addRef = fn () => raise E.OLEError E.NullObjectPointer,
        release = fn () => raise E.OLEError E.NullObjectPointer,
        invoke = fn _ => fn _ => raise E.OLEError E.NullObjectPointer,
        invokeByDISPID = fn _ => fn _ => raise E.OLEError E.NullObjectPointer,
        get = fn _ => fn _ => raise E.OLEError E.NullObjectPointer,
        getByDISPID = fn _ => fn _ => raise E.OLEError E.NullObjectPointer,
        set = fn _ => fn _ => fn _ => raise E.OLEError E.NullObjectPointer,
        setByDISPID =
        fn _ => fn _ => fn _ => raise E.OLEError E.NullObjectPointer,
        setRef = fn _ => fn _ => fn _ => raise E.OLEError E.NullObjectPointer,
        setRefByDISPID =
        fn _ => fn _ => fn _ => raise E.OLEError E.NullObjectPointer,
        getTypeInfo = fn _ => raise E.OLEError E.NullObjectPointer,
        this = Finalizable.new (UM.NULL, fn _ => ())
      } : Dispatch

  fun isNullDispatch ({this, ...} : Dispatch) =
      UM.isNULL (Finalizable.getValue this)

  (**********)

  type WriteCTX = BS.outstream * ((unit -> unit) -> unit)

  type ReadCTX = BS.instream

  (**********)
  (* reader/writer for some basic types are defined here for dependency reason.
   *)

  fun readByte (CTX as (instream) : ReadCTX) =
      let val (byte, instream) = BS.input instream
      in (byte, instream) end
  fun readWord32 CTX =
      let
        val (byte1, CTX) = readByte CTX
        val (byte2, CTX) = readByte CTX
        val (byte3, CTX) = readByte CTX
        val (byte4, CTX) = readByte CTX
        val value = word8QuadToWord32 (byte1, byte2, byte3, byte4)
      in
        (value, CTX)
      end
  fun readAddress CTX =
      let val (word, CTX) = readWord32 CTX in (UM.wordToAddress word, CTX) end

  fun writeByte byte ((outstream, addFinisher) : WriteCTX) =
      let val outstream = BS.output (outstream, byte)
      in (outstream, addFinisher) end
  fun writeWord32 word ((outstream, addFinisher) : WriteCTX) =
      let
        val (byte1, byte2, byte3, byte4) = word32ToWord8Quad word
        val outstream = BS.output (outstream, byte1)
        val outstream = BS.output (outstream, byte2)
        val outstream = BS.output (outstream, byte3)
        val outstream = BS.output (outstream, byte4)
      in
        (outstream, addFinisher)
      end
  fun writeAddress address CTX = writeWord32 (UM.addressToWord address) CTX

  (**********)
  (* serialize and deserialize SAFEARRAY. *)

  (**
   * serialize array of SAFEARRAYBOUNDs.
   * SAFEARRAYBOUND is declared in oaidl.h as follows:
   *   typedef struct tagSAFEARRAYBOUND {
   *        ULONG cElements;
   *        LONG lLbound;
   *   } SAFEARRAYBOUND;
   * lengths is a list of cElements.
   * lLbound is 0 always.
   *)
  fun serializeSAFEARRAYBOUNDs lengths =
      let
        val array = Array.array (2 * List.length lengths, 0)
        val _ =
            List.foldl
                (fn (len, offset) =>
                    (Array.update (array, offset, len); offset + 2))
                0
                lengths
      in
        array
      end

  (**
   * converts a single dimension array to a SAFEARRAY of multiple dimensions.
   *)
  fun arrayToSAFEARRAY
          addFinisher (elementWriter, elementVTtag) (array, lengths) =
      let
        (* setup SAFEARRAYBOUND[] *)
        val arrayLen = Array.length array
        val _ =
            if arrayLen <> (productOfInts lengths)
            then raise Fail "incorrect lengths in array."
            else ()
        val BOUNDS = FLOB.fixedCopy (serializeSAFEARRAYBOUNDs lengths)
        val _ = addFinisher (fn _ => FLOB.release BOUNDS)

        (* create array *)
        val safearray =
            W.SafeArrayCreate
                (
                  elementVTtag,
                  Word.fromInt(List.length lengths),
                  FLOB.addressOf BOUNDS
                )
        val _ = if UM.isNULL safearray
                then raise Fail "cannot create Safearray."
                else ()

        (* check size *)
        val elemSize = W.SafeArrayGetElemsize safearray

        val sizeOfArray = Word.toInt elemSize * arrayLen

        (* write values into SAFEARRAY. *)
        val refData = ref UM.NULL
        val _ = COM.checkHRESULT(W.SafeArrayAccessData(safearray, refData))
        val outstream = BS.openUnmanagedMemoryOut (!refData, sizeOfArray)

        val _ = Array.foldl
                    (fn (variant, CTX) => elementWriter variant CTX)
                    (outstream, addFinisher) array

        (* clean up *)
        val _ = COM.checkHRESULT(W.SafeArrayUnaccessData(safearray))
      in
        safearray
      end

  (**
   * converts a SAFEARRAY of multiple dimensions to a single dimension array.
   *)
  fun SAFEARRAYToArray (elementReader, elementVTtag, elementSize) safeArray =
      let
        val vtref = ref (0w0 : W.VARTYPE)
        val _ = COM.checkHRESULT(W.SafeArrayGetVartype(safeArray, vtref))
        val vt = !vtref
        val _ =
            if vt <> elementVTtag
            then
              raise
                E.OLEError
                    (E.TypeMismatch
                         ("array of unexpected VT 0wx" ^ Word.toString vt))
            else ()

        val dim = W.SafeArrayGetDim(safeArray)
        fun getLengths level dims =
            if dim < level
            then List.rev dims
            else
              let
                val lboundRef = ref 0
                val _ =
                    COM.checkHRESULT
                        (W.SafeArrayGetLBound(safeArray, level, lboundRef))
                val uboundRef = ref 0
                val _ =
                    COM.checkHRESULT
                        (W.SafeArrayGetUBound (safeArray, level, uboundRef))
              in
                getLengths
                    (level + 0w1)
                    ((!uboundRef - !lboundRef + 1) :: dims)
              end
        val lengths = getLengths 0w1 []
        val elements = productOfInts lengths

        val elemSize = Word.toInt(W.SafeArrayGetElemsize safeArray)
        val _ =
            if elemSize <> elementSize
            then raise Fail ("BUG: elemeSize = " ^ Int.toString elemSize)
            else ()
        val arraySize = elemSize * elements

        val refData = ref UM.NULL
        val _ = COM.checkHRESULT (W.SafeArrayAccessData(safeArray, refData))
        val instream = BS.openUnmanagedMemoryIn (!refData, arraySize)
        fun deserialize 0 instream vs = Array.fromList (List.rev vs)
          | deserialize n instream vs =
            let
              val CTX = (instream) : ReadCTX
              val (v, instream') = elementReader CTX
              val _ =
                  if BS.getPosIn instream' - BS.getPosIn instream = elemSize
                  then ()
                  else raise Fail "incomplete deserialization of array"
            in
              deserialize (n - 1) instream' (v :: vs)
            end
        val array = deserialize elements instream []
      in
        COM.checkHRESULT(W.SafeArrayUnaccessData(safeArray));
        (array, lengths)
      end

  fun writeARRAY (writer, tag) array (CTX as (outstream, addFinisher)) =
      let
        val safearray = arrayToSAFEARRAY addFinisher (writer, tag) array
      in writeAddress safearray CTX end

  fun readARRAY (reader, tag, size) CTX =
      let
        val (address, CTX) = readAddress CTX
        val arrayAndDims = SAFEARRAYToArray (reader, tag, size) address
      in (arrayAndDims, CTX) end

  (**********)
  (* serializing Variant. *)

  fun emptyVariant () =
      let val buffer = Word8Array.array (W.SIZEOF_VARIANT, 0w0)
      in buffer
      end

  infix >>
  fun f >> g = (g o f)

  fun writeEMPTY CTX = CTX
  fun writeNULL CTX = CTX
  fun writeUI1 byte CTX = writeByte byte CTX
  fun writeUI2 word16 CTX =
      let
        val word32 = word16ToWord32 word16
        val low = word32ToWord8 (Word32.andb (word32, 0wxFF))
        val high = word32ToWord8 (Word32.andb (Word32.>> (word32, 0w8), 0wxFF))
      in
        (writeUI1 low >> writeUI1 high) CTX
      end
  fun writeUI4 word CTX = writeWord32 word CTX
  fun writeI1 int8 ((outstream, addFinisher) : WriteCTX) =
      let val outstream = BS.output (outstream, int8ToWord8 int8)
      in (outstream, addFinisher) end
  fun writeI2 int16 CTX =
      let val word = int16ToWord32 int16
      in writeUI2 word CTX end
  fun writeI4 int CTX = writeUI4 (int32ToWord32 int) CTX
  fun writeR4 real32 CTX =
      let val word = real32ToWord32 real32
      in writeUI4 word CTX end
  fun writeR8 real64 CTX =
      let val (word1, word2) = real64ToWord32Double real64
      in (writeUI4 word1 >> writeUI4 word2) CTX
      end
  fun writeBSTR olestr (CTX as (_, addFinisher) : WriteCTX) =
      let val bstr = OLESTRToBSTR olestr
      in addFinisher (fn () => W.SysFreeString bstr); writeUI4 bstr CTX
      end
  fun writeDISPATCH ({this, ...} : Dispatch) CTX =
      writeAddress (Finalizable.getValue this) CTX
  fun writeERROR scode CTX = writeI4 scode CTX
  fun writeBOOL bool CTX =
      (if bool then writeUI2 W.VARIANT_TRUE else writeUI2 W.VARIANT_FALSE) CTX
  fun writeUNKNOWN ({this, ...} : COM.Unknown) CTX =
      writeAddress (Finalizable.getValue this) CTX
  fun writeDECIMAL inVariant decimal ((outstream, addFinisher) : WriteCTX) =
      let (* NOTE: write a decimal inline, not pointer. *)
        val outstream =
            Decimal.export inVariant (outstream, decimal)
            handle
            General.Overflow => raise E.OLEError (E.Conversion "decimal")
      in
        (outstream, addFinisher)
      end
  fun writeI8 int64 CTX =
      let val (word1, word2) = int64ToWords int64
      in (writeUI4 word1 >> writeUI4 word2) CTX
      end
  fun writeUI8 word64 CTX =
      let val (word1, word2) = word64ToWords word64
      in (writeUI4 word1 >> writeUI4 word2) CTX
      end
  fun writeINT int CTX = writeI4 int CTX
  fun writeUINT word CTX = writeUI4 word CTX

  fun writeBYREF v (CTX as (outstream, addFinisher)) =
      let
        val address = W.CoTaskMemAlloc W.SIZEOF_VARIANT
        val outstream' =
            BS.openUnmanagedMemoryOut
                (UM.wordToAddress address, W.SIZEOF_VARIANT)
        val _ = writeVariant false v (outstream', addFinisher)
        (* ToDo : Is it safe to release memory by client ? *)
        val _ = addFinisher (fn _ => W.CoTaskMemFree address)
      in
        writeUI4 address CTX
      end

  and writeBYREFOUT (r as ref(v)) (CTX as (outstream, addFinisher)) =
      let
        val tag = tagOfVariant v

        val COMbuffer = W.CoTaskMemAlloc W.SIZEOF_VARIANT
        val _ = addFinisher (fn _ => W.CoTaskMemFree COMbuffer)
        val outstream' =
            BS.openUnmanagedMemoryOut
                (UM.wordToAddress COMbuffer, W.SIZEOF_VARIANT)
        val CTX' = (outstream', addFinisher)
        val _ = writeVariant false v CTX'

        fun writeBack () =
            let
              val instream =
                  BS.openUnmanagedMemoryIn 
                      (UM.wordToAddress COMbuffer, W.SIZEOF_VARIANT)
              val (v, _) = readVariant (SOME tag) instream
              val _ = r := v
            in () end
        val _ = addFinisher writeBack
      in
        writeUI4 COMbuffer CTX
      end

  and writeI2ARRAY array CTX = writeARRAY (writeI2, W.VT_I2) array CTX
  and writeI4ARRAY array CTX = writeARRAY (writeI4, W.VT_I4) array CTX
  and writeR4ARRAY array CTX = writeARRAY (writeR4, W.VT_R4) array CTX
  and writeR8ARRAY array CTX = writeARRAY (writeR8, W.VT_R8) array CTX
  and writeBSTRARRAY array CTX = writeARRAY (writeBSTR, W.VT_BSTR) array CTX
  and writeDISPATCHARRAY array CTX = writeARRAY (writeDISPATCH, W.VT_DISPATCH) array CTX
  and writeERRORARRAY array CTX = writeARRAY (writeERROR, W.VT_ERROR) array CTX
  and writeBOOLARRAY array CTX = writeARRAY (writeBOOL, W.VT_BOOL) array CTX
  and writeVARIANTARRAY array CTX = writeARRAY (writeVariant true, W.VT_VARIANT) array CTX
  and writeUNKNOWNARRAY array CTX = writeARRAY (writeUNKNOWN, W.VT_UNKNOWN) array CTX
  and writeDECIMALARRAY array CTX = writeARRAY (writeDECIMAL false, W.VT_DECIMAL) array CTX
  and writeI1ARRAY array CTX = writeARRAY (writeI1, W.VT_I1) array CTX
  and writeUI1ARRAY array CTX = writeARRAY (writeUI1, W.VT_UI1) array CTX
  and writeUI2ARRAY array CTX = writeARRAY (writeUI2, W.VT_UI2) array CTX
  and writeUI4ARRAY array CTX = writeARRAY (writeUI4, W.VT_UI4) array CTX
  and writeI8ARRAY array CTX = writeARRAY (writeI8, W.VT_I8) array CTX
  and writeUI8ARRAY array CTX = writeARRAY (writeUI8, W.VT_UI8) array CTX
  and writeINTARRAY array CTX = writeARRAY (writeINT, W.VT_INT) array CTX
  and writeUINTARRAY array CTX = writeARRAY (writeUINT, W.VT_UINT) array CTX

  and writeVariant withTag variant (CTX as (outstream, addFinisher)) =
      let
        val writeTag =
            if withTag
            then fn tag => writeUI2 tag >> writeUI2 0w0 >> writeUI4 0w0
            else fn tag => fn CTX => CTX
        fun writeArrayTag tag = writeTag (tagOfArray tag)
        fun writeByRefTag tag = writeTag (Word.orb(W.VT_BYREF, tag))
        val startPos = BS.getPosOut outstream
        val writer = 
            case variant of
              EMPTY => writeTag W.VT_EMPTY
            | NULL => writeTag W.VT_NULL
            | I2 int16 => writeTag W.VT_I2 >> writeI2 int16
            | I4 int32 => writeTag W.VT_I4 >> writeI4 int32
            | R4 real32 => writeTag W.VT_R4 >> writeR4 real32
            | R8 real64 => writeTag W.VT_R8 >> writeR8 real64
            | BSTR olestr => writeTag W.VT_BSTR >> writeBSTR olestr
            | DISPATCH dispatch =>
              writeTag W.VT_DISPATCH >> writeDISPATCH dispatch
            | ERROR scode => writeTag W.VT_ERROR >> writeERROR scode
            | BOOL bool => writeTag W.VT_BOOL >> writeBOOL bool
            | VARIANT v => writeVariant true v (* FIXME: should reject ? *)
            | UNKNOWN unknown => writeTag W.VT_UNKNOWN >> writeUNKNOWN unknown
            | DECIMAL decimal => (* no tag *) writeDECIMAL true decimal
            | I1 int8 => writeTag W.VT_I1 >> writeI1 int8
            | UI1 byte => writeTag W.VT_UI1 >> writeUI1 byte
            | UI2 word16 => writeTag W.VT_UI2 >> writeUI2 word16
            | UI4 word32 => writeTag W.VT_UI4 >> writeUI4 word32
            | I8 int64 => writeTag W.VT_I8 >> writeI8 int64
            | UI8 word64 => writeTag W.VT_UI8 >> writeUI8 word64
            | INT int => writeTag W.VT_INT >> writeINT int
            | UINT word => writeTag W.VT_UINT >> writeUINT word

            | BYREF v => writeByRefTag (tagOfVariant v) >> writeBYREF v
            | BYREFOUT r => writeByRefTag(tagOfVariant (!r)) >> writeBYREFOUT r

            | I2ARRAY array =>
              writeArrayTag W.VT_I2 >> writeI2ARRAY array
            | I4ARRAY array =>
              writeArrayTag W.VT_I4 >> writeI4ARRAY array
            | R4ARRAY array =>
              writeArrayTag W.VT_R4 >> writeR4ARRAY array
            | R8ARRAY array =>
              writeArrayTag W.VT_R8 >> writeR8ARRAY array
            | BSTRARRAY array =>
              writeArrayTag W.VT_BSTR >> writeBSTRARRAY array
            | DISPATCHARRAY array =>
              writeArrayTag W.VT_DISPATCH >> writeDISPATCHARRAY array
            | ERRORARRAY array =>
              writeArrayTag W.VT_ERROR >> writeERRORARRAY array
            | BOOLARRAY array =>
              writeArrayTag W.VT_BOOL >> writeBOOLARRAY array
            | VARIANTARRAY array =>
              writeArrayTag W.VT_VARIANT >> writeVARIANTARRAY array
            | UNKNOWNARRAY array =>
              writeArrayTag W.VT_UNKNOWN >> writeUNKNOWNARRAY array
            | DECIMALARRAY array =>
              writeArrayTag W.VT_DECIMAL >> writeDECIMALARRAY array
            | I1ARRAY array =>
              writeArrayTag W.VT_I1 >> writeI1ARRAY array
            | UI1ARRAY array =>
              writeArrayTag W.VT_UI1 >> writeUI1ARRAY array
            | UI2ARRAY array =>
              writeArrayTag W.VT_UI2 >> writeUI2ARRAY array
            | UI4ARRAY array =>
              writeArrayTag W.VT_UI4 >> writeUI4ARRAY array
            | I8ARRAY array =>
              writeArrayTag W.VT_I8 >> writeI8ARRAY array
            | UI8ARRAY array =>
              writeArrayTag W.VT_UI8 >> writeUI8ARRAY array
            | INTARRAY array =>
              writeArrayTag W.VT_INT >> writeINTARRAY array
            | UINTARRAY array =>
              writeArrayTag W.VT_UINT >> writeUINTARRAY array

(*
            | _ => raise Fail "BUG:unsupported variant."
*)
        val CTX as (outstream, _) = writer CTX
        val endPos = BS.getPosOut outstream
        val paddingLength = W.SIZEOF_VARIANT - (endPos - startPos)
        val outstream = BS.skipOut (outstream, paddingLength)
      in
        (outstream, addFinisher) : WriteCTX
      end

  and variantsToArray variants =
      let
        val numBytes = length variants * W.SIZEOF_VARIANT
        val array = Word8Array.array (numBytes, 0w0)
        val finishers = ref ([] : (unit -> unit) list)
        fun addFinisher finisher = finishers := finisher :: (!finishers)
        val outstream = BS.openArrayOut array
      in
        List.foldl
            (fn (variant, CTX) => writeVariant true variant CTX)
            (outstream, addFinisher)
            variants;
        (array, fn () => List.app (fn f => f ()) (!finishers))
      end

  (**********)
  (* deserializing Variant. *)

  and readEMPTY CTX = CTX
  and readNULL CTX = CTX
  and readUI1 CTX = readByte CTX
  and readUI2 (CTX as (instream) : ReadCTX) =
      let
        val (low, CTX) = readUI1 CTX
        val (high, CTX) = readUI1 CTX
        val value =
            Word32.orb (Word32.<< (word8ToWord32 high, 0w8), word8ToWord32 low)
      in (value, CTX) end
  and readUI4 CTX = readWord32 CTX
  and readI1 (instream : ReadCTX) =
      let
        val (byte, instream) = BS.input instream
        val int8 = word8ToInt8 byte
      in (int8, instream) end
  and readI2 CTX =
      let val (word16, CTX) = readUI2 CTX
      in (word32ToInt16 word16, CTX) end
  and readI4 CTX =
      let val (word32, CTX) = readUI4 CTX
      in (word32ToInt32X word32, CTX) end
  and readR4 CTX =
      let val (word32, CTX) = readUI4 CTX
      in (word32ToReal32 word32, CTX) end
  and readR8 CTX =
      let
        val (word1, CTX) = readUI4 CTX
        val (word2, CTX) = readUI4 CTX
      in (word32DoubleToReal64 (word1, word2), CTX) end
  and readBSTR CTX =
      let val (bstr, CTX) = readUI4 CTX
      in (BSTRToOLESTR bstr, CTX) before W.SysFreeString bstr end
  and readDISPATCH CTX =
      let
        val (address, CTX) = readAddress CTX
        val dispatch = 
            if UnmanagedMemory.isNULL address
            then NullDispatch
            else wrapDispatch (COM.wrapUnknown address)
      in
        (dispatch, CTX)
      end
  and readERROR CTX = readI4 CTX
  and readBOOL CTX =
      let val (word16, CTX) = readUI2 CTX
      in (not (word16 = W.VARIANT_FALSE), CTX) end
  and readUNKNOWN CTX =
      let
        val (address, CTX) = readAddress CTX
        val unknown =
            if UnmanagedMemory.isNULL address
            then COM.NullUnknown
            else COM.wrapUnknown address
      in
        (unknown, CTX)
      end
  and readDECIMAL (CTX as instream : ReadCTX) =
      let
        val (decimal, instream) = Decimal.import instream
      in
        (decimal, instream)
      end
  and readI8 CTX =
      let
        val (word1, CTX) = readUI4 CTX
        val (word2, CTX) = readUI4 CTX
      in (wordsToInt64 (word1, word2), CTX) end
  and readUI8 CTX =
      let
        val (word1, CTX) = readUI4 CTX
        val (word2, CTX) = readUI4 CTX
      in (wordsToWord64 (word1, word2), CTX) end
  and readINT CTX = readI4 CTX
  and readUINT CTX = readUI4 CTX

  and readI2ARRAY CTX =
      readARRAY (readI2, W.VT_I2, W.SIZEOF_I2) CTX
  and readI4ARRAY CTX =
      readARRAY (readI4, W.VT_I4, W.SIZEOF_I4) CTX
  and readR4ARRAY CTX =
      readARRAY (readR4, W.VT_R4, W.SIZEOF_R4) CTX
  and readR8ARRAY CTX =
      readARRAY (readR8, W.VT_R8, W.SIZEOF_R8) CTX
  and readBSTRARRAY CTX =
      readARRAY (readBSTR, W.VT_BSTR, W.SIZEOF_BSTR) CTX
  and readDISPATCHARRAY CTX =
      readARRAY (readDISPATCH, W.VT_DISPATCH, W.SIZEOF_DISPATCH) CTX
  and readERRORARRAY CTX =
      readARRAY (readERROR, W.VT_ERROR, W.SIZEOF_ERROR) CTX
  and readBOOLARRAY CTX =
      readARRAY (readBOOL, W.VT_BOOL, W.SIZEOF_BOOL) CTX
  and readVARIANTARRAY CTX =
      readARRAY (readVariant NONE, W.VT_VARIANT, W.SIZEOF_VARIANT) CTX
  and readUNKNOWNARRAY CTX =
      readARRAY (readUNKNOWN, W.VT_UNKNOWN, W.SIZEOF_UNKNOWN) CTX
  and readDECIMALARRAY CTX =
      readARRAY (readDECIMAL, W.VT_DECIMAL, W.SIZEOF_DECIMAL) CTX
  and readI1ARRAY CTX =
      readARRAY (readI1, W.VT_I1, W.SIZEOF_I1) CTX
  and readUI1ARRAY CTX =
      readARRAY (readUI1, W.VT_UI1, W.SIZEOF_UI1) CTX
  and readUI2ARRAY CTX =
      readARRAY (readUI2, W.VT_UI2, W.SIZEOF_UI2) CTX
  and readUI4ARRAY CTX =
      readARRAY (readUI4, W.VT_UI4, W.SIZEOF_UI4) CTX
  and readI8ARRAY CTX =
      readARRAY (readI8, W.VT_I8, W.SIZEOF_I8) CTX
  and readUI8ARRAY CTX =
      readARRAY (readUI8, W.VT_UI8, W.SIZEOF_UI8) CTX
  and readINTARRAY CTX =
      readARRAY (readINT, W.VT_INT, W.SIZEOF_INT) CTX
  and readUINTARRAY CTX =
      readARRAY (readUINT, W.VT_UINT, W.SIZEOF_UINT) CTX

  (**
   * If tagOpt is NONE, read tag from stream.
   *)
  and readVariant tagOpt (StartCTX as instream : ReadCTX) =
      let
        infix <<
        fun (tag << reader) context =
            let val (value, context) = reader context
            in (tag value, context) end

        val startPos = BS.getPosIn instream
        val (tag, CTX) =
            case tagOpt
             of NONE =>
                let
                  val (tag, CTX) = readUI2 StartCTX
                  val (_, CTX) = readUI2 CTX
                  val (_, CTX) = readUI4 CTX
                in (tag, CTX) end
              | SOME tag => (tag, StartCTX)
        val (variant, CTX as intream) =
            if tag = W.VT_EMPTY then (EMPTY, CTX)
            else if tag = W.VT_NULL then (NULL, CTX)
            else if tag = W.VT_I2 then (I2 << readI2) CTX
            else if tag = W.VT_I4 then (I4 << readI4) CTX
            else if tag = W.VT_R4 then (R4 << readR4) CTX
            else if tag = W.VT_R8 then (R8 << readR8) CTX
            else if tag = W.VT_BSTR then (BSTR << readBSTR) CTX
            else if tag = W.VT_DISPATCH then (DISPATCH << readDISPATCH) CTX
            else if tag = W.VT_ERROR then (ERROR << readERROR) CTX
            else if tag = W.VT_BOOL then (BOOL << readBOOL) CTX
            else if tag = W.VT_UNKNOWN then (UNKNOWN << readUNKNOWN) CTX
            else if tag = W.VT_DECIMAL then (DECIMAL << readDECIMAL) StartCTX
            else if tag = W.VT_I1 then (I1 << readI1) CTX
            else if tag = W.VT_UI1 then (UI1 << readUI1) CTX
            else if tag = W.VT_UI2 then (UI2 << readUI2) CTX
            else if tag = W.VT_UI4 then (UI4 << readUI4) CTX
            else if tag = W.VT_I8 then (I8 << readI8) CTX
            else if tag = W.VT_UI8 then (UI8 << readUI8) CTX
            else if tag = W.VT_INT then (INT << readINT) CTX
            else if tag = W.VT_UINT then (UINT << readUINT) CTX

            else if tag = tagOfArray W.VT_I2
            then (I2ARRAY << readI2ARRAY) CTX
            else if tag = tagOfArray W.VT_I4
            then (I4ARRAY << readI4ARRAY) CTX
            else if tag = tagOfArray W.VT_R4
            then (R4ARRAY << readR4ARRAY) CTX
            else if tag = tagOfArray W.VT_R8
            then (R8ARRAY << readR8ARRAY) CTX
            else if tag = tagOfArray W.VT_BSTR
            then (BSTRARRAY << readBSTRARRAY) CTX
            else if tag = tagOfArray W.VT_DISPATCH
            then (DISPATCHARRAY << readDISPATCHARRAY) CTX
            else if tag = tagOfArray W.VT_ERROR
            then (ERRORARRAY << readERRORARRAY) CTX
            else if tag = tagOfArray W.VT_BOOL
            then (BOOLARRAY << readBOOLARRAY) CTX
            else if tag = tagOfArray W.VT_VARIANT
            then (VARIANTARRAY << readVARIANTARRAY) CTX
            else if tag = tagOfArray W.VT_UNKNOWN
            then (UNKNOWNARRAY << readUNKNOWNARRAY) CTX
            else if tag = tagOfArray W.VT_DECIMAL
            then (DECIMALARRAY << readDECIMALARRAY) CTX
            else if tag = tagOfArray W.VT_I1
            then (I1ARRAY << readI1ARRAY) CTX
            else if tag = tagOfArray W.VT_UI1
            then (UI1ARRAY << readUI1ARRAY) CTX
            else if tag = tagOfArray W.VT_UI2
            then (UI2ARRAY << readUI2ARRAY) CTX
            else if tag = tagOfArray W.VT_UI4
            then (UI4ARRAY << readUI4ARRAY) CTX
            else if tag = tagOfArray W.VT_I8
            then (I8ARRAY << readI8ARRAY) CTX
            else if tag = tagOfArray W.VT_UI8
            then (UI8ARRAY << readUI8ARRAY) CTX
            else if tag = tagOfArray W.VT_INT
            then (INTARRAY << readINTARRAY) CTX
            else if tag = tagOfArray W.VT_UINT
            then (UINTARRAY << readUINTARRAY) CTX

            else
              raise
                E.OLEError
                    (E.TypeMismatch
                         ("unsupported VARIANT type:" ^ Word.toString tag))

        val endPos = BS.getPosIn instream
        val paddingLength = W.SIZEOF_VARIANT - (endPos - startPos)
        val CTX = BS.skipIn (instream, paddingLength)
      in
        (variant, CTX)
      end

  and arrayToVariants array =
      let
        val instream = BS.openArrayIn array
        val CTX = instream : ReadCTX
        fun deserialize (CTX as instream) variants =
            if Word8Array.length array = BS.getPosIn instream
            then List.rev variants
            else if Word8Array.length array < BS.getPosIn instream
            then raise Fail "BUG: readVariant exceeds the end of array"
            else
              let
                val (variant, CTX') = readVariant NONE CTX
              in
                deserialize CTX' (variant :: variants)
              end
      in
        deserialize CTX []
      end

  (**********)

  and wrapDispatch (Unknown : COM.Unknown) =
      let
        type this = UM.address

        val ptrDispatch = #queryInterface Unknown W.IID_IDispatch

        val vptr = UM.subWord ptrDispatch

        val fptrQueryInterface = UM.wordToAddress (UMSubWord vptr)
        val IDispatch_QueryInterface =
            fptrQueryInterface
            : _import _stdcall (this, W.REFIID, UM.address ref) -> W.HRESULT

        val fptrAddRef = UM.wordToAddress (UMSubWord (vptr + 0w4))
        val IDispatch_AddRef =
            fptrAddRef : _import _stdcall (this) -> W.ULONG

        val fptrRelease = UM.wordToAddress (UMSubWord (vptr + 0w8))
        val IDispatch_Release =
            fptrRelease : _import _stdcall (this) -> W.ULONG

        val fptrGetTypeInfoCount = UM.wordToAddress (UMSubWord (vptr + 0w12))
        val IDispatch_GetTypeInfoCount =
            fptrGetTypeInfoCount
            : _import _stdcall (this, W.UINT ref) -> W.HRESULT

        val fptrGetTypeInfo = UM.wordToAddress (UMSubWord (vptr + 0w16))
        val IDispatch_GetTypeInfo =
            fptrGetTypeInfo
              : _import _stdcall
                          (this, W.UINT, W.LCID, W.LPTYPEINFO ref) -> W.HRESULT

        val fptrGetIDsOfNames = UM.wordToAddress (UMSubWord (vptr + 0w20))
        val IDispatch_GetIDsOfNames =
            fptrGetIDsOfNames
            : _import _stdcall
                (this, W.REFIID, W.LPOLESTR ref, W.UINT, W.LCID, W.DISPID ref)
                -> W.HRESULT

        val fptrInvoke = UM.wordToAddress (UMSubWord (vptr + 0w24))
        val IDispatch_Invoke =
            fptrInvoke
            : _import _stdcall
              (
                this,
                W.DISPID,
                W.REFIID,
                W.LCID,
                W.WORD,
                W.DISPPARAMS,
                W.VARIANT,
                W.EXCEPINFO,
                W.UINT ref
              ) -> W.HRESULT

        val this =
            Finalizable.new (ptrDispatch, fn t => (IDispatch_Release t; ()))
                   
        fun getIDOfName name =
            let
              val DISPIDRef = ref 0
              val _ =
                  COM.checkHRESULT
                      (IDispatch_GetIDsOfNames
                           (
                             Finalizable.getValue this,
                             W.IID_NULL,
                             ref (OLEString.MBSToBytes name),
                             0w1,
                             0w0,
                             DISPIDRef
                           ))
            in
              ! DISPIDRef
            end

        fun invoke dispatch_flag DISPID positionalArgs namedIDArgs =
            let
              val namedIDs =
                  Array.fromList (map (Word.fromInt o #1) namedIDArgs)
              (*
               * namedArgs are followed by positionalArgs.
               * positionalArgs are placed in reversed order.
               *)
              val (argsBuffer, cleanArgs) =
                  variantsToArray
                      ((map #2 namedIDArgs) @ (List.rev positionalArgs))
              val dispparams : W.DISPPARAMS =
                  (
                    argsBuffer,
                    namedIDs,
                    Word.fromInt(length positionalArgs + length namedIDArgs),
                    Word.fromInt(length namedIDArgs)
                  )
              val resultBuffer = emptyVariant ()
              val excepinfo : W.EXCEPINFO =
                  Array.array
                      (W.SIZEOF_EXCEPINFO div (Word.wordSize div 8), 0w0)
                  (*
                  (0w0, 0w0, 0w0, 0w0, 0w0, 0w0, 0w0, 0w0)
                  *)
              val argErr = ref 0w0

              val hresult = 
                  IDispatch_Invoke
                      (
                        Finalizable.getValue this,
                        DISPID,
                        W.IID_NULL,
                        W.LOCALE_USER_DEFAULT,
                        dispatch_flag,
                        dispparams,
                        resultBuffer,
                        excepinfo,
                        argErr
                      )
            in
              cleanArgs ();
              if hresult = W.DISP_E_EXCEPTION
              then
                let
                  val code = Array.sub(excepinfo, 0)
                  val source = Array.sub(excepinfo, 1)
                  val description = Array.sub(excepinfo, 2)
                  val helpfile = Array.sub(excepinfo, 3)
                  val helpcontext = Array.sub(excepinfo, 4)
                  val exn = 
                      E.ComApplicationError
                          {
                            code = code,
                            source =
                            (OLEString.toAsciiString o BSTRToOLESTR) source,
                            description =
                            (OLEString.toAsciiString o BSTRToOLESTR)
                                description,
                            helpfile = 
                            (OLEString.toAsciiString o BSTRToOLESTR) helpfile,
                            helpcontext = helpcontext
                          }
                  val _ = W.SysFreeString source
                  val _ = W.SysFreeString description
                  val _ = W.SysFreeString helpfile
                in
                  raise E.OLEError exn
                end
              else
                COM.checkHRESULT hresult;
                case arrayToVariants resultBuffer
                 of [] => NONE
                  | [result] => SOME result
                  | _ =>
                    raise
                      E.OLEError
                          (E.ResultMismatch
                               "Invoke returns more than one variants.")
            end

        fun methodInvokeByDISPID DISPID args =
            invoke W.DISPATCH_METHOD DISPID args []

        fun methodInvoke name =
            let val DISPID = getIDOfName name
            in fn args => methodInvokeByDISPID DISPID args
            end

        fun propertyGetByDISPID DISPID indexes =
            Option.valOf(invoke W.DISPATCH_PROPERTYGET DISPID indexes [])

        fun propertyGet name =
            let val DISPID = getIDOfName name
            in fn indexes => propertyGetByDISPID DISPID indexes
            end

        fun propertyPutByDISPID DISPID indexes value =
            (
              invoke
                  W.DISPATCH_PROPERTYPUT
                  DISPID
                  indexes
                  [(W.DISPID_PROPERTYPUT, value)];
                  ()
            )

        fun propertyPut name =
            let val DISPID = getIDOfName name
            in
              fn indexes =>
                 fn value => propertyPutByDISPID DISPID indexes value
            end

        fun propertyPutRefByDISPID DISPID indexes value =
            (
              invoke
                  W.DISPATCH_PROPERTYPUTREF
                  DISPID
                  indexes
                  [(W.DISPID_PROPERTYPUT, value)];
                  ()
            )

        fun propertyPutRef name =
            let val DISPID = getIDOfName name
            in
              fn indexes =>
                 fn value => propertyPutRefByDISPID DISPID indexes value
            end

        fun getTypeInfo () =
            let
              val TYPEINFORef = ref 0w0
              val _ =
                  COM.checkHRESULT
                      (IDispatch_GetTypeInfo
                           (
                             Finalizable.getValue this,
                             0w0,
                             W.LOCALE_USER_DEFAULT,
                             TYPEINFORef
                           ))
            in
              wrapTypeInfo(COM.wrapUnknown(UM.wordToAddress(! TYPEINFORef)))
            end

      in
        {
          addRef = fn () => IDispatch_AddRef (Finalizable.getValue this),
          release = fn () => IDispatch_Release (Finalizable.getValue this),
          get = propertyGet,
          getByDISPID = propertyGetByDISPID,
          set = propertyPut,
          setByDISPID = propertyPutByDISPID,
          setRef = propertyPutRef,
          setRefByDISPID = propertyPutRefByDISPID,
          invoke = methodInvoke,
          invokeByDISPID = methodInvokeByDISPID,
          getTypeInfo = getTypeInfo,
          this = this
        }
      end

  and wrapTypeInfo (Unknown : COM.Unknown) =
      let
        type this = UM.address

        val ptrTypeInfo = #queryInterface Unknown W.IID_ITypeInfo

        val vptr = UM.subWord ptrTypeInfo

        (* HRESULT QueryInterface(THIS,REFIID,PVOID* ); *)
        val fptrQueryInterface = UM.wordToAddress (UMSubWord vptr)
        val ITypeInfo_QueryInterface =
            fptrQueryInterface
            : _import _stdcall (this, W.REFIID, UM.address ref) -> W.HRESULT

        (* HRESULT ULONG,AddRef(THIS); *)
        val fptrAddRef = UM.wordToAddress (UMSubWord (vptr + 0w4))
        val ITypeInfo_AddRef =
            fptrAddRef : _import _stdcall (this) -> W.ULONG

        (* HRESULT ULONG,Release(THIS); *)
        val fptrRelease = UM.wordToAddress (UMSubWord (vptr + 0w8))
        val ITypeInfo_Release =
            fptrRelease : _import _stdcall (this) -> W.ULONG

        (* HRESULT GetTypeAttr(THIS,LPTYPEATTR* ); *)
        (* vptr + 0w12 *)
        (* HRESULT GetTypeComp(THIS,LPTYPECOMP* ); *)
        (* vptr + 0w16 *)
        (* HRESULT GetFuncDesc(THIS,UINT,LPFUNCDESC* ); *)
        (* vptr + 0w20 *)
        (* HRESULT GetVarDesc(THIS,UINT,LPVARDESC* ); *)
        (* vptr + 0w24 *)
        (* HRESULT GetNames(THIS,MEMBERID,BSTR*,UINT,UINT* ); *)
        (* vptr + 0w28 *)
        (* HRESULT GetRefTypeOfImplType(THIS,UINT,HREFTYPE* ); *)
        (* vptr + 0w32 *)
        (* HRESULT GetImplTypeFlags(THIS,UINT,INT* ); *)
        (* vptr + 0w36 *)
        (* HRESULT GetIDsOfNames(THIS,LPOLESTR*,UINT,MEMBERID* ); *)
        (* vptr + 0w40 *)
        (* HRESULT Invoke(THIS,PVOID,MEMBERID,WORD,DISPPARAMS*,VARIANT*,EXCEPINFO*,UINT* ); *)
        (* vptr + 0w44 *)
        (* HRESULT GetDocumentation(THIS,MEMBERID,BSTR*,BSTR*,DWORD*,BSTR* ); *)
        val fptrGetDocumentation = UM.wordToAddress (UMSubWord (vptr + 0w48))
        val ITypeInfo_GetDocumentation =
            fptrGetDocumentation
            : _import _stdcall
              (this, W.MEMBERID, W.BSTR ref, W.BSTR ref, W.pointer (*W.DWORD ref*), W.pointer (*W.BSTR ref*)) -> W.ULONG

        (* HRESULT GetDllEntry(THIS,MEMBERID,INVOKEKIND,BSTR*,BSTR*,WORD* ); *)
        (* vptr + 0w52 *)
        (* HRESULT GetRefTypeInfo(THIS,HREFTYPE,LPTYPEINFO* ); *)
        (* vptr + 0w56 *)
        (* HRESULT AddressOfMember(THIS,MEMBERID,INVOKEKIND,PVOID* ); *)
        (* vptr + 0w60 *)
        (* HRESULT CreateInstance(THIS,LPUNKNOWN,REFIID,PVOID* ); *)
        (* vptr + 0w64 *)
        (* HRESULT GetMops(THIS,MEMBERID,BSTR* ); *)
        (* vptr + 0w68 *)
        (* HRESULT GetContainingTypeLib(THIS,LPTYPELIB*,UINT* ); *)
        (* vptr + 0w72 *)
        (* HRESULT void,ReleaseTypeAttr(THIS,LPTYPEATTR); *)
        (* vptr + 0w76 *)
        (* HRESULT void,ReleaseFuncDesc(THIS,LPFUNCDESC); *)
        (* vptr + 0w80 *)
        (* HRESULT void,ReleaseVarDesc(THIS,LPVARDESC); *)
        (* vptr + 0w84 *)

        val this =
            Finalizable.new (ptrTypeInfo, fn t => (ITypeInfo_Release t; ()))

        fun getDocumentation () =
            let
              val nameRef = ref 0w0
              val documentRef = ref 0w0
              val _ = COM.checkHRESULT
                          (ITypeInfo_GetDocumentation
                               (
                                 Finalizable.getValue this,
                                 W.MEMBERID_NIL,
                                 nameRef,
                                 documentRef,
                                 0w0,
                                 0w0
                               ))
              val name = BSTRToOLESTR (!nameRef)
              val document = BSTRToOLESTR (!documentRef)
              val _ = W.SysFreeString (!nameRef)
              val _ = W.SysFreeString (!documentRef)
            in
              (name, document)
            end
      in
        {
          addRef = fn () => ITypeInfo_AddRef (Finalizable.getValue this),
          release = fn () => ITypeInfo_Release (Finalizable.getValue this),
          getDocumentation = getDocumentation,
          this = this
        } : TypeInfo
      end

  (****************************************)
  (* IEnumVARIANT *)

  fun wrapEnumVARIANT (Unknown : COM.Unknown) =
      let
        type this = UM.address

        val ptrEnumVARIANT = #queryInterface Unknown W.IID_IEnumVARIANT

        val vptr = UM.subWord ptrEnumVARIANT

        val fptrQueryInterface = UM.wordToAddress (UMSubWord vptr)
        val IEnumVARIANT_QueryInterface =
            fptrQueryInterface
            : _import _stdcall (this, W.REFIID, UM.address ref) -> W.HRESULT

        val fptrAddRef = UM.wordToAddress (UMSubWord (vptr + 0w4))
        val IEnumVARIANT_AddRef =
            fptrAddRef : _import _stdcall (this) -> W.ULONG

        val fptrRelease = UM.wordToAddress (UMSubWord (vptr + 0w8))
        val IEnumVARIANT_Release =
            fptrRelease : _import _stdcall (this) -> W.ULONG

        val fptrNext = UM.wordToAddress (UMSubWord (vptr + 0w12))
        val IEnumVARIANT_Next =
            fptrNext
            : _import _stdcall
                  (this, W.ULONG, Word8Array.array, W.ULONG ref) -> W.HRESULT

        val fptrSkip = UM.wordToAddress (UMSubWord (vptr + 0w16))
        val IEnumVARIANT_Skip =
            fptrSkip : _import _stdcall (this, W.ULONG) -> W.HRESULT

        val fptrReset = UM.wordToAddress (UMSubWord (vptr + 0w20))
        val IEnumVARIANT_Reset =
            fptrReset : _import _stdcall (this) -> W.HRESULT

        val fptrClone = UM.wordToAddress (UMSubWord (vptr + 0w24))
        val IEnumVARIANT_Clone =
            fptrClone : _import _stdcall (this, UM.address ref) -> W.HRESULT

        val this =
            Finalizable.new
                (ptrEnumVARIANT, fn t => (IEnumVARIANT_Release t; ()))
                   
        fun next count =
            let
              val (resultsBuffer : Word8Array.array, cleanArgs) =
                  variantsToArray (List.tabulate (count, fn _ => EMPTY))
              val got = ref 0w0
              val hresult = 
                  IEnumVARIANT_Next
                      (
                        Finalizable.getValue this,
                        Word.fromInt count,
                        resultsBuffer,
                        got
                      )
            in
              COM.checkHRESULT hresult;
              List.take (arrayToVariants resultsBuffer, Word.toInt(!got))
            end

        fun skip count =
            let
              val hresult = 
                  IEnumVARIANT_Skip
                      (Finalizable.getValue this, Word.fromInt count)
            in
              COM.checkHRESULT hresult;
              ()
            end

        fun reset count =
            let val hresult = IEnumVARIANT_Reset (Finalizable.getValue this)
            in COM.checkHRESULT hresult; ()
            end

        fun clone () =
            let
              val resultRef = ref UM.NULL
              val hresult =
                  IEnumVARIANT_Clone (Finalizable.getValue this, resultRef)
            in
              COM.checkHRESULT hresult; !resultRef
            end

      in
        {
          addRef = fn () => IEnumVARIANT_AddRef (Finalizable.getValue this),
          release = fn () => IEnumVARIANT_Release (Finalizable.getValue this),
          next = next,
          skip = skip,
          reset = reset,
          clone = clone,
          this = this
        } : EnumVARIANT
      end

  (****************************************)
  (* Automation *)

  local
    fun create CLSID =
      let
        val lp_IDispatch = ref UM.NULL
        val ctxFlag = Word.orb (W.CLSCTX_INPROC_SERVER, W.CLSCTX_LOCAL_SERVER)
        val _ =
            COM.checkHRESULT
                (W.CoCreateInstance
                     (CLSID, 0w0, ctxFlag, W.IID_IDispatch, lp_IDispatch))

        val this = !lp_IDispatch
      in
        wrapDispatch (COM.wrapUnknown this)
      end
    val CLSIDTransporter =
        NDT.boxed (NDT.tuple4 (NDT.word, NDT.word, NDT.word, NDT.word))
    val CLSIDBuffer = NDT.export CLSIDTransporter (0w0, 0w0, 0w0, 0w0)
  in        
  fun createInstanceOfProgID progID =
      let
        val _ =
            COM.checkHRESULT
                (W.CLSIDFromProgID
                     (OLEString.MBSToBytes progID, NDT.addressOf CLSIDBuffer))
        val CLSID = NDT.import CLSIDBuffer
      in
        create CLSID
      end

  fun createInstanceOfCLSID CLSIDString =
      let
        val _ =
            COM.checkHRESULT
                (W.CLSIDFromString
                     (
                       OLEString.MBSToBytes CLSIDString,
                       NDT.addressOf CLSIDBuffer
                     ))
        val CLSID = NDT.import CLSIDBuffer
      in
        create CLSID
      end

  end

  fun getObject name =
      let
        val lp_IDispatch = ref UM.NULL
        val nameBytes = OLEString.MBSToBytes name
        val _ =
            COM.checkHRESULT
                (W.CoGetObject (nameBytes, 0w0, W.IID_IDispatch, lp_IDispatch))

        val this = !lp_IDispatch
      in
        wrapDispatch (COM.wrapUnknown this)
      end

  (****************************************)

end;