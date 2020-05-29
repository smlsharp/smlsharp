(**
 * exist type id
 *
 * @copyright (c) 2020, Tohoku University.
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
