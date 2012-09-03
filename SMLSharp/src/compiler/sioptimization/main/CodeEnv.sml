(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: CodeEnv.sml,v 1.5 2007/09/10 14:13:30 kiyoshiy Exp $
 *)

structure CodeEnv : CODEENV = struct

  structure SI = SymbolicInstructions
  structure BT = BasicTypes

  structure Entry_ord:ORD_KEY = struct 
  type ord_key = SI.entry
               
  fun compare ({id = id1, displayName = displayName1},{id = id2, displayName = displayName2}) =
      ID.compare(id1,id2)
  end
  
  structure EntryMap = BinaryMapMaker(Entry_ord)
  structure EntrySet = BinarySetFn(Entry_ord)

  datatype constant =
           Int of BT.SInt32
         | Word of BT.UInt32
         | Real of string
         | Float of string
         | Char of BT.UInt32

  type codeEnv = constant EntryMap.map

  val empty = EntryMap.empty : codeEnv

  fun constToInstruction (const, destination) =
      case const of 
        Int value => SI.LoadInt{value = value, destination = destination}
      | Word value => SI.LoadWord{value = value, destination = destination}
      | Real value => SI.LoadReal{value = value, destination = destination}
      | Float value => SI.LoadFloat{value = value, destination = destination}
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

  fun floatOf (codeEnv, entry) =
      case EntryMap.find(codeEnv,entry) of
        SOME (Float value) => SOME value
      | _ => NONE

  fun charOf (codeEnv, entry) =
      case EntryMap.find(codeEnv,entry) of
        SOME (Char value) => SOME value
      | _ => NONE

end
