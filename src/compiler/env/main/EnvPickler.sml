(**
 * Copyright (c) 2006, Tohoku University.
 *
 * picklers for data structures declared in env module.
 * @author YAMATODANI Kiyoshi
 * @version $Id: EnvPickler.sml,v 1.2 2006/02/18 04:59:21 ohori Exp $
 *)
structure EnvPickler
  : sig

      val IEnv : 'a Pickle.pu -> 'a IEnv.map Pickle.pu
      val SEnv : 'a Pickle.pu -> 'a SEnv.map Pickle.pu

      val ISet : ISet.set Pickle.pu
      val SSet : SSet.set Pickle.pu

    end =
struct

  (***************************************************************************)

  structure P = Pickle
  structure IEnvPickler = OrdMapPickler(IEnv)
  structure SEnvPickler = OrdMapPickler(SEnv)
  structure ISetPickler = OrdSetPickler(ISet)
  structure SSetPickler = OrdSetPickler(SSet)

  (***************************************************************************)

  fun IEnv (value_pu : 'value P.pu) : 'value IEnv.map P.pu =
      IEnvPickler.map (P.int, value_pu)

  fun SEnv (value_pu : 'value P.pu) : 'value SEnv.map P.pu =
      SEnvPickler.map (P.string, value_pu)

  val ISet : ISet.set P.pu = ISetPickler.set P.int

  val SSet : SSet.set P.pu = SSetPickler.set P.string

  (***************************************************************************)

end
