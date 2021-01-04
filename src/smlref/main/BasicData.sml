structure BasicData =
struct
  structure C = Config
  exception InvalidFileId of int
  exception InvalidFilePath of string
  type fileInfo = 
       {
        fileType:string, 
        fileName:string,
        fileId:int,
        filePlace:string
       }
  type defInfo = 
       {
        kind : string,
        sourceFileId : int,
        category : string,
        defSymbol : string,
        defSymbolFileId : int,
        defSymbolStartPos : int,
        defSymbolEndPos : int,
        defRangeFileId : int,
        defRangeStartPos : int,
        defRangeEndPos : int,
        definedSymbol : string
       }
  fun fileIdFileNameMaps () = 
      let
        val r = 
           (_sql db :
            ({sourceTable:{fileType:string, 
                           fileName:string,
                           fileId:int,
                           filePlace:string} list,...},'_) SQL.db =>
            select distinct
              #s.fileName as fileName,
              #s.fileType as fileType,
              #s.fileId as fileId,
              #s.filePlace as filePlace
            from 
              #db.sourceTable as s
            where
              #s.fileType <> "OBJECT"
           order by #.fileName 
           ) (Config.getConn ())
        fun insert (fileIdMap, fileNameMap) =
            case SQL.fetch r of 
              NONE => (fileIdMap, fileNameMap)
            | SOME (file as {fileName, fileId, ...}) =>
              insert
              (IEnv.insert (fileIdMap, fileId, file),
               SEnv.insert (fileNameMap, fileName, file))
      in
        insert (IEnv.empty, SEnv.empty)
      end

  local
    val (fileIdMap, fileNameMap) = fileIdFileNameMaps()
  in
  fun findFileByFileId id =
      case IEnv.find (fileIdMap, id) of
        NONE => 
        (print ("No file with the file id:" ^ Int.toString id ^ "\n");
         raise InvalidFileId id)
      | SOME fileInfo => fileInfo
  fun findFileByFileName string =
      case SEnv.find (fileNameMap, string) of
        NONE => 
        (print ("No file with the file ptha:" ^ string ^ "\n");
         raise InvalidFilePath string)
      | SOME fileInfo => fileInfo
  fun fileNameToFileId path = #fileId (findFileByFileName path)
  fun fileIdToFileName id = (#fileName (findFileByFileId id))
                            handle _ => "unknownFileName"
  end

  fun fileDefMap () =
      let
        val r = 
           (_sql db :
            ({defTable:
              {
               kind : string,
               sourceFileId : int,
               category : string,
               defSymbol : string,
               defSymbolFileId : int,
               defSymbolStartPos : int,
               defSymbolEndPos : int,
               defRangeFileId : int,
               defRangeStartPos : int,
               defRangeEndPos : int,
               definedSymbol : string,
               internalId : int,
               tfunKind : string
              } list,...},'_) SQL.db =>
            select 
               #d.kind as kind,
               #d.sourceFileId as sourceFileId,
               #d.category as category,
               #d.defSymbol as defSymbol,
               #d.defSymbolFileId as defSymbolFileId,
               #d.defSymbolStartPos as defSymbolStartPos,
               #d.defSymbolEndPos as defSymbolEndPos,
               #d.defRangeFileId as defRangeFileId,
               #d.defRangeStartPos as defRangeStartPos,
               #d.defRangeEndPos as defRangeEndPos,
               #d.definedSymbol as definedSymbol
            from 
              #db.defTable as d
           )
	     (Config.getConn ())
        fun insert fileIdMap =
            case SQL.fetch r of 
              NONE => fileIdMap
            | SOME (tuple as {defSymbolFileId,
                              defSymbolStartPos, 
                              defSymbol,...}) => 
              let
                val fileIdMap = 
                    case IEnv.find (fileIdMap, defSymbolFileId) of
                      NONE => 
                      IEnv.insert
                        (fileIdMap,
                         defSymbolFileId,
                         IntStringMap.singleton
                           ((defSymbolStartPos,defSymbol),
                            tuple)
                        )
                    | SOME ismap => 
                      IEnv.insert
                        (fileIdMap,
                         defSymbolFileId,
                         IntStringMap.insert
                           (ismap,
                            (defSymbolStartPos,defSymbol),
                            tuple)
                        )
                      
              in
                insert fileIdMap
              end
      in
        insert IEnv.empty
      end

  val fileDefMap = fileDefMap()

  fun findParents (fileId, startPos, endPos, symbol) =
      let
        val r = 
           (_sql db :
            ({defTable:
              {
               kind : string,
               sourceFileId : int,
               category : string,
               defSymbol : string,
               defSymbolFileId : int,
               defSymbolStartPos : int,
               defSymbolEndPos : int,
               defRangeFileId : int,
               defRangeStartPos : int,
               defRangeEndPos : int,
               definedSymbol : string,
               internalId : int,
               tfunKind : string
              } list,...},'_) SQL.db =>
            select 
               #d.kind as kind,
               #d.category as category,
               #d.defSymbol as defSymbol,
               #d.defSymbolStartPos as defSymbolStartPos,
               #d.defSymbolEndPos as defSymbolEndPos
            from 
              #db.defTable as d
            where
             (((#d.defRangeFileId = fileId and
                #d.defRangeStartPos <= startPos) and
                #d.defRangeEndPos > endPos) and
                #d.defSymbol <> symbol)
            order by #.defSymbolStartPos desc
           )
	     (Config.getConn ())
      in
        SQL.fetchAll r
      end

(*
  type refTuple = 
    {
     category : string,
     kind : string,
     sourceFileId : int,
     refSymbol : string,
     refSymbolFileId : int,
     refSymbolStartPos : int,
     refSymbolEndPos : int,
     defRangeFileId : int,
     defRangeStartPos : int,
     defRangeEndPos : int,
     internalId : int,
     tfunKind : string,
     defSymbol : string,
     defSymbolFileId : int,
     defSymbolStartPos : int,
     defSymbolEndPos : int,
     definedSymbol : string
    }
*)
  fun  fileSymDefRef () = 
    let
      val r = 
          (_sql db :
           ({refTable:DBSchema.refTuple list,...},
            '_) SQL.db =>
             select
               #d.defSymbolFileId as defSymbolFileId,
               #d.defSymbol as defSymbol,
               #d.defSymbolStartPos as defSymbolStartPos,
               #d.defSymbolEndPos as defSymbolEndPos,
               #d.refSymbolFileId as refSymbolFileId,
               #d.refSymbolStartPos as refSymbolStartPos,
               #d.refSymbolEndPos as refSymbolEndPos,
               #d.refSymbol as refSymbol,
               #d.definedSymbol as definedSymbol
             from
               #db.refTable as d
          ) (Config.getConn ())
      fun insert (defIMap, refIMap) =
          case SQL.fetch r of
            NONE => (defIMap, refIMap)
          | SOME 
            (t as {defSymbol,
                   defSymbolFileId,
                   definedSymbol,
                   defSymbolStartPos,
                   defSymbolEndPos,
                   refSymbol,
                   refSymbolFileId,
                   refSymbolStartPos,
                   refSymbolEndPos
            })
            =>
            let
              val defKey = (defSymbolFileId,
                            defSymbolStartPos,
                            defSymbolEndPos,
                            defSymbol)
              val defSymKey = (defSymbolStartPos,
                               defSymbol)
              val refKey = (refSymbolFileId,
                            refSymbolStartPos,
                            refSymbolEndPos,
                            refSymbol)
              val refSymKey = (refSymbolStartPos,
                               refSymbol)
              val defIMap = 
                  IEnv.insertWithi2
                    (fn (i, symMap1, symMap2) => 
                        IntStringMap.unionWith
                          IntIntIntStringSet.union
                          (symMap1,symMap2))
                    (defIMap,
                     defSymbolFileId,
                     IntStringMap.singleton(defSymKey, 
                                            IntIntIntStringSet.singleton(refKey)))
              val refIMap = 
                  IEnv.insertWithi2
                    (fn (i, symMap1, symMap2) => 
                        IntStringMap.unionWith
                          IntIntIntStringSet.union
                          (symMap1,symMap2))
                    (refIMap,
                     refSymbolFileId,
                     IntStringMap.singleton(refSymKey, 
                                            IntIntIntStringSet.singleton(defKey)))
            in
              insert (defIMap, refIMap)
            end
    in
      insert (IEnv.empty, IEnv.empty)
    end

  val (defIMap, refIMap) = fileSymDefRef()
  fun findRefsByFileId id =
      case IEnv.find (defIMap, id) of
        NONE => 
        (print "findRefsByFileId\n";
         print (Int.toString id ^ "\n");
        IntStringMap.empty)
      | SOME defs => defs
  fun findDefsByFileId id = 
      case IEnv.find (refIMap, id) of
        NONE => 
        (print "findRefsByFileId\n";
         print (Int.toString id ^ "\n");
         IntStringMap.empty)
      | SOME defs => defs
  fun findRefsByFileName name = findRefsByFileId (fileNameToFileId name)
  fun findDefsByFileName name = findDefsByFileId (fileNameToFileId name)
      
  fun  refsByfileNameSymbol (fileName, defSymbol) = 
    let
      val fileId = fileNameToFileId fileName
      val r = 
          (_sql db :
           ({refTable:DBSchema.refTuple list,...},
            '_) SQL.db =>
             select
               #d.defSymbolStartPos as defStartPos,
               #d.refSymbolFileId as fileId,
               #d.refSymbolStartPos as startPos,
               #d.refSymbol as symbol
             from
               #db.refTable as d
             where
              (#d.defSymbolFileId = fileId and
               #d.defSymbol = defSymbol)
          ) (Config.getConn ())
      fun insert refIMap =
          case SQL.fetch r of
            NONE => refIMap
          | SOME
            (t as {defStartPos,
                   fileId,
                   startPos,
                   symbol})
            =>
            let
              val refFileName = fileIdToFileName fileId
              val refIMap =
                  IEnv.insertWithi2
                  (fn (_, L1, L2) => L1 @ L2)
                  (refIMap,
                   defStartPos, 
                   [(refFileName, startPos, symbol)]
                   )
            in
              insert refIMap
            end
    in
      insert IEnv.empty
    end

  fun defRefRel () = 
    let
      val r = 
          (_sql db :
           ({refTable:{kind:string, 
                       defSymbolFileId:int,
                       refSymbolFileId:int,...} list,...},
            '_) SQL.db =>
             select distinct
               #d.defSymbolFileId as defFileId,
               #d.refSymbolFileId as refFileId
             from
               #db.refTable as d
            order by #.defFileId, #.refFileId
          ) (Config.getConn ())
    in
      SQL.fetchAll r
    end
  fun UPDefRefRel () = 
    let
      val r = 
          (_sql db :
           ({UPRefTable:{defSymbolFileId:int,
                         refSymbolFileId:int,...} list,...},
            '_) SQL.db =>
             select distinct
               #d.defSymbolFileId as defFileId,
               #d.refSymbolFileId as refFileId
             from
               #db.UPRefTable as d
            order by #.defFileId, #.refFileId
          ) (Config.getConn ())
    in
      SQL.fetchAll r
    end
end
(*
  fun fileDependList () =
      let
        val defRefRel = defRefRel()
        val UPDefRefRel = UPDefRefRel()
        val dependFiles = 
            foldr 
              (fn ({defFile, refFile}, dependFiles) =>
                  if isBuiltin defFile orelse isSelf (defFile, refFile) then dependFiles
                  else 
                    case SEnv.find (dependFiles, refFile) of
                      SOME dependSet => SEnv.insert(dependFiles,
                                                    refFile,
                                                    SSet.add (dependSet, defFile))
                    | NONE => SEnv.insert(dependFiles,
                                          refFile,
                                          SSet.singleton defFile)
              )
              SEnv.empty
              (defRefRel @ UPDefRefRel)
        fun spliceSmi (baseFile, arg) =
            SSet.foldl
            (fn (file, dependSet) =>
                if isSmi file then RSSet.add (dependSet, DIRECT (mkRelative (file, baseFile)))
                else if isSml file 
                then
                  let
                    val smlSet = 
                        case SEnv.find (dependFiles, file) of
                          SOME fileSet => 
                          SSet.foldl
                            (fn (file, rsset) => 
				if isSelf (baseFile, file) then rsset
				else RSSet.add (rsset, LOCAL (mkRelative (file, baseFile))))
                            RSSet.empty
                            fileSet
(*
                            (SSet.filter isSmi fileSet)
*)
                        | NONE => RSSet.empty
                  in
                    RSSet.union (dependSet, smlSet)
                  end
                else dependSet)
            RSSet.empty
            arg
        val dependMap = SEnv.mapi spliceSmi dependFiles
        val dependList =
              SEnv.map (fn sset => RSSet.listItems sset)
              (SEnv.filteri (fn (file, iterm) => isSmi file) dependMap)
      in
        dependList
      end
*)
(*

  fun dependFiles (fileName:string) =
      let
        val r =
            _sql db :
            ({fileDependTable:{fileId:int, 
                               dependFileId:int, 
                               dependType:string,...} list,
              sourceTable:{fileId:int, fileName:string,...} list,
              ...}, '_) SQL.db =>
          select
            #sd.fileName as name,
            #d.dependType as kind
         from
            #db.fileDependTable as d,
            #db.sourceTable as ss,
            #db.sourceTable as sd
         where 
          ((#ss.fileName = fileName
            and #ss.fileId = #d.fileId)
            and #sd.fileId = #d.dependFileId)
        order by #.name

  fun findInterface (defSymbol:string, pos:int, fileName:string) =
      let
        val r =
            _sql db :
            ({provideTable:{kind:string, 
                            defSymbol:string,
                            refSymbol:string,
                            refSymbolFileId:int,...} list,
              sourceTable:{fileName:string, fileId:int,...} list,...},
             '_) SQL.db =>
            select
              #is.fineName as interfaceFale,
              #is.defSymbolStartPos as interfacePos
            from
              #db.provideTable as p,
              #db.sourceTable as ss,
              #db.sourceTable as is,
            where
            ((((
                #ss.fileName = op SQL.Op.toSQL fileName
            and #p.refSymbol = op SQL.Op.toSQL defSymbol)
            and #p.refSymbolStartPos = op SQL.Op.toSQL pos)
            and #p.refSymbolFileId = #ss.fileId)
            and #p.defSymbolFileId = #is.fileId)

(*
val requireRel = 
    Dynamic.nest (SQL.fetchAll (fileDepend conn))
    : {name:string, L:{dependOn:string, kind:string} list} list
*)
fun findDef (refSym:string) =
  _sql db :
       ({refTable:{kind:string, 
                   defSymbol:string,
                   refSymbol:string,
                   refSymbolFileId:int,...} list,
         sourceTable:{fileName:string, fileId:int,...} list,...},
        '_) SQL.db =>
    select distinct
       #ds.fileName as interfaceFile,
       #r.defSymbol as interfaceSymbol,
       #r.defSymbolStartPos as interfaceSymbolPos,
       #ps.fileName as defFile,
       #p.defSymbol as defSymbol,
       #p.defSymbolStartPos as defSymbolPos,
       #r.kind as kind
    from
       #db.refTable as r,
       #db.provideTable as p,
       #db.sourceTable as ds,
       #db.sourceTable as ps
    where
      ((((#r.refSymbol = op SQL.Op.toSQL refSym
      and #p.refSymbol = #r.defSymbol)
      and #p.refSymbolStartPos = #r.defSymbolStartPos)
      and #r.defSymbolFileId = #ds.fileId)
      and #p.defSymbolFileId = #ps.fileId)

fun findRef (defSym:string) =
  _sql db :
       ({refTable:{kind:string, 
                   defSymbol:string,
                   refSymbol:string,
                   refSymbolFileId:int,...} list,
         provideTable:{kind:string, 
                   defSymbol:string,
                   refSymbol:string,
                   refSymbolFileId:int,...} list,
         sourceTable:{fileName:string, fileId:int,...} list,...},
        '_) SQL.db =>
    select distinct
       #defs.fileName as interfaceFile,
       #def.refSymbol as interfaceSymbol,
       #def.refSymbolStartPos as interfaceSymbolPos,
       #refs.fileName as sourceFile,
       #refT.refSymbol as sourceRefSymbol,
       #refT.refSymbolStartPos as sourceRefSymbolPos,
       #refT.kind as kind
    from
       #db.provideTable as def,
       #db.refTable as refT,
       #db.sourceTable as defs,
       #db.sourceTable as refs
    where
      ((((#def.refSymbol = op SQL.Op.toSQL defSym
      and #def.refSymbol = #refT.defSymbol)
      and #def.refSymbolStartPos = #refT.defSymbolStartPos)
      and #def.refSymbolFileId = #defs.fileId)
      and #refT.refSymbolFileId = #refs.fileId)

(*
val defRef = defRef conn

val defRefRel =
  Dynamic.nest defRef
  : {file:string, L:{toFile:string, kind:string, symbol:string} list} list

val refDef =
 _sql db : ({provideTable:{defSymbolStartPos:int,kind:string,
                           refSymbolFileId:int,...} list,
             refTable:{defSymbolFileId:int, defSymbolStartPos:int,
                       refSymbolFileId:int, refSymbolStartPos:int, 
                       defSymbol:string, refSymbol:string, ...} list,
             sourceTable:{fileName:string, fileId:int,...} list, 
             ...},
            '_) SQL.db
 =>
 select distinct
    #ds.fileName as interfaceFile,
    #rs.fileName as refFile,
    #ps.fileName as sourceFile,
    #r.refSymbol as refName,
    #r.refSymbolStartPos as refPos,
    #r.defSymbolStartPos as interFacePos,
    #p.defSymbolStartPos as sourcePos,
    #p.kind as kind
 from
    #db.provideTable as p,
    #db.refTable as r,
    #db.sourceTable as ds,
    #db.sourceTable as rs,
    #db.sourceTable as ps
 where
   (((((#r.refSymbolFileId = #rs.fileId
    and #r.defSymbolFileId = #ds.fileId)
    and #r.defSymbolFileId = #p.refSymbolFileId)
    and #r.defSymbol = #p.refSymbol)
    and #p.defSymbolFileId = #ps.fileId)
    and #rs.fileId <> #ds.fileId)
   order by #.refFile, #.refName

val funDefs  =
 _sql db :
    ({bindTable:{defSymbol:string, defRangeStartPos:int, 
                 defRangeEndPos:int, category:string, ...} list,
      sourceTable:{fileId:int, fileName:string,...} list, ...},
     '_a) SQL.db
   => 
  select
    #b.defSymbol as funName,
    #b.defRangeStartPos as from,
    #b.defRangeEndPos as to,
    #s.fileName as file
 from
   #db.bindTable as b,
   #db.sourceTable as s
 where 
   (#b.defSymbolFileId = #s.fileId
    and #b.category = "FUNCTION")
 order by #.file, #.funName

*)
*)
