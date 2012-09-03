(**
 * libcurses.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libcurses.sml,v 1.1.2.1 2007/03/26 06:26:50 katsu Exp $
 *)

structure Libcurses =
struct

  local
    open CConfig
    open DynamicLink
    val libcursesName =
        case findLibrary ("curses","initscr",["curses.h"]) of
          SOME x => x
        | NONE => valOf (findLibrary ("ncurses","initscr",["curses.h"]))
(*
    (* Mac OS X *)
    val libcursesName = "/usr/lib/libncurses.5.4.dylib"
*)

    val libcurses = dlopen libcursesName
  in

  val A_REVERSE = valOf (haveConstUInt ("A_REVERSE",["curses.h"]))
  val A_BOLD = valOf (haveConstUInt ("A_BOLD",["curses.h"]))
(*
  (* Mac OS X *)
  val A_REVERSE = 262144
  val A_BOLD = 2097152
*)
               
  val initscr  = dlsym (libcurses, "initscr")  : _import () -> unit
  val endwin   = dlsym (libcurses, "endwin")   : _import () -> unit
  val nocbreak = dlsym (libcurses, "nocbreak") : _import () -> unit
  val noecho   = dlsym (libcurses, "noecho")   : _import () -> unit
  val nonl     = dlsym (libcurses, "nonl")     : _import () -> unit
  val attron   = dlsym (libcurses, "attron")   : _import (word) -> unit
  val attroff  = dlsym (libcurses, "attroff")  : _import (word) -> unit
  val addch    = dlsym (libcurses, "addch")    : _import (char) -> unit
  val addstr   = dlsym (libcurses, "addstr")   : _import (string) -> unit 
  val move     = dlsym (libcurses, "move")     : _import (int, int) -> unit
  val refresh  = dlsym (libcurses, "refresh")  : _import () -> unit
  val clear    = dlsym (libcurses, "clear")    : _import () -> unit

  end

end
