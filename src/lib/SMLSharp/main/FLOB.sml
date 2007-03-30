(**
 * 'FLOB' is abbreviation of 'Fixed Location OBject'.
 * @author YAMATODANI Kiyoshi
 * @copyright (c) 2006, Tohoku University.
 * @version $Id: FLOB.sml,v 1.1.2.1 2007/03/28 08:11:21 kiyoshiy Exp $
 *)
structure FLOB : FLOB =
struct

  fun fixedCopy x = GC_fixedCopy (ref x)
  fun release x = GC_releaseFLOB (ref x)
  fun addressOf x = GC_addressOfFLOB (ref x)

end;