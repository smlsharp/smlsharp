(**
 *
 * pickler for name module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: NamePickler.sml,v 1.19 2008/08/06 17:23:40 ohori Exp $
 *)
structure NamePickler 
 : sig
     val id : VarID.id Pickle.pu
     val IDMap : 'value Pickle.pu -> 'value VarID.Map.map Pickle.pu
     val IDSet : VarID.Set.set Pickle.pu
     val TyConIDMap : 'value Pickle.pu -> 'value TyConID.Map.map Pickle.pu
     val TyConIDSet : TyConID.Set.set Pickle.pu
     val ExternalVarIDMap : 
       'value Pickle.pu -> 'value ExternalVarID.Map.map Pickle.pu
     val ExternalVarIDSet : ExternalVarID.Set.set Pickle.pu
     val ExnTagIDMap : 'value Pickle.pu -> 'value ExnTagID.Map.map Pickle.pu
     val ExnTagIDSet : ExnTagID.Set.set Pickle.pu
     val pos : Loc.pos Pickle.pu
     val loc : Loc.loc Pickle.pu
     val path : Path.path Pickle.pu
   end =
struct

  (***************************************************************************)

  structure P = Pickle

  (***************************************************************************)

  val id = VarID.pu_ID

  val externalVarID = ExternalVarID.pu_ID

  val tyConID = TyConID.pu_ID

  val tag = ExnTagID.pu_ID

  structure IDMapPickler = OrdMapPickler(VarID.Map)
  fun IDMap value_pu = IDMapPickler.map (id, value_pu)

  structure IDSetPickler = OrdSetPickler(VarID.Set)
  val IDSet = IDSetPickler.set id

  structure TyConIDMapPickler = OrdMapPickler(TyConID.Map)
  fun TyConIDMap value_pu = TyConIDMapPickler.map (tyConID, value_pu)

  structure TyConIDSetPickler = OrdSetPickler(TyConID.Set)
  val TyConIDSet = TyConIDSetPickler.set tyConID

  structure ExternalVarIDMapPickler = OrdMapPickler(ExternalVarID.Map)

  fun ExternalVarIDMap value_pu = 
    ExternalVarIDMapPickler.map (externalVarID, value_pu)

  structure ExternalVarIDSetPickler = OrdSetPickler(ExternalVarID.Set)
  val ExternalVarIDSet = ExternalVarIDSetPickler.set externalVarID

  structure ExnTagIDMapPickler = OrdMapPickler(ExnTagID.Map)
  fun ExnTagIDMap value_pu = ExnTagIDMapPickler.map (tag, value_pu)

  structure ExnTagIDSetPickler = OrdSetPickler(ExnTagID.Set)
  val ExnTagIDSet = ExnTagIDSetPickler.set tag

  val pos =
      P.conv
          (
            fn (fileName, line, col) =>
               Loc.makePos{fileName = fileName, line = line, col = col},
            fn pos =>
               (Loc.fileNameOfPos pos, Loc.lineOfPos pos, Loc.colOfPos pos)
          )
          (P.tuple3 (P.string, P.int, P.int))

  val loc = P.tuple2 (pos, pos)

  val path =
    let
      fun toInt Path.NilPath = 0
        | toInt (Path.PUsrStructure _) = 1
        | toInt (Path.PSysStructure _) = 2

      fun pu_NilPath pu = P.con0 Path.NilPath pu
      fun pu_PUsrStructure pu =
        P.con1
        Path.PUsrStructure
        (fn Path.PUsrStructure arg => arg
          | Path.PSysStructure arg => 
              raise Control.Bug "non PUsrStructure to pu_PUsrStructure"
          | Path.NilPath => 
              raise Control.Bug "non PUsrStructure to pu_PUsrStructure")
        (P.tuple2 (P.string, pu))
      fun pu_PSysStructure pu =
        P.con1
        Path.PSysStructure
        (fn Path.PSysStructure arg => arg
          | Path.PUsrStructure arg => 
             raise 
             Control.Bug 
             "PUsrStructure to pu_PStructure (name/main/NamePickler.sml)"
          | Path.NilPath => 
             raise 
             Control.Bug 
             "NilPath to pu_PStructure (name/main/NamePickler.sml)"
        )
        (P.tuple2 (P.string, pu))
    in
      P.data (toInt, [pu_NilPath, pu_PUsrStructure, pu_PSysStructure])
    end
end
