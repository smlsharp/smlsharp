(**
 * display_text.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: display_text.sml,v 1.3 2007/04/02 09:42:29 katsu Exp $
 *)

structure Display : DISPLAY =
struct

  structure PS = PowerSpectrum(
                   val numSamples = 2048
                   val samplingFreq = 44100.0
                 )
  structure SA = SpectrumAnalyzer(PS)
  structure IN = Input(PS)

  val interval = floor (PS.interval * 1000000.0)  (* usec *)

  fun dec n =
      let val s = "00" ^ Int.toString n
          val x = size s
      in if x > 3 then substring (s, x - 3, 3) else s
      end

  fun printAryAsInt ary =
      (Array.app (fn x => print (dec (floor x) ^ " ")) ary;
       print "\n")

  val buf = Array.array (20, 0.0)

  fun mainLoop input =
      let
        val _ = IN.fill input
        val _ = IN.read input
      in
        SA.toMonoral (IN.buffer, PS.samples);
        PS.calc ();
        SA.powerToHeight PS.spectrum;
        SA.summarize (PS.spectrum, 0, Array.length PS.spectrum, buf);
        printAryAsInt buf;
        Libc.usleep (interval div 4);
        if IN.finished input then () else mainLoop input
      end

  fun main () =
      let
        val input = IN.openInput ()
      in
        IN.startInput input;
        mainLoop input
      end

end
