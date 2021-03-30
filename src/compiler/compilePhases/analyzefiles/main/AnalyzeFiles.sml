(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure AnalyzeFiles =
struct
local
  structure IM = InfoMaps
  open AnalyzerTy
  open DBSchema
in
  fun compileSML {llvmOptions, topOptions, topContext, ...} (source as (p,filename)) =
    let
      val fileId = InfoMaps.findSourceMap source
                   handle x => (print "c1\n";raise x)
      val fileInfo = Dynamic.format fileId

      val _ = Bug.printMessage
                ("Analyzing sml file " 
                 ^ Filename.toString filename
                 ^ ":" ^ fileInfo ^ "\n")

      val io = Filename.TextIO.openIn filename
      val context = topContext ()
      val topOptions = topOptions # {baseFilename = SOME filename}
      val input =
          Parser.setup
            {source = Loc.FILE source,
             read = fn (_, n) => TextIO.inputN (io, n),
             initialLineno = 1}
      val _ = IM.initRefMap ()
      val _ = IM.initDefMap ()
      val _ = Analyzers.pushSourceFileId (#fileId fileId)
      val _ = Top.compile llvmOptions topOptions context input handle e => raise e
      val _ = Analyzers.popSourceFileId ()
      val _ = TextIO.closeIn io
      val _ = IM.addRefTable()
      val _ = IM.addDefTable()
    in
      ()
    end
      
  fun analyzeFiles (options as {topOptions,...}) dbparam (place, file) =
    let
      val _ = Bug.printMessage ("Initializing the compiler database with " ^ dbparam ^ "...\n")
      val _ = AnalyzerDB.initDB dbparam
      val _ = Bug.printMessage "The compiler database initialization completed.\n"
      val _ = Bug.printMessage "Registering all the files to the database ..."
      val _ = SetupFiles.setUp options (* topOptions *) (place, file)
      val _ = Bug.printMessage "All the files have registered.\n"
      val sourceMap = InfoMaps.currentSourceMap ()
      fun isSml (_,{fileType,...}) =  fileTypeSMLSource = fileType
      val _ = Control.doNameAnalysis := true
      val sourceList = map #1 (List.filter isSml (SourceMap.listItemsi sourceMap))
      val _ = IM.initUPRefMap ()
      val _ = map (compileSML options) sourceList
      val _ = IM.addUPRefTable()
      val _ = AnalyzerDB.closeDB ()
      val _ = Bug.printMessage "Source file analysis completed.\n"
    in
      ()
    end
    handle e => (AnalyzerDB.closeDB (); raise e)
end
end
