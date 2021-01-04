(*
val r = BasicData.findParents (13914, 625, 636, "analyzeIdRef")
val _ = Dynamic.pp r
val nameEvalSmiId = 
    BasicData.findFileByFileName "src/compiler/compilePhases/nameevaluation/main/NameEval.smi"
val _ = Dynamic.pp nameEvalSmiId
val nameEvalSmlId = 
    BasicData.findFileByFileName "src/compiler/compilePhases/nameevaluation/main/NameEval.sml"
val _ = Dynamic.pp nameEvalSmlId
val nameEvalSmiName = 
    BasicData.findFileByFileId (#fileId nameEvalSmiId)
val _ = Dynamic.pp nameEvalSmiName
val nameEvalSmlName = 
    BasicData.findFileByFileId (#fileId nameEvalSmlId)

val _ = Dynamic.pp nameEvalSmlName
val defFileLists = IEnv.listKeys BasicData.defIMap
val _ = Dynamic.pp defFileLists
val refFileLists = IEnv.listKeys BasicData.defIMap
val _ = Dynamic.pp refFileLists

val AnalyzerslSmiId = 
    BasicData.findFileByFileName "src/compiler/compilePhases/analyzefiles/main/Analyzers.smi"
val defsAnalyzersSmi = BasicData.findDefsByFileId (#fileId AnalyzerslSmiId)
val refsAnalyzersSmi = BasicData.findRefsByFileId (#fileId AnalyzerslSmiId)
val refFileRefSymDefSyms =
    map (fn ((p,s), iis) => 
            ((p, s),
               map (fn (f,i1,i2, s) => 
                       (BasicData.fileIdToFileName f, f, i1, i2, s))
               (IntIntIntStringSet.listItems iis)))
        (IntStringMap.listItemsi defsAnalyzersSmi)
val _ = print "src/compiler/compilePhases/analyzefiles/main/Analyzers.smi\n"
val _ = print ("fileId:" ^ (Int.toString (#fileId AnalyzerslSmiId)) ^ "\n")
val _ = print "******************* findDefs ***********************\n"
val _ = Dynamic.pp refFileRefSymDefSyms
val refFileRefSymDefSyms =
    map (fn ((p,s), iis) => 
            ((p, s),
               map (fn (f,i1,i2, s) => 
                       (BasicData.fileIdToFileName f, f, i1, i2, s))
               (IntIntIntStringSet.listItems iis)))
        (IntStringMap.listItemsi refsAnalyzersSmi)
val _ = print "******************* findRefs ***********************\n"
val _ = Dynamic.pp refFileRefSymDefSyms
val refs = BasicData.refsByfileNameSymbol
           ("src/compiler/compilePhases/analyzefiles/main/InfoMaps.smi", 
            "insertDefMap")
val _ = Dynamic.pp refs
*)

(*
val refFileRefSymDefSyms =
    map (fn ((p,s), iis) => 
            ((p, s),
               map (fn (f,i,s) => 
                       (BasicData.fileIdToFileName f, i, s))
               (IntIntStringSet.listItems iis)))
        (IntStringMap.listItemsi defsInNameEvalSmi)
val _ = Dynamic.pp refFileRefSymDefSyms

val _ = Dynamic.pp 
          (map (fn (x, iis) => (x, IntIntStringSet.listItems iis))
          (IntStringMap.listItemsi refsInNameEvalSmi))
val _ = Dynamic.pp (IntStringMap.listItemsi defsInNameEvalSml)
val _ = Dynamic.pp (IntStringMap.listItemsi refsInNameEvalSml)
*)
