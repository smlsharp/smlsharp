(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

structure P = OS.Path;
structure F = OS.FileSys;
exception Found of string
val cmd = case argv of name :: _ => name;
(
  app
      (fn dir =>
          let val path = P.concat (dir, cmd)
          in
            if F.access (path, [F.A_EXEC])
            then raise Found path
            else ()
          end handle SysErr _ => ())
      (fields ":" (env "PATH"));
  print "not found\n"
)
handle Found name => print name;
