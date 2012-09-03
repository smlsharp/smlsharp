(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SQL =
struct
  open SMLSharp.SQLImpl
  open SMLSharp.SQLUtils

  type 'a server = 'a '_SQL'.server
  type 'a conn = 'a '_SQL'.conn
  type ('a,'b) db = ('a,'b) '_SQL'.db
  type ('a,'b) table = ('a,'b) '_SQL'.table
  type ('a,'b) row = ('a,'b) '_SQL'.row
  type ('a,'b) value = ('a,'b) '_SQL'.value
  type 'a query = 'a '_SQL'.query
  type 'a rel = 'a '_SQL'.rel
  type result = '_SQL'.result

  val op + = '_SQL'.+
  val op - = '_SQL'.-
  val op * = '_SQL'.*
  val op div = '_SQL'.div
  val op mod = '_SQL'.mod
  val op / = '_SQL'./
  val op ~ = '_SQL'.~
  val op abs = '_SQL'.abs
  val op < = '_SQL'.<
  val op <= = '_SQL'.<=
  val op > = '_SQL'.>
  val op >= = '_SQL'.>=
  val op == = '_SQL'.==
  val op ^ = '_SQL'.^
  val op andAlso = '_SQL'.andAlso
  val op orElse = '_SQL'.orElse
  val op not = '_SQL'.not
  val isNull = '_SQL'.isNull
  val isNotNull = '_SQL'.isNotNull
  val toSQL = '_SQL'.toSQL

  (* for debug *)
  (* open '_SQL' *)
end
