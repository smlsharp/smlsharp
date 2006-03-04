(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: TypedFlatCalcPickler.sml,v 1.5 2006/02/27 06:31:09 bochao Exp $
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
            fn (id, displayName, ty) =>
               {id = id, displayName = displayName, ty = ty},
               fn {id, displayName, ty} => (id, displayName, ty)
          )
          (P.tuple3(id, P.string, TypesPickler.ty))

  (* ToDo : this is temporal imple.*)
  val tfpexp =
      let
        fun toInt (TFC.TFPCONSTANT _) = 0
        fun pu_TFPCONSTANT pu =
            P.con1
                TFC.TFPCONSTANT
                (fn (TFC.TFPCONSTANT x) => x)
                (P.tuple2(TypesPickler.constant, NamePickler.loc))
      in
        P.data (toInt, [pu_TFPCONSTANT])
      end

  (* ToDo : this is temporal imple.*)
  val tfpdecl =
      let
        fun toInt (TFC.TFPSETGLOBAL _) = 0
        fun pu_TFPSETGLOBAL pu =
            P.con1
                TFC.TFPSETGLOBAL
                (fn (TFC.TFPSETGLOBAL x) => x)
                (P.tuple3(P.string, tfpexp, NamePickler.loc))
      in
        P.data (toInt, [pu_TFPSETGLOBAL])
      end

  (***************************************************************************)

end
