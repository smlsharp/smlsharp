(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure AnalyzerDB =
struct
local
  structure PG = PGSQLDynamic
  val conn = ref NONE : PG.conn option ref
  open AnalyzerTy
  open DBSchema
in
  fun insert table = 
      case !conn of 
        SOME c => PG.insert c table
      | _ => ()

  fun initDB dbparam =
      let
        val con = PG.connect dbparam
      in
        let
          val configTable = 
              PG.TABLE {keys = nil} : {configTable : configTuple list} PG.table
          val sourceTable = 
              PG.TABLE {keys = ["fileId"]} : {sourceTable : sourceTuple list} PG.table
          val fileMapTable = 
              PG.TABLE {keys = ["fileId"]} 
              :  {fileMapTable : fileMapTuple list} PG.table
          val fileDependTable = 
              PG.TABLE {keys = ["fileId", "startPos"]}
              :  {fileDependTable : fileDependTuple list} PG.table
          val defTable = 
              PG.TABLE {keys = ["sourceFileId", "category", "defSymbolFileId", "defSymbolStartPos"]} 
              :  {defTable : defTuple list} PG.table
          val refTable = 
              PG.TABLE {keys = ["sourceFileId", "refSymbolFileId", "refSymbolStartPos"]} 
              :  {refTable : refTuple list} PG.table
          val UPRefTable = 
              PG.TABLE {keys = ["defSymbolFileId", "refSymbolFileId"]} 
              :  {UPRefTable : UPRefTuple list} PG.table
          val _ = PG.clearTables con 
          val _ = PG.createTables con configTable
          val _ = PG.createTables con sourceTable
          val _ = PG.createTables con fileMapTable
          val _ = PG.createTables con fileDependTable
          val _ = PG.createTables con defTable
          val _ = PG.createTables con refTable
          val _ = PG.createTables con UPRefTable
          val _ = conn := SOME con
        in
          ()
        end
        handle e => (PG.closeConn con; conn := NONE; raise e)
      end

  fun closeDB () = 
      case !conn of
        SOME c => (PG.closeConn c;  conn := NONE)
      | _ => ()
end
end
