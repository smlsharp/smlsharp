(**
 * libglut.sml
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: libglut.sml,v 1.11 2007/04/02 09:42:29 katsu Exp $
 *)

use "CConfig/load.sml";

local
  open CConfig

  val libglName =
      valOf (findLibrary ("gl","glEnable",["GL/gl.h"]))
      handle Option =>
      valOf (findLibrary ("GL","glEnable",["GL/gl.h"]))
      handle Option =>
      valOf (findLibrary ("-framework OpenGL","glEnable",["OpenGL/gl.h"]))
  val libgluName =
      valOf (findLibrary ("glu","gluLookAt",["GL/glu.h"]))
      handle Option =>
      valOf (findLibrary ("GLU","gluLookAt",["GL/glu.h"]))
      handle Option =>
      valOf (findLibrary ("-framework OpenGL","gluLookAt",["OpenGL/glu.h"]))
  val libglutName =
      valOf (findLibrary ("glut","glutInit",["GL/glut.h"]))
      handle Option =>
      valOf (findLibrary ("-framework GLUT","glutInit",["GLUT/glut.h"]))
(*
  (* Mac OS X *)
  val _ = #set (CConfig.config "CFLAGS")
               (SOME "-framework OpenGL -framework GLUT")
  val libglName = "/System/Library/Frameworks/OpenGL.framework/Versions/A/OpenGL"
  val libgluName = libglName
  val libglutName = "/System/Library/Frameworks/GLUT.framework/Versions/A/GLUT"
*)

  fun constWord name =
      let
        val w = valOf (haveConstUInt (name, ["GL/glut.h"]))
                handle Option =>
                valOf (haveConstUInt (name, ["GLUT/glut.h"]))
      (*val _ = print ("val "^name^" = 0wx"^Word.fmt StringCvt.HEX w^"\n")*)
      in
        w
      end

  open DynamicLink

  val libgl = dlopen libglName
  val libglu = if libglName = libgluName then libgl else dlopen libgluName
  val libglut = dlopen libglutName
in

structure GLUT =
struct
  val glutInit =
      dlsym (libglut, "glutInit")
      : _import (int ref, string array) -> unit
  val glutInitDisplayMode =
      dlsym (libglut, "glutInitDisplayMode")
      : _import word -> unit
  val glutInitWindowSize =
      dlsym (libglut, "glutInitWindowSize")
      : _import (int, int) -> unit
  val glutCreateWindow =
      dlsym (libglut, "glutCreateWindow")
      : _import string -> unit
  val glutDisplayFunc =
      dlsym (libglut, "glutDisplayFunc")
      : _import (()->unit) -> unit
  val glutReshapeFunc =
      dlsym (libglut, "glutReshapeFunc")
      : _import ((int, int)->unit) -> unit
  val glutMouseFunc =
      dlsym (libglut, "glutMouseFunc")
      : _import (()->unit) -> unit
  val glutKeyboardFunc =
      dlsym (libglut, "glutKeyboardFunc")
      : _import ((int, int, int)->unit) -> unit
  val glutTimerFunc =
      dlsym (libglut, "glutTimerFunc")
      : _import (int, int->unit, int) -> unit
  val glutIdleFunc =
      dlsym (libglut, "glutIdleFunc")
      : _import (()->unit) -> unit
  val glutMainLoop =
      dlsym (libglut, "glutMainLoop")
      : _import () -> unit
  val glutSwapBuffers =
      dlsym (libglut, "glutSwapBuffers")
      : _import () -> unit
  val glutPostRedisplay =
      dlsym (libglut, "glutPostRedisplay")
      : _import () -> unit

  val GLUT_RGBA = constWord "GLUT_RGBA"
  val GLUT_DOUBLE = constWord "GLUT_DOUBLE"
  val GLUT_DEPTH = constWord "GLUT_DEPTH"
(*
  (* Mac OS X *)
  val GLUT_RGBA = 0wx0
  val GLUT_DOUBLE = 0wx2
  val GLUT_DEPTH = 0wx10
*)

end

