(**
 * finalization mechanism.
 * <p>
 * Finalization is a mechanism that associates an object with a function and
 * invokes the function after the object becomes unreachable from rootset
 * and all other finalizables and before GC reclaims the object.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: FINALIZABLE.sig,v 1.3.4.2 2007/03/28 22:08:35 kiyoshiy Exp $
 *)
signature FINALIZABLE =
sig

  (**
   * an object associated with a finalizer function.
   *)
  type 'a finalizable

  (**
   * associates an object and a function to generate a finalizable.
   * The function is invoked after the generated finalizable becomes
   * unreachable from rootset and all other finalizables.
   *)
  val new : ('a * ('a -> unit)) -> 'a finalizable

  (**
   * replaces the finalizer function of a finalizable.
   *)
  val setFinalizer : ('a finalizable * ('a -> unit)) -> unit

  (**
   * extracts the actual object of a finalizable.
   *)
  val getValue : 'a finalizable -> 'a

end
