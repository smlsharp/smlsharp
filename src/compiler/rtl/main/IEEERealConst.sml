functor IEEERealConst (
  val manBits : int
  val expBits : int
) : sig

  val fromString : string -> {man: IntInf.int, exp: word, sign: bool} option
  val pack : {man: IntInf.int, exp: word, sign: bool}
             -> Word32.word * Word32.word

end =
struct

  (*
   * IEEE 754 floating point number format:
   *
   * let sign be an 1 bit unsigned integer,
   *     exp be an expBits-bit unsigned integer, and
   *     man be a (manBits-1)-bit unsigned integer.
   * let expMax = 2^(expBits-1) - 1.
   *
   *   if 1 <= exp <= 2^expBits - 2,
   *     r = (-1)^sign * 2^(exp - expMax) * (1 + man / 2^(manBits-1))
   *
   *   if exp = 0,
   *     r = (-1)^sign * 2^(1 - expMax) * (man / 2^manBits)
   *
   *   if exp = 2^expBits - 1 and man = 0, then it denotes (-1)^sign * inf
   *   if exp = 2^expBits - 1 and man <> 0, then it denotes NaN
   *
   * Real64 = {expBits = 11, manBits = 53}
   * Real32 = {expBits = 8,  manBits = 24}
   *
   * See
   *   Clinger, William D. How to read floating point numbers accurately.
   *   In Proceedings of PLDI 90, pp. 92--101, 1990.
   * for details of the algorithm.
   *)

  val manLimit = IntInf.pow (2, manBits)
  val manMax = manLimit - 1
  val manMSB = IntInf.pow (2, manBits - 1)
  val expLimit = Word.<< (0w1, Word.fromInt expBits)
  val expInf = expLimit - 0w1
  val expMax = Word.toInt (expLimit div 0w2 - 0w1)

  type float = {man: IntInf.int, exp: int}

  fun tos {man, exp} =
      IntInf.fmt StringCvt.HEX man ^ "E" ^ Int.toString exp

  fun nextfloat {man, exp} =
      if man = manMax
      then {man = manMSB, exp = exp + 1}
      else {man = man + 1, exp = exp}

  fun ratioToFloat (u, v, k) =
      let
        val (q, r) = IntInf.quotRem (u, v)
        val z = {man = q, exp = k}
      in
        if r < v - r then z
        else if r > v - r then nextfloat z
        else if q mod 2 = 1 then z
        else nextfloat z
      end

  fun algorithmM {man=f, exp=e} =
      let
        fun loop (u, v, k) =
            let
              val x = IntInf.quot (u, v)
            in
              if manMSB <= x andalso x < manLimit
              then ratioToFloat (u, v, k)
              else if x < manMSB
              then loop (2 * u, v, k - 1)
              else loop (u, 2 * v, k + 1)
            end
      in
        if e < 0
        then loop (f, IntInf.pow (10, ~e), 0)
        else loop (f * IntInf.pow (10, e), 1, 0)
      end

  fun fromString str =
      case IEEEReal.fromString str of
        NONE => NONE
      | SOME {class=IEEEReal.NAN, ...} =>
        SOME {man = 0, exp = expInf, sign = false}
      | SOME {class=IEEEReal.INF, sign, ...} =>
        SOME {man = 0, exp = expInf, sign = sign}
      | SOME {class=IEEEReal.ZERO, sign, ...} =>
        SOME  {man = 0, exp = 0w0, sign = sign}
      | SOME {class, sign, digits, exp} =>
        let
          val float =
              foldl (fn (x, {man, exp}) =>
                        {man = man * 10 + IntInf.fromInt x, exp = exp - 1})
                    {man = 0, exp = exp}
                    digits
          val f as {man, exp} = algorithmM float
          val exp = exp + (manBits - 1) + expMax
        in
          if exp >= Word.toInt expInf
          then SOME {man = 0, exp = expInf, sign = sign} (* Inf *)
          else if exp > 0
          then SOME {man = man - manMSB,
                     exp = Word.fromInt exp,
                     sign = sign}
          else SOME {man = IntInf.max
                             (IntInf.~>> (man, (Word.fromInt (~exp)) + 0w1), 1),
                     exp = 0w0,
                     sign = sign} (* denormal *)
        end

  infix << >> || &&

  structure Word64Pair =
  struct
    type word64 = Word32.word * Word32.word

    fun (h, l) << n : word64 =
        if n > 0w32 then ((h, l) << 0w32) << (n - 0w32)
        else (Word32.orb (Word32.<< (h, n), Word32.>> (l, 0w32 - n)),
              Word32.<< (l, n))

    fun (h1, l1) || (h2, l2) : word64 =
        (Word32.orb (h1, h2), Word32.orb (l1, l2))

    val w0 = (0w0, 0w0) : word64
    val w1 = (0w0, 0w1) : word64

    fun fromWord x =
        (0w0, Word32.fromInt (Word.toIntX x)) : word64

    fun fromLargeInt x =
        (Word32.fromLargeInt (IntInf.~>> (x, 0w32)),
         Word32.fromLargeInt x) : word64
  end

  fun pack {man, exp, sign} =
      let
        open Word64Pair
        val signBit = if sign then w1 else w0
      in
        (signBit << Word.fromInt (manBits + expBits - 1))
        || (fromWord exp << (Word.fromInt manBits - 0w1))
        || fromLargeInt man
      end

end

structure IEEERealConst64 = IEEERealConst(val expBits = 11 val manBits = 53)
structure IEEERealConst32 = IEEERealConst(val expBits = 8 val manBits = 24)
