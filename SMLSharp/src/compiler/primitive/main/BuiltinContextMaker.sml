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
        instances: {instTyList:string list,
                    instance: OPrimInstance.instance} list
      }
    (* ToDo: DUMMY is a nasty hack for printer code generation.
     *       Printer code generator should check whether required utilitity
     *       functions are defined and well-typed.
     *)
    | DUMMY of {ty: string}

  type context
  val emptyContext : context
  val getOPrimInstMap : context * OPrimID.id -> OPrimInstance.oprimInstMap
  val getTyCon : context * string -> Types.tyCon
  val getConPathInfo : context * string -> Types.conPathInfo
  val getExnPathInfo : context * string -> Types.exnPathInfo
  val define : context -> (string * decl) -> context
end =
struct

  fun bug s = Control.Bug ("BuiltinContextMaker:" ^ s)

  structure T = Types
  structure TU = TypesUtils


  datatype decl =
      TYPE of
      {
       eqKind: T.eqKind,
       tyvars: T.eqKind list,
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
       instances: {instTyList:string list,
                   instance: OPrimInstance.instance} list
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
        oprimEnv: OPrimInstance.oprimInstMap OPrimID.Map.map,
        topTyConEnv: T.topTyConEnv,
        topVarEnv: T.topVarEnv,
        basicNameMap: NameMap.basicNameMap,
        topVarIDEnv: VarIDContext.topVarIDEnv,
        exceptionGlobalNameMap: string ExnTagID.Map.map,
        runtimeTyEnv : RuntimeTypes.ty TyConID.Map.map,
        interoperableKindMap : RuntimeTypes.interoperableKind TyConID.Map.map
      }

  val emptyContext =
      {
        oprimEnv = OPrimID.Map.empty,
        topTyConEnv = SEnv.empty,
        topVarEnv = SEnv.empty,
        basicNameMap = NameMap.emptyBasicNameMap,
        topVarIDEnv = VarIDContext.emptyTopVarIDEnv,
        exceptionGlobalNameMap = ExnTagID.Map.empty,
        runtimeTyEnv = TyConID.Map.empty,
        interoperableKindMap = TyConID.Map.empty
      } : context

  fun getOPrimInstMap ({oprimEnv, ...}:context, oprimId) =
      case OPrimID.Map.find (oprimEnv, oprimId) of
        SOME instmap => instmap
      | _ => raise bug ("oprimInfo not found: " ^
                         OPrimID.toString oprimId)
before print (OPrimID.toString oprimId^"\n")

  fun getTyCon ({topTyConEnv, ...}:context, tyName) =
      case SEnv.find (topTyConEnv, tyName) of
        SOME (T.TYCON {tyCon, ...}) => tyCon
      | _ => raise bug ("getTyCon: not found: " ^ tyName)
before print (tyName^"\n")

  fun getConPathInfo ({topVarEnv, ...}:context, conName) =
      case SEnv.find (topVarEnv, conName) of
        SOME (T.CONID conPathInfo) => conPathInfo
      | _ => raise bug ("getConPathInfo: not found: " ^ conName)
