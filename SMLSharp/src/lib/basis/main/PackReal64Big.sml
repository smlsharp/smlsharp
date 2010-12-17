(**
 * packing real value in big-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PackReal64Big.sml,v 1.1 2007/03/08 08:07:00 kiyoshiy Exp $
 *)
structure PackReal64Big =
          PackReal64Base(struct
                           val isBigEndian = true
                           val unpack = SMLSharp.Runtime.Pack_unpackReal64Big
                           val pack = SMLSharp.Runtime.Pack_packReal64Big
                         end)
