(**
 * A portable way to serialize/unserialize a real.
 *
 * @author UENO Katsuhiro
 * @version $Id: IEEE754.sml,v 1.2 2007/11/13 03:50:53 katsu Exp $
 *)

  structure Word32List =
  struct

    type word = Word32.word list   (* lowWord ... highWord *)

    fun << (w, n) =
        let
          fun sh (0w0, nil, n) = nil
            | sh (c, nil, n) = [c]
            | sh (c, h::t, n) =
              Word32.orb (Word32.<< (h, n), c)
              :: sh (Word32.>> (h, 0w32 - n), t, n)

          fun shift (w, n) =
              if n < 0w32
              then sh (0w0, w, n)
              else shift (0w0::w, n - 0w32)
        in
          shift (w, n)
        end

    fun >> (w, n) =
        let
          fun sh (nil, n) = (0w0, nil)
            | sh (h::t, n) =
              let val (c, w) = sh (t, n)
              in (Word32.<< (h, 0w32 - n),
                  Word32.orb (c, Word32.>> (h, n)) :: w)
              end

          fun shift (nil, n) = nil
            | shift (l as _::t, n) =
              if n < 0w32
              then #2 (sh (l, n))
              else shift (t, n - 0w32)
        in
          shift (w, n)
        end

    fun || (h1::t1, h2::t2) = Word32.orb (h1, h2) :: || (t1, t2)
      | || (nil, w) = w
      | || (w, nil) = w

    fun && (h1::t1, h2::t2) = Word32.andb (h1, h2) :: && (t1, t2)
      | && (nil, w) = nil
      | && (w, nil) = nil

    fun toInt nil = 0
      | toInt (h::t) = Word32.toInt h

    fun fromInt n =
        [Word32.fromInt n]

    fun l8 s = String.extract (s, size s - 8, NONE)
    fun fmt nil = ""
      | fmt (h::t) = fmt t ^ l8 ("0000000" ^ Word32.fmt StringCvt.HEX h)

    val w0 = fromInt 0
    val w1 = fromInt 1

    fun isZero nil = true
      | isZero (h::t) = h = (0w0:Word32.word) andalso isZero t

  end

  (*
   * The following code assumes real number is represented in
   * IEEE 754 double precision floating point, which is used by
   * almost all FPUs.
   *
   * This code also assumes that both muptiplication and division
   * by 2 over reals doesn't make any modification to mantissa.
   *
   * Under the above assumptions, "dump" and "load" can convert between
   * a real and IEEE 754 double floating point without any errors.
   *
   * IEEE 754 64bit double precision floating point format:
   *   let sign be an 1 bit unsigned integer,
   *       exp be an 11bit unsigned integer,
   *       and man be a 52bit unsigned integer.
   *
   *   if 1 <= exp <= 2046,
   *   r = (-1)^sign * 2^(exp - 1023) * (2^52 + man) / 2^52
   *
   *   if exp = 0,
   *   r = (-1)^sign * 2^-1022 * (man / 2^52)
   *
   *   if exp = 2047 and man = 0, r = NaN
   *   if exp = 2047 and man <> 0, r = (-1)^sign * inf
   *
   * IEEE 754 32bit single precision floating point format:
   * - sign is an 1 bit unsigned integer.
   * - exp is an 8 bit unsigned integer.
   * - man is a 23 bit unsigned integer.
   *
   *)

  functor IEEE754Fn
  (
    val expBits : word
    val manBits : word
  ) : sig
    val load : Word32.word list -> real
    val dump : real -> Word32.word list
  end =
  struct

    val inf = 1.0 / 0.0
    val nan = 0.0 / 0.0

    open Word32List
    infix << >> || &&

    fun repeat 0w0 f x = x
      | repeat n f x = repeat (n - 0w1) f (f x)

    fun fillBit n =
        repeat n (fn w => (w << 0w1) || w1) w0

    val manMask = fillBit manBits
    val expMask = fillBit expBits << manBits
    val signMask = w1 << (manBits + expBits)
    val oneBit = w1 << manBits

    val expInf = Word.toInt (Word.<< (0w1, (expBits - 0w1)))
    val expBias = expInf - 1
    val expMin = ~(expBias - 1)

    fun normalize (r as {man, exp}) =
        if man < 1.0 andalso exp > expMin
        then normalize {man = man * 2.0, exp = exp - 1}
        else if man >= 2.0 orelse exp < expMin
        then normalize {man = man / 2.0, exp = exp + 1}
        else r

    fun isEvenWhole r =
        let val {whole, ...} = Real.split r
            val {frac, ...} = Real.split (whole / 2.0)
        in Real.ceil frac = 0
        end

    fun dumpFinite r =
        let
          val sign = Real.signBit r
          val {man, exp} = normalize (Real.toManExp (Real.abs r))
          val (_, manDump) =
              repeat (manBits + 0w1)
                  (fn (r, n) =>
                      let val b = if isEvenWhole r then w0 else w1
                      in (r * 2.0, (n << 0w1) || b)
                      end)
                  (man, w0)
          val exp = if man >= 1.0 then exp else exp - 1
        in
          (sign, exp, manDump && manMask)
        end

    fun dump r =
        let
          val (sign, exp, man) =
              if Real.isNan r then (Real.signBit r, expInf, manMask)
              else if Real.isFinite r then dumpFinite r
              else (Real.signBit r, expInf, w0)
          val sign = if sign then w1 else w0
        in
          (sign << (expBits + manBits))
          || (fromInt (exp + expBias) << manBits)
          || man
        end

    fun loadMan man =
        #1 (repeat (manBits + 0w1)
                (fn (r, x, n) =>
                    if isZero (n && oneBit) then (r, x / 2.0, n << 0w1)
                    else (r + x, x / 2.0, n << 0w1))
                (0.0, 1.0, man))

    (* FIXME: work around the bug of Real.fromManExp of SML/NJ. *)
    fun fromManExp {man, exp} =
        if exp < 0
        then repeat (Word.fromInt (~exp)) (fn r => r / 2.0) man
        else repeat (Word.fromInt exp) (fn r => r * 2.0) man
    (*
        Real.fromManExp { man = man, exp = exp }
     *)

    fun load d =
        let
          val sign = not (isZero (d && signMask))
          val exp = toInt ((d && expMask) >> manBits) - expBias
          val man = d && manMask
          val r = if exp = expInf
                  then if isZero man then inf else nan
                  else if exp = ~expBias
                  then fromManExp {man = loadMan man, exp = expMin}
                  else fromManExp {man = loadMan (man || oneBit), exp = exp}
        in
          if sign then ~r else r
        end

  end

