structure CConfigCache :> sig

  type 'a fmt
  val INT : int fmt
  val UINT : word fmt
  val LONG : LargeInt.int fmt
  val ULONG : LargeWord.word fmt
  val BOOL : bool fmt
  val REAL : real fmt
  val STRING : string fmt
  val OPTION : 'a fmt -> 'a option fmt
  val PAIR : 'a fmt -> ('a * 'a) fmt

  exception Format
  type cache
  val openCache : string -> cache
  val findCache : 'a fmt -> cache * string -> 'a option
  val addCache : 'a fmt -> bool -> cache * string * 'a -> unit
  val commit : cache -> unit

end =
struct

  val skip = StringCvt.skipWS

  fun scanName getc src =
      case StringCvt.splitl (not o Char.isSpace) getc (skip getc src) of
        ("", src) => NONE
      | x => SOME x

  fun scanList nil getc src = SOME ((), src)
    | scanList (h::t) getc src =
      case getc src of
        SOME (x, src) => if x = h then scanList t getc src else NONE
      | NONE => NONE

  fun scanTerm term getc src =
      scanList (String.explode term) getc (skip getc src)

  fun scanEntry getc src =
      case scanTerm "val" getc src of
        NONE => NONE
      | SOME (_, src) =>
        case scanName getc src of
          NONE => NONE
        | SOME (name, src) =>
          case scanTerm "=" getc src of
            NONE => NONE
          | SOME (_, src) =>
            SOME ((name, StringCvt.takel (fn _ => true) getc (skip getc src)),
                  src)

  fun scanString getc src =
      case scanTerm "\"" getc src of
        NONE => NONE
      | SOME (_, src) =>
        case StringCvt.splitl (fn c => c <> #"\"") getc src of
          (s, src) =>
          case getc src of
            SOME (#"\"", src) => SOME (valOf (String.fromString s), src)
          | _ => NONE

  fun scanOption scan getc src =
      case scanName getc src of
        SOME ("NONE", src) => SOME (NONE, src)
      | SOME ("SOME", src) =>
        (case scan getc src of NONE => NONE
                             | SOME (x, src) => SOME (SOME x, src))
      | _ => NONE

  fun scanPair scan getc src =
      case scanTerm "(" getc src of
        NONE => NONE
      | SOME (_, src) =>
        case scan getc src of
          NONE => NONE
        | SOME (x, src) =>
          case scanTerm "," getc src of
            NONE => NONE
          | SOME (_, src) =>
            case scan getc src of
              NONE => NONE
            | SOME (y, src) =>
              case scanTerm ")" getc src of
                NONE => NONE
              | SOME (_, src) => SOME ((x, y), src)

  fun dumpEntry (name, value) =
      "val " ^ name ^ " = " ^ value ^ "\n"

  fun dumpChar c =
      StringCvt.padLeft #"0" 3 (Int.toString (ord c))

  fun escape s =
      String.translate
        (fn #"_" => "__"
          | c => if Char.isAlphaNum c then str c else "_" ^ dumpChar c)
        (if Char.isAlpha (String.sub (s, 0)) handle Subscript => false
         then s else "e_e" ^ s)

  fun dumpString s =
      "\""
      ^ String.translate
          (fn #"\"" => "\\034"
            | c => if Char.isGraph c then str c else "\\" ^ dumpChar c)
          s
      ^ "\""

  fun dumpOption dump NONE = "NONE"
    | dumpOption dump (SOME x) = "SOME " ^ dump x

  fun dumpPair dump (x,y) =
      "(" ^ dump x ^ ", " ^ dump y ^ ")"

  type 'a scan = (char, StringCvt.cs) StringCvt.reader
                 -> ('a, StringCvt.cs) StringCvt.reader
  type 'a fmt = 'a scan * ('a -> string)
  val INT = (Int.scan StringCvt.DEC, Int.fmt StringCvt.DEC)
  val UINT = (Word.scan StringCvt.DEC, fn x => "0w" ^ Word.fmt StringCvt.DEC x)
  val LONG = (LargeInt.scan StringCvt.DEC, LargeInt.fmt StringCvt.DEC)
  val ULONG = (LargeWord.scan StringCvt.DEC,
               fn x => "0w" ^ LargeWord.fmt StringCvt.DEC x)
  val BOOL = (Bool.scan, Bool.toString)
  val REAL = (Real.scan, Real.fmt StringCvt.EXACT)
  val STRING = (scanString, dumpString)
  fun OPTION (scan, dump) = (scanOption scan, dumpOption dump)
  fun PAIR (scan, dump) = (scanPair scan, dumpPair dump)

  exception Format
  exception File
  type cache = {filename: string,
                map: (string * string) list ref,
                pool: (string * string) list ref}

  fun openCache filename =
      let
        val file = TextIO.openIn filename handle _ => raise File
        fun load file =
            case TextIO.inputLine file of
              NONE => nil
            | SOME line =>
              case StringCvt.scanString scanEntry line of
                SOME (name, value) => (name, value) :: load file
              | NONE => raise Format
        val map = load file handle e => (TextIO.closeIn file; raise e)
      in
        TextIO.closeIn file;
        {filename = filename, map = ref (rev map), pool = ref nil} : cache
      end
      handle File => {filename = filename, map = ref nil, pool = ref nil}

  fun findCache ((scan, dump):'a fmt) ({filename, map, pool}:cache, name) =
      let
        val name = escape name
      in
        case List.find (fn (k,v) => k = name) (!map) of
          NONE => NONE
        | SOME (k, v) => StringCvt.scanString scan v
      end

  fun addCache ((scan, dump):'a fmt) commit
               ({filename, map, pool}:cache, name, value) =
      let
        val entry = (escape name, dump value)
      in
        pool := entry :: (!pool);
        if commit then map := entry :: (!map) else ()
      end

  fun commit ({filename, map, pool = ref nil}:cache) = ()
    | commit ({filename, map, pool}:cache) =
      let
        val file = TextIO.openAppend filename handle _ => raise File
        val _ = foldr (fn (entry, ()) => TextIO.output (file, dumpEntry entry))
                      () (!pool)
                handle e => (TextIO.closeOut file; raise e)
      in
        TextIO.closeOut file;
        map := (!pool) @ (!map);
        pool := nil
      end

end
