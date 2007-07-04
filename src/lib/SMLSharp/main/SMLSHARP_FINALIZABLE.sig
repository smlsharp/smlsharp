(**
 * finalization mechanism.
 * <p>
 * Finalization is a mechanism that associates an object with a function and
 * invokes the function after the object becomes unreachable from rootset
 * and all other finalizables and before GC reclaims the object.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSHARP_FINALIZABLE.sig,v 1.1 2007/04/13 04:35:25 kiyoshiy Exp $
 *)
signature SMLSHARP_FINALIZABLE =
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
