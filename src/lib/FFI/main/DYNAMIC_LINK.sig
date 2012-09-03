(**
 * access to dynamic link library.
 * @author YAMATODANI Kiyoshi
 * @version $Id: DYNAMIC_LINK.sig,v 1.1.4.2 2007/03/22 04:30:44 ohori Exp $
 *)
signature DYNAMIC_LINK = 
sig
  type dllHandle
  type symbol
  val dlopen : string -> dllHandle
  val dlclose : dllHandle -> unit
  val dlsym : dllHandle * string -> symbol
end