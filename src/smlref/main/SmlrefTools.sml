structure SMLRefTools =
struct
  type sym = {fileId:int, startPos:int, endPos:int, symbol:string}
  type refTree = RefTypes.refTree
  type useTree = RefTypes.useTree
  datatype category = datatype DBSchema.category
  datatype idKind = datatype DBSchema.idKind
  datatype defInfo = datatype RefTypes.defInfo
  val fileIdToFileName = DBBasics.fileIdToFileName
  val fileNameToFileId = DBBasics.fileNameToFileId
  val listDefSymsInFile = DBBasics.listDefSymsInFile
  val listDefSymsReferencedInFile = DBBasics.listDefSymsReferencedInFile
  val listDefSymsReferencedInDefSymLocal = DBBasics.listDefSymsReferencedInDefSymLocal
  val listDefSymsReferencedInDefSymExternal = DBBasics.listDefSymsReferencedInDefSymExternal
  val makeTree = RefTrees.makeTree
  val makeUseTree = RefTrees.makeUseTree
  fun symToString sym =
      SMLFormat.prettyPrint nil (RefTypes.format_sym sym)
  fun reftreeToString refTree =
      SMLFormat.prettyPrint nil (RefTypes.format_refTree refTree)
  fun printSym sym = print (symToString sym ^ "\n")
  fun printRefTree refTree = print (reftreeToString refTree ^ "\n")
  val findDefInfo = RefUtiles.findDefInfo
end
