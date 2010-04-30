signature LR_TABLE =
sig
    datatype state = STATE of int
    datatype term = T of int
    datatype action = SHIFT of state
                    | REDUCE of int
                    | ACCEPT
                    | ERROR
    type table = {x : int}

    val action : table -> state * term -> action
end;
structure LrTable : LR_TABLE = 
struct
    datatype state = STATE of int
    datatype term = T of int
    datatype action = SHIFT of state
                    | REDUCE of int
                    | ACCEPT
                    | ERROR
    type table = {x : int}

    val action =
        fn ({x,...} : table) =>
          fn (STATE state,term : term) => ERROR
end;
structure LrParser =
struct
  structure LrTable = LrTable

  open LrTable

  fun prAction action =
      case action of SHIFT state => print ("SHIFT")
end;
