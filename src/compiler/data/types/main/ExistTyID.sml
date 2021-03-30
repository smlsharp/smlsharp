(**
 * exist type id
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

structure ExistTyID =
struct
  type id = int 
  val count = ref 0
  fun generate () = !count before count := !count + 1
  val format_id = SMLFormat.BasicFormatters.format_int
  val toString = Int.toString
  fun toInt x = x
  val compare = Int.compare
end
