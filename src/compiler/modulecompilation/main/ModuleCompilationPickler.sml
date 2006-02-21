(**
 * Copyright (c) 2006, Tohoku University.
 * @author Kiyoshi Yamatodani
 * @version $Id: ModuleCompilationPickler.sml,v 1.12 2006/02/18 16:04:06 duchuu Exp $
 *)
structure ModuleCompilationPickler =
struct

  (***************************************************************************)

  structure P = Pickle

  structure TO = TopObject
  structure PE = PathEnv
  structure MC = ModuleContext

  structure TFCPickler = TypedFlatCalcPickler
  structure TPickler = TypesPickler
  structure NPickler = NamePickler
  (***************************************************************************)

  (* picklers for datatypes defined in TopObject. *)

  val pageType = P.int
  val pageArrayIndex = P.word32
  val offset = P.int
  val globalIndex : TO.globalIndex P.pu = P.tuple3(pageType, pageArrayIndex, offset)

  val freeEntryPointer : TO.freeEntryPointer P.pu =
      EnvPickler.IEnv (P.tuple2(pageArrayIndex, offset))

  (****************************************)

  (* picklers for datatypes defined in PathEnv. *)

  val pathVar_globalIndex_ty = 
      P.tuple3(P.tuple2(NamePickler.path, P.string), globalIndex, TPickler.ty)
  val pathVar_id_ty_loc = P.tuple4(P.tuple2(NamePickler.path, P.string), 
                            TFCPickler.id,
                            TPickler.ty,
                            NPickler.loc
                            )

  val pathVarItem : PE.pathVarItem P.pu =
      let
        fun toInt (PE.TopItem _) = 0
          | toInt (PE.CurItem _) = 1
        fun pu_TopItem pu =
            P.con1 PE.TopItem (fn PE.TopItem x => x) pathVar_globalIndex_ty
        fun pu_CurItem pu =
            P.con1 PE.CurItem (fn PE.CurItem x => x) pathVar_id_ty_loc
      in
        P.data (toInt, [pu_TopItem, pu_CurItem])
      end

  val (pathStrEnvEntryFunctions, pathStrEnvEntry) =
      P.makeNullPu (PE.PATHAUX(PE.emptyPathVarEnv, SEnv.empty))

  val pathVarEnv : PE.pathVarEnv P.pu = EnvPickler.SEnv pathVarItem
  val pathStrEnv : PE.pathStrEnv P.pu = EnvPickler.SEnv pathStrEnvEntry
  val pathEnv : PE.pathEnv P.pu = P.tuple2(pathVarEnv, pathStrEnv)
  val pathFunEnv : PE.pathFunEnv P.pu =
      EnvPickler.SEnv
          (P.tuple3
               (pathStrEnv, pathEnv, P.list TFCPickler.tfpdecl))
  (* ToDo : temporary, use empty pathFunEnv. *)
  val pathBasis : PE.pathBasis P.pu =
      P.conv
          (fn x => x, fn (pathFunEnv, pathEnv) => (SEnv.empty, pathEnv))
          (P.tuple2(pathFunEnv, pathEnv))

  local
    (* implement real pickler for pathStrEnvEntry. *)
    val newPathStrEnvEntry =
        let
          fun toInt (PE.PATHAUX _) = 0
          fun pu_PATHAUX pu =
              P.con1
                  PE.PATHAUX
                  (fn PE.PATHAUX x => x) 
                  (P.tuple2(pathVarEnv, EnvPickler.SEnv pathStrEnvEntry))
        in
          P.data (toInt, [pu_PATHAUX])
        end
  in
  val _ = P.updateNullPu pathStrEnvEntryFunctions newPathStrEnvEntry
  end

  (* ToDo : temporary empty funenv *)
  val topPathBasis : PE.topPathBasis P.pu =
      P.conv
          (
            fn x => x,
            fn (pathFunEnv, pathStrEnv) => (SEnv.empty, pathStrEnv)
          )
          (P.tuple2(pathFunEnv, pathStrEnv))

  (****************************************)

  val context : MC.context P.pu =
      P.conv
          (
            fn (topPathBasis, pathBasis, prefix) =>
               {
                 topPathBasis = topPathBasis,
                 pathBasis = pathBasis,
                 prefix = prefix
               },
            fn {topPathBasis, pathBasis,  prefix} =>
               (topPathBasis, pathBasis,  prefix)
          )
          (P.tuple3
             (topPathBasis, pathBasis, NamePickler.path))

  (****************************************)

  val moduleEnv : ModuleCompiler.moduleEnv P.pu =
      P.conv
          (
            fn (freeEntryPointer, topPathBasis) =>
               {
                 freeEntryPointer = freeEntryPointer,
                 topPathBasis = topPathBasis
               },
            fn {freeEntryPointer, topPathBasis} =>
               (freeEntryPointer, topPathBasis)
          )
          (P.tuple2(freeEntryPointer, topPathBasis))

  (***************************************************************************)

end
