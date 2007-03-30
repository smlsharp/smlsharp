(**
 * Pickler of constant terms.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ConstantTermPickler.sml,v 1.2 2007/02/12 01:59:17 kiyoshiy Exp $
 *)
structure ConstantTermPickler =
struct

  structure P = Pickle
  structure T = ConstantTerm

  val constant =
      let
        fun toInt (T.INT _) = 0
          | toInt (T.WORD _) = 1
          | toInt (T.STRING _) = 2
          | toInt (T.REAL _) = 3
          | toInt (T.CHAR _) = 4
          | toInt T.UNIT = 5
        fun pu_INT pu = P.con1 T.INT (fn (T.INT x) => x) P.int32
        fun pu_WORD pu = P.con1 T.WORD (fn (T.WORD x) => x) P.word32
        fun pu_STRING pu = P.con1 T.STRING (fn (T.STRING x) => x) P.string
        fun pu_REAL pu = P.con1 T.REAL (fn (T.REAL x) => x) P.string
        fun pu_CHAR pu = P.con1 T.CHAR (fn (T.CHAR x) => x) P.char
      in
        P.data (toInt, [pu_INT, pu_WORD, pu_STRING, pu_REAL, pu_CHAR])
      end

end