(**
 * @copyright (c) 2007, Tohoku University.
 * @author Isao Sasano
 * @version $Id: InlineUtils.sml,v 1.13 2008/08/06 17:23:40 ohori Exp $
 *)

structure InlineUtils = 
struct

local
structure AT = AnnotatedTypes
structure ATU = AnnotatedTypesUtils
structure T = Types
in

val localInlineNum = ref 0
val localPolyInlineNum = ref 0
val globalInlineNum = ref 0
val globalPolyInlineNum = ref 0
val wholeInlineNum = ref 0

fun wholeInlineCount () = 
    " (" ^
    "L=" ^ (Int.toString (!localInlineNum)) ^ ", " ^
    "G=" ^ (Int.toString (!globalInlineNum)) ^ ", " ^
    "PL=" ^ (Int.toString (!localPolyInlineNum)) ^ ", " ^
    "PG=" ^ (Int.toString (!globalPolyInlineNum)) ^ ", " ^
    "WHOLE=" ^ (Int.toString (!wholeInlineNum)) ^ 
    ")"

fun printLocalInline displayName =
    print ("Local inline [" ^ 
	   (Int.toString (!localInlineNum)) ^ 
	   "]: " ^ displayName ^ wholeInlineCount () ^ "\n")

fun localInlineCount displayName = 
    (localInlineNum := (!localInlineNum) + 1;
     wholeInlineNum := (!wholeInlineNum) + 1;
     printLocalInline displayName)

fun printGlobalInline displayName =
    print ("Global inline [" ^ 
	   (Int.toString (!globalInlineNum)) ^ 
	   "]: " ^ displayName ^ wholeInlineCount () ^ "\n")

fun globalInlineCount displayName = 
    (globalInlineNum := !globalInlineNum + 1;
     wholeInlineNum := (!wholeInlineNum) + 1;
     printGlobalInline displayName)

fun printLocalPolyInline displayName =
    print ("Local poly inline [" ^ 
	   (Int.toString (!localPolyInlineNum)) ^ 
	   "]: " ^ displayName ^ wholeInlineCount () ^ "\n")

fun localPolyInlineCount displayName = 
    (localPolyInlineNum := !localPolyInlineNum + 1;
     wholeInlineNum := (!wholeInlineNum) + 1;
     printLocalPolyInline displayName)

fun printGlobalPolyInline displayName =
    print ("Global poly inline [" ^ 
	   (Int.toString (!globalPolyInlineNum)) ^ 
	   "]: " ^ displayName ^ wholeInlineCount () ^ "\n")

fun globalPolyInlineCount displayName = 
    (globalPolyInlineNum := !globalPolyInlineNum + 1;
     wholeInlineNum := (!wholeInlineNum) + 1;
     printGlobalPolyInline displayName)

fun printLoc loc = print ("Loc is " ^ Control.prettyPrint (Loc.format_loc loc) ^ "\n")

fun printRenameEnv env =
    VarID.Map.appi 
	(fn (id,newId) => 
	    (print ("  " ^
		    Control.prettyPrint (VarID.format_id id) ^
		    " |-> " ^
		    Control.prettyPrint (VarID.format_id newId) ^
		    "\n")))
	env

fun printLocalEnv env =
    VarID.Map.appi 
	(fn (id,inlineInfo) => 
	    (print ("  " ^
		    Control.prettyPrint (VarID.format_id id) ^
		    " |-> ");
	     InlineEnv.printInlineInfo inlineInfo))
	env
	
fun changeTY newTY {varId,displayName,ty} =
    {varId=varId,displayName=displayName,ty=newTY}

fun changeID newID {varId,displayName,ty} =
    case varId of
	T.INTERNAL id =>
	{varId=T.INTERNAL newID,displayName=displayName,ty=ty}
      | T.EXTERNAL _ =>
	raise Control.Bug "inliner bug about changeID"

fun bodyTy (AT.FUNMty {bodyTy,...}) = bodyTy
  | bodyTy _ = raise Control.Bug "function type is expected"

fun renameID {varId,displayName,ty} =
    case varId of
	T.INTERNAL id =>
	let
	    val id = Counters.newLocalID ()
	in
	    {varId=T.INTERNAL id, displayName=displayName, ty=ty}
	end
      | T.EXTERNAL _ =>
	raise Control.Bug "inliner bug about renameID"

