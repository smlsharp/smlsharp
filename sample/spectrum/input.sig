(**
 * input.sig
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: input.sig,v 1.1.2.1 2007/03/26 06:26:50 katsu Exp $
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
