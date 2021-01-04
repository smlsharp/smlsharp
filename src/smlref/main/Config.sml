structure Config =
struct
local
  datatype 'a opt = NotYet | Error | Found of 'a
  val conn = ref NotYet : DBSchema.dbSchema SQL.conn opt ref
  val refdbName = 
      case OS.Process.getEnv "SMLSHARP_SMLREFDB" of
        SOME name => name
      | NONE => "smlsharp"
  val serverParam = "dbname=" ^ refdbName
  val server = _sqlserver serverParam : DBSchema.dbSchema
in
  exception ConfigInfoNotFound
  exception DatabaseNotAvailable
  val doLogging = ref false
  val systemName = ref ""
  val version = ref ""
  val baseDir = ref ""
  val rootFile = ref ""
  fun closeConn () =
      case !conn of 
	  Found c => SQL.closeConn c
	| _ => ()
  fun getConn () = 
      case !conn of
	  NotYet => 
	  (let
	       val con = SQL.connect server
	       val _ = conn := Found con 
	   in
	     con
	   end
	   handle e => (conn := Error; raise e))
	| Error => raise DatabaseNotAvailable
	| Found con => con

  val _ = 
      if !systemName = "" then 
          let
              val r = 
                  (_sql db : (DBSchema.dbSchema, '_) SQL.db =>
                   select
                       #c.systemName as systemName,
                   #c.version as version,
                   #c.baseDir as baseDir,
                   #c.rootFile as rootFile
                               from
                               #db.configTable as c) 
		      (getConn ())
              val result as {systemName =s, version =v , baseDir = b, rootFile =r} =
                  case SQL.fetchAll r of
                      nil => raise ConfigInfoNotFound
                    | h::_ => h
              val _ = systemName := s
              val _ = version := v
              val _ = baseDir := b
              val _ = rootFile := r
          in
              ()
          end
      else ()
  fun config () =
      {baseDir = !baseDir,
       version = !version,
       systemName = !systemName,
       rootFile = !rootFile
      }
end
end
