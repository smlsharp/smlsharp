(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure FileIDIntStringOrd =
struct
  type ord_key = {fileId:int, startPos:int, category:string}
  fun compare ({fileId =fid1, startPos = int1, category=cat1},
               {fileId=fid2, startPos=int2, category=cat2}) = 
      case Int.compare (fid1,fid2) of
        EQUAL => 
        (case Int.compare(int1, int2) of
           EQUAL => String.compare(cat1, cat2)
         | x => x)
      | x => x
end
structure FileIDIntStringMap = BinaryMapFn(FileIDIntStringOrd)
