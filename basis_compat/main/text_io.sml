structure TextIO : TEXT_IO =
struct
  open Orig_TextIO

(* FIXME!
  structure StreamIO : TEXT_STREAM_IO =
  struct
    open Orig_TextIO.StreamIO
    type in_pos = pos
  end
*)

  fun inputLine source =
      case Orig_TextIO.inputLine source of
        SOME x => x
      | NONE => ""
end
