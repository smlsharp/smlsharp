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
  datatype order = LESS | EQUAL | GREATER

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

  (* FIXME *)
  fun exnName (exn : exn) = "exnName is not implemented"
  fun exnMessage (exn : exn) = "exnMessage is not implemented"

  fun ! (ref arg) = arg
  val op := = op :=
  fun op o (f, g) x = f(g(x))
  fun op before (result, ignored) = result
  fun ignore ignored = ()

end

datatype order = datatype General.order
val ! = General.!
val op before = General.before
val exnMessage = General.exnMessage
val exnName = General.exnName
val ignore = General.ignore
val op o = General.o
exception Chr = General.Chr
exception Span = General.Span
