(**
 * The OLE structure provides access to Microsoft COM and OLE automation.
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

  (****************************************)

  structure OLEString = UTF16LECodec.String

  structure Win32 = OLE_Win32
  structure Automation = OLE_Automation
  structure Decimal = OLE_Decimal
  structure SafeArray = OLE_SafeArray

  open OLE_DataConverter

  (****************************************)

  type string = UTF16LECodec.String.string

  type decimal = Decimal.decimal

  datatype coinit = datatype OLE_COM.coinit
  type Unknown = OLE_COM.Unknown

  type 'a safearray = 'a Automation.safearray
  type TypeInfo = Automation.TypeInfo
  datatype variant = datatype Automation.variant
  type Dispatch = Automation.Dispatch
  type EnumVARIANT = Automation.EnumVARIANT

  (****************************************)

  datatype error = datatype OLE_Error.error

  exception OLEError = OLE_Error.OLEError

  (****************************************)

  val initialize = OLE_COM.initialize
  val uninitialize = OLE_COM.uninitialize

  val checkHRESULT = OLE_COM.checkHRESULT

  val NullUnknown = OLE_COM.NullUnknown
  val isNullUnknown = OLE_COM.isNullUnknown
  val wrapUnknown = OLE_COM.wrapUnknown

  (****************************************)

  val createInstanceOfProgID = Automation.createInstanceOfProgID
  val createInstanceOfCLSID = Automation.createInstanceOfCLSID
  val getObject = Automation.getObject
  val wrapDispatch = Automation.wrapDispatch
  val wrapEnumVARIANT = Automation.wrapEnumVARIANT
  val variantToString = Automation.variantToString
  val NullDispatch = Automation.NullDispatch
  val isNullDispatch = Automation.isNullDispatch

  (****************************************)

  (* for user convenience *)

  val NOPARAM = ERROR(word32ToInt32X Win32.DISP_E_PARAMNOTFOUND)
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
