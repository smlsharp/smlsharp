(**
 * A portable way to serialize/unserialize a real.
 *
 * @author UENO Katsuhiro
 * @version $Id: IEEE754.sml,v 1.6 2007/02/19 16:00:38 kiyoshiy Exp $
 *)
structure MyWord64 =
struct

  type word64 = Word32.word * Word32.word
  infix << >> || &&

  fun (h, l) << n : word64 =
      if n > 0w32 then ((h, l) << 0w32) << (n - 0w32)
      else (Word32.orb (Word32.<< (h, n), Word32.>> (l, 0w32 - n)),
            Word32.<< (l, n))

  fun (h, l) >> n : word64 =
      if n > 0w32 then ((h, l) >> 0w32) >> (n - 0w32)
      else (Word32.>> (h, n),
            Word32.orb (Word32.>> (l, n), Word32.<< (h, 0w32 - n)))

  fun (h1, l1) || (h2, l2) : word64 =
      (Word32.orb (h1, h2), Word32.orb (l1, l2))

  fun (h1, l1) && (h2, l2) : word64 =
      (Word32.andb (h1, h2), Word32.andb (l1, l2))

  fun toInt (h, l) =
      Word32.toInt l

  fun fromInt n =
      (0w0, Word32.fromInt n) : word64

  fun fromWord n =
      (0w0, n) : word64

  fun toWord (h, l) = l

  fun l8 s = String.extract (s, size s - 8, NONE)
  fun fmt (h, l) =
      l8 ("0000000" ^ Word32.fmt StringCvt.HEX h)
      ^ l8 ("0000000" ^ Word32.fmt StringCvt.HEX l)

  val w0 = fromInt 0
  val w1 = fromInt 1

end

(***************************************************************************)

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

functor IEEE754Fn(
    val expBits : word
    val manBits : word
) : sig
    val load : MyWord64.word64 -> real
    val dump : real -> MyWord64.word64
end =
struct

  open MyWord64
  infix << >> || &&

  val inf = 1.0 / 0.0
  val nan = 0.0 / 0.0

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
                if (n && oneBit) = w0 then (r, x / 2.0, n << 0w1)
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
        val sign = (d && signMask) <> w0
        val exp = toInt ((d && expMask) >> manBits) - expBias
        val man = d && manMask
        val r = if exp = expInf
                then if man = w0 then inf else nan
                else if exp = ~expBias
                then fromManExp {man = loadMan man, exp = expMin}
                else fromManExp {man = loadMan (man || oneBit), exp = exp}
      in
        if sign then ~r else r
      end

end

(***************************************************************************)

structure IEEE754 : sig

  type word64 = Word32.word * Word32.word
  val dump64 : real -> word64
  val load64 : word64 -> real

  val dump32 : real -> Word32.word
  val load32 : Word32.word -> real

end =
struct

  open MyWord64

  structure IEEE754_64 =
      IEEE754Fn(struct val expBits = 0w11 val manBits = 0w52 end)
  
  structure IEEE754_32 =
      IEEE754Fn(struct val expBits = 0w8 val manBits = 0w23 end)

  (**
   * serializes a real.
   * @params real
   *)
  val dump64 = IEEE754_64.dump
  fun dump32 x = toWord (IEEE754_32.dump x)

  (**
   * unserializes a real.
   * @params real
   *)
  val load64 = IEEE754_64.load
  fun load32 x = IEEE754_32.load (fromWord x)


  (***************************************************************************)
(*
  (* self test *)
  val _ =
      let
        fun realfmt r =
            Real.fmt (StringCvt.SCI (SOME 20)) r
        fun realeq (r, r') =
            (Real.isNan r andalso Real.isNan r') orelse Real.== (r, r')
        fun test (r, expect) =
            let val d = dump64 r
                val actual = String.map Char.toLower (fmt d)
                val _ = if actual = expect then ()
                        else raise Fail ("IEEE754.dump64 test failed: " ^
                                         actual ^ " " ^ expect)
                val r' = load64 d
                val _ = if realeq (r, r') then ()
                        else raise Fail ("IEEE754.load64 test failed: " ^
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
  (***************************************************************************)

end
