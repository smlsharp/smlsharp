(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: BoundTypeVarID.sml,v 1.2 2008/08/06 02:08:01 ohori Exp $
 *)
structure BoundTypeVarID
  : sig
      type boundTypeVarID
      val maxReservedBoundTypeVarID : boundTypeVarID
      val initialReservedBoundTypeVarID : boundTypeVarID
      val nextReservedBoundTypeVarID : boundTypeVarID -> boundTypeVarID
      val nextNthReservedBoundTypeVarID : boundTypeVarID -> int -> boundTypeVarID
      val initialBoundTypeVarID  : boundTypeVarID
      val nextBoundTypeVarID : boundTypeVarID -> boundTypeVarID
      val nextNthBoundTypeVarID  : boundTypeVarID -> int -> boundTypeVarID
      val pu_boundTypeVarID : boundTypeVarID Pickle.pu
    end 
  =
struct
  type boundTypeVarID = int
  val maxReservedBoundTypeVarID = 100
  val initialReservedBoundTypeVarID = 0
  fun nextReservedBoundTypeVarID boundVarID = 
    if (boundVarID +  1) > maxReservedBoundTypeVarID then
      raise Control.Bug "exceed maximum reserved bound type variable!\n"
    else boundVarID +  1
  fun nextNthReservedBoundTypeVarID boundVarID n =
    if (boundVarID +  n) > maxReservedBoundTypeVarID then
      raise Control.Bug "exceed maximum reserved bound type variable!\n"
    else
      boundVarID + n
  val initialBoundTypeVarID = maxReservedBoundTypeVarID + 1
  fun nextBoundTypeVarID boundVarID = 
    boundVarID +  1
  fun nextNthBoundTypeVarID boundVarID n =
    boundVarID + n
  val pu_boundTypeVarID = Pickle.int
end

