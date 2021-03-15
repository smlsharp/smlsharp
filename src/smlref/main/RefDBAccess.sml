structure RefDBAccess =
struct
local
  open DBSchema
  structure C = Config
in
  exception RefNotFound
  exception ConfigInfoNotFound
  exception FileNotFoudInFileMap

  fun findDefInRefTable (pos:int, path:string) = 
    let
      val _ = Log.log "findDefInRefTable\n"
      val _ = Log.log path
      val _ = Log.log "\n"
      val _ = Log.log (Int.toString pos)
      val _ = Log.log "\n"
      val r = 
          (_sql db : (dbSchema, _) SQL.db =>
             select distinct
               #r.defSymbolStartPos as pos,
               #r.refSymbol as refSym,
               #ds.fileName as path
             from
               #db.refTable as r,
               #db.sourceTable as rs,
               #db.sourceTable as ds
            where
           ((((#r.refSymbolStartPos = pos)
               and #rs.fileName = path)
               and #rs.fileId = #r.refSymbolFileId)
               and #ds.fileId = #r.defSymbolFileId)
          ) (Config.getConn ())
    in
      SQL.fetchAll r
    end

  fun findRefInRefTable (pos, path) = 
    let
      val _ = Log.log "findRefInRefTable\n"
      val r = 
          (_sql db : (dbSchema, _) SQL.db =>
             select distinct
               #d.refSymbolStartPos as pos,
               #d.defSymbol as defSym,
               #rs.fileName as path
             from
               #db.refTable as d,
               #db.sourceTable as rs,
               #db.sourceTable as ds
            where
            ((((#d.defSymbolStartPos = pos)
                and #ds.fileName = path)
                and #ds.fileId = #d.defSymbolFileId)
                and #rs.fileId = #d.refSymbolFileId)
            order by #.path, #.pos
          ) (Config.getConn ())
    in
      SQL.fetchAll r
    end

  fun findDef {path, pos} =
    let
      val _ = Log.log "findDef\n"
      val fileName = 
          if OS.Path.isRelative path then path
          else OS.Path.mkRelative {path = path, relativeTo = !C.baseDir}
      val _ = Log.log (fileName ^ "\n")
      val infoList = findDefInRefTable (pos, fileName)
      val _ = Log.log (Dynamic.format infoList ^ "\n")
      val res =
          case infoList of
             {refSym, pos, path}:: _ => {status = OK, refSym = refSym, pos = pos, path = path}
           | _ => {status = NG,  refSym = "", pos = ~1, path = ""}
    in
      res
    end

  fun findRef {path, pos} =
    let
      val _ = Log.log "findRef\n"
      val fileName = 
          if OS.Path.isRelative path then path
          else OS.Path.mkRelative {path = path, relativeTo = !C.baseDir}
      val _ = Log.log (fileName ^ "\n")
      val infoList = findRefInRefTable (pos, fileName)
      val _ = Log.log (Dynamic.format infoList ^ "\n")
    in
        case infoList of 
            nil => {status = NG, defSym = "", files = nil}
          | {defSym, pos, path}::_ =>  {status = OK, defSym = defSym, files = infoList}
    end

  fun findDefEcho arg = arg

  val sample1 = {path = "src/compiler/compilePhases/elaborate/main/Elaborator.sml",
                 pos = 600}
  val sample2 = {path = "src/compiler/compilePhases/elaborate/main/Elaborator.smi",
                 pos = 711}

end
end
