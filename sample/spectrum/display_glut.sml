(**
 * display_glut.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: display_glut.sml,v 1.3 2007/04/02 09:42:29 katsu Exp $
 *)

structure Display : DISPLAY =
struct

  structure PS = PowerSpectrum(
                   val numSamples = 1024
                   val samplingFreq = 44100.0
                 )
  structure SA = SpectrumAnalyzer(PS)
  structure IN = Input(PS)

  val interval = floor (PS.interval * 1000.0)  (* msec *)
  val interval = interval * 2

  fun repeat 0 f = ()
    | repeat n f = (f n; repeat (n - 1) f)

  open GL GLU GLUT

  infix ++
  val op ++ = Word.orb

  val progname = "smlsharp"

  val input = ref NONE : IN.input option ref
  val spectrums = ref nil : real array list ref
  val summarySize = 100

  val x = ref 280.0
  val y = ref 50.0
  val z = ref 360.0
  val vx = ref 80.0
  val vy = ref 50.0
  val vz = ref 10.0

  fun plotSpectrum (ary, z) =
      (
        Array.appi
          (fn (x, h) =>
              let
                val x = real x
                val b = 1.0 - x * 1.0 / real (Array.length ary)
                val g = 0.2 + 0.8 * x / real (Array.length ary)
                val f = 1.0 - z * 0.008
                val f = if f < 1.0 then f * 0.5 else f
              in
                glColor3d (0.2 * f, g * f, b * f);
                glVertex3d (x, 0.0, ~z);
                glVertex3d (x, h, ~z)
              end)
          ary
      )

  fun plot z nil = nil
    | plot z (ary::arrays) =
      if z > 100.0 then nil
      else ary :: plot (z + 1.0) arrays before plotSpectrum (ary, z)

  fun display () =
      (
        glClear (GL_COLOR_BUFFER_BIT);
        glLoadIdentity ();
        gluLookAt (!x, !y, !z, !vx, !vy, !vz, 0.0, 1.0, 0.0);

        glBegin GL_LINES;
        spectrums := plot 0.0 (!spectrums);

        glColor3d (0.8, 0.0, 0.0);
        glVertex3d (~3.0, 0.0, 0.0);
        glVertex3d (~3.0, 100.0, 0.0);
        glVertex3d (0.0, 0.0, 0.0);
        glVertex3d (100.0, 0.0, 0.0);
        repeat 10 (fn n =>
                      let val x = if n mod 5 = 0 then ~0.5 else ~1.5
                          val y = real n * 10.0
                      in glVertex3d (~3.0, y, 0.0);
                         glVertex3d (x, y, 0.0)
                      end);
        glEnd ();

        glutSwapBuffers ()
      )

  fun resize (w, h) =
      (
        glViewport (0, 0, w, h);
        glMatrixMode GL_PROJECTION;
        glLoadIdentity ();
        gluPerspective (15.0, real w / real h, 1.0, 2000.0);
        glMatrixMode GL_MODELVIEW
      )

  fun timer n =
      let
        val ary = Array.array (summarySize, 0.0)
      in
        IN.read (valOf (!input));
        SA.toMonoral (IN.buffer, PS.samples);
        PS.calc ();
        SA.powerToHeight PS.spectrum;
        SA.summarize (PS.spectrum, 0, Array.length PS.spectrum, ary);
        spectrums := ary :: !spectrums;

        glutPostRedisplay ();
        glutTimerFunc (interval, timer, 0)
      end

  fun idle () =
      (
        while IN.fill (valOf (!input)) do ();
        ()
      )

  fun keyboard (c, _:int, _:int) =
      (
        case chr c of
          #"j" => x := !x + 1.0
        | #"k" => y := !y + 1.0
        | #"l" => z := !z + 1.0
        | #"J" => x := !x - 1.0
        | #"K" => y := !y - 1.0
        | #"L" => z := !z - 1.0
        | #"u" => vx := !vx + 1.0
        | #"i" => vy := !vy + 1.0
        | #"o" => vz := !vz + 1.0
        | #"U" => vx := !vx - 1.0
        | #"I" => vy := !vy - 1.0
        | #"O" => vz := !vz - 1.0
        | _ => ();
        print (Real.toString (!x)^", "^
               Real.toString (!y)^", "^
               Real.toString (!z)^", "^
               Real.toString (!vx)^", "^
               Real.toString (!vy)^", "^
               Real.toString (!vz)^"\n")
      )

  fun main () =
      (
        glutInit (ref 1, Array.fromList [progname]);
        glutInitDisplayMode (GLUT_RGBA ++ GLUT_DOUBLE);
        glutInitWindowSize (640, 480);
        glutCreateWindow progname;
        glutDisplayFunc display;
(*
        glutKeyboardFunc keyboard;
*)
        glutReshapeFunc resize;
        glutTimerFunc (interval, timer, 0);
        input := SOME (IN.openInput ());
        glutIdleFunc idle;
        glClearColor (0.02, 0.02, 0.02, 1.0);

        IN.startInput (valOf (!input));
        glutMainLoop ()
      )

end
