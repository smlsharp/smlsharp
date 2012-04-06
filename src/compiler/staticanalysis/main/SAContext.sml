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

  type context = {varEnv : AC.varInfo VEnv.map, exVarEnv : AC.exVarInfo PathEnv.map, btvEnv : AT.btvEnv}

  val empty = {varEnv = VEnv.empty, exVarEnv = PathEnv.empty, btvEnv = BoundTypeVarID.Map.empty} : context

  fun insertVariable (context as {varEnv, exVarEnv, btvEnv} : context) (varInfo as {id,...}) =
      {
        varEnv = VEnv.insert(varEnv, id, varInfo),
        exVarEnv = exVarEnv,
        btvEnv = btvEnv
      }
      
  fun insertVariables context [] = context
    | insertVariables context (var::rest) =
      insertVariables (insertVariable context var) rest

  fun insertExVar (context:context) (exVarInfo as {path,...}) =
      {
        varEnv = #varEnv context,
        exVarEnv = PathEnv.insert (#exVarEnv context, path, exVarInfo),
        btvEnv = #btvEnv context
      } : context

  fun insertBtvEnv ({varEnv, exVarEnv, btvEnv} : context) btvKinds =
      {
       varEnv = varEnv,
       exVarEnv = exVarEnv,
       btvEnv =
       BoundTypeVarID.Map.foldli
           (fn (tid, btvKind, S) => BoundTypeVarID.Map.insert(S, tid, btvKind))
           btvEnv
           btvKinds
      }

  fun lookupVariable ({varEnv,...} : context)
                     ({path, id, ty}:TypedLambda.varInfo) loc =
      case VEnv.find(varEnv, id) of
        SOME varInfo => varInfo
      | NONE => 
          raise
            Control.BugWithLoc
            ("variable not found:" ^ String.concatWith "." path ^ "(" ^
             (VarID.toString id) ^ ")", 
             loc)

  fun lookupExVar ({exVarEnv,...} : context)
                  ({path, ty}:TypedLambda.exVarInfo) loc =
      case PathEnv.find (exVarEnv, path) of
        SOME varInfo => varInfo
      | NONE =>
          raise
            Control.BugWithLoc
            ("exvar not found (SAContext):" ^ String.concatWith "." path, loc)

  fun lookupTid ({btvEnv,...} : context) tid =
      case BoundTypeVarID.Map.find(btvEnv, tid) of
        SOME btvKind => btvKind
      | NONE => raise Control.Bug ("type variable not found " ^ (BoundTypeVarID.toString tid))

  fun fieldType (context as {btvEnv,...} : context) (recordType, label) =
      let
        fun ft flty =
            case LabelEnv.find(flty, label) of
              SOME ty => ty
            | _ => raise Control.Bug "label not found"
      in
        case recordType of
          AT.RECORDty {fieldTypes,...} => ft fieldTypes
        | AT.BOUNDVARty tid =>
          (
           case #tvarKind (lookupTid context tid) of
             AT.REC flty => ft flty
           | _ => raise Control.Bug "invalid record tyvar"
          )
        | _ => raise Control.Bug "invalid record tyvar"
      end

end
