(**
 * cube.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: cube.sml,v 1.4 2007/04/02 09:42:29 katsu Exp $
 *)

open GL GLU GLUT

infix ++
val op ++ = Word.orb

val progname = "smlsharp"
val r = ref 0.0

(*
 *     (0,h,d) +-------+ (w,h,d)
 *            /|      /|
 *           / |     / |
 *  (0,h,0) +-------+  |(w,h,0)
 *   (0,0,d)|  +-------+ (w,0,d)
 *        h | /     | /
 *          |/      |/  d
 *  (0,0,0) +-------+ (w,0,0)
 *              w
 *)

fun cube (w, h, d) =
    (glBegin GL_QUADS;
     app (fn (normal,vertexes) =>
             (glNormal3dv normal;
              app glVertex3dv vertexes))
         [
           (( 1.0, 0.0, 0.0),
            [(  w, 0.0, 0.0),(  w,   h, 0.0),(  w,   h,   d),(  w, 0.0,   d)]),
           (( 0.0, 1.0, 0.0),
            [(0.0,   h, 0.0),(0.0,   h,   d),(  w,   h,   d),(  w,   h, 0.0)]),
           (( 0.0, 0.0,~1.0),
            [(0.0, 0.0, 0.0),(0.0,   h, 0.0),(  w,   h, 0.0),(  w, 0.0, 0.0)]),
           ((~1.0, 0.0, 0.0),
            [(0.0, 0.0,   d),(0.0,   h,   d),(0.0,   h, 0.0),(0.0, 0.0, 0.0)]),
           (( 0.0,~1.0, 0.0),
            [(0.0, 0.0,   d),(0.0, 0.0, 0.0),(  w, 0.0, 0.0),(  w, 0.0,   d)]),
           (( 0.0, 0.0, 1.0),
            [(  w, 0.0,   d),(  w,   h,   d),(0.0,   h,   d),(0.0, 0.0,   d)])
         ];
     glEnd ())

fun display () =
    (glClear (GL_COLOR_BUFFER_BIT ++ GL_DEPTH_BUFFER_BIT);
     glLoadIdentity ();
     gluLookAt (3.0, 4.0, 5.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
     glLightfv (GL_LIGHT0, GL_POSITION, (0.0, 3.0, 5.0, 1.0));
     glLightfv (GL_LIGHT1, GL_POSITION, (5.0, 3.0, 0.0, 1.0));

     glPushMatrix ();

     glRotated(!r, 0.0, 1.0, 0.0);
     glMaterialfv (GL_FRONT_AND_BACK, GL_DIFFUSE, (0.2, 0.2, 0.8, 1.0));
     cube (1.0, 1.0, 1.0);

     glTranslated (0.5, 0.0, 0.5);
     glRotated (2.0 * !r, 0.0, 1.0, 0.0);
     glTranslated (1.0, 0.0, ~0.5);
     glMaterialfv (GL_FRONT_AND_BACK, GL_DIFFUSE, (0.8, 0.2, 0.2, 1.0));
     cube (1.0, 1.0, 1.0);

     glPopMatrix ();
     glutSwapBuffers ())

fun resize (w, h) =
    (glViewport (0, 0, w, h);

     glMatrixMode GL_PROJECTION;
     glLoadIdentity ();
     gluPerspective (30.0, real w / real h, 1.0, 100.0);

     glMatrixMode GL_MODELVIEW;
     glLoadIdentity ();
     gluLookAt (3.0, 4.0, 5.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0))

fun timer n =
    (r := !r + 1.0;
     if !r >= 360.0 then r := 0.0 else ();
     glutPostRedisplay ();
     glutTimerFunc (10, timer, 0))
    (*FIXME: unaligned double *)

val _ = glutInit (ref 1, Array.fromList [progname])
val _ = glutInitDisplayMode (GLUT_RGBA ++ GLUT_DOUBLE ++ GLUT_DEPTH)
val _ = glutCreateWindow progname
val _ = glutDisplayFunc display
val _ = glutReshapeFunc resize
val _ = glutTimerFunc (10, timer, 0)

val _ = glClearColor (0.95, 0.95, 1.0, 1.0)

val _ = glEnable GL_DEPTH_TEST
val _ = glEnable GL_CULL_FACE
val _ = glCullFace GL_BACK

val _ = app glEnable [GL_LIGHTING, GL_LIGHT0, GL_LIGHT1]
val _ = glLightfv (GL_LIGHT1, GL_DIFFUSE, (0.0, 1.0, 0.0, 1.0))
val _ = glLightfv (GL_LIGHT1, GL_SPECULAR, (0.0, 1.0, 0.0, 1.0))

val _ = glutMainLoop ()
