structure GenReuireDecls =
struct
  datatype requireStatus 
    = LOCAL of string
    | DIRECT of string
  fun requireStatusToString (LOCAL s)  = "_require local " ^ "\"" ^ s ^ "\""
    | requireStatusToString (DIRECT s) = "_require       " ^ "\"" ^ s ^ "\""
  structure requireStatusKey =
    struct
      type ord_key = requireStatus
      fun compare (rs1, rs2) =
          let
            val s1 = case rs1 of DIRECT s => s | LOCAL s => s
            val s2 = case rs2 of DIRECT s => s | LOCAL s => s
          in
            String.compare (s1, s2)
          end
    end
  structure RSSet = BinarySetFn (requireStatusKey)

  fun isSml file = String.isSuffix ".sml" file 
  fun isSmi file = String.isSuffix ".smi" file 
  fun isSelf (f1, f2) = f1 = f2
  fun isBuiltin f = f = "src/builtin.smi"
  fun mkRelative (f1, f2) =
      let
        val {dir, file = _} = OS.Path.splitDirFile f2
        val baseDir = "/" ^ dir
        val file = "/" ^ f1
      in
        "./" ^ (OS.Path.mkRelative {path = file, relativeTo = baseDir})
      end

  fun defRefRel () = 
    let
      val r = 
          (_sql db :
           ({refTable:{kind:string, 
                       defSymbol:string,
                       defSymbolFileId:int,
                       refSymbol:string,
                       refSymbolFileId:int,...} list,
             sourceTable:{fileName:string, fileId:int,...} list,...},
            '_) SQL.db =>
             select distinct
               #ds.fileName as defFile,
               #rs.fileName as refFile
             from
               #db.refTable as d,
               #db.sourceTable as rs,
               #db.sourceTable as ds
            where
             ((#ds.fileId = #d.defSymbolFileId)
               and #rs.fileId = #d.refSymbolFileId)
            order by #.refFile, #.defFile
          ) (Config.getConn ())
    in
      SQL.fetchAll r
    end
  fun UPDefRefRel () = 
    let
      val r = 
          (_sql db :
           ({UPRefTable:{defSymbol:string,
                         defSymbolFileId:int,
                         refSymbol:string,
                         refSymbolFileId:int,...} list,
             sourceTable:{fileName:string, fileId:int,...} list,...},
            '_) SQL.db =>
             select distinct
               #ds.fileName as defFile,
               #rs.fileName as refFile
             from
               #db.UPRefTable as d,
               #db.sourceTable as rs,
               #db.sourceTable as ds
            where
             ((#ds.fileId = #d.defSymbolFileId)
               and #rs.fileId = #d.refSymbolFileId)
            order by #.refFile, #.defFile
          ) (Config.getConn ())
    in
      SQL.fetchAll r
    end

  fun genRequireDecls () =
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
         SEnv.appi
          (fn (file, sset) =>
	      let
		val prefix = String.concatWith 
			       "\n" 
			       (map requireStatusToString sset)
	      in
		ProcessRequireFile.replaceInteraceFile(file, prefix)
	      end
	  )
          dependList
      end
      
val _ = genRequireDecls ()
end
