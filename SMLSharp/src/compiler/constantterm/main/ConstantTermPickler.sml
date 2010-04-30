(**
 * Pickler of constant terms.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ConstantTermPickler.sml,v 1.1 2008/11/19 19:57:44 ohori Exp $
 *)
structure ConstantTermPickler =
struct

  structure P = Pickle
  structure T = ConstantTerm

  val constant =
      let
        fun toInt (T.INT _) = 0
          | toInt (T.LARGEINT _) = 1
          | toInt (T.WORD _) = 2
          | toInt (T.BYTE _) = 3
          | toInt (T.STRING _) = 4
          | toInt (T.REAL _) = 5
          | toInt (T.FLOAT _) = 6
          | toInt (T.CHAR _) = 7
          | toInt T.UNIT = 8
          | toInt T.NULL = 9
        fun pu_INT pu = 
          P.con1 
          T.INT 
          (fn (T.INT x) => x
            | _ => 
              raise 
                Control.Bug "non INT to pu_INT (primitives/compiler/main/ConstantTermPickler.sml)"
           ) 
          P.int32
        fun pu_LARGEINT pu =
          P.con1
          T.LARGEINT
          (fn (T.LARGEINT x) => x
            | _ => 
              raise 
                Control.Bug "non LARGEINT to pu_LARGEINT (primitives/compiler/main/ConstantTermPickler.sml)"
           )
          (P.conv (valOf o BigInt.fromString, BigInt.toString) P.string)
        fun pu_WORD pu = 
          P.con1 
          T.WORD 
          (fn (T.WORD x) => x
            | _ => 
              raise 
                Control.Bug "non WORD to pu_WORD (primitives/compiler/main/ConstantTermPickler.sml)"
           ) 
          P.word32
        fun pu_BYTE pu = 
          P.con1 
          T.BYTE 
          (fn (T.BYTE x) => x
            | _ => 
              raise 
                Control.Bug "non WORD to pu_WORD (primitives/compiler/main/ConstantTermPickler.sml)"
           ) 
          P.word32
        fun pu_STRING pu = 
          P.con1 
          T.STRING 
          (fn (T.STRING x) => x
            | _ => 
              raise 
                Control.Bug "non STRING to pu_STRING (primitives/compiler/main/ConstantTermPickler.sml)"
           ) 
          P.string
        fun pu_REAL pu = 
          P.con1 
          T.REAL 
          (fn (T.REAL x) => x
            | _ => 
              raise 
                Control.Bug "non REAL to pu_REAL (primitives/compiler/main/ConstantTermPickler.sml)"
           ) 
          P.string
        fun pu_FLOAT pu = 
          P.con1 
          T.FLOAT 
          (fn (T.FLOAT x) => x
            | _ => 
              raise 
                Control.Bug "non FLOAT to pu_FLOAT (primitives/compiler/main/ConstantTermPickler.sml)"
           ) 
          P.string
        fun pu_CHAR pu = 
          P.con1 
          T.CHAR 
          (fn (T.CHAR x) => x
            | _ => 
              raise 
                Control.Bug "non CHAR to pu_CHAR (primitives/compiler/main/ConstantTermPickler.sml)"
           ) 
          P.char
      in
        P.data
            (
              toInt,
              [pu_INT, pu_LARGEINT, pu_WORD, pu_STRING, pu_REAL, pu_FLOAT, pu_CHAR]
            )
      end

end
