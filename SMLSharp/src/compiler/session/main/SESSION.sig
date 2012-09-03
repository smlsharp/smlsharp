(**
 * Session abstracts communication with the IML runtime.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SESSION.sig,v 1.4 2006/02/28 16:11:05 kiyoshiy Exp $
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
