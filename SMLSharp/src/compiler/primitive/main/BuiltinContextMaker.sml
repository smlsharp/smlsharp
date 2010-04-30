(**
 * @copyright (c) 2006-2008, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
structure BuiltinContextMaker : sig

  datatype decl =
      TYPE of
      {
       eqKind: Types.eqKind,
       tyvars: Types.eqKind list,
       constructors: {name:string, hasArg:bool, ty:string, tag:int} list,
       runtimeTy: RuntimeTypes.ty option,
       interoperable: RuntimeTypes.interoperableKind
      }
    | EXCEPTION of
      {
        hasArg: bool,
        ty: string,
        tag: ExnTagID.id,  (* ToDo: tag will be eliminated *)
        extern: string
      }
    | PRIM of BuiltinPrimitive.prim_or_special
    | OPRIM of
      {
       ty: string,
       instances: {instTy:string, name: BuiltinPrimitive.prim_or_special} list
      }
    (* ToDo: DUMMY is a nasty hack for printer code generation.
     *       Printer code generator should check whether required utilitity
     *       functions are defined and well-typed.
     *)
    | DUMMY of {ty: string}

  type context =
      (* ToDo: exceptionGlobalNamelEnv is an ad-hoc hack for
       * DeclarationRecovery. Frontend phases should deal with global
       * symbols directly... *)
      {
        topTyConEnv: Types.topTyConEnv,
        topVarEnv: Types.topVarEnv,
        basicNameMap: NameMap.basicNameMap,
        topVarIDEnv: VarIDContext.topVarIDEnv,
        exceptionGlobalNameMap: string ExnTagID.Map.map,
        runtimeTyEnv : RuntimeTypes.ty TyConID.Map.map,
        interoperableKindMap : RuntimeTypes.interoperableKind TyConID.Map.map
      }

  val emptyContext : context

  val getTyCon : context * string -> Types.tyCon
  val getConPathInfo : context * string -> Types.conPathInfo
  val getExnPathInfo : context * string -> Types.exnPathInfo

  val define : context -> (string * decl) -> context

end =
struct

  datatype decl =
      TYPE of
      {
       eqKind: Types.eqKind,
       tyvars: Types.eqKind list,
       constructors: {name:string, hasArg:bool, ty:string, tag:int} list,
       runtimeTy: RuntimeTypes.ty option,
       interoperable: RuntimeTypes.interoperableKind
      }
    | EXCEPTION of
      {
        hasArg: bool,
        ty: string,
        tag: ExnTagID.id,
        extern: string
      }
    | PRIM of BuiltinPrimitive.prim_or_special
    | OPRIM of
      {
       ty: string,
       instances: {instTy:string, name: BuiltinPrimitive.prim_or_special} list
      }
    | DUMMY of {ty: string}

  type context =
      {
        topTyConEnv: Types.topTyConEnv,
        topVarEnv: Types.topVarEnv,
        basicNameMap: NameMap.basicNameMap,
        topVarIDEnv: VarIDContext.topVarIDEnv,
        exceptionGlobalNameMap: string ExnTagID.Map.map,
        runtimeTyEnv : RuntimeTypes.ty TyConID.Map.map,
        interoperableKindMap : RuntimeTypes.interoperableKind TyConID.Map.map
      }

  val emptyContext =
      {
        topTyConEnv = SEnv.empty,
        topVarEnv = SEnv.empty,
        basicNameMap = NameMap.emptyBasicNameMap,
        topVarIDEnv = VarIDContext.emptyTopVarIDEnv,
        exceptionGlobalNameMap = ExnTagID.Map.empty,
        runtimeTyEnv = TyConID.Map.empty,
        interoperableKindMap = TyConID.Map.empty
      } : context

  fun getTyCon ({topTyConEnv, ...}:context, tyName) =
      case SEnv.find (topTyConEnv, tyName) of
        SOME (Types.TYCON {tyCon, ...}) => tyCon
      | _ => raise Control.Bug ("getTyCon: not found: " ^ tyName)
before print (tyName^"\n")

  fun getConPathInfo ({topVarEnv, ...}:context, conName) =
      case SEnv.find (topVarEnv, conName) of
        SOME (Types.CONID conPathInfo) => conPathInfo
      | _ => raise Control.Bug ("getConPathInfo: not found: " ^ conName)
before print (conName^"\n")

  fun getExnPathInfo ({topVarEnv, ...}:context, exnName) =
      case SEnv.find (topVarEnv, exnName) of
        SOME (Types.EXNID exnPathInfo) => exnPathInfo
      | _ => raise Control.Bug ("getExnPathInfo: not found: " ^ exnName)
before print (exnName^"\n")

  val toExternPath = NameMap.injectPathToExternPath
  val toTopName = NameMap.usrNamePathToString

  fun defineName' context parentPath (nil, name) K =
      K (context:context, (name, toExternPath parentPath))
    | defineName' context parentPath (strname::path, name) K =
      let
        val (tyNameMap, varNameMap, strNameMap) = #basicNameMap context
        val myPath = Path.appendUsrPath (parentPath, strname)
        val basicNameMap =
            case SEnv.find (strNameMap, strname) of
              SOME (NameMap.NAMEAUX {basicNameMap, ...}) => basicNameMap
            | NONE => NameMap.emptyBasicNameMap

        val context =
            {topTyConEnv = #topTyConEnv context,
             topVarEnv = #topVarEnv context,
             basicNameMap = basicNameMap,
             topVarIDEnv = #topVarIDEnv context,
             exceptionGlobalNameMap = #exceptionGlobalNameMap context,
             runtimeTyEnv = #runtimeTyEnv context,
             interoperableKindMap = #interoperableKindMap context}

        val {topTyConEnv = topTyConEnv,
             topVarEnv = topVarEnv,
             basicNameMap = basicNameMap,
             topVarIDEnv = topVarIDEnv,
             exceptionGlobalNameMap = exceptionGlobalNameMap,
             runtimeTyEnv = runtimeTyEnv,
             interoperableKindMap = interoperableKindMap} =
              defineName' context myPath (path, name) K

        val newEntry =
            NameMap.NAMEAUX {name = strname,
                             wrapperSysStructure = NONE,
                             parentPath = parentPath,
                             basicNameMap = basicNameMap}
      in
        {topTyConEnv = topTyConEnv,
         topVarEnv = topVarEnv,
         basicNameMap = (tyNameMap,
                         varNameMap,
                         SEnv.insert (strNameMap, strname, newEntry)),
         topVarIDEnv = topVarIDEnv,
         exceptionGlobalNameMap = exceptionGlobalNameMap,
         runtimeTyEnv = runtimeTyEnv,
         interoperableKindMap = interoperableKindMap} : context
      end

  fun stringToPath s =
      case rev (String.fields (fn x => x = #".") s) of
        h::t => (rev t, h)
      | nil => (nil, s)

  fun defineName (context, longid) K =
      defineName' context Path.NilPath (stringToPath longid) K
      
  fun define context (longid, decl) =
      defineName (context, longid)
        (fn (context as {topTyConEnv = topTyConEnv,
                         topVarEnv = topVarEnv,
                         basicNameMap = (tyNameMap, varNameMap, strNameMap),
                         topVarIDEnv = topVarIDEnv,
                         exceptionGlobalNameMap = exceptionGlobalNameMap,
                         runtimeTyEnv = runtimeTyEnv,
                         interoperableKindMap = interoperableKindMap},
             namePath as (name, path)) =>
            case decl of
              TYPE {eqKind, tyvars, constructors, runtimeTy, interoperable} =>
              let
                val tyConId = ReservedTyConIDKeyGen.generate ()

                val hasArgList =
                    SEnv.listItems
                      (SEnv.fromList
                        (map (fn {name,hasArg,...} => (name, hasArg))
                             constructors))

                val tyCon =
                    {
                      id = tyConId,
                      name = name,
                      strpath = path,
                      tyvars = tyvars,
                      abstract = false,
                      eqKind = ref eqKind,
                      constructorHasArgFlagList = hasArgList
                    } : Types.tyCon

                val tmpTyConEnv =
                    SEnv.insert (topTyConEnv, name,
                                 Types.TYCON {tyCon=tyCon, datacon=SEnv.empty})

                val (datacon, dataconNameMap) =
                    foldl
                      (fn ({name, ty, tag, hasArg}, (datacon, nameMap)) =>
                          let
                            val ty = TypeParser.readTy tmpTyConEnv ty
                            val idState =
                                Types.CONID {namePath = (name, path),
                                             funtyCon = hasArg,
                                             ty = ty,
                                             tag = tag,
                                             tyCon = tyCon}
                            val nameState = NameMap.CONID (name, path)
                          in
                            (SEnv.insert (datacon, name, idState),
                             SEnv.insert (nameMap, name, nameState))
                          end)
                      (SEnv.empty, SEnv.empty)
                      constructors

                val tyState =
                    Types.TYCON {tyCon=tyCon, datacon=datacon}
                val nameState =
                    if SEnv.isEmpty dataconNameMap
                    then NameMap.NONDATATY namePath
                    else NameMap.DATATY (namePath, dataconNameMap)

                val tyNameMap =
                    SEnv.insert (tyNameMap, name, nameState)
                val varNameMap =
                    SEnv.unionWith #2 (varNameMap, dataconNameMap)
                val topTyConEnv =
                    SEnv.insert (topTyConEnv, toTopName namePath, tyState)
                val topVarEnv =
                    SEnv.foldli
                      (fn (conname, idState, topVarEnv) =>
                          SEnv.insert (topVarEnv, toTopName (conname, path),
                                       idState))
                      topVarEnv
                      datacon
                val runtimeTyEnv =
                    case runtimeTy of
                      SOME ty => TyConID.Map.insert (runtimeTyEnv, tyConId, ty)
                    | NONE => runtimeTyEnv
                val interoperableKindMap =
                    TyConID.Map.insert (interoperableKindMap, tyConId,
                                        interoperable)
              in
                {topTyConEnv = topTyConEnv,
                 topVarEnv = topVarEnv,
                 basicNameMap = (tyNameMap, varNameMap, strNameMap),
                 topVarIDEnv = topVarIDEnv,
                 exceptionGlobalNameMap = exceptionGlobalNameMap,
                 runtimeTyEnv = runtimeTyEnv,
                 interoperableKindMap = interoperableKindMap}
              end

            | EXCEPTION {hasArg, ty, tag, extern} =>
              let
                val {tyCon, ...} =
                    case SEnv.find (topTyConEnv, "exn") of
                      SOME (Types.TYCON x) => x
                    | _ => raise Control.Bug "exn not defined"

                val ty = TypeParser.readTy topTyConEnv ty
                val idState =
                    Types.EXNID {namePath = namePath,
                                 funtyCon = hasArg,
                                 ty = ty,
                                 tag = tag,
                                 tyCon = tyCon}
                val topName = toTopName namePath

                val topVarEnv =
                    SEnv.insert (topVarEnv, topName, idState)
                val varNameMap =
                    SEnv.insert (varNameMap, name, NameMap.EXNID namePath)
                val exceptionGlobalNameMap =
                    ExnTagID.Map.insert (exceptionGlobalNameMap, tag, extern)
              in
                {topTyConEnv = topTyConEnv,
                 topVarEnv = topVarEnv,
                 basicNameMap = (tyNameMap, varNameMap, strNameMap),
                 topVarIDEnv = topVarIDEnv,
                 exceptionGlobalNameMap = exceptionGlobalNameMap,
                 runtimeTyEnv = runtimeTyEnv,
                 interoperableKindMap = interoperableKindMap}
              end

            | PRIM prim =>
              let
                val primInfo = BuiltinPrimitiveType.primInfo topTyConEnv prim
                val idState = Types.PRIM primInfo
                val topName = toTopName namePath

                val topVarEnv =
                    SEnv.insert (topVarEnv, topName, idState)
                val varNameMap =
                    SEnv.insert (varNameMap, name, NameMap.VARID namePath)
                val topVarIDEnv =
                    SEnv.insert (topVarIDEnv, topName, VarIDContext.Dummy)
              in
                {topTyConEnv = topTyConEnv,
                 topVarEnv = topVarEnv,
                 basicNameMap = (tyNameMap, varNameMap, strNameMap),
                 topVarIDEnv = topVarIDEnv,
                 exceptionGlobalNameMap = exceptionGlobalNameMap,
                 runtimeTyEnv = runtimeTyEnv,
                 interoperableKindMap = interoperableKindMap}
              end

            | DUMMY {ty} =>
              let
                val ty = TypeParser.readTy topTyConEnv ty
                val idState = Types.VARID {namePath = namePath, ty = ty}
                val topName = toTopName namePath
                val topVarEnv =
                    SEnv.insert (topVarEnv, topName, idState)
                val varNameMap =
                    SEnv.insert (varNameMap, name, NameMap.VARID namePath)
                val topVarIDEnv =
                    SEnv.insert (topVarIDEnv, topName, VarIDContext.Dummy)
              in
                {topTyConEnv = topTyConEnv,
                 topVarEnv = topVarEnv,
                 basicNameMap = (tyNameMap, varNameMap, strNameMap),
                 topVarIDEnv = topVarIDEnv,
                 exceptionGlobalNameMap = exceptionGlobalNameMap,
                 runtimeTyEnv = runtimeTyEnv,
                 interoperableKindMap = interoperableKindMap}
              end

            | OPRIM {ty, instances} =>
              let
                val oprimTy = TypeParser.readTy topTyConEnv ty

                val instMap =
                    foldl
                      (fn ({instTy=tyName, name}, instMap) =>
                          let
                            val instTy = TypeParser.readTy topTyConEnv tyName
                            val id = case instTy of
                                       Types.RAWty {tyCon,...} => #id tyCon
                                     | _ => raise Control.Bug "OPRIM"
                            val primTy = TypesUtils.tpappTy (oprimTy, [instTy])
                            val prim = {name = name, ty = primTy}
                          in
                            TyConID.Map.insert (instMap, id, prim)
                          end)
                      TyConID.Map.empty
                      instances

                val idState =
                    Types.OPRIM {name = name,
                                 ty = oprimTy,
                                 instances = instMap}

                val topName = toTopName namePath
                val topVarEnv =
                    SEnv.insert (topVarEnv, topName, idState)
                val varNameMap =
                    SEnv.insert (varNameMap, name, NameMap.VARID namePath)
                val varIDContext =
                    SEnv.insert (topVarIDEnv, topName, VarIDContext.Dummy)
              in
                {topTyConEnv = topTyConEnv,
                 topVarEnv = topVarEnv,
                 basicNameMap = (tyNameMap, varNameMap, strNameMap),
                 topVarIDEnv = topVarIDEnv,
                 exceptionGlobalNameMap = exceptionGlobalNameMap,
                 runtimeTyEnv = runtimeTyEnv,
                 interoperableKindMap = interoperableKindMap}
              end)

end
