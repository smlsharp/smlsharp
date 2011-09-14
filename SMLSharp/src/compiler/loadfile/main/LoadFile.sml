(**
 * LoadFile.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure LoadFile : sig

  val load : {baseName: Filename.filename option,
              loadPath: Filename.filename list}
             -> Absyn.unit
             -> {loadedFiles: string list} * AbsynInterface.compileUnit

end =
struct

  structure A = Absyn
  structure I = AbsynInterface

  type env =
      {
        baseDirs : Filename.filename list,
        loadPath : Filename.filename list,
        visited : SSet.set
      }

  type content =
      {
        requires : {id: {id: InterfaceID.id, loc: I.loc}, hash: string} list,
        topdecs : A.topdec list
      }

  val emptyContent =
      {requires = nil, topdecs = nil} : content

  fun appendContent (c1:content, c2:content) =
      let
        val reqs =
            List.filter
              (fn {id={id=x,...},...} =>
                  not (List.exists (fn {id={id,...},...} => id = x)
                                   (#requires c1)))
              (#requires c2)
      in
        {requires = #requires c1 @ reqs,
         topdecs = #topdecs c1 @ #topdecs c2} : content
      end

  type loaded =
      {
        interfaceEnv : I.interfaceDec InterfaceID.Map.map,
        sourceMap : content SEnv.map,
        interfaceDecs : I.interfaceDec list,
        loadedFiles : string list
      }

  val nothingLoaded =
      {interfaceEnv = InterfaceID.Map.empty,
       sourceMap = SEnv.empty,
       interfaceDecs = nil,
       loadedFiles = nil} : loaded

  fun findIds ({sourceMap, ...}:loaded, sourceName) =
      SEnv.find (sourceMap, sourceName)

  fun addInterface ({interfaceEnv,sourceMap,interfaceDecs,loadedFiles}:loaded,
                    sourceName,
                    interface as {interfaceId, interfaceName={hash,...}, ...},
                    loc) =
      let
        val content = {requires = [{id = {id = interfaceId, loc = loc},
                                    hash = hash}],
                       topdecs = nil}
      in
        ({interfaceEnv =
            InterfaceID.Map.insert (interfaceEnv, interfaceId, interface),
          sourceMap = SEnv.insert (sourceMap, sourceName, content),
          interfaceDecs = interface :: interfaceDecs,
          loadedFiles = sourceName :: loadedFiles}
         : loaded,
         content)
      end

  fun addContent ({interfaceEnv,sourceMap,interfaceDecs,loadedFiles}:loaded,
                  sourceName, content) =
      ({interfaceEnv = interfaceEnv,
        sourceMap = SEnv.insert (sourceMap, sourceName, content),
        interfaceDecs = interfaceDecs,
        loadedFiles = sourceName :: loadedFiles}
       : loaded,
       content)

  fun raiseUserError (loc, exn) =
      raise UserError.UserErrors [(loc, UserError.Error, exn)]

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

  fun openFile nil filename =
      (filename, Filename.TextIO.openIn filename)
    | openFile (base::loadPath) filename =
      if Filename.isAbsolute filename
      then (filename, Filename.TextIO.openIn filename)
      else
        let
          val file = Filename.concatPath (base, filename)
        in
          (file, Filename.TextIO.openIn file)
          handle e as IO.Io {cause, function, name} =>
                 if isENOENT cause then openFile loadPath filename
                 else raise e
        end

  fun parseFile parse ({baseDirs, loadPath, visited}:env) (name, loc) =
      let
        val filename = Filename.fromString name
        val (filename, file) =
            openFile (baseDirs @ loadPath) filename
            handle e as IO.Io _ => raiseUserError (loc, e)
        val (visited, result) =
            let
              val sourceName = Filename.toString (Filename.realPath filename)
              val _ = if SSet.member (visited, sourceName)
                      then raiseUserError (loc, LoadFileError.CircularLoad name)
                      else ()
              val visited = SSet.add (visited, sourceName)
              val _ = if !Control.switchTrace andalso !Control.traceFileLoad
                      then TextIO.output (TextIO.stdErr,
                                          "source: " ^ sourceName ^ "\n")
                      else ()
            in
              (visited, parse (sourceName, file))
            end
            handle e => (TextIO.closeIn file; raise e)
        val _ = TextIO.closeIn file
        val baseDirs = [Filename.dirname filename]
        val newEnv = {baseDirs=baseDirs, loadPath=loadPath, visited=visited}
      in
        (newEnv, result)
      end

  datatype parseResult =
      LOADED of content
    | PARSED of string * I.itop

  fun parseInterface env loaded {name, loc} =
      parseFile
        (fn (sourceName, file) =>
            case findIds (loaded, sourceName) of
              SOME content => LOADED content
            | NONE =>
              let
                val input = InterfaceParser.setup
                              {read = fn n => TextIO.inputN (file, n),
                               sourceName = sourceName}
                val result = InterfaceParser.parse input
              in
                PARSED (sourceName, result)
              end)
        env
        (name, loc)

  fun loadInterface env loaded (name as {loc,...}) =
      let
        val (newEnv, result) = parseInterface env loaded name
      in
        case result of
          LOADED content => (loaded, content)
        | PARSED (sourceName, I.INCLUDES {includes, topdecs=decs}) =>
          let
            val (loaded, {requires, topdecs}) =
                loadInterfaces newEnv loaded includes
            val content = {requires = requires, topdecs = topdecs @ decs}
          in
            addContent (loaded, sourceName, content)
          end
        | PARSED (sourceName, I.INTERFACE {requires, topdecs}) =>
          let
            val (loaded, {requires, topdecs=_}) =
                loadInterfaces newEnv loaded requires
            val newId = InterfaceID.generate ()
            val hash = InterfaceHash.generate
                         (sourceName, map #hash requires, topdecs)
            val interface = {interfaceId = newId,
                             interfaceName = {sourceName = sourceName,
                                              hash = hash},
                             requires = map #id requires,
                             topdecs = topdecs} : I.interfaceDec
          in
            addInterface (loaded, sourceName, interface, loc)
          end
      end

  and loadInterfaces env loaded nil = (loaded, emptyContent)
    | loadInterfaces env loaded (name::names) =
      let
        val (loaded, content1) = loadInterface env loaded name
        val (loaded, content2) = loadInterfaces env loaded names
      in
        (loaded, appendContent (content1, content2))
      end

  fun loadTopInterface env (name as {loc, name=filename}) =
      let
        val (newEnv, result) = parseInterface env nothingLoaded name
      in
        case result of
          LOADED _ => raise Control.Bug "loadTopInterface"
        | PARSED (sourceName, I.INCLUDES names) =>
          raiseUserError (loc, LoadFileError.InvalidTopInterface filename)
        | PARSED (sourceName, I.INTERFACE {requires, topdecs}) =>
          let
            val (loaded, {requires, topdecs=decs}) =
                loadInterfaces newEnv nothingLoaded requires
            val hash = InterfaceHash.generate
                         (sourceName, map #hash requires, topdecs)
          in
            (rev (sourceName :: #loadedFiles loaded),
             {decls = rev (#interfaceDecs loaded),
              interfaceName = SOME {sourceName = sourceName, hash = hash},
              requires = map #id requires,
              topdecs = topdecs} : I.interface,
             decs)
          end
      end

  fun parseSource env {name, loc} =
      parseFile
        (fn (sourceName, file) =>
            let
              val input = Parser.setup
                            {mode = Parser.File,
                             read = fn (_,n) => TextIO.inputN (file, n),
                             sourceName = sourceName,
                             initialLineno = 1}
            in
              Parser.parse input
            end)
        env
        (name, loc)

  fun evalTop env nil = nil
    | evalTop env (top::tops) =
      let
        val topdecs =
            case top of
              A.TOPDEC topdecs => topdecs
            | A.USE (name, loc) =>
              let
                val (env, result) = parseSource env {name = name, loc = loc}
                val tops2 =
                    case result of
                      A.EOF => nil
                    | (A.UNIT {interface = A.NOINTERFACE, tops, ...}) => tops
                    | (A.UNIT {interface = A.INTERFACE _, ...}) =>
                      raiseUserError (loc, LoadFileError.UseWithInterface name)
              in
                evalTop env tops2
              end
      in
        topdecs @ evalTop env tops
      end

  val emptyInterface =
      {decls = nil, requires = nil, interfaceName = NONE, topdecs = nil}
      : I.interface

  fun defaultInterface baseName =
      case baseName of
        NONE => A.NOINTERFACE
      | SOME filename =>
        case Filename.suffix filename of
          SOME "sml" =>
          let
            val smifile = Filename.replaceSuffix "smi" filename
          in
            if CoreUtils.testExist smifile
            then A.INTERFACE {loc = Loc.noloc, name = Filename.toString smifile}
            else A.NOINTERFACE
          end
        | _ => A.NOINTERFACE

  fun load {baseName, loadPath} ({interface, tops, loc}:A.unit) =
      let
        val baseDirs =
            case baseName of
              SOME name => [Filename.dirname name]
            | NONE => nil
        val env = {baseDirs = baseDirs,
                   loadPath = loadPath,
                   visited = SSet.empty} : env
        val interface =
            case interface of
              A.INTERFACE _ => interface
            | A.NOINTERFACE => defaultInterface baseName
        val (loadedFiles, interface, topdecs1) =
            case interface of
              A.INTERFACE name => loadTopInterface env name
            | A.NOINTERFACE => (nil, emptyInterface, nil)
        val topdecs2 = evalTop env tops
        val compileUnit =
            {interface = interface, topdecs = topdecs1 @ topdecs2}
            : I.compileUnit
      in
        ({loadedFiles=loadedFiles}, compileUnit)
      end

end
