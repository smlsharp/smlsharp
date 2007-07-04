(**
 * access to dynamic link library.
 * @author YAMATODANI Kiyoshi
 * @version $Id: DYNAMIC_LINK.sig,v 1.2 2007/04/02 09:42:29 katsu Exp $
 *)
signature DYNAMIC_LINK = 
sig
  type dllHandle
  type symbol
  val dlopen : string -> dllHandle
  val dlclose : dllHandle -> unit
  val dlsym : dllHandle * string -> symbol
end