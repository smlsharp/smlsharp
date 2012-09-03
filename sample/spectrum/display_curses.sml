(**
 * display_curses.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: display_curses.sml,v 1.3 2007/04/02 09:42:29 katsu Exp $
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

  fun repeat 0 f = ()
    | repeat n f = (f n; repeat (n - 1) f)

  val buf = Array.array (80, 0.0)

  fun mainLoop input =
      let
        val _ = IN.fill input
        val _ = IN.read input
      in
        SA.toMonoral (IN.buffer, PS.samples);
        PS.calc ();
        SA.powerToHeight PS.spectrum;
        SA.summarize (PS.spectrum, 0, Array.length PS.spectrum, buf);

        Libcurses.clear ();
        Array.appi
          (fn (x, h) =>
              repeat (floor (h / 100.0 * 20.0))
                     (fn y =>
                         (Libcurses.move (20 - y, x);
                          Libcurses.addch #"#")))
          buf;

        Libcurses.refresh ();
        Libc.usleep (interval div 4);
        if IN.finished input then () else mainLoop input
      end

  fun main () =
      let
        val input = IN.openInput ()
      in
        Libcurses.initscr ();
        Libcurses.nocbreak ();
        Libcurses.noecho ();
        Libcurses.nonl ();
        Libcurses.clear ();
        Libcurses.refresh ();
        IN.startInput input;
        mainLoop input;
        IN.closeInput input;
        Libcurses.endwin ()
      end

end
