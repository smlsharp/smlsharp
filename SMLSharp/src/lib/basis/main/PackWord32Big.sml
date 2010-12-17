(**
 * packing word value in big-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PackWord32Big.sml,v 1.1 2007/03/08 08:07:00 kiyoshiy Exp $
 *)
structure PackWord32Big = 
          PackWord32Base(struct
                           val isBigEndian = true
                           val unpack = SMLSharp.Runtime.Pack_unpackWord32Big
                           val pack = SMLSharp.Runtime.Pack_packWord32Big
                         end)
