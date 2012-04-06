(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SQL =
struct
  open SMLSharp_SQL_Prim
  val op ^ = strcat
  open SMLSharp_SQL_Utils
end
