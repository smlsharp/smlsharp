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
    (* parse a character ignoring case. *)
    fun char_ic ch =
        PC.or(PC.char (Char.toLower ch), PC.char (Char.toUpper ch))
    (* parse a string ignoring case. *)
    fun string_ic string result =
        List.foldr
            (PC.seqWith #2)
            (PC.result result)
            (List.map char_ic (String.explode string))
    (* FIXME: BUF is raised for the following code. *)
(*
    val parser = PC.or(string_ic "true" true, string_ic "false" false)
*)
    fun parser reader =
        PC.or(string_ic "true" true, string_ic "false" false) reader
  in
  fun scan reader source =
      let val source = StringCvt.skipWS reader source
      in parser reader source
      end
  end

  fun fromString bool = StringCvt.scanString scan bool

  fun toString true = "true"
    | toString false = "false"

  (***************************************************************************)

end;
