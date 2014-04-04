(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestTypes.sml,v 1.3 2007/02/19 14:11:56 kiyoshiy Exp $
 *)
structure TestTypes =
struct

  (***************************************************************************)

  type caseResult =
       {
         sourcePath : string,
         isSameContents : bool,
         source : Word8Vector.vector,
         output : Word8Vector.vector,
         expected : Word8Vector.vector,
         exceptions : exn list
       }

  (***************************************************************************)

end
