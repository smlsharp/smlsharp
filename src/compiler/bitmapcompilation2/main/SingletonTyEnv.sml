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

  datatype value =
      VAR of RecordCalc.varInfo
    | TAG of Types.ty * RuntimeTypes.tag
    | SIZE of Types.ty * int
    | CONST of Word32.word
    | CAST of value * Types.ty
  val format_value : value TermFormat.formatter

  val emptyEnv : env
  val bindTyvar : env * BoundTypeVarID.id * Types.btvKind -> env
  val bindTyvars : env * Types.btvEnv -> env
  val bindVar : env * RecordCalc.varInfo -> env
  val bindVars : env * RecordCalc.varInfo list -> env

  val btvEnv : env -> Types.btvEnv
  val constTag : env -> Types.ty -> RuntimeTypes.tag option
  val constSize : env -> Types.ty -> int option
  val unalignedSize : env -> Types.ty -> int
  val findTag : env -> Types.ty -> value
  val findSize : env -> Types.ty -> value

end =
struct

  structure T = Types
  type varInfo = RecordCalc.varInfo

  datatype entry =
      SIZEty of BoundTypeVarID.id
    | TAGty of BoundTypeVarID.id

  datatype value =
      VAR of varInfo
    | TAG of Types.ty * RuntimeTypes.tag
    | SIZE of Types.ty * int
    | CONST of Word32.word
    | CAST of value * Types.ty

  local
    open TermFormat.FormatComb
  in
  fun format_value value =
      case value of
        VAR var => RecordCalc.format_varInfo var
      | TAG (ty, n) => RuntimeTypes.format_tag n
      | SIZE (ty, n) => begin_ text "size(" $(int n) text ")" end_
      | CONST n => begin_ text "0wx" $(term (Word32.fmt StringCvt.HEX n)) end_
      | CAST (value, ty) =>
        begin_ text "cast(" $(format_value value) text ")" end_
  end

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
      case TypeLayout2.runtimeTy btvEnv ty of
        NONE => NONE
      | SOME ty => SOME (TypeLayout2.tagOf ty)

  fun constSize ({btvEnv,...}:env) ty =
      case TypeLayout2.runtimeTy btvEnv ty of
        NONE => NONE
      | SOME ty => SOME (TypeLayout2.sizeOf ty)

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
        | _ => raise Bug.Bug ("findTag " ^ Bug.prettyPrint (T.format_ty nil ty))

  fun findSize (env as {sizeEnv,...}) ty =
      case constSize env ty of
        SOME size => SIZE (ty, size)
      | NONE =>
        case TypesBasics.derefTy ty of
          T.BOUNDVARty tid =>
          (
            case BoundTypeVarID.Map.find (sizeEnv, tid) of
              NONE => raise Bug.Bug
                            ("findSize btvId:" ^ BoundTypeVarID.toString tid)
            | SOME var => VAR var
          )
        | _ => raise Bug.Bug "findSize"

end
