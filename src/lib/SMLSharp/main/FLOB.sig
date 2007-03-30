(**
 * 'FLOB' is abbreviation of 'Fixed Location OBject'.
 * In SML code, a FLOB is seen as other usual values allocated in SML# heap,
 * but it will not be relocated by the garbage collector.
 * So, you can pass its address to external functions which store it in
 * a global variable to keep it after the functions finish.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: FLOB.sig,v 1.1.2.2 2007/03/28 22:08:35 kiyoshiy Exp $
 *)
signature FLOB =
sig

  (**
   * generates a fixed copy of a heap block.
   * The result block will not be relocated by GC, and will not be released
   * until 'release' is invoked on and it becomes unreachable from
   * rootset.
   * @params v
   * @param v this must be a boxed value.
   * @return a duplicated copy of v allocated at a fixed memory address.
   *)
  val fixedCopy : 'a -> 'a

  (**
   * indicates that a fixed location object can be released.
   * Then, GC will release this object after it finds that this object is
   * unreachable from rootset.
   * @params v
   * @param v this must be a boxed value obtained by <code>fixedCopy</code>.
   *)
  val release : 'a -> unit

  (**
   * get address of a FLOB.
   * @params v
   * @param v this must be a boxed value obtained by <code>fixedCopy</code>.
   * @return the memory address where v is allocated.
   *)
  val addressOf : 'a -> unit ptr

end