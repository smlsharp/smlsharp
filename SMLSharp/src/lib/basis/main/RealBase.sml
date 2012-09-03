(**
 * generator of Real structures.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Real64.sml,v 1.6 2008/01/16 08:17:46 kiyoshiy Exp $
 *)
functor RealBase
        ((** basic operations on real. *)
         B
         : sig
             type real
             type largeReal

             (** 0.0 *)
             val zero : real
             (** 0.5 *)
             val half : real
             (** 1.0 *)
             val one : real
             (** ~1.0 *)
             val negative_one : real

             val add : real * real -> real
             val sub : real * real -> real
             val mul : real * real -> real
             val div : real * real -> real

             val precision : int
             val maxFinite : real
             val minPos : real
             val minNormalPos : real
             val posInf : real
             val negInf : real
             val nan : real
             val fromInt : int -> real
             val toLarge : real -> largeReal
             val fromLarge: IEEEReal.rounding_mode -> largeReal -> real
             val toString : real -> string
             val floor : real -> int
             val ceil : real -> int
             val trunc : real -> int
             val round : real -> int
             val split : real -> real * real
             val toManExp : real -> real * int
             val fromManExp : real * int -> real
             val nextAfter : real * real -> real
             val copySign : real * real -> real
             val equal : real * real -> bool
             val class : real -> int
             val dtoa : (real * int) -> string * int
             val strtod : string -> real

             (** compare floating-points other than nan. *)
             val compareNormal : real * real -> General.order

             structure Math : MATH sharing type real = Math.real
           end) =
