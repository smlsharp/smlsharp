(**
 * packing word value in little-endian byte order.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PackWord32Little.sml,v 1.1 2007/03/08 08:07:00 kiyoshiy Exp $
 *)
structure PackWord32Little = 
          PackWord32Base(struct
                           val isBigEndian = false
                           val unpack = Pack_unpackWord32Little
                           val pack = Pack_packWord32Little
                         end);
