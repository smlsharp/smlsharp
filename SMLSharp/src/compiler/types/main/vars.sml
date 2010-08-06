(**
 * utilities for variables.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: vars.sml,v 1.35 2008/08/06 17:23:41 ohori Exp $
 *)
structure TvOrd : ORD_KEY =
struct 
  local open Types
  in
  type ord_key = tvState ref
  val compare =
      fn (
           ref(TVAR {id = id1, ...}) : tvState ref,
           ref(TVAR {id = id2, ...}) : tvState ref
         ) =>
         FreeTypeVarID.compare (id1, id2)
       | _ => raise Control.Bug "TvordCompare"
  end
end
   
structure TidOrd : ORD_KEY =
struct 
  type ord_key = FreeTypeVarID.id
  val compare = FreeTypeVarID.compare
end
   

structure TEnv = BinaryMapMaker(TidOrd)

structure OTSet = BinarySetFn(TvOrd)
(*
local 
  structure TMap = BinaryMapMaker(TvOrd)
in
  (*
   * A set of type variables that preserve the insertion order.
   * OTSet.listItems returns the list of type varibales in the order of 
     addition.  This additional property is needed to represent a polytype
   *)
  structure OTSet = struct
    type set = int * int TMap.map
    val empty = (0,TMap.empty)
    fun isEmpty (n,otset) = TMap.isEmpty otset
    fun singleton ty = (1, TMap.singleton (ty,1))
    fun add ((n,otset),ty) = 
      if TMap.inDomain(otset,ty) then (n,otset)
      else (n+1, TMap.insert(otset, ty, n+1))
    fun addi ((n,otset),ty,m) = 
      if TMap.inDomain(otset,ty) then (n,otset)
      else (Int.max(n,m), TMap.insert(otset, ty, m))
    fun member((n,otset), ty) = TMap.inDomain(otset,ty)
    fun union((n1,otset1),(n2,otset2)) =
      (n1 + n2, TMap.unionWith #1 (otset1, TMap.map (fn x => x + n1) otset2))
    fun difference((n1,otset1), (n2,otset2)) =
      (n1,
       TMap.foldli
       (fn (tv,_,otset) =>
        if TMap.inDomain(otset, tv) then #1 (TMap.remove(otset,tv))
        else otset)
       otset1
       otset2)
    fun foldr f result (n,otset) = TMap.foldri (fn (x,y,z) => f (x,z)) result otset 
    fun foldri f result (n,otset) = TMap.foldri f result otset 
    fun remove ((n,otset), tv) = (n,#1 (TMap.remove(otset,tv)))
    fun listItems (n,otset) =
      IEnv.listItems
      (TMap.foldri 
       (fn (tv,n,ienv) =>IEnv.insert(ienv,n,tv))
       IEnv.empty
       otset)
  end
end

*)
(*********************************************************)
structure VarIdOrd : ORD_KEY =
struct
  fun compare (ID1, ID2) =
      (* 
       * stipulation : external > internal
       *)
      case (ID1, ID2) of
          (Types.INTERNAL id1, Types.INTERNAL id2) => VarID.compare(id1, id2)
        | (Types.INTERNAL _, Types.EXTERNAL _) => LESS
        | (Types.EXTERNAL _, Types.INTERNAL _) => GREATER
        | (Types.EXTERNAL index1, Types.EXTERNAL index2) => ExVarID.compare (index1, index2)

  type ord_key = Types.varId
end

structure VarIdEnv = BinaryMapMaker(VarIdOrd)
structure VarIdSet = BinarySetFn(VarIdOrd)

(*********************************************************)
structure Vord : ORD_KEY =
struct
  fun compare ({displayName = n1, ty = ty1, varId = varId1}, 
	       {displayName = n2, ty = ty2, varId = varId2}) =
      VarIdEnv.Key.compare (varId1, varId2)
  type ord_key = Types.varIdInfo
end
structure VarEnv = BinaryMapMaker(Vord)
structure VarSet = BinarySetFn(Vord)

(*********************************************************)

(*
structure Vars =
struct
   fun freshName () = 
    let
        val int = VarNameGen.generate ()
    in
        "$" ^ (Int.toString int)
    end
end
*)
