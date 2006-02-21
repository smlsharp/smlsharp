(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Session abstracts communication with the IML runtime.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: SESSION.sig,v 1.3 2006/02/18 04:59:28 ohori Exp $
 *)
signature SESSION =
sig

  (***************************************************************************)

  (** parameter for opening a session. *)
  type InitialParameter

  (***************************************************************************)

  (**
   * open a new session.
   *)
  val openSession : InitialParameter -> SessionTypes.Session

  (***************************************************************************)

end
