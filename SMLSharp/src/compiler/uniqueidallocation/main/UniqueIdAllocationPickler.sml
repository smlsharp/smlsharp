(**
 * Pickler for module compilation
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Kiyoshi Yamatodani
 * @version $Id: UniqueIdAllocationPickler.sml,v 1.15 2008/03/18 06:20:51 bochao Exp $
 *)
structure UniqueIdAllocationPickler =
struct

  (***************************************************************************)

  structure P = Pickle
  structure UIAC = UniqueIdAllocationContext
  structure VIC  = VarIDContext


  structure TFCPickler = TypedFlatCalcPickler
  structure TPickler = TypesPickler
  structure NPickler = NamePickler

  (* picklers for datatypes defined in PathEnv. *)

  val id_ty = P.tuple2(TFCPickler.id, TPickler.ty)

  val varIDItem : VIC.varIDItem P.pu =
      let
        fun toInt (VIC.External _) = 0
          | toInt (VIC.Internal _) = 1
          | toInt VIC.Dummy = 2
        fun pu_External pu =
          P.con1 
          VIC.External 
          (fn VIC.External x => x
            | _ => 
              raise 
                Control.Bug 
                "Internal to pu_External (modulecompilation/main/ModuleCompilationPickler.sml)"
           ) 
          ExVarID.pu_ID
        fun pu_Internal pu =
          P.con1 
          VIC.Internal 
          (fn VIC.Internal x => x
            | _ =>
              raise 
                Control.Bug 
                "External to pu_Internal (modulecompilation/main/ModuleCompilationPickler.sml)"
           ) 
          id_ty
        fun pu_Dummy pu = P.con0 VIC.Dummy pu
      in
        P.data (toInt, [pu_External, pu_Internal, pu_Dummy])
      end

  val topVarEnv : VIC.topVarIDEnv P.pu = EnvPickler.SEnv varIDItem
  val varIDEnv : VIC.varIDEnv P.pu = 
      NameMapPickler.NPEnv varIDItem

  val functorEnv : VIC.functorEnv P.pu =
      EnvPickler.SEnv
          (P.conv
               (
                fn (name:string, 
                    argName:string, 
                    argExternalVarIDEnv:VIC.varIDEnv, 
                    bodyExternalVarIDEnv:VIC.varIDEnv, 
                    generativeExternalVarIDSet) =>
                   {name = name, 
                    argName = argName, 
                    argExternalVarIDEnv = argExternalVarIDEnv, 
                    bodyExternalVarIDEnv = bodyExternalVarIDEnv, 
                    generativeExternalVarIDSet = generativeExternalVarIDSet},
                fn {name, argName, argExternalVarIDEnv, bodyExternalVarIDEnv, generativeExternalVarIDSet} =>
                   (name, argName, argExternalVarIDEnv, bodyExternalVarIDEnv, generativeExternalVarIDSet)
                   )
               (P.tuple5(P.string, 
                         P.string, 
                         varIDEnv,
                         varIDEnv,
                         NamePickler.ExternalVarIDSet
                        )
               )
          )
  
  (* ToDo : temporary, use empty pathFunEnv. *)
  val varIDBasis : VIC.varIDBasis P.pu =
      P.conv
          (fn x => x, fn (pathFunEnv, varIDEnv) => (SEnv.empty, varIDEnv))
          (P.tuple2(functorEnv, varIDEnv))


  (* ToDo : temporary empty funenv *)
  val topExternalVarIDBasis : VIC.topExternalVarIDBasis P.pu =
      P.conv
          (
            fn x => x,
            fn (pathFunEnv, varIDEnv) => (SEnv.empty, varIDEnv)
          )
          (P.tuple2(functorEnv, topVarEnv))
end
