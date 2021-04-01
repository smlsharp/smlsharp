(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure AnalyzerTy =
struct
  type sourceKey = 
    {
     filePlace : Loc.file_place, 
     fileName : Filename.filename
    }
  type sourceInfo = 
    {
     fileId : int,
     fileType : string
    }
  type sourceMap = sourceInfo SourceMap.map
  type fileIDKey =
    {
     fileId : int
    }
  type fileMapInfo = 
    {
     interfaceHash : string, 
     smlFileId : int, 
     objFileId :int
    } 
  type fileMap = fileMapInfo FileIDMap.map
  type fileIDIntKey = 
    {
     fileId : int, 
     startPos : int
    }
  type fileDependInfo = 
    {
     endPos : int, 
     dependFileId : int, 
     dependType : string
    }
  type fileDependMap = fileDependInfo FileIDIntMap.map
  type defMap = DBSchema.defTuple FileIDIntStringMap.map
  type refMap = DBSchema.refTuple FileIDIntMap.map
  type UPRefMap = DBSchema.UPRefTuple FileIDFileIDMap.map
end
