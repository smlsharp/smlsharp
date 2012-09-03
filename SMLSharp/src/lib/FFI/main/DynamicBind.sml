(**
 * dynamic bind.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: DynamicBind.sml,v 1.1 2008/01/11 05:54:42 kiyoshiy Exp $
 *)
structure DynamicBind : DYNAMIC_BIND = 
struct
  type symbol = unit ptr
  val importSymbol = SMLSharp.Runtime.DynamicBind_importSymbol
  val exportSymbol = SMLSharp.Runtime.DynamicBind_exportSymbol
end
