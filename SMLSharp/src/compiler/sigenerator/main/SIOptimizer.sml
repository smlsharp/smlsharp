(** symbolic code optimization
 * @copyright (c) 2006, Tohoku University.
 * @author Nguyen Huu-Duc
 * @version $Id: SIOptimizer.sml,v 1.14 2008/08/06 17:23:40 ohori Exp $
 *)
structure SIOptimizer : SIOPTIMIZER = struct

  structure CTX = SIGContext
  structure BT = BasicTypes
  structure P = BuiltinPrimitive
  open SymbolicInstructions

  structure Entry_ord:ORD_KEY = struct 
  type ord_key = entry

  fun compare ({id = id1, displayName = displayName1},{id = id2, displayName = displayName2}) =
      VarID.compare(id1,id2)
  end
  
  structure EntryMap = BinaryMapMaker(Entry_ord)
  structure EntrySet = BinarySetMaker(Entry_ord)

  datatype SizeListKind =
           EmptySizeList
         | SingletonSizeList of size
         | SingleSizeList 
         | LastArbitrarySizeList of size
         | FixedSizeList of BT.UInt32 list
         | VariantSizeList 

  fun allFixedSizes context [] L = SOME (rev L)
    | allFixedSizes context (sizeEntry::rest) L =
      (
       case CTX.wordOf context sizeEntry of
         SOME w => allFixedSizes context rest (w::L)
       | NONE => NONE
      )

  fun computeSizeListKind context [] = EmptySizeList
    | computeSizeListKind context [sizeEntry] = 
      (
       case CTX.wordOf context sizeEntry of
         SOME 0w1 => SingletonSizeList SINGLE
       | SOME 0w2 => SingletonSizeList DOUBLE
       | _ => SingletonSizeList (VARIANT sizeEntry)
      )
    | computeSizeListKind context sizeEntries = 
      let
        val L = rev sizeEntries
        val sizeEntries = rev (List.tl L)
        val lastSizeEntry = List.hd L
      in
        case allFixedSizes context sizeEntries [] of
          SOME sizes => 
          (
           if List.all (fn w => w = 0w1) sizes 
           then
             case CTX.wordOf context lastSizeEntry of
               SOME 0w0 => FixedSizeList (sizes @ [0w0])
             | SOME 0w1 => SingleSizeList
             | SOME 0w2 => LastArbitrarySizeList DOUBLE
             | SOME _ => raise Control.Bug "illeagal size entry: (sigenerator/main/SIOptimizer.sml)"
             | NONE => LastArbitrarySizeList (VARIANT lastSizeEntry)
           else
             case CTX.wordOf context lastSizeEntry of
               SOME w => FixedSizeList (sizes @ [w])
             | _ => VariantSizeList
          )
        | NONE => VariantSizeList
      end

  fun optimizeCallPrim context (instruction as CallPrim {primitive, argEntries, destination}) =
      let
        val intOf = CTX.intOf context
        val wordOf = CTX.wordOf context
        fun charOf entry = 
            case CTX.charOf context entry of 
              SOME ch => SOME (Word32.fromInt (Char.ord ch))
            | NONE => NONE
        val realOf = CTX.realOf context
        val floatOf = CTX.floatOf context
        fun largeIntOf argEntry =
            case CTX.largeIntOf context argEntry
             of SOME v =>
                SOME (CTX.addStringConstant context (BigInt.toCString v))
              | NONE => NONE 

        fun optimize converter (operator1, operator2) (argEntry1, argEntry2) =
            case (converter argEntry1, converter argEntry2) of
              (SOME v, NONE) => 
              operator1 {argValue1 = v, argEntry2 = argEntry2, destination = destination}
            | (NONE, SOME v) =>
              operator2 {argEntry1 = argEntry1, argValue2 = v, destination = destination}
            | _ => instruction

      in
        case (primitive, argEntries) of
          (PRIM (P.Int_add _), [arg1,arg2]) => optimize intOf (AddInt_Const_1, AddInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_add, [arg1,arg2]) => optimize largeIntOf (AddLargeInt_Const_1, AddLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Real_add, [arg1,arg2]) => optimize realOf (AddReal_Const_1, AddReal_Const_2) (arg1, arg2)
        | (PRIM P.Float_add, [arg1,arg2]) => optimize floatOf (AddFloat_Const_1, AddFloat_Const_2) (arg1, arg2)
        | (PRIM P.Word_add, [arg1,arg2]) => optimize wordOf (AddWord_Const_1, AddWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_add, [arg1,arg2]) => optimize wordOf (AddByte_Const_1, AddByte_Const_2) (arg1, arg2)

        | (PRIM (P.Int_sub _), [arg1,arg2]) => optimize intOf (SubInt_Const_1, SubInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_sub, [arg1,arg2]) => optimize largeIntOf (SubLargeInt_Const_1, SubLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Real_sub, [arg1,arg2]) => optimize realOf (SubReal_Const_1, SubReal_Const_2) (arg1, arg2)
        | (PRIM P.Float_sub, [arg1,arg2]) => optimize floatOf (SubFloat_Const_1, SubFloat_Const_2) (arg1, arg2)
        | (PRIM P.Word_sub, [arg1,arg2]) => optimize wordOf (SubWord_Const_1, SubWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_sub, [arg1,arg2]) => optimize wordOf (SubByte_Const_1, SubByte_Const_2) (arg1, arg2)

        | (PRIM (P.Int_mul _), [arg1,arg2]) => optimize intOf (MulInt_Const_1, MulInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_mul, [arg1,arg2]) => optimize largeIntOf (MulLargeInt_Const_1, MulLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Real_mul, [arg1,arg2]) => optimize realOf (MulReal_Const_1, MulReal_Const_2) (arg1, arg2)
        | (PRIM P.Float_mul, [arg1,arg2]) => optimize floatOf (MulFloat_Const_1, MulFloat_Const_2) (arg1, arg2)
        | (PRIM P.Word_mul, [arg1,arg2]) => optimize wordOf (MulWord_Const_1, MulWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_mul, [arg1,arg2]) => optimize wordOf (MulByte_Const_1, MulByte_Const_2) (arg1, arg2)

        | (PRIM (P.Int_div _), [arg1,arg2]) => optimize intOf (DivInt_Const_1, DivInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_div, [arg1,arg2]) => optimize largeIntOf (DivLargeInt_Const_1, DivLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Real_div, [arg1,arg2]) => optimize realOf (DivReal_Const_1, DivReal_Const_2) (arg1, arg2)
        | (PRIM P.Float_div, [arg1,arg2]) => optimize floatOf (DivFloat_Const_1, DivFloat_Const_2) (arg1, arg2)
        | (PRIM P.Word_div, [arg1,arg2]) => optimize wordOf (DivWord_Const_1, DivWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_div, [arg1,arg2]) => optimize wordOf (DivByte_Const_1, DivByte_Const_2) (arg1, arg2)

        | (PRIM (P.Int_mod _), [arg1,arg2]) => optimize intOf (ModInt_Const_1, ModInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_mod, [arg1,arg2]) => optimize largeIntOf (ModLargeInt_Const_1, ModLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Word_mod, [arg1,arg2]) => optimize wordOf (ModWord_Const_1, ModWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_mod, [arg1,arg2]) => optimize wordOf (ModByte_Const_1, ModByte_Const_2) (arg1, arg2)

        | (PRIM (P.Int_quot _), [arg1,arg2]) => optimize intOf (QuotInt_Const_1, QuotInt_Const_2) (arg1, arg2)
        | (NAME "quotLargeInt", [arg1,arg2]) => optimize largeIntOf (QuotLargeInt_Const_1, QuotLargeInt_Const_2) (arg1, arg2)
        | (PRIM (P.Int_rem _), [arg1,arg2]) => optimize intOf (RemInt_Const_1, RemInt_Const_2) (arg1, arg2)
        | (NAME "remLargeInt", [arg1,arg2]) => optimize largeIntOf (RemLargeInt_Const_1, RemLargeInt_Const_2) (arg1, arg2)

        | (PRIM P.Int_lt, [arg1,arg2]) => optimize intOf (LtInt_Const_1, LtInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_lt, [arg1,arg2]) => optimize largeIntOf (LtLargeInt_Const_1, LtLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Real_lt, [arg1,arg2]) => optimize realOf (LtReal_Const_1, LtReal_Const_2) (arg1, arg2)
        | (PRIM P.Float_lt, [arg1,arg2]) => optimize floatOf (LtFloat_Const_1, LtFloat_Const_2) (arg1, arg2)
        | (PRIM P.Word_lt, [arg1,arg2]) => optimize wordOf (LtWord_Const_1, LtWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_lt, [arg1,arg2]) => optimize wordOf (LtByte_Const_1, LtByte_Const_2) (arg1, arg2)
        | (PRIM P.Char_lt, [arg1,arg2]) => optimize charOf (LtChar_Const_1, LtChar_Const_2) (arg1, arg2)

        | (PRIM P.Int_gt, [arg1,arg2]) => optimize intOf (GtInt_Const_1, GtInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_gt, [arg1,arg2]) => optimize largeIntOf (GtLargeInt_Const_1, GtLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Real_gt, [arg1,arg2]) => optimize realOf (GtReal_Const_1, GtReal_Const_2) (arg1, arg2)
        | (PRIM P.Float_gt, [arg1,arg2]) => optimize floatOf (GtFloat_Const_1, GtFloat_Const_2) (arg1, arg2)
        | (PRIM P.Word_gt, [arg1,arg2]) => optimize wordOf (GtWord_Const_1, GtWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_gt, [arg1,arg2]) => optimize wordOf (GtByte_Const_1, GtByte_Const_2) (arg1, arg2)
        | (PRIM P.Char_gt, [arg1,arg2]) => optimize charOf (GtChar_Const_1, GtChar_Const_2) (arg1, arg2)

        | (PRIM P.Int_lteq, [arg1,arg2]) => optimize intOf (LteqInt_Const_1, LteqInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_lteq, [arg1,arg2]) => optimize largeIntOf (LteqLargeInt_Const_1, LteqLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Real_lteq, [arg1,arg2]) => optimize realOf (LteqReal_Const_1, LteqReal_Const_2) (arg1, arg2)
        | (PRIM P.Float_lteq, [arg1,arg2]) => optimize floatOf (LteqFloat_Const_1, LteqFloat_Const_2) (arg1, arg2)
        | (PRIM P.Word_lteq, [arg1,arg2]) => optimize wordOf (LteqWord_Const_1, LteqWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_lteq, [arg1,arg2]) => optimize wordOf (LteqByte_Const_1, LteqByte_Const_2) (arg1, arg2)
        | (PRIM P.Char_lteq, [arg1,arg2]) => optimize charOf (LteqChar_Const_1, LteqChar_Const_2) (arg1, arg2)

        | (PRIM P.Int_gteq, [arg1,arg2]) => optimize intOf (GteqInt_Const_1, GteqInt_Const_2) (arg1, arg2)
        | (PRIM P.IntInf_gteq, [arg1,arg2]) => optimize largeIntOf (GteqLargeInt_Const_1, GteqLargeInt_Const_2) (arg1, arg2)
        | (PRIM P.Real_gteq, [arg1,arg2]) => optimize realOf (GteqReal_Const_1, GteqReal_Const_2) (arg1, arg2)
        | (PRIM P.Float_gteq, [arg1,arg2]) => optimize floatOf (GteqFloat_Const_1, GteqFloat_Const_2) (arg1, arg2)
        | (PRIM P.Word_gteq, [arg1,arg2]) => optimize wordOf (GteqWord_Const_1, GteqWord_Const_2) (arg1, arg2)
        | (PRIM P.Byte_gteq, [arg1,arg2]) => optimize wordOf (GteqByte_Const_1, GteqByte_Const_2) (arg1, arg2)
        | (PRIM P.Char_gteq, [arg1,arg2]) => optimize charOf (GteqChar_Const_1, GteqChar_Const_2) (arg1, arg2)

        | (PRIM P.Word_andb, [arg1,arg2]) => optimize wordOf (Word_andb_Const_1, Word_andb_Const_2) (arg1, arg2)
        | (PRIM P.Word_orb, [arg1,arg2]) => optimize wordOf (Word_orb_Const_1, Word_orb_Const_2) (arg1, arg2)
        | (PRIM P.Word_xorb, [arg1,arg2]) => optimize wordOf (Word_xorb_Const_1, Word_xorb_Const_2) (arg1, arg2)
        | (PRIM P.Word_lshift, [arg1,arg2]) => 
          optimize wordOf (Word_leftShift_Const_1, Word_leftShift_Const_2) (arg1, arg2)
        | (PRIM P.Word_rshift, [arg1,arg2]) => 
          optimize wordOf (Word_logicalRightShift_Const_1, Word_logicalRightShift_Const_2) (arg1, arg2)
        | (PRIM P.Word_arshift, [arg1,arg2]) => 
          optimize wordOf (Word_arithmeticRightShift_Const_1, Word_arithmeticRightShift_Const_2) (arg1, arg2)

        | _ => instruction
      end
    | optimizeCallPrim context instruction = raise Control.Bug "CallPrim is expected"


  fun optimizeInstruction context instruction = 
      case instruction of
        AccessNestedEnv{nestLevel,offset,variableSize,destination} =>
        if nestLevel = 0w0
        then
          AccessEnv 
              {
               offset = offset, 
               variableSize = variableSize,
               destination = destination
              }
        else instruction
      | GetFieldIndirect{blockEntry,fieldOffsetEntry,fieldSize,destination} =>
        (
         case CTX.wordOf context fieldOffsetEntry of
           SOME fieldOffset =>
           GetField
               {
                blockEntry = blockEntry,
                fieldOffset = fieldOffset,
                fieldSize = fieldSize,
                destination = destination
               }
         | NONE => instruction
        )
      | GetNestedField{nestLevel,blockEntry,fieldOffset,fieldSize,destination} =>
        if nestLevel = 0w0
        then
          GetField
              {
               blockEntry = blockEntry,
               fieldOffset = fieldOffset,
               fieldSize = fieldSize,
               destination = destination
              }
        else instruction
      | GetNestedFieldIndirect{nestLevelEntry,blockEntry,fieldOffsetEntry,fieldSize,destination} =>
        (
         case (CTX.wordOf context nestLevelEntry, CTX.wordOf context fieldOffsetEntry) of
           (SOME 0w0,SOME fieldOffset) =>
           GetField
               {
                blockEntry = blockEntry,
                fieldOffset = fieldOffset,
                fieldSize = fieldSize,
                destination = destination
               }
         | (SOME 0w0, NONE) =>
           GetFieldIndirect
               {
                blockEntry = blockEntry,
                fieldOffsetEntry = fieldOffsetEntry,
                fieldSize = fieldSize,
                destination = destination
               }
         | (SOME nestLevel, SOME fieldOffset) =>
           GetNestedField
               {
                nestLevel = nestLevel,
                blockEntry = blockEntry,
                fieldOffset = fieldOffset,
                fieldSize = fieldSize,
                destination = destination
               }
         | _ => instruction
        )
      | SetFieldIndirect{blockEntry,fieldOffsetEntry,fieldSize,newValueEntry} =>
        (
         case CTX.wordOf context fieldOffsetEntry of
           SOME fieldOffset =>
           SetField
               {
                blockEntry = blockEntry,
                fieldOffset = fieldOffset,
                fieldSize = fieldSize,
                newValueEntry = newValueEntry
               }
         | NONE => instruction
        )
      | SetNestedField{nestLevel,blockEntry,fieldOffset,fieldSize,newValueEntry} =>
        if nestLevel = 0w0
        then
          SetField
              {
               blockEntry = blockEntry,
               fieldOffset = fieldOffset,
               fieldSize = fieldSize,
               newValueEntry = newValueEntry
              }
        else instruction
      | SetNestedFieldIndirect{nestLevelEntry,blockEntry,fieldOffsetEntry,fieldSize,newValueEntry} =>
        (
         case (CTX.wordOf context nestLevelEntry, CTX.wordOf context fieldOffsetEntry) of
           (SOME 0w0,SOME fieldOffset) =>
           SetField
               {
                blockEntry = blockEntry,
                fieldOffset = fieldOffset,
                fieldSize = fieldSize,
                newValueEntry = newValueEntry
               }
         | (SOME 0w0, NONE) =>
           SetFieldIndirect
               {
                blockEntry = blockEntry,
                fieldOffsetEntry = fieldOffsetEntry,
                fieldSize = fieldSize,
                newValueEntry = newValueEntry
               }
         | (SOME nestLevel, SOME fieldOffset) =>
           SetNestedField
               {
                nestLevel = nestLevel,
                blockEntry = blockEntry,
                fieldOffset = fieldOffset,
                fieldSize = fieldSize,
                newValueEntry = newValueEntry
               }
         | _ => instruction
        )
      | CallPrim {destination,...} => optimizeCallPrim context instruction
      | Apply_MV {closureEntry,argEntries,argSizeEntries,destinations} =>
        (
         case computeSizeListKind context argSizeEntries of
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
        )
      | TailApply_MV {closureEntry,argEntries,argSizeEntries} =>
        (
         case computeSizeListKind context argSizeEntries of
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
        )
      | CallStatic_MV {entryPoint,envEntry,argEntries,argSizeEntries,destinations} =>
        (
         case computeSizeListKind context argSizeEntries of
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
        )
      | TailCallStatic_MV {entryPoint,envEntry,argEntries,argSizeEntries} =>
        (
         case computeSizeListKind context argSizeEntries of
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
        )
      | RecursiveCallStatic_MV {entryPoint,argEntries,argSizeEntries,destinations} =>
        (
         case computeSizeListKind context argSizeEntries of
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
        )
      | RecursiveTailCallStatic_MV {entryPoint,argEntries,argSizeEntries} =>
        (
         case computeSizeListKind context argSizeEntries of
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
        )
      | MakeBlock{bitmapEntry,sizeEntry,fieldEntries,fieldSizeEntries,destination} =>
        (
         case computeSizeListKind context fieldSizeEntries of
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
        )
      | MakeFixedSizeBlock{bitmapEntry,size,fieldEntries,fieldSizes,destination} =>
        (
         if size = 0w0 
         then LoadEmptyBlock {destination = destination}
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
        )
      | Return_MV {variableEntries, variableSizeEntries} =>
        (
         case computeSizeListKind context variableSizeEntries of
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
        )
      | _ => instruction

 
  val ALWAYS_EntryOptRef = 
      (* must be initilized at the beginning of sigeneration *)
      ref NONE : {id : VarID.id, displayName : string } option ref

  fun initialize_ALWAYS_Entry id = 
      ALWAYS_EntryOptRef := SOME {id = id, displayName = ""}

  fun get_ALWAYS_Entry () = 
      case !ALWAYS_EntryOptRef of 
          NONE => raise Control.Bug "ALWAYS_Entry is not initilized(get_ALWAYS_Entry)"
        | SOME x => x
      
  fun get_ALWAYS () = 
      case !ALWAYS_EntryOptRef of 
          NONE => raise Control.Bug "ALWAYS_Entry is not initilized(ALWAYS)"
        | SOME x => [x]

  fun entryOfSize SINGLE = []
    | entryOfSize DOUBLE = []
    | entryOfSize (VARIANT v) = [v]

  fun analyse instruction =
      case instruction of
        LoadInt {destination,...} => ([],[destination])
      | LoadLargeInt {destination,...} => ([],[destination])
      | LoadWord {destination,...} => ([],[destination])
      | LoadReal {destination,...} => ([],[destination])
      | LoadFloat {destination,...} => ([],[destination])
      | LoadString {destination,...} => ([],[destination])
      | LoadChar {destination,...} => ([],[destination])
      | LoadEmptyBlock {destination} => ([],[destination])
      | LoadAddress _ => raise Control.Bug "SIOptimizer: cannot deal with LoadAddress"
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
        (blockEntry::newValueEntry::(entryOfSize fieldSize),get_ALWAYS ())
      | SetFieldIndirect{fieldOffsetEntry,fieldSize,blockEntry,newValueEntry} =>
        (fieldOffsetEntry::blockEntry::newValueEntry::(entryOfSize fieldSize),get_ALWAYS ())
      | SetNestedField{fieldSize,blockEntry,newValueEntry,...} =>
        (blockEntry::newValueEntry::(entryOfSize fieldSize),get_ALWAYS ())
      | SetNestedFieldIndirect{nestLevelEntry,fieldOffsetEntry,fieldSize,blockEntry,newValueEntry} =>
        (nestLevelEntry::fieldOffsetEntry::blockEntry::newValueEntry::(entryOfSize fieldSize),get_ALWAYS ())
      | CopyBlock{blockEntry, nestLevelEntry,destination} => 
        ([blockEntry,nestLevelEntry],[destination])
      | CopyArray{srcEntry,srcOffsetEntry,dstEntry,dstOffsetEntry,lengthEntry,elementSize} =>
        (srcEntry::srcOffsetEntry::dstEntry::dstOffsetEntry::lengthEntry::(entryOfSize elementSize),get_ALWAYS ())
      | GetGlobal{variableSize,destination,...} => 
        (entryOfSize variableSize,[destination])
      | SetGlobal{newValueEntry,variableSize,...} =>  
        (newValueEntry::(entryOfSize variableSize),get_ALWAYS ())
      | InitGlobalArrayUnboxed _ => ([],get_ALWAYS ())
      | InitGlobalArrayBoxed _ => ([],get_ALWAYS ())
      | InitGlobalArrayDouble _ => ([],get_ALWAYS ())
      | GetEnv{destination} => ([],[destination])
      | CallPrim{argEntries,destination,...} => 
        (argEntries,destination::get_ALWAYS ())
      | ForeignApply{closureEntry,argEntries,destination,...} => 
        (closureEntry::argEntries,destination::get_ALWAYS ())
      | RegisterCallback{closureEntry,destination,...} => 
        ([closureEntry],destination::get_ALWAYS ())

      | Apply_0{closureEntry,destinations} => 
        ([closureEntry], destinations @ get_ALWAYS ())
      | Apply_1{closureEntry,argEntry,argSize,destinations} => 
        (closureEntry::argEntry::(entryOfSize argSize), destinations @ get_ALWAYS ())
      | Apply_MS{closureEntry,argEntries,destinations}=>
        (closureEntry::argEntries, destinations @ get_ALWAYS ())
      | Apply_ML{closureEntry,argEntries,lastArgSize,destinations,...}=>
        ((closureEntry::argEntries) @ (entryOfSize lastArgSize), destinations @ get_ALWAYS ())
      | Apply_MF{closureEntry,argEntries,destinations,...}=>
        (closureEntry::argEntries, destinations @ get_ALWAYS ())
      | Apply_MV{closureEntry,argEntries,argSizeEntries,destinations,...}=>
        ((closureEntry::argEntries) @ argSizeEntries, destinations @ get_ALWAYS ())

      | TailApply_0{closureEntry} => 
        ([closureEntry], get_ALWAYS ())
      | TailApply_1{closureEntry,argEntry,argSize} => 
        (closureEntry::argEntry::(entryOfSize argSize), get_ALWAYS ())
      | TailApply_MS{closureEntry,argEntries}=>
        (closureEntry::argEntries, get_ALWAYS ())
      | TailApply_ML{closureEntry,argEntries,lastArgSize,...}=>
        ((closureEntry::argEntries) @ (entryOfSize lastArgSize), get_ALWAYS ())
      | TailApply_MF{closureEntry,argEntries,...}=>
        (closureEntry::argEntries, get_ALWAYS ())
      | TailApply_MV{closureEntry,argEntries,argSizeEntries,...}=>
        ((closureEntry::argEntries) @ argSizeEntries, get_ALWAYS ())

      | CallStatic_0{envEntry,destinations,...} => 
        ([envEntry], destinations @ get_ALWAYS ())
      | CallStatic_1{envEntry,argEntry,argSize,destinations,...} => 
        (envEntry::argEntry::(entryOfSize argSize), destinations @ get_ALWAYS ())
      | CallStatic_MS{envEntry,argEntries,destinations,...}=>
        (envEntry::argEntries, destinations @ get_ALWAYS ())
      | CallStatic_ML{envEntry,argEntries,lastArgSize,destinations,...}=>
        ((envEntry::argEntries) @ (entryOfSize lastArgSize), destinations @ get_ALWAYS ())
      | CallStatic_MF{envEntry,argEntries,destinations,...}=>
        (envEntry::argEntries, destinations @ get_ALWAYS ())
      | CallStatic_MV{envEntry,argEntries,argSizeEntries,destinations,...}=>
        ((envEntry::argEntries) @ argSizeEntries, destinations @ get_ALWAYS ())

      | TailCallStatic_0{envEntry,...} => 
        ([envEntry], get_ALWAYS ())
      | TailCallStatic_1{envEntry,argEntry,argSize,...} => 
        (envEntry::argEntry::(entryOfSize argSize), get_ALWAYS ())
      | TailCallStatic_MS{envEntry,argEntries,...}=>
        (envEntry::argEntries, get_ALWAYS ())
      | TailCallStatic_ML{envEntry,argEntries,lastArgSize,...}=>
        ((envEntry::argEntries) @ (entryOfSize lastArgSize), get_ALWAYS ())
      | TailCallStatic_MF{envEntry,argEntries,...}=>
        (envEntry::argEntries, get_ALWAYS ())
      | TailCallStatic_MV{envEntry,argEntries,argSizeEntries,...}=>
        ((envEntry::argEntries) @ argSizeEntries, get_ALWAYS ())

      | RecursiveCallStatic_0{destinations,...} => 
        ([], destinations @ get_ALWAYS ())
      | RecursiveCallStatic_1{argEntry,argSize,destinations,...} => 
        (argEntry::(entryOfSize argSize), destinations @ get_ALWAYS ())
      | RecursiveCallStatic_MS{argEntries,destinations,...}=>
        (argEntries, destinations @ get_ALWAYS ())
      | RecursiveCallStatic_ML{argEntries,lastArgSize,destinations,...}=>
        (argEntries @ (entryOfSize lastArgSize), destinations @ get_ALWAYS ())
      | RecursiveCallStatic_MF{argEntries,destinations,...}=>
        (argEntries, destinations @ get_ALWAYS ())
      | RecursiveCallStatic_MV{argEntries,argSizeEntries,destinations,...}=>
        (argEntries @ argSizeEntries, destinations @ get_ALWAYS ())

      | RecursiveTailCallStatic_0 _ => 
        ([], get_ALWAYS ())
      | RecursiveTailCallStatic_1{argEntry,argSize,...} => 
        (argEntry::(entryOfSize argSize), get_ALWAYS ())
      | RecursiveTailCallStatic_MS{argEntries,...}=>
        (argEntries, get_ALWAYS ())
      | RecursiveTailCallStatic_ML{argEntries,lastArgSize,...}=>
        (argEntries @ (entryOfSize lastArgSize), get_ALWAYS ())
      | RecursiveTailCallStatic_MF{argEntries,...}=>
        (argEntries, get_ALWAYS ())
      | RecursiveTailCallStatic_MV{argEntries,argSizeEntries,...}=>
        (argEntries @ argSizeEntries, get_ALWAYS ())

      | MakeBlock{bitmapEntry,sizeEntry,fieldEntries,fieldSizeEntries,destination,...} =>
        (bitmapEntry::sizeEntry::(fieldEntries @ fieldSizeEntries),[destination])
      | MakeFixedSizeBlock{bitmapEntry,fieldEntries,destination,...} => (bitmapEntry::fieldEntries,[destination])
      | MakeBlockOfSingleValues{bitmapEntry,fieldEntries,destination,...} => (bitmapEntry::fieldEntries,[destination])
      | MakeArray{bitmapEntry,sizeEntry,initialValueEntry,initialValueSize,isMutable,destination} =>
        (bitmapEntry::sizeEntry::initialValueEntry::(entryOfSize initialValueSize),[destination])
      | MakeClosure{envEntry,destination,...} => ([envEntry],[destination])
      | Raise{exceptionEntry} => ([exceptionEntry],get_ALWAYS ())
      | PushHandler{exceptionEntry, ...} => ([exceptionEntry],get_ALWAYS ())
      | PopHandler _ => ([],get_ALWAYS ())
      | Label _ => ([],get_ALWAYS ())
      | Location _ => ([],get_ALWAYS ())
      | SwitchInt {targetEntry,...} => ([targetEntry],get_ALWAYS ())
      | SwitchLargeInt {targetEntry,...} => ([targetEntry],get_ALWAYS ())
      | SwitchWord {targetEntry,...} => ([targetEntry],get_ALWAYS ())
      | SwitchString {targetEntry,...} => ([targetEntry],get_ALWAYS ())
      | SwitchChar {targetEntry,...} => ([targetEntry],get_ALWAYS ())
      | Jump _ => ([],get_ALWAYS ())
      | IndirectJump _ => raise Control.Bug "SIOptimizer: cannot deal with IndirectJump"
      | Exit => ([],get_ALWAYS ())
      | Return_0 => ([],get_ALWAYS ())
      | Return_1 {variableEntry,variableSize} => (variableEntry::(entryOfSize variableSize),get_ALWAYS ())
      | Return_MS {variableEntries} => (variableEntries,get_ALWAYS ())
      | Return_ML {variableEntries,lastVariableSize} => 
        (variableEntries @ (entryOfSize lastVariableSize),get_ALWAYS ())
      | Return_MF {variableEntries,variableSizes} => (variableEntries,get_ALWAYS ())
      | Return_MV {variableEntries,variableSizeEntries} => (variableEntries @ variableSizeEntries,get_ALWAYS ())
      | ConstString _ => ([],get_ALWAYS ())

      | AddInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | AddLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | AddReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | AddFloat_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddFloat_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | AddWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | AddByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | AddByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
        
      | SubInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | SubLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | SubReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | SubFloat_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubFloat_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | SubWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | SubByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | SubByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | MulInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | MulLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | MulReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | MulFloat_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulFloat_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | MulWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | MulByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | MulByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | DivInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | DivLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | DivReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | DivFloat_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivFloat_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | DivWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | DivByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | DivByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | ModInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | ModInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | ModLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | ModLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | ModWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | ModWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | ModByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | ModByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | QuotInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | QuotInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | QuotLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | QuotLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | RemInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | RemInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | RemLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | RemLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | LtInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtFloat_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtFloat_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LtChar_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LtChar_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | GtInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtFloat_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtFloat_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GtChar_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GtChar_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | LteqInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqFloat_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqFloat_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqWord_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqWord_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqByte_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqByte_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | LteqChar_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | LteqChar_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])

      | GteqInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GteqLargeInt_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqLargeInt_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GteqReal_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqReal_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
      | GteqFloat_Const_1{argValue1,argEntry2,destination} => ([argEntry2],[destination])
      | GteqFloat_Const_2{argEntry1,argValue2,destination} => ([argEntry1],[destination])
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


  fun deadCodeEliminateInstruction (instruction,(entrySet,instructions)) =
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

  fun deadCodeEliminateFunction ({name, loc, args, instructions} : functionCode) =
      let
        val entrySet = EntrySet.singleton(get_ALWAYS_Entry ())
        val (entrySet,newInstructions) =
            foldr
                deadCodeEliminateInstruction
                (entrySet,[])
                instructions
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
        
  fun deadCodeEliminateCluster ({frameInfo, functionCodes, loc} : clusterCode) =
      let
        val (entrySet,newFunctionCodesRev) =
            foldl
                (fn (C,(S,L)) =>
                    let
                      val (entrySet,code) = deadCodeEliminateFunction C
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

  val deadCodeEliminate = deadCodeEliminateCluster

end
