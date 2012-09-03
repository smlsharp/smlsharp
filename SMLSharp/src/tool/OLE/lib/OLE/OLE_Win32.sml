(**
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_Win32 =
struct

  structure UM = UnmanagedMemory
  structure Word16 = Word32

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
  type VARIANT = Word8Array.array
  type VARIANTARG = VARIANT

  type DISPPARAMS =
       (Word8Array.array * (* named args *) Word.word array * UINT * (* #of named args *) UINT)
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
                          
  (** the number of bytes occupied by a Variants *)
  val SIZEOF_I2 = 2
  val SIZEOF_I4 = 4
  val SIZEOF_R4 = 4
  val SIZEOF_R8 = 8
  val SIZEOF_BSTR = 4 (* size of pointer *)
  val SIZEOF_DISPATCH = 4 (* size of pointer *)
  val SIZEOF_ERROR = 4 (* sizeof(SCODE) *)
  val SIZEOF_BOOL = 2 (* sizeof(VARIANT_BOOL) *)
  val SIZEOF_VARIANT = 16
  val SIZEOF_UNKNOWN = 4 (* size of pointer *)
  val SIZEOF_DECIMAL = 16
  val SIZEOF_I1 = 1
  val SIZEOF_UI1 = 1
  val SIZEOF_UI2 = 2
  val SIZEOF_UI4 = 4
  val SIZEOF_I8 = 8
  val SIZEOF_UI8 = 8
  val SIZEOF_INT = 4
  val SIZEOF_UINT = 4
                       
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

