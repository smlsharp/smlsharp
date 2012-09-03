(**
 * Mutable record and tuple.
 * Mutable copies can be passed to foreign functions which update their
 * contents.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP_MUTABLE.sig,v 1.2 2007/05/06 07:55:55 kiyoshiy Exp $
 *)
signature SMLSHARP_MUTABLE =
sig

  type 'a mutable

  (**
   * creates a mutable copy of a tuple or record.
   * It is safe to pass a mutable copy to foreign functions which mutate its
   * contents.
   * @params record
   * @param record record or tuple.
   * @return a mutable copy of record.
   * @exception Fail raise if record is not record or tuple.
   *)
  val mutableCopy : 'a -> 'a mutable

  (**
   * creates a immutable copy of a mutable tuple or record.
   * @params mutable
   * @param mutable a mutable record or tuple.
   * @return a immutable copy of record.
   *)
  val immutableCopy : 'a mutable -> 'a

  (**
   * apply a function to a mutable.
   * @params f m
   * @param f a function
   * @param m a mutable object
   * @return if <code>m</code> is obtained by <code>mutableCopy x</code>,
   *         <code>f x</code> is returned.
   *)
  val app : ('a -> 'b) -> 'a mutable -> 'b

end
