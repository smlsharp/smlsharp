(*
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: VarIDContextPickler.sml,v 1.3 2008/03/18 06:20:50 bochao Exp $
 *)
structure VarIDContextPickler =
struct
      structure VIC = VarIDContext 
      structure P = Pickle
      val varIDItem : VIC.varIDItem Pickle.pu  =
          let
              fun toInt (VIC.External _) = 0
                | toInt (VIC.Internal _) = 1
                | toInt VIC.Dummy = 2

              fun pu_EXTERNAL pu =
                  P.con1
                      VIC.External
                      (fn (VIC.External x) => x
                        | _ => raise Control.Bug "non EXTERNAL to pu_EXTERNAL"
                      )
                      (ExVarID.pu_ID)

              fun pu_INTERNAL pu =
                  P.con1
                      VIC.Internal
                      (fn (VIC.Internal x) => x
                        | _ => raise Control.Bug "non INTERNAL to pu_INTERNAL"
                      )
                      (P.tuple2(NamePickler.id, TypesPickler.ty))

              fun pu_Dummy pu = P.con0 VIC.Dummy pu
          in
              P.data (toInt, [pu_EXTERNAL, pu_INTERNAL, pu_Dummy])
          end

      val topVarIDEnv : VIC.topVarIDEnv Pickle.pu = EnvPickler.SEnv varIDItem 
end
