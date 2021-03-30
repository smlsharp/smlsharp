(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure SetupFiles =
struct
  structure DB = AnalyzerDB
  structure IM = InfoMaps
  structure U = AnalyzerUtils
  structure I = InterfaceName
  structure F = Filename
  structure L = Loc
  open AnalyzerTy
  open DBSchema
  fun printNode node =
      Bug.printMessage
        (Bug.prettyPrint 
           (I.format_file_dependency_node node)
         ^ "\n")
  fun printEdge (edge as (t,n,l)) =
      (Bug.printMessage
         (Bug.prettyPrint 
            (I.format_file_dependency_edge edge)
          ^ "\n");
       Bug.printMessage 
       ("at "
        ^
        (L.locToString l))
      )
  fun printRootNode node =
      Bug.printMessage
        (Bug.prettyPrint 
           (I.format_file_dependency_root node)
         ^ "\n")
  fun printRootType ty =
      Bug.printMessage
        (Bug.prettyPrint 
           (I.format_file_dependency_root_file_type ty)
         ^ "\n")
  fun registerConfig (p, filename) =
      DB.insert {configTable = [{systemName = "smlsharp",
                                 baseDir = UnixUtils.pwd (),
                                 version = SMLSharp_Version.Release,
                                 rootFile = F.toString filename}]}
  fun registerFiles {llvmOptions, 
                     topContext,
                     topOptions as {loadPath, loadMode,...},
                     ...} 
                    source =
      let
        val ({allNodes,...}, root) =
            LoadFile.loadInterfaceFiles
              {loadPath=loadPath, loadMode=loadMode}
              [source]
        fun toSML filename = F.replaceSuffix "sml" filename
        fun toObj filename = F.replaceSuffix "o" filename
        fun nodeToFileId (I.FILE {source,...}) =
            FileID.toInt  (#fileId (IM.findSourceMap source))
	    handle IM.SourceMap 
		   => (print "nodeToFileId\n";
		       raise IM.SourceMap)
                 | x => (print "s2\n";raise x)
        fun regDepend (source, edges) =
	    if U.onStdpath source then ()
	    else
            let
              val {fileId,...} = IM.findSourceMap source
				 handle IM.SourceMap 
					=> (print "regdepend\n";
					    raise IM.SourceMap)
                                      | x => (print "s1\n";raise x)

            in
              app
              (fn (kind, node, loc) => 
                let
                  val key = {fileId = fileId, startPos = U.locToStartPos loc}
                  val fileDependInfo : fileDependInfo = 
                      {dependType = Dynamic.format kind,
                       dependFileId = nodeToFileId node,
                       endPos = U.locToEndPos loc}
(*
                  val dependInfo = {fileId = fileId, dependInfo = fileDependInfo}
                  val _ = Bug.printMessage "regDepend:\n"
                  val _ = Bug.printMessage (Dynamic.format dependInfo)
                  val _ = Bug.printMessage "\n"
*)
                in
                  IM.insertFileDependMap (key, fileDependInfo)
                end)
              (List.filter 
		   (fn (kind, I.FILE {source,...}, loc) => U.onUserpath source)
		   edges)
            end

        fun smlLoad (source as (p, filename)) = 
            let
              fun nonInterfaceNode (_, I.FILE {fileType = I.SML,...},_) = true
                | nonInterfaceNode _ = false
              val io = Filename.TextIO.openIn filename
              val context = topContext ()
              val topOptions = 
                  topOptions # {baseFilename = SOME filename} # {stopAt=Top.SyntaxCheck}
              val input =
                  Parser.setup
                    {source = Loc.FILE source,
                     read = fn (_, n) => TextIO.inputN (io, n),
                     initialLineno = 1}
              val ({root={edges,fileType, mode},...},_) 
                  = Top.compile llvmOptions topOptions context input handle e => raise e
              val _ = TextIO.closeIn io
              val smlEdges = List.filter nonInterfaceNode edges
(*
              val _ = Bug.printMessage "smlRoot fileType:\n"
              val _ = printRootType fileType
              val _ = Bug.printMessage "smlRoot mode:\n"
              val _ = Bug.printMessage (Dynamic.format mode)
              val _ = Bug.printMessage "sml edges:\n"
              val _ = map printEdge smlEdges
*)
              fun regSMLIfNot (t,I.FILE {source as (p,f), fileType,...},l) =
                  case IM.checkSourceMap source of
                    NONE => 
                    let
                      val fileId = FileID.generate()
                      val sourceInfo : sourceInfo =
                          {fileId = fileId, fileType = fileTypeSMLUse}
(*
                      val _ = Bug.printMessage "inserting to sourceMap"
                      val _ = Bug.printMessage "sorceInfo:"
                      val _ = Bug.printMessage (Dynamic.format sourceInfo)
                      val _ = Bug.printMessage "\n sourceFile:"
                      val _ = Bug.printMessage (Dynamic.format 
                                                  {filePlace = Dynamic.tagOf p,
                                                   fileName = Filename.toString f}
                                               )
                      val _ = Bug.printMessage "\n"
*)
                      val _ = IM.insertSourceMap (source, sourceInfo)
                    in
                      ()
                    end
                  | _ => ()
              val _ = app regSMLIfNot smlEdges
              val _ = regDepend (source,smlEdges)
            in
              ()
            end
        fun regFile (I.FILE {source = source as (p,f), fileType,...}) =
	    if U.onStdpath source then ()
	    else
            let
              val fileId = FileID.generate()
              val sourceInfo : sourceInfo =
                  {fileId = fileId, fileType = Dynamic.tagOf fileType}
(*
              val _ = Bug.printMessage "inserting to sourceMap"
              VAL _ = BUG.printMessage "sorceInfo:"
              val _ = Bug.printMessage (Dynamic.format sourceInfo)
              val _ = Bug.printMessage "\n sourceFile:"
              val _ = Bug.printMessage (Dynamic.format 
                                        {filePlace = Dynamic.tagOf p,
                                         fileName = Filename.toString f}
                                       )
              val _ = Bug.printMessage "\n"
*)
              val _ = IM.insertSourceMap (source, sourceInfo)
            in
              case fileType of 
                I.INTERFACE hash => 
                let
                  val smlSource = (p, toSML f)
                  val smlId = FileID.generate()
                  val smlSourceInfo = {fileId = smlId, fileType = fileTypeSMLSource}
                  val _ = IM.insertSourceMap (smlSource, smlSourceInfo)
                  val _ = smlLoad smlSource
                  val objSource = (p, toObj f)
                  val objId = FileID.generate()
                  val objSourceInfo = {fileId = objId, fileType = fileTypeOBJECT}
                  val _ = IM.insertSourceMap (objSource, objSourceInfo)
                  val interfaceInfo : fileMapInfo
                    = {interfaceHash = I.hashToString hash,
                       smlFileId = smlId, 
                       objFileId = objId}
                  val _ = IM.insertFileMapMap ({fileId = fileId}, interfaceInfo)
                in
                  ()
                end
              | _ => ()
            end
        val systemList = 
[
            I.FILE{source = (Loc.USERPATH, 
                             Filename.fromString "src/builtin.smi"),
                   fileType = I.INCLUDES,
                   edges = nil}
(*
            I.FILE{source = (Loc.STDPATH,
                             Filename.fromString "src/prelude.smi"),
                   fileType = I.INCLUDES,
                   edges = nil},
            I.FILE{source = (Loc.STDPATH, 
                             Filename.fromString "/usr/local/lib/smlsharp/builtin.smi"),
                   fileType = I.INCLUDES,
                   edges = nil},
            I.FILE{source = (Loc.STDPATH, 
                             Filename.fromString "/usr/local/lib/smlsharp/prelude.smi"),
                   fileType = I.INCLUDES,
                   edges = nil}
*)
        ]
            
        val allNodes = systemList @ allNodes
        val _ = app regFile allNodes
        val _ = app regDepend
                    (map (fn (I.FILE {source, edges,...}) => (source, edges))
                         allNodes)
      in
        allNodes
      end

  fun setUp options source =
      (registerConfig source;
       registerFiles options source;
       IM.addSourceTable();
       IM.addFileMapTable();
       IM.addFileDependTable())
end
