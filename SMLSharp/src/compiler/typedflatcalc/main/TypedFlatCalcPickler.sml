(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypedFlatCalcPickler.sml,v 1.10 2008/01/22 06:31:36 bochao Exp $
 *)
structure TypedFlatCalcPickler =
struct

  (***************************************************************************)

  structure P = Pickle
  structure TFC = TypedFlatCalc

  (***************************************************************************)

  val id : TFC.id P.pu = NamePickler.id



  val varIdInfo : TFC.varIdInfo P.pu =
      P.conv
          (
            fn (displayName, ty, varId) =>
               {displayName = displayName, ty = ty, varId = varId},
               fn {displayName, ty, varId} => (displayName, ty, varId)
          )
          (P.tuple3(P.string, TypesPickler.ty, TypesPickler.varId))

  (* ToDo : this is temporal imple.*)
  val tfpexp =
      let
        fun toInt (TFC.TFPCONSTANT _) = 0
          | toInt _ = raise Control.Bug "incomplete (typedflatcalc/main/TypedFlatCalcPickler.sml)"
        fun pu_TFPCONSTANT pu =
            P.con1
                TFC.TFPCONSTANT
                (fn (TFC.TFPCONSTANT x) => x
                  | _ => 
                    raise 
                      Control.Bug 
                      "non TFPCONSTANT to pu_TFPCONSTANT (typedflatcalc/main/TypedFlatCalcPickler.sml)"
                 )
                (P.tuple2(ConstantTermPickler.constant, NamePickler.loc))
      in
        P.data (toInt, [pu_TFPCONSTANT])
      end

(*
  (* ToDo : this is temporal imple.*)
  val tfpdecl =
      let
        fun toInt (TFC.TFPSETGLOBAL _) = 0
          | toInt _ = raise Control.Bug "incomplete (typedflatcalc/main/TypedFlatCalcPickler.sml)"
        fun pu_TFPSETGLOBAL pu =
            P.con1
                TFC.TFPSETGLOBAL
                (fn (TFC.TFPSETGLOBAL x) => x
                  | _ => 
                    raise 
                      Control.Bug 
                      "non TFPSETGLOBAL to pu_TFPSETGLOBAL (typedflatcalc/main/TypedFlatCalcPickler.sml)"
                 )
                (P.tuple3(P.string, tfpexp, NamePickler.loc))
      in
        P.data (toInt, [pu_TFPSETGLOBAL])
      end
*)
  (* ToDo : this is temporal imple.*)
  val tfpdecl =
      let
        fun toInt (TFC.TFPSETFIELD _) = 0
          | toInt _ = raise Control.Bug "incomplete (typedflatcalc/main/TypedFlatCalcPickler.sml)"
        fun pu_TFPSETFIELD pu =
            P.con1
                TFC.TFPSETFIELD
                (fn (TFC.TFPSETFIELD x) => x
                  | _ => 
                    raise 
                      Control.Bug 
                      "non TFPSETFIELD to pu_TFPSETFIELD (typedflatcalc/main/TypedFlatCalcPickler.sml)"
                 )
                (P.tuple5(tfpexp, tfpexp, P.int, TypesPickler.ty, NamePickler.loc))
      in
        P.data (toInt, [pu_TFPSETFIELD])
      end

  (***************************************************************************)

end
