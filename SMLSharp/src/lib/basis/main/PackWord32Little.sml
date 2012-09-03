(**
 * packing word value in little-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PackWord32Little.sml,v 1.1 2007/03/08 08:07:00 kiyoshiy Exp $
 *)
structure PackWord32Little = 
          PackWord32Base(struct
                           val isBigEndian = false
                           val unpack = SMLSharp.Runtime.Pack_unpackWord32Little
                           val pack = SMLSharp.Runtime.Pack_packWord32Little
                         end)
