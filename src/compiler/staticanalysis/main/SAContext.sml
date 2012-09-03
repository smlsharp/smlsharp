(**
 * SAContext
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure SAContext : SACONTEXT = struct

  structure VEnv = ID.Map
  structure AT = AnnotatedTypes
  structure AC = AnnotatedCalc

  type context = {varEnv : AC.varInfo VEnv.map, btvEnv : AT.btvEnv}

  val empty = {varEnv = VEnv.empty, btvEnv = IEnv.empty} : context

  fun insertVariable ({varEnv, btvEnv} : context) (varInfo as {id, displayName, ty}) =
      {
       varEnv = VEnv.insert(varEnv, id, varInfo),
       btvEnv = btvEnv
      }
      
  fun insertVariables context [] = context
    | insertVariables context (var::rest) =
      insertVariables (insertVariable context var) rest

  fun insertBtvEnv ({varEnv, btvEnv} : context) btvKinds =
      {
       varEnv = varEnv,
       btvEnv =
       IEnv.foldli
           (fn (tid, btvKind, S) => IEnv.insert(S, tid, btvKind))
           btvEnv
           btvKinds
      }

  fun lookupVariable ({varEnv,...} : context) id =
      case VEnv.find(varEnv, id) of
        SOME varInfo => varInfo
      | NONE => raise Control.Bug "variable not found"

  fun lookupTid ({btvEnv,...} : context) tid =
      case IEnv.find(btvEnv, tid) of
        SOME btvKind => btvKind
      | NONE => raise Control.Bug ("type variable not found " ^ (Int.toString tid))

  fun fieldType (context as {btvEnv,...} : context) (recordType, label) =
      let
        fun ft flty =
            case SEnv.find(flty, label) of
              SOME ty => ty
            | _ => raise Control.Bug "label not found"
      in
        case recordType of
          AT.RECORDty {fieldTypes,...} => ft fieldTypes
        | AT.BOUNDVARty tid =>
          (
           case #recKind (lookupTid context tid) of
             AT.REC flty => ft flty
           | _ => raise Control.Bug "invalid record tyvar"
          )
        | _ => raise Control.Bug "invalid record tyvar"
      end

end
