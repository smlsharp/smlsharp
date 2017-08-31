(**
 * LoadFile.sml
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * refactorded by Atsushi Ohori
 *)

structure LoadFile =
struct

  structure A = Absyn
  structure I = AbsynInterface
  structure N = InterfaceName

  fun printErr x =
      TextIO.output (TextIO.stdErr, x)

  fun raiseUserError (loc, exn) =
      raise UserError.UserErrors [(loc, UserError.Error, exn)]

  fun raiseLoadFileError exn (filename, loc) =
      raiseUserError (loc, exn filename)

  (* a vairant of SEnv in which the insertion order is significant *)
  structure Assoc :> sig
    type 'a assoc
    type key = Filename.filename
    val empty : 'a assoc
    val singleton : key * 'a -> 'a assoc
    val find : 'a assoc * key -> 'a option
    val append : 'a assoc * key * 'a -> 'a assoc
    val concatWith : ('a * 'a -> order) -> 'a assoc * 'a assoc -> 'a assoc
    val map : ('a -> 'b) -> 'a assoc -> 'b assoc
    val gather : ('a -> 'b list) -> 'a assoc -> 'b list
    val listItems : 'a assoc -> 'a list
  end =
  struct
    type 'a assoc = 'a SEnv.map * (Filename.filename * 'a) list
    type key = Filename.filename

    val empty = (SEnv.empty, nil): 'a assoc

    fun singleton (k, v) =
        (SEnv.singleton (Filename.toString k, v), [(k, v)]) : 'a assoc

    fun find ((map, _):'a assoc, key) =
        SEnv.find (map, Filename.toString key)

    fun append (assoc as (map, pairs):'a assoc, key, value) =
        let
          val s = Filename.toString key
        in
          case SEnv.find (map, s) of
            NONE => (SEnv.insert (map, s, value), (key, value) :: pairs)
          | SOME _ => assoc
        end

    fun concatWith priority (a:'a assoc, (_, nil):'a assoc) = a
      | concatWith priority (a, (map2, (k2,v2)::pairs2)) =
        let
          val (map1, pairs1) = concatWith priority (a, (map2, pairs2))
          val s2 = Filename.toString k2
        in
          case SEnv.find (map1, s2) of
            NONE => (SEnv.insert (map1, s2, v2), (k2, v2) :: pairs1)
          | SOME v1 =>
            case priority (v1, v2) of
              GREATER => (map1, pairs1)
            | EQUAL => (map1, pairs1)
            | LESS => (SEnv.insert (map1, s2, v2),
                       (k2, v2) :: List.filter (fn (k,v) => k <> k2) pairs1)
        end

    fun map f ((_, pairs):'a assoc) =
        let
          val l = List.map (fn (k,v) => (k, f v)) pairs
          val m = List.foldl
                    (fn ((k,v),z) => SEnv.insert (z, Filename.toString k, v))
                    SEnv.empty
                    l
        in
          (m, l)
        end

    fun mapRev f r nil = r
      | mapRev f r ((_:key,h)::t) = mapRev f (f h :: r) t
    fun gather f ((_, pairs):'a assoc) = List.concat (mapRev f nil pairs)

    fun listItems ((_, pairs):'a assoc) = mapRev (fn x => x) nil pairs
  end

  datatype base_dir =
      DIR of N.source
    | PWD of N.file_place

  fun placeOf (DIR (p, _)) = p
    | placeOf (PWD p) = p

  fun setPlace (DIR (_, f)) p = DIR (p, f)
    | setPlace (PWD _) p = PWD p

  type loader =
       {
         baseDir : base_dir,
         loadPath : N.source list,
         circularCheck : SSet.set
       }

  datatype mode =
      COMPILE
    | NOLOCAL
    | LINK
    | COMPILE_AND_LINK
    | ALL

  fun goDown COMPILE = NOLOCAL
    | goDown NOLOCAL = NOLOCAL
    | goDown LINK = LINK
    | goDown COMPILE_AND_LINK = LINK
    | goDown ALL = ALL

  fun loadRequireLocal COMPILE = true
    | loadRequireLocal NOLOCAL = false
    | loadRequireLocal LINK = true
    | loadRequireLocal COMPILE_AND_LINK = true
    | loadRequireLocal ALL = true

  fun loadUseLocal COMPILE = true
    | loadUseLocal NOLOCAL = false
    | loadUseLocal LINK = false
    | loadUseLocal COMPILE_AND_LINK = true
    | loadUseLocal ALL = true

  fun isENOENT exn =
      case exn of
        OS.SysErr (msg, errno) =>
        (case OS.syserror "noent" of
           enoent as SOME _ => errno = enoent
         | NONE =>
           (* We cannot make sure whether the error is ENOENT.
            * Assume ENOENT anyway. *)
           true)
      | _ => false

  exception NotFound

  fun openFileOnPath nil filename = raise NotFound
    | openFileOnPath ((place, dir)::loadPath) filename =
      let
        val openName = Filename.concatPath (dir, filename)
        val ret =
            SOME (Filename.TextIO.openIn openName, (place, openName) : N.source)
            handle e as IO.Io {cause, ...} =>
                   if isENOENT cause then NONE else raise e
      in
        case ret of
          SOME x => x
        | NONE => openFileOnPath loadPath filename
      end

  fun openFileExact place filename =
      (Filename.TextIO.openIn filename, (place, filename) : N.source)
      handle e as IO.Io {cause, ...} =>
             if isENOENT cause then raise NotFound else raise e

  fun filterSTDPATH loadPath =
      List.filter
        (fn (N.STDPATH, _) : N.source => true
          | (N.LOCALPATH, _) => false)
        loadPath

  (*
   * How to search for a file:
   * (1) If "filename" is an absolute path, just open it.
   * (2) If "baseDir" is PWD, "filename" is a relative path from the
   *     current directory of the process and do not search in "loadPath".
   * (3) If "filename" begins with ".", "filename" is a relative path
   *     from "baseDir" and do not search in "loadPath".
   * (4) Otherwise, "filename" is a relative path from either "baseDir"
   *     or a directory in "loadPath".
   *     If "baseDir" is in STDPATH, only STDPATHs in loadPath are used.
   *)
  fun openFile ({baseDir, loadPath, ...}:loader) (fileLoc as (filename, loc)) =
      (if Filename.isAbsolute filename
       then openFileExact (placeOf baseDir) filename
       else case baseDir of
              PWD place => openFileExact place filename
            | DIR baseDir =>
              if String.isPrefix "." (Filename.toString filename)
              then openFileOnPath [baseDir] filename
              else openFileOnPath
                     (case #1 baseDir of
                        N.STDPATH => baseDir :: filterSTDPATH loadPath
                      | N.LOCALPATH => baseDir :: loadPath)
                     filename)
      handle e as IO.Io _ =>
             raiseUserError (loc, e)
           | NotFound =>
             raiseLoadFileError LoadFileError.FileNotFound fileLoc

  fun visitFile (loader as {circularCheck, loadPath, ...}:loader) fileLoc =
      let
        val (file, (filePlace, filename)) = openFile loader fileLoc
      in
        let
          val realPath = Filename.realPath filename
          val key = Filename.toString realPath
          val circularCheck =
              if SSet.member (circularCheck, key)
              then raiseLoadFileError LoadFileError.CircularLoad fileLoc
              else SSet.add (circularCheck, key)
        in
          (file,
           {baseDir = DIR (filePlace, Filename.dirname realPath),
            loadPath = loadPath,
            circularCheck = circularCheck} : loader,
           (filePlace, realPath) : N.source)
        end
        handle e => (TextIO.closeIn file; raise e)
      end

  fun parseInterface (source:N.source, file) =
      (if !Control.traceFileLoad
       then printErr ("require: " ^ Filename.toString (#2 source) ^ "\n")
       else ();
       InterfaceParser.parse
         (InterfaceParser.setup
            {read = fn n => TextIO.inputN (file, n),
             sourceName = Filename.toString (#2 source)}))

  fun parseSource (source:N.source, file) =
      (if !Control.traceFileLoad
       then printErr ("use: " ^ Filename.toString (#2 source) ^ "\n")
       else ();
       Parser.parse
         (Parser.setup
            {mode = Parser.File,
             read = fn (_,n) => TextIO.inputN (file, n),
             sourceName = Filename.toString (#2 source),
             initialLineno = 1}))

  datatype dec =
      REQUIRE of I.interfaceDec * I.loc
    | LOCALREQ of I.interfaceDec * I.loc
    | TOPDECS of A.topdec list
    | LOCALUSE of Filename.filename

  datatype parse_result =
      LOADED of (I.interfaceDec * I.loc) list
                * {source : N.source,
                   dep : N.file_dependency_node,
                   decs : dec Assoc.assoc}
    | NEW of loader * N.source * I.itop

  fun loadAndParseInterfaceFile loaded loader fileLoc =
      let
        val (file, newLoader, source) = visitFile loader fileLoc
      in
        (case Assoc.find (loaded, #2 source) of
           SOME result => LOADED result
         | NONE => NEW (newLoader, source, parseInterface (source, file))
                   handle e => (TextIO.closeIn file; raise e))
        before TextIO.closeIn file
      end

  fun makeInterfaceDec (source, decs, provide) =
      let
        val requires =
            Assoc.gather (fn REQUIRE x => [x] | _ => nil) decs
        val id = InterfaceID.generate ()
        val hash = InterfaceHash.generate
                     {source = source,
                      requires = map (#interfaceName o #1) requires,
                      topdecs = provide}
        val requiredIds =
            map (fn (dec, loc) => {id = #interfaceId dec, loc = loc}) requires
      in
        {interfaceId = id,
         interfaceName = {hash = hash, source = source},
         requiredIds = requiredIds,
         provideTopdecs = provide} : I.interfaceDec
      end

  fun evalREQUIRE loaded {loader, mode} fileLoc =
      case loadAndParseInterfaceFile loaded loader fileLoc of
        LOADED (idec, node) => (loaded, node)
      | NEW (loader, source, I.INCLUDES {includes, topdecs}) =>
        let
          val env = {loader = loader, mode = goDown mode}
          val reqs = map I.REQUIRE includes
          val (loaded, deps, decs) = evalRequireList loaded env reqs
          val dep = (source, N.INCLUDES, Assoc.listItems deps)
          val decs = Assoc.append (decs, #2 source, TOPDECS topdecs)
          val node = {source = source, dep = dep, decs = decs}
        in
          (Assoc.append (loaded, #2 source, (nil, node)), node)
        end
      | NEW (loader, source, I.INTERFACE {requires, provide}) =>
        let
          val env = {loader = loader, mode = goDown mode}
          val (loaded, deps, decs) = evalRequireList loaded env requires
          val idec = (makeInterfaceDec (source, decs, provide), #2 fileLoc)
          val dep = (source, N.INTERFACE (#interfaceName (#1 idec)),
                     Assoc.listItems deps)
          val decs = Assoc.singleton (#2 source, REQUIRE idec)
          val node = {source = source, dep = dep, decs = decs}
        in
          (Assoc.append (loaded, #2 source, ([idec], node)), node)
        end

  and evalRequire loaded (env as {loader, mode}) (I.LOCAL_REQUIRE fileLoc) =
      if loadRequireLocal mode then
        let
          val (loaded, {source, dep, decs}) = evalREQUIRE loaded env fileLoc
        in
          (loaded,
           Assoc.singleton (#2 source, N.LOCAL dep),
           Assoc.map (fn REQUIRE x => LOCALREQ x | x => x) decs)
        end
      else (loaded, Assoc.empty, Assoc.empty)
    | evalRequire loaded (env as {loader, mode}) (I.LOCAL_USE fileLoc) =
      if loadUseLocal mode then
        let
          val (file, _, source) = visitFile (loader # {loadPath = nil}) fileLoc
        in
          TextIO.closeIn file;
          (loaded,
           Assoc.singleton (#2 source, N.LOCAL (source, N.SML, nil)),
           Assoc.singleton (#2 source, LOCALUSE (#2 source)))
        end
        handle UserError.UserErrors [(_, _, LoadFileError.FileNotFound _)] =>
               (loaded, Assoc.empty, Assoc.empty)
      else (loaded, Assoc.empty, Assoc.empty)
    | evalRequire loaded env (I.REQUIRE fileLoc) =
      let
        val (loaded, {source, dep, decs}) = evalREQUIRE loaded env fileLoc
      in
        (loaded, Assoc.singleton (#2 source, N.DEPEND dep), decs)
      end

  and evalRequireList loaded env reqs =
      evalRequireList' loaded (map (fn x => (env, x)) reqs)

  and evalRequireList' loaded envReqs =
      foldl
        (fn ((env, req), (loaded, deps, decs)) =>
            let
              val (loaded, deps2, decs2) = evalRequire loaded env req
            in
              (loaded,
               Assoc.concatWith
                 (fn (N.LOCAL _, _) => LESS | _ => GREATER)
                 (deps, deps2),
               Assoc.concatWith
                 (fn (_, REQUIRE _) => LESS | _ => GREATER)
                 (decs, decs2))
            end)
        (loaded, Assoc.empty, Assoc.empty)
        envReqs

  fun checkDuplicateHash (decs : (I.interfaceDec * Loc.loc) list) =
      (foldl
         (fn (({interfaceName = iname as {hash,...},...}, loc), map) =>
             let
               val s = InterfaceName.hashToString hash
             in
               case SEnv.find (map, s) of
                 NONE => SEnv.insert (map, s, (iname, loc))
               | SOME y =>
                 raiseUserError (loc, LoadFileError.DuplicateHash (iname, y))
             end)
         SEnv.empty
         decs;
       ())

  fun loadInterface (env as {loader, ...}) fileLoc =
      case loadAndParseInterfaceFile Assoc.empty loader fileLoc of
        LOADED _ => raise Bug.Bug "loadInterface"
      | NEW (loader, source, I.INCLUDES _) =>
        raiseLoadFileError LoadFileError.NotAnInterface fileLoc
      | NEW (loader, source, I.INTERFACE {requires, provide}) =>
        let
          val (loaded, deps, decs) = evalRequireList Assoc.empty env requires
          val interfaceDecs = Assoc.gather #1 loaded
          val dec as {interfaceName, requiredIds, provideTopdecs, ...} =
              makeInterfaceDec (source, decs, provide)
          val _ = checkDuplicateHash ((dec, #2 fileLoc) :: interfaceDecs)
          val locallyRequiredIds =
              Assoc.gather
                (fn LOCALREQ (dec, loc) => [{id = #interfaceId dec, loc = loc}]
                  | _ => nil)
                decs
        in
          {interface =
             {interfaceDecs = map #1 interfaceDecs,
              provideInterfaceNameOpt = SOME interfaceName,
              requiredIds = requiredIds,
              locallyRequiredIds = locallyRequiredIds,
              provideTopdecs = provideTopdecs} : I.interface,
           dependency =
             {interfaceNameOpt = SOME interfaceName,
              depends = Assoc.listItems deps} : N.dependency,
           topdecsInclude = Assoc.gather (fn TOPDECS s => s | _ => nil) decs,
           allowUse = Assoc.gather (fn LOCALUSE s => [s] | _ => nil) decs}
        end

  fun loadIncludes (env as {loader as {baseDir, ...}, ...}) sources =
      let
        val sources =
            map (fn (place, filename) =>
                    (env # {loader = loader
                                       # {baseDir = setPlace baseDir place}},
                     I.REQUIRE (filename, Loc.noloc)))
                sources
        val (loaded, deps, decs) = evalRequireList' Assoc.empty sources
        val interfaceDecs = Assoc.gather #1 loaded
        val _ = checkDuplicateHash interfaceDecs
      in
        ({interfaceNameOpt = NONE,
          depends = Assoc.listItems deps} : N.dependency,
         {interfaceDecs = map #1 interfaceDecs,
          requiredIds =
            Assoc.gather
              (fn REQUIRE (dec, loc) => [{id = #interfaceId dec, loc = loc}]
                | _ => nil)
              decs,
          topdecsInclude = Assoc.gather (fn TOPDECS s => s | _ => nil) decs}
         : I.interface_unit)
      end

  fun evalTop loaded (env as {loader, allowUse}) top =
      case top of
        A.TOPDEC topdecs => (loaded, topdecs)
      | A.USE fileLoc =>
        let
          val (file, newLoader, source) = visitFile loader fileLoc
          val deps = [N.DEPEND (source, N.SML, nil)]
        in
          case allowUse of
            NONE => ()
          | SOME allowUse =>
            if List.exists (fn x => x = #2 source) allowUse
            then ()
            else (TextIO.closeIn file;
                  raiseLoadFileError LoadFileError.UseNotAllowed fileLoc);
          case Assoc.find (loaded, #2 source) of
            SOME (_, decs) =>
            (TextIO.closeIn file; (loaded, decs))
          | NONE =>
            case (parseSource (source, file)
                  handle e => (TextIO.closeIn file; raise e))
                 before TextIO.closeIn file
            of
              A.EOF => (Assoc.append (loaded, #2 source, (deps, nil)), nil)
            | A.UNIT {interface = A.INTERFACE _, tops, loc} =>
              raiseLoadFileError LoadFileError.UnexpectedInterfaceDecl fileLoc
            | A.UNIT {interface = A.NOINTERFACE, tops, loc} =>
              let
                val (loaded, decs) = evalTopList loaded env tops
              in
                (Assoc.append (loaded, #2 source, (deps, decs)), decs)
              end
        end

  and evalTopList loaded env nil = (loaded, nil)
    | evalTopList loaded env (top::tops) =
      let
        val (loaded, topdecs1) = evalTop loaded env top
        val (loaded, topdecs2) = evalTopList loaded env tops
      in
        (loaded, topdecs1 @ topdecs2)
      end

  fun makeLoadPath (stdPath, loadPath) =
      map (fn x => (N.STDPATH, x)) stdPath
      @ map (fn x => (N.LOCALPATH, x)) loadPath

  fun defaultInterface baseFilename =
      case baseFilename of
        NONE => NONE
      | SOME filename =>
        case Filename.suffix filename of
          SOME "sml" =>
          let
            val smifile = Filename.replaceSuffix "smi" filename
          in
            if CoreUtils.testExist smifile
            then SOME (Filename.basename smifile, Loc.noloc)
            else NONE
          end
        | _ => NONE

  fun load {baseFilename, stdPath, loadPath, loadMode}
           ({interface, tops, loc}:A.unit) =
      let
        val interfaceFileLoc =
            case interface of
              A.NOINTERFACE => defaultInterface baseFilename
            | A.INTERFACE fileLoc =>
              case baseFilename of
                SOME _ => SOME fileLoc
              | NONE =>
                raiseLoadFileError LoadFileError.UnexpectedInterfaceDecl fileLoc
        val baseDir =
            case baseFilename of
              SOME filename => DIR (N.LOCALPATH, Filename.dirname filename)
            | NONE => PWD N.LOCALPATH
        val loader = {baseDir = baseDir,
                      loadPath = makeLoadPath (stdPath, loadPath),
                      circularCheck = SSet.empty} : loader
      in
        case interfaceFileLoc of
          NONE =>
          let
            val (loaded, topdecs) =
                evalTopList Assoc.empty
                            {loader = loader # {loadPath = nil},
                             allowUse = NONE}
                            tops
          in
            ({interfaceNameOpt = NONE, depends = Assoc.gather #1 loaded},
             {interface = NONE, topdecsInclude = nil, topdecsSource = topdecs})
          end
        | SOME fileLoc =>
          let
            val {interface, dependency, topdecsInclude, allowUse} =
                loadInterface {loader = loader, mode = loadMode} fileLoc
            val (_, topdecs) =
                evalTopList Assoc.empty
                            {loader = loader # {loadPath = nil},
                             allowUse = SOME allowUse}
                            tops
          in
            (dependency,
             {interface = SOME interface,
              topdecsInclude = topdecsInclude,
              topdecsSource = topdecs} : I.compile_unit)
          end
      end

  fun loadInterfaceFiles {stdPath, loadPath, loadMode} sources =
      loadIncludes
        {loader = {baseDir = PWD N.LOCALPATH,
                   loadPath = makeLoadPath (stdPath, loadPath),
                   circularCheck = SSet.empty},
         mode = goDown loadMode}
        sources

end
