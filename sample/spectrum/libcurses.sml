(**
 * libcurses.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libcurses.sml,v 1.2 2007/04/02 09:42:29 katsu Exp $
 *)

structure Libcurses =
struct

  (* Mac OS X *)
  val A_REVERSE = 262144
  val A_BOLD = 2097152

  val initscr  = _import "initscr" : () -> unit
  val endwin   = _import "endwin" : () -> unit
  val nocbreak = _import "nocbreak" : () -> unit
  val noecho   = _import "noecho" : () -> unit
  val nonl     = _import "nonl" : () -> unit
  val attron   = _import "attron" : (word) -> unit
  val attroff  = _import "attroff" : (word) -> unit
  val addch    = _import "addch" : (char) -> unit
  val addstr   = _import "addstr" : (string) -> unit 
  val move     = _import "move" : (int, int) -> unit
  val refresh  = _import "refresh" : () -> unit
  val clear    = _import "clear" : () -> unit

end
