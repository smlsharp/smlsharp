(**
 * record layout and bitmap compilation
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Huu-Duc Nguyen
 * @author Atsushi Ohori
 *)
structure SingletonTyEnv2 :> sig

  type env

  val emptyEnv : env
  val bindTyvar : env * BoundTypeVarID.id * Types.kind -> env
  val bindTyvars : env * Types.btvEnv -> env
  val bindVar : env * RecordLayoutCalc.varInfo -> env
  val bindVars : env * RecordLayoutCalc.varInfo list -> env

  val btvEnv : env -> Types.btvEnv
  val constTag : env -> Types.ty -> RuntimeTypes.tag option
  val constSize : env -> Types.ty -> RuntimeTypes.size option
  val unalignedSize : env -> Types.ty -> RuntimeTypes.size
  val findTag : env -> Types.ty -> RecordLayoutCalc.value
  val findSize : env -> Types.ty -> RecordLayoutCalc.value

end =
struct

  structure T = Types
  structure R = RuntimeTypes
  type varInfo = RecordLayoutCalc.varInfo

  datatype entry =
      SIZEty of BoundTypeVarID.id
    | TAGty of BoundTypeVarID.id

  datatype value = datatype RecordLayoutCalc.value

  type env =
      {
        btvEnv : T.btvEnv,
        vidMap : entry VarID.Map.map,
        tagEnv : varInfo BoundTypeVarID.Map.map,
        sizeEnv : varInfo BoundTypeVarID.Map.map
      }

  val emptyEnv =
      {
        btvEnv = BoundTypeVarID.Map.empty,
        vidMap = VarID.Map.empty,
        tagEnv = BoundTypeVarID.Map.empty,
        sizeEnv = BoundTypeVarID.Map.empty
      } : env

  val btvEnv = #btvEnv : env -> T.btvEnv

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
            case TypesBasics.derefTy ty of
              T.SINGLETONty (T.TAGty (T.BOUNDVARty tid)) =>
              (VarID.Map.insert (vidMap, id, TAGty tid),
               BoundTypeVarID.Map.insert (tagEnv, tid, var))
            | _ => (vidMap, tagEnv)
        val (vidMap, sizeEnv) =
            case TypesBasics.derefTy ty of
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
      case TypeLayout2.propertyOf btvEnv ty of
        SOME {tag = R.TAG tag, ...} => SOME tag
      | SOME {tag = R.ANYTAG, ...} => NONE
      | _ => raise Bug.Bug "constTag"

  fun constSize ({btvEnv,...}:env) ty =
      case TypeLayout2.propertyOf btvEnv ty of
        SOME {size = R.SIZE size, ...} => SOME size
      | SOME {size = R.ANYSIZE, ...} => NONE
      | NONE => raise Bug.Bug "constSize"

  fun unalignedSize env ty =
      case constSize env ty of
        NONE => TypeLayout2.maxSize
      | SOME n => n

  fun findTag (env as {tagEnv, ...}) ty =
      case constTag env ty of
        SOME tag => TAG (ty, tag)
      | NONE =>
        case TypesBasics.derefTy ty of
          T.BOUNDVARty tid =>
          (
            case BoundTypeVarID.Map.find (tagEnv, tid) of
              NONE => raise Bug.Bug ("findTag " ^ BoundTypeVarID.toString tid)
            | SOME var => VAR var
          )
        | _ => raise Bug.Bug ("findTag " ^ Bug.prettyPrint (T.format_ty ty))

  fun findSize (env as {sizeEnv,...}) ty =
      case constSize env ty of
        SOME size => SIZE (ty, size)
      | NONE =>
        case TypesBasics.derefTy ty of
          T.BOUNDVARty tid =>
          (
            case BoundTypeVarID.Map.find (sizeEnv, tid) of
              NONE => 
              (print "findSize\n";
               print (Bug.prettyPrint (Types.format_ty ty));
               raise Bug.Bug
                       ("findSize btvId:" ^ BoundTypeVarID.toString tid)
              )
            | SOME var => VAR var
          )
        | _ => raise Bug.Bug "findSize"

end
