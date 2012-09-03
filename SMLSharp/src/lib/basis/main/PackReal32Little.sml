(**
 * packing real value in little-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PackReal32Little.sml,v 1.1 2007/11/01 01:53:04 kiyoshiy Exp $
 *)
structure PackReal32Little =
          PackReal32Base(struct
                           val isBigEndian = false
                           val unpack = SMLSharp.Runtime.Pack_unpackReal32Little
                           val pack = SMLSharp.Runtime.Pack_packReal32Little
                         end);
