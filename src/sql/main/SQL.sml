(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SQL =
struct
  open SMLSharp_SQL_Prim
  open SMLSharp_SQL_Backend
  val op ^ = strcat
  open SMLSharp_SQL_Utils
  structure TimeStamp = SMLSharp_SQL_TimeStamp
  structure Decimal = SMLSharp_SQL_Decimal
  structure Float = SMLSharp_SQL_Float
end