before print (conName^"\n")

  fun getExnPathInfo ({topVarEnv, ...}:context, exnName) =
      case SEnv.find (topVarEnv, exnName) of
        SOME (T.EXNID exnPathInfo) => exnPathInfo
      | _ => raise bug ("getExnPathInfo: not found: " ^ exnName)
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
            {
             oprimEnv = #oprimEnv context,
             topTyConEnv = #topTyConEnv context,
             topVarEnv = #topVarEnv context,
             basicNameMap = basicNameMap,
             topVarIDEnv = #topVarIDEnv context,
             exceptionGlobalNameMap = #exceptionGlobalNameMap context,
             runtimeTyEnv = #runtimeTyEnv context,
             interoperableKindMap = #interoperableKindMap context}

        val {
             oprimEnv = oprimEnv,
             topTyConEnv = topTyConEnv,
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
        {
         oprimEnv = oprimEnv,
         topTyConEnv = topTyConEnv,
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
        (fn (context as {oprimEnv = oprimEnv,
                         topTyConEnv = topTyConEnv,
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
                val tyConId = 
                    if name = "_" then OPrimInstance.wildCardTyConId
                    else TyConID.generate ()

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
                    } : T.tyCon

                val tmpTyConEnv =
                    SEnv.insert (topTyConEnv, name,
                                 T.TYCON {tyCon=tyCon, datacon=SEnv.empty})

                val (datacon, dataconNameMap) =
                    foldl
                      (fn ({name, ty, tag, hasArg}, (datacon, nameMap)) =>
                          let
                            val ty = TypeParser.readTy tmpTyConEnv ty
                            val idState =
                                T.CONID {namePath = (name, path),
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
                    T.TYCON {tyCon=tyCon, datacon=datacon}
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
                {oprimEnv = oprimEnv,
                 topTyConEnv = topTyConEnv,
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
                      SOME (T.TYCON x) => x
                    | _ => raise bug "exn not defined"

                val ty = TypeParser.readTy topTyConEnv ty
                val idState =
                    T.EXNID {namePath = namePath,
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
                {oprimEnv = oprimEnv,
                 topTyConEnv = topTyConEnv,
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
                val idState = T.PRIM primInfo
                val topName = toTopName namePath

                val topVarEnv =
                    SEnv.insert (topVarEnv, topName, idState)
                val varNameMap =
                    SEnv.insert (varNameMap, name, NameMap.VARID namePath)
                val topVarIDEnv =
                    SEnv.insert (topVarIDEnv, topName, VarIDContext.Dummy)
              in
                {oprimEnv = oprimEnv,
                 topTyConEnv = topTyConEnv,
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
                val idState = T.VARID {namePath = namePath, ty = ty}
                val topName = toTopName namePath
                val topVarEnv =
                    SEnv.insert (topVarEnv, topName, idState)
                val varNameMap =
                    SEnv.insert (varNameMap, name, NameMap.VARID namePath)
                val topVarIDEnv =
                    SEnv.insert (topVarIDEnv, topName, VarIDContext.Dummy)
              in
                {oprimEnv = oprimEnv,
                 topTyConEnv = topTyConEnv,
                 topVarEnv = topVarEnv,
                 basicNameMap = (tyNameMap, varNameMap, strNameMap),
                 topVarIDEnv = topVarIDEnv,
                 exceptionGlobalNameMap = exceptionGlobalNameMap,
                 runtimeTyEnv = runtimeTyEnv,
                 interoperableKindMap = interoperableKindMap}
              end

            | OPRIM {ty, instances} =>
              let
                val oprimId = OPrimID.generate ()
                val oprimPolyTy = TypeParser.readTy topTyConEnv ty
                val (oprimPolyTyBtvEnv, oprimPolyTybody) =
                    case TU.derefTy oprimPolyTy of
                      T.POLYty{boundtvars, body} => (boundtvars, body)
                    | _ => raise bug "non poly oprimTy" 
                val btvIdKindList = IEnv.listItemsi oprimPolyTyBtvEnv
                val oprimInstPolyTvarList =
                    map (fn (i,_) => T.BOUNDVARty i) btvIdKindList
                val btvIdKeyKindList =
                    List.filter
                      (fn (_, {recordKind = T.OPRIMkind _,...})
                          => true
                        | _ => false)
                      btvIdKindList
                val oprimKeyPolyTvarList =
                    map (fn (i,_) => T.BOUNDVARty i) btvIdKeyKindList
                val oprimPolyTyBtvEnv =
                    IEnv.map
                    (fn {recordKind = T.OPRIMkind {instances, ...}, eqKind}
                        =>
                        {
                         recordKind =
                           T.OPRIMkind
                             {instances = instances,
                              operators = [{oprimId = oprimId,
                                            name = name,
                                            oprimPolyTy = oprimPolyTy,
                                            keyTyList = oprimKeyPolyTvarList,
                                            instTyList = oprimInstPolyTvarList
                                           }
                                          ]
                             },
                         eqKind = eqKind
                        }
                      | btvKind => btvKind
                    )
                    oprimPolyTyBtvEnv
                val oprimPolyTy =
                    T.POLYty{boundtvars = oprimPolyTyBtvEnv,
                             body = oprimPolyTybody}
                val instMap =
                    foldl
                      (fn ({instTyList, instance}, instMap) =>
                          let
                            val instTyList =
                                map (TypeParser.readTy topTyConEnv) instTyList
                            val tyConIdList = 
                                map
                                (fn instTy => 
                                    case TU.derefTy instTy of
                                      T.RAWty {tyCon,...} => #id tyCon
                                    | _ => raise bug "OPRIM")
                                instTyList
                            val oprimInst = {name = name, instance = instance}
                          in
                            OPrimInstance.Map.insert (instMap,
                                                      tyConIdList,
                                                      oprimInst)
                          end
                      )
                      OPrimInstance.Map.empty
                      instances
                val idState =
                    T.OPRIM {name = name,
                             oprimId = oprimId,
                             oprimPolyTy = oprimPolyTy}
                val topName = toTopName namePath
                val topVarEnv =
                    SEnv.insert (topVarEnv, topName, idState)
                val varNameMap =
                    SEnv.insert (varNameMap, name, NameMap.VARID namePath)
                val varIDContext =
                    SEnv.insert (topVarIDEnv, topName, VarIDContext.Dummy)
                val oprimEnv =
                    OPrimID.Map.insert (oprimEnv, oprimId, instMap)
              in
                {oprimEnv = oprimEnv,
                 topTyConEnv = topTyConEnv,
                 topVarEnv = topVarEnv,
                 basicNameMap = (tyNameMap, varNameMap, strNameMap),
                 topVarIDEnv = topVarIDEnv,
                 exceptionGlobalNameMap = exceptionGlobalNameMap,
                 runtimeTyEnv = runtimeTyEnv,
                 interoperableKindMap = interoperableKindMap}
              end)
end
