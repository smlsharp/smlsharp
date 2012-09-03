(**
 * finalization mechanism.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: Finalizable.sml,v 1.3.2.1 2007/03/28 22:08:35 kiyoshiy Exp $
 *)
structure Finalizable :> FINALIZABLE =
struct

  type 'a finalizable = 'a ref * ('a ref -> unit) ref

  fun wrapFinalizer f =
      fn (ref v) =>
         ((f v)
          handle e => (print ("Execption in finalizer:" ^ exnMessage e); ()))

  fun new (value, finalizer) =
      let val finalizable = (ref value, ref (wrapFinalizer finalizer))
      in GC_addFinalizable (ref finalizable); finalizable
      end

  fun getValue (ref value, _) = value

  fun setFinalizer ((_, finalizerRef), newFinalizer) =
      finalizerRef := wrapFinalizer newFinalizer

end
