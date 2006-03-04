(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: CodeEnv.sml,v 1.2 2006/02/28 16:11:05 kiyoshiy Exp $
 *)

structure CodeEnv = struct

  structure SI = SymbolicInstructions
  structure BT = BasicTypes

  datatype constant =
           Int of BT.SInt32
         | Word of BT.UInt32
         | Real of BT.Real64
         | Char of BT.UInt32

  type codeEnv = constant EntryMap.map

  val empty = EntryMap.empty : codeEnv

  fun constToInstruction (const, destination) =
      case const of 
        Int value => SI.LoadInt{value = value, destination = destination}
      | Word value => SI.LoadWord{value = value, destination = destination}
      | Real value => SI.LoadReal{value = Real64.toString value, destination = destination}
      | Char value => SI.LoadChar{value = value, destination = destination}

  fun entryToString {id,displayName} = ID.toString id

  fun addConstant (codeEnv, entry, const) =
      EntryMap.insert(codeEnv, entry, const)

  fun wordOf (codeEnv, entry) =
      case EntryMap.find(codeEnv,entry) of
        SOME (Word value) => SOME value
      | _ => NONE

  fun intOf (codeEnv, entry) =
      case EntryMap.find(codeEnv,entry) of
        SOME (Int value) => SOME value
      | _ => NONE

  fun realOf (codeEnv, entry) =
      case EntryMap.find(codeEnv,entry) of
        SOME (Real value) => SOME value
      | _ => NONE

  fun charOf (codeEnv, entry) =
      case EntryMap.find(codeEnv,entry) of
        SOME (Char value) => SOME value
      | _ => NONE

end
