(* -*- sml -*- *)
(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure RecordLabel =
struct

  type label = string * string

  fun getDigits ss =
      case Substring.getc ss of
        NONE => ss
      | SOME (c, ss2) =>
        if Char.isDigit c then getDigits ss2 else ss

  fun getNumeric ss =
      case Substring.getc ss of
        NONE => ss
      | SOME (#"0", ss2) =>
        if (case Substring.getc ss2 of
              SOME (c, _) => not (Char.isDigit c)
            | NONE => true)
        then ss2
        else ss
      | SOME _ => getDigits ss

  fun fromString string : label =
      case Substring.base (getNumeric (Substring.full string)) of
        (s, i, _) => (String.substring (s, 0, i), String.extract (s, i, NONE))

  fun toString (digits, label) = digits ^ label

  fun fromInt n = (Int.toString n, "")

  fun fromSymbol symbol = fromString (Symbol.toString symbol)

  fun fromLongsymbol longsymbol = fromString (Longsymbol.toString longsymbol)

  fun isAlphaNumUtf8String ss =
      case StringEscape.getc ss of
        NONE => true
      | SOME (s, ss) =>
        (Substring.size s > 1 orelse Char.isAlphaNum (Substring.sub (s, 0)))
        andalso isAlphaNumUtf8String ss

  fun isAlphaNumUtf8Label ss =
      case StringEscape.getc ss of
        NONE => false
      | SOME (s, ss) =>
        (Substring.size s > 1 orelse Char.isAlpha (Substring.sub (s, 0)))
        andalso isAlphaNumUtf8String ss

  fun term s = [SMLFormat.FormatExpression.Term (size s, s)]

  fun format_label (digits, "") = term digits
    | format_label ("", label) =
      if isAlphaNumUtf8Label (Substring.full label)
      then term label
      else term (StringEscape.toStringLiteral label)
    | format_label (digits, label) =
      term (StringEscape.toStringLiteral (digits ^ label))

  fun compareDigits digits1 digits2 =
      let
        val len1 = size digits1
        val len2 = size digits2
      in
        if len1 = len2
        then String.compare (digits1, digits2)
        else Int.compare (len1, len2)
      end

  (* There are three kinds of record labels: numeric, id, and string.
   * Numeric and string ones must be ordered in the order of their
   * numeric parts. *)
  fun compare ((digits1, lab1), (digits2, lab2)) =
      case compareDigits digits1 digits2 of
        EQUAL => String.compare (lab1, lab2)
      | order => order

  structure Ord =
  struct
    type ord_key = label
    val compare = compare
  end

  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)

  (* return true if the given list is of the form [(1,_), (2,_), ..., (n,_)]
   * where n >= 2. *)
  fun isTupleList nil = false
    | isTupleList [_] = false
    | isTupleList fields =
      let
        fun check n nil = true
          | check n (((digits, ""), _) :: t) =
            Int.toString n = digits andalso check (n + 1) t
          | check n (_ :: _) = false
      in
        check 1 fields
      end

  fun isTupleMap lmap =
      isTupleList (Map.listItemsi lmap)

  (* return true if the given fields consist of only sequential numeric and
   * numeric-with-id labels *)
  fun isOrderedList fields =
      let
        fun check n nil = true
          | check n (((digits, _), _) :: t) =
            Int.toString n = digits andalso check (n + 1) t
      in
        check 1 fields
      end

  fun isOrderedMap lmap =
      isOrderedList (Map.listItemsi lmap)

  fun tupleList values =
      let
        fun make n nil r = Snoc.toList r
          | make n (h :: t) r = make (n + 1) t (r ::> ((Int.toString n, ""), h))
      in
        make 1 values NIL
      end

  fun tupleMap values =
      let
        fun make n nil r = r
          | make n (h :: t) r =
            make (n + 1) t (Map.insert (r, (Int.toString n, ""), h))
      in
        make 1 values Map.empty
      end

end