fun typeSubst subst ty =
    case ty of
        AT.BOUNDVARty tid =>
        (case BoundTypeVarID.Map.find(subst,tid) of
             SOME ty => ty
           | NONE => ty
        )
      | AT.FUNMty {annotation, argTyList, bodyTy, funStatus} =>
        AT.FUNMty
            {
             argTyList = map (typeSubst subst) argTyList,
             bodyTy = typeSubst subst bodyTy,
             annotation = annotation,
             funStatus = funStatus
            }
      | AT.MVALty tyList => AT.MVALty (map (typeSubst subst) tyList)
      | AT.RECORDty {fieldTypes, annotation} =>
        AT.RECORDty
            {
             fieldTypes = SEnv.map (typeSubst subst) fieldTypes,
             annotation = annotation
            }
      | AT.RAWty {tyCon, args} =>
        AT.RAWty {tyCon = tyCon, args = map (typeSubst subst) args}
(*
      | AT.POLYty {boundtvars, body} =>
        AT.POLYty
            {
             boundtvars = boundtvars,  (* keep original kinds*)
             body = typeSubst subst body
            }
*)
      (* do renaming of bound type variables *)
      | AT.POLYty {boundtvars, body} =>
	let val (substitution,boundtvars) = 
                copyBtvEnv boundtvars
	    val subst = BoundTypeVarID.Map.foldri (fn (oldId,btv,subst) => BoundTypeVarID.Map.insert (subst,oldId,btv))
				    subst substitution
	in
            AT.POLYty
		{
(*
		 boundtvars = boundtvars,  (* keep original kinds*)
*)
		 boundtvars = substituteBtvEnv subst boundtvars,
		 body = typeSubst subst body
		}
	end
(*
      | AT.SPECty ty => AT.SPECty (typeSubst subst ty)
*)
      | _ => ty

  and substituteBtvEnv subst btvEnv =
      BoundTypeVarID.Map.map (substituteBtvKind subst) btvEnv

  and substituteBtvKind subst {id, recordKind, eqKind, instancesRef = ref instances} =
      {
       id = id,
       recordKind = substituteRecKind subst recordKind,
       eqKind = eqKind,
       instancesRef = ref (map (typeSubst subst) instances)
      }

  and substituteRecKind subst recordKind =
      case recordKind of 
        AT.UNIV => AT.UNIV
      | AT.REC flty => AT.REC (SEnv.map (typeSubst subst) flty)
      | AT.OPRIMkind {instances, operators} => 
        AT.OPRIMkind
          {instances = map (typeSubst subst) instances,
           operators =
             map
               (fn {oprimId,oprimPolyTy,name,keyTyList,instTyList} =>
                   {
                    oprimId = oprimId,
                    oprimPolyTy = typeSubst subst oprimPolyTy,
                    name = name,
                    keyTyList = map (typeSubst subst) keyTyList,
                    instTyList = map (typeSubst subst) instTyList
                   }
               )
               operators
          }


  (* This function makes a copy of btvEnv with new bound type variables
   * and returns that with the substitution of bound type variables. 
   *)
  and copyBtvEnv btvEnv =
      let 
	  val newSubst = 
              BoundTypeVarID.Map.map (fn _ => 
                           let
                               val newBoundVarId = BoundTypeVarID.generate ()
                           in AT.BOUNDVARty (newBoundVarId) end) 
                       btvEnv
	  val newBtvEnv = BoundTypeVarID.Map.foldri
			      (fn (oldId, {id,recordKind,eqKind,instancesRef}, newBtvEnv) =>
				  let val newId =
					  case BoundTypeVarID.Map.find (newSubst, oldId) of
					      SOME (AT.BOUNDVARty newId) => newId
					    | _ => raise Control.Bug "copyBtvEnv"
				      val recordKind = substituteRecKind newSubst recordKind
				      val btvKind = {id=newId,
						     recordKind=recordKind,
						     eqKind=eqKind,
						     instancesRef=instancesRef
						    }
				  in
				      BoundTypeVarID.Map.insert (newBtvEnv, newId, btvKind)
				  end)
			      BoundTypeVarID.Map.empty btvEnv
      in
	  (newSubst, newBtvEnv)
      end

fun substitute subst ty =
    case subst of
	NONE => ty
      | SOME subst => typeSubst subst ty

fun substVarInfo subst {varId,displayName,ty} =
    let val ty = substitute subst ty
    in 
	{varId=varId, displayName=displayName, ty=ty}
    end
    
fun insertTyEnv (subst, key, ty) =
    case subst of
	NONE => SOME (BoundTypeVarID.Map.insert (BoundTypeVarID.Map.empty, key, ty))
      | SOME subst => SOME (BoundTypeVarID.Map.insert (subst, key, ty))

end
end
