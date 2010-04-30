(**
 * a session implementation which communicates with the VM simulator.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: VMSession.sml,v 1.15 2008/01/16 06:43:11 kiyoshiy Exp $
 *)
structure VMSession : SESSION =
struct

  (***************************************************************************)

  structure RE = RuntimeErrors
  structure ES = ExecutableSerializer

  (***************************************************************************)

  type InitialParameter =
       {
         VM : VM.VM
       }

  (***************************************************************************)

  fun openSession ({VM, ...} : InitialParameter) =
      {
        execute =
        fn result =>
           let
             val codeBlock =
                 case result of
                   SessionTypes.CODEBLOCK codeBlock => codeBlock
                 | _ => raise Control.Bug "VMSession requires CODEBLOCK"
             val executable = ES.deserialize codeBlock
           in VM.execute (VM, executable) end
           handle exn as RE.Abort => raise SessionTypes.Fatal exn
                | exn as RE.Interrupted => raise SessionTypes.Failure exn
                | RE.InvalidCode message =>
                  raise SessionTypes.Failure (Fail message)
                | RE.InvalidStatus message =>
                  raise SessionTypes.Failure (Fail message)
                | RE.UnexpectedPrimitiveArguments message =>
                  raise SessionTypes.Failure (Fail message)
                | RE.Error message => raise SessionTypes.Failure (Fail message)
                | exn => raise SessionTypes.Failure (exn),
        close = fn _ => ()
      }

  (***************************************************************************)

end
