(**
 * SAContext
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen
 * @version $$
 *)
structure SAContext : SACONTEXT = struct

  structure VEnv = VarID.Map
  structure AT = AnnotatedTypes
  structure AC = AnnotatedCalc

  type context = {varEnv : AC.varInfo VEnv.map, btvEnv : AT.btvEnv}

  val empty = {varEnv = VEnv.empty, btvEnv = IEnv.empty} : context

  fun insertVariable (context as {varEnv, btvEnv} : context) (varInfo as {displayName, ty, varId}) =
      case varId of
          Types.INTERNAL id =>
          {
           varEnv = VEnv.insert(varEnv, id, varInfo),
           btvEnv = btvEnv
          }
        | Types.EXTERNAL _ => context
      
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

  fun lookupVariable ({varEnv,...} : context) id (displayName, loc) =
      case VEnv.find(varEnv, id) of
        SOME varInfo => varInfo
      | NONE => 
          raise
            Control.BugWithLoc
            ("variable not found:" ^ displayName ^ "(" ^
             (VarID.toString id) ^ ")", 
             loc)

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
           case #recordKind (lookupTid context tid) of
             AT.REC flty => ft flty
           | _ => raise Control.Bug "invalid record tyvar"
          )
        | _ => raise Control.Bug "invalid record tyvar"
      end

end
