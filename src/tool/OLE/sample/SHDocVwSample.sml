(*
 * To run this sample code, you should generate two files as follows.
 *
 *   $ OLE2SML.exe -c InternetExplorer InternetExplorer.Application
 *   generated SHDocVw.sml
 *   $ OLE2SML.exe -c HTMLDocument -c HTMLHtmlElement \
 *      "C:\\WINDOWS\\system32\\MSHTML.TLB"
 *   generated MSHTML.sml
 *)

(* OLE.sml is installed in SML# system library directory. *)
use "OLE.sml";

(* initialize the current thread. *)
OLE.initialize [OLE.COINIT_MULTITHREADED];

(****************************************)

use "./SHDocVw.sml";

(* create COM object. *)
val IE = SHDocVw.newInternetExplorer ();

(* property get *)
#getVisible IE ();

(* property set *)
#setVisible IE true;

(* To print OLE string (= UTF16LE string), converts it to Ascii string. *)
OLE.OLEString.toAsciiString(#getPath IE ());

(* method invoke. *)
#GoHome IE ();

(* Last 4 arguments of Navigate are optional.
 *)
#Navigate IE (OLE.L"http://www.pllab.riec.tohoku.ac.jp/smlsharp/", NONE, NONE, NONE, NONE);

(****************************************)

use "./MSHTML.sml";

val doc = MSHTML.HTMLDocument (#getDocument IE ());
val charset = OLE.A(#getcharset doc ());

val body = MSHTML.HTMLHtmlElement(#getbody doc ());

(* get contents of body. *)
val bodyText = OLE.A(#getinnerText body ());

val _ = print bodyText

(* decode bodyText. Codec is decided dynamically. *)
val decodedText = MultiByteString.String.decodeString charset bodyText;
val textLength = MultiByteString.String.size decodedText;

(****************************************)

(* After use, client must release COM object.
 * This OLE library releases COM objects automatically by use of SML#
 * finalizer mechanism, if objects are not referenced.
 *
 * But following references are global, so they will not become garbage.
 * We have to call 'release' method for these objects explicitly.
 *)
#release body ();
#release doc ();
#release IE ();

(* uninitialize COM. *)
OLE.uninitialize ();
