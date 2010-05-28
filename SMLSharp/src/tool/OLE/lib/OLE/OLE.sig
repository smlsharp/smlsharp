(**
 * The OLE structure provides access to Microsoft OLE automation.
 * It wraps IDispatch interface of COM object in a record of functions.
 * @copyright (c) 2007, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
signature OLE = 
sig

  (** In COM/OLE, string is usually encoded in UTF16LE. *)
  structure OLEString : MULTI_BYTE_STRING
                            where type string = UTF16LECodec.String.string
  type string = OLEString.string

  structure Decimal : OLE_DECIMAL
  type decimal = Decimal.decimal

  (** parameter to OLE.initialize. *)
  datatype coinit =
           COINIT_MULTITHREADED
         | COINIT_APARTMENTTHREADED
         | COINIT_DISABLE_OLE1DDE
         | COINIT_SPEED_OVER_MEMORY

  (** wrapper of IUnknown instance. *)
  type Unknown

  (** wrapper of IDispatch instance. *)
  type Dispatch

  (** wrapper of IEnumVARIANT instance. *)
  type EnumVARIANT

  (** wrapper of ITypeInfo instance. *)
  type TypeInfo

  (** representation of OLE VARIANT.
   * Members correspond to those of VARENUM defined in wtypes.h.
   * See http://msdn.microsoft.com/en-us/library/cc237865(PROT.13).aspx
   *)
  datatype variant =
           EMPTY
         | (** SQL NULL. *) NULL
         | I2 of Int32.int
         | I4 of Int32.int
         | R4 of Real32.real
         | R8 of Real64.real
(*
         | CY of ?
         | DATE of ?
*)
         | BSTR of string
         | DISPATCH of Dispatch
         | ERROR of Int32.int
         | BOOL of bool
         | VARIANT of variant
         | UNKNOWN of Unknown
         | DECIMAL of decimal
         | I1 of Int32.int (* ToDo : should be Int8.int, if we have it. *)
         | UI1 of Word8.word
         | UI2 of Word32.word
         | UI4 of Word32.word
         | I8 of IntInf.int (* ToDo : should be Int64.int, if we have it. *)
         | UI8 of IntInf.int (* ToDo : should be Word64.word, if we have it. *)
         | INT of Int32.int
         | UINT of Word32.word
(*
         | VOID of ?
         | HRESULT of ?
         | PTR of ?
         | SAFEARRAY of ?
         | CARRAY of ?
         | USERDEFINED of ?
         | LPSTR of ?
         | LPWSTR of ?
         | RECORD of ?
         | INT_PTR of ?
         | UINT_PTR of ?
         | FILETIME of ?
         | BLOB of ?
         | STREAM of ?
         | STORAGE of ?
         | STREAMED_OBJECT of ?
         | STORED_OBJECT of ?
         | BLOB_OBJECT of ?
         | CF of ?
         | CLSID of ?
         | BSTR_BLOB of ?
         | VECTOR of ?
         | ARRAY of ?
*)
         | (** BYREF can be used to construct an argument to a parameter
            * of [in] attribute with no [out] attribute. *)
           BYREF of variant
         | (** parameter of VT_BYREF type with [out] attribute. *)
           BYREFOUT of variant ref
         | (** corresponds to (VT_ARRAY | VT_VARIANT).
            * Second component is the numbers of elements of each
            * dimension.
            * <code>VARIANTARRAY(ar, [0w10, 0w20, 0w30])</code>
            * corresponds to <code>VARIANT ar[10][20][30]</code> in C
            * syntax, for example.
            *)
           VARIANTARRAY of variant array * word list

  (** specific information of error raised in the OLE structure. *)
  datatype error = 
           (* indicates an error occurs in COM API. *)
           ComSystemError of String.string
         | (** indicates an error occurs in an invocation of COM object
            * method. *)
           ComApplicationError
           of {
                code : word,
                source : String.string,
                description : String.string,
                helpfile : String.string,
                helpcontext : word
              }
         | (** raised if pointer passed to wrapXXX is null pointer. *)
           NullObjectPointer
         | (** indicates mismatch of Variant type. *)
           TypeMismatch of String.string
         | (** indicates unexpected result of method invocation.
            * This is raised in a case, for example, that an object method
            * returns no value although expected to return any value. *)
           ResultMismatch of String.string
         | (** indicates a failure in conversion between SML datatype and
            * OLE datatype.
            *)
           Conversion of String.string

  (** indicates an error occurrence in OLE structure. *)
  exception OLEError of error

  (** initialize COM for the current thread.
   * You have to call this function before using other functions in this
   * structure.
   *)
  val initialize : coinit list -> unit

  (** uninitialize COM for the current thread. *)
  val uninitialize : unit -> unit

  (** obtain a new instance of COM class specified with a ProgID.
   * The ProgID should specify a COM class which implements IDispatch.
   * @params ProgID
   * @param ProgID a text representation of a ProgID.
   *             (ex. "Internet.Explorer")
   * @return a wrapper of IDispatch instance of the COM class of the
   *       specified ProgID.
   *)
  val createInstanceOfProgID : string -> Dispatch

  (**
   * obtain a new instance of COM class specified with a CLSID.
   * The CLSID should specify a COM class which implements IDispatch.
   * @params CLSID
   * @param CLSID a text representation of a CLSID.
   *               (ex. "{00024500-0000-0000-C000-000000000046}")
   * @return a wrapper of IDispatch instance of the COM class of the
   *       specified CLSID.
   *)
  val createInstanceOfCLSID : string -> Dispatch

  (** obtain a reference to an instance located by a path name.
   * <p>
   * Example.
   * <pre>
   *   OLE.getObject (OLE.L "C:/home/yamato/doc/Sample.xls");
   * </pre>
   * </p>
   *)
  val getObject : string -> Dispatch

  (**
   * obtains IUnknown from a raw pointer.
   * @params pointer
   * @param pointer a pointer to IUnknown instance.
   * @return a wrappr of an IUnknown interface of the argument object.
   *)
  val wrapUnknown : UnmanagedMemory.address -> Unknown

  (**
   * obtains IDispatch from an IUnknown instance.
   * @params IUnknown
   * @param IUnknown a IUnknown instance which should implement IDispatch.
   * @return a wrappr of an IDispatch interface of the argument object.
   *)
  val wrapDispatch : Unknown -> Dispatch

  (**
   * obtains IEnumVARIANT from an IUnknown instance.
   * @params IUnknown
   * @param IUnknown a pointer to IUnknown instance which should
   *               implement IEnumVARIANT.
   * @return a wrappr of an IEnumVARIANT interface of the argument object.
   *)
  val wrapEnumVARIANT : Unknown -> EnumVARIANT

  (* below functions are for user convenience. *)

  (** special variant which is used to indicate the corresponding optional
   * parameter is not specified. *)
  val NOPARAM : variant
                
  (** converts ASCII string to OLE string (in UTF16LE). *)
  val L : String.string -> string

  (** converts OLE string (in UTF16LE) to ASCII string. *)
  val A : string -> String.string

  (** fold elements obtained from an enumerable object. *)
  val fold_enum : (variant * 'accum -> 'accum) -> 'accum -> Dispatch -> 'accum

  (** apply a function to elements obtained from an enumerable object. *)
  val for_each : (variant -> unit) -> Dispatch -> unit

  (** get all elements obtained from an enumerable object. *)
  val enumAll : Dispatch -> variant list

  (** a null pointer to IUnknown interface. *) 
  val NullUnknown : Unknown

  (** a null pointer to IDispatch interface. *)
  val NullDispatch : Dispatch

  (** true if the unknown pointer is null. *)
  val isNullUnknown : Unknown -> bool

  (** true if the dispatch pointer is null. *)
  val isNullDispatch : Dispatch -> bool

end;
