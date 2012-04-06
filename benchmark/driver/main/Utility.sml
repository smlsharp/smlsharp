(**
 * @author YAMATODANI Kiyoshi
 * @version $Id: Utility.sml,v 1.2 2007/01/26 09:33:15 kiyoshiy Exp $
 *)
structure Utility =
struct

  (***************************************************************************)

  structure PU = PathUtility

  (***************************************************************************)

  fun closeOutputChannel (channel : ChannelTypes.OutputChannel) =
      #close channel ()

  fun closeInputChannel (channel : ChannelTypes.InputChannel) =
      #close channel ()

  fun getDirectory path = case PU.splitDirFile path of {dir, ...} => dir

  fun replaceExt ext fileName =
      case PU.splitBaseExt fileName of
        {base, ...} => PU.joinBaseExt{base = base, ext = SOME ext}

  (** ensure finalizer is executed *)
  fun finally arg userFunction finalizer =
      ((userFunction arg) before (finalizer arg))
      handle e => (finalizer arg; raise e)

  fun isSuffix (string, suffix) =
      let
        val stringlen = size string
        val suffixlen = size suffix
      in
        suffixlen <= stringlen
        andalso
        suffix = String.substring (string, stringlen - suffixlen, suffixlen)
      end

  (***************************************************************************)

end
