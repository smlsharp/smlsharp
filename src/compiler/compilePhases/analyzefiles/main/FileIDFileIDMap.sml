structure FileIDFileIDOrd =
struct
  type ord_key = {refFileId:int, defFileId:int}
  fun compare ({refFileId =rfid1, defFileId = dfid1},
               {refFileId =rfid2, defFileId = dfid2}) =
      case Int.compare (rfid1,rfid2) of
        EQUAL => Int.compare(dfid1, dfid2)
      | x => x
end
structure FileIDFileIDMap = BinaryMapFn(FileIDFileIDOrd)
