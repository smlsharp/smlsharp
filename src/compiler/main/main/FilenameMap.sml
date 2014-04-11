(**
 * map between interface files and object files
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure FilenameMap : sig

  exception Load
  type map
  val load : Filename.filename -> map
  val find : map * Filename.filename -> Filename.filename option

end =
struct

  exception Load

  val getc = TextIO.StreamIO.input1

  fun skipSpace src =
      case getc src of
        NONE => src
      | SOME (c, src2) =>
        if Char.isSpace c then skipSpace src2 else src

  fun parseSingleQuoted src =
      case getc src of
        NONE => NONE
      | SOME (#"'", src) => SOME (nil, src)
      | SOME (c, src) =>
        case parseSingleQuoted src of
          NONE => NONE
        | SOME (cs, src) => SOME (c::cs, src)

  fun parseDoubleQuoted src =
      case getc src of
        NONE => NONE
      | SOME (#"\"", src) => SOME (nil, src)
      | SOME _ =>
        case Char.scan getc src of
          NONE => NONE
        | SOME (c, src) =>
          case parseDoubleQuoted src of
            NONE => NONE
          | SOME (cs, src) => SOME (c::cs, src)

  fun parseName src =
      case getc src of
        NONE => NONE
      | SOME (c, src2) =>
        if Char.isSpace c
        then NONE
        else case parseName src2 of
               NONE => SOME ([c], src2)
             | SOME (cs, src) => SOME (c::cs, src)

  fun parseItem src =
      case getc src of
        NONE => NONE
      | SOME (#"\"", src) => parseDoubleQuoted src
      | SOME (#"'", src) => parseSingleQuoted src
      | SOME _ => parseName src

  fun ensureEOF src =
      case getc (skipSpace src) of
        NONE => ()
      | SOME _ => raise Load

  fun parseItems src =
      case parseItem (skipSpace src) of
        NONE => (ensureEOF src; nil)
      | SOME (item, src) => CharVector.fromList item :: parseItems src

  type map = Filename.filename SEnv.map

  fun makeMap nil = SEnv.empty
    | makeMap (_::nil) = raise Load
    | makeMap (h1::h2::t) =
      let
        val h1 = Filename.toString (Filename.realPath (Filename.fromString h1))
      in
        SEnv.insert (makeMap t, h1, Filename.fromString h2)
      end

  fun load filename =
      let
        val instream = Filename.TextIO.openIn filename
        val items = parseItems (TextIO.getInstream instream)
                    handle e => (TextIO.closeIn instream; raise e)
        val _ = TextIO.closeIn instream
      in
        makeMap items
      end

  fun find (map:map, filename) =
      SEnv.find (map, Filename.toString filename)

end
