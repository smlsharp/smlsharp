(**
 * utilities for variables.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: vars.sml,v 1.23 2006/02/28 16:11:10 kiyoshiy Exp $
 *)
structure TvOrd : ordsig =
struct 
  local open Types
  in
  type ord_key = tvState ref
  val compare =
      fn (
           ref(TVAR {id = id1, ...}) : tvState ref,
           ref(TVAR {id = id2, ...}) : tvState ref
         ) =>
         Types.tidCompare (id1, id2)
       | _ => raise Control.Bug "TvordCompare"
  end
end
   
structure TidOrd : ordsig =
struct 
  type ord_key = Types.tid
  val compare = Types.tidCompare
end
   

structure TEnv = BinaryMapFn(TidOrd)

structure OTSet = BinarySetFn(TvOrd)
(*
local 
  structure TMap = BinaryMapFn(TvOrd)
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

structure Vord : ordsig =
struct
  fun compare ({id = id1, displayName = n1, ty = ty1}, 
	       {id = id2, displayName = n2, ty = ty2}) =
      ID.compare(id1, id2)
  type ord_key = Types.varIdInfo
end

structure VEnv = BinaryMapFn(Vord)
structure VSet = BinarySetFn(Vord)

structure Cord:ordsig =
struct 
  type ord_key = Types.constant
  fun compare (x, y) = 
      case (x, y) of
	(Types.INT i1, Types.INT i2) => Int32.compare(i1, i2)
      | (Types.INT _, _) => LESS
      | (Types.WORD _, Types.INT _) => GREATER
      | (Types.WORD w1, Types.WORD w2) => Word32.compare (w1,w2)
      | (Types.WORD _, _) => LESS
      | (Types.STRING _, Types.INT _) => GREATER
      | (Types.STRING _, Types.WORD _) => GREATER
      | (Types.STRING s1, Types.STRING s2) => String.compare (s1, s2)
      | (Types.STRING _, _) => LESS
      | (Types.REAL r1, Types.INT _) => GREATER
      | (Types.REAL r1, Types.WORD _) => GREATER
      | (Types.REAL r1, Types.STRING _) => GREATER
      | (Types.REAL r1, Types.REAL r2) => String.compare(r1, r2)
      | (Types.REAL _, _) => LESS
      | (Types.CHAR _, Types.INT _) =>  GREATER
      | (Types.CHAR _, Types.WORD _) =>  GREATER
      | (Types.CHAR _, Types.STRING _) =>  GREATER
      | (Types.CHAR _, Types.REAL _) =>  GREATER
      | (Types.CHAR c1, Types.CHAR c2) =>  Char.compare(c1, c2)
end

structure CEnv = BinaryMapFn(Cord)

structure Vars =
struct

  local
    open Types

  (** system generated variable counter 
   * This is shared by all the calculus.
   *)
  val varNameSequence = SequentialNumber.generateSequence 0
  fun nextVarName () = SequentialNumber.generate varNameSequence
  fun freshName () = "$" ^ (Int.toString (nextVarName()))

  in

  (** for Absyn *)
  fun newASTVarName() = freshName()

  (** for PatternCalc *)
  fun newPLVarName() = freshName()

  (** for PatternCalcWithTvars *)
  fun newPTVarName() = freshName()

  (** for TypedCalc *)
  fun newTPVarName() = freshName()

  (* for typedflatCalc*)
  fun newTFPVarName() = freshName()

  (** for RecordCal *)
  fun newRCVarName() = freshName()

  (** for typedlambda *)

  fun newTLVar (id,ty) = {id = id,displayName = freshName(), ty = ty}

  (** for UBCalc *)
  fun newUBVar (ty, varKind) = {name = freshName(), ty = ty, varKind = varKind}

  val UBLabelidSequence = SequentialNumber.generateSequence 0
  fun nextUBLabelid () = SequentialNumber.generate UBLabelidSequence
  fun newUBLabel () = "L" ^ Int.toString (nextUBLabelid())

  (** initialize vars.
   * This should be called only one for each compilation unit.
   *)
  fun initVars () =
      (
        SequentialNumber.init varNameSequence;
        SequentialNumber.init UBLabelidSequence
      )

end

end
