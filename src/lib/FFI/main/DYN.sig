(**
 * serialize library based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
 * @author Martin Elsman
 * @version $Id: DYN.sig,v 1.1 2007/05/20 03:53:25 kiyoshiy Exp $
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