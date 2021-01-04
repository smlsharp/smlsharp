structure PGSQLDynamic =
struct
local
  structure PGB = SMLSharp_SQL_PGSQLBackend
  structure D = Dynamic
  structure Rty = ReifiedTy
  structure P = SMLSharp_Builtin.Pointer
  fun quoteSQLString s = "\"" ^ s ^ "\""
  fun recordLabelToSqlString l =
      quoteSQLString (RecordLabel.toString l)
      
  val schemeQuery =
      " WITH res as (\n"
      ^ "  SELECT tables.table_name as table,\n"
      ^ "  (WITH temp as\n"
      ^ "    (\n"
      ^ "      SELECT pg_attribute.attname as column, pg_type.typname as ty\n"
      ^ "      FROM pg_class, pg_attribute, pg_type\n"
      ^ "      WHERE pg_class.relname = tables.table_name\n"
      ^ "        AND pg_class.relkind ='r'\n"
      ^ "        AND pg_attribute.attrelid = pg_class.oid\n"
      ^ "        AND pg_attribute.attnum > 0\n"
      ^ "        AND pg_type.oid = pg_attribute.atttypid\n"
      ^ "    ) SELECT json_agg(temp) from temp) as fields\n"
      ^ "  FROM information_schema.tables as tables\n"
      ^ "  WHERE table_schema='public'\n"
      ^ " ) SELECT json_agg(res) from res\n"
