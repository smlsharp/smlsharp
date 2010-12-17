(**
 * mutable record and tuple.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharpMutable.sml,v 1.2 2007/05/06 07:55:55 kiyoshiy Exp $
 *)
structure SMLSharpMutable :> SMLSHARP_MUTABLE =
struct

  type 'a mutable = 'a
  fun mutableCopy (x : 'a) =
      let val r = ref x in SMLSharp.Runtime.GC_copyBlock r; !r end : 'a mutable
  fun immutableCopy (x : 'a mutable) =
      let val r = ref x in SMLSharp.Runtime.GC_copyBlock r; !r end : 'a
  fun app f (x : 'a mutable) = f x

end
