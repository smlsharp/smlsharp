(**
 * HTTP server
 * @author YAMATODANI Kiyoshi
 * @version $Id: HTTPD.sig,v 1.1 2007/01/02 05:13:01 kiyoshiy Exp $
 *)
signature HTTPD =
sig

  (***************************************************************************)

  (**
   * start the server.
   * @params oneShot port docRoot
   * @param oneShot If true, server shuts down after it processes the first
   *               request.
   * @param port the port number
   * @param docRoot the directory under which documents are published.
   * @return unit
   *)
  val start :
      bool -> (** port *) word -> (** document root *) string -> unit

  (**
   * close the server socket if it is opened yet.
   *)
  val shutdown : unit -> unit

  (***************************************************************************)

end;
