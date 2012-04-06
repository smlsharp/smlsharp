(**
 * General structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "General.smi"

structure General :> GENERAL
  where type unit = unit
=
struct
  type unit = unit
  type exn = exn
  datatype order = datatype order
  exception Bind = Bind
  exception Chr = Chr
  exception Div = Div
  exception Domain = Domain
  exception Fail = Fail (* Fail is builtin exception *)
  exception Match = Match
  exception Overflow = Overflow
  exception Size = Size
  exception Span = Span
  exception Subscript = Subscript

  val exnName = exnName
  val exnMessage = exnName

(* 2012-1-7 ohori: this must be a builtin primitive.
  fun ! (ref arg) = arg
*)
  val ! = !
  val op := = op :=
  fun op o (f, g) x = f(g(x))
  fun op before (result, ignored) = result
  fun ignore ignored = ()
end

(* 2012-1-9 ohori: order is builtin *)
datatype order = datatype order
(* 2012-1-7 ohori: this must be a builtin primitive.
val ! = General.!
*)
val op before = General.before
val exnMessage = General.exnMessage
val ignore = General.ignore
val op o = General.o
exception Chr = General.Chr
exception Span = General.Span
