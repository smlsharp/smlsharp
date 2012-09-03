(**
 *
 * @author YAMATODNI Kiyoshi
 * @version $Id: Utility.sml,v 1.1 2005/12/10 08:04:57 kiyoshiy Exp $
 *)
structure Utility =
struct

  (**
   * convert a reader to a new one which skips from a '#' to the next end of
   * line.
   *)
  fun skipCommentParser reader stream =
      case reader stream of
        SOME (#"#", src) =>
        let
          val stream = StringCvt.dropl (fn c => c <> #"\n") reader stream
          val SOME(_, stream) = reader stream
        in
          skipCommentParser reader stream
        end
      | result => result

end;
