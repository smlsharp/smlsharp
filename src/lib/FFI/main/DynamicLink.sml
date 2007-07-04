(**
 * access to dynamic link library.
 * @author YAMATODANI Kiyoshi
 * @version $Id: DynamicLink.sml,v 1.5 2007/04/02 09:42:29 katsu Exp $
 *)
structure DynamicLink = 
struct
  type dllHandle = unit ptr
  type symbol = unit ptr
  val dlopen = DynamicLink_dlopen
  val dlclose = DynamicLink_dlclose
  val dlsym = DynamicLink_dlsym
end
