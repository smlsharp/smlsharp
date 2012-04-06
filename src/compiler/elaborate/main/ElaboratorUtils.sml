structure ElaboratorUtils : sig

  val initializeErrorQueue : unit -> unit
  val getErrorsAndWarnings : unit -> UserError.errorInfo list
  val getErrors : unit -> UserError.errorInfo list
  val getWarnings : unit -> UserError.errorInfo list
  val enqueueError : Loc.loc * exn -> unit
  val enqueueWarning : Loc.loc * exn -> unit
  val elabInfixPrec : string * Loc.loc -> int

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

  fun elabInfixPrec (src, loc) =
      case src of
        "0" => 0
      | "1" => 1
      | "2" => 2
      | "3" => 3
      | "4" => 4
      | "5" => 5
      | "6" => 6
      | "7" => 7
      | "8" => 8
      | "9" => 9
      | _ => (enqueueError (loc, ElaborateError.InvalidFixityPrecedence);
              case Int.fromString src of
                SOME x => x
              | NONE => 0)

end
