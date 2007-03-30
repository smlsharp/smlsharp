(**
 * General structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: General.sml,v 1.8 2007/02/05 08:32:45 kiyoshiy Exp $
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

  exception Div

  exception Domain

  exception Fail = Fail (* Fail is builtin exception *)

  exception Match = Match

  exception Overflow

  exception Size

  exception Span

  exception Subscript

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
