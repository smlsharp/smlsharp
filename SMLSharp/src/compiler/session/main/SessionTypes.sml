(**
 * This module declares a type of operations which communicate with an instance
 * of the runtime.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SessionTypes.sml,v 1.10 2007/12/19 04:45:37 katsu Exp $
 *)
structure SessionTypes =
struct

  type asmOutput = (string -> unit) -> unit

  (**
   * result of compilation for each compilation unit.
   *)
  datatype compileResult =
      CODEBLOCK of Word8Vector.vector      (* for Yamatodani's runtime *)
    | OBJECTFILE of ObjectFile.objectFile  (* for Ueno's runtime *)
    | ASMFILE of                           (* for native code *)
      {code: asmOutput, nextDummy: asmOutput option}
      (*
       * "code" holds the resulting code of current compilation unit.
       * "nextDummy" holds a dummy code of next compilation unit.
       *
       * To link toplevel codes sequentially beyond object files, every
       * resulting code of native code generation has a reference to the
       * label of toplevel code in the next compilation unit. "nextDummy"
       * has a dummy definition of the label of the next toplevel.
       * If there is the next compilation unit, then "nextDummy" will be
       * abandoned since the next compilation unit will define actual toplevel
       * code and its label. Otherwise, "nextDummy" will be used to avoid
       * linking and semantics errors.
       *)

  (***************************************************************************)

  (**
   * operations which communicate with an instance of the runtime.
   *)
  type Session =
       {
         (** executes a code block. *)
         execute : compileResult -> unit,

         (** close the session. *)
         close : unit -> unit
       }

  (***************************************************************************)

  (** recoverable error *)
  exception Failure of exn

  (** unrecoverable error *)
  exception Fatal of exn

  (** user requests to 'exit' process. *)
  exception Exit of BasicTypes.SInt32

  (***************************************************************************)

end
