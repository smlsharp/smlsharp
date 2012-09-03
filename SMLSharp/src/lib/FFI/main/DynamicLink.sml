(**
 * access to dynamic link library.
 * @author YAMATODANI Kiyoshi
 * @version $Id: DynamicLink.sml,v 1.6 2008/01/11 05:54:42 kiyoshiy Exp $
 *)
structure DynamicLink : DYNAMIC_LINK = 
struct
  type dllHandle = unit ptr
  type symbol = unit ptr
  val dlopen = SMLSharp.Runtime.DynamicLink_dlopen
  val dlclose = SMLSharp.Runtime.DynamicLink_dlclose
  val dlsym = SMLSharp.Runtime.DynamicLink_dlsym
end
