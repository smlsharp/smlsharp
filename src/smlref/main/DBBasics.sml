structure DBBasics =
struct
(* Terminology:
   sym : symbol occurrance
   def sym : binding occurrance
   ref sym : referencing occurrance
*)

  structure C = Config
  exception InvalidFileId of int
  exception InvalidFilePath of string

  type sym = {fileId:int, startPos:int, endPos:int, symbol:string}

  val tagOf = Dynamic.tagOf
  open DBSchema

  fun fileNameToFileId string = 
      let
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
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
           (_sql db : (dbSchema,'_) SQL.db =>
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

  fun findDefSymInFile {fileName, symbol} =
      let
        val fileId = fileNameToFileId fileName
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
               #d.defSymbolFileId as fileId,
               #d.defSymbol as symbol,
               #d.defSymbolStartPos as startPos,
               #d.defSymbolEndPos as endPos
            from 
              #db.defTable as d
            where
             (#d.defSymbolFileId = fileId and
              #d.defSymbol = symbol)
            order by #.startPos
           )
	     (Config.getConn ())
      in
        SQL.fetchAll r
      end

  (* Return the list of def syms in fileName *)
  fun listDefSymsInFile fileName =
      let
        val fileId = fileNameToFileId fileName
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
               #d.defSymbolFileId as fileId,
               #d.defSymbol as symbol,
               #d.defSymbolStartPos as startPos,
               #d.defSymbolEndPos as endPos
            from 
              #db.defTable as d
            where
              #d.defSymbolFileId = fileId
            order by #.startPos
           )
	     (Config.getConn ())
      in
        SQL.fetchAll r
      end
      
  (* Return the list of def syms referenced in fileName *)
  fun listDefSymsReferencedInFile fileName =
      let
        val fileId = fileNameToFileId fileName
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
               #d.defSymbolFileId as fileId,
               #d.defSymbol as symbol,
               #d.defSymbolStartPos as startPos,
               #d.defSymbolEndPos as endPos
            from 
              #db.refTable as d
            where
              #d.refSymbolFileId = fileId
            order by #.startPos
           )
	     (Config.getConn ())
      in
        SQL.fetchAll r
      end

  fun findDefTuple (sym as {fileId, startPos, endPos, symbol}) =
      let
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
              #d.category as category,
              #d.defRangeEndPos as defRangeEndPos,
              #d.defRangeFileId as defRangeFileId,
              #d.defRangeStartPos as defRangeStartPos,
              #d.defSymbol as defSymbol,
              #d.defSymbolEndPos as defSymbolEndPos,
              #d.defSymbolFileId as defSymbolFileId,
              #d.defSymbolStartPos as defSymbolStartPos,
              #d.definedSymbol as definedSymbol,
              #d.internalId as internalId,
              #d.kind as kind,
              #d.sourceFileId as sourceFileId,
              #d.tfunKind as tfunKind
            from 
              #db.defTable as d
            where
            ((#d.defSymbol = symbol and
              #d.defSymbolFileId = fileId) and
              #d.defSymbolStartPos = startPos)
           )
	     (Config.getConn ())
      in
        case SQL.fetchAll r of
          h::_ => h
        | nil => 
          raise 
            (Dynamic.pp sym;
            Fail "findDefTuple")
      end

  (* List def syms referenced in fileName *)
  fun listDefSymsReferencedInDefSymLocal sym  =
      let
        val {defRangeEndPos=epos, defRangeFileId=fid, defRangeStartPos=spos,...} =
          findDefTuple sym
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
              #d.defSymbolFileId as fileId,
              #d.defSymbol as symbol,
              #d.defSymbolStartPos as startPos,
              #d.defSymbolEndPos as endPos
            from 
              #db.defTable as d,
              #db.refTable as r
            where
            (((((
              #r.refSymbolFileId = fid and
              #r.refSymbolStartPos >= spos) and
              #r.refSymbolEndPos <= epos) and
              #d.defSymbolFileId = #r.defSymbolFileId) and 
              #d.defSymbolStartPos = #r.defSymbolStartPos) and
              #d.defSymbolFileId = fid)
            order by #.fileId, #.startPos
           )
	     (Config.getConn ())
      in
        SQL.fetchAll r
      end
  (* List def syms referenced in fileName *)
  fun listDefSymsReferencedInDefSymExternal sym  =
      let
        val {defRangeEndPos=epos, defRangeFileId=fid, defRangeStartPos=spos,...} =
          findDefTuple sym
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
              #d.defSymbolFileId as fileId,
              #d.defSymbol as symbol,
              #d.defSymbolStartPos as startPos,
              #d.defSymbolEndPos as endPos
            from 
              #db.defTable as d,
              #db.refTable as r
            where
            (((((
              #r.refSymbolFileId = fid and
              #r.refSymbolStartPos >= spos) and
              #r.refSymbolEndPos <= epos) and
              #d.defSymbolFileId = #r.defSymbolFileId) and 
              #d.defSymbolStartPos = #r.defSymbolStartPos) and
              #d.defSymbolFileId <> fid)
            order by #.fileId, #.startPos
           )
	     (Config.getConn ())
      in
        SQL.fetchAll r
      end

  fun findParents {fileId, startPos, endPos, symbol} =
      let
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
               #d.defSymbolFileId as fileId,
               #d.defSymbol as symbol,
               #d.defSymbolEndPos as endPos,
               #d.defSymbolStartPos as startPos
            from 
              #db.defTable as d
            where
            ((((#d.defRangeFileId = fileId and
                #d.defSymbolFileId = fileId) and
                #d.defRangeStartPos <= startPos) and
                #d.defRangeEndPos > endPos) and
                #d.defSymbol <> symbol)
            order by #.startPos desc
           )
	     (Config.getConn ())
      in
        SQL.fetchAll r
      end

  fun findRefTuples {fileId, startPos, endPos, symbol} =
      let
        val r = 
           (_sql db : (dbSchema,'_) SQL.db =>
            select 
              #r.category as category,
              #r.defRangeEndPos as defRangeEndPos,
              #r.defRangeFileId as defRangeFileId,
              #r.defRangeStartPos as defRangeStartPos,
              #r.defSymbol as defSymbol,
              #r.defSymbolEndPos as defSymbolEndPos,
              #r.defSymbolFileId as defSymbolFileId,
              #r.defSymbolStartPos as defSymbolStartPos,
              #r.definedSymbol as definedSymbol,
              #r.internalId as internalId,
              #r.kind as kind,
              #r.sourceFileId as sourceFileId,
              #r.tfunKind as tfunKind,
              #r.refSymbolFileId as refSymbolFileId,
              #r.refSymbol as refSymbol,
              #r.refSymbolStartPos as refSymbolStartPos,
              #r.refSymbolEndPos as refSymbolEndPos
            from 
              #db.refTable as r
            where
            ((#r.defSymbol = symbol and
              #r.defSymbolFileId = fileId) and
              #r.defSymbolStartPos = startPos)
            order by #.refSymbolStartPos
           )
	     (Config.getConn ())
      in
        SQL.fetchAll r
      end

end
