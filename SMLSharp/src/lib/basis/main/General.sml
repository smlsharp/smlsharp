(**
 * General structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: General.sml,v 1.9 2009/06/18 07:10:49 katsu Exp $
 *)
structure General :> GENERAL =
struct

  (***************************************************************************)

  type unit = unit

  type exn = exn

  datatype order = LESS | EQUAL | GREATER

  (***************************************************************************)

  exception Bind = Bind

  exception Chr

  exception Div = Div

  exception Domain = Domain

  exception Fail = Fail (* Fail is builtin exception *)

  exception Match = Match

  exception Overflow = Overflow

  exception Size = Size

  exception Span

  exception Subscript = Subscript

  (***************************************************************************)

  (* exnName is redefined later to use SMLFormat. *)
  fun exnName (exn : exn) = "exnName is not implemented"

  (* exnName is redefined later to use SMLFormat. *)
  fun exnMessage (exn : exn) = "exnMessage is not implemented"

  fun ! (ref arg) = arg;

  val (op :=) = (op :=)

  fun (f o g) x = f(g(x))

  fun result before ignored = result

  fun ignore ignored = ()

  (***************************************************************************)

end;
