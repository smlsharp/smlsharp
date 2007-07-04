(**
 * mutable record and tuple.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharpMutable.sml,v 1.2 2007/05/06 07:55:55 kiyoshiy Exp $
 *)
structure SMLSharpMutable :> SMLSHARP_MUTABLE =
struct

  type 'a mutable = 'a
  fun mutableCopy (x : 'a) = (GC_copyBlock (ref x)) : 'a mutable
  fun immutableCopy (x : 'a mutable) = (GC_copyBlock (ref x)) : 'a
  fun app f (x : 'a mutable) = f x

end;