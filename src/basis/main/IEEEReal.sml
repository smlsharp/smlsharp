(**
 * IEEEReal
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 7 * / div mod
infix 6 + - ^
infixr 5 :: @
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int32.add_unsafe
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op > = SMLSharp_Builtin.Int32.gt
val op ~ = SMLSharp_Builtin.Int32.neg
val op ^ = String.^
val op @ = List.@

structure IEEEReal =
struct

  datatype real_order = LESS | EQUAL | GREATER | UNORDERED
  datatype float_class = NAN | INF | ZERO | NORMAL | SUBNORMAL
  datatype rounding_mode = TO_NEAREST | TO_NEGINF | TO_POSINF | TO_ZERO
  type decimal_approx =
      {class : float_class, sign : bool, digits : int list, exp : int}

  exception Unordered

  val fesetround =
      _import "prim_fesetround"
      : __attribute__((fast)) int -> int
  val fegetround =
      _import "prim_fegetround"
      : __attribute__((pure,fast)) () -> int

  val FE_TONEAREST =
      _import "prim_const_FE_TONEAREST"
      : __attribute__((pure,fast)) () -> int
  val FE_DOWNWARD =
      _import "prim_const_FE_DOWNWARD"
      : __attribute__((pure,fast)) () -> int
  val FE_UPWARD =
      _import "prim_const_FE_UPWARD"
      : __attribute__((pure,fast)) () -> int
  val FE_TOWARDZERO =
      _import "prim_const_FE_TOWARDZERO"
      : __attribute__((pure,fast)) () -> int

  fun setRoundingMode roundingMode =
      let
        val mode =
            case roundingMode of
              TO_NEAREST => FE_TONEAREST ()
            | TO_NEGINF => FE_DOWNWARD ()
            | TO_POSINF => FE_UPWARD ()
            | TO_ZERO => FE_TOWARDZERO ()
        val err = fesetround mode
      in
        if err = 0 then () else raise SMLSharp_Runtime.OS_SysErr ()
      end

  fun getRoundingMode () =
      let
        val mode = fegetround ()
      in
        if mode = FE_TONEAREST () then TO_NEAREST
        else if mode = FE_DOWNWARD () then TO_NEGINF
        else if mode = FE_UPWARD () then TO_POSINF
        else if mode = FE_TOWARDZERO () then TO_ZERO
        else raise SMLSharp_Runtime.SysErr
                     ("getRoundingMode: unknown rounding mode", NONE)
      end

  fun toString {class, sign, digits, exp} =
      let
        fun digitsToString () =
            let
              val digits = List.map SMLSharp_ScanChar.intToDigit digits
              val str = #"0" :: #"." :: digits
              val str = if sign then #"~" :: str else str
              val str = String.implode str
            in
              if exp = 0 then str else str ^ "E" ^ Int32.toString exp
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

  fun removeLeadingZeroes (0::t) = removeLeadingZeroes t
    | removeLeadingZeroes l = l

  fun removeTrailingZeroes nil = nil
    | removeTrailingZeroes (h::t) =
      case (h, removeTrailingZeroes t) of (0, nil) => nil | (h, t) => h::t

  fun toInt (sign, digits) =
      let
        val op + = SMLSharp_Builtin.Int32.add
        val op - = SMLSharp_Builtin.Int32.sub
        val op * = SMLSharp_Builtin.Int32.mul
        fun posloop z nil = z
          | posloop z (h::t) = posloop (z * 10 + h) t
        fun negloop z nil = z
          | negloop z (h::t) = negloop (z * 10 - h) t
      in
        if sign then negloop 0 digits else posloop 0 digits
      end

  (* ([0-9]+(\.[0-9]+)?|\.[0-9]+)([eE][+~-]?[0-9]* )? *)
  fun scan getc strm =
      let
        val strm = SMLSharp_ScanChar.skipSpaces getc strm
        val (sign, strm) = SMLSharp_ScanChar.scanSign getc strm
      in
        case scanInf sign getc strm of
          SOME (x, strm) => SOME (x, strm)
        | NONE =>
          case SMLSharp_ScanChar.scanMantissa getc strm of
            NONE => NONE
          | SOME ((il, fl), strm) =>
            let
              val (exp, strm) =
                  case SMLSharp_ScanChar.scanExponent getc strm of
                    NONE => (0, strm)
                  | SOME (x, strm) => (toInt x, strm)
            in
              case (removeLeadingZeroes il, removeTrailingZeroes fl) of
                (il as _::_, fl) =>
                SOME ({class = NORMAL, sign = sign,
                       digits = removeTrailingZeroes (il @ fl),
                       exp = exp + List.length il}, strm)
              | (nil, nil) =>
                SOME ({class=ZERO, sign=sign, digits=nil, exp=0}, strm)
              | (nil, fl) =>
                let
                  val len = List.length fl
                  val fl' = removeLeadingZeroes fl
                in
                  SOME ({class = NORMAL, sign = sign, digits = fl',
                         exp = exp - (len - List.length fl')}, strm)
                end
            end
      end

  fun fromString str =
      StringCvt.scanString scan str

end
