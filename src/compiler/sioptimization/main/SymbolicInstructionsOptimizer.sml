(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: SymbolicInstructionsOptimizer.sml,v 1.2 2006/02/28 16:11:06 kiyoshiy Exp $
 *)

structure SymbolicInstructionsOptimizer : SYMBOLIC_INSTRUCTIONS_OPTIMIZER = struct

  open SymbolicInstructions

  structure CE = CodeEnv

  datatype FunctionCallKind = 
           SingleArgument of SI.entry * SI.size
         | LastArbitraryArgument of SI.size
         | MultipleArguments

  fun optimizeSizeEntry codeEnv sizeEntry =
      case CE.wordOf(codeEnv,sizeEntry) of
        SOME 0w1 => SINGLE
      | SOME 0w2 => DOUBLE
      | _ => VARIANT sizeEntry

  fun optimizeSize codeEnv size =
      case size of 
        SINGLE => SINGLE
      | DOUBLE => DOUBLE
      | VARIANT v => optimizeSizeEntry codeEnv v


  fun lastArbitrarySize (codeEnv, []) = false
    | lastArbitrarySize (codeEnv, [sizeEntry]) = true
    | lastArbitrarySize (codeEnv, sizeEntry::rest) = 
      (
       case CE.wordOf(codeEnv,sizeEntry) of
         SOME 0w1 => lastArbitrarySize (codeEnv,rest)
       | _ => false
      )

  fun allSingleSize (codeEnv, []) = true
    | allSingleSize (codeEnv, sizeEntry :: rest) =
      (
       case CE.wordOf(codeEnv, sizeEntry) of
         SOME 0w1 => allSingleSize (codeEnv, rest)
       | _ => false
      )

  fun lastSize (codeEnv,[]) = raise Control.Bug "arguments are expected"
    | lastSize (codeEnv, [sizeEntry]) =
      (
       case CE.wordOf(codeEnv,sizeEntry) of
         SOME 0w1 => SINGLE
       | SOME 0w2 => DOUBLE
       | _ => VARIANT sizeEntry
      )
    | lastSize (codeEnv, sizeEntry::rest) = lastSize (codeEnv,rest)

  fun optimizeFunctionCall codeEnv (argEntries,argSizeEntries) =
      if !Control.doFunctionCallSpecialization 
      then
        case (argEntries,argSizeEntries) of
          ([argEntry],[argSizeEntry]) =>
          SingleArgument (argEntry,optimizeSizeEntry codeEnv argSizeEntry)
        | _ =>
          if lastArbitrarySize(codeEnv,argSizeEntries)
          then LastArbitraryArgument (lastSize(codeEnv,argSizeEntries))
          else MultipleArguments
      else MultipleArguments

  and optimizeInstructions codeEnv [] = []
    | optimizeInstructions codeEnv (instruction::rest) =
      case instruction of
        LoadInt{value,destination} => 
        instruction::(optimizeInstructions (CE.addConstant(codeEnv,destination,CE.Int value)) rest)
      | LoadWord{value,destination} => 
        instruction::(optimizeInstructions (CE.addConstant(codeEnv,destination,CE.Word value)) rest)
      | LoadString{string,destination} => 
        instruction::(optimizeInstructions codeEnv rest)
      | LoadReal{value,destination} => 
        (
         case Real64.fromString value of
           SOME real =>
           instruction::(optimizeInstructions (CE.addConstant(codeEnv,destination,CE.Real real)) rest)
         | _ => raise Control.Bug "real value is expected"
        )
      | LoadChar{value,destination} => 
        instruction::(optimizeInstructions (CE.addConstant(codeEnv,destination,CE.Char value)) rest)
      | Access{variableEntry,variableSize,destination} =>
        let
          val instruction = 
              Access
                  {
                   variableEntry = variableEntry,
                   variableSize = optimizeSize codeEnv variableSize,
                   destination = destination
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | AccessEnv{offset,variableSize,destination} =>
        let
          val instruction = 
              AccessEnv 
                  {
                   offset = offset, 
                   variableSize = optimizeSize codeEnv variableSize,
                   destination = destination
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | AccessEnvIndirect{offset,variableSize,destination} =>
        let
          val instruction = 
              AccessEnvIndirect 
                  {
                   offset = offset, 
                   variableSize = optimizeSize codeEnv variableSize,
                   destination = destination
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | AccessNestedEnv{nestLevel,offset,variableSize,destination} =>
        let
          val instruction = 
              if nestLevel = 0w0
              then
                AccessEnv 
                    {
                     offset = offset, 
                     variableSize = optimizeSize codeEnv variableSize,
                     destination = destination
                    }
              else
                AccessNestedEnv 
                    {
                     nestLevel = nestLevel,
                     offset = offset, 
                     variableSize = optimizeSize codeEnv variableSize,
                     destination = destination
                    }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | AccessNestedEnvIndirect{nestLevel,offset,variableSize,destination} =>
        let
          val instruction = 
              if nestLevel = 0w0
              then
                AccessEnvIndirect 
                    {
                     offset = offset, 
                     variableSize = optimizeSize codeEnv variableSize,
                     destination = destination
                    }
              else
                AccessNestedEnvIndirect 
                    {
                     nestLevel = nestLevel,
                     offset = offset, 
                     variableSize = optimizeSize codeEnv variableSize,
                     destination = destination
                    }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | GetField{blockEntry,fieldOffset,fieldSize,destination} =>
        let
          val instruction = 
              GetField
                  {
                   blockEntry = blockEntry,
                   fieldOffset = fieldOffset,
                   fieldSize = optimizeSize codeEnv fieldSize,
                   destination = destination
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | GetFieldIndirect{blockEntry,fieldEntry,fieldSize,destination} =>
        let
          val instruction = 
              case CE.wordOf(codeEnv,fieldEntry) of
                SOME w =>
                GetField
                    {
                     blockEntry = blockEntry,
                     fieldOffset = w,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     destination = destination
                    }
              | _ => 
                GetFieldIndirect
                    {
                     blockEntry = blockEntry,
                     fieldEntry = fieldEntry,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     destination = destination
                    }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | GetNestedFieldIndirect{nestLevelEntry,blockEntry,offsetEntry,fieldSize,destination} =>
        let
          val instruction =
              case (CE.wordOf(codeEnv,nestLevelEntry),CE.wordOf(codeEnv,offsetEntry)) of
                (SOME 0w0,SOME fieldOffset) =>
                GetField
                    {
                     blockEntry = blockEntry,
                     fieldOffset = fieldOffset,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     destination = destination
                    }
              | (SOME 0w0, NONE) =>
                GetFieldIndirect
                    {
                     blockEntry = blockEntry,
                     fieldEntry = offsetEntry,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     destination = destination
                    }
              | _ =>
                GetNestedFieldIndirect
                    {
                     nestLevelEntry = nestLevelEntry,
                     blockEntry = blockEntry,
                     offsetEntry = offsetEntry,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     destination = destination
                    }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | SetField{blockEntry,fieldOffset,fieldSize,newValueEntry} =>
        let
          val instruction = 
              SetField
                  {
                   blockEntry = blockEntry,
                   fieldOffset = fieldOffset,
                   fieldSize = optimizeSize codeEnv fieldSize,
                   newValueEntry = newValueEntry
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | SetFieldIndirect{blockEntry,fieldEntry,fieldSize,newValueEntry} =>
        let
          val instruction = 
              case CE.wordOf(codeEnv,fieldEntry) of
                SOME w =>
                SetField
                    {
                     blockEntry = blockEntry,
                     fieldOffset = w,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     newValueEntry = newValueEntry
                    }
              | _ => 
                SetFieldIndirect
                    {
                     blockEntry = blockEntry,
                     fieldEntry = fieldEntry,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     newValueEntry = newValueEntry
                    }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | SetNestedFieldIndirect{nestLevelEntry,blockEntry,offsetEntry,fieldSize,newValueEntry} =>
        let
          val instruction =
              case (CE.wordOf(codeEnv,nestLevelEntry),CE.wordOf(codeEnv,offsetEntry)) of
                (SOME 0w0,SOME fieldOffset) =>
                SetField
                    {
                     blockEntry = blockEntry,
                     fieldOffset = fieldOffset,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     newValueEntry = newValueEntry
                    }
              | (SOME 0w0, NONE) =>
                SetFieldIndirect
                    {
                     blockEntry = blockEntry,
                     fieldEntry = offsetEntry,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     newValueEntry = newValueEntry
                    }
              | _ =>
                SetNestedFieldIndirect
                    {
                     nestLevelEntry = nestLevelEntry,
                     blockEntry = blockEntry,
                     offsetEntry = offsetEntry,
                     fieldSize = optimizeSize codeEnv fieldSize,
                     newValueEntry = newValueEntry
                    }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | GetGlobal{globalArrayIndex,offset,variableSize,destination} =>
        let
          val instruction = 
              GetGlobal 
                  {
                   globalArrayIndex = globalArrayIndex,
                   offset = offset,
                   variableSize = optimizeSize codeEnv variableSize,
                   destination = destination
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | SetGlobal{globalArrayIndex,offset,newValueEntry,variableSize} =>
        let
          val instruction = 
              SetGlobal
                  {
                   globalArrayIndex = globalArrayIndex,
                   offset = offset,
                   variableSize = optimizeSize codeEnv variableSize,
                   newValueEntry = newValueEntry
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | CallPrim{primitive,argsCount,argEntries,argSizes,resultSize,destination} =>
        let
          val instruction =
              CallPrim
                  {
                   primitive = primitive,
                   argsCount = argsCount,
                   argEntries = argEntries,
                   argSizes = map (optimizeSize codeEnv) argSizes,
                   resultSize = optimizeSize codeEnv resultSize,
                   destination = destination
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | ForeignApply{closureEntry,argsCount,argEntries,argSizes,resultSize,destination} =>
        let
          val instruction =
              ForeignApply
                  {
                   closureEntry = closureEntry,
                   argsCount = argsCount,
                   argEntries = argEntries,
                   argSizes = map (optimizeSize codeEnv) argSizes,
                   resultSize = optimizeSize codeEnv resultSize,
                   destination = destination
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | Apply_M {closureEntry,argsCount,argEntries,argSizeEntries,destination} =>
        let
          val instruction = 
              case optimizeFunctionCall codeEnv (argEntries,argSizeEntries) of
                SingleArgument (argEntry,argSize) =>
                Apply_S
                    {
                     closureEntry = closureEntry,
                     argEntry = argEntry,
                     argSize = argSize,
                     destination = destination
                    }
              | LastArbitraryArgument lastArgSize =>
                Apply_ML
                    {
                     closureEntry = closureEntry,
                     argsCount = argsCount,
                     argEntries = argEntries,
                     lastArgSize = lastArgSize,
                     destination = destination
                    }
              | MultipleArguments => instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | TailApply_M {closureEntry,argsCount,argEntries,argSizeEntries} =>
        let
          val instruction = 
              case optimizeFunctionCall codeEnv (argEntries,argSizeEntries) of
                SingleArgument (argEntry,argSize) =>
                TailApply_S
                    {
                     closureEntry = closureEntry,
                     argEntry = argEntry,
                     argSize = argSize
                    }
              | LastArbitraryArgument lastArgSize =>
                TailApply_ML
                    {
                     closureEntry = closureEntry,
                     argsCount = argsCount,
                     argEntries = argEntries,
                     lastArgSize = lastArgSize
                    }
              | MultipleArguments => instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | CallStatic_M {entryPoint,envEntry,argsCount,argEntries,argSizeEntries,destination} =>
        let
          val instruction = 
              case optimizeFunctionCall codeEnv (argEntries,argSizeEntries) of
                SingleArgument (argEntry,argSize) =>
                CallStatic_S
                    {
                     entryPoint = entryPoint,
                     envEntry = envEntry,
                     argEntry = argEntry,
                     argSize = argSize,
                     destination = destination
                    }
              | LastArbitraryArgument lastArgSize =>
                CallStatic_ML
                    {
                     entryPoint = entryPoint,
                     envEntry = envEntry,
                     argsCount = argsCount,
                     argEntries = argEntries,
                     lastArgSize = lastArgSize,
                     destination = destination
                    }
              | MultipleArguments => instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | TailCallStatic_M {entryPoint,envEntry,argsCount,argEntries,argSizeEntries} =>
        let
          val instruction = 
              case optimizeFunctionCall codeEnv (argEntries,argSizeEntries) of
                SingleArgument (argEntry,argSize) =>
                TailCallStatic_S
                    {
                     entryPoint = entryPoint,
                     envEntry = envEntry,
                     argEntry = argEntry,
                     argSize = argSize
                    }
              | LastArbitraryArgument lastArgSize =>
                TailCallStatic_ML
                    {
                     entryPoint = entryPoint,
                     envEntry = envEntry,
                     argsCount = argsCount,
                     argEntries = argEntries,
                     lastArgSize = lastArgSize
                    }
              | MultipleArguments => instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | RecursiveCallStatic_M {entryPoint,argsCount,argEntries,argSizeEntries,destination} =>
        let
          val instruction = 
              case optimizeFunctionCall codeEnv (argEntries,argSizeEntries) of
                SingleArgument (argEntry,argSize) =>
                RecursiveCallStatic_S
                    {
                     entryPoint = entryPoint,
                     argEntry = argEntry,
                     argSize = argSize,
                     destination = destination
                    }
              | _ => instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | RecursiveTailCallStatic_M {entryPoint,argsCount,argEntries,argSizeEntries} =>
        let
          val instruction = 
              case optimizeFunctionCall codeEnv (argEntries,argSizeEntries) of
                SingleArgument (argEntry,argSize) =>
                RecursiveTailCallStatic_S
                    {
                     entryPoint = entryPoint,
                     argEntry = argEntry,
                     argSize = argSize
                    }
              | _ => instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | SelfRecursiveCallStatic_M {entryPoint,argsCount,argEntries,argSizeEntries,destination} =>
        let
          val instruction = 
              case optimizeFunctionCall codeEnv (argEntries,argSizeEntries) of
                SingleArgument (argEntry,argSize) =>
                SelfRecursiveCallStatic_S
                    {
                     entryPoint = entryPoint,
                     argEntry = argEntry,
                     argSize = argSize,
                     destination = destination
                    }
              | _ => instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | SelfRecursiveTailCallStatic_M {entryPoint,argsCount,argEntries,argSizeEntries} =>
        let
          val instruction = 
              case optimizeFunctionCall codeEnv (argEntries,argSizeEntries) of
                SingleArgument (argEntry,argSize) =>
                SelfRecursiveTailCallStatic_S
                    {
                     entryPoint = entryPoint,
                     argEntry = argEntry,
                     argSize = argSize
                    }
              | _ => instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | MakeBlock{bitmapEntry,sizeEntry,fieldsCount,fieldEntries,fieldSizeEntries,destination} =>
        let
          val instruction =
              if fieldsCount = 0w0 
              then 
                LoadEmptyBlock {destination = destination}
              else
                if allSingleSize(codeEnv,fieldSizeEntries)
                then
                  MakeBlockOfSingleValues
                      {
                       bitmapEntry = bitmapEntry,
                       fieldsCount = fieldsCount,
                       fieldEntries = fieldEntries,
                       destination = destination
                      }
                else instruction
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | MakeArray{bitmapEntry,sizeEntry,initialValueEntry,initialValueSize,destination} =>
        let
          val instruction =
              MakeArray
                  {
                   bitmapEntry = bitmapEntry,
                   sizeEntry = sizeEntry,
                   initialValueEntry = initialValueEntry,
                   initialValueSize = optimizeSize codeEnv initialValueSize,
                   destination = destination
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | Return {variableEntry,variableSize} =>
        let
          val instruction = 
              Return
                  {
                   variableEntry = variableEntry,
                   variableSize = optimizeSize codeEnv variableSize
                  }
        in
          instruction::(optimizeInstructions codeEnv rest)
        end
      | _ => 
        instruction::(optimizeInstructions codeEnv rest)

  val ALWAYS_Entry = {id= ID.reserve (),displayName =""}
  val ALWAYS = [ALWAYS_Entry]

  fun entryOfSize SINGLE = []
    | entryOfSize DOUBLE = []
    | entryOfSize (VARIANT v) = [v]

  fun analyse instruction =
      case instruction of
        LoadInt {destination,...} => ([],[destination])
      | LoadWord {destination,...} => ([],[destination])
      | LoadReal {destination,...} => ([],[destination])
      | LoadString {destination,...} => ([],[destination])
      | LoadChar {destination,...} => ([],[destination])
      | LoadEmptyBlock {destination} => ([],[destination])
      | Access {variableEntry,variableSize,destination} => 
        (variableEntry::(entryOfSize variableSize),[destination])
      | AccessEnv {variableSize, destination,...} => (entryOfSize variableSize,[destination])
      | AccessEnvIndirect {variableSize, destination,...} => (entryOfSize variableSize,[destination])
      | AccessNestedEnv {variableSize, destination,...} => (entryOfSize variableSize,[destination])
      | AccessNestedEnvIndirect {variableSize, destination,...} => (entryOfSize variableSize,[destination])
      | GetField{fieldSize,blockEntry,destination,...} =>
        (blockEntry::(entryOfSize fieldSize),[destination])
      | GetFieldIndirect{fieldEntry,fieldSize,blockEntry,destination} =>
        (fieldEntry::blockEntry::(entryOfSize fieldSize),[destination])
      | GetNestedFieldIndirect{nestLevelEntry,offsetEntry,fieldSize,blockEntry,destination} =>
        (nestLevelEntry::offsetEntry::blockEntry::(entryOfSize fieldSize),[destination])
      | SetField{fieldSize,blockEntry,newValueEntry,...} =>
        (blockEntry::newValueEntry::(entryOfSize fieldSize),ALWAYS)
      | SetFieldIndirect{fieldEntry,fieldSize,blockEntry,newValueEntry} =>
        (fieldEntry::blockEntry::newValueEntry::(entryOfSize fieldSize),ALWAYS)
      | SetNestedFieldIndirect{nestLevelEntry,offsetEntry,fieldSize,blockEntry,newValueEntry} =>
        (nestLevelEntry::offsetEntry::blockEntry::newValueEntry::(entryOfSize fieldSize),ALWAYS)
      | CopyBlock{blockEntry,destination} => ([blockEntry],[destination])
      | GetGlobal{variableSize,destination,...} => (entryOfSize variableSize,[destination])
      | SetGlobal{newValueEntry,variableSize,...} =>  (newValueEntry::(entryOfSize variableSize),ALWAYS)
      | InitGlobalArrayUnboxed _ => ([],ALWAYS)
      | InitGlobalArrayBoxed _ => ([],ALWAYS)
      | InitGlobalArrayDouble _ => ([],ALWAYS)
      | GetEnv{destination} => ([],[destination])
      | CallPrim{argEntries,destination,...} => (argEntries,ALWAYS)
      | ForeignApply{closureEntry,argEntries,destination,...} => (closureEntry::argEntries,ALWAYS)
      | Apply_S{closureEntry,argEntry,argSize,...} =>
        (closureEntry::argEntry::(entryOfSize argSize),ALWAYS)
      | Apply_ML{closureEntry,argEntries,lastArgSize,...} =>
        (closureEntry::((entryOfSize lastArgSize) @ argEntries),ALWAYS)
      | Apply_M{closureEntry,argEntries,argSizeEntries,...} =>
        (closureEntry::(argEntries @ argSizeEntries),ALWAYS)
      | TailApply_S{closureEntry,argEntry,argSize} =>
        (closureEntry::argEntry::(entryOfSize argSize),ALWAYS)
      | TailApply_ML{closureEntry,argEntries,lastArgSize,...} =>
        (closureEntry::((entryOfSize lastArgSize) @ argEntries),ALWAYS)
      | TailApply_M{closureEntry,argEntries,argSizeEntries,...} =>
        (closureEntry::(argEntries @ argSizeEntries),ALWAYS)
      | CallStatic_S{argEntry,argSize,...} =>
        (argEntry::(entryOfSize argSize),ALWAYS)
      | CallStatic_ML{argEntries,lastArgSize,...} =>
        (((entryOfSize lastArgSize) @ argEntries),ALWAYS)
      | CallStatic_M{argEntries,argSizeEntries,...} =>
        ((argEntries @ argSizeEntries),ALWAYS)
      | TailCallStatic_S{argEntry,argSize,...} =>
        (argEntry::(entryOfSize argSize),ALWAYS)
      | TailCallStatic_ML{argEntries,lastArgSize,...} =>
        (((entryOfSize lastArgSize) @ argEntries),ALWAYS)
      | TailCallStatic_M{argEntries,argSizeEntries,...} =>
        ((argEntries @ argSizeEntries),ALWAYS)
      | RecursiveCallStatic_S{argEntry,argSize,...} =>
        (argEntry::(entryOfSize argSize),ALWAYS)
      | RecursiveCallStatic_M{argEntries,argSizeEntries,...} =>
        ((argEntries @ argSizeEntries),ALWAYS)
      | RecursiveTailCallStatic_S{argEntry,argSize,...} =>
        (argEntry::(entryOfSize argSize),ALWAYS)
      | RecursiveTailCallStatic_M{argEntries,argSizeEntries,...} =>
        ((argEntries @ argSizeEntries),ALWAYS)
      | SelfRecursiveCallStatic_S{argEntry,argSize,...} =>
        (argEntry::(entryOfSize argSize),ALWAYS)
      | SelfRecursiveCallStatic_M{argEntries,argSizeEntries,...} =>
        ((argEntries @ argSizeEntries),ALWAYS)
      | SelfRecursiveTailCallStatic_S{argEntry,argSize,...} =>
        (argEntry::(entryOfSize argSize),ALWAYS)
      | SelfRecursiveTailCallStatic_M{argEntries,argSizeEntries,...} =>
        ((argEntries @ argSizeEntries),ALWAYS)
      | MakeBlock{bitmapEntry,sizeEntry,fieldEntries,fieldSizeEntries,destination,...} =>
        (bitmapEntry::sizeEntry::(fieldEntries @ fieldSizeEntries),[destination])
      | MakeBlockOfSingleValues{bitmapEntry,fieldEntries,destination,...} =>
        (bitmapEntry::fieldEntries,[destination])
      | MakeArray{bitmapEntry,sizeEntry,initialValueEntry,initialValueSize,destination} =>
        (bitmapEntry::sizeEntry::initialValueEntry::(entryOfSize initialValueSize),[destination])
      | MakeClosure{ENVEntry,destination,...} => ([ENVEntry],[destination])
      | Raise{exceptionEntry} => ([exceptionEntry],ALWAYS)
      | PushHandler{handler,exceptionEntry} => ([exceptionEntry],ALWAYS)
      | PopHandler => ([],ALWAYS)
      | Label _ => ([],ALWAYS)
      | Location _ => ([],ALWAYS)
      | SwitchInt {targetEntry,...} => ([targetEntry],ALWAYS)
      | SwitchWord {targetEntry,...} => ([targetEntry],ALWAYS)
      | SwitchString {targetEntry,...} => ([targetEntry],ALWAYS)
      | SwitchChar {targetEntry,...} => ([targetEntry],ALWAYS)
      | Jump _ => ([],ALWAYS)
      | Exit => ([],ALWAYS)
      | Return{variableEntry,variableSize} => (variableEntry::(entryOfSize variableSize),ALWAYS)
      | ConstString _ => ([],ALWAYS)
      | FFIVal{funNameEntry,libNameEntry,destination} => ([funNameEntry,libNameEntry],ALWAYS)

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
        val (inputEntries,outputEntries) = analyse instruction
      in
        if List.all (fn entry => EntrySet.member(entrySet,entry)) outputEntries
        then
          (
           foldl (fn (entry, S) => EntrySet.add(S,entry)) entrySet inputEntries,
           instruction::instructions
          )
        else
          (
           entrySet,
           instructions
          )
      end  

        

  (********************************)

  fun optimize ({name, funInfo, instructions, loc} : functionCode) =
      let
        val instructions' = optimizeInstructions CE.empty instructions
        val entrySet = EntrySet.singleton(ALWAYS_Entry)
        val (entrySet,instructions'') =
            foldr
                deadCodeEliminate
                (entrySet,[])
                instructions'
      in
        {
         name = name,
         funInfo = funInfo,
         instructions = instructions'',
         loc = loc
        }
      end
      
end
