(**
 * Key-value pair parser
 * @author UENO Katsuhiro
 * @copyright (c) 2010, Tohoku University.
 *)

structure SMLSharp_SQL_KeyValuePair : sig

  type pairs = (string * string) list

  exception ParseError

  val parse : string -> pairs
  val find : pairs * string -> string option
  val findExcept : string list -> pairs -> (string * string) option

end =
struct

  type pairs = (string * string) list
  exception ParseError

  (*
   * server description is a space-separated list of key value pairs of
   * the form:
   *   <server> ::= <pair>*
   *   <pair> ::= <key> (space) = (space) <value>
   *   <key> ::= (string)
   *   <value> ::= <char>* | ' (<char>|space)* '
   *   <char> ::= (alphabet) | \\ | \'
   *)

  fun scanRepeat get src =
      case get src of
        NONE => (nil, src)
      | SOME (h, src) =>
        let
          val (t, src) = scanRepeat get src
        in
          (h::t, src)
        end

  fun scanString getc src =
      let
        val (chars, src) = scanRepeat getc src
      in
        (String.implode chars, src)
      end

  fun scanValueChar getc src =
      case getc src of
        SOME (#"\\", src) =>
        (case getc src of
           SOME (c, src) => SOME (c, src)
         | NONE => NONE)
      | SOME (#"'", src) => NONE
      | SOME (c, src) => if Char.isSpace c then NONE else SOME (c, src)
      | NONE => NONE

  fun scanValueCharQuoted getc src =
      case scanValueChar getc src of
        SOME (c, src) => SOME (c, src)
      | NONE =>
        case getc src of
          SOME (c, src) =>
          if Char.isSpace c then SOME (c, src) else NONE
        | NONE => NONE

  fun scanValue getc src =
      case getc src of
        SOME (#"'", src) =>
        let
          val (ret, src) = scanString (scanValueCharQuoted getc) src
        in
          case getc src of
            SOME (#"'", src) => SOME (ret, src)
          | _ => NONE
        end
      | SOME _ => SOME (scanString (scanValueChar getc) src)
      | NONE => NONE

  fun scanKeyChar getc src =
      case getc src of
        SOME (#"_", src) => SOME (#"_", src)
      | SOME (c, src) => if Char.isAlphaNum c then SOME (c, src) else NONE
      | NONE => NONE

  fun scanKey getc src =
      let
        val (key, src) = scanString (scanKeyChar getc) src
      in
        if size key > 0 then SOME (key, src) else NONE
      end

  fun skipSpace getc src =
      case getc src of
        SOME (c, src') => if Char.isSpace c then skipSpace getc src' else src
      | NONE => src

  fun scanPair getc src =
      case scanKey getc (skipSpace getc src) of
        NONE => NONE
      | SOME (key, src) =>
        case getc (skipSpace getc src) of
          SOME (#"=", src) =>
          (case scanValue getc (skipSpace getc src) of
             SOME (value, src) => SOME ((key, value), src)
           | NONE => NONE)
        | _ => NONE

  fun scanPairList getc src =
      scanRepeat (scanPair getc) src

  fun endOfSource getc src =
      case getc (skipSpace getc src) of
        NONE => true
      | SOME _ => false

  fun parse src =
      let
        val src = Substring.full src
        val (pairs, src) = scanPairList Substring.getc src
      in
        if endOfSource Substring.getc src
        then pairs
        else raise ParseError
      end

  fun find (pairs:pairs, key) =
      case List.find (fn (k,v) => k = key) pairs of
        SOME (_, value) => SOME value
      | NONE => NONE

  fun findExcept keys (pairs:pairs) =
      List.find (fn (k,v) => not (List.exists (fn s => s = k) keys)) pairs

end
