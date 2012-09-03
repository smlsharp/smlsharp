(**
 * LoadFile.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure LoadFile : sig

  (* if baseName is NONE, all relative filenames immediately appearing
   * in Absyn.unit indicates files in the current directory. *)

  val load : {baseName: Filename.filename option,
              stdPath: Filename.filename list,
              loadPath: Filename.filename list}
             -> Absyn.unit
             -> {loadedFiles: (AbsynInterface.filePlace * string) list}
                * AbsynInterface.compileUnit

  val require : {stdPath: Filename.filename list,
                 loadPath: Filename.filename list}
                -> string
                -> {loadedFiles: (AbsynInterface.filePlace * string) list}
                   * AbsynInterface.compileUnit

end =
struct
  structure A = Absyn
  structure I = AbsynInterface

  type env =
      {
        baseDir : (AbsynInterface.filePlace * Filename.filename) option,
        loadPath : (AbsynInterface.filePlace * Filename.filename) list,
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
        loadedFiles : (AbsynInterface.filePlace * string) list
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
                    interface as {interfaceId, interfaceName={hash,place,...},
                                  ...},
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
          loadedFiles = (place, sourceName) :: loadedFiles}
         : loaded,
         content)
      end

  fun addContent ({interfaceEnv,sourceMap,interfaceDecs,loadedFiles}:loaded,
                  (place, sourceName), content) =
      ({interfaceEnv = interfaceEnv,
        sourceMap = SEnv.insert (sourceMap, sourceName, content),
        interfaceDecs = interfaceDecs,
        loadedFiles = (place, sourceName) :: loadedFiles}
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

  exception NotFound

  local
    fun doOpenFile (place, base, filename) =
        let
          val file = Filename.concatPath (base, filename)
        in
          if !Control.debugPrint
          then print ("try to open file " ^ Filename.toString filename ^ "\n")
          else ();
          SOME (file, Filename.TextIO.openIn file, place)
          handle e as IO.Io {cause, function, name} =>
                 if isENOENT cause then NONE else raise e
        end

    fun openFileOnPath nil filename = raise NotFound
      | openFileOnPath ((place, base)::loadPath) filename =
        let
          val file = Filename.concatPath (base, filename)
        in
          if !Control.debugPrint
          then print ("search file " ^ Filename.toString filename ^ "\n")
          else ();
          (file, Filename.TextIO.openIn file, place)
          handle e as IO.Io {cause, function, name} =>
                 if isENOENT cause
                 then openFileOnPath loadPath filename
                 else raise e
        end
  in

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
  fun openFile (baseDir, loadPath) filename =
      let
        val path =
            if Filename.isAbsolute filename then nil
            else case baseDir of
                   NONE => nil
                 | SOME path =>
                   if String.isPrefix "." (Filename.toString filename)
                   then [path]
                   else path :: loadPath
      in
        (case path of
           nil => (filename, Filename.TextIO.openIn filename, I.LOCALPATH)
         | _ => openFileOnPath path filename)
(*
        handle e as IO.Io {cause, function, name} =>
               if isENOENT cause then raise NotFound else raise e
*)
      end

  end (* local *)

  fun parseFile parse ({baseDir, loadPath, visited}:env) (name, loc) =
      let
        val filename = Filename.fromString name
        val (filename, file, place) =
            openFile (baseDir, loadPath) filename
            handle e as IO.Io _ => raiseUserError (loc, e)
                 | NotFound =>
                   raiseUserError (loc, LoadFileError.FileNotFound name)
        val realPath = Filename.realPath filename
        val (visited, result) =
            let
              val sourceName = Filename.toString realPath
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
        val baseDir = SOME (place, Filename.dirname realPath)
        val newEnv = {baseDir=baseDir, loadPath=loadPath, visited=visited}
      in
        (newEnv, result, place)
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
        val (newEnv, result, place) = parseInterface env loaded name
      in
        case result of
          LOADED content => (loaded, content)
        | PARSED (sourceName, I.INCLUDES {includes, topdecs=decs}) =>
          let
            val (loaded, {requires, topdecs}) =
                loadInterfaces newEnv loaded includes
            val content = {requires = requires, topdecs = topdecs @ decs}
          in
            addContent (loaded, (place, sourceName), content)
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
                                              hash = hash,
                                              place = place},
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
        val (newEnv, result, place) = parseInterface env nothingLoaded name
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
            (rev ((place, sourceName) :: #loadedFiles loaded),
             {decls = rev (#interfaceDecs loaded),
              interfaceName = SOME {sourceName = sourceName,
                                    hash = hash,
                                    place = place},
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
                val (env, result, place) =
                    parseSource env {name = name, loc = loc}
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
            val name = Filename.toString (Filename.basename smifile)
          in
            if CoreUtils.testExist smifile
            then A.INTERFACE {loc = Loc.noloc, name = name}
            else A.NOINTERFACE
          end
        | _ => A.NOINTERFACE

  fun makeEnv {baseName, stdPath, loadPath} =
      let
        val baseDir =
            case baseName of
              SOME name => SOME (I.LOCALPATH, Filename.dirname name)
            | NONE => NONE
        val loadPath = map (fn x => (I.STDPATH, x)) stdPath
                       @ map (fn x => (I.LOCALPATH, x)) loadPath
      in
        {baseDir = baseDir,
         loadPath = loadPath,
         visited = SSet.empty} : env
      end

  fun load (options as {baseName,...}) ({interface, tops, loc}:A.unit) =
      let
        val env = makeEnv options
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

  fun require {stdPath, loadPath} name =
      let
        val env = makeEnv {baseName = NONE, stdPath = stdPath,
                           loadPath = loadPath}
        val (loaded, {requires, topdecs}) =
            loadInterface env nothingLoaded {name=name, loc=Loc.noloc}
        val loadedFiles = #loadedFiles loaded
        val interface =
            {decls = rev (#interfaceDecs loaded),
             interfaceName = NONE,
             requires = map #id requires,
             topdecs = nil} : I.interface
        val compileUnit =
            {interface = interface, topdecs = topdecs} : I.compileUnit
      in
        ({loadedFiles = loadedFiles}, compileUnit)
      end

end
