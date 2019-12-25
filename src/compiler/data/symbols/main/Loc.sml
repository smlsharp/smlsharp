(**
 *
 * location in the source code.
 * @copyright (c) 2006, Tohoku University.
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

    datatype pos = 
        POS of {source : source, line : int, col : int, pos : int, gap : int}
      | NOPOS

    type loc = pos * pos

    fun format_file_place STDPATH =
        [SMLFormat.FormatExpression.Term (7, "STDPATH")]
      | format_file_place USERPATH =
        [SMLFormat.FormatExpression.Term (8, "USERPATH")]

    fun format_source (FILE (_, filename)) =
        Filename.format_filename filename
      | format_source INTERACTIVE =
        [SMLFormat.FormatExpression.Term (13, "(interactive)")]

    fun posToString NOPOS = "(none)"
      | posToString (POS {source = INTERACTIVE, line, col, pos, ...}) =
        "(interactive):" ^ Int.toString line ^ "." ^ Int.toString col
      | posToString (POS {source = FILE (_, filename), line, col, pos, ...}) =
        Filename.toString filename ^ ":"
        ^ Int.toString line ^ "." ^ Int.toString col

    fun posToStringShort NOPOS = "(none)"
      | posToStringShort (POS {line, col, ...}) =
        Int.toString line ^ "." ^ Int.toString col

    fun locToString (pos1, pos2) =
        posToString pos1 ^ "-" ^ posToStringShort pos2

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

    fun comparePos (NOPOS, NOPOS) = EQUAL
      | comparePos (POS _, NOPOS) = GREATER
      | comparePos (NOPOS, POS _) = LESS
      | comparePos (POS {line=l1, col=c1, source=s1, pos=pos1, gap=gap1},
                    POS {line=l2, col=c2, source=s2, pos=pos2, gap=gap2}) =
        case compareSource (s1, s2) of
          EQUAL => Int.compare (pos1, pos2)
        | x => x

    fun compareLoc ((pos1, _), (pos2,_)) = comparePos (pos1, pos2)

    val nopos = NOPOS
    val noloc = (nopos, nopos)
    fun isNopos NOPOS = true
      | isNopos (POS _) = false
    val makePos = POS

    fun mergeLocs ((pos11, pos12), (pos21, pos22)) = 
        if isNopos pos11 orelse isNopos pos12 then 
          (pos21, pos22)
        else if isNopos pos21 orelse isNopos pos22 then 
          (pos11, pos12)
        else
          let
            val pos1 = 
                case comparePos(pos11, pos21) of
                  GREATER => pos21
                | _ => pos11
            val pos2 = 
                case comparePos(pos12, pos22) of
                  LESS => pos22
                | _ => pos12
          in
            (pos1, pos2)
          end

    (*************************************************************************)

end
