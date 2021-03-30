(**
 * default file name substitution specified by user
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

structure UserFileMap =
struct

  exception Load of {msg : string, lineno : int}

  fun parseError (lineno, msg) =
      raise Load {msg = msg, lineno = lineno}

  (* trie of path components *)
  datatype map =
      NODE of {next : map Filename.Map.map, eos : Filename.filename option}

  val empty = NODE {next = Filename.Map.empty, eos = NONE}

  fun add (NODE {next, eos = NONE}, nil, f) =
      NODE {next = next, eos = SOME f}
    | add (trie as NODE {eos = SOME _, ...}, nil, _) = trie
    | add (trie as NODE {next, eos}, h :: t, m) =
      let
        val x = case Filename.Map.find (next, h) of SOME x => x | NONE => empty
      in
        NODE {next = Filename.Map.insert (next, h, add (x, t, m)), eos = eos}
      end

  fun fromList matches =
      foldl (fn ((filename, match), z) =>
                add (z, Filename.components filename, match))
            empty
            matches

  fun findLoop (NODE {next, eos}, nil) = eos
    | findLoop (NODE {next, eos}, h :: t) =
      case Filename.Map.find (next, h) of
        SOME x => findLoop (x, t)
      | NONE => NONE

  fun find (trie, filename) =
      findLoop (trie, Filename.components filename)

  fun exactMatch (s1, s2) =
      (Filename.fromString s1, Filename.fromString s2)

  fun full s = (s, 0)

  fun getc (s, i) =
      if size s > i then SOME (String.sub (s, i), (s, i + 1)) else NONE

  fun span ((s, i), (_:string, j)) =
      Filename.fromString (substring (s, i, j - i))

  fun stripl (s, i) =
      if size s > i andalso Char.isSpace (String.sub (s, i))
      then stripl (s, i + 1) else (s, i)

  fun stripr (s, i) =
      if i > 0 andalso Char.isSpace (String.sub (s, i - 1))
      then stripr (s, i - 1) else (s, i)

  fun splitl delim (s, i) =
      if size s <= i then ((s, i), NONE)
      else if String.sub (s, i) = delim then ((s, i), SOME (s, i + 1))
      else splitl delim (s, i + 1)

  (* s/str1/str2/ for each line, where / may be an arbitrary character
   * except for \n. the last / may be omitted. if omitted, str2 is read
   * up to the last non-space character in the line. *)
  fun parseLine lineno ss =
      case getc (stripl ss) of
        NONE => NONE (* empty line *)
      | SOME (#"#", ss) => NONE (* comment *)
      | SOME (c, ss) =>
        if c <> #"="
        then parseError (lineno, "illegal operation -- " ^ str c)
        else
          case getc ss of
            NONE => parseError (lineno, "unexpected end of line")
          | SOME (delim, ss11) =>
            case splitl delim ss11 of
              (_, NONE) => parseError (lineno, "unexpected end of line")
            | (ss12, SOME ss21) =>
              case splitl delim ss21 of
                (ss22, NONE) =>
                SOME (span (ss11, ss12), span (ss21, stripr ss22))
              | (ss22, SOME ss) =>
                case getc (stripl ss) of
                  NONE => SOME (span (ss11, ss12), span (ss21, ss22))
                | SOME (c, _) =>
                  parseError (lineno, "unexpected character -- " ^ str c)

  fun parseLines trie lineno file =
      case TextIO.inputLine file of
        NONE => trie
      | SOME line =>
        case parseLine lineno (full line) of
          NONE => parseLines trie (lineno + 1) file
        | SOME (filename, match) =>
          parseLines (add (trie, Filename.components filename, match))
                     (lineno + 1)
                     file

  fun parseFile file =
      parseLines empty 1 file

  fun load filename =
      let
        val file = Filename.TextIO.openIn filename
        val trie = parseFile file handle e => (TextIO.closeIn file; raise e)
      in
        TextIO.closeIn file;
        trie
      end

end
