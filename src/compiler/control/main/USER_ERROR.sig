(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: USER_ERROR.sig,v 1.8 2006/02/18 04:59:20 ohori Exp $
 *)
signature USER_ERROR =
sig

  (***************************************************************************)

  datatype errorKind = Error | Warning | Diagnosis of string
  type errorInfo = Loc.loc * errorKind * exn

  exception Bug of string
  exception BugWithLoc of string * Loc.loc
  exception UserErrors of errorInfo list

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
