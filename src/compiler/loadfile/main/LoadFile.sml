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

  fun printErr x = TextIO.output (TextIO.stdErr, x)

  fun raiseUserError (loc, exn) =
      raise UserError.UserErrors [(loc, UserError.Error, exn)]

  fun raiseLoadFileError exn symbol =
      raiseUserError (Symbol.symbolToLoc symbol, exn symbol)

  (* a vairant of SEnv in which the insertion order is significant *)
  structure Assoc :> sig
    type 'a assoc
    type key = Filename.filename
    val empty : 'a assoc
    val singleton : key * 'a -> 'a assoc
    val find : 'a assoc * key -> 'a option
    val append : 'a assoc * key * 'a -> 'a assoc
    val concat : 'a assoc * 'a assoc -> 'a assoc
    val map : ('a -> 'b) -> 'a assoc -> 'b list
    val gather : ('a -> 'b list) -> 'a assoc -> 'b list
    val removeLast : 'a assoc -> 'a assoc * 'a option
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

    fun concat (assoc, (_, pairs):'a assoc) =
        foldr (fn ((k,v),z) => append (z, k, v)) assoc pairs

    fun mapRev f r nil = r
      | mapRev f r ((_:key,h)::t) = mapRev f (f h :: r) t
    fun map f ((_,pairs):'a assoc) = mapRev f nil pairs

    fun gather f assoc = List.concat (map f assoc)

    fun removeLast (a as (_,nil):'a assoc) = (a, NONE)
      | removeLast (map,(k,v)::t) =
        ((#1 (SEnv.remove (map, Filename.toString k)), t), SOME v)
  end

  type env =
       {baseDir : N.source option, visited : SSet.set}

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
            handle e as IO.Io {cause, function, name} =>
                   if isENOENT cause then NONE else raise e
      in
        case ret of
          SOME x => x
        | NONE => openFileOnPath loadPath filename
      end

  fun openLocalFile filename =
      (Filename.TextIO.openIn filename, (N.LOCALPATH, filename) : N.source)
      handle e as IO.Io {cause, function, name} =>
             if isENOENT cause then raise NotFound else raise e

  (*
   * How to search for a file:
   * (1) if "filename" is an absolute filename, just open it.
   * (2) if "baseDir" is NONE, "filename" is a relative path from the
   *     current directory of the process and do not search in "loadPath".
   * (3) if "filename" begins with ".", "filename" is a relative path
   *     from "baseDir" and do not search in "loadPath".
   * (4) Otherwise, "filename" is a relative path from either "baseDir"
   *     or a directory in "loadPath".
   *)
  fun openFile ({baseDir, ...}:env, loadPath) symbol =
      let
        val filename = Filename.fromString (Symbol.symbolToString symbol)
      in
        (if Filename.isAbsolute filename
         then openLocalFile filename
         else case baseDir of
                NONE => openLocalFile filename
              | SOME baseDir =>
                if String.isPrefix "." (Filename.toString filename)
                then openFileOnPath [baseDir] filename
                else openFileOnPath (baseDir :: loadPath) filename)
        handle e as IO.Io _ =>
               raiseUserError (Symbol.symbolToLoc symbol, e)
             | NotFound =>
               raiseLoadFileError LoadFileError.FileNotFound symbol
      end

  fun visitFile ({visited, ...}:env) (filePlace, filename) symbol =
      let
        val realPath = Filename.realPath filename
        val key = Filename.toString realPath
        val visited =
            if SSet.member (visited, key)
            then raiseLoadFileError LoadFileError.CircularLoad symbol
            else SSet.add (visited, key)
      in
        ({baseDir = SOME (filePlace, Filename.dirname realPath),
          visited = visited},
         (filePlace, realPath) : N.source)
      end

  datatype 'a parse_result =
      LOADED of 'a
    | PARSED of env * N.source * I.itop

  fun parseInterface loaded (env, loadPath) symbol =
      let
        val (file, source) = openFile (env, loadPath) symbol
      in
        (let
           val (newEnv, source) = visitFile env source symbol
         in
           case Assoc.find (loaded, #2 source) of
             SOME result => LOADED result
           | NONE =>
             let
               val _ =
                   if !Control.traceFileLoad
                   then printErr ("require: " ^ Filename.toString (#2 source)
                                  ^ "\n")
                   else ()
               val input = InterfaceParser.setup
                             {read = fn n => TextIO.inputN (file, n),
                              sourceName = Filename.toString (#2 source)}
               val itop = InterfaceParser.parse input
             in
               PARSED (newEnv, source, itop)
             end
         end
         handle e => (TextIO.closeIn file; raise e))
         before TextIO.closeIn file
      end

  fun requiredIdOf ({interfaceId,...} : I.interfaceDec, loc : Loc.loc) =
      {id = interfaceId, loc = loc}

  fun interfaceNameOf ({interfaceName,...} : I.interfaceDec, _ : Loc.loc) =
      interfaceName

  fun setupInterface (source, requires, provide) =
      let
        val id = InterfaceID.generate ()
        val hash = InterfaceHash.generate
                     {source = source,
                      requires = map interfaceNameOf requires,
                      topdecs = provide}
      in
        {interfaceId = id,
         interfaceName = {hash = hash, source = source},
         requiredIds = map requiredIdOf requires,
         provideTopdecs = provide} : I.interfaceDec
      end

  fun filterLocalRequire l =
      List.mapPartial (fn I.REQUIRE s => NONE | I.LOCAL_REQUIRE s => SOME s) l
  fun filterRequire l =
      List.mapPartial (fn I.REQUIRE s => SOME s | I.LOCAL_REQUIRE s => NONE) l

  fun loadRequire loaded (context as {env, loadPath, loadAll}) symbol =
      case parseInterface loaded (env, loadPath) symbol of
        LOADED {ret, ...} => (loaded, ret)
      | PARSED (env, source, I.INCLUDES {includes, topdecs}) =>
        let
          val context = context # {env = env}
          val (loaded, ret) = loadRequires loaded context includes
          val ret = Assoc.append (ret, #2 source, {require=[], topdecs=topdecs})
          val dec = {interfaceDecs = [], loadedFile = source}
        in
          (Assoc.append (loaded, #2 source, {dec=dec, ret=ret}), ret)
        end
      | PARSED (env, source, I.INTERFACE {requires, provide}) =>
        let
          val context = context # {env = env}
          val reqs = filterRequire requires
          val (loaded, ret) = loadRequires loaded context reqs
          val loaded =
              if loadAll
              then #1 (loadRequires loaded context
                                    (filterLocalRequire requires))
              else loaded
          val idec = setupInterface (source, Assoc.gather #require ret, provide)
          val id = (idec, Symbol.symbolToLoc symbol)
          val ret = Assoc.singleton (#2 source, {require=[id], topdecs=nil})
          val dec = {interfaceDecs = [id], loadedFile = source}
        in
          (Assoc.append (loaded, #2 source, {dec=dec, ret=ret}), ret)
        end

  and loadRequires loaded context symbols =
      foldl (fn (symbol, (loaded, ret1)) =>
                let
                  val (loaded, ret2) = loadRequire loaded context symbol
                in
                  (loaded, Assoc.concat (ret1, ret2))
                end)
            (loaded, Assoc.empty)
            symbols

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

  fun removeIds ids1 ids2 =
      let
        val set = foldl (fn ({id,loc:Loc.loc},z) => InterfaceID.Set.add (z,id))
                        InterfaceID.Set.empty
                        ids2
      in
        List.filter (fn {id,loc} => not (InterfaceID.Set.member (set,id))) ids1
      end

  fun loadINTERFACE context (source, {requires, provide}) =
      let
        val (loaded, retReq) =
            loadRequires Assoc.empty context (filterRequire requires)
        val (loaded, retLocal) =
            loadRequires loaded context (filterLocalRequire requires)
        val decs = Assoc.map #dec loaded
        val interfaceDecs = List.concat (map #interfaceDecs decs)
        val _ = checkDuplicateHash interfaceDecs
        val interfaceDecs = map #1 interfaceDecs
        val {interfaceName, requiredIds, provideTopdecs, ...} =
            setupInterface (source, Assoc.gather #require retReq, provide)
        val retAll = Assoc.concat (retReq, retLocal)
        val allRequiredIds = map requiredIdOf (Assoc.gather #require retAll)
      in
        ({interface =
            {interfaceDecs = interfaceDecs,
             provideInterfaceNameOpt = SOME interfaceName,
             requiredIds = requiredIds,
             locallyRequiredIds = removeIds allRequiredIds requiredIds,
             provideTopdecs = provideTopdecs} : I.interface,
          topdecsInclude = Assoc.gather #topdecs retAll},
         {interfaceNameOpt = SOME interfaceName,
          compile = map #loadedFile decs,
          link = map #interfaceName interfaceDecs} : N.dependency,
         source)
      end

  fun loadINCLUDES context (source, {includes, topdecs}) =
      let
        val (loaded, ret) = loadRequires Assoc.empty context includes
        val decs = Assoc.map #dec loaded
        val interfaceDecs = List.concat (map #interfaceDecs decs)
        val _ = checkDuplicateHash interfaceDecs
        val interfaceDecs = map #1 interfaceDecs
        val includes = map #1 (Assoc.gather #require ret)
        val requiredIds = 
            InterfaceID.Map.listItems
              (foldl (fn (x,z) => InterfaceID.Map.insert (z, #id x, x))
                     InterfaceID.Map.empty
                     (List.concat (map #requiredIds includes)))
      in
        ({interface =
            {interfaceDecs = interfaceDecs,
             provideInterfaceNameOpt = NONE,
             requiredIds = requiredIds,
             locallyRequiredIds = nil,
             provideTopdecs = List.concat (map #provideTopdecs includes)},
          topdecsInclude = Assoc.gather #topdecs ret},
         {interfaceNameOpt = NONE,
          compile = map #loadedFile decs,
          link = map #interfaceName interfaceDecs} : N.dependency,
         source)
      end

  fun loadInterface (context as {env,...}) symbol =
      case parseInterface Assoc.empty (env, nil) symbol of
        PARSED (env, source, I.INTERFACE iface) =>
        loadINTERFACE (context # {env=env}) (source, iface)
      | PARSED (env, source, I.INCLUDES includes) =>
        loadINCLUDES (context # {env=env}) (source, includes)
      | LOADED _ => raise Bug.Bug "loadInterface"

  fun loadTopInterface (context as {env,...}) symbol =
      case parseInterface Assoc.empty (env, nil) symbol of
        PARSED (env, source, I.INTERFACE iface) =>
        loadINTERFACE (context # {env=env}) (source, iface)
      | PARSED (env, source, I.INCLUDES includes) =>
        raiseLoadFileError LoadFileError.InvalidTopInterface symbol
      | LOADED _ => raise Bug.Bug "loadTopInterface"

  fun parseSource loaded env src =
      let
        val (file, source) = openFile (env, nil) src
      in
        (let
           val (newEnv, source) = visitFile env source src
           val _ =
               if !Control.traceFileLoad
               then printErr ("use: " ^ Filename.toString (#2 source) ^ "\n")
               else ()
         in
           case Assoc.find (loaded, #2 source) of
             SOME x => (loaded, newEnv, #ret x)
           | NONE =>
             let
               val input = Parser.setup
                             {mode = Parser.File,
                              read = fn (_,n) => TextIO.inputN (file, n),
                              sourceName = Filename.toString (#2 source),
                              initialLineno = 1}
               val ret = Parser.parse input
             in
               (Assoc.append (loaded, #2 source, {ret=ret, loadedFile=source}),
                newEnv, ret)
             end
         end
         handle e => (TextIO.closeIn file; raise e))
        before TextIO.closeIn file
      end

  fun evalTop loaded env top =
      case top of
        A.TOPDEC topdecs => (loaded, topdecs)
      | A.USE symbol =>
        case parseSource loaded env symbol of
          (loaded, env, A.EOF) => (loaded, nil)
        | (loaded, env, A.UNIT {interface = A.INTERFACE _, ...}) =>
          raiseLoadFileError LoadFileError.UseWithInterface symbol
        | (loaded, env, A.UNIT {interface = A.NOINTERFACE, tops, ...}) =>
          evalTopList loaded env tops

  and evalTopList loaded env nil = (loaded, nil)
    | evalTopList loaded env (top::tops) =
      let
        val (loaded, tops1) = evalTop loaded env top
        val (loaded, tops2) = evalTopList loaded env tops
      in
        (loaded, tops1 @ tops2)
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
            then SOME (Symbol.mkSymbol
                         (Filename.toString (Filename.basename smifile))
                         Loc.noloc)
            else NONE
          end
        | _ => NONE

  fun load {baseFilename, stdPath, loadPath, loadAll}
           ({interface, tops, loc}:A.unit) =
      let
        val loadPath = makeLoadPath (stdPath, loadPath)
        val interfaceSymbol =
            case interface of
              A.INTERFACE symbol => SOME symbol
            | A.NOINTERFACE => defaultInterface baseFilename
        val baseDir =
            case baseFilename of
              SOME filename => SOME (N.LOCALPATH, Filename.dirname filename)
            | NONE => NONE
        val env = {baseDir = baseDir, visited = SSet.empty} : env
        val (loaded, topdecsSource) = evalTopList Assoc.empty env tops
        val loadedFiles1 = Assoc.map #loadedFile loaded
      in
        case interfaceSymbol of
          NONE =>
          ({interfaceNameOpt = NONE,
            compile = loadedFiles1,
            link = nil} : N.dependency,
           {interface = NONE,
            topdecsInclude = nil,
            topdecsSource = topdecsSource} : I.compileUnit)
        | SOME symbol =>
          let
            val ({interface, topdecsInclude}, dependency, source) =
                loadTopInterface {env=env, loadPath=loadPath, loadAll=loadAll}
                                 symbol
          in
            (dependency
               # {compile = loadedFiles1 @ #compile dependency @ [source]},
             {interface = SOME interface,
              topdecsInclude = topdecsInclude,
              topdecsSource = topdecsSource})
          end
      end

  fun loadInterfaceFile {stdPath, loadPath, loadAll} filename =
      let
        val loadPath = makeLoadPath (stdPath, loadPath)
        val symbol = Symbol.mkSymbol (Filename.toString filename) Loc.noloc
        val env = {baseDir = NONE, visited = SSet.empty} : env
        val context = {env = env, loadPath = loadPath, loadAll = loadAll}
        val (loaded, ret) = loadRequires Assoc.empty context [symbol]
        val allInterfaceDecs = Assoc.gather (#interfaceDecs o #dec) loaded
        val _ = checkDuplicateHash allInterfaceDecs
        val dependency : N.dependency =
            (* remove myself from dependency *)
            case Assoc.removeLast loaded of
              (_, NONE) => raise Bug.Bug "loadInterfaceFile"
            | (loaded2, SOME me) =>
              {interfaceNameOpt =
                 case #interfaceDecs (#dec me) of
                   [({interfaceName,...},_)] => SOME interfaceName
                 | _ => NONE,
               compile = Assoc.map (#loadedFile o #dec) loaded2,
               link = map (#interfaceName o #1)
                          (Assoc.gather (#interfaceDecs o #dec) loaded2)}
      in
        (dependency,
         {interfaceDecs = map #1 allInterfaceDecs,
          requiredIds = map requiredIdOf (Assoc.gather #require ret),
          topdecsInclude = Assoc.gather #topdecs ret} : I.interface_unit)
      end

  fun loadInteractiveEnv {stdPath, loadPath, loadAll} filename =
      let
        val loadPath = makeLoadPath (stdPath, loadPath)
        val symbol = Symbol.mkSymbol (Filename.toString filename) Loc.noloc
        val env = {baseDir = NONE, visited = SSet.empty} : env
        val ({interface, topdecsInclude}, dependency, _) =
            loadInterface {env=env, loadPath=loadPath, loadAll=loadAll} symbol
      in
        {interface = interface # {provideTopdecs = nil},
         interfaceDecls = #provideTopdecs interface,
         topdecsInclude = topdecsInclude} : I.interactiveUnit
      end

end
