(**
 * serialize library based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
<<<<<<< DYN.sig
 * @author YAMATODANI Kiyoshi
 * @version $Id: DYN.sig,v 1.3 2006/02/18 09:10:49 kiyoshiy Exp $
=======
 * @author Martin Elsman
 * @version $Id: DYN.sig,v 1.3 2006/02/18 09:10:49 kiyoshiy Exp $
>>>>>>> 1.2
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
