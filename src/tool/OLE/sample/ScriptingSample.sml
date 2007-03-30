(* This sample requires Scripting.sml generated as follows.
 * 
 *   $ OLE2SML Scripting.FileSystemObject 
 *)

use "OLE.sml";

(* initialize the current thread. *)
OLE.initialize [OLE.COINIT_MULTITHREADED];

use "./Scripting.sml";

val fs = Scripting.newFileSystemObject ();
val folder = Scripting.Folder(#GetFolder fs (OLE.L"."));
val folders = Scripting.Folders(#getSubFolders folder ());

fun pr (OLE.DISPATCH(folderObj)) =
    let val subFolder = Scripting.Folder (folderObj)
    in print (OLE.A(#getName subFolder ()))
    end
  | pr _ = raise Fail "DISPATCH expected.";

OLE.for_each pr (#this folders ());
val subnames = OLE.enumAll (#this folders ());

(*
fun listup foldersEnum =
    case #next foldersEnum 1
     of [] => ()
      | [v] => (pr v; listup foldersEnum);

val OLE.UNKNOWN enumUnknown = #get (#this folders ()) (OLE.L "_NewEnum") [];
val enum = OLE.EnumVARIANT enumUnknown;
listup enum;

val enum = OLE.EnumVARIANT(#get_NewEnum folders ());
listup enum;
*)

SMLSharp.GC.collect SMLSharp.GC.Major;