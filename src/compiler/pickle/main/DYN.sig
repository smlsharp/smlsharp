(**
 * serialize library based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
 * @author YAMATODANI Kiyoshi
 * @version $Id: DYN.sig,v 1.4 2006/03/01 08:55:46 kiyoshiy Exp $
 *)
signature DYN =
sig

  (***************************************************************************)

  type dyn

  (***************************************************************************)

  val new : ('a*'a->bool) -> ('a->word) -> ('a->dyn) * (dyn->'a)
  val eq : dyn * dyn -> bool
  val hash : dyn -> word

  (***************************************************************************)

end