structure GL =
struct
  val glClearColor =
      dlsym (libgl, "glClearColor")
      : _import (float, float, float, float) -> unit
  val glEnable =
      dlsym (libgl, "glEnable")
      : _import word -> unit
  val glFrontFace =
      dlsym (libgl, "glFrontFace")
      : _import word -> unit
  val glLightfv =
      dlsym (libgl, "glLightfv")
      : _import (word, word, float * float * float * float) -> unit
  val glClear =
      dlsym (libgl, "glClear")
      : _import word -> unit
  val glFlush =
      dlsym (libgl, "glFlush")
      : _import () -> unit
  val glViewport =
      dlsym (libgl, "glViewport")
      : _import (int, int, int, int) -> unit
  val glMatrixMode =
      dlsym (libgl, "glMatrixMode")
      : _import word -> unit
  val glLoadIdentity =
      dlsym (libgl, "glLoadIdentity")
      : _import () -> unit
  val glMatrixMode =
      dlsym (libgl, "glMatrixMode")
      : _import word -> unit
  val glPushMatrix =
      dlsym (libgl, "glPushMatrix")
      : _import () -> unit
  val glPopMatrix =
      dlsym (libgl, "glPopMatrix")
      : _import () -> unit
  val glRotated =
      dlsym (libgl, "glRotated")
      : _import (real, real, real, real) -> unit
  val glTranslated =
      dlsym (libgl, "glTranslated")
      : _import (real, real, real) -> unit
  val glMaterialfv =
      dlsym (libgl, "glMaterialfv")
      : _import (word, word, float * float * float * float) -> unit
  val glMaterialiv =
      dlsym (libgl, "glMaterialiv")
      : _import (word, word, int * int * int * int) -> unit
  val glBegin =
      dlsym (libgl, "glBegin")
      : _import word -> unit
  val glEnd =
      dlsym (libgl, "glEnd")
      : _import () -> unit
  val glNormal3dv =
      dlsym (libgl, "glNormal3dv")
      : _import (real * real * real) -> unit
  val glVertex3dv =
      dlsym (libgl, "glVertex3dv")
      : _import (real * real * real) -> unit
  val glVertex2d =
      dlsym (libgl, "glVertex2d")
      : _import (real, real) -> unit
  val glVertex3d =
      dlsym (libgl, "glVertex3d")
      : _import (real, real, real) -> unit
  val glCullFace =
      dlsym (libgl, "glCullFace")
      : _import word -> unit
  val glColor4i =
      dlsym (libgl, "glColor4i")
      : _import (word, word, word, word) -> unit
  val glColor3d =
      dlsym (libgl, "glColor3d")
      : _import (real, real, real) -> unit
  val glBlendFunc =
      dlsym (libgl, "glBlendFunc")
      : _import (word, word) -> unit
  val glOrtho =
      dlsym (libgl, "glOrtho")
      : _import (real, real, real, real, real, real) -> unit

  val GL_PROJECTION = constWord "GL_PROJECTION"
  val GL_DEPTH_TEST = constWord "GL_DEPTH_TEST"
  val GL_CULL_FACE = constWord "GL_CULL_FACE"
  val GL_BACK = constWord "GL_BACK"
  val GL_FRONT_AND_BACK = constWord "GL_FRONT_AND_BACK"
  val GL_FRONT = constWord "GL_FRONT"
  val GL_CW = constWord "GL_CW"
  val GL_LIGHTING = constWord "GL_LIGHTING"
  val GL_LIGHT0 = constWord "GL_LIGHT0"
  val GL_LIGHT1 = constWord "GL_LIGHT1"
  val GL_DIFFUSE = constWord "GL_DIFFUSE"
  val GL_SPECULAR = constWord "GL_SPECULAR"
  val GL_AMBIENT = constWord "GL_AMBIENT"
  val GL_COLOR_BUFFER_BIT = constWord "GL_COLOR_BUFFER_BIT"
  val GL_DEPTH_BUFFER_BIT = constWord "GL_DEPTH_BUFFER_BIT"
  val GL_MODELVIEW = constWord "GL_MODELVIEW"
  val GL_QUADS = constWord "GL_QUADS"
  val GL_POSITION = constWord "GL_POSITION"
  val GL_LINE_LOOP = constWord "GL_LINE_LOOP"
  val GL_LINES = constWord "GL_LINES"
  val GL_POLYGON = constWord "GL_POLYGON"
  val GL_LINE_SMOOTH = constWord "GL_LINE_SMOOTH"
  val GL_POLYGON_SMOOTH = constWord "GL_POLYGON_SMOOTH"
  val GL_BLEND = constWord "GL_BLEND"
  val GL_SRC_ALPHA = constWord "GL_SRC_ALPHA"
  val GL_ONE_MINUS_SRC_ALPHA = constWord "GL_ONE_MINUS_SRC_ALPHA"
(*
  (* Mac OS X *)
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
*)

end

structure GLU =
struct

  type gluQuadricObj = word

  val gluPerspective =
      dlsym (libglu, "gluPerspective")
      : _import (real, real, real, real) -> unit
  val gluLookAt =
      dlsym (libglu, "gluLookAt")
      : _import (real, real, real, real, real, real, real, real, real) -> unit
  val gluNewQuadric =
      dlsym (libglu, "gluNewQuadric")
      : _import () -> gluQuadricObj
  val gluDeleteQuadric =
      dlsym (libglu, "gluDeleteQuadric")
      : _import gluQuadricObj -> unit
  val gluQuadricDrawStyle =
      dlsym (libglu, "gluQuadricDrawStyle")
      : _import (gluQuadricObj, word) -> unit
  val gluQuadricNormals =
      dlsym (libglu, "gluQuadricNormals")
      : _import (gluQuadricObj, word) -> unit
  val gluQuadricOrientation =
      dlsym (libglu, "gluQuadricOrientation")
      : _import (gluQuadricObj, word) -> unit
  val gluCylinder =
      dlsym (libglu, "gluCylinder")
      : _import (gluQuadricObj, real, real, real, int, int) -> unit
  val gluDisk =
      dlsym (libglu, "gluDisk")
      : _import (gluQuadricObj, real, real, int, int) -> unit

  val GLU_FILL = constWord "GLU_FILL"
  val GLU_SMOOTH = constWord "GLU_SMOOTH"
  val GLU_INSIDE = constWord "GLU_INSIDE"
(*
  (* Mac OS X *)
  val GLU_FILL = 0wx186AC
  val GLU_SMOOTH = 0wx186A0
  val GLU_INSIDE = 0wx186B5
*)

end

end (* local *)
