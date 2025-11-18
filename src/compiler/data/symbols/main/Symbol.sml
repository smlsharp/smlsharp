(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure Symbol =
struct
  type symbol = word * int * string

  fun toString ((_, id, "") : symbol) = "{" ^ Int.toString id ^ "}"
    | toString (_, 0, name) =
      if String.sub (name, size name - 1) = #"}"
      then name ^ "{0}"
      else name
    | toString (_, id, name) = name ^ "{" ^ Int.toString id ^ "}"

  fun intern name : symbol = (FNVHash.hashString name, 0, name)

  fun compare ((hash1, id1, name1) : symbol, (hash2, id2, name2) : symbol) =
      if id1 = id2
      then if hash1 = hash2
           then String.compare (name1, name2)
           else Word.compare (hash1, hash2)
      else Int.compare (id1, id2)

  fun format_symbol symbol =
      SMLFormat.BasicFormatters.format_string (toString symbol)

  val count = ref 0

  fun generate (baseSymbol : symbol option) =
      let
        val id = !count + 1
      in
        count := id;
        case baseSymbol of
          NONE => (FNVHash.hashString "", id, "")
        | SOME (hash, _, name) => (hash, id, name)
      end

  structure Ord =
  struct
    type ord_key = symbol
    val compare = compare
  end
  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)
end
