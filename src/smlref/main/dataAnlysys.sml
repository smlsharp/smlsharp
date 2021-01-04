structure SMLRefAnalysis =
struct
  fun mkAbsPath file = 
      if OS.Path.isRelative file then
        OS.Path.concat (!C.baseDir, file)
      else file 

  fun fileList () = 
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
            ((fileTypeSMLSource = #s.fileType
              or fileTypeINTERFACE = #s.fileType)
              or fileTypeSMLUse =  #s.fileType)
           order by #.fileName) 
	       (Config.getConn ())
        val files1  = SQL.fetchAll r
        val json1 = Dynamic.valueToJson files1
        val _ = print json1
        val files2  = map #fileName files1
        val filesN = 
            DataUtils.mkNest
              (map 
                 DataUtils.listToTuple
                 (map (String.tokens (fn x => x = #"/")) files2))
            : {1:string, 
               L:{2:string, 
                  L:{3:string, 
                     L:{4:string, 
                        L:{5:string, 
                           L:{6:string} list
                          } list
                       } list
                    } list
                 } list
              } list
        val json = Dynamic.valueToJson filesN
        val _ = print json
      in
        json
      end


  fun fileList () = 
      let
        val r = 
           (_sql db :
            ({sourceTable:{fileType:string, 
                           fileName:string,...} list,...},'_) SQL.db =>
            select distinct
              #s.fileName
            from 
              #db.sourceTable as s
            where
            ("sml" = #s.fileType or
             "smi" =  #s.fileType)
           order by #.1) 
             (Config.getConn ())
        val files  = map #1 (SQL.fetchAll (fileList conn))
        val filesN = 
            DataUtils.mkNest
              (map 
                 DataUtils.listToTuple
                 (map (String.tokens (fn x => x = #"/")) files))
            : {1:string, 
               L:{2:string, 
                  L:{3:string, 
                     L:{4:string, 
                        L:{5:string, 
                           L:{6:string} list
                          } list
                       } list
                    } list
                 } list
              } list
      in
        (files, filesN)
      end
  fun dependFiles (file:string) =
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
          ((#ss.fileName = op SQL.Op.toSQL fileName
            and #ss.fileId = #d.fileId)
            and #sd.fileId = #d.dependFileId)
        order by #.name
(*
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
