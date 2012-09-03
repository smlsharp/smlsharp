(**
 * callback.sml - An example of passing complex callbacks between ML and C.
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: callback.sml,v 1.4 2007/04/02 09:42:29 katsu Exp $
 *)

val lib = DynamicLink.dlopen "./callback.so"
val sym1 = DynamicLink.dlsym (lib, "f1")
val sym2 = DynamicLink.dlsym (lib, "g1")
val f1 = sym1 : _import (((((()->unit)->unit)->unit)->unit)->unit)->unit
val g1 = sym2 : _import ()->()->()->()->unit

val () =
    f1 (fn h1 =>
           (print "h1\n";
            h1 (fn h2 =>
                   (print "h2\n";
                    h2 (fn h3 =>
                           print "h3\n")))))

val g2 = g1 ()
val g3 = g2 ()
val g4 = g3 ()
val () = g4 ()
