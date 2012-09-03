use "OLE.sml";

use "./HelloDotNetWorld.sml";

OLE.initialize [OLE.COINIT_MULTITHREADED];

val obj = HelloDotNetWorld.newHelloDotNetWorld ();
val str = OLE.A (#greeting obj (OLE.L "SML#"));
val _ = print (str ^ "\n");
