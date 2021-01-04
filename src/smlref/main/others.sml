(*
   A.smi  
      type foo : B.smi.bar
   A.sml
   B.smi
     _require C.smi
     val y : int
   B.sml
     val y = z
   C.smi
     val z : int
   C.sml
     val z = 1
         
   def     ref
   B.smi - A.smi
   A.sml - A.smi
   B.sml - B.smi
   C.smi - B.sml
   C.sml - C.smi

defSet
   A.smi - {A.sml, B.smi}
   B.smi - {B.sml}
   B.sml - {C.smi}
   C.smi - {C.sml}
refSet
   A.sml - {A.smi}
   B.smi - {A.smi}
   B.sml - {B.smi}
   C.smi - {B.sml}
   C.sml - {C.smi}

   A.sml - {A.smi}
   B.smi - {A.smi, A.sml}
   B.sml - {B.smi, B.sml}
   C.smi - {B.sml}
   C.sml - {C.smi, B.sml}
   
dependRel
   A.smi - {DIRECT B.smi}
   B.smi - {LOCAL C.smi}
   C.smi - {}
*)

  fun computeRefSets () =
      let
        val defRefRel = defRefRel()
        val (refSet, defSet) = 
            foldr
              (fn ({defFile, refFile}, (refSet, defSet)) =>
                  if isBuiltin defFile orelse isSelf (defFile, refFile) 
                  then (refSet, defSet)
                  else
                    let 
                      val refSet = 
                          case SEnv.find (refSet, defFile) of
                            SOME refFiles => 
                            SEnv.insert(refSet,
                                        defFile,
                                        SSet.add (refFiles, refFile))
                          | NONE => SEnv.insert(refSet,
                                                defFile,
                                                SSet.singleton refFile)
                      val defSet = 
                          case SEnv.find (defSet, refFile) of
                            SOME defFiles => 
                            SEnv.insert(defSet,
                                        refFile,
                                        SSet.add (defFiles, defFile))
                          | NONE => SEnv.insert(defSet,
                                                refFile,
                                                SSet.singleton defFile)
                    in
                      (refSet, defSet)
                    end
              )
              (SEnv.empty, SEnv.empty)
              defRefRel
      in
        print "refSet\n";
         SEnv.appi
          (fn (file, sset) =>
              (
               print (file ^ ":\n");
               map (fn s => print ("  " ^ s ^ "\n")) (SSet.listItems sset);
               print "\n";
               ()
               )
          )
          refSet;
        print "defSet\n";
         SEnv.appi
          (fn (file, sset) =>
              (
               print (file ^ ":\n");
               map (fn s => print ("  " ^ s ^ "\n")) (SSet.listItems sset);
               print "\n";
               ()
               )
          )
          defSet
      end

  fun fileDependTable () =
    let
      val r = 
          (_sql db :
           ({fileDependTable:
             {
              fileId : int, 
              startPos : int, 
              endPos : int, 
              dependFileId : int, 
              dependType : string
             } list,...},
            '_) SQL.db =>
             select distinct
               #ds.fileName as defFile,
               #rs.fileName as refFile,
               #d.dependType as fileType
             from
               #db.fileDependTable as d,
               #db.sourceTable as ds,
               #db.sourceTable as rs
            where
             ((#ds.fileId = #d.fileId)
               and #rs.fileId = #d.dependFileId)
            order by #.defFile
          ) (Config.getConn ())
    in
      SQL.fetchAll r
    end
      
  fun computeRefSets () =
      let
        val defRefRel = defRefRel()
        val (refSet, defSet) = 
            foldr
              (fn ({defFile, refFile}, (refSet, defSet)) =>
                  if isBuiltin defFile orelse isSelf (defFile, refFile) 
                  then (refSet, defSet)
                  else
                    let 
                      val refSet = 
                          case SEnv.find (refSet, defFile) of
                            SOME refFiles => 
                            SEnv.insert(refSet,
                                        defFile,
                                        SSet.add (refFiles, refFile))
                          | NONE => SEnv.insert(refSet,
                                                defFile,
                                                SSet.singleton refFile)
                      val defSet = 
                          case SEnv.find (defSet, refFile) of
                            SOME defFiles => 
                            SEnv.insert(defSet,
                                        refFile,
                                        SSet.add (defFiles, defFile))
                          | NONE => SEnv.insert(defSet,
                                                refFile,
                                                SSet.singleton defFile)
                    in
                      (refSet, defSet)
                    end
              )
              (SEnv.empty, SEnv.empty)
              defRefRel
      in
        print "refSet\n";
         SEnv.appi
          (fn (file, sset) =>
              (
               print (file ^ ":\n");
               map (fn s => print ("  " ^ s ^ "\n")) (SSet.listItems sset);
               print "\n";
               ()
               )
          )
          refSet;
        print "defSet\n";
         SEnv.appi
          (fn (file, sset) =>
              (
               print (file ^ ":\n");
               map (fn s => print ("  " ^ s ^ "\n")) (SSet.listItems sset);
               print "\n";
               ()
               )
          )
          defSet
      end

  fun fileDependTable () =
    let
      val r = 
          (_sql db :
           ({fileDependTable:
             {
              fileId : int, 
              startPos : int, 
              endPos : int, 
              dependFileId : int, 
              dependType : string
             } list,...},
            '_) SQL.db =>
             select distinct
               #ds.fileName as defFile,
               #rs.fileName as refFile,
               #d.dependType as fileType
             from
               #db.fileDependTable as d,
               #db.sourceTable as ds,
               #db.sourceTable as rs
            where
             ((#ds.fileId = #d.fileId)
               and #rs.fileId = #d.dependFileId)
          ) (Config.getConn ())
    in
      SQL.fetchAll r
    end


  fun fileIdAndFileType (fileName:string) =
      let
        val r =
            (_sql db :
             ({sourceTable:{fileId:int, fileType:string, fileName:string,...} list,
               ...}, '_) SQL.db =>
             select
               #ss.fileId as fileId,
               #ss.fileType as fileType
             from
               #db.sourceTable as ss
             where #ss.fileName = fileName
            ) (Config.getConn ())
        val L = SQL.fetchAll r
      in
        case L of
          tuple ::_ => tuple
        | _ => raise FileNotFoudInFileMap
      end

  fun dependFiles (fileName:string) =
      let
        val {isSmi, smiFileId, interfaceName} = smiFileId fileName
        val r =
           (_sql db :
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
              #db.sourceTable as sd
           where 
            (#d.fileId = smiFileId
             and #sd.fileId = #d.dependFileId)
           order by #.name) (Config.getConn ())
        val L = SQL.fetchAll r
        val result = {isSmi=isSmi, interfaceName = interfaceName, dependFiles = L}
        val json = Dynamic.valueToJson result
        val _ = print json
      in
        json
      end

  fun smiFileId (fileName:string) =
      let
        val r =
            (_sql db :
             ({fileMapTable:{fileId:int, 
                             smlFileId:int,...} list,
               sourceTable:{fileId:int, fileName:string,...} list,
               ...}, '_) SQL.db =>
             select
               #ss.fileId as inputFileId,
               #m.fileId as interfaceFileId,
               #si.fileName as interfaceName
             from
               #db.fileMapTable as m,
               #db.sourceTable as ss,
               #db.sourceTable as si
             where 
              ((#ss.fileName = fileName
               and (#ss.fileId = #m.fileId 
                    or #ss.fileId = #m.smlFileId))
               and #si.fileId = #m.fileId)
            ) (Config.getConn ())
        val L = SQL.fetchAll r
      in
        case L of
          {inputFileId, interfaceFileId, interfaceName}::_ =>
          {isSmi = inputFileId = interfaceFileId, 
           smiFileId = interfaceFileId, 
           interfaceName = interfaceName}
        | _ => raise FileNotFoudInFileMap
      end




