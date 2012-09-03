(**
 * packing real value in big-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: PackReal32Big.sml,v 1.1 2007/11/01 01:53:04 kiyoshiy Exp $
 *)
structure PackReal32Big =
          PackReal32Base(struct
                           val isBigEndian = true
                           val unpack = SMLSharp.Runtime.Pack_unpackReal32Big
                           val pack = SMLSharp.Runtime.Pack_packReal32Big
                         end);
