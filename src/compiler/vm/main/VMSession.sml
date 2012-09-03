(**
 * a session implementation which communicates with the VM simulator.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: VMSession.sml,v 1.14 2007/06/01 09:40:59 kiyoshiy Exp $
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
        fn code =>
           let val executable = ES.deserialize code
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
