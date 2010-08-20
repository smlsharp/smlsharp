(**
 * IEEEReal structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: IEEEReal.sml,v 1.6 2007/12/19 02:57:10 kiyoshiy Exp $
 *)
structure IEEEReal :> IEEE_REAL =
struct

  (***************************************************************************)

  datatype real_order = LESS | EQUAL | GREATER | UNORDERED

  datatype float_class =
           NAN
         | INF
         | ZERO
         | NORMAL
         | SUBNORMAL

  datatype rounding_mode =
           TO_NEAREST
         | TO_NEGINF
         | TO_POSINF
         | TO_ZERO

  type decimal_approx =
       {
         class : float_class,
         sign : bool,
         digits : int list,
         exp : int
       }

  (***************************************************************************)

  exception Unordered

  (***************************************************************************)

  fun setRoundingMode roundingMode =
      let
        val mode = case roundingMode
                    of TO_NEAREST => 0
                     | TO_NEGINF => 1
                     | TO_POSINF => 2
                     | TO_ZERO => 3
      in SMLSharp.Runtime.IEEEReal_setRoundingMode mode end
        
  fun getRoundingMode () =
      case SMLSharp.Runtime.IEEEReal_getRoundingMode ()
       of 0 => TO_NEAREST
        | 1 => TO_NEGINF
        | 2 => TO_POSINF
        | 3 => TO_ZERO

  local
    fun intsToString [] = "0"
      | intsToString digits =
        implode (map (fn digit => Char.chr(Char.ord #"0" + digit)) digits)
  in
  fun toString ({class, sign, digits, exp} : decimal_approx) =
      let
        val string = 
            case class of
              ZERO => "0.0"
            | NORMAL => "0." ^ intsToString digits
            | SUBNORMAL => "0." ^ intsToString digits
            | INF => "inf"
            | NAN => "nan"
        val string = if sign then "~" ^ string else string
        val string =
            if exp <> 0 andalso ((class = NORMAL) orelse (class = SUBNORMAL))
            then string ^ "E" ^ (Int.toString exp)
            else string
      in
        string
      end
  end

  local
    structure SC = StringCvt
    structure PC = ParserComb

    fun charToNumber char =
        case char of
          #"0" => 0
        | #"1" => 1
        | #"2" => 2
        | #"3" => 3
        | #"4" => 4
        | #"5" => 5
        | #"6" => 6
        | #"7" => 7
        | #"8" => 8
        | #"9" => 9
        | _ => raise Fail "unexpected char in IEEEReal.charToNumbr."

    val isNumberChar = Char.isDigit

    (* parse a character ignoring case. *)
    fun char_ic ch =
        PC.or(PC.char (Char.toLower ch), PC.char (Char.toUpper ch))
    (* parse a string ignoring case. *)
    fun string_ic string =
        List.foldr
            (PC.seqWith (op ::))
            (PC.result [])
            (List.map char_ic (String.explode string))

    (* (+|-|~)? *)
    fun scanSign reader stream = 
        PC.or(PC.seqWith #2 (PC.char #"+", PC.result false),
              PC.or (PC.seqWith #2 (PC.char #"~", PC.result true),
                     PC.or(PC.seqWith #2 (PC.char #"-", PC.result true),
                           PC.result false)))
             reader
             stream

    (* scan [0-9] *)
    fun scanNumChar reader stream =
        PC.wrap(PC.eatChar isNumberChar, charToNumber) reader stream

    (* NOTE: SMLBasis document seems specify [0-9]+.[0-9]+? .
     * But SML/NJ and MLton accept [0-9]+(.[0-9]+?)?
     * So, "5" should be rejected by SMLBasis spec, but is accepted by SML/NJ
     * and MLton.
     *)
    (* scan: [0-9]+(.[0-9]+?)? *)
    fun scanFirstForm reader stream =
        (PC.seq
             (
               PC.oneOrMore scanNumChar,
               PC.or(PC.seqWith #2 (PC.char #".", PC.zeroOrMore scanNumChar),
                     PC.result [0])
             ))
            reader stream

    (* scan: .[0-9]+ *)
    fun scanSecondForm reader stream =
        (PC.wrap
             (
               PC.seqWith #2 (PC.char #".", PC.oneOrMore scanNumChar),
               fn fractionals => ([], fractionals)
             ))
            reader stream

    (* scan: ([0-9]+(.[0-9]+?)? | .[0-9]+) *)
    fun scanDigits reader steram =
        PC.or (scanFirstForm, scanSecondForm) reader steram

    (* scan: (e|E)[+~-]?[0-9]+? *)
    fun scanExp reader stream =
        (PC.seqWith
             #2
             (
               PC.eatChar (fn ch => ch = #"e" orelse ch = #"E"),
               PC.seq (scanSign, PC.zeroOrMore scanNumChar)
             ))
             reader stream

    (* int list into an integer *)
    fun accumIntList ints =
        foldl (fn (int, accum) => accum * 10 + int) 0 ints

    (* [0, 0, 1, 2, 0] => ([0, 0], [1, 2, 0]) *)
    fun partitionPrefixZeros digits =
        let
          fun scan [] prefix = (prefix, [])
            | scan (0 :: tail) prefix = scan tail (0 :: prefix)
            | scan digits prefix = (prefix, digits)
        in scan digits []
        end

    (* [0, 0, 1, 2, 0] => ([0, 0, 1, 2], [0]) *)
    fun partitionSuffixZeros digits =
        case partitionPrefixZeros (List.rev digits) of
          (suffixZeros, reversedPrefix) =>
          (List.rev reversedPrefix, suffixZeros)
  in
  fun scan reader stream =
      let
        fun buildDecimal
                (sign, ((integers, fractionals), (expSign, expDigits))) =
            let
              val (_, integers) = partitionPrefixZeros integers
              val (fractionals, _) = partitionSuffixZeros fractionals
              val scannedExp =
                  (if expSign then ~1 else 1) * (accumIntList expDigits)

              val (class, digits, exp) =
                  case (integers, fractionals) of
                    ([], []) => (ZERO, [], 0)
                  | ([], _) =>
                    let
                      val class = NORMAL
                      val (prefixZeros, digits) =
                          partitionPrefixZeros fractionals
                      val exp = scannedExp - (List.length prefixZeros)
                    in (class, digits, exp)
                    end
                  | (_ :: _, _) =>
                    let
                      val class = NORMAL
                      val (digits, _) =
                          partitionSuffixZeros (integers @ fractionals)
                      val exp = scannedExp + (List.length integers)
                    in (class, digits, exp)
                    end

            in
              {class = class, sign = sign, digits = digits, exp = exp}
              : decimal_approx
            end
        fun scanNormal reader stream =
            PC.wrap
              (
                PC.seq
                    (
                      scanSign,
                      PC.seq(scanDigits, PC.or(scanExp, PC.result (true, [0])))
                    ),
                buildDecimal
              )
              reader
              stream
        fun scanUnnormal reader stream =
            PC.wrap
                (
                  PC.seq
                      (
                        scanSign, 
                        PC.or'
                            [
                              PC.wrap (string_ic "infinity", fn _ => INF),
                              PC.wrap (string_ic "inf", fn _ => INF),
                              PC.wrap (string_ic "nan", fn _ => NAN)
                            ]
                      ),
                  fn (sign, class) => 
                     {class = class, sign = sign, digits = [], exp = 0}
                     : decimal_approx
                )
                reader
                stream
      in
        PC.or
            (scanNormal, scanUnnormal)
            reader
            (StringCvt.skipWS reader stream)
      end
  fun fromString string = (SC.scanString scan) string
  end

  (***************************************************************************)

end
