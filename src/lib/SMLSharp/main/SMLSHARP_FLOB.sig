(**
 * 'FLOB' is abbreviation of 'Fixed Location OBject'.
 * In SML code, a FLOB is seen as other usual values allocated in SML# heap,
 * but it will not be relocated by the garbage collector.
 * So, you can pass its address to external functions which store it in
 * a global variable to keep it after the functions finish.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP_FLOB.sig,v 1.3 2007/05/09 13:13:32 kiyoshiy Exp $
 *)
signature SMLSHARP_FLOB =
sig

  (**
   * fixed location object.
   *)
  type 'a FLOB

  (**
   * generates a fixed copy of a heap block.
   * The result block will not be relocated by GC, and will not be released
   * until 'release' is invoked on and it becomes unreachable from
   * rootset.
   * @params v
   * @param v this must be a boxed value.
   * @return a duplicated copy of v allocated at a fixed memory address.
   *)
  val fixedCopy : 'a -> 'a FLOB

  (**
   * indicates that a fixed location object can be released.
   * Then, GC will release this object after it finds that this object is
   * unreachable from rootset.
   * @params v
   * @param v this must be a boxed value obtained by <code>fixedCopy</code>.
   *)
  val release : 'a FLOB -> unit

  (**
   * get address of a FLOB.
   * @params v
   * @param v this must be a boxed value obtained by <code>fixedCopy</code>.
   * @return the memory address where v is allocated.
   *)
  val addressOf : 'a FLOB -> unit ptr

  (**
   * apply a function to a FLOB.
   *)
  val app : ('a -> 'b) -> 'a FLOB -> 'b

  (**
   * true if an address points to a FLOB.
   *)
  val isAddressOfFLOB : unit ptr -> bool

end