(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SQL =
struct

  open SMLSharp_SQL_Prim
  open SMLSharp_SQL_Errors
  open SMLSharp_SQL_Backend
  structure Numeric = SMLSharp_SQL_Prim.Numeric
  structure Decimal = Numeric
  structure TimeStamp = SMLSharp_SQL_TimeStamp

end
