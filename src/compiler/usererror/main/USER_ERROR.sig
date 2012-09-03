(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: USER_ERROR.sig,v 1.2 2008/02/06 06:11:42 bochao Exp $
 *)
signature USER_ERROR =
sig

  (***************************************************************************)

  datatype errorKind = Error | Warning | Diagnosis of string
  type errorInfo = Loc.loc * errorKind * exn

  exception UserErrors of errorInfo list
  exception UserErrorsWithoutLoc of (errorKind * exn) list

  (***************************************************************************)

  type errorQueue

  val createQueue : unit -> errorQueue
  val clearQueue : errorQueue -> unit
  val isEmptyErrorQueue : errorQueue -> bool
  val enqueueError : errorQueue -> Loc.loc * exn -> unit
  val enqueueWarning : errorQueue -> Loc.loc * exn -> unit
  val enqueueDiagnosis : errorQueue -> Loc.loc * string * exn -> unit
  val format_errorInfo
      : errorInfo -> SMLFormat.FormatExpression.expression list
  val getErrorsAndWarnings : errorQueue -> errorInfo list
  val getErrors : errorQueue -> errorInfo list
  val getWarnings : errorQueue -> errorInfo list
  val getDiagnoses : errorQueue -> errorInfo list

  (***************************************************************************)

end
