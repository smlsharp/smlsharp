(**
 * This module packages definitions shared by codecs.
 * <p>
 * This module also provides a codec registry to enable to select a necessary
 * codec at runtime.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Codecs.sml,v 1.1.28.4 2010/05/11 07:08:04 kiyoshiy Exp $
 *)
structure Codecs : CODECS =
struct

  type char = exn
  type string = exn

  type buffer = Word8VectorSlice.slice

  type methods =
           {
             codecNames : String.string list,
             decode : buffer -> string,
             encode : string -> buffer,
             convert : String.string -> string -> buffer,

             sub : string * int -> char,
             substring : string * int * int -> string,
             size : string -> int,
             concat : string list -> string,

             compareChar : (char * char) -> order,

             ordw : char -> Word32.word,
             chrw: Word32.word -> char,
             minOrdw : unit -> Word32.word,
             maxOrdw : unit -> Word32.word,

             toAsciiChar : char -> Char.char option,
             fromAsciiChar : Char.char -> char,
             charToString : char -> string,

             isAscii : char -> bool,
             isSpace : char -> bool,
             isLower : char -> bool,
             isUpper : char -> bool,
             isDigit : char -> bool,
             isHexDigit : char -> bool,
             isPunct : char -> bool,
             isGraph : char -> bool,
             isCntrl : char -> bool,

             dumpChar : char -> String.string,
             dumpString : string -> String.string
           }

  type converter = buffer -> buffer

  exception BadFormat

  exception Unordered

  exception UnknownCodec

  exception ConverterNotFound

  local
    type entry =
         ((** codec name and aliases *) String.string list) * methods

    fun toUpperString string = String.map Char.toUpper string

    (* FIXME: List search is inefficient.
     * Use association table, such as implementations of ORD_MAP
     * (are those available on all platform ?).
     *)
    val codecs = ref ([] : (String.string * entry) list)

    fun findEntry name =
        let val name' = toUpperString name
        in Option.map #2 (List.find (fn (n, _) => n = name') (!codecs))
        end
  in

  fun registerCodec (names, makeCursor) =
      let
        val names' = List.map toUpperString names
        val entry = (names', makeCursor)
      in
        codecs := (List.map (fn name => (name, entry)) names') @ (!codecs)
      end

  fun findCodec name = Option.map #2 (findEntry name)

  fun isAliaseOfCodec (name, aliase) =
      case findEntry name
        of NONE => raise UnknownCodec
         | SOME(aliases, _) => isSome(List.find (fn a => a = aliase) aliases)
      
  fun getCodecNames () = #1 (ListPair.unzip (!codecs))

  end (* local for codec registry *)

end
