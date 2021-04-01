(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure FileIDStringOrd =
struct
  type ord_key = {fileId:int, string:string}
  fun compare ({fileId =fid1, string = str1},
               {fileId=fid2, string=str2}) = 
      case Int.compare (fid1,fid2) of
        EQUAL => String.compare(str1, str2)
      | x => x
end
structure FileIDStringMap = BinaryMapFn(FileIDStringOrd)
