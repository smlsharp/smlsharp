(**
 * @copyright (c) 2018, Tohoku University.
 * @author Atsushi Ohori
 *)
structure AnalyzeFiles =
struct

  structure I = InterfaceName
  structure MU = MainUtils
  exception RevertFail

(* copied for automatic pretty-printing *)
  type hash = string
  datatype file_place = PLACE_NONE | STDPATH | LOCALPATH
  type source = file_place * string
  type interface_name = {hash: hash, source: source}
  datatype file_type = TYPE_NONE | SML | INCLUDES | INTERFACE of interface_name
  datatype dependType = DEPENDTYPE_NONE | DEPEND | LOCAL
  datatype dependParent = DEPENDPARENT_NONE |SELF | PARENT_SOURCE of source

  fun transFilename filename = Filename.toString filename
  fun revertFilename filename = Filename.fromString filename
  fun transFile_place I.STDPATH  = STDPATH
    | transFile_place I.LOCALPATH = LOCALPATH
  fun revertFile_place STDPATH  = I.STDPATH
    | revertFile_place LOCALPATH = I.LOCALPATH
    | revertFile_place _ = raise RevertFail
  fun transSource (filePlace, fileName) =
      (transFile_place filePlace, transFilename fileName)
  fun revertSource (filePlace, fileName) =
      (revertFile_place filePlace, revertFilename fileName)
  fun transInterface_name {hash, source} =
      {hash = I.hashToString hash, source = transSource source}
  fun transFile_type I.SML = SML
    | transFile_type I.INCLUDES = INCLUDES
    | transFile_type (I.INTERFACE interface_name) = 
      INTERFACE (transInterface_name interface_name)

  fun smiSourceToObjSource options source  =
      transSource (MU.smiSourceToObjSource options (revertSource source))
  fun smiSourceToSmlSource options source =
      Option.map transSource (MU.smiSourceToSmlSource options (revertSource source))

  fun compareFilePlace (PLACE_NONE, PLACE_NONE) = EQUAL
    | compareFilePlace (PLACE_NONE, _) = LESS
    | compareFilePlace (_, PLACE_NONE) = GREATER
    | compareFilePlace (STDPATH, STDPATH) = EQUAL
    | compareFilePlace (STDPATH, LOCALPATH) = LESS
    | compareFilePlace (LOCALPATH, STDPATH) = GREATER
    | compareFilePlace (LOCALPATH, LOCALPATH) = EQUAL
  fun compareSource ((filePlace1, fileName1),(filePlace2, fileName2)) =
      case compareFilePlace (filePlace1, filePlace2) of
        EQUAL => String.compare(fileName1, fileName2)  
      | x => x
  fun compareSourceAndHash ({source = source1, hash = hash1},
                            {source = source2, hash = hash2}) =
      case compareSource (source1,source2) of
        EQUAL => String.compare(hash1, hash2)
      | x => x

  structure SourceOrd =
  struct
    type ord_key = source
    val compare = compareSource
  end
  structure InterfaceNameOrd =
  struct
    type ord_key = {source:source, hash:hash}
    val compare = compareSourceAndHash
  end
  structure SourceMap = BinaryMapFn(SourceOrd)
  structure InterfaceNameMap = BinaryMapFn(InterfaceNameOrd)
  structure SourceSet = BinarySetFn(SourceOrd)

  type dependRel = 
       {
        source: source,
        sourceType: file_type,
        objSource: source,
        smlSourceOpt: source option,
        dependType: dependType,
        dependParent: dependParent,
        dependSource: source
       }

  val templateRel:dependRel =
      {
        source = (PLACE_NONE, ""),
        sourceType = TYPE_NONE,
        objSource = (PLACE_NONE, ""),
        smlSourceOpt = NONE,
        dependType = DEPENDTYPE_NONE,
        dependParent = DEPENDPARENT_NONE,
        dependSource = (PLACE_NONE, "")
      }

  fun dependRel options fileDependencyList = 
      let
        val smiFileSet = ref SourceSet.empty : SourceSet.set ref
        val smlFileSet = ref SourceSet.empty : SourceSet.set ref
        val visitedSource = ref SourceSet.empty : SourceSet.set ref
        fun isVisited source = 
            if SourceSet.member(!visitedSource, source) then true
            else (visitedSource := SourceSet.add(!visitedSource, source);
                  false)
        fun resetVisited () = visitedSource := SourceSet.empty
        fun addSmi source = 
            smiFileSet := SourceSet.add(!smiFileSet, source);
        fun addSml source = 
            smlFileSet := SourceSet.add(!smlFileSet, source);

        fun dependRelDependencyList contextDependType fileDependencyList rel =
            foldr (dependRelDependency contextDependType) rel fileDependencyList

        and dependRelDependency contextDependType (fileDependency, rel:dependRel list) = 
            let
              val (source, fileType, fileDependencyList, dependType) =
                  case fileDependency of
                    I.DEPEND (source, fileType, fileDependencyList) => 
                    (
                     transSource source, 
                     transFile_type fileType, 
                     fileDependencyList, 
                     DEPEND
                    )
                  | I.LOCAL (source, fileType, fileDependencyList) => 
                    (
                     transSource source, 
                     transFile_type fileType, 
                     fileDependencyList, 
                     LOCAL
                    )
            in
              if isVisited source then rel
              else
                let
                  val relItem : dependRel = 
                      templateRel # {source = source,
                                     sourceType = fileType,
                                     dependParent = SELF
                                    }
                  val relItem : dependRel = 
                      case fileType of 
                        INTERFACE interfaceName =>
                        let
                          val objSource = smiSourceToObjSource options source
                          val smlSourceOpt = smiSourceToSmlSource options source
                          val _ = 
                              (case smlSourceOpt of
                                 SOME source => addSml source
                               | NONE => ();
                               addSmi source)
                        in
                          relItem # {
                          objSource = objSource,
                          smlSourceOpt = smlSourceOpt
                          }
                        end
                      | _ => relItem
                  val rel = makeDependRelDependencyList 
                              false 
                              dependType 
                              relItem 
                              fileDependencyList 
                              rel
                in
                  dependRelDependencyList dependType fileDependencyList rel
                end
            end
        and makeDependRelDependencyList
              useContext contextDependType relItem fileDependencyList rel =
            foldr 
              (makeDependRelDependency useContext contextDependType relItem) 
              rel 
              fileDependencyList
        and makeDependRelDependency
              useContext contextDependType sourceRelItem (fileDependency, rel) =
            let
              val (source, fileType, fileDependencyList, dependType) =
                  case fileDependency of
                    I.DEPEND (source, fileType, fileDependencyList) => 
                    (transSource source, transFile_type fileType, fileDependencyList, DEPEND)
                  | I.LOCAL (source, fileType, fileDependencyList) => 
                    (transSource source, transFile_type fileType, fileDependencyList, DEPEND)
              val effectiveDependType = 
                  if useContext then contextDependType else dependType
              val relItem : dependRel =
                  sourceRelItem # {dependSource = source,
                                   dependType = effectiveDependType
                                  }
              val rel = relItem :: rel
              val sourceRelItem  = sourceRelItem # {dependParent = PARENT_SOURCE source}
              val rel = 
                  case fileType of
                    INCLUDES =>
                    makeDependRelDependencyList 
                      true
                      effectiveDependType
                      sourceRelItem 
                      fileDependencyList 
                      rel
                  | _ => rel
            in
              rel
            end
        val dependRep = dependRelDependencyList DEPENDTYPE_NONE fileDependencyList nil
      in
        {dependRep = dependRep, smlFileSet =  !smlFileSet, smiFileSet = !smiFileSet}
      end

  fun checkInterface {topOptions, topContext,...} source = 
      (print "checkInterface: ";
       Dynamic.pp source;
(*
       Top.loadInterfaces topOptions (topContext ()) [(revertSource source)]
*)
       ()
      )
  fun checkSource {topOptions, llvmOptions, topContext,...} source = 
      (print "checkSource: ";
       Dynamic.pp source;
       let
         val (file_place, filename) = revertSource source
         val io = Filename.TextIO.openIn filename
         val context = topContext()
         val topOptions = topOptions # {baseFilename = SOME filename}
         val input =
             Parser.setup
               {mode = Parser.Batch filename,
                read = fn (_, n) => TextIO.inputN (io, n),
                initialLineno = 1}
         val r = Top.compile llvmOptions topOptions context input
         val _ = TextIO.closeIn io
       in
         ()
       end
      )
  fun analyzeFiles 
        (options as {topOptions = topOptions as {loadPath, loadMode, ...},
                     fileMap,...}) 
        source =
      let
        val topOptions = topOptions # {stopAt = Top.ErrorCheck}
        val options = options # {topOptions = topOptions}
        val (dependency as {interfaceNameOpt, depends},_) =
            LoadFile.loadInterfaceFiles
              {loadPath=loadPath, loadMode=loadMode}
              [source]
        val {dependRep, smlFileSet, smiFileSet} = dependRel options depends 
        val _ = map (checkInterface options) (SourceSet.listItems smiFileSet)
        val _ = print "checkInterface completed\n"
        val _ = map (checkSource options) (SourceSet.listItems smlFileSet)
        val _ = print "checkSource completed\n"
        val _ = map Dynamic.pp dependRep
      in
        ()
      end
end
