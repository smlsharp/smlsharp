(**
 * @copyright (c) 2006 - 2008, Tohoku University.
 * @author Atsushi Ohori
 *)

signature IDGEN = 
  sig
    type id
    val init : id -> unit (* id is the next id *)
    val reset : unit -> id (* id is the next id *)
    val generate : unit -> id 
    val peekNth : int -> id 
    val advance : int -> unit 
  end

  functor makeIDGen 
    (
      type id 
      val initialState : id option
      val nextNth : id -> int -> id
    ) : IDGEN =
  struct
    local
      val state = ref initialState : id option ref
    in
      type id = id
      fun init stamp = state := SOME stamp
      fun generate () = 
        case !state of
          NONE => raise Control.Bug "counter uninitialized"
        | SOME id => id before state := SOME (nextNth id 1)
      fun advance count =
        case !state of
          NONE => raise Control.Bug "counter uninitialized"
        | SOME id => state := SOME (nextNth id count)
      fun peekNth n =
        case !state of
          NONE => raise Control.Bug "counter uninitialized"
        | SOME id => nextNth id n
      fun reset () =
        case !state of
          NONE => raise Control.Bug "counter uninitialized"
        | SOME id => id  before state := NONE
    end
  end

  structure BoundTypeVarIDGen = 
    makeIDGen 
    (
     val initialState = NONE
     type id = BoundTypeVarID.boundTypeVarID
     val nextNth = BoundTypeVarID.nextNthBoundTypeVarID
     )

  structure ReservedBoundTypeVarIDGen = 
    makeIDGen 
    (
     val initialState = SOME BoundTypeVarID.initialReservedBoundTypeVarID
     type id = BoundTypeVarID.boundTypeVarID
     val nextNth = BoundTypeVarID.nextNthReservedBoundTypeVarID
     )

  structure TyConIDKeyGen = 
    makeIDGen 
    (
     type id = TyConID.id
     val initialState = NONE
     val nextNth = TyConID.nextNthID 
     )

  structure ReservedTyConIDKeyGen = 
    makeIDGen 
    (
     type id = TyConID.id
     val initialState = SOME TyConID.initialReservedID
     val nextNth = TyConID.nextNthReservedID
     )

  structure ExnTagIDKeyGen = 
    makeIDGen 
    (
     type id = ExnTagID.id
     val initialState = SOME (ExnTagID.fromInt Constants.TAG_exn_MAX)
     val nextNth = ExnTagID.nextNthID
    )

  structure ExternalVarIDKeyGen = 
    makeIDGen 
    (
     type id = ExternalVarID.id
     val initialState = NONE
     val nextNth = ExternalVarID.nextNthID
     )

  structure ClusterIDGen =
    makeIDGen 
    (
     type id = ClusterID.id
     val initialState = NONE
     val nextNth = ClusterID.nextNthID
     )

  structure LocalVarIDGen = 
    makeIDGen 
    (
     type id = LocalVarID.id
     val initialState = NONE
     val nextNth = LocalVarID.nextNthID
     )

  structure FreeTypeVarIDGen = 
    makeIDGen
    (
     type id = FreeTypeVarID.id
     val initialState = NONE
     val nextNth = FreeTypeVarID.nextNthID
     )

  structure VarNameGen = 
    struct
      local
        structure VarNameGen = 
          makeIDGen 
          (
            type id = VarNameID.id
            val initialState = NONE
            val nextNth = VarNameID.nextNthID
          )
      in
        val init = VarNameGen.init
        val reset = VarNameGen.reset
        val advance = VarNameGen.advance
        fun generate () =
          let
            val id = VarNameGen.generate ()
          in
            "$" ^ (VarNameID.toString id)
          end
        fun peekNth n =
          let
            val id = VarNameGen.peekNth n
          in
            "$" ^ (VarNameID.toString id)
          end
      end
    end



