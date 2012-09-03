use "CConfig/load.sml";
use "libc.sml";
use "libm.sml";
use "libgsl.sml";
use "spectrum.sml";

(* ---- input method ---- *)
use "input.sig";

use "input_plain.sml";

(* ---- display method ---- *)
use "display.sig";

(*
use "display_text.sml";
*)

(*
use "libcurses.sml";
use "display_curses.sml";
*)

use "../glut/libglut.sml";
use "display_glut.sml";



Display.main ();
