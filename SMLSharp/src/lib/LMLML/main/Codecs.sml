(**
 * This module packages definitions shared by codecs.
 * <p>
 * This module also provides a codec registry to enable to select a necessary
 * codec at runtime.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @version $Id: Codecs.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
structure Codecs : CODECS =
struct

  type codecID = unit ref

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
             isCntrl : char -> bool
           }

  type converter = buffer -> buffer

  exception BadFormat

  exception Unordered

  exception UnknownCodec

  exception ConverterNotFound

  local
    fun toUpperString string = String.map Char.toUpper string

    val aliasesRef = ref ([] : String.string list list)
    fun registerAliases aliases =
        aliasesRef := (List.map toUpperString aliases) :: (!aliasesRef)
    (** gets aliases of a codec. *)
    fun findAliases name =
        let val name' = toUpperString name
        in
          Option.getOpt
              (
                List.find
                    (isSome o (List.find (fn aliase => aliase = name')))
                    (!aliasesRef),
                []
              )
        end
  in

  local
    type entry =
         ((** codec name and aliases *) String.string list) * methods

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
        registerAliases names';
        codecs := (List.map (fn name => (name, entry)) names') @ (!codecs)
      end

  fun findCodec name = Option.map #2 (findEntry name)

  fun isAliaseOfCodec (name, aliase) =
      case findEntry name
        of NONE => raise UnknownCodec
         | SOME(aliases, _) => isSome(List.find (fn a => a = aliase) aliases)
      
  fun getCodecNames () = #1 (ListPair.unzip (!codecs))

  end (* local for codec registry *)

  end (* local for codec aliases table *)

end;
