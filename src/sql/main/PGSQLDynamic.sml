structure PGSQLDynamic =
struct
local
  structure PG = SMLSharp_SQL_PGSQL
  structure Rty = ReifiedTy
  structure P = SMLSharp_Builtin.Pointer
in  
           
  datatype 'a server = DB of string
  type 'a con = 'a ptr
  exception DynamicTypeMismatch
  exception Runtime

  fun makeServer s = DB s 

  fun getText (rel, i, j)  =
      Pointer.importString
         (P.fromUnitPtr (P.toUnitPtr (PG.PQgetvalue () (rel, i, j))) :  char ptr)

  fun getServerTy (con : 'a con) = 
      let
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
        val rel = PG.PQexec() (P.toUnitPtr con, schemeQuery)
        val schemeInJson = getText(rel, 0, 0)
        val schemeInDyn = Dynamic.fromJson schemeInJson
        val schemeRep = 
            _dynamic 
              schemeInDyn
              as {table:string, fields:{column:string, ty:string} list} list
        fun translateType dbTypeName =
            case dbTypeName of
              "int4" => Dynamic.INT32ty
            | "float4" => Dynamic.REAL32ty
            | "float8" => Dynamic.REAL64ty
            | "text" => Dynamic.STRINGty
            | "varchar" => Dynamic.STRINGty
            | "bool" => Dynamic.BOOLty
            | _ => Dynamic.ERRORty
      in
        Dynamic.RecordTy
          (map 
             (fn {table, fields} => 
                 (table, 
                  Dynamic.LISTty
                    (Dynamic.RecordTy 
                       (map (fn {column, ty} => 
                                (column, translateType ty)) fields))))
             schemeRep)
      end


  fun matchTy (serverTy, specTy) =
      let
        val fail = ref false
        val _ = 
            case (serverTy, specTy) of
              (Rty.RECORDty fields1, Rty.RECORDty fields2) =>
              RecordLabel.Map.mergeWithi 
                (fn (label, SOME ty1, SOME ty2) => 
                    if Rty.reifiedTyEq (ty1,ty2) then NONE
                    else (print ("Type of table " ^ RecordLabel.toString label ^ " do not agree\n");
                          fail := true;
                          NONE)
                  | (label, SOME _, NONE) => NONE
                  | (label, NONE, SOME _) => 
                    (print ("Table " ^ RecordLabel.toString label ^ " does not exists\n");
                     fail := true;
                     NONE)
                  | _ => NONE
                )
                (fields1, fields2)
            | _ => (print "Record type expected\n";
                    fail := true;
                   RecordLabel.Map.empty)
      in
        !fail
      end
 

  fun castCon con = P.fromUnitPtr (P.toUnitPtr con)

  fun ('a#reify) conAsTy con : 'a con =
      let
        val dbTy = getServerTy con
        val specTy = #reifiedTy (_reifyTy('a))
      in
        if matchTy(dbTy, specTy) then 
          castCon con : 'a con
        else raise DynamicTypeMismatch
      end

  fun ('a#reify) connect (DB s :'a server) : 'a con = 
      let
        val con = PG.PQconnectdb() s
        val serverTy = getServerTy con
        val specTy = #reifiedTy (_reifyTy('a))
      in
        if matchTy (serverTy, specTy) then
          castCon con : 'a con
        else raise DynamicTypeMismatch
      end

  fun ('a#reify) insert (con, namedeRel : 'a) =
      let
        val serverTy = getServerTy con
        val valueTy = #reifiedTy (_reifyTy('a))
        val (label, tableValueTy) = 
            case valueTy of
              Rty.RECORDty fields => 
              (case RecordLabel.Map.listItemsi fields of
                 [(label, tableTy)] => (label, tableTy)
               | _ => raise DynamicTypeMismatch)
            | _ => raise DynamicTypeMismatch
        val _ = case serverTy of
                  Rty.RECORDty fields => 
                  (case RecordLabel.Map.find(fields, label) of
                    SOME tableTy => if ReifiedTy.reifiedTyEq (tableTy, tableValueTy) then ()
                                    else raise DynamicTypeMismatch
                  | _ => raise DynamicTypeMismatch
                  )
                | _ => raise DynamicTypeMismatch
        val keyList = 
            case tableValueTy of
              Rty.LISTty (Rty.RECORDty fields) => 
              map RecordLabel.toString (RecordLabel.Map.listKeys fields)
            | _ => raise DynamicTypeMismatch
        val table = RecordLabel.toString label
        val tableValue = Dynamic.dynamicToTerm (Dynamic.## table (Dynamic.dynamic namedeRel))
        val rowList = case tableValue of
                        Dynamic.LIST rowList => rowList
                      | _ => raise DynamicTypeMismatch
        val valueListList = 
            map (fn row => (#2 (Dynamic.RecordTermToKeyListValueList row))) rowList

        fun mkInsertQuery () = 
            let
              val query = "INSERT INTO " ^ table 
                          ^ "(" ^ String.concatWith "," keyList ^ ")"
                          ^ " VALUES "
                          ^  String.concatWith "," 
                             (map (fn valueList => "(" ^ String.concatWith "," valueList ^ ")") 
                                  valueListList)
              val query = String.map (fn c => if c = #"\"" then #"'" else c) query
            in
              query
            end
         val q = mkInsertQuery ()
       val rel = PG.PQexec() (P.toUnitPtr con, q)
      in
        ()
      end

  fun finish con = PG.PQfinish() (P.toUnitPtr con)
end
end

