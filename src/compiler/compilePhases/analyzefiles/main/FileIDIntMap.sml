(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure FileIDIntOrd =
struct
  type ord_key = {fileId:int, startPos:int}
  fun compare ({fileId =fid1, startPos = int1},
               {fileId=fid2, startPos=int2}) = 
      case Int.compare (fid1,fid2) of
        EQUAL => Int.compare(int1, int2)
      | x => x
end
structure FileIDIntMap = BinaryMapFn(FileIDIntOrd)
