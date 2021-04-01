(*
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure GenID = 
struct
local
  val reservedId = ref 0
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun generateWithArg f = 
      let
        val newId = !state before state := !state + 1
        val _ = f newId
      in
        newId
      end
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
  fun setReservedId () = reservedId := (!state)
  fun isReserved id = id < (!reservedId)
end
end
