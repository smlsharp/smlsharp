(**
 * dummy type id
 *
 * @copyright (c) 2017, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure DummyTyID =
struct
  type id = int
  type snap = int
  val count = ref 0
  fun generate () = !count before count := !count + 1
  fun peek () = !count
  fun succ n = n + 1
  fun isNewerThan (id, snap) = id >= snap
  val format_id = SMLFormat.BasicFormatters.format_int
  val format_snap = SMLFormat.BasicFormatters.format_int
  val toString = Int.toString
  val snapToString = Int.toString
end
