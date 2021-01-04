structure FileIDOrd =
struct
  type ord_key = {fileId:int}
  fun compare ({fileId =fid1}, {fileId=fid2}) = 
      Int.compare (fid1,fid2)
end
structure FileIDMap = BinaryMapFn(FileIDOrd)
structure FileIDSet = BinarySetFn(FileIDOrd)
