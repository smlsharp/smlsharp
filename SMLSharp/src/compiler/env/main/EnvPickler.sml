(**
 * picklers for data structures declared in env module.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: EnvPickler.sml,v 1.9 2008/08/06 07:59:47 ohori Exp $
 *)
structure EnvPickler
  : sig
      val IEnv : 'a Pickle.pu -> 'a IEnv.map Pickle.pu
      val SEnv : 'a Pickle.pu -> 'a SEnv.map Pickle.pu
      val IEnvLazy : 'a Pickle.pu -> 'a IEnvLazy.map Pickle.pu
      val SEnvLazy : 'a Pickle.pu -> 'a SEnvLazy.map Pickle.pu
      val ISet : ISet.set Pickle.pu
      val SSet : SSet.set Pickle.pu
    end =
struct

  (***************************************************************************)

  structure P = Pickle

  (***************************************************************************)

  fun IEnv (value_pu : 'value P.pu) : 'value IEnv.map P.pu =
      IEnv.pu_map (P.int, value_pu)

  fun SEnv (value_pu : 'value P.pu) : 'value SEnv.map P.pu =
      SEnv.pu_map (P.string, value_pu)

  fun IEnvLazy (value_pu : 'value P.pu) : 'value IEnvLazy.map P.pu =
      IEnvLazy.pu_map (P.int, value_pu)

  fun SEnvLazy (value_pu : 'value P.pu) : 'value SEnvLazy.map P.pu =
      SEnvLazy.pu_map (P.string, value_pu)

  val ISet : ISet.set P.pu = ISet.pu_set P.int

  val SSet : SSet.set P.pu = SSet.pu_set P.string

  (***************************************************************************)

end
