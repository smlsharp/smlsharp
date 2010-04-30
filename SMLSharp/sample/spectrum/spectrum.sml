(**
 * spectrum.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: spectrum.sml,v 1.3 2007/04/02 09:42:29 katsu Exp $
 *)

functor PowerSpectrum (
  val numSamples : int
  val samplingFreq : real
) : sig

  val numSamples : int
  val samplingFreq : real
  val samplingCycle : real
  val interval : real

  val samples : real array
  val spectrum : real array
  val calc : unit -> unit

end =
struct

  val numSamples = numSamples

  val samplingFreq = samplingFreq
  val samplingCycle = 1.0 / samplingFreq
  fun freq x = real x / samplingCycle / real numSamples

  val interval = samplingCycle * real numSamples  (* sec *)

  (* sine window *)
  val window =
      Vector.tabulate (numSamples,
                       fn n => Libm.sin (Math.pi * real n / real numSamples))

  val samples = Array.array (numSamples, 0.0)
  val spectrum = Array.array (numSamples div 2 - 1, 0.0)

  val factor = real (numSamples div 2)

  fun applyWindow 0 = ()
    | applyWindow n =
      let
        val n = n - 1
        val x = Array.sub (samples, n) * Vector.sub (window, n)
      in
        Array.update (samples, n, x);
        applyWindow n
      end

  fun calcSpectrum (r, i) =
      if r >= i then ()
      else
        let
          val re = Array.sub (samples, r) / factor
          val im = Array.sub (samples, i) / factor
          val power = re * re + im * im
          val db = 10.0 * Libm.log10 power
        in
          Array.update (spectrum, r - 1, db);
          calcSpectrum (r + 1, i - 1)
        end

  (*
   * calculate `spectrum' from `samples'.
   * `samples' will be destructed.
   *)
  fun calc () =
      (applyWindow numSamples;
       GSL.fft_real_radix2_transform (samples, 1, numSamples);
       calcSpectrum (1, numSamples - 1))

end


functor SpectrumAnalyzer (
  val numSamples : int
  val samplingFreq : real
) =
struct

  val minSample = 1.0 / 32768.0
  val minPower = 10.0 * Libm.log10 (minSample * minSample)

  (* 0 - ~100dB -> height 100 - 0 *)
  fun powerToHeight ary =
      Array.modifyi
          (fn (n,x) =>
              let val x = 100.0 + x
              in if x < 0.0 then 0.0
                 else if x > 100.0 then 100.0
                 else x
              end)
          ary

  (* make a summary of src to dst *)
  local
    fun max (ary, i, j, r:real) =
        if i >= j then r
        else
          let
            val x = Array.sub (ary, i)
            val r = if r > x then r else x
          in
            max (ary, i + 1, j, r)
          end

    fun summary (src, offset, len, dst, n) =
        let
          val dstlen = Array.length dst
        in
          if n >= dstlen then ()
          else
            let
              val i = offset + n * len div dstlen
              val j = offset + (n + 1) * len div dstlen
              val x = max (src, i, j, 0.0)
            in
              Array.update (dst, n, x);
              summary (src, offset, len, dst, n + 1)
            end
        end
  in
  fun summarize (src, offset, len, dst) =
      summary (src, offset, len, dst, 0)

  end

  fun toMonoral (ary, dst) =
      Array.appi
        (fn (i,x) =>
            let
              val c1 = Word32.toInt (Word32.>> (x, 0w16))
              val c2 = Word32.toInt (Word32.andb (x, 0wxffff))
              val c1 = if c1 >= 32768 then c1 - 65536 else c1
              val c2 = if c2 >= 32768 then c2 - 65536 else c2
              val x = if c1 > c2 then c1 else c2
            in
              Array.update (dst, i, real x / 32768.0)
            end)
        ary


  (* for debug *)
  fun readBlockPulse dst =
      (
        Array.modifyi
          (fn (n,_) =>
              if numSamples div 4 <= n andalso n < numSamples * 3 div 4
              then 1.0 else 0.0)
          dst;
        false
      )

  fun readSineWave (speed, dst) =
      (
        Array.modifyi
          (fn (n,_) =>
              Libm.sin (speed * 2.0 * Math.pi * real n / real numSamples))
          dst;
        false
      )
              
  fun printAry ary =
      Array.appi
        (fn (n, x) =>
            print (Int.toString n^" : "
                   ^Real.fmt (StringCvt.FIX (SOME 6)) x^"\n"))
        ary

end
