(**
 * functions to access Garbage Collector.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP_GC.sig,v 1.2 2007/05/09 13:13:32 kiyoshiy Exp $
 *)
signature SMLSHARP_GC =
sig

  datatype mode =
           (** minor GC that scans only younger region of heap. *) Minor
         | (** major GC that scans whole heap. *) Major

  (**
   * invoke garbage collection.
   *)
  val collect : mode -> unit

  (**
   * true if an address points to a block.
   *)
  val isAddressOfBlock : unit ptr -> bool

end
