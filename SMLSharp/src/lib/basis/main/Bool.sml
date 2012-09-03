(**
 * Bool structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Bool.sml,v 1.5 2005/05/14 15:03:39 kiyoshiy Exp $
 *)
structure Bool :> BOOL =
struct

  (***************************************************************************)

  datatype bool = datatype bool

  (***************************************************************************)

  fun not true = false
    | not false = true

  local
    structure PC = ParserComb
  in
  fun scan reader source =
      let
        val source = StringCvt.skipWS reader source
      in
        PC.or(PC.seqWith #2 (PC.string "true", PC.result true),
              PC.seqWith #2 (PC.string "false", PC.result false))
        reader
        source
      end
  end

  fun fromString bool = StringCvt.scanString scan bool

  fun toString true = "true"
    | toString false = "false"

  (***************************************************************************)

end;