structure IEEE754_64 =
    IEEE754Fn(struct val expBits = 0w11 val manBits = 0w52 end)

structure IEEE754_32 =
    IEEE754Fn(struct val expBits = 0w8 val manBits = 0w23 end)

structure IEEE754_80 =
    IEEE754Fn(struct val expBits = 0w15 val manBits = 0w64 end)

(*
  (* self test *)
  val _ =
      let
        fun realfmt r =
            Real.fmt (StringCvt.SCI (SOME 20)) r
        fun realeq (r, r') =
            (Real.isNan r andalso Real.isNan r') orelse Real.== (r, r')
        fun test (r, expect) =
            let val d = IEEE754_64.dump r
                val actual = String.map Char.toLower (Word32List.fmt d)
                val _ = if actual = expect then ()
                        else raise Fail ("IEEE754_64.dump test failed: " ^
                                         actual ^ " " ^ expect)
                val r' = IEEE754_64.load d
                val _ = if realeq (r, r') then ()
                        else raise Fail ("IEEE754_64.load test failed: " ^
                                         realfmt r ^ " " ^ realfmt r')
            in ()
            end
      in
        (* normalized number *)
        test (~2.5,                    "c004000000000000");
        test (0.8414709848078965,      "3feaed548f090cee"); (* sin(1) *)
        test (2.2250738585072019e~308, "0010000000000001");
        test (1.7976931348623157e308,  "7fefffffffffffff");
        (* denormalized number *)
        test (0.0,                     "0000000000000000");
(*
        (* FIXME: SML/NJ doesn't accept these literals. *)
        test (4.9406564584124654e~324, "0000000000000001");
        test (1.4370268669525674e~308, "000a555555555555");
*)
        test (2.2250738585072014e~308/4503599627370496.0, "0000000000000001");
        test (2.8740537339051348e~308/2.0, "000a555555555555");
        (* NaN and Inf *)
        test (0.0 / 0.0,               "7fffffffffffffff");
        test (1.0 / 0.0,               "7ff0000000000000");
        test (~1.0 / 0.0,              "fff0000000000000");
        ()
      end
*)
