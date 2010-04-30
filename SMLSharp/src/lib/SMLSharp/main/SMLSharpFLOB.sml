(**
 * 'FLOB' is abbreviation of 'Fixed Location OBject'.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: SMLSharpFLOB.sml,v 1.3 2007/05/09 13:13:32 kiyoshiy Exp $
 *)
structure SMLSharpFLOB :> SMLSHARP_FLOB =
struct

  type 'a FLOB = 'a
  fun fixedCopy x =
      let val r = ref x in SMLSharp.Runtime.GC_fixedCopy r; !r end
  fun release x = SMLSharp.Runtime.GC_releaseFLOB (ref x)
  fun addressOf x = SMLSharp.Runtime.GC_addressOfFLOB (ref x)
  fun app f x = f x
  fun isAddressOfFLOB address = SMLSharp.Runtime.GC_isAddressOfFLOB address

end;