struct

  (***************************************************************************)

  type real = B.real

  (***************************************************************************)

  structure Math = B.Math
  structure IR = IEEEReal
  structure S = String
  structure SS = Substring

  (***************************************************************************)

  val radix = 2

  val precision = B.precision

  val maxFinite = B.maxFinite
  val minPos = B.minPos
  val minNormalPos = B.minNormalPos

  (* ToDo : which definition is correct ? *)
  val posInf = B.posInf
  val negInf = B.negInf
  val nan = B.nan

  (********************)
  (* classification *)

  local
    (* Following constants are defined in
     *    src/runtime/runtime-core/main/SystemDef.hh
     * 
     * 0 FP_SNAN signaling NaN
     * 1 FP_QNAN quiet NaN
     * 2 FP_NINF negative infinity
     * 3 FP_PINF positive infinity
     * 4 FP_NDENORM negative denormalized non-zero
     * 5 FP_PDENORM positive denormalized non-zero
     * 6 FP_NZERO negative zero
     * 7 FP_PZERO positive zero
     * 8 FP_NNORM negative normalized non-zero
     * 9 FP_PNORM positive normalized non-zero
     *)
    datatype internal_class = 
             FP_SNAN
           | FP_QNAN
           | FP_NINF
           | FP_PINF
           | FP_NDENORM
           | FP_PDENORM
           | FP_NZERO
           | FP_PZERO
           | FP_NNORM
           | FP_PNORM

    fun internalClass real =
        case B.class real of
          0 => FP_SNAN
        | 1 => FP_QNAN
        | 2 => FP_NINF
        | 3 => FP_PINF
        | 4 => FP_NDENORM
        | 5 => FP_PDENORM
        | 6 => FP_NZERO
        | 7 => FP_PZERO
        | 8 => FP_NNORM
        | 9 => FP_PNORM
        | _ => raise Fail "bug: unexpected return value of Real_class"
  in
  fun class real =
      case internalClass real of
        FP_SNAN => IR.NAN
      | FP_QNAN => IR.NAN
      | FP_NINF => IR.INF
      | FP_PINF => IR.INF
      | FP_NDENORM => IR.SUBNORMAL
      | FP_PDENORM => IR.SUBNORMAL
      | FP_NZERO => IR.ZERO
      | FP_PZERO => IR.ZERO
      | FP_NNORM => IR.NORMAL
      | FP_PNORM => IR.NORMAL

  fun isFinite real =
      case class real of IR.INF => false | IR.NAN => false |_ => true

  fun isInf real = case class real of IR.INF => true | _ => false

  fun isNan real = case class real of IR.NAN => true | _ => false

  fun isNormal real = case class real of IR.NORMAL => true | _ => false

  fun sign real = 
      case internalClass real of
        FP_SNAN => raise General.Domain
      | FP_QNAN => raise General.Domain
      | FP_NINF => ~1
      | FP_PINF => 1
      | FP_NDENORM => ~1
      | FP_PDENORM => 1
      | FP_NZERO => 0
      | FP_PZERO => 0
      | FP_NNORM => ~1
      | FP_PNORM => 1

  fun signBit real =
      case internalClass real of
        FP_NINF => true
      | FP_NDENORM => true
      | FP_NZERO => true
      | FP_NNORM => true

      (* We cannot depend on internalClass to get the sign of nan.
       * So, we copy the sign of nan to 1.0, and get the copied sign.
       * 
       * FIXME: It is better to add 'Real_signBit' and 'Float_signBit'
       * primitives in the runtime and use them to get the sign of floats and
       * reals. *)
      | FP_SNAN => signBit (B.copySign (B.one, real))
      | FP_QNAN => signBit (B.copySign (B.one, real))

      | _ => false

  fun sameSign (left, right) = (signBit left) = (signBit right)

  val copySign = B.copySign

  end

  (********************)
  (* comparison operators *)

  fun unordered (left, right) = isNan left orelse isNan right

  fun compare (left, right) =
      if unordered (left, right)
      then raise IR.Unordered
      else B.compareNormal (left, right)

  fun compareReal (left, right) = 
      (case compare (left, right) of
         General.LESS => IR.LESS
       | General.EQUAL => IR.EQUAL
       | General.GREATER => IR.GREATER)
      handle IR.Unordered => IR.UNORDERED

  fun op < (left, right) =
      if isNan left orelse isNan right
      then false
      else case compare (left, right) of General.LESS => true | _ => false
  fun op <= (left, right) =
      if isNan left orelse isNan right
      then false
      else case compare (left, right) of General.GREATER => false | _ => true
  fun op > (left, right) =
      if isNan left orelse isNan right then false else not (left <= right)
  fun op >= (left, right) =
      if isNan left orelse isNan right then false else not (left < right)

  fun min (left, right) =
      case (isNan left, isNan right)
       of (true, _) => right
        | (_, true) => left
        | (false, false) => if left < right then left else right
  fun max (left, right) =
      case (isNan left, isNan right)
       of (true, _) => right
        | (_, true) => left
        | (false, false) => if left < right then right else left

  local
    val equal = B.equal
  in
  fun == (left, right) =
      if isNan left orelse isNan right
      then false
      else equal (left, right)
  fun != x = not (op == x)

  fun ?= (left, right) =
      if isNan left orelse isNan right
      then true
      else equal (left, right)
  end

  (********************)
  (* arithmetics *)

  val op + = fn (left, right) => B.add (left, right)

  val op - = fn (left, right) => B.sub (left, right)

  val op * = fn (left, right) => B.mul (left, right)

  val op / = fn (left, right) => B.div (left, right)

  (* rem is defined later for dependency reason. *)

  fun *+ (r1, r2, r3) = r1 * r2 + r3
  fun *- (r1, r2, r3) = r1 * r2 - r3

  fun ~ real = real * B.negative_one

  fun abs real = copySign (real, B.one)

  (********************)
  (* composition/decomposition *)

  fun toManExp real =
      let val (man, exp) = B.toManExp real
      in {man = man, exp = exp}
      end

  fun fromManExp {man, exp} = B.fromManExp (man, exp)

  fun split real =
      let val (whole, frac) = B.split real
      in {whole = whole, frac = frac}
      end

  fun realMod x = #frac (split x)

  fun nextAfter (left, right) =
      if isInf left then left
      else if isNan left then left
      else if isNan right then right
      else B.nextAfter (left, right)

  (********************)
  (* conversions *)

  fun checkFloat real =
      case class real of
        IR.INF => raise General.Overflow
      | IR.NAN => raise General.Div (* Domain? This is a bug of Basis spec? *)
      | _ => real

  local
    val maxInt = B.fromInt (valOf Int.maxInt)
    val maxInt_05 = maxInt + B.half
    val maxInt_1 = maxInt + B.one
    val minInt = B.fromInt (valOf Int.minInt)
    val minInt_05 = minInt - B.half
    val minInt_1 = minInt - B.one
    fun check real =
        case class real of
          IR.INF => raise General.Overflow
        | IR.NAN => raise General.Domain (* not Div as checkFloat *)
        | _ => ()
  in
  fun floor real =
      (
        check real;
        if real < minInt orelse maxInt_1 <= real
        then raise Overflow
        else B.floor real
      )
  fun ceil real =
      (
        check real;
        if real <= minInt_1 orelse maxInt < real
        then raise Overflow
        else B.ceil real
      )
  fun trunc real = 
      (
        check real;
        if real <= minInt_1 orelse maxInt_1 <= real
        then raise Overflow
        else B.trunc real
      )
  fun round real = 
      (
        check real;
        if real <= minInt_05 orelse maxInt_05 <= real
        then raise Overflow
        else B.round real
      )
  fun toInt mode real =
      case mode
       of IR.TO_NEGINF => floor real
        | IR.TO_POSINF => ceil real
        | IR.TO_ZERO => trunc real
        | IR.TO_NEAREST => round real
  end

  val fromInt = B.fromInt

  (* toLargeInt and fromLargeInt are defined later for dependency reason. *)

  val toLarge = B.toLarge
  val fromLarge = B.fromLarge

  fun isZero real = class real = IR.ZERO
  local
    fun ifNonZeroFinite f real =
        case class real of
          IR.NORMAL => f real
        | IR.SUBNORMAL => f real
        | _ => real
    fun whole x = #whole (split x)
    val frac = realMod
  in
  (*
   * We cannot use floor to implement realFloor because, if the argument is
   * too big, the former may raise overflow but the latter should not raise.
   *)
  fun realFloor x =
      ifNonZeroFinite
      (fn real =>
          if B.zero < real
          then whole real (* 1.4 ==> 1.0 *)
          else
            if isZero (frac real)
            then whole real (* -1.0 ==> -1.0 *)
            else (whole real) - B.one) (* -1.2 ==> -2.0 *)
      x
  fun realCeil x =
      ifNonZeroFinite
      (fn real =>
          if real < B.zero
          then whole real (* -1.4 ==> -1.0 *)
          else
            if isZero (frac real)
            then whole real (* 1.0 ==> 1.0 *)
            else (whole real) + B.one) (* 1.2 ==> 2.0 *)
      x
  fun realTrunc x = ifNonZeroFinite (fn real => whole real) x
  fun realRound x = 
      ifNonZeroFinite
          (fn real =>
              whole (if real < B.zero then real - B.half else real + B.half))
          x

  end (* local *)

  fun rem (left, right) =
      if isInf left orelse isZero right
      then nan
      else if isInf right
      then left
      else left - (realTrunc(left / right) * right)

  (********************)
  (* conversion between IEEEReal.decimal_approx *)

  local
    structure PC = ParserComb
    exception NotNumChar
    fun charOfNum num = 
        case num of
          0 => #"0"
        | 1 => #"1"
        | 2 => #"2"
        | 3 => #"3"
        | 4 => #"4"
        | 5 => #"5"
        | 6 => #"6"
        | 7 => #"7"
        | 8 => #"8"
        | 9 => #"9"
        | _ => raise NotNumChar

    fun numOfChar char =
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
        | _ => raise Fail "bug: Real.numOfChar"

  in

  fun toDecimal r =
      let
        val class = class r
        val sign = signBit r
        (* toDecimal should handle SUBNORMAL as NORMAL also. *)
        val isNormal =
            case class
             of IR.NORMAL => true
              | IR.SUBNORMAL => true
              | _ => false
      in
        if isNormal
        then
          let
            val (str, exp) = B.dtoa (abs r, 0)
            val chars = String.explode str
            val digits = List.map numOfChar chars
          in
            {class = class, sign = sign, digits = digits, exp = exp}
          end
        else {class = class, sign = sign, digits = [], exp = 0}
      end

  (* sign * 0.d[1]d[2]...d[n] * 10 ^ exp *)
  fun fromDecimal ({class, sign, digits, exp} : IR.decimal_approx) =
      case class of
        IR.NAN => SOME nan
      | IR.INF => SOME(if sign then negInf else posInf)
      | IR.ZERO => SOME(if sign then B.negative_one * B.zero else B.zero)
      | _ =>
        let
          val string =
              String.implode (#"0" :: #"." :: List.map charOfNum digits)
          val string = if sign then "~" ^ string else string
          val string = string ^ "E" ^ Int.toString exp
        in
          SOME (B.strtod string)
        end
          handle NotNumChar => NONE

  (********************)
  (* conversion between LargeInt.int *)

  local
    val (op +) = IntInf.+
    val (op -) = IntInf.-
    val (op * ) = IntInf.*
    val (op <) = IntInf.<
    (* builds an integer from first 'exp' digits.
     * It returns the built integer and the (exp+1)th digit.
     * If digits has less than 'exp' elements, fills with 0.
     * Example:
     *   digitsToInt 0 3 [1, 2, 3, 4] = (123, 4)
     *   digitsToInt 0 4 [1, 2, 3, 4] = (1234, 0)
     *   digitsToInt 0 5 [1, 2, 3, 4] = (12340, 0)
     * @params accum exp digits
     *)
    fun digitsToInt accum 0 (frac :: _) = (accum : IntInf.int, frac)
      | digitsToInt accum 0 [] = (accum, 0)
      | digitsToInt accum exp (int :: remains) =
        digitsToInt (accum * 10 + IntInf.fromInt int) (Int.-(exp, 1)) remains
      | digitsToInt accum exp [] = digitsToInt (accum * 10) (Int.-(exp, 1)) []
  in
  fun toLargeInt mode real =
      let val {class, sign, digits, exp} = toDecimal real
      in
        case class
         of IR.NAN => raise General.Domain
          | IR.INF => raise General.Overflow
          | IR.ZERO => 0
          | _ =>
            if Int.< (exp, ~1)
            then 0
            else 
              let
                val signNum = if sign then ~1 else 1
                val (whole, frac) = digitsToInt 0 exp digits
                val whole =
                    case mode
                     of IR.TO_NEAREST =>
                        if Int.< (frac, 5) then whole else whole + 1
                      | IR.TO_NEGINF =>
                        if sign andalso Int.<(0, frac)
                        then whole + 1
                        else whole
                      | IR.TO_POSINF =>
                        if sign orelse 0 = frac then whole else whole + 1
                      | IR.TO_ZERO => whole
              in
                signNum * whole
              end
      end
  end (* local *)

  (* ToDo : It is better to use mpz_get_d of GMP. *)
  fun fromLargeInt int = B.strtod (IntInf.toString int)

  (********************)
  (* conversion between String.string *)

  local

    val emptySS = SS.full ""
    fun zeros num = (CharVector.tabulate (num, fn _ => #"0"))
    fun signToString real =
        (if ~1 = sign real then "~" else "")
        handle General.Domain => "" (* if real is nan. *)
    fun splitAt (string, i) =
        let val (l, r) = SS.splitAt (SS.full string, i)
        in (SS.string l, SS.string r)
        end
    (* We interpret here a real value r is
     *   r = 0.ddd.. * 10^exp
     * For example, 
     *   exp(10.0)=2, exp(12.0)=2, exp(0.01)=~1, exp(0.012)=~1
     * This is equal to the second component of the return value of
     * B.dtoa, which is implemented by GMP mpf_get_str.
     *)
    fun dtoa real =
        let
          val (digits, exp) = B.dtoa (real, 0)
          (* removes a minus sign. *)
          val digits =
              if 0 = S.size digits orelse S.sub (digits, 0) <> #"~"
              then SS.full digits
              else #2(SS.splitAt (SS.full digits, 1))
        in (digits, exp) end

    (* convert to scientific representation.
     *  [~]?[0-9].[0-9]+?E[0-9]+
     *)
    fun fmtSCI zeroTrail maxFrac (real, digits, exp) =
        let
          (* splits digits to whole part and fraction part. *)
          val (whole, frac) =
              if SS.isEmpty digits
              then (SS.full "0", emptySS)
              else SS.splitAt (digits, 1)
          (* adjusts the length of frac to maxFrac. *)
          val frac =
              if Int.< (SS.size frac, maxFrac)
              then (* frac is shorter than maxFrac *)
                if zeroTrail
                then (* appends 0s *)
                  SS.full
                      (SS.string frac ^ zeros (Int.-(maxFrac, SS.size frac)))
                else frac
              else
                (* takes first maxFrac digits from frac. *)
                #1(SS.splitAt (frac, maxFrac))
          val sign = if signBit real then SS.full "~" else emptySS
          val exp =
              SS.full
                  (if isZero real
                   then "E0"
                   else "E" ^ Int.toString (Int.-(exp, 1)))
        in
          SS.concat
              (sign
               :: whole
               :: (if SS.isEmpty frac then [] else [SS.full ".", frac])
               @ [exp])
        end
              
    (* convert to fixed-point representation
     *  [~]?[0-9]+.[0-9]+?
     *)
    fun fmtFIX zeroTrail maxFrac (real, digits, exp) =
        let
          val (whole, frac) =
              if Int.<(0, exp)
              then
                if Int.<(exp, SS.size digits)
                then
                  (* splits digits to whole part and fraction part. *)
                  SS.splitAt (digits, exp)
                else
                  (* digits are all in whole part. *)
                  (* appends 0s to whole part. *)
                  let val tail = zeros (Int.-(exp, SS.size digits))
                  in (SS.full (SS.concat[digits, SS.full tail]), emptySS) end
              else
                (* digits are all in fraction part. *)
                if SS.isEmpty digits orelse Int.<= (maxFrac, Int.~ exp)
                then (* no digits *) (emptySS, emptySS)
                else
                  (* prepends 0s to fraction part. *)
                  let val head = SS.full (zeros (Int.~ exp))
                  in (emptySS, SS.full (SS.concat[head, digits])) end
          val whole = if SS.isEmpty whole then SS.full "0" else whole
          (* adjusts the length of fraction part. *)
          val frac =
              if Int.<(maxFrac, SS.size frac)
              then
                (* truncates trailing digits beyond maxFrac. *)
                #1(SS.splitAt(frac, maxFrac))
              else 
                (* appends 0s if necessary. *)
                if zeroTrail
                then
                  let val tail = SS.full (zeros (Int.-(maxFrac, SS.size frac)))
                  in SS.full(SS.concat [frac, tail]) end
                else frac
          val sign = if signBit real then SS.full "~" else emptySS
        in
          SS.concat
              (sign
               :: whole
               :: (if SS.isEmpty frac then [] else [SS.full ".", frac]))
        end

    fun fmtEXACT (real, digits, exp) =
        (if signBit real then "~" else "")
        ^ "0." ^ SS.string digits
        ^ "E" ^ Int.toString exp

    fun fmtUnsafe mode real =
        case (mode, class real) of
          (_, IR.INF) => signToString real ^ "inf"
        | (_, IR.NAN) => signToString real ^ "nan"
        | (StringCvt.GEN maxDigitsOpt, _) =>
          let
            val maxDigits = getOpt (maxDigitsOpt, 12)
            val (digits, exp) = dtoa real
            (* truncates digits beyond maxDigits. *)
            val digits =
                if Int.<(maxDigits, SS.size digits)
                then #1(SS.splitAt (digits, maxDigits))
                else digits
            (* truncates trailing zeros. *)
            val digits = SS.dropr (fn ch => ch = #"0") digits
            (* precision *)
            val maxFracSCI = Int.-(maxDigits, 1)
            val maxFracFIX = Int.max(0, Int.-(maxDigits, exp))
            (* GEN is almostly same to FIX or SCI, but does not allow trailing
             * zeros. *)
            val fix = fmtFIX false maxFracFIX (real, digits, exp)
            val sci = fmtSCI false maxFracSCI (real, digits, exp)
          in
            if Int.<=(S.size fix, S.size sci) then fix else sci
          end
        | (StringCvt.SCI maxFracOpt, _) =>
          let
            val maxFrac = getOpt (maxFracOpt, 6)
            val (digits, exp) = dtoa real
          in fmtSCI true maxFrac (real, digits, exp)
          end
        | (StringCvt.FIX maxFracOpt, _) =>
          let
            val maxFrac = getOpt (maxFracOpt, 6)
            val (digits, exp) = dtoa real
          in fmtFIX true maxFrac (real, digits, exp)
          end
        | (StringCvt.EXACT, _) =>
          let val (digits, exp) = dtoa real in fmtEXACT (real, digits, exp) end

  in
  (* Basis spec specifies that Size exception should be raised when fmt is
   * applied to the first argument of invalid value. *)
  fun fmt mode =
      (
        case mode
         of StringCvt.GEN (SOME maxDigit) =>
            if Int.<(maxDigit, 1) then raise General.Size else ()
          | StringCvt.SCI (SOME maxFrac) =>
            if Int.<(maxFrac, 0) then raise General.Size else ()
          | StringCvt.FIX (SOME maxFrac) =>
            if Int.<(maxFrac, 0) then raise General.Size else ()
          | _ => ();
        fmtUnsafe mode
      )
  end

  fun toString real = fmt (StringCvt.GEN NONE) real

  fun scan reader stream =
      PC.bind
          (
            IR.scan,
            fn digits =>
               case fromDecimal digits
                of SOME r => PC.result r
                 | NONE => PC.failure
          )
          reader stream
  fun fromString x = StringCvt.scanString scan x

  end

  (***************************************************************************)

end
