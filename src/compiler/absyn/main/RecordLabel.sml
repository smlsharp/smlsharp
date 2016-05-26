(* -*- sml -*- *)
(**
 * @copyright (c) 2016, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure RecordLabel =
struct

  type label = string

  fun toString x = x : label
  val fromInt = Int.toString
  fun fromString x = x : label

  fun format_label l =
      let
        val s = toString l
      in
        [SMLFormat.FormatExpression.Term (size s, s)]
      end

  (* match with ^[1-9][0-9]*($|_) *)
  fun numericPrefix s =
      let
        val s = Substring.full s
      in
        case Substring.getc s of
          NONE => NONE
        | SOME (c, _) =>
          if Char.isDigit c andalso c <> #"0"
          then
            (* a label may contain an arbitrary precision integer *)
            case IntInf.scan StringCvt.DEC Substring.getc s of
              NONE => NONE
            | SOME (n, s) =>
              case Substring.getc s of
                NONE => SOME n
              | SOME (#"_", _) => SOME n
              | _ => NONE
          else NONE
      end

  (* There are four kinds of record labels: numeric, numeric-with-id, id,
   * and string.  Numeric and numeric-with-id ones must be ordered in the
   * order of their numeric parts.
   *)
  fun compare (x, y) =
      case (numericPrefix x, numericPrefix y) of
        (SOME m, SOME n) =>
        (case IntInf.compare (m, n) of
           EQUAL => String.compare (x, y)
         | order => order)
      | _ => String.compare (x, y)

  structure Ord =
  struct
    type ord_key = label
    val compare = compare
  end

  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)

  fun check f n nil = true
    | check f n ((l,_)::t) = f (n, l) andalso check f (IntInf.+ (n, 1)) t

  (* return true if the given list is of the form [(1,_), (2,_), ..., (n,_)]
   * where n >= 2. *)
  fun isTupleList nil = false
    | isTupleList [_] = false
    | isTupleList fields =
      let
        fun check n nil = true
          | check n ((l,_)::t) = Int.toString n = l andalso check (n+1) t
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
          | check n ((l,_)::t) =
            let
              val s = Int.toString n
            in
              (s = l orelse String.isPrefix (s ^ "_") l) andalso check (n+1) t
            end
      in
        check 1 fields
      end

  fun isOrderedMap lmap =
      isOrderedList (Map.listItemsi lmap)

  fun tupleList values =
      let
        fun make n nil = nil
          | make n (h::t) = (Int.toString n, h) :: make (n+1) t
      in
        make 1 values
      end

  fun tupleMap values =
      let
        fun make n z nil = z
          | make n z (h::t) = make (n+1) (Map.insert (z, Int.toString n, h)) t
      in
        make 1 Map.empty values
      end

end
