(**
 * Bool
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

structure Bool =
struct

  datatype bool = datatype bool

  fun not true = false
    | not false = true

  fun scan getc strm =
      let
        fun true3 strm =
            case getc strm of
              SOME (#"e", strm) => SOME (true, strm)
            | SOME (#"E", strm) => SOME (true, strm)
            | _ => NONE
        fun true2 strm =
            case getc strm of
              SOME (#"u", strm) => true3 strm
            | SOME (#"U", strm) => true3 strm
            | _ => NONE
        fun true1 strm =
            case getc strm of
              SOME (#"r", strm) => true2 strm
            | SOME (#"R", strm) => true2 strm
            | _ => NONE
        fun false4 strm =
            case getc strm of
              SOME (#"e", strm) => SOME (false, strm)
            | SOME (#"E", strm) => SOME (false, strm)
            | _ => NONE
        fun false3 strm =
            case getc strm of
              SOME (#"s", strm) => false4 strm
            | SOME (#"S", strm) => false4 strm
            | _ => NONE
        fun false2 strm =
            case getc strm of
              SOME (#"l", strm) => false3 strm
            | SOME (#"L", strm) => false3 strm
            | _ => NONE
        fun false1 strm =
            case getc strm of
              SOME (#"a", strm) => false2 strm
            | SOME (#"A", strm) => false2 strm
            | _ => NONE
      in
        case getc (SMLSharp_ScanChar.skipSpaces getc strm) of
          SOME (#"t", strm) => true1 strm
        | SOME (#"T", strm) => true1 strm
        | SOME (#"f", strm) => false1 strm
        | SOME (#"F", strm) => false1 strm
        | _ => NONE
      end

  fun fromString bool =
      StringCvt.scanString scan bool

  fun toString true = "true"
    | toString false = "false"

end
