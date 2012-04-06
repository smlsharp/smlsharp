(**
 * Bool structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Bool.smi"

structure Bool :> BOOL
  where type bool = bool
=
struct

  datatype bool = datatype bool

  fun not true = false
    | not false = true

  fun toLower NONE = NONE
    | toLower (SOME (c, strm)) = SOME (Char.toLower c, strm)

  fun scan getc strm =
      case toLower (getc (SMLSharpScanChar.skipSpaces getc strm)) of
        SOME (#"t", strm) =>
        (case toLower (getc strm) of
           SOME (#"r", strm) =>
           (case toLower (getc strm) of
              SOME (#"u", strm) =>
              (case toLower (getc strm) of
                 SOME (#"e", strm) => SOME (true, strm)
               | _ => NONE)
            | _ => NONE)
         | _ => NONE)
      | SOME (#"f", strm) =>
        (case toLower (getc strm) of
           SOME (#"a", strm) =>
           (case toLower (getc strm) of
              SOME (#"l", strm) =>
              (case toLower (getc strm) of
                 SOME (#"s", strm) =>
                 (case toLower (getc strm) of
                    SOME (#"e", strm) => SOME (false, strm)
                  | _ => NONE)
               | _ => NONE)
            | _ => NONE)
         | _ => NONE)
      | _ => NONE

  fun fromString bool =
      StringCvt.scanString scan bool

  fun toString true = "true"
    | toString false = "false"

end

val not = Bool.not
