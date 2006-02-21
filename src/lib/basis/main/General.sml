(**
 * General structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: General.sml,v 1.3 2005/05/05 15:20:19 kiyoshiy Exp $
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

  exception Fail of string

  exception Match = Match

  exception Overflow

  exception Size

  exception Span

  exception Subscript

  (***************************************************************************)

  (* ToDo *)
  fun exnName (exn : exn) = "not implemented"

  (* ToDo *)
  fun exnMessage (exn : exn) = "not implemented"

  fun ! (ref arg) = arg;

  val (op :=) = (op :=)

  fun (f o g) x = f(g(x))

  fun result before ignored = result

  fun ignore ignored = ()

  (***************************************************************************)

end;
