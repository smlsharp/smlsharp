(**
 * access to dynamic link library.
 * @author YAMATODANI Kiyoshi
 * @version $Id: DynamicLink.sml,v 1.4.2.2 2007/03/22 04:30:44 ohori Exp $
 *)
structure DynamicLink = 
struct
  type dllHandle = unit ptr
  type symbol = unit ptr
  val dlopen = DynamicLink_dlopen
  val dlclose = DynamicLink_dlclose
  val dlsym = DynamicLink_dlsym
end
