(**
 * libglut.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libglut.sml,v 1.11 2007/04/02 09:42:29 katsu Exp $
 *)

local
  type float = Real32.real
in

structure GLUT =
struct
  val glutInit =
      _import "glutInit"
      : (int ref, string array) -> ()
  val glutInitDisplayMode =
      _import "glutInitDisplayMode"
      : word -> ()
  val glutInitWindowSize =
      _import "glutInitWindowSize"
      : (int, int) -> ()
  val glutCreateWindow =
      _import "glutCreateWindow"
      : string -> ()
  val glutDisplayFunc =
      _import "glutDisplayFunc"
      : (()->()) -> ()
  val glutReshapeFunc =
      _import "glutReshapeFunc"
      : ((int, int)->()) -> ()
  val glutMouseFunc =
      _import "glutMouseFunc"
      : (()->()) -> ()
  val glutKeyboardFunc =
      _import "glutKeyboardFunc"
      : ((int, int, int)->()) -> ()
  val glutTimerFunc =
      _import "glutTimerFunc"
      : (int, int->(), int) -> ()
  val glutIdleFunc =
      _import "glutIdleFunc"
      : (()->()) -> ()
  val glutMainLoop =
      _import "glutMainLoop"
      : () -> ()
  val glutSwapBuffers =
      _import "glutSwapBuffers"
      : () -> ()
  val glutPostRedisplay =
      _import "glutPostRedisplay"
      : () -> ()

  val GLUT_RGBA = 0wx0
  val GLUT_DOUBLE = 0wx2
  val GLUT_DEPTH = 0wx10

end

structure GL =
struct
  val glClearColor =
      _import "glClearColor"
      : (float, float, float, float) -> ()
  val glEnable =
      _import "glEnable"
      : word -> ()
  val glFrontFace =
      _import "glFrontFace"
      : word -> ()
  val glLightfv =
      _import "glLightfv"
      : (word, word, float * float * float * float) -> ()
  val glClear =
      _import "glClear"
      : word -> ()
  val glFlush =
      _import "glFlush"
      : () -> ()
  val glViewport =
      _import "glViewport"
      : (int, int, int, int) -> ()
  val glMatrixMode =
      _import "glMatrixMode"
      : word -> ()
  val glLoadIdentity =
      _import "glLoadIdentity"
      : () -> ()
  val glPushMatrix =
      _import "glPushMatrix"
      : () -> ()
  val glPopMatrix =
      _import "glPopMatrix"
      : () -> ()
  val glRotated =
      _import "glRotated"
      : (real, real, real, real) -> ()
  val glTranslated =
      _import "glTranslated"
      : (real, real, real) -> ()
  val glMaterialfv =
      _import "glMaterialfv"
      : (word, word, float * float * float * float) -> ()
  val glMaterialiv =
      _import "glMaterialiv"
      : (word, word, int * int * int * int) -> ()
  val glBegin =
      _import "glBegin"
      : word -> ()
  val glEnd =
      _import "glEnd"
      : () -> ()
  val glNormal3dv =
      _import "glNormal3dv"
      : (real * real * real) -> ()
  val glVertex3dv =
      _import "glVertex3dv"
      : (real * real * real) -> ()
  val glVertex2d =
      _import "glVertex2d"
      : (real, real) -> ()
  val glVertex3d =
      _import "glVertex3d"
      : (real, real, real) -> ()
  val glCullFace =
      _import "glCullFace"
      : word -> ()
  val glColor4i =
      _import "glColor4i"
      : (word, word, word, word) -> ()
  val glColor3d =
      _import "glColor3d"
      : (real, real, real) -> ()
  val glBlendFunc =
      _import "glBlendFunc"
      : (word, word) -> ()
  val glOrtho =
      _import "glOrtho"
      : (real, real, real, real, real, real) -> ()

  val GL_PROJECTION = 0wx1701
  val GL_DEPTH_TEST = 0wxB71
  val GL_CULL_FACE = 0wxB44
  val GL_BACK = 0wx405
  val GL_FRONT_AND_BACK = 0wx408
  val GL_FRONT = 0wx404
  val GL_CW = 0wx900
  val GL_LIGHTING = 0wxB50
  val GL_LIGHT0 = 0wx4000
  val GL_LIGHT1 = 0wx4001
  val GL_DIFFUSE = 0wx1201
  val GL_SPECULAR = 0wx1202
  val GL_AMBIENT = 0wx1200
  val GL_COLOR_BUFFER_BIT = 0wx4000
  val GL_DEPTH_BUFFER_BIT = 0wx100
  val GL_MODELVIEW = 0wx1700
  val GL_QUADS = 0wx7
  val GL_POSITION = 0wx1203
  val GL_LINE_LOOP = 0wx2
  val GL_LINES = 0wx1
  val GL_POLYGON = 0wx9
  val GL_LINE_SMOOTH = 0wxB20
  val GL_POLYGON_SMOOTH = 0wxB41
  val GL_BLEND = 0wxBE2
  val GL_SRC_ALPHA = 0wx302
  val GL_ONE_MINUS_SRC_ALPHA = 0wx303

end

structure GLU =
struct

  type gluQuadricObj = unit ptr

  val gluPerspective =
      _import "gluPerspective"
      : (real, real, real, real) -> ()
  val gluLookAt =
      _import "gluLookAt"
      : (real, real, real, real, real, real, real, real, real) -> ()
  val gluNewQuadric =
      _import "gluNewQuadric"
      : () -> gluQuadricObj
  val gluDeleteQuadric =
      _import "gluDeleteQuadric"
      : gluQuadricObj -> ()
  val gluQuadricDrawStyle =
      _import "gluQuadricDrawStyle"
      : (gluQuadricObj, word) -> ()
  val gluQuadricNormals =
      _import "gluQuadricNormals"
      : (gluQuadricObj, word) -> ()
  val gluQuadricOrientation =
      _import "gluQuadricOrientation"
      : (gluQuadricObj, word) -> ()
  val gluCylinder =
      _import "gluCylinder"
      : (gluQuadricObj, real, real, real, int, int) -> ()
  val gluDisk =
      _import "gluDisk"
      : (gluQuadricObj, real, real, int, int) -> ()

  val GLU_FILL = 0w100012
  val GLU_SMOOTH = 0w100000
  val GLU_INSIDE = 0w100021

end

end (* local *)
