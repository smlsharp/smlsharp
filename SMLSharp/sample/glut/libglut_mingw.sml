(**
 * libglut.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libglut_mingw.sml,v 1.1 2007/03/29 17:00:24 katsu Exp $
 *)

local
  val libglName = "opengl32.dll"
  val libgluName = "glu32.dll"
  val libglutName = "glut32.dll"

  open DynamicLink

  val libgl = dlopen libglName
  val libglu = dlopen libgluName
  val libglut = dlopen libglutName
in

structure GLUT =
struct
  val glutInit =
      dlsym (libglut, "glutInit")
      : _import _stdcall (int ref, string array) -> unit
  val glutInitDisplayMode =
      dlsym (libglut, "glutInitDisplayMode")
      : _import _stdcall word -> unit
  val glutInitWindowSize =
      dlsym (libglut, "glutInitWindowSize")
      : _import _stdcall (int, int) -> unit
  val glutCreateWindow =
      dlsym (libglut, "glutCreateWindow")
      : _import _stdcall string -> unit
  val glutDisplayFunc =
      dlsym (libglut, "glutDisplayFunc")
      : _import _stdcall (()->unit) -> unit
  val glutReshapeFunc =
      dlsym (libglut, "glutReshapeFunc")
      : _import _stdcall ((int, int)->unit) -> unit
  val glutMouseFunc =
      dlsym (libglut, "glutMouseFunc")
      : _import _stdcall (()->unit) -> unit
  val glutKeyboardFunc =
      dlsym (libglut, "glutKeyboardFunc")
      : _import _stdcall ((int, int, int)->unit) -> unit
  val glutTimerFunc =
      dlsym (libglut, "glutTimerFunc")
      : _import _stdcall (int, int->unit, int) -> unit
  val glutIdleFunc =
      dlsym (libglut, "glutIdleFunc")
      : _import _stdcall (()->unit) -> unit
  val glutMainLoop =
      dlsym (libglut, "glutMainLoop")
      : _import _stdcall () -> unit
  val glutSwapBuffers =
      dlsym (libglut, "glutSwapBuffers")
      : _import _stdcall () -> unit
  val glutPostRedisplay =
      dlsym (libglut, "glutPostRedisplay")
      : _import _stdcall () -> unit

  val GLUT_RGBA = 0wx0
  val GLUT_DOUBLE = 0wx2
  val GLUT_DEPTH = 0wx10
end

structure GL =
struct
  val glClearColor =
      dlsym (libgl, "glClearColor")
      : _import _stdcall (float, float, float, float) -> unit
  val glEnable =
      dlsym (libgl, "glEnable")
      : _import _stdcall word -> unit
  val glFrontFace =
      dlsym (libgl, "glFrontFace")
      : _import _stdcall word -> unit
  val glLightfv =
      dlsym (libgl, "glLightfv")
      : _import _stdcall (word, word, float * float * float * float) -> unit
  val glClear =
      dlsym (libgl, "glClear")
      : _import _stdcall word -> unit
  val glFlush =
      dlsym (libgl, "glFlush")
      : _import _stdcall () -> unit
  val glViewport =
      dlsym (libgl, "glViewport")
      : _import _stdcall (int, int, int, int) -> unit
  val glMatrixMode =
      dlsym (libgl, "glMatrixMode")
      : _import _stdcall word -> unit
  val glLoadIdentity =
      dlsym (libgl, "glLoadIdentity")
      : _import _stdcall () -> unit
  val glMatrixMode =
      dlsym (libgl, "glMatrixMode")
      : _import _stdcall word -> unit
  val glPushMatrix =
      dlsym (libgl, "glPushMatrix")
      : _import _stdcall () -> unit
  val glPopMatrix =
      dlsym (libgl, "glPopMatrix")
      : _import _stdcall () -> unit
  val glRotated =
      dlsym (libgl, "glRotated")
      : _import _stdcall (real, real, real, real) -> unit
  val glTranslated =
      dlsym (libgl, "glTranslated")
      : _import _stdcall (real, real, real) -> unit
  val glMaterialfv =
      dlsym (libgl, "glMaterialfv")
      : _import _stdcall (word, word, float * float * float * float) -> unit
  val glMaterialiv =
      dlsym (libgl, "glMaterialiv")
      : _import _stdcall (word, word, int * int * int * int) -> unit
  val glBegin =
      dlsym (libgl, "glBegin")
      : _import _stdcall word -> unit
  val glEnd =
      dlsym (libgl, "glEnd")
      : _import _stdcall () -> unit
  val glNormal3dv =
      dlsym (libgl, "glNormal3dv")
      : _import _stdcall (real * real * real) -> unit
  val glVertex3dv =
      dlsym (libgl, "glVertex3dv")
      : _import _stdcall (real * real * real) -> unit
  val glVertex2d =
      dlsym (libgl, "glVertex2d")
      : _import _stdcall (real, real) -> unit
  val glVertex3d =
      dlsym (libgl, "glVertex3d")
      : _import _stdcall (real, real, real) -> unit
  val glCullFace =
      dlsym (libgl, "glCullFace")
      : _import _stdcall word -> unit
  val glColor4i =
      dlsym (libgl, "glColor4i")
      : _import _stdcall (word, word, word, word) -> unit
  val glColor3d =
      dlsym (libgl, "glColor3d")
      : _import _stdcall (real, real, real) -> unit
  val glBlendFunc =
      dlsym (libgl, "glBlendFunc")
      : _import _stdcall (word, word) -> unit
  val glOrtho =
      dlsym (libgl, "glOrtho")
      : _import _stdcall (real, real, real, real, real, real) -> unit

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
  type gluQuadricObj = word

  val gluPerspective =
      dlsym (libglu, "gluPerspective")
      : _import _stdcall (real, real, real, real) -> unit
  val gluLookAt =
      dlsym (libglu, "gluLookAt")
      : _import _stdcall (real, real, real, real, real, real, real, real, real) -> unit
  val gluNewQuadric =
      dlsym (libglu, "gluNewQuadric")
      : _import _stdcall () -> gluQuadricObj
  val gluDeleteQuadric =
      dlsym (libglu, "gluDeleteQuadric")
      : _import _stdcall gluQuadricObj -> unit
  val gluQuadricDrawStyle =
      dlsym (libglu, "gluQuadricDrawStyle")
      : _import _stdcall (gluQuadricObj, word) -> unit
  val gluQuadricNormals =
      dlsym (libglu, "gluQuadricNormals")
      : _import _stdcall (gluQuadricObj, word) -> unit
  val gluQuadricOrientation =
      dlsym (libglu, "gluQuadricOrientation")
      : _import _stdcall (gluQuadricObj, word) -> unit
  val gluCylinder =
      dlsym (libglu, "gluCylinder")
      : _import _stdcall (gluQuadricObj, real, real, real, int, int) -> unit
  val gluDisk =
      dlsym (libglu, "gluDisk")
      : _import _stdcall (gluQuadricObj, real, real, int, int) -> unit

  val GLU_FILL = 0wx186AC
  val GLU_SMOOTH = 0wx186A0
  val GLU_INSIDE = 0wx186B5
end

end (* local *)
