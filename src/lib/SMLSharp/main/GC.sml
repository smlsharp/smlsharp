(**
 * functions to access Garbage Collector.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: GC.sml,v 1.5 2007/03/16 11:30:36 kiyoshiy Exp $
 *)
structure GC : GC =
struct

  datatype mode = Minor | Major

  fun collect Minor = GC_doGC 0
    | collect Major = GC_doGC 1

end;
