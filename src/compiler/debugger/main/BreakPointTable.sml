(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: BreakPointTable.sml,v 1.2 2006/02/18 04:59:20 ohori Exp $
 *)
structure BreakPointTable
          : sig
              type table
              val create : unit -> table
              val register
                  : table
                    * RuntimeTypes.codeRef
                    * Instructions.OPCODE_instruction
                    -> int
              val find
                  : table * int
                    -> (RuntimeTypes.codeRef * Instructions.OPCODE_instruction)
                           option
              val delete : table * int -> unit
              val findByCodeRef
                  : table * RuntimeTypes.codeRef
                    -> (int * Instructions.OPCODE_instruction) option
                  
            end = 
struct

  (***************************************************************************)

  open BasicTypes
  structure I = Instructions
  structure RT = RuntimeTypes

  (***************************************************************************)

  type element = RT.codeRef * I.OPCODE_instruction

  type table = element IEnv.map ref

  (***************************************************************************)

  fun nextIndex table =
      let
        val numItems = IEnv.numItems (!table)
        val candidates = List.tabulate (numItems, fn x => x)
      in
        case
          List.find
              (fn candidate => not(isSome(IEnv.find (!table, candidate))))
              candidates
         of
          NONE =>
          (* NONE indicates that the table contains [0, ..., (numItems-1)]
           *)
          numItems
        | SOME index => index
      end

  fun create () = (ref IEnv.empty) : table

  fun register (table : table, codeRef, originalOpcode) =
      let val index = nextIndex table
      in
        table := IEnv.insert (!table, index, (codeRef, originalOpcode));
        index
      end

  fun find (table, index) = IEnv.find (!table, index)

  fun delete (table, index) = table := #1(IEnv.remove (!table, index))

  fun findByCodeRef (table, codeRef) = 
      Option.map
          (fn (index, (codeRef, opCode)) => (index, opCode))
          (List.find
               (fn (index, (cr, opCode)) => cr = codeRef)
               (IEnv.listItemsi (!table)))

  (***************************************************************************)

end

