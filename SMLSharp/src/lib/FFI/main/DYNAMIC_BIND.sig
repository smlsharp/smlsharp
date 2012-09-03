(**
 * dynamic bind.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: DYNAMIC_BIND.sig,v 1.1 2008/01/11 05:54:42 kiyoshiy Exp $
 *)
signature DYNAMIC_BIND =
sig
  type symbol
  val importSymbol : string -> symbol
  val exportSymbol : (string * symbol) -> unit
end