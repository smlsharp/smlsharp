(**
 * packing word value in big-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PackWord32Big.sml,v 1.1 2007/03/08 08:07:00 kiyoshiy Exp $
 *)
structure PackWord32Big = 
          PackWord32Base(struct
                           val isBigEndian = true
                           val unpack = Pack_unpackWord32Big
                           val pack = Pack_packWord32Big
                         end);
