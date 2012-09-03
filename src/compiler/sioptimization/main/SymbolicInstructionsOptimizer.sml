(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: SymbolicInstructionsOptimizer.sml,v 1.10 2007/06/20 06:50:41 kiyoshiy Exp $
 *)

structure SymbolicInstructionsOptimizer : SYMBOLIC_INSTRUCTIONS_OPTIMIZER = struct
  structure BT = BasicTypes
  structure CT = ConstantTerm
  open SymbolicInstructions

  structure Entry_ord:ordsig = struct 
  type ord_key = entry

  fun compare ({id = id1, displayName = displayName1},{id = id2, displayName = displayName2}) =
      ID.compare(id1,id2)
  end
  
  structure EntryMap = BinaryMapFn(Entry_ord)
  structure EntrySet = BinarySetFn(Entry_ord)

  datatype SizeListKind =
           EmptySizeList
         | SingletonSizeList of size
         | SingleSizeList 
         | LastArbitrarySizeList of size
         | FixedSizeList of BT.UInt32 list
         | VariantSizeList 

  datatype constant =
           Int of BT.SInt32
         | Word of BT.UInt32
         | Real of string
         | Float of string
         | String of string
         | Char of BT.UInt32
         | Variable

  type constMap = constant EntryMap.map

  fun eq (x,y) =
      case (x,y) of 
        (Int v1,Int v2) => v1 = v2
      | (Word v1,Word v2) => v1 = v2
      | (Real v1,Real v2) => v1 = v2
      | (Float v1,Float v2) => v1 = v2
      | (Char v1,Char v2) => v1 = v2
      | (String v1,String v2) => v1 = v2
      | _ => false

  fun wordOf constMap entry =
      case EntryMap.find(constMap,entry) of
        SOME (Word value) => SOME value
      | _ => NONE

  fun intOf constMap entry =
      case EntryMap.find(constMap,entry) of
        SOME (Int value) => SOME value
      | _ => NONE

  fun realOf constMap entry =
      case EntryMap.find(constMap,entry) of
        SOME (Real value) => SOME value
      | _ => NONE

  fun floatOf constMap entry =
      case EntryMap.find(constMap,entry) of
        SOME (Float value) => SOME value
      | _ => NONE

  fun charOf constMap entry =
      case EntryMap.find(constMap,entry) of
        SOME (Char value) => SOME value
      | _ => NONE

  fun stringOf constMap entry =
      case EntryMap.find(constMap,entry) of
        SOME (String value) => SOME value
      | _ => NONE

  fun constOf constMap entry = EntryMap.find(constMap,entry)

  fun ignore constMap entry = EntryMap.insert(constMap,entry,Variable)

  fun ignoreList constMap entryList = 
      foldl
          (fn (e,S) => EntryMap.insert(S,e,Variable))
          constMap
          entryList

  fun addConstant constMap entry constant =
      case EntryMap.find(constMap, entry) of 
        SOME c =>
        if eq(c,constant) 
        then constMap
        else ignore constMap entry
      | NONE => EntryMap.insert(constMap, entry, constant)

  val ALWAYS_Entry = {id= ID.reserve (),displayName =""}
  val ALWAYS = [ALWAYS_Entry]
  val dummyEntryList = ALWAYS

  fun optimizeSizeEntry constMap sizeEntry =
      case wordOf constMap sizeEntry of
        SOME 0w1 => SINGLE
      | SOME 0w2 => DOUBLE
      | _ => VARIANT sizeEntry

  fun optimizeSize constMap size =
      case size of 
        SINGLE => SINGLE
      | DOUBLE => DOUBLE
      | VARIANT v => optimizeSizeEntry constMap v

  fun allFixedSizes constMap [] L = SOME (rev L)
    | allFixedSizes constMap (sizeEntry::rest) L =
      (
       case wordOf constMap sizeEntry of
         SOME w => allFixedSizes constMap rest (w::L)
       | NONE => NONE
      )

  fun computeSizeListKind constMap [] = EmptySizeList
    | computeSizeListKind constMap [sizeEntry] = 
      SingletonSizeList (optimizeSizeEntry constMap sizeEntry)
    | computeSizeListKind constMap sizeEntries = 
      let
        val L = rev sizeEntries
        val sizeEntries = rev (List.tl L)
        val lastSizeEntry = List.hd L
      in
        case allFixedSizes constMap sizeEntries [] of
          SOME sizes => 
          (
           if List.all (fn w => w = 0w1) sizes 
           then
             case optimizeSizeEntry constMap lastSizeEntry of
               SINGLE => SingleSizeList
             | size => LastArbitrarySizeList size
           else
             case wordOf constMap lastSizeEntry of
               SOME w => FixedSizeList (sizes @ [w])
             | _ => VariantSizeList
          )
        | NONE => VariantSizeList
      end

  fun optimizeCallPrim constMap (instruction as CallPrim {primitive, argEntries, destination}) =
      let
        val intOf = intOf constMap
        val wordOf = wordOf constMap
        val charOf = charOf constMap
        val realOf = realOf constMap
        val floatOf = floatOf constMap
            
        fun optimize converter (operator1, operator2) (argEntry1, argEntry2) =
            case (converter argEntry1, converter argEntry2) of
              (SOME v, NONE) => 
              operator1 {argValue1 = v, argEntry2 = argEntry2, destination = destination}
            | (NONE, SOME v) =>
              operator2 {argEntry1 = argEntry1, argValue2 = v, destination = destination}
            | _ => instruction

      in
        case (#bindName primitive, argEntries) of
          ("addInt", [arg1,arg2]) => optimize intOf (AddInt_Const_1, AddInt_Const_2) (arg1, arg2)
        | ("addReal", [arg1,arg2]) => optimize realOf (AddReal_Const_1, AddReal_Const_2) (arg1, arg2)
        | ("addWord", [arg1,arg2]) => optimize wordOf (AddWord_Const_1, AddWord_Const_2) (arg1, arg2)
        | ("addByte", [arg1,arg2]) => optimize wordOf (AddByte_Const_1, AddByte_Const_2) (arg1, arg2)

        | ("subInt", [arg1,arg2]) => optimize intOf (SubInt_Const_1, SubInt_Const_2) (arg1, arg2)
        | ("subReal", [arg1,arg2]) => optimize realOf (SubReal_Const_1, SubReal_Const_2) (arg1, arg2)
        | ("subWord", [arg1,arg2]) => optimize wordOf (SubWord_Const_1, SubWord_Const_2) (arg1, arg2)
        | ("subByte", [arg1,arg2]) => optimize wordOf (SubByte_Const_1, SubByte_Const_2) (arg1, arg2)

        | ("mulInt", [arg1,arg2]) => optimize intOf (MulInt_Const_1, MulInt_Const_2) (arg1, arg2)
        | ("mulReal", [arg1,arg2]) => optimize realOf (MulReal_Const_1, MulReal_Const_2) (arg1, arg2)
        | ("mulWord", [arg1,arg2]) => optimize wordOf (MulWord_Const_1, MulWord_Const_2) (arg1, arg2)
        | ("mulByte", [arg1,arg2]) => optimize wordOf (MulByte_Const_1, MulByte_Const_2) (arg1, arg2)

        | ("divInt", [arg1,arg2]) => optimize intOf (DivInt_Const_1, DivInt_Const_2) (arg1, arg2)
        | ("/", [arg1,arg2]) => optimize realOf (DivReal_Const_1, DivReal_Const_2) (arg1, arg2)
        | ("divWord", [arg1,arg2]) => optimize wordOf (DivWord_Const_1, DivWord_Const_2) (arg1, arg2)
        | ("divByte", [arg1,arg2]) => optimize wordOf (DivByte_Const_1, DivByte_Const_2) (arg1, arg2)

        | ("modInt", [arg1,arg2]) => optimize intOf (ModInt_Const_1, ModInt_Const_2) (arg1, arg2)
        | ("modWord", [arg1,arg2]) => optimize wordOf (ModWord_Const_1, ModWord_Const_2) (arg1, arg2)
        | ("modByte", [arg1,arg2]) => optimize wordOf (ModByte_Const_1, ModByte_Const_2) (arg1, arg2)

        | ("quotInt", [arg1,arg2]) => optimize intOf (QuotInt_Const_1, QuotInt_Const_2) (arg1, arg2)
        | ("remInt", [arg1,arg2]) => optimize intOf (RemInt_Const_1, RemInt_Const_2) (arg1, arg2)

        | ("ltInt", [arg1,arg2]) => optimize intOf (LtInt_Const_1, LtInt_Const_2) (arg1, arg2)
        | ("ltReal", [arg1,arg2]) => optimize realOf (LtReal_Const_1, LtReal_Const_2) (arg1, arg2)
        | ("ltWord", [arg1,arg2]) => optimize wordOf (LtWord_Const_1, LtWord_Const_2) (arg1, arg2)
        | ("ltByte", [arg1,arg2]) => optimize wordOf (LtByte_Const_1, LtByte_Const_2) (arg1, arg2)
        | ("ltChar", [arg1,arg2]) => optimize charOf (LtChar_Const_1, LtChar_Const_2) (arg1, arg2)

        | ("gtInt", [arg1,arg2]) => optimize intOf (GtInt_Const_1, GtInt_Const_2) (arg1, arg2)
        | ("gtReal", [arg1,arg2]) => optimize realOf (GtReal_Const_1, GtReal_Const_2) (arg1, arg2)
        | ("gtWord", [arg1,arg2]) => optimize wordOf (GtWord_Const_1, GtWord_Const_2) (arg1, arg2)
        | ("gtByte", [arg1,arg2]) => optimize wordOf (GtByte_Const_1, GtByte_Const_2) (arg1, arg2)
        | ("gtChar", [arg1,arg2]) => optimize charOf (GtChar_Const_1, GtChar_Const_2) (arg1, arg2)

        | ("lteqInt", [arg1,arg2]) => optimize intOf (LteqInt_Const_1, LteqInt_Const_2) (arg1, arg2)
        | ("lteqReal", [arg1,arg2]) => optimize realOf (LteqReal_Const_1, LteqReal_Const_2) (arg1, arg2)
        | ("lteqWord", [arg1,arg2]) => optimize wordOf (LteqWord_Const_1, LteqWord_Const_2) (arg1, arg2)
        | ("lteqByte", [arg1,arg2]) => optimize wordOf (LteqByte_Const_1, LteqByte_Const_2) (arg1, arg2)
        | ("lteqChar", [arg1,arg2]) => optimize charOf (LteqChar_Const_1, LteqChar_Const_2) (arg1, arg2)

        | ("gteqInt", [arg1,arg2]) => optimize intOf (GteqInt_Const_1, GteqInt_Const_2) (arg1, arg2)
        | ("gteqReal", [arg1,arg2]) => optimize realOf (GteqReal_Const_1, GteqReal_Const_2) (arg1, arg2)
        | ("gteqWord", [arg1,arg2]) => optimize wordOf (GteqWord_Const_1, GteqWord_Const_2) (arg1, arg2)
        | ("gteqByte", [arg1,arg2]) => optimize wordOf (GteqByte_Const_1, GteqByte_Const_2) (arg1, arg2)
        | ("gteqChar", [arg1,arg2]) => optimize charOf (GteqChar_Const_1, GteqChar_Const_2) (arg1, arg2)

        | ("Word_andb", [arg1,arg2]) => optimize wordOf (Word_andb_Const_1, Word_andb_Const_2) (arg1, arg2)
        | ("Word_orb", [arg1,arg2]) => optimize wordOf (Word_orb_Const_1, Word_orb_Const_2) (arg1, arg2)
        | ("Word_xorb", [arg1,arg2]) => optimize wordOf (Word_xorb_Const_1, Word_xorb_Const_2) (arg1, arg2)
        | ("Word_leftShift", [arg1,arg2]) => 
          optimize wordOf (Word_leftShift_Const_1, Word_leftShift_Const_2) (arg1, arg2)
        | ("Word_logicalRightShift", [arg1,arg2]) => 
          optimize wordOf (Word_logicalRightShift_Const_1, Word_logicalRightShift_Const_2) (arg1, arg2)
        | ("Word_arithmeticRightShift", [arg1,arg2]) => 
          optimize wordOf (Word_arithmeticRightShift_Const_1, Word_arithmeticRightShift_Const_2) (arg1, arg2)

        | _ => instruction
      end
    | optimizeCallPrim constMap instruction = raise Control.Bug "CallPrim is expected"


  fun optimizeInstructions constMap L [] = rev L
    | optimizeInstructions constMap L (instruction::rest) =
      (
       case instruction of
         LoadInt{value,destination} => 
         optimizeInstructions (addConstant constMap destination (Int value)) (instruction::L) rest
       | LoadWord{value,destination} => 
         optimizeInstructions (addConstant constMap destination (Word value)) (instruction::L) rest
       | LoadString{string,destination} => 
         optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LoadReal{value,destination} => 
         optimizeInstructions (addConstant constMap destination (Real value)) (instruction::L) rest
       | LoadFloat{value,destination} => 
         optimizeInstructions (addConstant constMap destination (Float value)) (instruction::L) rest
       | LoadChar{value,destination} => 
         optimizeInstructions (addConstant constMap destination (Char value)) (instruction::L) rest
       | LoadEmptyBlock {destination} =>
         optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Access{variableEntry,variableSize,destination} =>
         (
          case constOf constMap variableEntry of
            SOME (Int v) =>
            optimizeInstructions 
                (addConstant constMap destination (Int v)) 
                (LoadInt{value = v, destination = destination}::L)
                rest
          | SOME (Word v) =>
            optimizeInstructions 
                (addConstant constMap destination (Word v)) 
                (LoadWord{value = v, destination = destination}::L)
                rest
          | SOME (Real v) =>
            optimizeInstructions 
                (addConstant constMap destination (Real v)) 
                (LoadReal{value = v, destination = destination}::L)
                rest
          | SOME (Float v) =>
            optimizeInstructions 
                (addConstant constMap destination (Float v)) 
                (LoadFloat{value = v, destination = destination}::L)
                rest
          | SOME (Char v) =>
            optimizeInstructions 
                (addConstant constMap destination (Char v)) 
                (LoadChar{value = v, destination = destination}::L)
                rest
          | _ =>
            let
              val instruction = 
                  Access
                      {
                       variableEntry = variableEntry,
                       variableSize = optimizeSize constMap variableSize,
                       destination = destination
                      }
            in
              optimizeInstructions (ignore constMap destination) (instruction::L) rest
            end
         )
       | AccessEnv{offset,variableSize,destination} =>
         let
           val instruction = 
               AccessEnv 
                   {
                    offset = offset, 
                    variableSize = optimizeSize constMap variableSize,
                    destination = destination
                   }
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | AccessNestedEnv{nestLevel,offset,variableSize,destination} =>
         let
           val instruction = 
               if nestLevel = 0w0
               then
                 AccessEnv 
                     {
                      offset = offset, 
                      variableSize = optimizeSize constMap variableSize,
                      destination = destination
                     }
               else
                 AccessNestedEnv 
                     {
                      nestLevel = nestLevel,
                      offset = offset, 
                      variableSize = optimizeSize constMap variableSize,
                      destination = destination
                     }
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | GetField{blockEntry,fieldOffset,fieldSize,destination} =>
         let
           val instruction =
               GetField
                   {
                    blockEntry = blockEntry,
                    fieldOffset = fieldOffset,
                    fieldSize = optimizeSize constMap fieldSize,
                    destination = destination
                   }
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | GetFieldIndirect{blockEntry,fieldOffsetEntry,fieldSize,destination} =>
         let
           val instruction =
               case wordOf constMap fieldOffsetEntry of
                 SOME fieldOffset =>
                 GetField
                     {
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      destination = destination
                     }
               | NONE =>
                 GetFieldIndirect
                     {
                      blockEntry = blockEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = optimizeSize constMap fieldSize,
                      destination = destination
                     }
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | GetNestedField{nestLevel,blockEntry,fieldOffset,fieldSize,destination} =>
         let
           val instruction =
               if nestLevel = 0w0
               then
                 GetField
                     {
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      destination = destination
                     }
               else
                 GetNestedField
                     {
                      nestLevel = nestLevel,
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      destination = destination
                     }
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | GetNestedFieldIndirect{nestLevelEntry,blockEntry,fieldOffsetEntry,fieldSize,destination} =>
         let
           val instruction =
               case (wordOf constMap nestLevelEntry,wordOf constMap fieldOffsetEntry) of
                 (SOME 0w0,SOME fieldOffset) =>
                 GetField
                     {
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      destination = destination
                     }
               | (SOME 0w0, NONE) =>
                 GetFieldIndirect
                     {
                      blockEntry = blockEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = optimizeSize constMap fieldSize,
                      destination = destination
                     }
               | (SOME nestLevel, SOME fieldOffset) =>
                 GetNestedField
                     {
                      nestLevel = nestLevel,
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      destination = destination
                     }
               | _ =>
                 GetNestedFieldIndirect
                     {
                      nestLevelEntry = nestLevelEntry,
                      blockEntry = blockEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = optimizeSize constMap fieldSize,
                      destination = destination
                     }
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | SetField{blockEntry,fieldOffset,fieldSize,newValueEntry} =>
         let
           val instruction =
               SetField
                   {
                    blockEntry = blockEntry,
                    fieldOffset = fieldOffset,
                    fieldSize = optimizeSize constMap fieldSize,
                    newValueEntry = newValueEntry
                   }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | SetFieldIndirect{blockEntry,fieldOffsetEntry,fieldSize,newValueEntry} =>
         let
           val instruction =
               case wordOf constMap fieldOffsetEntry of
                 SOME fieldOffset =>
                 SetField
                     {
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      newValueEntry = newValueEntry
                     }
               | NONE =>
                 SetFieldIndirect
                     {
                      blockEntry = blockEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = optimizeSize constMap fieldSize,
                      newValueEntry = newValueEntry
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | SetNestedField{nestLevel,blockEntry,fieldOffset,fieldSize,newValueEntry} =>
         let
           val instruction =
               if nestLevel = 0w0
               then
                 SetField
                     {
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      newValueEntry = newValueEntry
                     }
               else
                 SetNestedField
                     {
                      nestLevel = nestLevel,
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      newValueEntry = newValueEntry
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | SetNestedFieldIndirect{nestLevelEntry,blockEntry,fieldOffsetEntry,fieldSize,newValueEntry} =>
         let
           val instruction =
               case (wordOf constMap nestLevelEntry,wordOf constMap fieldOffsetEntry) of
                 (SOME 0w0,SOME fieldOffset) =>
                 SetField
                     {
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      newValueEntry = newValueEntry
                     }
               | (SOME 0w0, NONE) =>
                 SetFieldIndirect
                     {
                      blockEntry = blockEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = optimizeSize constMap fieldSize,
                      newValueEntry = newValueEntry
                     }
               | (SOME nestLevel, SOME fieldOffset) =>
                 SetNestedField
                     {
                      nestLevel = nestLevel,
                      blockEntry = blockEntry,
                      fieldOffset = fieldOffset,
                      fieldSize = optimizeSize constMap fieldSize,
                      newValueEntry = newValueEntry
                     }
               | _ =>
                 SetNestedFieldIndirect
                     {
                      nestLevelEntry = nestLevelEntry,
                      blockEntry = blockEntry,
                      fieldOffsetEntry = fieldOffsetEntry,
                      fieldSize = optimizeSize constMap fieldSize,
                      newValueEntry = newValueEntry
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | CopyBlock {destination,...} =>
         optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GetGlobal{globalArrayIndex,offset,variableSize,destination} =>
         let
           val instruction = 
               GetGlobal 
                   {
                    globalArrayIndex = globalArrayIndex,
                    offset = offset,
                    variableSize = optimizeSize constMap variableSize,
                    destination = destination
                   }
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | SetGlobal{globalArrayIndex,offset,newValueEntry,variableSize} =>
         let
           val instruction = 
               SetGlobal
                   {
                    globalArrayIndex = globalArrayIndex,
                    offset = offset,
                    variableSize = optimizeSize constMap variableSize,
                    newValueEntry = newValueEntry
                   }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | InitGlobalArrayUnboxed _ =>
         optimizeInstructions constMap (instruction::L) rest
       | InitGlobalArrayBoxed _ =>
         optimizeInstructions constMap (instruction::L) rest
       | InitGlobalArrayDouble _ =>
         optimizeInstructions constMap (instruction::L) rest
       | GetEnv {destination,...} =>
         optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | CallPrim {destination,...} =>
         let
           val instruction = optimizeCallPrim constMap instruction
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | ForeignApply {destination,...} =>
         optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | RegisterCallback {destination,...} =>
         optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Apply_0 {destinations,...} =>
         optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
       | Apply_1 {closureEntry, argEntry, argSize, destinations} =>
         let
           val instruction = 
               Apply_1
                   {
                    closureEntry = closureEntry,
                    argEntry = argEntry,
                    argSize = optimizeSize constMap argSize,
                    destinations = destinations
                   }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | Apply_MS {closureEntry, argEntries, destinations} =>
         optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
       | Apply_ML {closureEntry,argEntries,lastArgSize,destinations} =>
         let
           val instruction =
               case optimizeSize constMap lastArgSize of
                 SINGLE =>
                 Apply_MS
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               | size => 
                 Apply_ML
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      lastArgSize = size,
                      destinations = destinations
                     }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | Apply_MF {closureEntry,argEntries,argSizes,destinations} =>
         let
           val instruction = 
               if List.all (fn s => s = 0w1) argSizes
               then 
                 Apply_MS
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               else
                 Apply_MF
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      argSizes = argSizes,
                      destinations = destinations
                     }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | Apply_MV {closureEntry,argEntries,argSizeEntries,destinations} =>
         let
           val instruction = 
               case computeSizeListKind constMap argSizeEntries of
                 EmptySizeList =>
                 Apply_0
                     {
                      closureEntry = closureEntry,
                      destinations = destinations
                     }
               | SingletonSizeList argSize =>
                 Apply_1
                     {
                      closureEntry = closureEntry,
                      argEntry = List.hd argEntries,
                      argSize = argSize,
                      destinations = destinations
                     }
               | SingleSizeList =>
                 Apply_MS
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               | LastArbitrarySizeList size =>
                 Apply_ML
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      lastArgSize = size,
                      destinations = destinations
                     }
               | FixedSizeList argSizes =>
                 Apply_MF
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      argSizes = argSizes,
                      destinations = destinations
                     }
               | VariantSizeList => instruction
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | TailApply_0 _ => 
         optimizeInstructions constMap (instruction::L) rest
       | TailApply_1 {closureEntry, argEntry, argSize} =>
         let
           val instruction = 
               TailApply_1
                   {
                    closureEntry = closureEntry,
                    argEntry = argEntry,
                    argSize = optimizeSize constMap argSize
                   }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | TailApply_MS _ =>
         optimizeInstructions constMap (instruction::L) rest
       | TailApply_ML {closureEntry,argEntries,lastArgSize} =>
         let
           val instruction = 
               case optimizeSize constMap lastArgSize of
                 SINGLE =>
                 TailApply_MS
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries
                     }
               | size =>
                 TailApply_ML
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      lastArgSize = size
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | TailApply_MF {closureEntry,argEntries,argSizes} =>
         let
           val instruction = 
               if List.all (fn s => s = 0w1) argSizes
               then 
                 TailApply_MS
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries
                     }
               else
                 TailApply_MF
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      argSizes = argSizes
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | TailApply_MV {closureEntry,argEntries,argSizeEntries} =>
         let
           val instruction = 
               case computeSizeListKind constMap argSizeEntries of
                 EmptySizeList =>
                 TailApply_0
                     {
                      closureEntry = closureEntry
                     }
               | SingletonSizeList argSize =>
                 TailApply_1
                     {
                      closureEntry = closureEntry,
                      argEntry = List.hd argEntries,
                      argSize = argSize
                     }
               | SingleSizeList =>
                 TailApply_MS
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries
                     }
               | LastArbitrarySizeList size =>
                 TailApply_ML
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      lastArgSize = size
                     }
               | FixedSizeList argSizes =>
                 TailApply_MF
                     {
                      closureEntry = closureEntry,
                      argEntries = argEntries,
                      argSizes = argSizes
                     }
               | VariantSizeList => instruction
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | CallStatic_0 {destinations, ...} =>
         optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
       | CallStatic_1 {entryPoint, envEntry, argEntry, argSize,destinations} =>
         let
           val instruction = 
               CallStatic_1
                   {
                    entryPoint = entryPoint,
                    envEntry = envEntry,
                    argEntry = argEntry,
                    argSize = optimizeSize constMap argSize,
                    destinations = destinations
                   }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | CallStatic_MS {entryPoint,envEntry,argEntries,destinations} =>
         optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
       | CallStatic_ML {entryPoint,envEntry,argEntries,lastArgSize,destinations} =>
         let
           val instruction = 
               case optimizeSize constMap lastArgSize of 
                 SINGLE =>
                 CallStatic_MS
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               | size =>
                 CallStatic_ML
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      lastArgSize = size,
                      destinations = destinations
                     }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | CallStatic_MF {entryPoint,envEntry,argEntries,argSizes,destinations} =>
         let
           val instruction = 
               if List.all (fn s => s = 0w1) argSizes
               then
                 CallStatic_MS
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               else
                 CallStatic_MF
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      argSizes = argSizes,
                      destinations = destinations
                     }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | CallStatic_MV {entryPoint,envEntry,argEntries,argSizeEntries,destinations} =>
         let
           val instruction = 
               case computeSizeListKind constMap argSizeEntries of
                 EmptySizeList =>
                 CallStatic_0
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      destinations = destinations
                     }
               | SingletonSizeList argSize =>
                 CallStatic_1
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntry = List.hd argEntries,
                      argSize = argSize,
                      destinations = destinations
                     }
               | SingleSizeList =>
                 CallStatic_MS
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               | LastArbitrarySizeList size =>
                 CallStatic_ML
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      lastArgSize = size,
                      destinations = destinations
                     }
               | FixedSizeList argSizes =>
                 CallStatic_MF
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      argSizes = argSizes,
                      destinations = destinations
                     }
               | VariantSizeList => instruction
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | TailCallStatic_0 _ =>
         optimizeInstructions constMap (instruction::L) rest
       | TailCallStatic_1 {entryPoint, envEntry, argEntry, argSize} =>
         let
           val instruction = 
               TailCallStatic_1
                   {
                    entryPoint = entryPoint,
                    envEntry = envEntry,
                    argEntry = argEntry,
                    argSize = optimizeSize constMap argSize
                   }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | TailCallStatic_MS _ =>
         optimizeInstructions constMap (instruction::L) rest
       | TailCallStatic_ML {entryPoint,envEntry,argEntries,lastArgSize} =>
         let
           val instruction = 
               case optimizeSize constMap lastArgSize of
                 SINGLE =>
                 TailCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries
                     }
               | size =>
                 TailCallStatic_ML
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      lastArgSize = size
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | TailCallStatic_MF {entryPoint,envEntry,argEntries,argSizes} =>
         let
           val instruction = 
               if List.all (fn s => s = 0w1) argSizes
               then
                 TailCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries
                     }
               else
                 TailCallStatic_MF
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      argSizes = argSizes
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | TailCallStatic_MV {entryPoint,envEntry,argEntries,argSizeEntries} =>
         let
           val instruction = 
               case computeSizeListKind constMap argSizeEntries of
                 EmptySizeList =>
                 TailCallStatic_0
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry
                     }
               | SingletonSizeList argSize =>
                 TailCallStatic_1
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntry = List.hd argEntries,
                      argSize = argSize
                     }
               | SingleSizeList =>
                 TailCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries
                     }
               | LastArbitrarySizeList size =>
                 TailCallStatic_ML
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      lastArgSize = size
                     }
               | FixedSizeList argSizes =>
                 TailCallStatic_MF
                     {
                      entryPoint = entryPoint,
                      envEntry = envEntry,
                      argEntries = argEntries,
                      argSizes = argSizes
                     }
               | VariantSizeList => instruction
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | RecursiveCallStatic_0 {destinations,...} =>
         optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
       | RecursiveCallStatic_1 {entryPoint,argEntry,argSize,destinations} =>
         let
           val instruction = 
               RecursiveCallStatic_1
                   {
                    entryPoint = entryPoint,
                    argEntry = argEntry,
                    argSize = optimizeSize constMap argSize,
                    destinations = destinations
                   }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | RecursiveCallStatic_MS {entryPoint,argEntries,destinations} =>
         optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
       | RecursiveCallStatic_ML {entryPoint,argEntries, lastArgSize, destinations} =>
         let
           val instruction = 
               case optimizeSize constMap lastArgSize of
                 SINGLE =>
                 RecursiveCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               | size =>
                 RecursiveCallStatic_ML
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      lastArgSize = size,
                      destinations = destinations
                     }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | RecursiveCallStatic_MF {entryPoint,argEntries, argSizes, destinations} =>
         let
           val instruction = 
               if List.all (fn s => s = 0w1) argSizes
               then
                 RecursiveCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               else
                 RecursiveCallStatic_MF
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      argSizes = argSizes,
                      destinations = destinations
                     }
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | RecursiveCallStatic_MV {entryPoint,argEntries,argSizeEntries,destinations} =>
         let
           val instruction = 
               case computeSizeListKind constMap argSizeEntries of
                 EmptySizeList =>
                 RecursiveCallStatic_0
                     {
                      entryPoint = entryPoint,
                      destinations = destinations
                     }
               | SingletonSizeList argSize =>
                 RecursiveCallStatic_1
                     {
                      entryPoint = entryPoint,
                      argEntry = List.hd argEntries,
                      argSize = argSize,
                      destinations = destinations
                     }
               | SingleSizeList =>
                 RecursiveCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      destinations = destinations
                     }
               | LastArbitrarySizeList size =>
                 RecursiveCallStatic_ML
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      lastArgSize = size,
                      destinations = destinations
                     }
               | FixedSizeList argSizes =>
                 RecursiveCallStatic_MF
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      argSizes = argSizes,
                      destinations = destinations
                     }
               | VariantSizeList => instruction
         in
           optimizeInstructions (ignoreList constMap destinations) (instruction::L) rest
         end
       | RecursiveTailCallStatic_0 _ =>
         optimizeInstructions constMap (instruction::L) rest
       | RecursiveTailCallStatic_1 {entryPoint,argEntry,argSize} =>
         let
           val instruction = 
               RecursiveTailCallStatic_1
                   {
                    entryPoint = entryPoint,
                    argEntry = argEntry,
                    argSize = optimizeSize constMap argSize
                   }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | RecursiveTailCallStatic_MS _ =>
         optimizeInstructions constMap (instruction::L) rest
       | RecursiveTailCallStatic_ML {entryPoint,argEntries, lastArgSize} =>
         let
           val instruction = 
               case optimizeSize constMap lastArgSize of
                 SINGLE =>
                 RecursiveTailCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries
                     }
               | size =>
                 RecursiveTailCallStatic_ML
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      lastArgSize = size
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | RecursiveTailCallStatic_MF {entryPoint,argEntries, argSizes} =>
         let
           val instruction = 
               if List.all (fn s => s = 0w1) argSizes
               then
                 RecursiveTailCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries
                     }
               else
                 RecursiveTailCallStatic_MF
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      argSizes = argSizes
                     }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | RecursiveTailCallStatic_MV {entryPoint,argEntries,argSizeEntries} =>
         let
           val instruction = 
               case computeSizeListKind constMap argSizeEntries of
                 EmptySizeList =>
                 RecursiveTailCallStatic_0
                     {
                      entryPoint = entryPoint
                     }
               | SingletonSizeList argSize =>
                 RecursiveTailCallStatic_1
                     {
                      entryPoint = entryPoint,
                      argEntry = List.hd argEntries,
                      argSize = argSize
                     }
               | SingleSizeList =>
                 RecursiveTailCallStatic_MS
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries
                     }
               | LastArbitrarySizeList size =>
                 RecursiveTailCallStatic_ML
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      lastArgSize = size
                     }
               | FixedSizeList argSizes =>
                 RecursiveTailCallStatic_MF
                     {
                      entryPoint = entryPoint,
                      argEntries = argEntries,
                      argSizes = argSizes
                     }
               | VariantSizeList => instruction
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | MakeBlock{bitmapEntry,sizeEntry,fieldEntries,fieldSizeEntries,destination} =>
         let
           val instruction =
               case computeSizeListKind constMap fieldSizeEntries of
                 EmptySizeList => LoadEmptyBlock {destination = destination}
               | SingletonSizeList (SINGLE) =>
                 MakeFixedSizeBlock
                     {
                      bitmapEntry = bitmapEntry,
                      size = 0w1,
                      fieldEntries = fieldEntries,
                      fieldSizes = [0w1],
                      destination = destination
                     }
               | SingletonSizeList (DOUBLE) =>
                 MakeFixedSizeBlock
                     {
                      bitmapEntry = bitmapEntry,
                      size = 0w2,
                      fieldEntries = fieldEntries,
                      fieldSizes = [0w2],
                      destination = destination
                     }
               | SingletonSizeList (VARIANT sizeEntry) =>
                 MakeBlock
                     {
                      bitmapEntry = bitmapEntry,
                      sizeEntry = sizeEntry,
                      fieldEntries = fieldEntries,
                      fieldSizeEntries = [sizeEntry],
                      destination = destination
                     }
               | SingleSizeList =>
                 MakeBlockOfSingleValues
                     {
                      bitmapEntry = bitmapEntry,
                      fieldEntries = fieldEntries,
                      destination = destination
                     }
               | LastArbitrarySizeList DOUBLE =>
                 MakeFixedSizeBlock
                     {
                      bitmapEntry = bitmapEntry,
                      size = Word32.fromInt ((List.length fieldEntries) + 1),
                      fieldEntries = fieldEntries,
                      fieldSizes = 
                      (List.tabulate ((List.length fieldEntries) - 1, (fn _ => 0w1))) @ [0w2],
                      destination = destination
                     }
               | LastArbitrarySizeList _ => instruction
               | FixedSizeList fieldSizes =>
                 MakeFixedSizeBlock
                     {
                      bitmapEntry = bitmapEntry,
                      size = foldl (fn (x,y) => x + y) 0w0 fieldSizes,
                      fieldEntries = fieldEntries,
                      fieldSizes = fieldSizes,
                      destination = destination
                     }
               | VariantSizeList => instruction
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | MakeFixedSizeBlock{bitmapEntry,size,fieldEntries,fieldSizes,destination} =>
         let
           val instruction =
               if size = 0w0 
               then 
                 LoadEmptyBlock {destination = destination}
               else
                 if size = BT.UInt32.fromInt (List.length fieldEntries)
                 then
                   MakeBlockOfSingleValues
                       {
                        bitmapEntry = bitmapEntry,
                        fieldEntries = fieldEntries,
                        destination = destination
                       }
                 else instruction
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | MakeBlockOfSingleValues {destination,...} =>
         optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | MakeArray{bitmapEntry,sizeEntry,initialValueEntry,initialValueSize,destination} =>
         let
           val instruction =
               MakeArray
                   {
                    bitmapEntry = bitmapEntry,
                    sizeEntry = sizeEntry,
                    initialValueEntry = initialValueEntry,
                    initialValueSize = optimizeSize constMap initialValueSize,
                    destination = destination
                   }
         in
           optimizeInstructions (ignore constMap destination) (instruction::L) rest
         end
       | MakeClosure {destination,...} =>
         optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Raise _ =>
         optimizeInstructions constMap (instruction::L) rest
       | PushHandler _ =>
         optimizeInstructions constMap (instruction::L) rest
       | PopHandler _ =>
         optimizeInstructions constMap (instruction::L) rest
       | Label _ =>
         optimizeInstructions constMap (instruction::L) rest
       | Location _ =>
         optimizeInstructions constMap (instruction::L) rest
       | SwitchInt _ =>
         optimizeInstructions constMap (instruction::L) rest
       | SwitchWord _ =>
         optimizeInstructions constMap (instruction::L) rest
       | SwitchString _ =>
         optimizeInstructions constMap (instruction::L) rest
       | SwitchChar _ =>
         optimizeInstructions constMap (instruction::L) rest
       | Jump _ =>
         optimizeInstructions constMap (instruction::L) rest
       | Exit =>
         optimizeInstructions constMap (instruction::L) rest
       | Return_0 =>
         optimizeInstructions constMap (instruction::L) rest
       | Return_1{variableEntry, variableSize} =>
         let
           val instruction = 
               Return_1 
                   {
                    variableEntry = variableEntry, 
                    variableSize = optimizeSize constMap variableSize
                   }
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | Return_MS _ =>
         optimizeInstructions constMap (instruction::L) rest
       | Return_ML {variableEntries, lastVariableSize} =>
         let
           val instruction = 
               case optimizeSize constMap lastVariableSize of
                 SINGLE =>
                 Return_MS {variableEntries = variableEntries}
               | size =>
                 Return_ML {variableEntries = variableEntries, lastVariableSize = size}
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | Return_MF {variableEntries, variableSizes} =>
         let
           val instruction = 
               if List.all (fn s => s = 0w1) variableSizes
               then 
                 Return_MS {variableEntries = variableEntries}
               else
                 Return_MF {variableEntries = variableEntries, variableSizes = variableSizes}
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | Return_MV {variableEntries, variableSizeEntries} =>
         let
           val instruction = 
               case computeSizeListKind constMap variableSizeEntries of
                 EmptySizeList => Return_0
               | SingletonSizeList variableSize =>
                 Return_1 {variableEntry = List.hd variableEntries, variableSize = variableSize}
               | SingleSizeList =>
                 Return_MS {variableEntries = variableEntries}
               | LastArbitrarySizeList size =>
                 Return_ML {variableEntries = variableEntries, lastVariableSize = size}
               | FixedSizeList variableSizes =>
                 Return_MF {variableEntries = variableEntries, variableSizes = variableSizes}
               | VariantSizeList => instruction
         in
           optimizeInstructions constMap (instruction::L) rest
         end
       | ConstString _ =>
         optimizeInstructions constMap (instruction::L) rest
       | AddInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | AddInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | AddWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | AddWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | AddReal_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | AddReal_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | AddByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | AddByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | SubInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | SubInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | SubWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | SubWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | SubReal_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | SubReal_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | SubByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | SubByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | MulInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | MulInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | MulWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | MulWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | MulReal_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | MulReal_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | MulByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | MulByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | DivInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | DivInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | DivWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | DivWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | DivReal_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | DivReal_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | DivByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | DivByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | ModInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | ModInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | ModWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | ModWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | ModByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | ModByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | QuotInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | QuotInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | RemInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | RemInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | LtInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtReal_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtReal_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtChar_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LtChar_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | GtInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtReal_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtReal_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtChar_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GtChar_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | LteqInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqReal_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqReal_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqChar_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | LteqChar_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | GteqInt_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqInt_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqWord_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqWord_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqReal_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqReal_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqByte_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqByte_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqChar_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | GteqChar_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest

       | Word_andb_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_andb_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_orb_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_orb_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_xorb_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_xorb_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_leftShift_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_leftShift_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_logicalRightShift_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_logicalRightShift_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_arithmeticRightShift_Const_1 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
       | Word_arithmeticRightShift_Const_2 {destination,...} =>  optimizeInstructions (ignore constMap destination) (instruction::L) rest
      )

  fun entryOfSize SINGLE = []
    | entryOfSize DOUBLE = []
    | entryOfSize (VARIANT v) = [v]

  fun analyse instruction =
      case instruction of
        LoadInt {destination,...} => ([],[destination])
      | LoadWord {destination,...} => ([],[destination])
      | LoadReal {destination,...} => ([],[destination])
      | LoadFloat {destination,...} => ([],[destination])
      | LoadString {destination,...} => ([],[destination])
      | LoadChar {destination,...} => ([],[destination])
      | LoadEmptyBlock {destination} => ([],[destination])
      | Access {variableEntry,variableSize,destination} => 
        (variableEntry::(entryOfSize variableSize),[destination])
      | AccessEnv {variableSize, destination,...} => 
        (entryOfSize variableSize,[destination])
      | AccessNestedEnv {variableSize, destination,...} => 
        (entryOfSize variableSize,[destination])
      | GetField{fieldSize,blockEntry,destination,...} =>
        (blockEntry::(entryOfSize fieldSize),[destination])
      | GetFieldIndirect{fieldOffsetEntry,fieldSize,blockEntry,destination} =>
        (fieldOffsetEntry::blockEntry::(entryOfSize fieldSize),[destination])
      | GetNestedField{fieldSize,blockEntry,destination,...} =>
        (blockEntry::(entryOfSize fieldSize),[destination])
      | GetNestedFieldIndirect{nestLevelEntry,fieldOffsetEntry,fieldSize,blockEntry,destination} =>
        (nestLevelEntry::fieldOffsetEntry::blockEntry::(entryOfSize fieldSize),[destination])
      | SetField{fieldSize,blockEntry,newValueEntry,...} =>
        (blockEntry::newValueEntry::(entryOfSize fieldSize),ALWAYS)
      | SetFieldIndirect{fieldOffsetEntry,fieldSize,blockEntry,newValueEntry} =>
        (fieldOffsetEntry::blockEntry::newValueEntry::(entryOfSize fieldSize),ALWAYS)
      | SetNestedField{fieldSize,blockEntry,newValueEntry,...} =>
        (blockEntry::newValueEntry::(entryOfSize fieldSize),ALWAYS)
      | SetNestedFieldIndirect{nestLevelEntry,fieldOffsetEntry,fieldSize,blockEntry,newValueEntry} =>
        (nestLevelEntry::fieldOffsetEntry::blockEntry::newValueEntry::(entryOfSize fieldSize),ALWAYS)
      | CopyBlock{blockEntry, nestLevelEntry,destination} => 
        ([blockEntry,nestLevelEntry],[destination])
      | GetGlobal{variableSize,destination,...} => 
        (entryOfSize variableSize,[destination])
      | SetGlobal{newValueEntry,variableSize,...} =>  
        (newValueEntry::(entryOfSize variableSize),ALWAYS)
      | InitGlobalArrayUnboxed _ => ([],ALWAYS)
      | InitGlobalArrayBoxed _ => ([],ALWAYS)
      | InitGlobalArrayDouble _ => ([],ALWAYS)
      | GetEnv{destination} => ([],[destination])
      | CallPrim{argEntries,destination,...} => 
        (argEntries,destination::ALWAYS)
      | ForeignApply{closureEntry,argEntries,destination,...} => 
        (closureEntry::argEntries,destination::ALWAYS)
      | RegisterCallback{closureEntry,destination,...} => 
        ([closureEntry],destination::ALWAYS)

      | Apply_0{closureEntry,destinations} => 
        ([closureEntry], destinations @ ALWAYS)
      | Apply_1{closureEntry,argEntry,argSize,destinations} => 
        (closureEntry::argEntry::(entryOfSize argSize), destinations @ ALWAYS)
      | Apply_MS{closureEntry,argEntries,destinations}=>
        (closureEntry::argEntries, destinations @ ALWAYS)
      | Apply_ML{closureEntry,argEntries,lastArgSize,destinations,...}=>
        ((closureEntry::argEntries) @ (entryOfSize lastArgSize), destinations @ ALWAYS)
      | Apply_MF{closureEntry,argEntries,destinations,...}=>
        (closureEntry::argEntries, destinations @ ALWAYS)
      | Apply_MV{closureEntry,argEntries,argSizeEntries,destinations,...}=>
        ((closureEntry::argEntries) @ argSizeEntries, destinations @ ALWAYS)

      | TailApply_0{closureEntry} => 
        ([closureEntry], ALWAYS)
      | TailApply_1{closureEntry,argEntry,argSize} => 
        (closureEntry::argEntry::(entryOfSize argSize), ALWAYS)
      | TailApply_MS{closureEntry,argEntries}=>
        (closureEntry::argEntries, ALWAYS)
      | TailApply_ML{closureEntry,argEntries,lastArgSize,...}=>
        ((closureEntry::argEntries) @ (entryOfSize lastArgSize), ALWAYS)
      | TailApply_MF{closureEntry,argEntries,...}=>
        (closureEntry::argEntries, ALWAYS)
      | TailApply_MV{closureEntry,argEntries,argSizeEntries,...}=>
        ((closureEntry::argEntries) @ argSizeEntries, ALWAYS)

      | CallStatic_0{envEntry,destinations,...} => 
        ([envEntry], destinations @ ALWAYS)
      | CallStatic_1{envEntry,argEntry,argSize,destinations,...} => 
        (envEntry::argEntry::(entryOfSize argSize), destinations @ ALWAYS)
      | CallStatic_MS{envEntry,argEntries,destinations,...}=>
        (envEntry::argEntries, destinations @ ALWAYS)
      | CallStatic_ML{envEntry,argEntries,lastArgSize,destinations,...}=>
        ((envEntry::argEntries) @ (entryOfSize lastArgSize), destinations @ ALWAYS)
      | CallStatic_MF{envEntry,argEntries,destinations,...}=>
        (envEntry::argEntries, destinations @ ALWAYS)
      | CallStatic_MV{envEntry,argEntries,argSizeEntries,destinations,...}=>
        ((envEntry::argEntries) @ argSizeEntries, destinations @ ALWAYS)

      | TailCallStatic_0{envEntry,...} => 
        ([envEntry], ALWAYS)
      | TailCallStatic_1{envEntry,argEntry,argSize,...} => 
        (envEntry::argEntry::(entryOfSize argSize), ALWAYS)
      | TailCallStatic_MS{envEntry,argEntries,...}=>
        (envEntry::argEntries, ALWAYS)
      | TailCallStatic_ML{envEntry,argEntries,lastArgSize,...}=>
        ((envEntry::argEntries) @ (entryOfSize lastArgSize), ALWAYS)
      | TailCallStatic_MF{envEntry,argEntries,...}=>
        (envEntry::argEntries, ALWAYS)
      | TailCallStatic_MV{envEntry,argEntries,argSizeEntries,...}=>
        ((envEntry::argEntries) @ argSizeEntries, ALWAYS)

      | RecursiveCallStatic_0{destinations,...} => 
        ([], destinations @ ALWAYS)
      | RecursiveCallStatic_1{argEntry,argSize,destinations,...} => 
        (argEntry::(entryOfSize argSize), destinations @ ALWAYS)
      | RecursiveCallStatic_MS{argEntries,destinations,...}=>
        (argEntries, destinations @ ALWAYS)
      | RecursiveCallStatic_ML{argEntries,lastArgSize,destinations,...}=>
        (argEntries @ (entryOfSize lastArgSize), destinations @ ALWAYS)
      | RecursiveCallStatic_MF{argEntries,destinations,...}=>
        (argEntries, destinations @ ALWAYS)
      | RecursiveCallStatic_MV{argEntries,argSizeEntries,destinations,...}=>
        (argEntries @ argSizeEntries, destinations @ ALWAYS)

      | RecursiveTailCallStatic_0 _ => 
        ([], ALWAYS)
      | RecursiveTailCallStatic_1{argEntry,argSize,...} => 
        (argEntry::(entryOfSize argSize), ALWAYS)
      | RecursiveTailCallStatic_MS{argEntries,...}=>
        (argEntries, ALWAYS)
      | RecursiveTailCallStatic_ML{argEntries,lastArgSize,...}=>
        (argEntries @ (entryOfSize lastArgSize), ALWAYS)
      | RecursiveTailCallStatic_MF{argEntries,...}=>
        (argEntries, ALWAYS)
      | RecursiveTailCallStatic_MV{argEntries,argSizeEntries,...}=>
        (argEntries @ argSizeEntries, ALWAYS)

      | MakeBlock{bitmapEntry,sizeEntry,fieldEntries,fieldSizeEntries,destination,...} =>
        (bitmapEntry::sizeEntry::(fieldEntries @ fieldSizeEntries),[destination])
      | MakeFixedSizeBlock{bitmapEntry,fieldEntries,destination,...} => (bitmapEntry::fieldEntries,[destination])
      | MakeBlockOfSingleValues{bitmapEntry,fieldEntries,destination,...} => (bitmapEntry::fieldEntries,[destination])
      | MakeArray{bitmapEntry,sizeEntry,initialValueEntry,initialValueSize,destination} =>
        (bitmapEntry::sizeEntry::initialValueEntry::(entryOfSize initialValueSize),[destination])
      | MakeClosure{envEntry,destination,...} => ([envEntry],[destination])
      | Raise{exceptionEntry} => ([exceptionEntry],ALWAYS)
      | PushHandler{exceptionEntry, ...} => ([exceptionEntry],ALWAYS)
      | PopHandler _ => ([],ALWAYS)
      | Label _ => ([],ALWAYS)
      | Location _ => ([],ALWAYS)
      | SwitchInt {targetEntry,...} => ([targetEntry],ALWAYS)
      | SwitchWord {targetEntry,...} => ([targetEntry],ALWAYS)
      | SwitchString {targetEntry,...} => ([targetEntry],ALWAYS)
      | SwitchChar {targetEntry,...} => ([targetEntry],ALWAYS)
      | Jump _ => ([],ALWAYS)
      | Exit => ([],ALWAYS)
      | Return_0 => ([],ALWAYS)
      | Return_1 {variableEntry,variableSize} => (variableEntry::(entryOfSize variableSize),ALWAYS)
      | Return_MS {variableEntries} => (variableEntries,ALWAYS)
      | Return_ML {variableEntries,lastVariableSize} => 
        (variableEntries @ (entryOfSize lastVariableSize),ALWAYS)
      | Return_MF {variableEntries,variableSizes} => (variableEntries,ALWAYS)
      | Return_MV {variableEntries,variableSizeEntries} => (variableEntries @ variableSizeEntries,ALWAYS)
      | ConstString _ => ([],ALWAYS)

      | AddInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | AddReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | AddWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | AddByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
        
      | SubInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | SubReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | SubWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | SubByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | MulInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | MulReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | MulWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | MulByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | DivInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | DivReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | DivWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | DivByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | ModInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | ModInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | ModWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | ModWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | ModByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | ModByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | QuotInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | QuotInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | RemInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | RemInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | LtInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtChar_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtChar_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | GtInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtChar_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtChar_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | LteqInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqChar_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqChar_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | GteqInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GteqReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GteqWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GteqByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GteqChar_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqChar_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | Word_andb_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | Word_andb_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | Word_orb_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | Word_orb_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | Word_xorb_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | Word_xorb_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | Word_leftShift_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | Word_leftShift_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | Word_logicalRightShift_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | Word_logicalRightShift_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | Word_arithmeticRightShift_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | Word_arithmeticRightShift_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])


  fun deadCodeEliminate (instruction,(entrySet,instructions)) =
      let
        fun addEntry (e,S) = EntrySet.add(S,e)
        fun useful e = EntrySet.member(entrySet, e)
        val (inputEntries,outputEntries) = analyse instruction
      in
        if List.exists useful outputEntries
        then
          (
           foldl addEntry (foldl addEntry entrySet outputEntries) inputEntries,
           instruction::instructions
          )
        else
          (
           entrySet,
           instructions
          )
      end  

  fun optimizeFunction ({name, loc, args, instructions} : functionCode) =
      let
        val newInstructions = optimizeInstructions EntryMap.empty [] instructions
        val entrySet = EntrySet.singleton(ALWAYS_Entry)
        val (entrySet,newInstructions) =
            foldr
                deadCodeEliminate
                (entrySet,[])
                newInstructions
      in
        (
         entrySet,
         {
          name = name,
          loc = loc,
          args = args,
          instructions = newInstructions
         } : functionCode
        )
      end      
        
  fun optimizeCluster ({frameInfo, functionCodes, loc} : clusterCode) =
      let
        val (entrySet,newFunctionCodesRev) =
            foldl
                (fn (C,(S,L)) =>
                    let
                      val (entrySet,code) = optimizeFunction C
                      val entrySet =
                          foldl
                              (fn (e,S) => EntrySet.add(S,e))
                              entrySet
                              (#args code)
                    in
                      (EntrySet.union(entrySet,S),code::L)
                    end
                )
                (EntrySet.empty,[])
                functionCodes
        fun removeUselessEntries L = 
            List.filter (fn e => EntrySet.member(entrySet,e)) L
        val newFrameInfo =
            {
             bitmapvals = #bitmapvals frameInfo,
             pointers = removeUselessEntries (#pointers frameInfo),
             atoms = removeUselessEntries (#atoms frameInfo),
             doubles = removeUselessEntries (#doubles frameInfo),
             records = map removeUselessEntries (#records frameInfo)
            }
      in
        {
         frameInfo = newFrameInfo,
         functionCodes = rev newFunctionCodesRev,
         loc = loc
        } : clusterCode
      end

  (********************************)

  fun optimize clusterCodes = map optimizeCluster clusterCodes
      
end
