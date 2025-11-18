(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure Symbol =
struct
  type symbol = int * string

  fun toString (id, "") = "{" ^ Int.toString id ^ "}"
    | toString (0, name) =
      if String.sub (name, size name - 1) = #"}"
      then name ^ "{0}"
      else name
    | toString (id, name) = name ^ "{" ^ Int.toString id ^ "}"

  fun intern (x : string) = (0, x)

  fun compare ((id1, name1) : symbol, (id2, name2) : symbol) =
      if id1 = id2
      then String.compare (name1, name2)
      else Int.compare (id1, id2)

  fun format_symbol symbol =
      SMLFormat.BasicFormatters.format_string (toString symbol)

  val count = ref 0

  fun generate baseSymbol =
      let
        val id = !count + 1
      in
        count := id;
        case baseSymbol of
          NONE => (id, "")
        | SOME (_, name) => (id, name)
      end

  structure Ord =
  struct
    type ord_key = symbol
    val compare = compare
  end
  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)
end
