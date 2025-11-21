(**
 * LoadFile.sml
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)

structure LoadFile =
struct

  structure A = Absyn
  structure I = AbsynInterface
  structure L = AbsynInterfaceLoaded
  structure N = InterfaceName
  structure F = SMLFormat.FormatExpression
  structure E = LoadFileError
      
  fun consOpt (SOME x, y) = x :: y
    | consOpt (NONE, y) = y

  val ind_d = F.Indicator {space = true, newline = SOME {priority = F.Deferred}}
  fun Term x = F.Term (size x, x)

  fun printErr x =
      TextIO.output (TextIO.stdErr, x)

  fun raiseError (loc, exn) =
      raise UserError.UserErrors [(Loc.LOC loc, UserError.Error, exn)]

  (* Key-value store in which insertion order is preserved *)
  structure Assoc :> sig
    type 'a assoc
    type key = Filename.filename
    type keys
    val empty : 'a assoc
    val singleton : key * 'a -> 'a assoc
    val find : 'a assoc * key -> 'a option
    (* add to right if not exist *)
    val append : 'a assoc * key * 'a -> 'a assoc
    (* left precedes right *)
    val concatWith : ('a * 'a -> 'a) -> 'a assoc * 'a assoc -> 'a assoc
    val remove : 'a assoc * key -> 'a assoc
    val keys : 'a assoc -> keys
    val listItems : 'a assoc -> 'a list
    val map : ('a -> 'b) -> 'a assoc -> 'b assoc
    val collect : ('a -> 'b) -> 'a assoc -> 'b list
    val collectPartial : ('a -> 'b option) -> 'a assoc -> 'b list
    (* for debug *)
    val format : ('a -> SMLFormat.format) -> 'a assoc -> SMLFormat.format
  end =
  struct
    type key = Filename.filename
    datatype keys = N | I of key | A of keys * keys
    fun keysFoldr f z N = z
      | keysFoldr f z (I k) = f (k, z)
      | keysFoldr f z (A (a, N)) = keysFoldr f z a
      | keysFoldr f z (A (a, I k)) = keysFoldr f (f (k, z)) a
      | keysFoldr f z (A (a, A (b, c))) = keysFoldr f z (A (A (a, b), c))
    fun rmKey key N r = r
      | rmKey key (I x) r = if x = key then r else A (I x, r)
      | rmKey key (A (a, N)) r = rmKey key a r
      | rmKey key (A (a, A (b, c))) r = rmKey key (A (A (a, b), c)) r
      | rmKey key (A (a, I x)) r =
        if x = key then A (a, r) else rmKey key a (A (I x, r))
    val rmKey = fn key => fn keys => rmKey key keys N
    fun keysMinus keys1 keys2 = keysFoldr (fn (k,z) => rmKey k z) keys1 keys2

    type 'a assoc = 'a Filename.Map.map * keys
    val empty = (Filename.Map.empty, N)
    fun singleton (k, v) = (Filename.Map.singleton (k, v), I k)
    fun append ((smap, keys), k, v) =
        (Filename.Map.insert (smap, k, v),
         if Filename.Map.inDomain (smap, k) then keys else A (keys, I k))
    fun concatWith f ((smap1, keys1), (smap2, keys2)) =
        (Filename.Map.unionWith f (smap1, smap2),
         A (keys1, keysMinus keys2 keys1))
    fun find ((smap, keys), k) = Filename.Map.find (smap, k)
    fun remove ((smap, keys), k) =
        (#1 (Filename.Map.remove (smap, k))
         handle LibBase.NotFound => raise Bug.Bug "Assoc.remove",
         rmKey k keys)
    fun keys (smap, keys) = keys
    fun listItems (smap, keys) =
        keysFoldr (fn (k,z) => Filename.Map.lookup (smap, k) :: z) nil keys
        handle LibBase.NotFound => raise Bug.Bug "Assoc.listItems"
    fun map f (smap, keys) = (Filename.Map.map f smap, keys)
    fun collect f (smap, keys) =
        keysFoldr (fn (k,z) => f (Filename.Map.lookup (smap, k)) :: z) nil keys
        handle LibBase.NotFound => raise Bug.Bug "Assoc.collect"
    fun collectPartial f (smap, keys) =
        keysFoldr
          (fn (k, z) => case Filename.Map.find (smap, k) of
                          NONE => raise Bug.Bug "Assoc.collectPartial"
                        | SOME v => consOpt (f v, z))
          nil
          keys
    fun format fmt (smap, keys) =
        SMLFormat.BasicFormatters.format_list
          (fn (k, v) =>
              [Term (Filename.toString k), ind_d,
               Term "->", ind_d, F.Sequence (fmt v)])
          [F.Newline]
          (keysFoldr (fn (k,z) => (k, Filename.Map.lookup (smap, k)) :: z)
                     nil keys)
  end

  datatype base_dir =
      DIR of InterfaceName.source
    | PWD of Loc.file_place

  fun placeOf (DIR (p, _)) = p
    | placeOf (PWD p) = p

  type loader = {baseDir : base_dir, loadPath : InterfaceName.source list}

  fun baseDirPlace ({baseDir = DIR (place, _), ...}:loader) = place
    | baseDirPlace ({baseDir = PWD place, ...}) = place

  fun isENOENT exn =
      case exn of
        OS.SysErr (msg, SOME errno) =>
        (case OS.errorName errno of
           "noent" => true
         | _ => false)
      | _ => false

  exception NotFound

  fun openFileOnPath (nil : N.source list) filename = raise NotFound
    | openFileOnPath ((place, dir)::loadPath) filename =
      let
        val openName = Filename.concatPath (dir, filename)
        val ret =
            SOME (Filename.TextIO.openIn openName, (place, openName))
            handle e as IO.Io {cause, ...} =>
                   if isENOENT cause then NONE else raise e
      in
        case ret of
          SOME x => x
        | NONE => openFileOnPath loadPath filename
      end

  fun openFileExact place filename =
      (Filename.TextIO.openIn filename, (place, filename) : N.source)

  fun filterSTDPATH loadPath =
      List.filter
        (fn (Loc.STDPATH, _) : N.source => true
          | (Loc.USERPATH, _) => false)
        loadPath

  (*
   * How to search for a file:
   * (1) If "baseDir" is PWD, "path" is a relative path from the
   *     current directory of the process.
   * (2) If "filename" begins with "." or "..", "filename" is a relative path
   *     from "baseDir" and is not searched for in "loadPath".
   * (3) Otherwise, "filename" is a relative path from either "baseDir"
   *     or a directory in "loadPath".
   *     If "baseDir" is in STDPATH, only STDPATHs in loadPath are used.
   *)
  fun openPath ({baseDir, loadPath, ...}:loader) (path, loc) =
      (case baseDir of
         PWD place =>
         (openFileExact place (RequirePath.toFilename path)
          handle e as IO.Io {cause, ...} =>
                 if isENOENT cause then raise NotFound else raise e)
       | DIR baseDir =>
         if RequirePath.beginsWithDot path
         then openFileOnPath [baseDir] (RequirePath.toFilename path)
         else openFileOnPath
                (case #1 baseDir of
                   Loc.STDPATH => baseDir :: filterSTDPATH loadPath
                 | Loc.USERPATH => baseDir :: loadPath)
               (RequirePath.toFilename path))
      handle e as IO.Io _ =>
             raiseError (loc, e)
           | NotFound =>
             raiseError (loc, E.FileNotFoundOnPath path)
           | RequirePath.Path RequirePath.EmptyPath =>
             raiseError (loc, LoadFileError.PathMustNotBeEmpty)
           | RequirePath.Path RequirePath.AbsolutePath =>
             raiseError (loc, LoadFileError.AbsolutePathNotAllowed path)
           | RequirePath.Path RequirePath.DirectoryPath =>
             raiseError (loc, LoadFileError.DirectoryPathNotAllowed path)

  datatype file_or_path =
      FILE of InterfaceName.source
    | PATH of RequirePath.path

  fun visitFile loader filePathLoc =
      let
        val (file, (filePlace, filename)) =
            case filePathLoc of
              (FILE (place, file), loc) => openFileExact place file
            | (PATH path, loc) => openPath loader (path, loc)
        val realPath = Filename.realPath filename
                       handle e => (TextIO.closeIn file; raise e)
      in
        (loader # {baseDir = DIR (filePlace, Filename.dirname realPath)},
         file,
         (filePlace, realPath) : N.source)
      end

  fun parseSmi (file, source as (_, filename)) =
      (if !Control.traceFileLoad
       then printErr ("smi: " ^ Filename.toString filename ^ "\n")
       else ();
       #2 (InterfaceParser.parse
             (InterfaceParser.setup
                {read = fn n => TextIO.inputN (file, n),
                 source = Loc.FILE source,
                 allowUtf8 = !Control.allowUtf8})))

  fun parseSml (file, source as (_, filename)) =
      (if !Control.traceFileLoad
       then printErr ("sml: " ^ Filename.toString filename ^ "\n")
       else ();
       Parser.parse
         (Parser.setup
            {source = Loc.FILE source,
             read = fn (_, n) => TextIO.inputN (file, n),
             initialLineno = 1,
             allowUtf8 = !Control.allowUtf8}))

  datatype allow_use =
      ALLOW_ALL
    | ALLOW_ONLY of Filename.Set.set

  datatype parse_result =
      L of A.absyn
    | I of I.top

  type toplevel_additionals =
      {initRequisites : (L.interface_dec * N.init_requisite) Assoc.assoc,
       locallyRequiredIds : (L.interface_dec * L.loc) Assoc.assoc,
       topdecsInclude : A.topdec list Assoc.assoc}

  datatype eval_result =
      SML of {node : N.file_dependency_node,
              topdecs : A.topdec list}
    | SMI of {dec : (L.interface_dec * toplevel_additionals) option,
              node : N.file_dependency_node,
              inits : (L.interface_dec * N.init_requisite) Assoc.assoc,
              requires : (L.interface_dec * L.loc) Assoc.assoc,
              topdecs : A.topdec list Assoc.assoc}
    | CYCLE

  datatype ('eval_result, 'parse_result) new_or_loaded =
      LOADED of 'eval_result
    | NEW of loader * 'parse_result * N.source

  (* for debug *)
  fun format_base_dir (DIR source) =
      InterfaceName.format_source source
    | format_base_dir (PWD place) =
      [F.Sequence (Loc.format_file_place place), ind_d, Term "(PWD)"]
  fun format_loader {baseDir, loadPath} =
      Term "BASE" :: ind_d :: F.Sequence (format_base_dir baseDir) :: F.Newline
      :: Term "PATH" :: ind_d
      :: SMLFormat.BasicFormatters.format_list
           InterfaceName.format_source
           [ind_d]
           loadPath
  fun format_eval_result er =
      case er of
        CYCLE => [Term "CYCLE"]
      | SML {node, ...} =>
        Term "SML" :: ind_d
        :: InterfaceName.format_file_dependency_node node
      | SMI {node, requires, dec, ...} =>
        Term "SMI" :: ind_d
        :: F.Sequence
             (case dec of
                SOME ({interfaceId=x, ...}, _) => InterfaceID.format_id x
              | NONE => [Term "-"])
        :: Term ":" :: ind_d
        :: F.Sequence (SMLFormat.BasicFormatters.format_list
                         (InterfaceID.format_id o #interfaceId o #1)
                         [ind_d]
                         (Assoc.listItems requires))
        :: ind_d :: InterfaceName.format_file_dependency_node node

  fun visitAndParseSmi loaded loader (filePathLoc as (_, loc)) =
      let
        val (newLoader, file, source) = visitFile loader filePathLoc
      in
        (case Assoc.find (loaded, #2 source) of
           SOME (SMI result) => LOADED result
         | SOME (SML _) => raiseError (loc, E.UseRequireConflict (#2 source))
         | SOME CYCLE => raiseError (loc, E.CircularLoad (#2 source))
         | NONE => NEW (newLoader, parseSmi (file, source), source)
                   handle e => (TextIO.closeIn file; raise e))
        before TextIO.closeIn file
      end

  fun visitAndParseSml loaded loader (filePathLoc as (_, loc)) =
      let
        (* ignore the load path when processing _use file *)
        val loader = loader # {loadPath = nil}
        val (newLoader, file, source) = visitFile loader filePathLoc
      in
        (case Assoc.find (loaded, #2 source) of
           SOME (SML result) => LOADED result
         | SOME (SMI _) => raiseError (loc, E.UseRequireConflict (#2 source))
         | SOME CYCLE => raiseError (loc, E.CircularLoad (#2 source))
         | NONE => NEW (newLoader, parseSml (file, source), source)
                   handle e => (TextIO.closeIn file; raise e))
        before TextIO.closeIn file
      end

  fun nextMode N.ALL = N.ALL
    | nextMode N.ALL_USERPATH = N.ALL_USERPATH
    | nextMode N.COMPILE_AND_LINK = N.LINK
    | nextMode N.LINK = N.LINK
    | nextMode N.COMPILE = N.NOLOCAL
    | nextMode N.NOLOCAL = N.NOLOCAL

  fun evalTop loaded loader allow top =
      case top of
        A.TOPDEC (topdecs, loc) =>
        (loaded, {edge = NONE, topdecs = topdecs})
      | A.USE ((path, _), loc) =>
        let
          val (loaded, {node, topdecs}) = loadUse loaded loader (path, loc)
        in
          case (allow, node) of
            (ALLOW_ALL, _) => ()
          | (ALLOW_ONLY names, N.FILE {source, ...}) =>
            if Filename.Set.member (names, #2 source)
            then ()
            else raiseError (loc, E.UseNotAllowed path);
          (loaded, {edge = SOME (N.USE, node, Loc.LOC loc), topdecs = topdecs})
        end
      | A.U_USE (path, loc) =>
        evalTop loaded loader allow (A.USE (path, loc))
      | A.TOPSEMICOLON _ =>
        (loaded, {edge = NONE, topdecs = nil})

  and evalTopList loaded loader allow nil =
      (loaded, {edges = nil, topdecs = nil})
    | evalTopList loaded loader allow (top :: tops) =
      let
        val (loaded, {edge, topdecs=t1}) =
            evalTop loaded loader allow top
        val (loaded, {edges, topdecs=t2}) =
            evalTopList loaded loader allow tops
      in
        (loaded, {edges = consOpt (edge, edges), topdecs = t1 @ t2})
      end

  and loadUse loaded loader (path, loc) =
      case visitAndParseSml loaded loader (PATH path, loc) of
        LOADED result => (loaded, result)
      | NEW (loader, abunit, source) =>
        let
          val loaded = Assoc.append (loaded, #2 source, CYCLE)
          val (loaded, {edges, topdecs}) =
              case abunit of
                A.EOF _ => (loaded, {edges = nil, topdecs = nil})
              | A.UNIT (SOME ((path, _), loc), tops, _) =>
                raiseError (loc, E.UnexpectedInterfaceDecl path)
              | A.UNIT (NONE, tops, _) =>
                evalTopList loaded loader ALLOW_ALL tops
          val result = {node = N.FILE {source = source,
                                       fileType = N.SML,
                                       edges = edges},
                        topdecs = topdecs}
          val loaded = Assoc.remove (loaded, #2 source)
          val loaded = Assoc.append (loaded, #2 source, SML result)
        in
          (loaded, result)
        end

  fun decLocToIdLoc ({interfaceId, ...} : L.interface_dec, loc) =
      {id = interfaceId, loc = loc}

  fun decInitToInitName ({interfaceName, ...} : L.interface_dec, init) =
      (init, interfaceName)

  fun maxInit (N.INIT_ALWAYS, _) = N.INIT_ALWAYS
    | maxInit (N.INIT_IFNEEDED, x) = x

  fun toTopdec (I.SIGNATURE sigdec) = [A.TOPSIGNATURE sigdec]
    | toTopdec (I.SIGSEMICOLON _) = []

  fun evalRequireOptions symbols inits =
      let
        val {init} =
            foldl
              (fn ((symbol, loc), options) =>
                  case Symbol.toString symbol of
                    "init" => options # {init = true}
                  | s => raiseError (loc, E.UnknownRequireOption s))
              {init = false}
              symbols
      in
        if init
        then Assoc.map (fn (dec, _) => (dec, N.INIT_ALWAYS)) inits
        else inits
      end

  fun evalIrequire loaded loader mode irequire =
      case irequire of
        I.REQUIRE ((path, _), options, loc) =>
        let
          val loc = loc
          val (loaded, {dec = _, node, inits, requires, topdecs}) =
              loadRequire loaded loader (nextMode mode) (PATH path, loc)
          val inits = evalRequireOptions options inits
        in
          (loaded, SOME {edge = (N.REQUIRE, node, Loc.LOC loc),
                         inits = inits,
                         localRequires = Assoc.empty,
                         requires = requires,
                         topdecs = topdecs})
        end
      | I.REQUIRE_LOCAL ((path, _), options, loc) =>
        if case mode of
             N.ALL => true
           | N.ALL_USERPATH => baseDirPlace loader = Loc.USERPATH
           | N.COMPILE_AND_LINK => true
           | N.LINK => true
           | N.COMPILE => true
           | N.NOLOCAL => false
        then
          let
            val loc = loc
            val (loaded, {dec = _, node, inits, requires, topdecs}) =
                loadRequire loaded loader (nextMode mode) (PATH path, loc)
            val inits = evalRequireOptions options inits
          in
            (loaded, SOME {edge = (N.LOCAL_REQUIRE, node, Loc.LOC loc),
                           inits = inits,
                           localRequires = requires,
                           requires = Assoc.empty,
                           topdecs = topdecs})
          end
        else (loaded, NONE)
      | I.USE_LOCAL ((path, _), loc) =>
        if case mode of
             N.ALL => true
           | N.ALL_USERPATH => baseDirPlace loader = Loc.USERPATH
           | N.COMPILE_AND_LINK => true
           | N.LINK => false
           | N.COMPILE => true
           | N.NOLOCAL => false
        then
          let
            val (loaded, {node, topdecs = _}) =
                loadUse loaded loader (path, loc)
          in
            (loaded, SOME {edge = (N.LOCAL_USE, node, Loc.LOC loc),
                           inits = Assoc.empty,
                           localRequires = Assoc.empty,
                           requires = Assoc.empty,
                           topdecs = Assoc.empty})
          end
        else (loaded, NONE)
      | I.REQSEMICOLON _ => (loaded, NONE)

  and evalIrequireList loaded loader mode nil =
      (loaded, {edges = nil,
                inits = Assoc.empty,
                localRequires = Assoc.empty,
                requires = Assoc.empty,
                topdecs = Assoc.empty})
    | evalIrequireList loaded loader mode (fileLoc :: fileLocs) =
      let
        val (loaded, result1) = evalIrequire loaded loader mode fileLoc
        val (loaded, result2) = evalIrequireList loaded loader mode fileLocs
      in
        case (result1, result2) of
          (NONE, _) => (loaded, result2)
        | (SOME {edge, inits=i1, localRequires=l1, requires=r1, topdecs=t1},
           {edges, inits=i2, localRequires=l2, requires=r2, topdecs=t2}) =>
          (loaded, {edges = edge :: edges,
                    inits = Assoc.concatWith
                              (fn ((d1, x), (d2, y)) => (d2, maxInit (x, y)))
                              (i1, i2),
                    localRequires = Assoc.concatWith #2 (l1, l2),
                    requires = Assoc.concatWith #2 (r1, r2),
                    topdecs = Assoc.concatWith #2 (t1, t2)})
      end

  and loadRequire loaded loader mode filePathLoc =
      case visitAndParseSmi loaded loader filePathLoc of
        LOADED result => (loaded, result)
      | NEW (loader, I.INCLUDES (includes, sigdecs, _), source) =>
        let
(*
fun locToString loc = Loc.locToString loc ^ "\n"
fun topdecLoc (A.TOPDECSTR (_, loc)) = loc
  | topdecLoc (A.TOPDECSIG (_, loc)) = loc
  | topdecLoc (A.TOPDECFUN (_, loc)) = loc
val topDecLocs = map topdecLoc topdecs
val _ = print "loadRequire\n"
val _ = print "require loc\n"
val _ = print (locToString loc)
val _ = print "topdecLocs\n"
val _ = map print (map locToString  topDecLocs)
val _ = print "\n"
*)
          val loaded = Assoc.append (loaded, #2 source, CYCLE)
          val (loaded, {edges, inits, requires, topdecs = topdecsAssoc}) =
              loadIncludeList loaded loader mode includes
          val topdecs = List.concat (map toTopdec sigdecs)
          val result =
              {dec = NONE,
               node = N.FILE {source = source,
                              fileType = N.INCLUDES,
                              edges = edges},
               inits = inits,
               requires = requires,
               topdecs = Assoc.append (topdecsAssoc, #2 source, topdecs)}
          val loaded = Assoc.remove (loaded, #2 source)
          val loaded = Assoc.append (loaded, #2 source, SMI result)
        in
          (loaded, result)
        end
      | NEW (loader, I.INTERFACE (requires, provide, _), source) =>
        let
          val loaded = Assoc.append (loaded, #2 source, CYCLE)
          val (loaded, {edges, inits, localRequires, requires, topdecs}) =
              evalIrequireList loaded loader mode requires
          val hash = InterfaceHash.generate
                       {filename = #2 source,
                        requires = Assoc.collect (#interfaceName o #1) requires,
                        topdecs = provide}
          val dec : L.interface_dec =
              {interfaceId = InterfaceID.generate (),
               interfaceName = {source = source, hash = hash},
               requiredIds = Assoc.collect decLocToIdLoc requires,
               provideTopdecs = provide}
          val top =
              {initRequisites = inits,
               locallyRequiredIds = localRequires,
               topdecsInclude = topdecs}
          val result =
              {dec = SOME (dec, top),
               node = N.FILE {source = source,
                              fileType = N.INTERFACE hash,
                              edges = edges},
               inits = Assoc.append (inits, #2 source, (dec, N.INIT_IFNEEDED)),
               requires = Assoc.singleton (#2 source, (dec, #2 filePathLoc)),
               topdecs = Assoc.empty}
          val loaded = Assoc.remove (loaded, #2 source)
          val loaded = Assoc.append (loaded, #2 source, SMI result)
        in
          (loaded, result)
        end

  and loadIncludeList loaded loader mode nil =
      (loaded, {edges = nil,
                inits = Assoc.empty,
                requires = Assoc.empty,
                topdecs = Assoc.empty})
    | loadIncludeList loaded loader mode
                      (I.INCLUDE ((path, _), loc) :: pathLocs) =
      let
        val (loaded, {node, inits=i1, requires=r1, topdecs=t1, ...}) =
            loadRequire loaded loader mode (PATH path, loc)
        val (loaded, {edges, inits=i2, requires=r2, topdecs=t2}) =
            loadIncludeList loaded loader mode pathLocs
      in
        (loaded, {edges = (N.INCLUDE, node, Loc.LOC loc) :: edges,
                  inits = Assoc.concatWith #2 (i1, i2),
                  requires = Assoc.concatWith #2 (r1, r2),
                  topdecs = Assoc.concatWith #2 (t1, t2)})
      end
    | loadIncludeList loaded loader mode (I.INCSEMICOLON _ :: t) =
      loadIncludeList loaded loader mode t

  fun nodeEofLoc (N.FILE {source, ...}) =
      let
        val eof = {source = Loc.FILE source, pos = Loc.EOF}
      in
        (eof, eof)
      end

  fun checkHashDuplication (decs : L.interface_dec list) node =
      foldl
        (fn (dec as {interfaceName = iname1 as {hash, ...}, ...}, z) =>
            let
              val k = InterfaceName.hashToString hash
            in
              case SEnv.find (z, k) of
                NONE => SEnv.insert (z, k, iname1)
              | SOME iname2 =>
                raiseError (nodeEofLoc node, E.DuplicateHash (iname1, iname2))
            end)
        SEnv.empty
        decs

  fun loadProvideInterface loaded loader mode NONE =
      (loaded, {node = NONE,
                prelude = {toplevelName = NONE, initRequisites = nil},
                interface = NONE,
                baseDir = #baseDir loader})
    | loadProvideInterface loaded loader mode (SOME filePathLoc) =
      case loadRequire loaded loader mode filePathLoc of
        (loaded, {dec = NONE, node = N.FILE {source, ...}, ...}) =>
        raiseError (#2 filePathLoc, E.NotAnInterface (#2 source))
      | (loaded, {dec = SOME (dec, top), node, ...}) =>
        let
          val {initRequisites, locallyRequiredIds, topdecsInclude} = top
          val initRequisites =
              Assoc.collect decInitToInitName initRequisites
          val locallyRequiredIds =
              Assoc.collect decLocToIdLoc locallyRequiredIds
          val topdecsInclude =
              Assoc.listItems topdecsInclude
          val {interfaceName = {source, ...}, requiredIds, ...} = dec
          val requires =
              foldl
                (fn ({id,...},z) => InterfaceID.Set.add (z, id))
                InterfaceID.Set.empty
                requiredIds
          val locallyRequiredIds =
              List.filter
                (fn {id, ...} => not (InterfaceID.Set.member (requires, id)))
                locallyRequiredIds
          val interfaceDecs =
              Assoc.collectPartial
                (fn SMI {dec = SOME (dec, _), ...} => SOME dec | _ => NONE)
                (Assoc.remove (loaded, #2 source))
          val interface : L.loc L.interface =
              {interfaceDecs = interfaceDecs,
               provide = {requiredIds = #requiredIds dec,
                          locallyRequiredIds = locallyRequiredIds,
                          provideTopdecs = #provideTopdecs dec,
                          topdecsInclude = List.concat topdecsInclude}}
          val prelude : N.toplevel_prelude =
              {toplevelName = SOME (#interfaceName dec),
               initRequisites = initRequisites}
        in
          checkHashDuplication (dec :: interfaceDecs) node;
          (loaded, {node = SOME (node, #2 filePathLoc),
                    prelude = prelude,
                    interface = SOME interface,
                    baseDir = DIR (#1 source, Filename.dirname (#2 source))})
        end

  (* The default interface file of X.sml is X.smi.  For files other than
   * the form X.sml or interactive mode, the default interface is empty. *)
  fun defaultInterfaceFilename baseFilename =
      case baseFilename of
        NONE => NONE
      | SOME filename =>
        case Filename.suffix filename of
          SOME "sml" => SOME (Filename.replaceSuffix "smi" filename)
        | _ => NONE

  fun listNodes loaded =
      Assoc.collect
        (fn SML {node, ...} => node
          | SMI {node, ...} => node
          | CYCLE => raise Bug.Bug "listNodes: CYCLE")
        loaded

  fun load {baseFilename, loadPath, loadMode, defaultInterface} absyn =
      let
        val (interface, tops, loc) =
            case absyn of
              A.UNIT unit => unit
            | A.EOF pos =>
              case baseFilename of
                SOME filename => (NONE, nil, (pos, pos))
              | NONE => (NONE, nil, (pos, pos))

        (* "_interface" may appear only in batch compile mode.
         * file path of "_interface" is relative to the sml file. *)
        val interfaceFileLoc =
            case interface of
              NONE =>
              (case defaultInterfaceFilename baseFilename of
                 NONE => NONE
               | SOME smifile =>
                 let
                   val smifile = defaultInterface smifile
                 in
                   if CoreUtils.testExist smifile
                   then SOME (FILE (Loc.USERPATH, smifile), loc)
                   else NONE
                 end)
            | SOME ((path, _), loc) =>
              case baseFilename of
                NONE => raiseError (loc, E.UnexpectedInterfaceDecl path)
              | SOME smlfile =>
                SOME (FILE (Loc.USERPATH,
                            Filename.concatPath
                              (Filename.dirname smlfile,
                               RequirePath.toFilename path)),
                      loc)
        (* the _inteface file path is relative to the sml file *)
        val loader =
            {baseDir =
               case baseFilename of
                 NONE => PWD Loc.USERPATH
               | SOME file => DIR (Loc.USERPATH, Filename.dirname file),
             loadPath = loadPath}
        (* prevent reference to the base filename *)
        val baseFilenameReal = Option.map Filename.realPath baseFilename
        val loaded =
            case baseFilenameReal of
              NONE => Assoc.empty
            | SOME file => Assoc.singleton (file, CYCLE)
        (* load _interface and its requisites *)
        val (loaded, {node = smiNode, prelude, interface, baseDir}) =
            loadProvideInterface loaded loader loadMode interfaceFileLoc
        val loaded =
            case baseFilenameReal of
              NONE => loaded
            | SOME file => Assoc.remove (loaded, file)
        val smiEdge =
            Option.map (fn (node, loc) => (N.PROVIDE, node, Loc.LOC loc))
                       smiNode

        (* In batch compile mode, _use is allowed only if its file
         * path is declared for _use in the interface file.
         * In interactive mode, any _use is allowed except when
         * there is a cycle. *)
        val allowUse =
            case (baseFilename, smiNode) of
              (NONE, _) => ALLOW_ALL
            | (SOME _, NONE) => ALLOW_ONLY Filename.Set.empty
            | (SOME _, SOME (N.FILE {edges, ...}, _)) =>
              ALLOW_ONLY
                (foldl
                   (fn ((N.LOCAL_USE, N.FILE {source=(_, x), ...}, _), z) =>
                       Filename.Set.add (z, x)
                     | (_, z) => z)
                   Filename.Set.empty
                   edges)
        (* _use file path is relative to the interface file, not the sml file *)
        val loader = {baseDir = baseDir, loadPath = loadPath}
        val (loaded, {edges, topdecs}) =
            evalTopList loaded loader allowUse tops

        val source = Option.map (fn x => (Loc.USERPATH, x)) baseFilename
        val dependency =
            {allNodes = listNodes loaded,
             root = {fileType = N.ROOT_SML source,
                     mode = loadMode,
                     edges = consOpt (smiEdge, edges)}}
        val compileUnit = {interface = interface, topdecsSource = topdecs}
      in
        (dependency, prelude, compileUnit)
      end

  fun loadInterfaceFileList loaded loader mode nil =
      (loaded, {edges = nil, requires = Assoc.empty, topdecs = Assoc.empty})
    | loadInterfaceFileList loaded loader mode (source :: sources) =
      let
        val dummyPos = {source = Loc.INTERACTIVE, pos = Loc.EOF}
        val dummyLoc = (dummyPos, dummyPos)
        val (loaded, {node, requires=r1, topdecs=t1, ...}) =
            loadRequire loaded loader mode (FILE source, dummyLoc)
        val (loaded, {edges, requires=r2, topdecs=t2}) =
            loadInterfaceFileList loaded loader mode sources
      in
        (loaded, {edges = (N.INCLUDE, node, Loc.NOLOC) :: edges,
                  requires = Assoc.concatWith #2 (r1, r2),
                  topdecs = Assoc.concatWith #2 (t1, t2)})
      end

  fun loadInterfaceFiles {loadPath, loadMode} sources =
      let
        val loader = {baseDir = PWD Loc.USERPATH, loadPath = loadPath}
        val (loaded, {edges, requires, topdecs}) =
            loadInterfaceFileList Assoc.empty loader loadMode sources
        val dependency =
            {allNodes = listNodes loaded,
             root = {fileType = N.ROOT_INCLUDES,
                     mode = loadMode,
                     edges = edges}}
        val interfaceDecs =
            Assoc.collectPartial
              (fn SMI {dec = SOME (dec, _), ...} => SOME dec | _ => NONE)
              loaded
        fun requiredId ({interfaceId, ...}, _) = {id = interfaceId, loc = ()}
      in
        checkHashDuplication interfaceDecs;
        (dependency,
         {interfaceDecs = interfaceDecs,
          requiredIds = Assoc.collect requiredId requires,
          topdecsInclude = List.concat (Assoc.listItems topdecs)})
      end

  fun revisitEdgeList visited place mode nil = (visited, nil)
    | revisitEdgeList visited place mode ((edgeType, node, loc) :: edges) =
      case (case (mode, edgeType, place) of
              (N.ALL, _, _) => SOME mode
            | (_, N.INCLUDE, _) => SOME mode
            | (_, N.PROVIDE, _) => SOME mode
            | (N.ALL_USERPATH, N.REQUIRE, _) => SOME N.ALL_USERPATH
            | (N.ALL_USERPATH, N.LOCAL_REQUIRE, Loc.STDPATH) => NONE
            | (N.ALL_USERPATH, N.LOCAL_REQUIRE, Loc.USERPATH) =>
              SOME N.ALL_USERPATH
            | (N.ALL_USERPATH, N.LOCAL_USE, Loc.STDPATH) => NONE
            | (N.ALL_USERPATH, N.LOCAL_USE, Loc.USERPATH) => SOME N.ALL_USERPATH
            | (N.ALL_USERPATH, N.USE, _) => SOME N.ALL_USERPATH
            | (N.NOLOCAL, N.REQUIRE, _) => SOME N.NOLOCAL
            | (N.NOLOCAL, N.LOCAL_REQUIRE, _) => NONE
            | (N.NOLOCAL, N.LOCAL_USE, _) => NONE
            | (N.NOLOCAL, N.USE, _) => SOME N.NOLOCAL
            | (N.COMPILE, N.REQUIRE, _) => SOME N.NOLOCAL
            | (N.COMPILE, N.LOCAL_REQUIRE, _) => SOME N.NOLOCAL
            | (N.COMPILE, N.LOCAL_USE, _) => SOME N.NOLOCAL
            | (N.COMPILE, N.USE, _) => SOME N.NOLOCAL
            | (N.LINK, N.REQUIRE, _) => SOME N.LINK
            | (N.LINK, N.LOCAL_REQUIRE, _) => SOME N.LINK
            | (N.LINK, N.LOCAL_USE, _) => NONE
            | (N.LINK, N.USE, _) => NONE
            | (N.COMPILE_AND_LINK, N.REQUIRE, _) => SOME N.LINK
            | (N.COMPILE_AND_LINK, N.LOCAL_REQUIRE, _) => SOME N.LINK
            | (N.COMPILE_AND_LINK, N.LOCAL_USE, _) => SOME N.NOLOCAL
            | (N.COMPILE_AND_LINK, N.USE, _) => SOME N.NOLOCAL) of
        NONE => revisitEdgeList visited place mode edges
      | SOME next =>
        let
          val (visited, node) = revisitNode visited next node
          val (visited, edges) = revisitEdgeList visited place mode edges
        in
          (visited, (edgeType, node, loc) :: edges)
        end

  and revisitNode visited mode (N.FILE (node as {source, edges, ...})) =
      case Assoc.find (visited, #2 source) of
        SOME result => (visited, result)
      | NONE =>
        let
          val (visited, edges) = revisitEdgeList visited (#1 source) mode edges
          val node = N.FILE (node # {edges = edges})
        in
          (Assoc.append (visited, #2 source, node), node)
        end

  fun revisit (root as {edges, mode, fileType} : N.file_dependency_root) =
      let
        val place =
            case fileType of
              N.ROOT_SML (SOME (place, _)) => place
            | N.ROOT_SML NONE => Loc.USERPATH
            | N.ROOT_INCLUDES => Loc.USERPATH
        val (visited, edges) = revisitEdgeList Assoc.empty place mode edges
      in
        {allNodes = Assoc.listItems visited,
         root = root # {edges = edges}}
      end

end
