(**
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE : OLE =
struct

  (* reference:
   *
   * Interoperability between .NET Framework and COM components.
   * http://msdn.microsoft.com/en-us/library/ms172270(VS.80).aspx
   *
   * VARIANT type.
   * http://msdn.microsoft.com/en-us/library/ms221627(VS.80).aspx
   *)

  structure Finalizable = SMLSharp.Finalizable
  structure FLOB = SMLSharp.FLOB
  structure NDT = NativeDataTransporter
  structure OLEString = UTF16LECodec.String
  structure Decimal = OLE_Decimal
  structure UM = UnmanagedMemory
  structure Int8 = Int32 (* FIXME : We should have Int8. *)
  structure Int16 = Int32
  structure Word16 = Word32

  (**********************************************************************)

  structure Win32 =
  struct

    type pointer = word
    type WORD = word
    type LONG = Int32.int
    type PVOID = word
    type LPVOID = word
    type SIZE_T = int (* ? *)

    (* basetypes.h *)
    type LPGUID = Word32.word * Word32.word * Word32.word * Word32.word
    type LPIID = LPGUID
    type REFIID = LPGUID
    type LPCLSID = LPGUID
    type REFCLSID = LPGUID

    (* winnt.h *)
    type ULONG = word
    type LPSTR = string

    (* windef.h *)
    type DWORD = word
    type UINT = Word16.word
    type HRESULT = word

    (* wtypes.h *)
    type VARTYPE = Word16.word
    type SCODE = LONG
    (* UTF16 encoded string allocated in SML# heap.
     *)
    type LPOLESTR = Word8Vector.vector
    (* BSTR allocated by SysAllocString{ByteLen} and freed by SysFreeString.
     * About BSTR, see:
     *   http://msdn2.microsoft.com/en-us/library/ms221069.aspx
     *)
    type BSTR = pointer

    type VARIANT_BOOL = Word16.word
    type LPTYPEINFO = word

    (* winnt.h *)
    type LCID = DWORD

    (* oaidl.h *)
    type DISPID = LONG
    type MEMBERID = DISPID
    (* second, third fields are reserved. *)
    type VARIANT = Word.word array
    type VARIANTARG = VARIANT

    type DISPPARAMS =
         (Word.word array * (* named args *) Word.word array * UINT * (* #of named args *) UINT)
    type EXCEPINFO =
         word Array.array
(*
         (
           WORD * (* wCode, wReserved *)
           BSTR * (* bstrSource *)
           BSTR * (* bstrDescription *)
           BSTR * (* bstrHelpFile *)
           DWORD * (* dwHelpContext *)
           PVOID * (* pvReserved *)
           word * (* pfnDeferredFillIn *)
           SCODE (* scode *)
         )
*)
    (* basetypes.h *)
    val IID_NULL = (0w0, 0w0, 0w0, 0w0) : LPIID
    val IID_IDispatch = ( 0wx20400, 0wx0, 0wxc0, 0wx46000000 ) : LPCLSID
    val IID_IEnumVARIANT = ( 0wx20404, 0wx0, 0wxc0, 0wx46000000 ) : LPCLSID
    val IID_ITypeInfo = ( 0wx20401, 0wx0, 0wxc0, 0wx46000000 ) : LPCLSID
    (*
    val IID_IDispatch = (0w0, 0w0, 0w0, 0w0) : LPCLSID
    val _ =
      IIDFromString
          (OLESTR "{00020400-0000-0000-C000-000000000046}", IID_IDispatch)
     *)

    (* winerror.h *)
    val S_OK = 0w0 : HRESULT
    val S_FALSE = 0w1 : HRESULT
    val DISP_E_EXCEPTION = 0wx80020009 : HRESULT
    val DISP_E_PARAMNOTFOUND =  0wx80020004 : HRESULT

    (* oaidl.h *)
    val SIZEOF_EXCEPINFO = 32

    (* objbase.h *)
    val COINIT_MULTITHREADED = 0wx0
    val COINIT_APARTMENTTHREADED = 0wx2
    val COINIT_DISABLE_OLE1DDE = 0wx4
    val COINIT_SPEED_OVER_MEMORY = 0wx8

    (* wtypes.h *)
    val VT_EMPTY = 0w0
    val VT_NULL = 0w1
    val VT_I2 = 0w2
    val VT_I4 = 0w3
    val VT_R4 = 0w4
    val VT_R8 = 0w5
    val VT_CY = 0w6 
    val VT_DATE = 0w7
    val VT_BSTR = 0w8
    val VT_DISPATCH = 0w9
    val VT_ERROR = 0w10
    val VT_BOOL = 0w11
    val VT_VARIANT = 0w12
    val VT_UNKNOWN = 0w13
    val VT_DECIMAL = 0w14
    val VT_I1 = 0w16
    val VT_UI1 = 0w17
    val VT_UI2 = 0w18
    val VT_UI4 = 0w19
    val VT_I8 = 0w20
    val VT_UI8 = 0w21
    val VT_INT = 0w22
    val VT_UINT = 0w23
    val VT_VOID = 0w24
    val VT_HRESULT = 0w25
    val VT_PTR = 0w26
    val VT_SAFEARRAY = 0w27
    val VT_CARRAY = 0w28
    val VT_USERDEFINED = 0w29
    val VT_LPSTR = 0w30
    val VT_LPWSTR = 0w31
    val VT_RECORD = 0w36
    val VT_INT_PTR = 0w37
    val VT_UINT_PTR = 0w38
    val VT_FILETIME = 0w64
    val VT_BLOB = 0w65
    val VT_STREAM = 0w66
    val VT_STORAGE = 0w67
    val VT_STREAMED_OBJECT = 0w68
    val VT_STORED_OBJECT = 0w69
    val VT_BLOB_OBJECT = 0w70
    val VT_CF = 0w71
    val VT_CLSID = 0w72
    val VT_BSTR_BLOB = 0wxfff
    val VT_VECTOR = 0wx1000
    val VT_ARRAY = 0wx2000
    val VT_BYREF = 0wx4000
    val VT_RESERVED = 0wx8000
    val VT_ILLEGAL = 0wxffff
    val VT_ILLEGALMASKED = 0wxfff
    val VT_TYPEMASK = 0wxfff

    val VARIANT_TRUE = 0wxffff : VARIANT_BOOL
    val VARIANT_FALSE = 0w0 : VARIANT_BOOL

    val CLSCTX_INPROC_SERVER        = 0wx1 
    val CLSCTX_INPROC_HANDLER       = 0wx2 
    val CLSCTX_LOCAL_SERVER         = 0wx4 
    val CLSCTX_INPROC_SERVER16      = 0wx8
    val CLSCTX_REMOTE_SERVER        = 0wx10
    val CLSCTX_INPROC_HANDLER16     = 0wx20
    val CLSCTX_RESERVED1            = 0wx40
    val CLSCTX_RESERVED2            = 0wx80
    val CLSCTX_RESERVED3            = 0wx100
    val CLSCTX_RESERVED4            = 0wx200
    val CLSCTX_NO_CODE_DOWNLOAD     = 0wx400
    val CLSCTX_RESERVED5            = 0wx800
    val CLSCTX_NO_CUSTOM_MARSHAL    = 0wx1000
    val CLSCTX_ENABLE_CODE_DOWNLOAD = 0wx2000
    val CLSCTX_NO_FAILURE_LOG       = 0wx4000
    val CLSCTX_DISABLE_AAA          = 0wx8000
    val CLSCTX_ENABLE_AAA           = 0wx10000
    val CLSCTX_FROM_DEFAULT_CONTEXT = 0wx20000
    val CLSCTX_ACTIVATE_32_BIT_SERVER = 0wx40000
    val CLSCTX_ACTIVATE_64_BIT_SERVER = 0wx80000

    (* winbase.h *)
    val FORMAT_MESSAGE_ALLOCATE_BUFFER = 0w256
    val FORMAT_MESSAGE_IGNORE_INSERTS = 0w512
    val FORMAT_MESSAGE_FROM_STRING = 0w1024
    val FORMAT_MESSAGE_FROM_HMODULE = 0w2048
    val FORMAT_MESSAGE_FROM_SYSTEM = 0w4096
    val FORMAT_MESSAGE_ARGUMENT_ARRAY = 0w8192
    val FORMAT_MESSAGE_MAX_WIDTH_MASK = 0w255
                                        
    (* winnls.h *)
    val LOCALE_SYSTEM_DEFAULT = 0wx800
    val LOCALE_USER_DEFAULT = 0wx400
                              
    (* winnt.h *)
    val LANGID_ENGLISH_US = 0w1033
                            
    (** the number of bytes occupied by a VARIANT *)
    val SIZEOF_VARIANT = 16
                         
    val DISPID_UNKNOWN = (~1)
    val DISPID_VALUE = (0)
    val DISPID_PROPERTYPUT = (~3)
    val DISPID_NEWENUM = (~4)
    val DISPID_EVALUATE = (~5)
    val DISPID_CONSTRUCTOR = (~6)
    val DISPID_DESTRUCTOR = (~7)
    val DISPID_COLLECT = (~8)
    val MEMBERID_NIL = DISPID_UNKNOWN
                         
    (* oleauto.h *)
    val DISPATCH_METHOD = 0w1
    val DISPATCH_PROPERTYGET = 0w2
    val DISPATCH_PROPERTYPUT = 0w4
    val DISPATCH_PROPERTYPUTREF = 0w8

    (****************************************)

    val ole32 = DynamicLink.dlopen "ole32.dll"

    val fptrCoInitializeEx = DynamicLink.dlsym (ole32, "CoInitializeEx")
    val CoInitializeEx =
        fptrCoInitializeEx : _import _stdcall (int, DWORD) -> HRESULT

    val fptrCoUninitialize = DynamicLink.dlsym (ole32, "CoUninitialize")
    val CoUninitialize =
        fptrCoUninitialize : _import _stdcall () -> unit

    val fptrOleInitialize = DynamicLink.dlsym (ole32, "OleInitialize")
    val OleInitialize =
        fptrOleInitialize : _import _stdcall (int) -> HRESULT

    val fptrCLSIDFromProgID = DynamicLink.dlsym (ole32, "CLSIDFromProgID")
    val CLSIDFromProgID =
        fptrCLSIDFromProgID
            : _import _stdcall (LPOLESTR, UM.address) -> HRESULT

    val fptrCLSIDFromString = DynamicLink.dlsym (ole32, "CLSIDFromString")
    val CLSIDFromString =
        fptrCLSIDFromString
            : _import _stdcall (LPOLESTR, UM.address) -> HRESULT

    val fptrCoCreateInstance = DynamicLink.dlsym (ole32, "CoCreateInstance")
    val CoCreateInstance =
        fptrCoCreateInstance
        : _import _stdcall
                  (REFCLSID, word, DWORD, REFIID, UM.address ref) -> HRESULT

    val fptrCoGetObject = DynamicLink.dlsym (ole32, "CoGetObject")
    val CoGetObject =
        fptrCoGetObject
        : _import _stdcall
                  (Word8Vector.vector, DWORD, REFIID, UM.address ref) -> HRESULT

    val fptrCoTaskMemAlloc = DynamicLink.dlsym (ole32, "CoTaskMemAlloc")
    val CoTaskMemAlloc =
        fptrCoTaskMemAlloc
        : _import _stdcall (SIZE_T) -> LPVOID

    val fptrCoTaskMemFree = DynamicLink.dlsym (ole32, "CoTaskMemFree")
    val CoTaskMemFree = fptrCoTaskMemFree : _import _stdcall (LPVOID) -> unit

    (**********)

    val oleaut32 = DynamicLink.dlopen "oleaut32.dll"

    val fptrSafeArrayCreate = DynamicLink.dlsym (oleaut32, "SafeArrayCreate")
    val SafeArrayCreate =
        fptrSafeArrayCreate
        : _import _stdcall (VARTYPE, UINT, UM.address) -> UM.address

    val fptrSafeArrayGetVartype =
        DynamicLink.dlsym (oleaut32, "SafeArrayGetVartype")
    val SafeArrayGetVartype =
        fptrSafeArrayGetVartype
        : _import _stdcall (UM.address, VARTYPE ref) -> HRESULT

    val fptrSafeArrayGetLBound =
        DynamicLink.dlsym (oleaut32, "SafeArrayGetLBound")
    val SafeArrayGetLBound =
        fptrSafeArrayGetLBound
        : _import _stdcall (UM.address, UINT, LONG ref) -> HRESULT

    val fptrSafeArrayGetUBound =
        DynamicLink.dlsym (oleaut32, "SafeArrayGetUBound")
    val SafeArrayGetUBound =
        fptrSafeArrayGetUBound
        : _import _stdcall (UM.address, UINT, LONG ref) -> HRESULT

    val fptrSafeArrayGetDim = DynamicLink.dlsym (oleaut32, "SafeArrayGetDim")
    val SafeArrayGetDim =
        fptrSafeArrayGetDim : _import _stdcall (UM.address) -> UINT

    val fptrSafeArrayGetElemsize =
        DynamicLink.dlsym (oleaut32, "SafeArrayGetElemsize")
    val SafeArrayGetElemsize =
        fptrSafeArrayGetElemsize : _import _stdcall (UM.address) -> UINT

    val fptrSafeArrayAccessData =
        DynamicLink.dlsym (oleaut32, "SafeArrayAccessData")
    val SafeArrayAccessData =
        fptrSafeArrayAccessData
        : _import _stdcall (UM.address, UM.address ref) -> HRESULT

    val fptrSafeArrayUnaccessData =
        DynamicLink.dlsym (oleaut32, "SafeArrayUnaccessData")
    val SafeArrayUnaccessData =
        fptrSafeArrayUnaccessData : _import _stdcall (UM.address) -> HRESULT

    (**********)

    val kernel32 = DynamicLink.dlopen "kernel32.dll"

    val fptrlstrcatA = DynamicLink.dlsym (kernel32, "lstrcatA")
    val lstrcatA = fptrlstrcatA : _import _stdcall (string, string) -> word

    val fptrlstrlenA = DynamicLink.dlsym (kernel32, "lstrlenA")
    val lstrlenA = fptrlstrlenA : _import _stdcall (LPSTR) -> word

    val fptrlstrlenW = DynamicLink.dlsym (kernel32, "lstrlenW")
    val lstrlenW = fptrlstrlenA : _import _stdcall (word) -> int

    val fptrFormatMessageW = DynamicLink.dlsym (kernel32, "FormatMessageW")
    val FormatMessageW =
        fptrFormatMessageW
        : _import _stdcall
                    (DWORD, word, DWORD, DWORD, word ref, DWORD, word) -> DWORD

    val fptrLocalFree = DynamicLink.dlsym (kernel32, "LocalFree")
    val LocalFree = fptrLocalFree : _import _stdcall (word) -> word

    (**********)

    val oleaut32 = DynamicLink.dlopen "oleaut32.dll";

    val fptrSysAllocString = DynamicLink.dlsym (oleaut32, "SysAllocString")
    val SysAllocString =
        fptrSysAllocString : _import _stdcall (LPOLESTR) -> BSTR

    val fptrSysAllocStringByteLen =
        DynamicLink.dlsym (oleaut32, "SysAllocStringByteLen")
    val SysAllocStringByteLen =
        fptrSysAllocStringByteLen
        : _import _stdcall (LPOLESTR, (* numbytes *) word) -> BSTR

    val fptrSysFreeString = DynamicLink.dlsym (oleaut32, "SysFreeString")
    val SysFreeString = fptrSysFreeString : _import _stdcall (BSTR) -> unit

    (* returns the number of bytes, NOT including null-terminator *)
    val fptrSysStringByteLen = DynamicLink.dlsym (oleaut32, "SysStringByteLen")
    val SysStringByteLen =
        fptrSysStringByteLen : _import _stdcall (BSTR) -> UINT

  end

  (**********************************************************************)

  structure W = Win32

  (****************************************)

  type string = UTF16LECodec.String.string

  type decimal = Decimal.decimal

  datatype coinit =
           COINIT_MULTITHREADED
         | COINIT_APARTMENTTHREADED
         | COINIT_DISABLE_OLE1DDE
         | COINIT_SPEED_OVER_MEMORY

  type Unknown =
       {
         addRef : unit -> W.ULONG,
         release : unit -> W.ULONG,
         queryInterface : W.LPGUID -> UM.address,
         this : UM.address Finalizable.finalizable
       }

  type TypeInfo =
       {
         addRef : unit -> W.ULONG,
         release : unit -> W.ULONG,
         getDocumentation
         : unit -> (** name *) string * (** description *) string,
         this : UM.address Finalizable.finalizable
       }

  datatype variant =
           EMPTY
         | NULL
         | I2 of Int32.int
         | I4 of Int32.int
         | R4 of Real32.real
         | R8 of Real64.real
         | BSTR of string
         | DISPATCH of Dispatch
         | ERROR of Int32.int
         | BOOL of bool
         | VARIANT of variant
         | UNKNOWN of Unknown
         | DECIMAL of decimal
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
         | VARIANTARRAY of variant array * word list

  withtype Dispatch =
           {
             addRef : unit -> W.ULONG,
             release : unit -> W.ULONG,
             invoke : string -> variant list -> variant option,
             invokeByDISPID : W.DISPID -> variant list -> variant option,
             get : string -> variant list -> variant,
             getByDISPID : W.DISPID -> variant list -> variant,
             set : string -> variant list -> variant -> unit,
             setByDISPID : W.DISPID -> variant list -> variant -> unit,
             setRef : string -> variant list -> variant -> unit,
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

  datatype error = 
           ComSystemError of String.string
         | ComApplicationError
           of {
                code : word,
                source : String.string,
                description : String.string,
                helpfile : String.string,
                helpcontext : word
              }
         | NullObjectPointer
         | TypeMismatch of String.string
         | ResultMismatch of String.string
         | Conversion of String.string

  exception OLEError of error

  (****************************************)
  (* datatype conversion *)

  val int32ToWord32 = Word32.fromLargeInt o Int32.toLarge
  val word32ToInt32 = Int32.fromLarge o Word32.toLargeInt
  val word32ToInt32X = Int32.fromLarge o Word32.toLargeIntX

  val word32ToIntInf = IntInf.fromLarge o Word32.toLargeInt
  val word32ToIntInfX = IntInf.fromLarge o Word32.toLargeIntX

  local
    val MaxInt8 = 0x7F : Int8.int
    val MinInt8 = ~0x80 : Int8.int
  in
  fun int8ToWord32 (int8 : Int8.int) =
      if (MaxInt8 < int8) orelse (int8 < MinInt8)
      then raise OLEError (Conversion "cannot convert Int8 to Word32.")
      else Word32.andb (0wxFF, int32ToWord32 int8)
  fun word32ToInt8 word32 =
      if Word32.andb (word32, 0wx80) = 0w0
      then word32ToInt32 word32
      else word32ToInt32X (Word32.orb (0wxFFFFFF00, word32)) : Int8.int
  end

  local
    val MaxInt16 = 0x7FFF : Int16.int
    val MinInt16 = ~0x8000 : Int16.int
  in
  fun int16ToWord32 (int16 : Int16.int) =
      if (MaxInt16 < int16) orelse (int16 < MinInt16)
      then raise OLEError (Conversion "cannot convert Int16 to Word32.")
      else Word32.andb (0wxFFFF, int32ToWord32 int16)
  fun word32ToInt16 word32 =
      if Word32.andb (word32, 0wx8000) = 0w0
      then word32ToInt32 word32
      else word32ToInt32X (Word32.orb (0wxFFFF0000, word32)) : Int16.int
  end

  local
    val MaxWord16 = 0wxFFFF : Word32.word
  in
  fun word16ToWord32 (word16 : Word16.word) =
      if (MaxWord16 < word16)
      then
        raise
          OLEError
              (Conversion
                   ("can't convert Word16(" ^ Word16.toString word16 ^ ")"))
      else word16
  fun word32ToWord16 word32 = Word32.andb (0wxFFFF, word32) : Word16.word
  end

  local
    val MaxInt64 = 0x7FFFFFFFFFFFFFFF : IntInf.int
(* FIXME: 
   see http://www.pllab.riec.tohoku.ac.jp/hiki/smlsharp-dev/?Ticket-7
    val MinInt64 = ~0x8000000000000000 : IntInf.int
*)
    val MinInt64 = ~1 * 0x8000000000000000 : IntInf.int
  in
  fun wordsToInt64 (word1, word2) =
      let
        val higher = 
            if Word32.andb (word2, 0wx80000000) = 0w0
            then word32ToIntInf word2
            else word32ToIntInfX word2
        val lower = word32ToIntInf word1
      in
        IntInf.orb(IntInf.<< (higher, 0w32), lower)
      end
  fun int64ToWords int64 =
      if (int64 < MinInt64) orelse (MaxInt64 < int64)
      then
        raise
          OLEError
            (Conversion("can't convert Int64(" ^ IntInf.toString int64 ^ ")"))
      else
        (
          Word32.fromLargeInt (IntInf.andb (0xFFFFFFFF, int64)),
          Word32.fromLargeInt (IntInf.~>> (int64, 0w32))
        )
  end

  local
    val MaxWord64 = 0xFFFFFFFFFFFFFFFF : IntInf.int
    val MinWord64 = 0 : IntInf.int
  in
  fun wordsToWord64 (word1, word2) =
      let
        val higher = word32ToIntInf word2
        val lower = word32ToIntInf word1
      in
        IntInf.orb(IntInf.<< (higher, 0w32), lower)
      end
  fun word64ToWords word64 =
      if (word64 < MinWord64) orelse (MaxWord64 < word64)
      then
        raise
          OLEError
            (Conversion("can't convert Word64(" ^ IntInf.toString word64 ^ ")"))
      else
        (
          Word32.fromLargeInt (IntInf.andb (0xFFFFFFFF, word64)),
          Word32.fromLargeInt (IntInf.~>> (word64, 0w32))
        )
  end

  fun real32ToWord real32 =
      let
        val vec = PackReal32Little.toBytes real32
        val word = PackWord32Little.subVec (vec, 0)
      in word
      end

  fun wordToReal32 word =
      let
        val array = Word8Array.array (4, 0w0)
        val _ = PackWord32Little.update (array, 0, word)
      in PackReal32Little.subArr(array, 0)
      end

  fun real64ToWords real64 =
      let
        val vec = PackReal64Little.toBytes real64
        val word1 = PackWord32Little.subVec (vec, 0)
        val word2 = PackWord32Little.subVec (vec, 4)
      in (word1, word2)
      end

  fun wordsToReal64 (word1, word2) =
      let
        val array = Word8Array.array (8, 0w0)
        val _ = PackWord32Little.update (array, 0, word1)
        val _ = PackWord32Little.update (array, 4, word2)
      in PackReal64Little.subArr(array, 0)
      end

  (****************************************)
  (* OLE specific utility functions *)

  fun UMSubWord word = UM.subWord (UM.wordToAddress word)
  fun UMImport (bstr, bytelen) = UM.import (UM.wordToAddress bstr, bytelen)

  fun formatMessage hresult =
      let
        val bufferRef = ref 0w0
        val flag =
            Word.orb
              (W.FORMAT_MESSAGE_FROM_SYSTEM, W.FORMAT_MESSAGE_ALLOCATE_BUFFER)
        val numchars = 
            W.FormatMessageW
                (flag, 0w0, hresult, W.LANGID_ENGLISH_US, bufferRef, 0w0, 0w0)
      in
        if numchars = 0w0
        then OLEString.fromAsciiString "cannot format message"
        else
          let
            val bytes =
                UM.import
                    (UM.wordToAddress(!bufferRef), Word.toInt numchars * 2)
            val _ = W.LocalFree (!bufferRef)
          in
            OLEString.bytesToMBS bytes
          end
      end

  fun checkHRESULT hresult =
      if 0 <= Word32.toIntX hresult
      then ()
      else
        raise
          OLEError
              (ComSystemError(OLEString.toAsciiString (formatMessage hresult)))

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

  (****************************************)

  fun initialize coinits =
      let
        fun coinitOf COINIT_MULTITHREADED = W.COINIT_MULTITHREADED
          | coinitOf COINIT_APARTMENTTHREADED = W.COINIT_APARTMENTTHREADED
          | coinitOf COINIT_DISABLE_OLE1DDE = W.COINIT_DISABLE_OLE1DDE
          | coinitOf COINIT_SPEED_OVER_MEMORY = W.COINIT_SPEED_OVER_MEMORY
        val flag = List.foldl Word.orb 0w0 (map coinitOf coinits)
      in
        checkHRESULT (W.CoInitializeEx (0, flag))
      end

  val uninitialize = W.CoUninitialize

  (****************************************)
  (* IUnknown *)

  val NullUnknown =
       {
         addRef = fn () => raise OLEError NullObjectPointer,
         release = fn () => raise OLEError NullObjectPointer,
         queryInterface = fn _ => raise OLEError NullObjectPointer,
         this = Finalizable.new (UM.NULL, fn _ => ())
       } : Unknown

  fun isNullUnknown ({this, ...} : Unknown) =
      UM.isNULL (Finalizable.getValue this)

  fun wrapUnknown ptrUnknown =
      let
        type this = UM.address

        val _ = if UM.isNULL ptrUnknown
                then raise OLEError NullObjectPointer
                else ()

        val vptr = UM.subWord ptrUnknown

        val fptrQueryInterface = UM.wordToAddress (UMSubWord vptr)
        val IUnknown_QueryInterface =
            fptrQueryInterface
            : _import _stdcall (this, W.REFIID, UM.address ref) -> W.HRESULT

        val fptrAddRef = UM.wordToAddress (UMSubWord (vptr + 0w4))
        val IUnknown_AddRef =
            fptrAddRef : _import _stdcall (this) -> W.ULONG

        val fptrRelease = UM.wordToAddress (UMSubWord (vptr + 0w8))
        val IUnknown_Release =
            fptrRelease : _import _stdcall (this) -> W.ULONG

        val this =
            Finalizable.new (ptrUnknown, fn t => (IUnknown_Release t; ()))

        fun queryInterface IID =
            let
              val resultRef = ref UM.NULL
              val hresult = IUnknown_QueryInterface(ptrUnknown, IID, resultRef)
            in
              checkHRESULT hresult;
              !resultRef
            end

      in
        {
          addRef = fn () => IUnknown_AddRef (Finalizable.getValue this),
          release = fn () => IUnknown_Release (Finalizable.getValue this),
          queryInterface = queryInterface,
          this = this
        } : Unknown
      end

  (****************************************)
  (* IDispatch *)

  val WordsOfVariant = W.SIZEOF_VARIANT div (Word.wordSize div 8)
  val BytesOfWord = Word.wordSize div 8
  val productOfWords = List.foldl (op * ) 0w1

  val NullDispatch =
      {
        addRef = fn () => raise OLEError NullObjectPointer,
        release = fn () => raise OLEError NullObjectPointer,
        invoke = fn _ => fn _ => raise OLEError NullObjectPointer,
        invokeByDISPID = fn _ => fn _ => raise OLEError NullObjectPointer,
        get = fn _ => fn _ => raise OLEError NullObjectPointer,
        getByDISPID = fn _ => fn _ => raise OLEError NullObjectPointer,
        set = fn _ => fn _ => fn _ => raise OLEError NullObjectPointer,
        setByDISPID = fn _ => fn _ => fn _ => raise OLEError NullObjectPointer,
        setRef = fn _ => fn _ => fn _ => raise OLEError NullObjectPointer,
        setRefByDISPID =
        fn _ => fn _ => fn _ => raise OLEError NullObjectPointer,
        getTypeInfo = fn _ => raise OLEError NullObjectPointer,
        this = Finalizable.new (UM.NULL, fn _ => ())
      } : Dispatch

  fun isNullDispatch ({this, ...} : Dispatch) =
      UM.isNULL (Finalizable.getValue this)

  (**********)
  (* serialize and deserialize SAFEARRAY. *)

  (*
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
        val array = Array.array (2 * List.length lengths, 0w0)
        val _ =
            List.foldl
                (fn (len, offset) =>
                    (Array.update (array, offset, len); offset + 2))
                0
                lengths
      in
        array
      end

  fun arrayToSAFEARRAY (elementSerializer, elementVTtag) (array, lengths) =
      let
        val finishers = ref ([] : (unit -> unit) list)
        fun addFinisher finisher = finishers := finisher :: (!finishers)

        (* setup SAFEARRAYBOUND[] *)
        val arrayLen = Array.length array
        val _ =
            if arrayLen <> Word.toInt(productOfWords lengths)
            then raise Fail "incorrect lengths in VARIANTARRAY."
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
(*
        val elemSize = W.SafeArrayGetElemsize safearray
        val _ = if (Word.toInt elemSize div BytesOfWord) <> WordsOfVariant
                then raise Fail ("BUG: elemeSize = " ^ Word.toString elemSize)
                else ()
*)

        (* write values into SAFEARRAY. *)
        val refData = ref UM.NULL
        val _ = checkHRESULT(W.SafeArrayAccessData(safearray, refData))
        fun update (wordOffset, value) =
            UM.updateWord
                (UM.advance(!refData, BytesOfWord * wordOffset), value)
        val _ = Array.foldl (elementSerializer addFinisher update) 0 array

        (* clean up *)
        val _ = checkHRESULT(W.SafeArrayUnaccessData(safearray))
        fun finisher () = List.app (fn f => f ()) (!finishers)
      in
        (safearray, finisher)
      end

  (**
   * converts a SAFEARRAY of multiple dimensions to a single dimension array.
   *)
  fun SAFEARRAYToArray (elementDeserializer, constructor) safeArray =
      let
        val vtref = ref (0w0 : W.VARTYPE)
        val _ = checkHRESULT(W.SafeArrayGetVartype(safeArray, vtref))
        val vt = !vtref
        val _ =
            if vt <> W.VT_VARIANT
            then
              raise
                OLEError
                    (TypeMismatch
                         ("array of unsupported VT 0wx" ^ Word.toString vt))
            else ()

        val dim = W.SafeArrayGetDim(safeArray)
        fun getLengths level dims =
            if dim < level
            then List.rev dims
            else
              let
                val lboundRef = ref 0
                val _ =
                    checkHRESULT
                        (W.SafeArrayGetLBound(safeArray, level, lboundRef))
                val uboundRef = ref 0
                val _ =
                    checkHRESULT
                        (W.SafeArrayGetUBound (safeArray, level, uboundRef))
              in
                getLengths
                    (level + 0w1)
                    (Word.fromInt (!uboundRef - !lboundRef + 1) :: dims)
              end
        val lengths = getLengths 0w1 []
        val elements = Word.toInt(productOfWords lengths)

        val elemSize = Word.toInt(W.SafeArrayGetElemsize safeArray)
        val _ =
            if (elemSize div BytesOfWord) <> WordsOfVariant
            then raise Fail ("BUG: elemeSize = " ^ Int.toString elemSize)
            else ()

        val BytesOfSafeArray = elements * WordsOfVariant * BytesOfWord

        val refData = ref UM.NULL
        val _ = checkHRESULT (W.SafeArrayAccessData(safeArray, refData))

        fun deserialize 0 address vs = Array.fromList (List.rev vs)
          | deserialize n address vs =
            let
              val tag = UM.subWord address
              val word1 = UM.subWord (UM.advance(address, 2 * BytesOfWord))
              val word2 = UM.subWord (UM.advance(address, 3 * BytesOfWord))
              val v = elementDeserializer (tag, word1, word2)
            in
              deserialize (n - 1) (UM.advance(address, elemSize)) (v :: vs)
            end
        val array = deserialize elements (!refData) []
      in
        checkHRESULT(W.SafeArrayUnaccessData(safeArray));
        constructor(array, lengths)
      end

  (**********)
  (* serializing Variant. *)

  fun emptyVariant () =
      let val resultBuffer = Array.array (WordsOfVariant, 0w0)
      in resultBuffer
      end

  fun VariantArrayToSAFEARRAY (array, lengths) =
      arrayToSAFEARRAY (serializeVariant, W.VT_VARIANT) (array, lengths)

  and decompVariant addFinisher variant =
      case variant of
        EMPTY => (W.VT_EMPTY, 0w0, 0w0)
      | NULL => (W.VT_NULL, 0w0, 0w0)
      | I2 int => (W.VT_I2, (int16ToWord32 int), 0w0)
      | I4 int => (W.VT_I4, (int32ToWord32 int), 0w0)
      | R4 real32 =>
        let val word = real32ToWord real32
        in (W.VT_R4, word, 0w0)
        end
      | R8 real64 =>
        let val (word1, word2) = real64ToWords real64
        in (W.VT_R8, word1, word2)
        end
      | BSTR olestr =>
        let val bstr = OLESTRToBSTR olestr
        in addFinisher (fn () => W.SysFreeString bstr); (W.VT_BSTR, bstr, 0w0)
        end
      | DISPATCH {this, ...} =>
        (W.VT_DISPATCH, UM.addressToWord(Finalizable.getValue this), 0w0)
      | ERROR scode => (W.VT_ERROR, int32ToWord32 scode, 0w0)
      | BOOL bool => 
        (W.VT_BOOL, if bool then W.VARIANT_TRUE else W.VARIANT_FALSE, 0w0)
      | VARIANT v => raise OLEError(TypeMismatch "unexpected VARIANT.")
      | UNKNOWN {this, ...} =>
        (W.VT_UNKNOWN, UM.addressToWord(Finalizable.getValue this), 0w0)
      | DECIMAL decimal =>
        let
          val address = W.CoTaskMemAlloc Decimal.SIZE_OF_DECIMAL
          val _ = Decimal.export decimal (UM.wordToAddress address)
                  handle General.Overflow =>
                         raise OLEError (Conversion "decimal")
          val _ = addFinisher (fn _ => W.CoTaskMemFree address)
        in
          (Word.orb (W.VT_BYREF, W.VT_DECIMAL), address, 0w0)
        end
      | I1 int => (W.VT_I1, int8ToWord32 int, 0w0)
      | UI1 byte => (W.VT_UI1, Word8.toLargeWord byte, 0w0)
      | UI2 word => (W.VT_UI2, word16ToWord32 word, 0w0)
      | UI4 word => (W.VT_UI4, word, 0w0)
      | I8 int64 =>
        let val (word1, word2) = int64ToWords int64
        in (W.VT_I8, word1, word2)
        end
      | UI8 word64 =>
        let val (word1, word2) = word64ToWords word64
        in (W.VT_UI8, word1, word2)
        end
      | INT int => (W.VT_INT, int32ToWord32 int, 0w0)
      | UINT word => (W.VT_UINT, word, 0w0)
      | BYREF(VARIANT v) =>
        let
          val (array, finisher) = variantsToArray [v]
          val FLOB = FLOB.fixedCopy array
          val FLOBaddress = UM.addressToWord(FLOB.addressOf FLOB)
          val _ = addFinisher finisher
          (* ToDo : Is it safe to release memory by client ? *)
          val _ = addFinisher (fn _ => FLOB.release FLOB)
        in
          (Word.orb (W.VT_BYREF, W.VT_VARIANT), FLOBaddress, 0w0)
        end
      | BYREF(v) =>
        let
          val (tag, word1, word2) = decompVariant addFinisher v
          val array = Array.fromList [word1, word2]
          val FLOB = FLOB.fixedCopy array
          val FLOBaddress = UM.addressToWord(FLOB.addressOf FLOB)
          val _ = addFinisher (fn _ => FLOB.release FLOB)
        in
          (Word.orb (W.VT_BYREF, tag), FLOBaddress, 0w0)
        end
      | BYREFOUT(r as ref(VARIANT v)) =>
        let
          val (array, finisher) = variantsToArray [v]
          val FLOB = FLOB.fixedCopy array
          val FLOBaddress = UM.addressToWord(FLOB.addressOf FLOB)
          val _ = addFinisher finisher
          val _ =
              addFinisher
                  (fn _ =>
                      (
                        case FLOB.app arrayToVariants FLOB
                         of [v'] => r := VARIANT v'
                          | _ => () (* error? *);
                        FLOB.release FLOB
                      ))
        in
          (Word.orb (W.VT_BYREF, W.VT_VARIANT), FLOBaddress, 0w0)
        end
      | BYREFOUT(r as ref(v)) =>
        let
          val (tag, word1, word2) = decompVariant addFinisher v
          val array = Array.fromList [word1, word2]
          val FLOB = FLOB.fixedCopy array
          val FLOBaddress = UM.addressToWord(FLOB.addressOf FLOB)
          val _ =
              addFinisher
                  (fn _ =>
                      let
                        val word1 = FLOB.app (fn a => Array.sub (a, 0)) FLOB
                        val word2 = FLOB.app (fn a => Array.sub (a, 1)) FLOB
                      in
                        r := constructVariant (tag, word1, word2);
                        FLOB.release FLOB
                      end)
        in
          (Word.orb (W.VT_BYREF, tag), FLOBaddress, 0w0)
        end
      | VARIANTARRAY (array, lengths) =>
        let
          val (safearray, finisher) = VariantArrayToSAFEARRAY (array, lengths)
          val _ = addFinisher finisher
          (* safearray will be released by callee. (exactly?) *)
        in
          (Word.orb(W.VT_ARRAY, W.VT_VARIANT), UM.addressToWord safearray, 0w0)
        end
                           
  and serializeVariant addFinisher update (variant, offset) =
      let
        val (tag, word1, word2) = decompVariant addFinisher variant
        val _ = update (offset, tag)
        val _ = update (offset + 2, word1)
        val _ = update (offset + 3, word2)
      in
        offset + 4
      end

  and variantsToArray variants =
      let
        val numWords = length variants * WordsOfVariant
        val array : Word.word Array.array = Array.array (numWords, 0w0)
        val finishers = ref ([] : (unit -> unit) list)
        fun addFinisher finisher = finishers := finisher :: (!finishers);
        fun update (offset, value) = Array.update (array, offset, value)
      in
        List.foldl (serializeVariant addFinisher update) 0 variants;
        (array, fn () => List.app (fn f => f ()) (!finishers))
      end

  (**********)
  (* deserializing Variant. *)

  and SAFEARRAYToVariantArray safeArray =
      SAFEARRAYToArray (constructVariant, VARIANTARRAY) safeArray

  and constructVariant (tag, word1, word2) =
      if tag = W.VT_EMPTY
      then EMPTY
      else
      if tag = W.VT_NULL
      then NULL
      else
      if tag = W.VT_I2
      then I2 (word32ToInt16 word1)
      else
      if tag = W.VT_I4
      then I4 (word32ToInt32X word1)
      else
      if tag = W.VT_R4
      then R4 (wordToReal32 word1)
      else
      if tag = W.VT_R8
      then R8 (wordsToReal64 (word1, word2))
      else
      if tag = W.VT_BSTR
      then BSTR (BSTRToOLESTR word1) before W.SysFreeString word1
      else
      if tag = W.VT_DISPATCH
      then
        if 0w0 <> word1
        then DISPATCH (wrapDispatch (wrapUnknown (UM.wordToAddress word1)))
        else DISPATCH NullDispatch
      else
      if tag = W.VT_ERROR
      then ERROR (word32ToInt32 word1)
      else
      if tag = W.VT_BOOL
      then BOOL (not (word1 = W.VARIANT_FALSE))
      else
      if tag = W.VT_UNKNOWN
      then
         if 0w0 <> word1
         then UNKNOWN (wrapUnknown (UM.wordToAddress word1))
         else UNKNOWN NullUnknown
      else
      if tag = Word.orb(W.VT_BYREF, W.VT_DECIMAL)
      then
        (* FIXME: the buffer should be freed ? *)
        DECIMAL (Decimal.import (UM.wordToAddress word1))
        before W.CoTaskMemFree word1
      else
      if tag = W.VT_I1
      then I1 (word32ToInt8 word1)
      else
      if tag = W.VT_UI1
      then UI1 (Word8.fromLargeWord word1)
      else
      if tag = W.VT_UI2
      then UI2 (word32ToWord16 word1)
      else
      if tag = W.VT_UI4
      then UI4 word1
      else
      if tag = W.VT_I8
      then I8 (wordsToInt64 (word1, word2))
      else
      if tag = W.VT_UI8
      then UI8 (wordsToWord64 (word1, word2))
      else
      if tag = W.VT_INT
      then INT (word32ToInt32 word1)
      else
      if tag = W.VT_UINT
      then UINT word1
      else
      if tag = Word.orb(W.VT_ARRAY, W.VT_VARIANT)
      then SAFEARRAYToVariantArray (UM.wordToAddress word1)
      else
        raise
          OLEError
              (TypeMismatch ("unsupported VARIANT type:" ^ Word.toString tag))

  and arrayToVariants array =
      let
        fun sub offset = Array.sub (array, offset)
        fun deserialize (offset, variants) =
            if offset = Array.length array
            then List.rev variants
            else
              let
                val tag = Word32.andb(sub offset, 0wxFFFF)
(*
                val _ = print ("tag = " ^ Word.toString tag ^ "\n")
*)
                val variant = 
                    if tag = W.VT_DECIMAL
                    then DECIMAL (Decimal.importWordArray (array, offset))
                    else
                      let
                        val word1 = sub (offset + 2)
                        val word2 = sub (offset + 3)
                      in constructVariant (tag, word1, word2) end
              in
                deserialize (offset + 4, variant :: variants)
              end
      in
        deserialize (0, [])
      end

  (**********)

  and wrapDispatch (Unknown : Unknown) =
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
                  checkHRESULT
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
              val flag = 
                  if dispatch_flag = W.DISPATCH_PROPERTYPUT
                  then Word.orb (W.DISPATCH_PROPERTYPUT, W.DISPATCH_METHOD)
                  else if dispatch_flag = W.DISPATCH_PROPERTYPUTREF
                  then Word.orb (W.DISPATCH_PROPERTYPUTREF, W.DISPATCH_METHOD)
                  else dispatch_flag
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
                        flag,
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
(*
                  val code = #1 excepinfo
                  val source = #2 excepinfo
                  val description = #3 excepinfo
                  val helpfile = #4 excepinfo
                  val helpcontext = #5 excepinfo
*)
                  val code = Array.sub(excepinfo, 0)
                  val source = Array.sub(excepinfo, 1)
                  val description = Array.sub(excepinfo, 2)
                  val helpfile = Array.sub(excepinfo, 3)
                  val helpcontext = Array.sub(excepinfo, 4)
                  val exn = 
                      ComApplicationError
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
                  raise OLEError exn
                end
              else
                checkHRESULT hresult;
                case arrayToVariants resultBuffer
                 of [] => NONE
                  | [result] => SOME result
                  | _ =>
                    raise
                      OLEError
                          (ResultMismatch
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
                  checkHRESULT
                      (IDispatch_GetTypeInfo
                           (
                             Finalizable.getValue this,
                             0w0,
                             W.LOCALE_USER_DEFAULT,
                             TYPEINFORef
                           ))
            in
              wrapTypeInfo(wrapUnknown(UM.wordToAddress(! TYPEINFORef)))
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

  and wrapTypeInfo (Unknown : Unknown) =
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
              val _ = checkHRESULT
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

  fun wrapEnumVARIANT (Unknown : Unknown) =
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
                  (this, W.ULONG, Word.word array, W.ULONG ref) -> W.HRESULT

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
              val (resultsBuffer, cleanArgs) =
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
              cleanArgs ();
              checkHRESULT hresult;
              List.take (arrayToVariants resultsBuffer, Word.toInt(!got))
            end

        fun skip count =
            let
              val hresult = 
                  IEnumVARIANT_Skip
                      (Finalizable.getValue this, Word.fromInt count)
            in
              checkHRESULT hresult;
              ()
            end

        fun reset count =
            let val hresult = IEnumVARIANT_Reset (Finalizable.getValue this)
            in checkHRESULT hresult; ()
            end

        fun clone () =
            let
              val resultRef = ref UM.NULL
              val hresult =
                  IEnumVARIANT_Clone (Finalizable.getValue this, resultRef)
            in
              checkHRESULT hresult; !resultRef
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

  local
    fun create CLSID =
      let
        val lp_IDispatch = ref UM.NULL
        val ctxFlag = Word.orb (W.CLSCTX_INPROC_SERVER, W.CLSCTX_LOCAL_SERVER)
        val _ =
            checkHRESULT
                (W.CoCreateInstance
                     (CLSID, 0w0, ctxFlag, W.IID_IDispatch, lp_IDispatch))

        val this = !lp_IDispatch
      in
        wrapDispatch (wrapUnknown this)
      end
    val CLSIDTransporter =
        NDT.boxed (NDT.tuple4 (NDT.word, NDT.word, NDT.word, NDT.word))
    val CLSIDBuffer = NDT.export CLSIDTransporter (0w0, 0w0, 0w0, 0w0)
  in        
  fun createInstanceOfProgID progID =
      let
        val _ =
            checkHRESULT
                (W.CLSIDFromProgID
                     (OLEString.MBSToBytes progID, NDT.addressOf CLSIDBuffer))
        val CLSID = NDT.import CLSIDBuffer
      in
        create CLSID
      end

  fun createInstanceOfCLSID CLSIDString =
      let
        val _ =
            checkHRESULT
                (W.CLSIDFromString
                     (OLEString.MBSToBytes CLSIDString, NDT.addressOf CLSIDBuffer))
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
            checkHRESULT
                (W.CoGetObject (nameBytes, 0w0, W.IID_IDispatch, lp_IDispatch))

        val this = !lp_IDispatch
      in
        wrapDispatch (wrapUnknown this)
      end

  (* for user convenience *)

  val NOPARAM = ERROR(word32ToInt32X W.DISP_E_PARAMNOTFOUND)
  val L = OLEString.fromAsciiString
  val A = OLEString.toAsciiString

  fun fold_enum f initial (object : Dispatch) =
      let
        val enumUnknown =
            case #get object (L "_NewEnum") []
             of UNKNOWN unknown => unknown
              | _ =>
                raise OLEError(TypeMismatch "_NewEnum returns not IUnknown.")
        val enum = wrapEnumVARIANT enumUnknown
        fun loop accum =
            case #next enum 1
             of [] => accum
              | [v] => loop (f (v, accum))
              | _ =>
                raise
                  OLEError
                      (ResultMismatch
                           "next method returns more than one values.")
      in
        loop initial
      end
  fun for_each f object = fold_enum (fn (v, ()) => f v) () object
  fun enumAll (object : Dispatch) = List.rev(fold_enum (op ::) [] object)

  (**********************************************************************)

end; (* structure OLE *)
