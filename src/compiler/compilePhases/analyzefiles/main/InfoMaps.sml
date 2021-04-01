(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure InfoMaps =
struct
local
  structure I = InterfaceName
  structure F = Filename
  structure L = Loc
  structure U = AnalyzerUtils
  structure DB = AnalyzerDB
  open AnalyzerTy
  open DBSchema
  val processedFiles  = ref FileID.Set.empty : FileID.Set.set ref
  val sourceMap = ref SourceMap.empty : sourceMap ref
  val fileMapMap = ref FileIDMap.empty : fileMap ref
  val fileDependMap = ref FileIDIntMap.empty : fileDependMap ref
  val defMap = ref FileIDIntStringMap.empty : defMap ref
  val refMap = ref FileIDIntMap.empty : refMap ref
  val UPRefMap = ref FileIDFileIDMap.empty : UPRefMap ref
in
  exception SourceMap
  fun printSource (p,f) = 
      (
       print "(";
       print (Dynamic.tagOf p);
       print ",";
       print (Filename.toString f);
       print ")"
      )
  fun initMaps () = 
      (
       processedFiles := FileID.Set.empty;
       sourceMap := SourceMap.empty;
       fileMapMap := FileIDMap.empty;
       fileDependMap := FileIDIntMap.empty
      )
  fun insertProcessedFiles {fileId,...} = 
      processedFiles := FileID.Set.add(!processedFiles, fileId)
  fun memberProcessedFiles {fileId,...} = 
      FileID.Set.member(!processedFiles, fileId)
  fun insertSourceMap (sourceKey, sourceInfo : sourceInfo) =
      sourceMap := SourceMap.insert(!sourceMap, sourceKey, sourceInfo)
  fun findSourceMap source = 
      if U.onStdpath source then raise U.OnStdPath
      else
        case SourceMap.find (!sourceMap, source) of 
          SOME idKey => idKey
        | NONE => (printSource source; print "\n"; raise SourceMap)
  fun checkSourceMap source = SourceMap.find (!sourceMap, source)
  fun currentSourceMap () = !sourceMap
  fun addSourceTable () = 
      let
        val sourceTable = 
             SourceMap.foldri
             (fn ((p,f), sourceInfo:sourceInfo, sourceTable) =>
                 (sourceTupleTemplate
                  # {{filePlace = Dynamic.tagOf p, 
                      fileName = Filename.toString f}}
                  # {sourceInfo})
             :: sourceTable)
             nil
             (!sourceMap)

      in
        if null sourceTable then ()
        else DB.insert {sourceTable = sourceTable}
      end

  fun insertFileMapMap (id, interfaceInfo) = 
      fileMapMap :=FileIDMap.insert(!fileMapMap, id, interfaceInfo)
  fun addFileMapTable () =
      let
        val fileMapTable = 
             FileIDMap.foldri
             (fn (key:fileIDKey, fileInfo:fileMapInfo, fileTable) =>
                 (fileMapTupleTemplate
                  # {key}
                  # {fileInfo})
             :: fileTable)
             nil
             (!fileMapMap)
      in
        if null fileMapTable then () else 
        DB.insert {fileMapTable = fileMapTable}
      end

  fun insertFileDependMap (id, interfaceInfo) = 
      fileDependMap := FileIDIntMap.insert(!fileDependMap, id, interfaceInfo)
  fun addFileDependTable () =
      let
        val fileDependTable = 
             FileIDIntMap.foldri
             (fn (key:fileIDIntKey, 
                  fileDependInfo:fileDependInfo, fileDependTable) =>
                 (fileDependTupleTemplate
                  # {key}
                  # {fileDependInfo})
             :: fileDependTable)
             nil
             (!fileDependMap)
      in
        if null fileDependTable then () else 
        DB.insert {fileDependTable = fileDependTable}
      end

  type key = {fileId:int, startPos:int}
  fun initDefMap () =
      defMap := FileIDIntStringMap.empty
  fun insertDefMap (defInfo as {category, 
                                defSymbolFileId, 
                                defSymbolStartPos,...}) =
      let
        val key  = {fileId = defSymbolFileId,
                    startPos = defSymbolStartPos,
                    category = category}
      in
        defMap := FileIDIntStringMap.insert(!defMap, key, defInfo)
      end
  fun addDefTable () =
      let
        val defTable =  FileIDIntStringMap.listItems (!defMap)
      in
        if null defTable then () else 
        DB.insert {defTable = defTable}
      end
  fun initRefMap () =
      refMap := FileIDIntMap.empty
  fun insertRefMap (key, refInfo) =
      refMap := FileIDIntMap.insert(!refMap, key, refInfo)
  fun addRefTable () =
      let
        val refTable = FileIDIntMap.listItems (!refMap)
      in
        if null refTable then () else 
        DB.insert {refTable = refTable}
      end
  fun initUPRefMap () =
      UPRefMap := FileIDFileIDMap.empty
  fun insertUPRefMap (key, UPRefInfo) =
      UPRefMap := FileIDFileIDMap.insert(!UPRefMap, key, UPRefInfo)
  fun addUPRefTable () =
      let
        val UPRefTable = FileIDFileIDMap.listItems (!UPRefMap)
      in
        if null UPRefTable then () else 
        DB.insert {UPRefTable = UPRefTable}
      end
(*
  fun initProvideMap () =
      provideMap := FileIDIntMap.empty
  fun insertProvideMap (key, provideInfo) =
      provideMap := FileIDIntMap.insert(!provideMap, key, provideInfo)
  fun addProvideTable () =
      let
        val provideTable = FileIDIntMap.listItems (!provideMap)
      in
        if null provideTable then () else 
        DB.insert {provideTable = provideTable}
      end
*)      
end
end
