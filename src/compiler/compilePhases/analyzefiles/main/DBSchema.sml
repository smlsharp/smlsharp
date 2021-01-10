structure DBSchema =
struct
  datatype category
    = TOPENV
    | PROVIDE
    | INTERFACE
    | FIND
    | CHECKPROVIDE
    | BIND_TSTR
    | BIND_VAL
    | BIND_FUNCTION
    | BIND_PAT_FN
    | BIND_PAT_CASE
    | BIND_SIG
    | BIND_STR
    | BIND_FUNCTOR
    | SIGCHECK
    | FUNCTOR_ARG
    | SYSTEMUSE
  datatype idKind
    = VAR
    | CON
    | EXN
    | TYCON
    | STR
    | SIG
    | FUNCTOR

  val fileTypeSMLSource = "SMLSource"
  val fileTypeSMLUse = "SMLUse"
  val fileTypeINTERFACE = "INTERFACE"
  val fileTypeOBJECT = "OBJECT"

  val OK = "OK"
  val NG = "NG"

  type configTuple = 
    {
     systemName : string, 
     version : string,
     baseDir : string,
     rootFile : string
    }
  type sourceTuple = 
    {
     filePlace : string, 
     fileName : string,
     fileId : int, 
     fileType : string
    }
  val sourceTupleTemplate : sourceTuple
    = {
    filePlace = "",
    fileName = "",
    fileId = ~1, 
    fileType = ""
    }
  type fileMapTuple = 
    {
     fileId : int,
     interfaceHash : string, 
     smlFileId : int, 
     objFileId : int
    }
  val fileMapTupleTemplate : fileMapTuple
    = {
    fileId = ~1, 
    interfaceHash = "", 
    smlFileId = ~1, 
    objFileId = ~1
    }
  type fileDependTuple = 
    {
     fileId : int, 
     startPos : int, 
     endPos : int, 
     dependFileId : int, 
     dependType : string
    }
  val fileDependTupleTemplate : fileDependTuple
    =  {
    fileId = ~1, 
    startPos= ~1, 
    endPos= ~1,
    dependFileId = ~1, 
    dependType = ""
    }
  type defTuple = 
    {
     kind : string,
     sourceFileId : int,
     category : string,
     defSymbol : string,
     defSymbolFileId : int,
     defSymbolStartPos : int,
     defSymbolEndPos : int,
     defRangeFileId : int,
     defRangeStartPos : int,
     defRangeEndPos : int,
     definedSymbol : string,
     internalId : int,
     tfunKind : string
    }
  val defTupleTemplate : defTuple
    = {
     kind = "",
     sourceFileId = 9999999,
     category = "",
     defSymbol = "",
     defSymbolFileId = ~1,
     defSymbolStartPos = ~1,
     defSymbolEndPos = ~1,
     defRangeFileId = ~1,
     defRangeStartPos = ~1,
     defRangeEndPos = ~1,
     definedSymbol = "",
     internalId = ~1,
     tfunKind = ""
    }
  type refTuple = 
    {
     category : string,
     defRangeEndPos : int,
     defRangeFileId : int,
     defRangeStartPos : int,
     defSymbol : string,
     defSymbolEndPos : int,
     defSymbolFileId : int,
     defSymbolStartPos : int,
     definedSymbol : string,
     internalId : int,
     kind : string,
     refSymbol : string,
     refSymbolEndPos : int,
     refSymbolFileId : int,
     refSymbolStartPos : int,
     sourceFileId : int,
     tfunKind : string
    }
  val refTupleTemplate : refTuple
    = {
     category = "",
     kind = "",
     sourceFileId = ~1,
     refSymbol = "",
     refSymbolFileId = ~1,
     refSymbolStartPos = ~1,
     refSymbolEndPos = ~1,
     defRangeFileId  = ~1,
     defRangeStartPos = ~1,
     defRangeEndPos = ~1,
     defSymbol = "",
     defSymbolFileId = ~1,
     defSymbolStartPos = ~1,
     defSymbolEndPos = ~1,
     definedSymbol = "",
     internalId = ~1,
     tfunKind = ""
    }
  type UPRefTuple = 
    {
     refSymbol : string,
     refSymbolFileId : int,
     refSymbolStartPos : int,
     refSymbolEndPos : int,
     defSymbol : string,
     defSymbolFileId : int,
     defSymbolStartPos : int,
     defSymbolEndPos : int
    }
  val UPRefTupleTemplate : UPRefTuple
  = {
     refSymbol = "",
     refSymbolFileId  = ~1,
     refSymbolStartPos  = ~1,
     refSymbolEndPos  = ~1,
     defSymbol = "",
     defSymbolFileId  = ~1,
     defSymbolStartPos  = ~1,
     defSymbolEndPos  = ~1
  }
  type dbSchema =
    {
     configTable : configTuple list,
     sourceTable: sourceTuple list,
     fileMapTable : fileMapTuple list,
     fileDependTable : fileDependTuple list,
     defTable : defTuple list,
     refTable : refTuple list,
     UPRefTable : UPRefTuple list
    }
end
