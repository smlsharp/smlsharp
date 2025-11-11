(**
 *
 * location in the source code.
 * @copyright (C) 2021 SML# Development Team.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Loc.ppg,v 1.1 2007/08/12 06:32:55 ohori Exp $
 *)
structure Loc (* :> LOC *) =
struct

    (*************************************************************************)

    datatype file_place =
        STDPATH
      | USERPATH

    datatype source =
        FILE of file_place * Filename.filename
      | INTERACTIVE

    datatype at =
        AT of {line : int, col : int, pos : int, token : int}
      | EOF

    type pos = {source : source, pos : at}

    datatype loc =
        LOC of pos * pos
      | NOLOC

    fun format_file_place STDPATH =
        [SMLFormat.FormatExpression.Term (7, "STDPATH")]
      | format_file_place USERPATH =
        [SMLFormat.FormatExpression.Term (8, "USERPATH")]

    fun format_source (FILE (_, filename)) =
        Filename.format_filename filename
      | format_source INTERACTIVE =
        [SMLFormat.FormatExpression.Term (13, "(interactive)")]

    fun sourceToString INTERACTIVE = "(interactive)"
      | sourceToString (FILE (_, filename)) = Filename.toString filename

    fun lineColToString {line, col, ...} =
        Int.toString line ^ "." ^ Int.toString col

    fun atToString EOF = "eof"
      | atToString (AT at) = lineColToString at

    fun atPairToString (EOF, EOF) = "eof"
      | atPairToString (AT at1, AT at2) =
        if at1 = at2
        then lineColToString at1
        else if #line at1 = #line at2
        then lineColToString at1 ^ "-" ^ Int.toString (#col at2)
        else lineColToString at1 ^ "-" ^ lineColToString at2
      | atPairToString (at1, at2) =
        atToString at1 ^ "-" ^ atToString at2

    fun posToString {source, pos} =
        sourceToString source ^ ":" ^ atToString pos

    fun rangeToString (pos1 as {source = source1, pos = at1},
                       pos2 as {source = source2, pos = at2}) =
        if source1 = source2
        then sourceToString source1 ^ ":" ^ atPairToString (at1, at2)
        else posToString pos1 ^ "-" ^ posToString pos2

    fun locToString NOLOC = "(none)"
      | locToString (LOC (pos1, pos2)) = rangeToString (pos1, pos2)

    fun format_loc loc =
        SMLFormat.BasicFormatters.format_string (locToString loc)

    (*************************************************************************)

    fun compareFilePlace (STDPATH, USERPATH) = LESS
      | compareFilePlace (STDPATH, STDPATH) = EQUAL
      | compareFilePlace (USERPATH, USERPATH) = EQUAL
      | compareFilePlace (USERPATH, STDPATH) = GREATER

    fun compareSource (INTERACTIVE, INTERACTIVE) = EQUAL
      | compareSource (INTERACTIVE, FILE _) = LESS
      | compareSource (FILE _, INTERACTIVE) = GREATER
      | compareSource (FILE (p1, f1), FILE (p2, f2)) =
        case compareFilePlace (p1, p2) of
          EQUAL => Filename.compare (f1, f2)
        | x => x

    fun compareAt (EOF, EOF) = EQUAL
      | compareAt (AT _, EOF) = LESS
      | compareAt (EOF, AT _) = GREATER
      | compareAt (AT {pos = pos1, ...}, AT {pos = pos2, ...}) =
        Int.compare (pos1, pos2)

    fun comparePos ({source=s1, pos=pos1}, {source=s2, pos=pos2}) =
        case compareSource (s1, s2) of
          EQUAL => compareAt (pos1, pos2)
        | x => x

    fun compareLoc (NOLOC, NOLOC) = EQUAL
      | compareLoc (NOLOC, _) = LESS
      | compareLoc (_, NOLOC) = GREATER
      | compareLoc (LOC (pos1, _), LOC (pos2,_)) = comparePos (pos1, pos2)

    val noloc = NOLOC

    fun mergeRange ((pos11, pos12), (pos21, pos22)) =
        let
          val pos1 =
              case comparePos (pos11, pos21) of
                GREATER => pos21
              | _ => pos11
          val pos2 =
              case comparePos (pos12, pos22) of
                LESS => pos22
              | _ => pos12
        in
          (pos1, pos2)
        end

    fun mergeLocs (NOLOC, loc) = loc
      | mergeLocs (loc, NOLOC) = loc
      | mergeLocs (LOC loc1, LOC loc2) = LOC (mergeRange (loc1, loc2))

    (*************************************************************************)

end
