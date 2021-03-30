(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (C) 2021 SML# Development Team.
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
