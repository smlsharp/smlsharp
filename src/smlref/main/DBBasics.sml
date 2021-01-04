structure DBBasics =
struct

  structure DB = DBSchema
  structure C = Config
  exception InvalidFileId of int
  exception InvalidFilePath of string

  fun fileNameToFileId string = 
      let
        val r = 
           (_sql db : (DB.dbSchema,'_) SQL.db =>
            select distinct
              #s.fileId as fileId
            from 
              #db.sourceTable as s
            where
              #s.fileName = string
           ) (Config.getConn ())
        val tuples = SQL.fetchAll r
      in
        case tuples of
          [{fileId}] => fileId
        | _ => raise InvalidFilePath string
      end
  fun fileIdToFileName id = 
      let
        val r = 
           (_sql db : (DB.dbSchema,'_) SQL.db =>
            select distinct
              #s.fileName as fileName
            from 
              #db.sourceTable as s
            where
              #s.fileId = id
           ) (Config.getConn ())
        val tuples = SQL.fetchAll r
      in
        case tuples of
          [{fileName}] => fileName
        | _ => raise InvalidFileId id
      end

  fun findSymInFile {fileName, symbol} =
      let
        val fileId = fileNameToFileId fileName
        val r = 
           (_sql db : (DB.dbSchema,'_) SQL.db =>
            select 
               #d.kind as kind,
               #d.category as category,
               #d.sourceFileId as sourceFileId,
               #d.defSymbol as symbol,
               #d.defSymbolFileId as fileId,
               #d.defSymbolStartPos as startPos,
               #d.defSymbolEndPos as endPos
            from 
              #db.defTable as d
            where
             (#d.defSymbolFileId = fileId and
              #d.defSymbol = symbol)
            order by #.startPos desc
           )
	     (Config.getConn ())
        val tuples = SQL.fetchAll r
      in
        map (fn (x as {sourceFileId, ...}) =>
                (fileIdToFileName sourceFileId,
                 x))
            tuples
      end

  fun findParents {fileId, startPos, endPos, symbol} =
      let
        val r = 
           (_sql db : (DB.dbSchema,'_) SQL.db =>
            select 
               #d.category as category,
               #d.defRangeEndPos as defRangeEndPos,
               #d.defRangeFileId as defRangeFileId,
               #d.defRangeStartPos as defRangeStartPos,
               #d.defSymbol as defSymbol,
               #d.defSymbolFileId as defSymbolFileId,
               #d.defSymbolEndPos as defSymbolEndPos,
               #d.defSymbolStartPos as defSymbolStartPos,
               #d.definedSymbol as definedSymbol,
               #d.kind as kind
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
end
