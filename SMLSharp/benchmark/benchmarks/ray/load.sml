exception Fail of string; (** not present in old versions **)


use "./objects.sml";
use "./ray.sml";
use "./interp.sml";
use "./interface.sml";
use "./main.sml";

Main.doit ();
print "Done";
