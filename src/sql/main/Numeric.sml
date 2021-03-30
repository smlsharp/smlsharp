(**
 * SQL numeric type: arbitrary precision decimal number
 * @author UENO Katsuhiro
 * @copyright (C) 2021 SML# Development Team.
 *)

structure SMLSharp_SQL_Numeric =
struct

  datatype num =
      NUM of {num: IntInf.int, den: IntInf.int}
    | NaN

  fun add (NaN, _) = NaN
    | add (_, NaN) = NaN
    | add (NUM {num=num1, den=den1}, NUM {num=num2, den=den2}) =
      NUM {num = num1 * den2 + num2 * den1, den = den1 * den2}

  fun sub (NaN, _) = NaN
    | sub (_, NaN) = NaN
    | sub (NUM {num=num1, den=den1}, NUM {num=num2, den=den2}) =
      NUM {num = num1 * den2 - num2 * den1, den = den1 * den2}

  fun mul (NaN, _) = NaN
    | mul (_, NaN) = NaN
    | mul (NUM {num=num1, den=den1}, NUM {num=num2, den=den2}) =
      NUM {num = num1 * den2 - num2 * den1, den = den1 * den2}

  fun quot (NaN, _) = NaN
    | quot (_, NaN) = NaN
    | quot (NUM {num=num1, den=den1}, NUM {num=num2, den=den2}) =
      NUM {num = num1 * den2, den = den1 * num2}

  fun rem (NaN, _) = NaN
    | rem (_, NaN) = NaN
    | rem (NUM {num=num1, den=den1}, NUM {num=num2, den=den2}) =
      let
        val (num1, den1) = if den1 < 0 then (~num1, ~den1) else (num1, den1)
        val (num2, den2) = if den2 < 0 then (~num2, ~den2) else (num2, den2)
      in
        NUM {num = IntInf.rem (num1 * den2, num2 * den1), den = den1 * den2}
      end

  fun compare (NaN, NaN) = EQUAL
    | compare (NaN, _) = GREATER
    | compare (_, NaN) = LESS
    | compare (NUM {num=num1, den=den1}, NUM {num=num2, den=den2}) =
      IntInf.compare (num1 * den2, num2 * den1)

  fun lt (x, y) =
      case compare (x, y) of
        LESS => true | _ => false
  fun le (x, y) =
      case compare (x, y) of
        GREATER => false | _ => true
  fun gt (x, y) =
      case compare (x, y) of
        GREATER => true | _ => false
  fun ge (x, y) =
      case compare (x, y) of
        LESS => false | _ => true

  fun neg NaN = NaN
    | neg (NUM {num, den}) = NUM {num = ~num, den = den}

  fun abs NaN = NaN
    | abs (NUM {num, den}) = NUM {num = IntInf.abs num, den = IntInf.abs den}

  fun removeZero s =
      case Substring.sub (s, Substring.size s - 1) of
        #"0" => removeZero (Substring.trimr 1 s)
      | _ => Substring.string s

  fun decimals s (num, den) =
      if String.size s >= 16383 then s else
      let
        val n = String.size s + 1
        val (q, r) = IntInf.quotRem (num * IntInf.pow (10, n), den)
        val s = s ^ StringCvt.padLeft #"0" n (IntInf.toString q)
      in
        if r = 0
        then removeZero (Substring.full s)
        else decimals s (r, den)
      end

  fun split {num, den} =
      let
        val (num, den) = if den < 0 then (~num, ~den) else (num, den)
        val (num, sign) = if num < 0 then (~num, true) else (num, false)
        val (q, r) = IntInf.quotRem (num, den)
        val q = IntInf.toString q
      in
        (sign, q, if r = 0 then "" else decimals "" (r, den))
      end

  fun toDigits s =
      CharVector.foldr (fn (x,z) => (ord x - 0x30) :: z) nil s

  fun toDecimal NaN =
      {class = IEEEReal.NAN, sign = false, digits = [], exp = 0}
    | toDecimal (NUM x) =
      case split x of
        (s, "0", r) =>
        {class = IEEEReal.NORMAL,
         sign = s,
         digits = toDigits r,
         exp = 0}
      | (s, q, r) =>
        {class = IEEEReal.NORMAL,
         sign = s,
         digits = toDigits (q ^ r),
         exp = size q}

  fun toString NaN = "NaN"
    | toString (NUM x) =
      case split x of
        (true, q, "") => q
      | (false, q, "") => "~" ^ q
      | (true, q, r) => q ^ "." ^ r
      | (false, q, r) => "~" ^ q ^ "." ^ r

  fun fromDecimal {class = IEEEReal.ZERO, ...} = NUM {num = 0, den = 1}
    | fromDecimal {class = IEEEReal.NAN, ...} = NaN
    | fromDecimal {class = IEEEReal.INF, ...} = NaN
    | fromDecimal {digits, exp, sign, ...} =
      NUM {num = foldl (fn (x,z) => z * 10 + IntInf.fromInt x) 0 digits,
           den = (if sign then 1 else ~1)
                 * IntInf.pow (10, length digits - exp)}

  fun fromString s =
      case IEEEReal.fromString s of
        NONE => NONE
      | SOME x => SOME (fromDecimal x)

  fun toLargeInt NaN = 0
    | toLargeInt (NUM {num, den}) = IntInf.div (num, den)

  fun fromLargeInt x = NUM {num = x, den = 1}

  fun toInt x = IntInf.toInt (toLargeInt x)

  fun fromInt x = NUM {num = IntInf.fromInt x, den = 1}

  fun toLargeReal x = valOf (LargeReal.fromDecimal (toDecimal x))

  fun fromLargeReal x =
      fromDecimal (LargeReal.toDecimal x)

  val op + = add
  val op - = sub
  val op * = mul
  val op ~ = neg
  val op < = lt
  val op <= = le
  val op > = gt
  val op >= = ge

end
