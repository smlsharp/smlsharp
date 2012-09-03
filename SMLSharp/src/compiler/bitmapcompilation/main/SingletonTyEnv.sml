(**
 * record layout and bitmap compilation
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Huu-Duc Nguyen
 * @author Atsushi Ohori
 *)
structure SingletonTyEnv :> sig

  type env

  val emptyEnv : env
  val bindTyvar : env * BoundTypeVarID.id * AnnotatedTypes.btvKind -> env
  val bindTyvars : env * BitmapCalc.btvEnv -> env
  val bindVar : env * BitmapCalc.varInfo -> env
  val bindVars : env * BitmapCalc.varInfo list -> env

  val btvEnv : env -> BitmapCalc.btvEnv
  val constTag : env -> AnnotatedTypes.ty -> int option
  val constSize : env -> AnnotatedTypes.ty -> int option
  val unalignedSize : env -> AnnotatedTypes.ty -> int
  val findTag : env -> AnnotatedTypes.ty -> RecordLayout.value
  val findSize : env -> AnnotatedTypes.ty -> RecordLayout.value

end =
struct

  structure B = BitmapCalc
  structure T = AnnotatedTypes

  datatype entry =
      SIZEty of BoundTypeVarID.id
    | TAGty of BoundTypeVarID.id

  type env =
      {
        btvEnv : B.btvEnv,
        vidMap : entry VarID.Map.map,
        tagEnv : B.varInfo BoundTypeVarID.Map.map,
        sizeEnv : B.varInfo BoundTypeVarID.Map.map
      }

  val emptyEnv =
      {
        btvEnv = BoundTypeVarID.Map.empty,
        vidMap = VarID.Map.empty,
        tagEnv = BoundTypeVarID.Map.empty,
        sizeEnv = BoundTypeVarID.Map.empty
      } : env

  val btvEnv = #btvEnv : env -> BitmapCalc.btvEnv

  fun bindVar ({btvEnv, vidMap, tagEnv, sizeEnv}:env, var as {id, ty, ...}) =
      let
        val (tagEnv, sizeEnv) =
            case VarID.Map.find (vidMap, id) of
              NONE => (tagEnv, sizeEnv)
            | SOME (TAGty tid) =>
              (#1 (BoundTypeVarID.Map.remove (tagEnv, tid)), sizeEnv)
            | SOME (SIZEty tid) =>
              (tagEnv, #1 (BoundTypeVarID.Map.remove (sizeEnv, tid)))
        val (vidMap, tagEnv) =
            case ty of
              T.SINGLETONty (T.TAGty (T.BOUNDVARty tid)) =>
              (VarID.Map.insert (vidMap, id, TAGty tid),
               BoundTypeVarID.Map.insert (tagEnv, tid, var))
            | _ => (vidMap, tagEnv)
        val (vidMap, sizeEnv) =
            case ty of
              T.SINGLETONty (T.SIZEty (T.BOUNDVARty tid)) =>
              (VarID.Map.insert (vidMap, id, SIZEty tid),
               BoundTypeVarID.Map.insert (sizeEnv, tid, var))
            | _ => (vidMap, sizeEnv)
      in
        {btvEnv = btvEnv,
         vidMap = vidMap,
         tagEnv = tagEnv,
         sizeEnv = sizeEnv} : env
      end

  fun bindVars (env, vars) =
      foldl (fn (x,z) => bindVar (z,x)) env vars

  fun bindTyvar ({btvEnv, vidMap, tagEnv, sizeEnv}:env, tid, kind) =
      let
        val (vidMap, tagEnv) =
            case BoundTypeVarID.Map.find (tagEnv, tid) of
              NONE => (vidMap, tagEnv)
            | SOME {id,...} => (#1 (VarID.Map.remove (vidMap, id)),
                                #1 (BoundTypeVarID.Map.remove (tagEnv, tid)))
        val (vidMap, sizeEnv) =
            case BoundTypeVarID.Map.find (sizeEnv, tid) of
              NONE => (vidMap, sizeEnv)
            | SOME {id,...} => (#1 (VarID.Map.remove (vidMap, id)),
                                #1 (BoundTypeVarID.Map.remove (sizeEnv, tid)))
      in
        {btvEnv = BoundTypeVarID.Map.insert (btvEnv, tid, kind),
         vidMap = vidMap,
         tagEnv = tagEnv,
         sizeEnv = sizeEnv} : env
      end

  fun bindTyvars (env, btvEnv) =
      BoundTypeVarID.Map.foldli
        (fn (tid, kind, env) => bindTyvar (env, tid, kind))
        env
        btvEnv

  fun constTag ({btvEnv,...}:env) ty =
      case TypeLayout.runtimeTy btvEnv ty of
        NONE => NONE
      | SOME ty => SOME (TypeLayout.tagOf ty)

  fun constSize ({btvEnv,...}:env) ty =
      case TypeLayout.runtimeTy btvEnv ty of
        NONE => NONE
      | SOME ty => SOME (TypeLayout.sizeOf ty)

  fun unalignedSize env ty =
      case constSize env ty of
        NONE => TypeLayout.maxSize
      | SOME n => n

  fun findTag (env as {tagEnv, ...}) ty =
      case constTag env ty of
        SOME tag => RecordLayout.const tag
      | NONE =>
        case ty of
          T.BOUNDVARty tid =>
          (
            case BoundTypeVarID.Map.find (tagEnv, tid) of
              NONE => raise Control.Bug "findTag"
            | SOME var => RecordLayout.VAR (var, NONE)
          )
        | _ => raise Control.Bug "findTag"

  fun findSize (env as {sizeEnv,...}) ty =
      case constSize env ty of
        SOME size => RecordLayout.const size
      | NONE =>
        case ty of
          T.BOUNDVARty tid =>
          (
            case BoundTypeVarID.Map.find (sizeEnv, tid) of
              NONE => raise Control.Bug "sizeSize"
            | SOME var => RecordLayout.VAR (var, NONE)
          )
        | _ => raise Control.Bug "findSize"

end
