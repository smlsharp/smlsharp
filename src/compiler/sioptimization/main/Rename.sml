(**
 * @copyright (c) 2006, Tohoku University.
 * @author Yutaka Matsuno
 * @version $Id: Rename.sml,v 1.2 2007/06/16 14:23:45 matsu Exp $
 *)


structure Rename = struct
open SymbolicInstructions
structure AUX = Aux


fun reallocate (varMap,func) = 
  let fun vmp var = case AUX.VarMap.find (varMap,var) of SOME v => v
                                                       | _ => var
      fun eOfS SINGLE = SINGLE
        | eOfS DOUBLE = DOUBLE
        | eOfS (VARIANT v) = VARIANT (vmp v) 
      fun aux p = 
          case p of [] => []
                  | (LoadInt {value, destination}) :: t  => 
                    (LoadInt {value=value, destination = vmp destination}) :: (aux t)
                  | (LoadWord   {value, destination}) :: t  => 
                    (LoadWord   {value=value, destination = vmp destination}) :: (aux t) 
                  | (LoadString {string, destination}) :: t  => 
                    (LoadString {string = string, destination = vmp destination}) :: (aux t)
                  | (LoadFloat {value,destination}) :: t => 
                    (LoadFloat {value=value,destination=vmp destination}) :: (aux t)
                  | (LoadReal   {value, destination}) :: t  =>  
                    (LoadReal   {value = value, destination = vmp destination}) :: (aux t)  
                  | (LoadChar   {value, destination}) :: t  =>  
                    (LoadChar   {value = value, destination = vmp destination}) :: (aux t)  
                  | (LoadEmptyBlock {destination}) :: t  =>
                    (LoadEmptyBlock {destination = vmp destination}) :: (aux t) 
                  
                  | (Access {variableEntry,variableSize,destination}) :: t =>  
                    (Access {variableEntry=vmp variableEntry,
                             variableSize=eOfS variableSize,
                             destination = vmp destination}) :: (aux t)   
                    
                  | (AccessEnv {destination, variableSize, offset}) :: t =>  
                    (AccessEnv {destination=vmp destination, 
                                variableSize = eOfS variableSize, 
                                offset = offset}) :: (aux t)  
                  
                  (* | (AccessEnvIndirect {destination,variableSize, offset}) :: t =>  
                       (AccessEnvIndirect {destination=vmp destination,
                                           variableSize=eOfS variableSize, 
                                                     offset=offset}) :: (aux t)  *)
                    
                  | (AccessNestedEnv {destination, variableSize, nestLevel, offset}) :: t =>  
                    (AccessNestedEnv {destination=vmp destination, 
                                      variableSize= eOfS variableSize, 
                                      nestLevel = nestLevel, 
                                      offset = offset}) :: (aux t)  
                  (*
                  | (AccessNestedEnvIndirect {destination,variableSize,nestLevel,offset}) :: t =>
                    (AccessNestedEnvIndirect {destination=vmp destination,
                                              variableSize= eOfS variableSize,
                                              nestLevel=nestLevel,
                                              offset = offset}) :: (aux t) *)
                    
                    
                  | (GetField {destination,blockEntry,fieldSize, fieldOffset}) :: t => 
                    (GetField {destination=vmp destination,
                               blockEntry=vmp blockEntry ,
                               fieldSize= eOfS fieldSize, 
                               fieldOffset = fieldOffset}) :: (aux t) 
                    
                  | (GetFieldIndirect {destination,blockEntry,fieldOffsetEntry, fieldSize}) :: t =>
                    (GetFieldIndirect {destination = vmp destination,
                                       blockEntry = vmp blockEntry,
                                       fieldOffsetEntry = vmp fieldOffsetEntry, 
                                       fieldSize = eOfS fieldSize}) :: (aux t) 
                    
                  | (GetNestedField {nestLevel, fieldOffset, fieldSize,blockEntry,destination}) :: t => 
                    (GetNestedField {nestLevel= nestLevel, 
                                     fieldOffset = fieldOffset,
                                     fieldSize = eOfS fieldSize,
                                     blockEntry= vmp blockEntry,
                                     destination= vmp destination}) :: (aux t) 
                    
                    
                  | (GetNestedFieldIndirect {nestLevelEntry, fieldOffsetEntry,destination,blockEntry,fieldSize}) :: t => 
                    (GetNestedFieldIndirect {nestLevelEntry= vmp nestLevelEntry, 
                                             fieldOffsetEntry= vmp fieldOffsetEntry,
                                             destination= vmp destination,
                                             blockEntry= vmp blockEntry,
                                             fieldSize= eOfS fieldSize }) :: (aux t) 
                    
                  | (SetField {blockEntry, newValueEntry,fieldSize,fieldOffset}) :: t =>  
                    (SetField {blockEntry= vmp blockEntry, 
                               newValueEntry= vmp newValueEntry,
                               fieldSize= eOfS fieldSize,
                               fieldOffset = fieldOffset}) :: (aux t)  
                  | (SetNestedField {nestLevel,fieldOffset,fieldSize,blockEntry,newValueEntry}) :: t => 
                    (SetNestedField {nestLevel = nestLevel,
                                     fieldOffset = fieldOffset,
                                     fieldSize = eOfS fieldSize,
                                     blockEntry = vmp blockEntry,
                                     newValueEntry = vmp newValueEntry
                    }) :: (aux t)
                  | (SetFieldIndirect {blockEntry,fieldOffsetEntry,
                                       fieldSize,newValueEntry}) :: t => 
                    (SetFieldIndirect {blockEntry = vmp blockEntry, 
                                       newValueEntry = vmp newValueEntry,
                                       fieldOffsetEntry = vmp fieldOffsetEntry,
                                       fieldSize = eOfS fieldSize}) :: (aux t) 
                    
                  | (SetNestedFieldIndirect {blockEntry, newValueEntry,nestLevelEntry,fieldOffsetEntry,fieldSize}) :: t => 
                    (SetNestedFieldIndirect {blockEntry = vmp blockEntry, 
                                             newValueEntry = vmp newValueEntry,
                                             nestLevelEntry = vmp nestLevelEntry,
                                             fieldOffsetEntry = vmp fieldOffsetEntry,
                                             fieldSize = eOfS fieldSize}) :: (aux t) 
                    
                  | (CopyBlock {nestLevelEntry,blockEntry,destination}) :: t =>  
                    (CopyBlock 
                         {
                          nestLevelEntry = vmp nestLevelEntry,
                          blockEntry= vmp blockEntry,
                          destination = vmp destination}) :: (aux t)  
                    
                  | (GetGlobal {destination,variableSize,globalArrayIndex,offset})::t =>  
                    (GetGlobal {destination= vmp destination,variableSize = eOfS variableSize,
                                globalArrayIndex = globalArrayIndex,
                                offset=offset}):: (aux t)  
                    
                  | (SetGlobal {newValueEntry,variableSize,globalArrayIndex,offset}) :: t => 
                    (SetGlobal {newValueEntry= vmp newValueEntry,
                                variableSize = eOfS variableSize,
                                globalArrayIndex=globalArrayIndex,
                                offset=offset}) :: (aux t) 
                    
                  | (h as (InitGlobalArrayUnboxed _)) :: t =>  h  :: (aux t)
                  | (h as (InitGlobalArrayBoxed _)) :: t => h :: (aux t)
                  | (h as (InitGlobalArrayDouble _)) :: t =>  h :: (aux t)
                  | (GetEnv {destination})::t => (GetEnv {destination=vmp destination})::(aux t) 
                  | (CallPrim {argEntries, destination,primitive}):: t =>  
                    (CallPrim {argEntries= map vmp argEntries, 
                               destination = vmp destination, 
                               primitive = primitive}) :: (aux t)  
                    
                  | (ForeignApply 
                         {closureEntry,switchTag,argEntries,destination,convention}):: t => 
                    (ForeignApply {closureEntry= vmp closureEntry,switchTag = switchTag, 
                                   argEntries = map vmp argEntries,
                                   destination = vmp destination,
                                   convention = convention}) :: (aux t)
                  | (RegisterCallback
                         {sizeTag,closureEntry,destination}):: t=>
                    (RegisterCallback {sizeTag=sizeTag,closureEntry=vmp closureEntry,destination=vmp destination})
                    :: (aux t)
                  | (Apply_0 {closureEntry,destinations}) :: t =>
                    (Apply_0 {closureEntry = vmp closureEntry, destinations = map vmp destinations}) :: (aux t)
                  | (Apply_1 {closureEntry,argEntry,argSize,destinations}) :: t =>
                    (Apply_1 {closureEntry = vmp closureEntry,
                              argEntry = vmp argEntry,
                              argSize = eOfS argSize,
                              destinations = map vmp destinations}) :: (aux t)
                  | (Apply_MS {closureEntry,argEntries,destinations} )::t => 
                    (Apply_MS {closureEntry= vmp closureEntry,argEntries = map vmp argEntries,
                               destinations = map vmp destinations} ) :: (aux t)
                  | (Apply_ML {closureEntry,argEntries,lastArgSize,destinations}) :: t =>
                    (Apply_ML {closureEntry = vmp closureEntry, argEntries = map vmp argEntries,
                               lastArgSize = eOfS lastArgSize, destinations = map vmp destinations}) 
                    :: (aux t)
                  | (Apply_MF {closureEntry,argEntries,destinations,argSizes} )::t => 
                    (Apply_MF {closureEntry= vmp closureEntry,argEntries = map vmp argEntries,
                               destinations = map vmp destinations, argSizes = argSizes} ) :: (aux t) 
                  | (Apply_MV {closureEntry,argEntries,argSizeEntries,destinations} ):: t => 
                    (Apply_MV {closureEntry = vmp closureEntry ,argSizeEntries = map vmp argSizeEntries,
                               destinations = map vmp destinations,argEntries = map vmp argEntries} ):: (aux t) 
                    
                  | (TailApply_0 {closureEntry}) :: t => 
                    (TailApply_0 {closureEntry = vmp closureEntry}) :: (aux t)            
                  | (TailApply_1 {closureEntry,argEntry,argSize}):: t => 
                    (TailApply_1 {closureEntry=vmp closureEntry,argEntry=vmp argEntry,argSize=eOfS argSize}) :: (aux t) 
                    
                  | (TailApply_MS {closureEntry,argEntries}):: t =>  
                    (TailApply_MS {closureEntry=vmp closureEntry,argEntries=map vmp argEntries}) :: (aux t)  
                    
                  | (TailApply_ML {closureEntry,argEntries,lastArgSize}):: t =>
                    (TailApply_ML {closureEntry=vmp closureEntry,argEntries= map vmp argEntries,
                                   lastArgSize = eOfS lastArgSize}) :: (aux t)
                    
                  | (TailApply_MF {closureEntry,argEntries,argSizes}) :: t =>
                    (TailApply_MF {closureEntry=vmp closureEntry, argEntries = map vmp argEntries
                                 , argSizes = argSizes}) :: (aux t)
                  | (TailApply_MV {closureEntry,argEntries,argSizeEntries}) :: t => 
                    (TailApply_MV {closureEntry = vmp closureEntry, argEntries = map vmp argEntries,
                                                argSizeEntries = map vmp argSizeEntries}) :: (aux t)
                  | (CallStatic_0 {entryPoint,envEntry,destinations}) :: t => 
                    (CallStatic_0 {entryPoint=entryPoint, envEntry=vmp envEntry, destinations = map vmp destinations})
                    :: (aux t)
                  | (CallStatic_1 {envEntry,argEntry,argSize,destinations,entryPoint})::t =>
                    (CallStatic_1 {envEntry= vmp envEntry,argEntry=vmp argEntry,
                                   argSize = eOfS argSize,destinations = map vmp destinations,
                                   entryPoint = entryPoint}):: (aux t)
                  | (CallStatic_MS {entryPoint,envEntry,argEntries,destinations}) :: t => 
                    (CallStatic_MS {entryPoint = entryPoint, envEntry = vmp envEntry,
                                    argEntries = map vmp argEntries, destinations = map vmp destinations}) :: (aux t)
                  | (CallStatic_ML {envEntry,argEntries,destinations,lastArgSize,entryPoint}):: t => 
                    (CallStatic_ML {envEntry= vmp envEntry,argEntries= map vmp argEntries,
                                    destinations = map vmp destinations ,lastArgSize = eOfS lastArgSize,
                                    entryPoint = entryPoint}):: (aux t) 
                    
                  | (CallStatic_MF {envEntry,argEntries,argSizes,destinations,entryPoint})::t =>  
                    (CallStatic_MF {envEntry= vmp envEntry,argEntries=map vmp argEntries,
                                    argSizes = argSizes,destinations = map vmp destinations,
                                    entryPoint= entryPoint}) :: (aux t)  
                    
                  | (CallStatic_MV {entryPoint,envEntry,argEntries,argSizeEntries,destinations}) :: t => 
                    (CallStatic_MV {entryPoint=entryPoint,envEntry=vmp envEntry,argEntries = map vmp argEntries,
                                    argSizeEntries = map vmp argSizeEntries, destinations = map vmp destinations})
                    :: (aux t)
                    
                  | (TailCallStatic_0 {entryPoint,envEntry}) :: t => 
                    (TailCallStatic_0 {entryPoint=entryPoint,envEntry=vmp envEntry}) :: (aux t)
                    
                  | (TailCallStatic_1 {envEntry,argEntry,argSize,entryPoint})::t => 
                    (TailCallStatic_1 {envEntry=vmp envEntry,argEntry=vmp argEntry,
                                       argSize= eOfS argSize ,entryPoint=entryPoint}):: (aux t) 
                  | (TailCallStatic_MS {entryPoint,envEntry,argEntries}) :: t =>
                    (TailCallStatic_MS {entryPoint=entryPoint,envEntry=vmp envEntry,
                                        argEntries = map vmp argEntries}) :: (aux t)
                  | (TailCallStatic_ML {envEntry,argEntries,lastArgSize,entryPoint})::t => 
                    (TailCallStatic_ML {envEntry=vmp envEntry,argEntries= map vmp argEntries,
                                        lastArgSize= eOfS lastArgSize,
                                        entryPoint=entryPoint})::(aux t) 
                    
                  | (TailCallStatic_MF {envEntry,argEntries,argSizes, entryPoint}):: t =>
                    (TailCallStatic_MF {envEntry=vmp envEntry,argEntries=map vmp argEntries,
                                        argSizes = argSizes,
                                        entryPoint=entryPoint}):: (aux t)
                  | (TailCallStatic_MV {envEntry,argEntries,argSizeEntries,entryPoint}):: t =>
                    (TailCallStatic_MV {envEntry=vmp envEntry,argEntries=map vmp argEntries,
                                        argSizeEntries= map vmp argSizeEntries,
                                        entryPoint=entryPoint}):: (aux t)
                  | (RecursiveCallStatic_0 {entryPoint,destinations}) :: t =>
                    (RecursiveCallStatic_0 {entryPoint = entryPoint, destinations = map vmp destinations}) :: (aux t) 
                  | (RecursiveCallStatic_1 {entryPoint,argEntry,argSize,destinations}) :: t => 
                    (RecursiveCallStatic_1 {entryPoint=entryPoint,argEntry=vmp argEntry,
                                            argSize = eOfS argSize, destinations = map vmp destinations})
                    :: (aux t)
                    
                    
                  | (RecursiveCallStatic_MS {argEntries,destinations,entryPoint}):: t => 
                    (RecursiveCallStatic_MS {argEntries=map vmp argEntries,destinations=map vmp destinations,
                                             entryPoint= entryPoint}):: (aux t) 
                    
                  | (RecursiveCallStatic_ML {entryPoint,argEntries,lastArgSize,destinations}) :: t =>
                    (RecursiveCallStatic_ML {entryPoint=entryPoint,argEntries=map vmp argEntries,
                                             lastArgSize=eOfS lastArgSize, destinations = map vmp destinations})
                    :: (aux t)
                  | (RecursiveCallStatic_MF {argEntries,argSizes,destinations,entryPoint}):: t => 
                    (RecursiveCallStatic_MF {argEntries=map vmp argEntries,argSizes = argSizes,
                                             destinations=map vmp destinations,entryPoint=entryPoint}):: (aux t) 
                  | (RecursiveCallStatic_MV {argEntries,argSizeEntries,entryPoint,destinations}):: t => 
                    (RecursiveCallStatic_MV {argEntries=map vmp argEntries,argSizeEntries =map vmp argSizeEntries,
                                             entryPoint=entryPoint,destinations = map vmp destinations}):: (aux t) 
                              
                  | (RecursiveTailCallStatic_0 {entryPoint}) :: t => 
                    (RecursiveTailCallStatic_0 {entryPoint = entryPoint}) :: (aux t)
                    
                  | (RecursiveTailCallStatic_1 {argEntry,argSize,entryPoint}):: t => 
                    (RecursiveTailCallStatic_1 {argEntry=vmp argEntry,argSize= eOfS argSize,
                                                entryPoint=entryPoint}):: (aux t) 
                    
                  | (RecursiveTailCallStatic_MS {entryPoint,argEntries}) :: t => 
                    (RecursiveTailCallStatic_MS {entryPoint=entryPoint,argEntries=map vmp argEntries}) :: (aux t)
                    
                  | (RecursiveTailCallStatic_ML {entryPoint,argEntries,lastArgSize}) :: t =>
                    (RecursiveTailCallStatic_ML {entryPoint=entryPoint,argEntries=map vmp argEntries,
                                                 lastArgSize = eOfS lastArgSize}) :: (aux t)
                    
                  | (RecursiveTailCallStatic_MF {argEntries,argSizes,entryPoint}) :: t =>
                    (RecursiveTailCallStatic_MF {argEntries=map vmp argEntries,
                                                 argSizes = argSizes,
                                                 entryPoint= entryPoint}) :: (aux t)
                  | (RecursiveTailCallStatic_MV {entryPoint,argEntries,argSizeEntries}) :: t => 
                    (RecursiveTailCallStatic_MV {entryPoint=entryPoint,argEntries = map vmp argEntries,
                                                 argSizeEntries = map vmp argSizeEntries
                                                              }) :: (aux t)
                    
                  | (MakeBlock {bitmapEntry,sizeEntry,fieldEntries,fieldSizeEntries,destination})::t  =>
                    (MakeBlock {bitmapEntry= vmp bitmapEntry,sizeEntry= vmp sizeEntry,
                                fieldEntries= map vmp fieldEntries,fieldSizeEntries= map vmp fieldSizeEntries,
                                destination= vmp destination}):: (aux t) 
                  | (MakeFixedSizeBlock {bitmapEntry,fieldEntries,fieldSizes,destination,size}) :: t =>
                    (MakeFixedSizeBlock {bitmapEntry=vmp bitmapEntry,size=size,
                                         fieldEntries = map vmp fieldEntries,
                                         fieldSizes = fieldSizes, destination = vmp destination}) :: (aux t)
                  | (MakeBlockOfSingleValues {bitmapEntry,fieldEntries,destination})::t=>
                    (MakeBlockOfSingleValues {bitmapEntry = vmp bitmapEntry,fieldEntries = map vmp fieldEntries,
                                              destination = vmp destination}) :: (aux t)
                    
                  | (MakeArray {bitmapEntry,sizeEntry,initialValueEntry,destination,initialValueSize})::t=>
                    (MakeArray {bitmapEntry= vmp bitmapEntry,sizeEntry= vmp sizeEntry,
                                initialValueEntry= vmp initialValueEntry,destination= vmp destination,
                                initialValueSize= eOfS initialValueSize}) :: (aux t)
                    
                  | (MakeClosure {envEntry,destination,entryPoint})::t => 
                    (MakeClosure {envEntry= vmp envEntry,destination= vmp destination,entryPoint=entryPoint}):: (aux t) 
                    
                  | (Raise {exceptionEntry})::t=> (Raise {exceptionEntry= vmp exceptionEntry}) :: (aux t) 
                  | (PushHandler {exceptionEntry,handlerStart,handlerEnd})::t=> 
                    (PushHandler {exceptionEntry=vmp exceptionEntry,handlerStart=handlerStart,handlerEnd=handlerEnd}):: (aux t)
                    
                  | (h as (PopHandler l)):: t => h :: (aux t) 
                  | (h as (Label _)) :: t => h :: (aux t) 
                  | (h as (Location _)) ::t => h :: (aux t)
                  | (SwitchInt {targetEntry,cases,default} ):: t=> 
                    (SwitchInt {targetEntry=vmp targetEntry,
                                             cases=cases,default=default} ):: (aux t) 
                  | (SwitchWord {targetEntry,cases,default} ):: t=> 
                    (SwitchWord {targetEntry=vmp targetEntry,
                                 cases=cases,default=default} ):: (aux t) 
                  | (SwitchChar {targetEntry,cases,default} ):: t=> 
                    (SwitchChar {targetEntry=vmp targetEntry,
                                 cases=cases,default=default} ):: (aux t) 
                  | (SwitchString {targetEntry,cases,default} ):: t=> 
                    (SwitchString {targetEntry=vmp targetEntry,
                                   cases=cases,default=default} ):: (aux t) 
                  | (h as (Jump _)) :: t=> h :: (aux t)
                  | (h as Exit) :: t => h :: (aux t)
                  | (h as Return_0) :: t => h :: (aux t)  
                  | (Return_1 {variableEntry,variableSize}) :: t => 
                    (Return_1 {variableEntry= vmp variableEntry,variableSize= eOfS variableSize}) :: (aux t)   
                  | (Return_MS {variableEntries}) :: t =>
                    (Return_MS {variableEntries = map vmp variableEntries}) :: (aux t)
                  | (Return_ML {variableEntries, lastVariableSize}) :: t =>
                    (Return_ML {variableEntries=map vmp variableEntries, lastVariableSize = eOfS lastVariableSize}) :: (aux t)
                  | (Return_MF {variableEntries, variableSizes}) :: t => 
                    (Return_MF {variableEntries=map vmp variableEntries, 
                                variableSizes= variableSizes}) :: (aux t)
                  | (Return_MV {variableEntries, variableSizeEntries}) :: t => 
                    (Return_MV {variableEntries=map vmp variableEntries, variableSizeEntries = map vmp variableSizeEntries})
                    :: (aux t)
                  | (h as (ConstString _)):: t => h :: (aux t) 
                  (*    | (FFIVal {funNameEntry,libNameEntry,destination}):: t=>
                                          (FFIVal {funNameEntry=vmp funNameEntry,
                                                   libNameEntry= vmp libNameEntry,
                                                   destination = vmp destination}):: (aux t) *)
                                                
                  | (AddInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (AddInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (AddInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (AddInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (AddReal_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (AddReal_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (AddReal_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (AddReal_Const_2  {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (AddWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (AddWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (AddWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (AddWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (AddByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (AddByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (AddByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (AddByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (SubInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (SubInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (SubInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (SubInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (SubReal_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (SubReal_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (SubReal_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (SubReal_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (SubWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (SubWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (SubWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (SubWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (SubByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (SubByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (SubByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (SubByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (MulInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (MulInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (MulInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (MulInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (MulReal_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (MulReal_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (MulReal_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (MulReal_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (MulWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (MulWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (MulWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (MulWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (MulByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (MulByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (MulByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (MulByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (DivInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (DivInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (DivInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (DivInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (DivReal_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (DivReal_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (DivReal_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (DivReal_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (DivWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (DivWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (DivWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (DivWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (DivByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (DivByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (DivByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (DivByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (ModInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (ModInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (ModInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (ModInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (ModWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (ModWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (ModWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (ModWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (ModByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (ModByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (ModByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (ModByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (QuotInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (QuotInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (QuotInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (QuotInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (RemInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (RemInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (RemInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (RemInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                    
                  | (LtInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LtInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LtInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LtInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (LtReal_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LtReal_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LtReal_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LtReal_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (LtWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LtWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LtWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LtWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (LtByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LtByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LtByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LtByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (LtChar_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LtChar_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LtChar_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LtChar_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                    
                  | (GtInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GtInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GtInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GtInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (GtReal_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GtReal_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GtReal_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GtReal_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (GtWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GtWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GtWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GtWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (GtByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GtByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GtByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GtByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (GtChar_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GtChar_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GtChar_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GtChar_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                    
                  | (LteqInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LteqInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LteqInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LteqInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (LteqReal_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LteqReal_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LteqReal_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LteqReal_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (LteqWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LteqWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LteqWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LteqWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (LteqByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LteqByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LteqByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LteqByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (LteqChar_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (LteqChar_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (LteqChar_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (LteqChar_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                    
                  | (GteqInt_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GteqInt_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GteqInt_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GteqInt_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (GteqReal_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GteqReal_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GteqReal_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GteqReal_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (GteqWord_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GteqWord_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GteqWord_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GteqWord_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (GteqByte_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GteqByte_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GteqByte_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GteqByte_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (GteqChar_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (GteqChar_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (GteqChar_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (GteqChar_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                    
                    
                  | (Word_andb_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (Word_andb_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (Word_andb_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (Word_andb_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (Word_orb_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (Word_orb_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (Word_orb_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (Word_orb_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (Word_xorb_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (Word_xorb_Const_1 {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (Word_xorb_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (Word_xorb_Const_2 {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (Word_leftShift_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (Word_leftShift_Const_1 
                         {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (Word_leftShift_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (Word_leftShift_Const_2 
                         {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (Word_logicalRightShift_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (Word_logicalRightShift_Const_1 
                         {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (Word_logicalRightShift_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (Word_logicalRightShift_Const_2 
                         {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
                  | (Word_arithmeticRightShift_Const_1 {argEntry2,destination,argValue1}):: t =>
                    (Word_arithmeticRightShift_Const_1 
                         {argEntry2=vmp argEntry2,destination=vmp destination,argValue1=argValue1}) :: (aux t)
                  | (Word_arithmeticRightShift_Const_2 {argEntry1,destination,argValue2}):: t =>
                    (Word_arithmeticRightShift_Const_2 
                         {argEntry1=vmp argEntry1,destination=vmp destination,argValue2=argValue2}) :: (aux t)
  in aux func
  end
    
end
