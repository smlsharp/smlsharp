(**
 * functions to access Garbage Collector.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharpGC.sml,v 1.2 2007/05/09 13:13:32 kiyoshiy Exp $
 *)
structure SMLSharpGC : SMLSHARP_GC =
struct

  datatype mode = Minor | Major

  fun collect Minor = GC_doGC 0
    | collect Major = GC_doGC 1

  fun isAddressOfBlock address = GC_isAddressOfBlock address

end;
