(**
 * packing real value in little-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PackReal64Little.sml,v 1.1 2007/03/08 08:07:00 kiyoshiy Exp $
 *)
structure PackReal64Little =
          PackReal64Base(struct
                           val isBigEndian = false
                           val unpack = SMLSharp.Runtime.Pack_unpackReal64Little
                           val pack = SMLSharp.Runtime.Pack_packReal64Little
                         end);
