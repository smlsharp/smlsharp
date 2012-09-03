(*
 * This code creates a new object which runs on Microsoft CLR.
 * Because OLE2SML cannot retrieve type information about most .Net
 * components from type library, we use IDispatch methods directly.
 *)

use "OLE.sml";

OLE.initialize [OLE.COINIT_MULTITHREADED];

val stack = OLE.createInstanceOfProgID (OLE.L"System.Collections.Stack");
val _ = #invoke stack (OLE.L"Push") [OLE.BSTR(OLE.L"foo")];
val _ = #invoke stack (OLE.L"Push") [OLE.BSTR(OLE.L"bar")];
val s1 =
    case #invoke stack (OLE.L"Pop") [] of SOME(OLE.BSTR bstr) => OLE.A bstr;
val _ = print s1;
val s2 =
    case #invoke stack (OLE.L"Pop") [] of SOME(OLE.BSTR bstr) => OLE.A bstr;
val _ = print s2;

val _ = #release stack ();

val _ = OLE.uninitialize ();
