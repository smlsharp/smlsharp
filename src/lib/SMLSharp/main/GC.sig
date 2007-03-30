(**
 * functions to access Garbage Collector.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: GC.sig,v 1.7 2007/03/16 11:30:36 kiyoshiy Exp $
 *)
signature GC =
sig

  datatype mode =
           (** minor GC that scans only younger region of heap. *) Minor
         | (** major GC that scans whole heap. *) Major

  (**
   * invoke garbage collection.
   *)
  val collect : mode -> unit

end
