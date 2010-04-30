(**
 * input.sig
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: input.sig,v 1.2 2007/04/02 09:42:29 katsu Exp $
 *)

signature INPUT =
sig

  type input

  val buffer : word array

  val openInput : unit -> input
  val startInput : input -> unit
  val closeInput : input -> unit
  val fill : input -> bool
  val read : input -> unit
  val finished : input -> bool

end
