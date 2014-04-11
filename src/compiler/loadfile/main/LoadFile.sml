(**
 * LoadFile.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * refactorded by Atsushi Ohori
 *)

(*
structure LoadFile : sig

  (* if baseName is NONE, all relative filenames immediately appearing
   * in Absyn.unit indicates files in the current directory. *)

  type dependency =
      {interfaceName : AbsynInterface.interfaceName,
       link : AbsynInterface.interfaceName list,
       compile : (AbsynInterface.filePlace * Filename.filename) list}

  val load
      : {baseName: Filename.filename option,
         stdPath: Filename.filename list,
         loadPath: Filename.filename list,
         version: int option}
        -> Absyn.unit
        -> dependency * AbsynInterface.compileUnit

  datatype interfaceFileKind =
      COMPILATION
    | INTERFACE

  val loadInterface
      : {stdPath: Filename.filename list,
         loadPath: Filename.filename list}
        -> Filename.filename
        -> dependency * interfaceFileKind * AbsynInterface.compileUnit

end =
*)
structure LoadFile =
struct

  structure A = Absyn
  structure I = AbsynInterface

  fun printErr x = TextIO.output (TextIO.stdErr, x)

  fun raiseUserError (loc, exn) =
      raise UserError.UserErrors [(loc, UserError.Error, exn)]

  structure LoadedMap = IEnv

  type dependency =
      {
        (* name of interface of this *)
        interfaceNameOpt : I.interfaceName option,
        (* list of interfaces needed to eval this interface in link order *)
        link : AbsynInterface.interfaceName list,
        (* list of files needed to eval this *)
        compile : I.source list
      }

  type env = {baseDir : I.source option, visited : SSet.set}

  type result =
      {
        requiredIdHashes : ({id: InterfaceID.id, loc: I.loc} * string) LoadedMap.map,
        topdecs : A.topdec list LoadedMap.map
      }

  val emptyResult =
      {requiredIdHashes = LoadedMap.empty, topdecs = LoadedMap.empty} : result

  fun appendResult (c1:result, c2:result) =
      {requiredIdHashes = LoadedMap.unionWith #1 (#requiredIdHashes c1, #requiredIdHashes c2),
       topdecs = LoadedMap.unionWith #1 (#topdecs c1, #topdecs c2)} : result

  type loadAccum =
      {
        loadCount : int ref,
        smiFileMap : result SEnv.map ref,
        smlFileMap : A.unitparseresult SEnv.map ref,
        interfaceDecsRev : I.interfaceDec list ref,
        loadedFiles : I.source list ref
      }

  fun newLoadedKey ({loadCount, ...}:loadAccum) =
      !loadCount before loadCount := !loadCount + 1

  fun newLoadAccum () =
      {loadCount = ref 0,
       smiFileMap = ref SEnv.empty,
       smlFileMap = ref SEnv.empty,
       interfaceDecsRev = ref nil,
       loadedFiles = ref nil} : loadAccum

  fun mkDependency ({interfaceDecsRev, loadedFiles, ...}:loadAccum, interfaceNameOpt) =
      let
        val linkDepends = map #interfaceName (!interfaceDecsRev)
        val compileDepends = rev (!loadedFiles)
      in
        {interfaceNameOpt = interfaceNameOpt,
         link = linkDepends,
         compile = compileDepends} : dependency
      end

  fun findLoaded ({smiFileMap, ...}:loadAccum, sourceString) =
      SEnv.find (!smiFileMap, sourceString)

  fun addResult ({smiFileMap, loadedFiles, ...}:loadAccum,
                 source as (_, filename), result) =
      (smiFileMap := SEnv.insert (!smiFileMap, Filename.toString filename, result);
       loadedFiles := source :: !loadedFiles)

  fun addInterface ({interfaceDecsRev,...}:loadAccum, dec) =
      interfaceDecsRev := dec :: !interfaceDecsRev

  fun addUse ({smlFileMap, loadedFiles, ...}:loadAccum,
              source as (_, filename), result) =
      (smlFileMap := SEnv.insert (!smlFileMap, Filename.toString filename, result);
       loadedFiles := source :: !loadedFiles)

  fun appendNewTopdec loaded (r:result, topdecs) =
      let
        val key = newLoadedKey loaded
      in
        {requiredIdHashes = #requiredIdHashes r,
         topdecs = LoadedMap.insert (#topdecs r, key, topdecs)} : result
      end

  fun newRequireEntry loaded (id, hash, loc) =
      let
        val key = newLoadedKey loaded
        val content = ({id=id, loc=loc}, hash)
      in
        {requiredIdHashes = LoadedMap.singleton(key, content), 
         topdecs = LoadedMap.empty} : result
      end

  fun uniq' set nil = nil
    | uniq' set (h::t) =
      if InterfaceID.Set.member (set, #id h)
      then uniq' set t
      else h :: uniq' (InterfaceID.Set.add (set, #id h)) t

  fun uniq l = uniq' InterfaceID.Set.empty l

  fun isENOENT exn =
      case exn of
        OS.SysErr (msg, errno) =>
        (
          case OS.syserror "noent" of
            (* We cannot make sure whether the error is ENOENT.
             * Assume ENOENT anyway. *)
            NONE => true
          | enoent as SOME _ => errno = enoent
        )
      | _ => false

  exception NotFound

  fun openFileOnPath nil filename = raise NotFound
    | openFileOnPath ((place:I.filePlace, baseFilename)::loadPath) filename =
      let
        val pathFilename = Filename.concatPath (baseFilename, filename)
        val _ =
            if !Bug.debugPrint
            then printErr ("search file " ^ Filename.toString pathFilename ^ "\n")
            else ()
        val ret =
            SOME (Filename.TextIO.openIn pathFilename, place, pathFilename)
            handle e as IO.Io {cause, function, name} =>
                   if isENOENT cause then NONE else raise e
      in
        case ret of
          SOME x => x
        | NONE => openFileOnPath loadPath filename
      end

  fun openLocalFile filename =
      (Filename.TextIO.openIn filename, I.LOCALPATH, filename)
      handle e as IO.Io {cause, function, name} =>
             if isENOENT cause then raise NotFound else raise e

  (*
   * How to search files:
   * (1) if "filename" is an absolute filename, just open it.
   * (2) if "baseDir" is NONE, "filename" is a relative path from the
   *     current directory of the process and do not search on "loadPath".
   * (3) if "filename" begins with ".", "filename" is a relative path
   *     from "baseDir" and do not search on "loadPath".
   * (4) Otherwise, "filename" is a relative path from either "baseDir"
   *     or a directory on "loadPath".
   *)
  fun openFile ({baseDir, ...}:env, loadPath) symbol =
      let
        val name = Symbol.symbolToString symbol
        val loc =  Symbol.symbolToLoc symbol
        val filename = Filename.fromString name
      in
        (if Filename.isAbsolute filename
         then openLocalFile filename
         else case baseDir of
                NONE => openLocalFile filename
              | SOME baseDir =>
                if String.isPrefix "." name
                then openFileOnPath [baseDir] filename
                else openFileOnPath (baseDir :: loadPath) filename)
        handle e as IO.Io _ => raiseUserError (loc, e)
             | NotFound => raiseUserError (loc, LoadFileError.FileNotFound name)
      end

  datatype parseResult =
      LOADED of result
    | PARSED of env * I.source * I.itop

  fun visitFile ({visited, ...}:env) filePlace filename symbol =
      let
        val loc  = Symbol.symbolToLoc symbol
        val realPath = Filename.realPath filename
        val sourceName = Filename.toString realPath
        val visited =
            if SSet.member (visited, sourceName)
            then raiseUserError (loc, LoadFileError.CircularLoad symbol)
            else SSet.add (visited, sourceName)
      in
        ({baseDir = SOME (filePlace, Filename.dirname realPath),
          visited = visited},
         (filePlace, realPath),
         sourceName)
      end

  fun parseInterface loadPath env loaded fileSymbol =
      let
        val (file, filePlace, filename) = openFile (env, loadPath) fileSymbol
      in
        (let
           val (newEnv, source, sourceName) =
           visitFile env filePlace filename fileSymbol
         in
           case findLoaded (loaded, sourceName) of
             SOME result => LOADED result
           | NONE =>
             let
               val _ = if !Control.traceFileLoad
                       then printErr ("require: " ^ sourceName ^ "\n")
                       else ()
               val input = InterfaceParser.setup
                             {read = fn n => TextIO.inputN (file, n),
                              sourceName = sourceName}
               val itop = InterfaceParser.parse input
            in
              PARSED (newEnv, source, itop)
            end
         end
         handle e => (TextIO.closeIn file; raise e))
         before TextIO.closeIn file
      end

  fun setupInterface (source, provide, {requiredIdHashes, topdecs}:result) =
      let
        val (requiredIds, hashes) = ListPair.unzip (LoadedMap.listItems requiredIdHashes)
        val hash = InterfaceHash.generate (source, hashes, provide)
      in
        ({hash = hash, source = source}, requiredIds)
      end

  fun loadRequire loadPath env loaded symbol =
      case parseInterface loadPath env loaded symbol of
        LOADED result => result
      | PARSED (env, source, I.INCLUDES {includes, topdecs}) =>
        let
          val result = loadRequires loadPath env loaded includes
          val result = appendNewTopdec loaded (result, topdecs)
        in
          addResult (loaded, source, result);
          result
        end
      | PARSED (env, source, I.INTERFACE {requires, provide}) =>
        let
          val result = loadRequires loadPath env loaded requires
          val id = InterfaceID.generate ()
          val (interfaceName as {hash,...}, requiredIds) =
              setupInterface (source, provide, result)
          val interfaceDec =
              {interfaceId = id,
               interfaceName = interfaceName,
               requiredIds = requiredIds,
               provideTopdecs = provide} : I.interfaceDec
          val result = newRequireEntry loaded (id, hash, Symbol.symbolToLoc symbol)
        in
          addInterface (loaded, interfaceDec);
          addResult (loaded, source, result);
          result
        end

  and loadRequires loadPath env loaded nil = emptyResult
    | loadRequires loadPath env loaded (symbol::symbols) =
      let
        val result1 = loadRequire loadPath env loaded symbol
        val result2 = loadRequires loadPath env loaded symbols
      in
        appendResult (result1, result2)
      end


  fun parseSource env loaded symbol =
      let
        val (file, filePlace, filename) = openFile (env, nil) symbol
      in
        (let
           val (newEnv, source, sourceName) =
               visitFile env filePlace filename symbol
         in
           case SEnv.find (!(#smlFileMap loaded), sourceName) of
             SOME x => x
           | NONE =>
             let
               val input = Parser.setup
                             {mode = Parser.File,
                              read = fn (_,n) => TextIO.inputN (file, n),
                              sourceName = Filename.toString filename,
                              initialLineno = 1}
               val result = Parser.parse input
             in
               addUse (loaded, source, result);
               result
             end
         end
         handle e => (TextIO.closeIn file; raise e))
         before TextIO.closeIn file
      end

  fun includeUse env loaded top =
      case top of
        A.TOPDEC topdecs => topdecs
      | A.USE symbol =>
        case parseSource env loaded symbol of
          A.EOF => nil
        | A.UNIT {interface = A.INTERFACE _, ...} =>
          raiseUserError (Symbol.symbolToLoc symbol, LoadFileError.UseWithInterface symbol)
        | A.UNIT {interface = A.NOINTERFACE, tops, ...} =>
          includeUseFiles env loaded tops

  and includeUseFiles env loaded nil = nil
    | includeUseFiles env loaded (top::tops) =
      includeUse env loaded top @ includeUseFiles env loaded tops

  fun defaultInterface baseInterfaceName =
      case baseInterfaceName of
        NONE => NONE
      | SOME filename =>
        case Filename.suffix filename of
          SOME "sml" =>
          let
            val smifile = Filename.replaceSuffix "smi" filename
          in
            if CoreUtils.testExist smifile
            then SOME (NONE, Symbol.mkSymbol (Filename.toString smifile) Loc.noloc)
            else NONE
          end
        | _ => NONE

  fun dirname baseFilename =
      case baseFilename of
        SOME filename => SOME (I.LOCALPATH, Filename.dirname filename)
      | NONE => NONE

  fun makeLoadPath (stdPath, loadPath) =
      map (fn x => (I.STDPATH, x)) stdPath
      @ map (fn x => (I.LOCALPATH, x)) loadPath

  fun addSource ({loadedFiles, ...}:loadAccum, source) =
      loadedFiles := source :: !loadedFiles

  fun load {baseFilename, stdPath, loadPath} ({interface, tops, loc}:A.unit) =
      let
        val _ = if !Control.traceFileLoad
                then printErr ("load basefilename: " ^ 
                               (case baseFilename of NONE => "NONE"
                                                  | SOME baseFilename =>Filename.toString baseFilename )
                               ^ "\n")
                else ()

        val baseDir = dirname baseFilename
        val _ = if !Control.traceFileLoad
                then printErr ("load baseDir: " ^ 
                               (case baseDir of NONE => "NONE"
                                              | SOME (_, baseDir) => Filename.toString baseDir)
                               ^ "\n")
                else ()

        val interface = 
            case interface of
              A.INTERFACE symbol => SOME (baseDir, symbol)
            | A.NOINTERFACE => defaultInterface baseFilename
        val loaded = newLoadAccum ()
      in
        case interface of
          NONE => 
          let
            val env = {baseDir=baseDir, visited=SSet.empty} : env
            val topdecs = includeUseFiles env loaded tops
          in
            (mkDependency (loaded, NONE),
             {interface=NONE, topdecsInclude=nil, topdecsSource=topdecs}
            )
          end
        | SOME (baseDir, symbol) =>
          let
            val env = {baseDir=baseDir, visited=SSet.empty} : env
          in
            case parseInterface nil env loaded symbol of
              PARSED (env, source, I.INTERFACE {requires, provide}) =>
              let
                val loadPath = makeLoadPath (stdPath, loadPath)
                val result = loadRequires loadPath env loaded requires
                val (interfaceName, requires) = setupInterface (source, provide, result)
                val topdecsInclude = List.concat (LoadedMap.listItems (#topdecs result))
                val interfaceDecs = rev (! (#interfaceDecsRev loaded))
                val _ = addSource (loaded, #source interfaceName)
                val dependency = mkDependency (loaded, SOME interfaceName)
                val topdecs = includeUseFiles env loaded tops
              in
                (dependency, 
                 {interface = SOME {interfaceDecs = interfaceDecs,
                                    provideInterfaceNameOpt = SOME interfaceName,
                                    provideTopdecs = provide,
                                    requiredIds = requires},
                  topdecsInclude = topdecsInclude,
                  topdecsSource=topdecs}
                )
              end
            | PARSED (env, source, I.INCLUDES {includes, topdecs}) =>
              raiseUserError (Symbol.symbolToLoc symbol, 
                              LoadFileError.InvalidTopInterface symbol)
            | LOADED _ => raise Bug.Bug "load"
          end
      end

  fun generateDependency {stdPath, loadPath} filename =
      let
        val loadPath = makeLoadPath (stdPath, loadPath)
        val symbol = Symbol.mkSymbol (Filename.toString filename) Loc.noloc
        val loaded = newLoadAccum ()
        val env = {baseDir = NONE, visited = SSet.empty} : env
        val interfaceNameOpt =
            case parseInterface nil env loaded symbol of
              LOADED _ => raise Bug.Bug "generateDependency"
            | PARSED (env, source, I.INTERFACE {requires, provide}) =>
              let 
                val result = loadRequires loadPath env loaded requires
                val (interfaceName, requires) = setupInterface (source, provide, result)
              in
                SOME interfaceName
              end
            | PARSED (env, source, I.INCLUDES {includes, topdecs}) =>
              (loadRequires loadPath env loaded includes;
               NONE)
        val dependency = mkDependency (loaded, interfaceNameOpt)
      in
        dependency
      end

  fun loadInteractiveEnv {stdPath, loadPath} filename =
      let
        val loadPath = makeLoadPath (stdPath, loadPath)
        val symbol = Symbol.mkSymbol (Filename.toString filename) Loc.noloc
        val loaded = newLoadAccum ()
        val loc = Symbol.symbolToLoc symbol
        val env = {baseDir = NONE, visited = SSet.empty} : env
      in
        case parseInterface nil env loaded symbol of
          LOADED _ => raise Bug.Bug "loadTopInteractive"
        | PARSED (env, source, I.INTERFACE {requires, provide}) =>
          let
            val result = loadRequires loadPath env loaded requires
            val (interfaceName, requires) = setupInterface (source, provide, result)
            val topdecs = List.concat (LoadedMap.listItems (#topdecs result))
            val interfaceDecs = rev (! (#interfaceDecsRev loaded))
          in
            {interface = {interfaceDecs = interfaceDecs,
                          provideInterfaceNameOpt = SOME interfaceName,
                          provideTopdecs = provide,
                          requiredIds = requires},
             interfaceDecls = nil,
             topdecsInclude = topdecs}
          end
        | PARSED (env, source, I.INCLUDES {includes, topdecs}) =>
          let
            val result = loadRequires loadPath env loaded includes
            val interfaceMap =
                foldl (fn (dec as {interfaceId, ...}, map) =>
                          InterfaceID.Map.insert (map, interfaceId, dec))
                      InterfaceID.Map.empty
                      (!(#interfaceDecsRev loaded))
            val (requires, provide) =
                foldr
                  (fn (({id, ...}, _), (requires2, provide2)) =>
                      case InterfaceID.Map.find (interfaceMap, id) of
                        NONE => raise Bug.Bug "loadCompilation"
                      | SOME {requiredIds, provideTopdecs, ...} =>
                        (requiredIds @ requires2, provideTopdecs @ provide2))
                  (nil, nil)
                  (LoadedMap.listItems (#requiredIdHashes result))
            val topdecs = List.concat (LoadedMap.listItems (#topdecs result)) @ topdecs
            val interfaceDecs = rev (! (#interfaceDecsRev loaded))
          in
            {interface = {interfaceDecs = interfaceDecs,
                          provideInterfaceNameOpt = NONE (* interfaceName *),
                          provideTopdecs = nil,
                          requiredIds = uniq requires},
             interfaceDecls = provide,
             topdecsInclude = topdecs}
          end
      end

end
