(**
 * IEEEReal structure.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, Tohoku University.
 *)
_interface "IEEEReal.smi"

structure IEEEReal (*:> IEEE_REAL*) =
struct

  infix 7 * / div mod
  infix 6 + - ^
  infixr 5 :: @
  infix 4 = <> > >= < <=
  val op + = SMLSharp.Int.add
  val op - = SMLSharp.Int.sub
  val op * = SMLSharp.Int.mul
  val op ~ = SMLSharp.Int.neg

  datatype real_order = LESS | EQUAL | GREATER | UNORDERED
  datatype float_class = NAN | INF | ZERO | NORMAL | SUBNORMAL
  datatype rounding_mode = TO_NEAREST | TO_NEGINF | TO_POSINF | TO_ZERO
  type decimal_approx =
      {class : float_class, sign : bool, digits : int list, exp : int}

  exception Unordered

  val fesetround =
      _import "fesetround"
      : __attribute__((no_callback)) int -> int
  val fegetround =
      _import "fegetround"
      : __attribute__((pure,no_callback)) () -> int

  fun setRoundingMode roundingMode =
      let
        val mode =
            case roundingMode of
              TO_NEAREST => SMLSharpRuntime.cconstInt "FE_TONEAREST"
            | TO_NEGINF => SMLSharpRuntime.cconstInt "FE_DOWNWARD"
            | TO_POSINF => SMLSharpRuntime.cconstInt "FE_UPWARD"
            | TO_ZERO => SMLSharpRuntime.cconstInt "FE_TOWARDZERO"
        val err = fesetround mode
      in
        if err = 0 then () else raise SMLSharpRuntime.OS_SysErr ()
      end

  fun getRoundingMode () =
      let
        val mode = fegetround ()
      in
        if mode = SMLSharpRuntime.cconstInt "FE_TONEAREST" then TO_NEAREST
        else if mode = SMLSharpRuntime.cconstInt "FE_DOWNWARD" then TO_NEGINF
        else if mode = SMLSharpRuntime.cconstInt "FE_UPWARD" then TO_POSINF
        else if mode = SMLSharpRuntime.cconstInt "FE_TOWARDZERO" then TO_ZERO
        else raise SMLSharpRuntime.SysErr
                     ("getRoundingMode: unknown rounding mode", NONE)
      end

  fun toString {class, sign, digits, exp} =
      let
        fun digitsToString () =
            let
              val digits = map SMLSharpScanChar.intToDigit digits
              val str = #"0" :: #"." :: digits
              val str = if sign then #"~" :: str else str
              val str = implode str
            in
              if exp = 0 then str else str ^ "E" ^ Int.toString exp
            end
      in
        case class of
          ZERO => if sign then "~0.0" else "0.0"
        | INF => if sign then "~inf" else "inf"
        | NAN => if sign then "~nan" else "nan"
        | NORMAL => digitsToString ()
        | SUBNORMAL => digitsToString ()
      end

  fun toLower NONE = NONE
    | toLower (SOME (c, strm)) = SOME (Char.toLower c, strm)

  fun scanInf sign getc strm =
      case toLower (getc strm) of
        SOME (#"n", strm) =>
        (case toLower (getc strm) of
           SOME (#"a", strm) =>
           (case toLower (getc strm) of
              SOME (#"n", strm) =>
              SOME ({class=NAN, sign=sign, digits=nil, exp=0}, strm)
            | _ => NONE)
         | _ => NONE)
      | SOME (#"i", strm) =>
        (case toLower (getc strm) of
           SOME (#"n", strm) =>
           (case toLower (getc strm) of
              SOME (#"f", strm) =>
              let
                val strm =
                    case toLower (getc strm) of
                      SOME (#"i", strm2) =>
                      (case toLower (getc strm2) of
                         SOME (#"n", strm2) =>
                         (case toLower (getc strm2) of
                            SOME (#"i", strm2) =>
                            (case toLower (getc strm2) of
                               SOME (#"t", strm2) =>
                               (case toLower (getc strm2) of
                                  SOME (#"y", strm2) => strm2
                                | _ => strm)
                             | _ => strm)
                          | _ => strm)
                       | _ => strm)
                    | _ => strm
              in
                SOME ({class=INF, sign=sign, digits=nil, exp=0}, strm)
              end
            | _ => NONE)
         | _ => NONE)
      | _ => NONE

  fun scanSign getc strm =
      case getc strm of
        SOME (#"+", strm) => (false, strm)
      | SOME (#"~", strm) => (true, strm)
      | SOME (#"-", strm) => (true, strm)
      | _ => (false, strm)

  fun scanDigits getc strm =
      case SMLSharpScanChar.scanRepeat1 SMLSharpScanChar.scanDigit getc strm of
        NONE => (nil, strm)
      | SOME x => x

  fun removeLeadingZeroes (0::t) = removeLeadingZeroes t
    | removeLeadingZeroes l = l

  fun removeTrailingZeroes nil = nil
    | removeTrailingZeroes (h::t) =
      case (h, removeTrailingZeroes t) of (0, nil) => nil | (h, t) => h::t

  (* ToDo: overflow *)
  fun toInt (sign, digits) =
      let
        val n = foldl (fn (x,z) => z * 10 + x) 0 digits
      in
        if sign then ~n else n
      end

  fun scanExp getc strm =
      case toLower (getc strm) of
        SOME (#"e", strm) =>
        let
          val (sign, strm) = scanSign getc strm
        in
          case scanDigits getc strm of
            (nil, strm) => (0, strm)
          | (digits, strm) => (toInt (sign, digits), strm)
        end
      | _ => (0, strm)

  fun scan getc strm =
      let
        val strm = SMLSharpScanChar.skipSpaces getc strm
        val (sign, strm) = scanSign getc strm
      in
       case scanInf sign getc strm of
          SOME (x, strm) => SOME (x, strm)
        | NONE =>
          let
            (* scan ([0-9]+(\.[0-9]+)?|\.[0-9]+)([eE][+~-]?[0-9]* )? *)
            val (il, strm) = scanDigits getc strm
            val (fl, strm) =
                case getc strm of
                  SOME (#".", strm) => scanDigits getc strm
                | _ => (nil, strm)
          in
            case (il, fl) of
              (nil, nil) => NONE
            | _ =>
              let
                val (exp, strm) = scanExp getc strm
              in
                case (removeLeadingZeroes il, removeTrailingZeroes fl) of
                  (il as _::_, fl) =>
                  SOME ({class = NORMAL, sign = sign,
                         digits = removeTrailingZeroes (il @ fl),
                         exp = exp + length il}, strm)
                | (nil, nil) =>
                  SOME ({class=ZERO, sign=sign, digits=nil, exp=0}, strm)
                | (nil, fl) =>
                  let
                    val len = length fl
                    val fl' = removeLeadingZeroes fl
                  in
                    SOME ({class = NORMAL, sign = sign, digits = fl',
                           exp = exp - (len - length fl')}, strm)
                  end
              end
          end
      end

  fun fromString str =
      StringCvt.scanString scan str

end
