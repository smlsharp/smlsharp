(**
 * Errors raised from OLE module.
 * @copyright (c) 2010, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: OLE.sml,v 1.27.22.2 2010/05/09 03:58:29 kiyoshiy Exp $
 *)
structure OLE_Error =
struct

  datatype error = 
           ComSystemError of String.string
         | ComApplicationError
           of {
                code : word,
                source : String.string,
                description : String.string,
                helpfile : String.string,
                helpcontext : word
              }
         | NullObjectPointer
         | TypeMismatch of String.string
         | ResultMismatch of String.string
         | Conversion of String.string

  exception OLEError of error

end;