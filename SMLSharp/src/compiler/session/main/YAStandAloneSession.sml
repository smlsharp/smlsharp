(**
 * Yet another session implementation for batch mode compile.
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: YAStandAloneSession.sml,v 1.3 2007/11/19 06:00:02 katsu Exp $
 *)
structure YAStandAloneSession : sig
  include SESSION
(*
  val printObjectFile : ObjectFile.objectFile -> unit
*)
end =
struct

  type InitialParameter =
      {
        objectFile : ObjectFile.objectFile option ref
      }

  fun openSession ({objectFile} : InitialParameter) =
      let
        fun execute (SessionTypes.OBJECTFILE objfile) =
            (
            objectFile :=
            SOME (case !objectFile of
                    NONE => objfile
                  | SOME prev => ObjectFileLinker.link (prev, objfile))
            )
          | execute _ = raise Control.Bug "compilation result mismatch"

        fun close () = ()
      in
        {
          execute = execute,
          close = close
        }
      end

(*
  fun printObjectFile objfile =
      (
        print (ObjectFileFormatter.binaryObjectFileToString objfile);
        print "\n"
      )
*)

end