in  
  exception Exec = SMLSharp_SQL_Errors.Exec
  exception Connect = SMLSharp_SQL_Errors.Connect
  exception Format = SMLSharp_SQL_Errors.Format

  exception DynamicTypeMismatch
  exception IlleagalSqlty
  exception IlleagalColumTy
  exception IlleagalTableTy
  exception DropTable
  datatype 'a server = SERVER of string
  type conn = SMLSharp_SQL_PGSQLBackend.conn
  datatype 'a con = CONN of conn
  datatype 'a table = TABLE of {keys : string list}
  fun sqlTyToReifiedTy dbTypeName =
      case dbTypeName of
        "int4" => D.INT32ty
      | "float4" => D.REAL32ty
      | "float8" => D.REAL64ty
      | "text" => D.STRINGty
      | "varchar" => D.STRINGty
      | "bool" => D.BOOLty
      | s => 
        (print ("sql type " ^ s ^ " not supported\n");
         raise IlleagalSqlty
        )
  fun reifiedTyToSqlTy dbTypeName =
      case dbTypeName of
        D.INT32ty => "int4"
      | D.REAL32ty => "float4" 
      | D.REAL64ty => "float8"
      | D.STRINGty => "text"
      | D.BOOLty  => "bool"
      | ty => 
        (print ("type " ^ (D.tyToString ty) ^ " not supported\n");
         raise IlleagalSqlty
        )
  fun connect string = PGB.connect string
  fun getString (res,i) = 
      let
        val _ = PGB.fetch res
      in
        case PGB.getValue(res, i) of
          NONE => NONE
        | SOME value => PGB.stringValue value
      end
  fun getServerTy conn = 
      let
        val res = PGB.execQuery (conn, schemeQuery)
        val stringOption = getString (res, 0)
      in
        case stringOption of
          NONE => ReifiedTy.UNITty
        | SOME schemeInJson => 
          let
            val schemeInDyn = Dynamic.fromJson schemeInJson
            val schemeRep = 
                _dynamic 
                  schemeInDyn
                  as {table:string, fields:{column:string, ty:string} list} list
          in
            Dynamic.RecordTy
              (map 
                 (fn {table, fields} => 
                     (table, 
                      D.LISTty
                        (Dynamic.RecordTy 
                           (map (fn {column, ty} => 
                                    (column, sqlTyToReifiedTy ty)) fields))))
                 schemeRep)
          end
      end

  fun printServerTy conn = 
      let
        val ty = getServerTy conn
        val string = Rty.reifiedTyToString ty
      in
        print (string ^ " server\n")
      end

  fun matchTy (serverTy, specTy) =
      let
        val fail = ref false
        fun match (serverTy, specTy)  =
            case (serverTy, specTy) of
              (D.RECORDty fields, D.UNITty) => ()
            | (D.LISTty tupleTy1, D.LISTty tupleTy2) =>
              match (tupleTy1, tupleTy2)
            | (D.RECORDty fields1, D.RECORDty fields2) => 
              (RecordLabel.Map.mergeWithi
                 (fn (label, SOME ty1, SOME ty2) => 
                     if Rty.reifiedTyEq (ty1,ty2) then NONE
                     else (print ( "Type of table " 
                                  ^ RecordLabel.toString label 
                                  ^ " do not agree\n");
                           fail := true;
                           NONE)
                   | (label, SOME _, NONE) => NONE
                   | (label, NONE, SOME _) => 
                     (print ("Table " ^ RecordLabel.toString label ^ " does not exists\n");
                      fail := true;
                      NONE)
                   | _ => NONE)
                 (fields1, fields2);
               ()
              )
            | _ => (print "Record type expected\n";
                    fail := true;
                    ())
      in
        not (!fail)
      end

  fun ('a#reify) conAsTy con : 'a con =
      let
        val dbTy = getServerTy con
        val specTy = #reifiedTy (_reifyTy('a))
      in
        if matchTy(dbTy, specTy) then 
          CONN con : 'a con
        else raise DynamicTypeMismatch
      end

  fun ('a#reify) insert conn (namedeRel : 'a) =
      let
        val serverTy = getServerTy conn
        val valueTy = #reifiedTy (_reifyTy('a))
        val (label, tableValueTy) = 
            case valueTy of
              D.RECORDty fields => 
              (case RecordLabel.Map.listItemsi fields of
                 [(label, tableTy)] => (label, tableTy)
               | _ => 
                 (print ("table list expected:"
                         ^ D.tyToString valueTy ^ "\n");
                     raise IlleagalTableTy)
              )
            | _ => 
              (print ("table type expected:"
                      ^ D.tyToString valueTy ^ "\n");
               raise IlleagalTableTy)
        val _ = case serverTy of
                  D.RECORDty fields => 
                  (case RecordLabel.Map.find(fields, label) of
                    SOME tableTy => if ReifiedTy.reifiedTyEq (tableTy, tableValueTy) then ()
                                    else 
                                      (print (   "type of table " ^ RecordLabel.toString label 
                                               ^ " does not agree.\n"
                                               ^ "serverTy:" ^ D.tyToString tableTy ^ "\n" 
                                               ^ "valuesTy:" ^ D.tyToString tableValueTy ^ "\n");
                                       raise DynamicTypeMismatch)
                  | _ => 
                    (print ("table " ^ RecordLabel.toString label ^ "does not exists in server\n");
                     raise DynamicTypeMismatch))
                | _ => raise DynamicTypeMismatch
        val keyList = 
            case tableValueTy of
              D.LISTty (D.RECORDty fields) => 
              map recordLabelToSqlString (RecordLabel.Map.listKeys fields)
            | _ => raise DynamicTypeMismatch
        val table = RecordLabel.toString label
        val tableValue = Dynamic.dynamicToTerm (Dynamic.## table (Dynamic.dynamic namedeRel))
        val rowList = case tableValue of
                        Dynamic.LIST rowList => rowList
                      | _ => raise DynamicTypeMismatch
        val valueListList = map Dynamic.RecordTermToSQLValueList rowList
        val query = "INSERT INTO " ^ quoteSQLString table
                    ^ " (" ^ String.concatWith ", " keyList ^ ")\n"
                    ^ "VALUES\n"
                    ^  String.concatWith ",\n" 
                                         (map (fn valueList => "  (" ^ String.concatWith "," valueList ^ ")") 
                                              valueListList)
                    ^ "\n"
         val _ = Bug.printMessage "Executing the sql query:\n"
         val _ = Bug.printMessage (query ^ "\n")
      in
        (PGB.execQuery(conn, query); ())
      end

  fun dropTable conn string = 
      let
        val ty = getServerTy conn
        val _ = 
            case ty of
              D.RECORDty tables => 
              if List.exists
                   (fn x => x = string) 
                   (map RecordLabel.toString (RecordLabel.Map.listKeys tables))
              then ()
              else raise DropTable
            | D.UNITty => raise DropTable
            | _ => raise Fail "dropTable"
        val query = "DROP TABLE " ^ (quoteSQLString string) ^ "\n"
(*
        val _ = Bug.printMessage "Executing the sql query:\n"
        val _ = Bug.printMessage (query ^ "\n")
*)
        val rel = PGB.execQuery(conn, query)
      in
        ()
      end

  fun clearTables conn = 
      let
        val ty = getServerTy conn
        val tableNames = 
            case ty of
              D.RECORDty tables => 
              map RecordLabel.toString (RecordLabel.Map.listKeys tables)
            | D.UNITty => nil
            | _ => nil
        val queryList = map (fn x => "DROP TABLE " ^ quoteSQLString x) tableNames
        val _ = map (fn x => 
                        (
(*
                         Bug.printMessage "Executing the sql query:\n";
                         Bug.printMessage (x ^ "\n");
*)
                         PGB.execQuery(conn, x))
                    ) queryList
      in
        ()
      end

  fun ('a#reify) createTables conn (TABLE {keys} : 'a table) =
      let
        val {reifiedTy,...} = _reifyTy('a)
        val tableNameColumTyList = 
            case reifiedTy of
              D.RECORDty tables => 
              map
                (fn (l, tb) => (recordLabelToSqlString l, tb))
                (RecordLabel.Map.listItemsi tables)
            | _ => raise IlleagalTableTy
        fun columString tb = 
              case tb of
                D.LISTty (D.RECORDty fields) =>
                map (fn (l,t) =>
                        (  " " ^ recordLabelToSqlString l 
                         ^ " " 
                         ^ reifiedTyToSqlTy t
                         ^ " NOT NULL")
                    )
                    (RecordLabel.Map.listItemsi fields)
              | _ => raise IlleagalColumTy
        val keyConst = 
            case map quoteSQLString keys of
              nil => ""
            | keys => ",\n PRIMARY KEY(" ^ (String.concatWith "," keys) ^ ")"
        val createQueryList =
            map
            (fn (tableName, tb) => 
                "CREATE TABLE " ^ tableName ^ " (\n"
             ^ String.concatWith ",\n" (columString tb)
             ^ keyConst
             ^ "\n)\n"
            )
            tableNameColumTyList
        fun exec q = 
            (
             Bug.printMessage "Executing the sql query:\n";
             Bug.printMessage (q ^ "\n");
             PGB.execQuery(conn, q)
            )
        val _ = map exec createQueryList
        in
          ()
        end
                          
  fun closeConn conn = 
      (PGB.closeConn conn; ())

  fun ('a#reify) initDb (s as SERVER param:'a server)  =
      let
        val ty = _reifyTy('a)
        val conn = connect param
        val _ = clearTables conn
        val _ = createTables conn (TABLE {keys = nil} : 'a table)
      in
        conn
      end
end
end
