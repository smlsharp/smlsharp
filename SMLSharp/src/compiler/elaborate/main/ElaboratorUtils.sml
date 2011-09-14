structure ElaboratorUtils : sig

  val initializeErrorQueue : unit -> unit
  val getErrorsAndWarnings : unit -> UserError.errorInfo list
  val getErrors : unit -> UserError.errorInfo list
  val getWarnings : unit -> UserError.errorInfo list
  val enqueueError : Loc.loc * exn -> unit
  val enqueueWarning : Loc.loc * exn -> unit

(*
  val checkNameDuplication' : ('a -> string option)
                             -> 'a list
                             -> Loc.loc
                             -> (string -> exn)
                             -> unit

  val checkNameDuplication : ('a -> string)
                             -> 'a list
                             -> Loc.loc
                             -> (string -> exn)
                             -> unit
  val listToTuple : 'a list -> (string * 'a) list
*)

end =
struct

  local
    val errorQueue = UserError.createQueue ()
  in
    fun initializeErrorQueue () = UserError.clearQueue errorQueue
    fun getErrorsAndWarnings () = UserError.getErrorsAndWarnings errorQueue
    fun getErrors () = UserError.getErrors errorQueue
    fun getWarnings () = UserError.getWarnings errorQueue
    val enqueueError = UserError.enqueueError errorQueue
    val enqueueWarning = UserError.enqueueWarning errorQueue
  end

end
