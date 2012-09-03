(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

use "OLE.sml";

use "./HelloDotNETWorld.sml";

OLE.initialize [OLE.COINIT_MULTITHREADED];

val object = HelloDotNETWorld.newHelloDotNETWorld ();
val message = OLE.A (#greeting object (OLE.L "world"));
val _ = print (message ^ "\n");
