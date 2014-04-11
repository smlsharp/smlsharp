(**
 * utilities for variables.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: vars.sml,v 1.35 2008/08/06 17:23:41 ohori Exp $
 *)
structure TvOrd : ORD_KEY =
struct 
  local 
    structure T = Types
  in
  type ord_key = T.tvState ref
  val compare =
     fn (
           ref(T.TVAR {id = id1, ...}) : T.tvState ref,
           ref(T.TVAR {id = id2, ...}) : T.tvState ref
         ) =>
         FreeTypeVarID.compare (id1, id2)
       | _ => raise Bug.Bug "TvordCompare"
  end
end
   
structure TidOrd : ORD_KEY =
struct 
  type ord_key = FreeTypeVarID.id
  val compare = FreeTypeVarID.compare
end
   
structure TEnv = BinaryMapFn(TidOrd)
structure OTSet = BinarySetFn(TvOrd)

structure varInfoOrd : ORD_KEY =
struct
  type ord_key = {path:string list, id:VarID.id, ty:Types.ty}
  fun compare ({path = _, ty = _, id = varId1} : ord_key, 
	       {path = _, ty = _, id = varId2} : ord_key) =
      VarID.compare (varId1, varId2)
end
structure VarInfoEnv = BinaryMapFn(varInfoOrd)
structure VarInfoSet = BinarySetFn(varInfoOrd)

(*
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
*)
