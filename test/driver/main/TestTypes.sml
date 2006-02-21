(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestTypes.sml,v 1.2 2005/03/17 14:58:46 kiyoshiy Exp $
 *)
structure TestTypes =
struct

  (***************************************************************************)

  type caseResult =
       {
         sourcePath : string,
         isSameContents : bool,
         source : Word8Array.array,
         output : Word8Array.array,
         expected : Word8Array.array,
         exceptions : exn list
       }

  (***************************************************************************)

end