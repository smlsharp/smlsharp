(**
 * finalization mechanism.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharpFinalizable.sml,v 1.1 2007/04/13 04:35:25 kiyoshiy Exp $
 *)
structure SMLSharpFinalizable :> SMLSHARP_FINALIZABLE =
struct

  type 'a finalizable = 'a ref * ('a ref -> unit) ref

  fun wrapFinalizer f =
      fn (ref v) =>
         ((f v)
          handle e => (print ("Execption in finalizer:" ^ exnMessage e); ()))

  fun new (value, finalizer) =
      let val finalizable = (ref value, ref (wrapFinalizer finalizer))
      in SMLSharp.Runtime.GC_addFinalizable (ref finalizable); finalizable
      end

  fun getValue (ref value, _) = value

  fun setFinalizer ((_, finalizerRef), newFinalizer) =
      finalizerRef := wrapFinalizer newFinalizer

end
