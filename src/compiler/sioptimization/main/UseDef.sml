(**
 * @copyright (c) 2006, Tohoku University.
 * @author Yutaka Matsuno
 * @version $Id: UseDef.sml,v 1.4 2007/06/18 03:10:22 matsu Exp $
 *)


structure UseDefAnalysis = struct
open SymbolicInstructions

structure AUX = Aux 
                
                
fun entryOfSize SINGLE = []
  | entryOfSize DOUBLE = []
  | entryOfSize (VARIANT v) = [v]
                              

fun findNumbers varMap vars = valOf (AUX.VarMap.find (varMap,vars))
                              
fun def arg_map inst =
    let fun aux ins =  
            case ins of LoadInt {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LoadWord {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LoadString {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LoadFloat {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LoadReal {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LoadChar {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LoadEmptyBlock {destination} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Access {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AccessEnv {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AccessNestedEnv {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GetField {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GetFieldIndirect {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GetNestedField {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GetNestedFieldIndirect {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SetField _ => [] : int list
                      | SetFieldIndirect _  => []
                      | SetNestedField _ => []
                      | SetNestedFieldIndirect _ => []
                      | CopyBlock {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GetGlobal {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SetGlobal _ => []
                      | InitGlobalArrayUnboxed _ => []
                      | InitGlobalArrayBoxed _ => []
                      | InitGlobalArrayDouble _ => []
                      | GetEnv {destination} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | CallPrim {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | ForeignApply {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | RegisterCallback {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Apply_0 {destinations,...} => map (findNumbers arg_map) destinations
                      | Apply_1 {destinations,...} => map (findNumbers arg_map) destinations
                      | Apply_MS {destinations,...} => map (findNumbers arg_map) destinations
                      | Apply_ML {destinations,...} => map (findNumbers arg_map) destinations
                      | Apply_MF {destinations,...} => map (findNumbers arg_map) destinations
                      | Apply_MV {destinations,...} => map (findNumbers arg_map) destinations
                      | TailApply_0 _ => []
                      | TailApply_1 _ => []
                      | TailApply_MS _ => []
                      | TailApply_ML _ => []
                      | TailApply_MF _ => []
                      | TailApply_MV _ => []
                      | CallStatic_0 {destinations,...} => map (findNumbers arg_map) destinations
                      | CallStatic_1 {destinations,...} => map (findNumbers arg_map) destinations
                      | CallStatic_MS {destinations,...} => map (findNumbers arg_map) destinations
                      | CallStatic_ML {destinations,...} => map (findNumbers arg_map) destinations
                      | CallStatic_MF {destinations,...} => map (findNumbers arg_map) destinations
                      | CallStatic_MV {destinations,...} => map (findNumbers arg_map) destinations
                      | TailCallStatic_0 _ => []
                      | TailCallStatic_1 _ => []
                      | TailCallStatic_MS _ => []
                      | TailCallStatic_ML _ => []
                      | TailCallStatic_MF _ => []
                      | TailCallStatic_MV _ => []
                      | RecursiveCallStatic_0 {destinations,...} =>  map (findNumbers arg_map) destinations
                      | RecursiveCallStatic_1 {destinations,...} =>  map (findNumbers arg_map) destinations
                      | RecursiveCallStatic_MS {destinations,...} => map (findNumbers arg_map) destinations
                      | RecursiveCallStatic_ML {destinations,...} => map (findNumbers arg_map) destinations
                      | RecursiveCallStatic_MF {destinations,...} => map (findNumbers arg_map) destinations
                      | RecursiveCallStatic_MV {destinations,...} => map (findNumbers arg_map) destinations
                      | RecursiveTailCallStatic_0 _ => []
                      | RecursiveTailCallStatic_1 _ => []
                      | RecursiveTailCallStatic_MS _ => []
                      | RecursiveTailCallStatic_ML _ => []
                      | RecursiveTailCallStatic_MF _ => []
                      | RecursiveTailCallStatic_MV _ => []
                      | MakeBlock {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MakeFixedSizeBlock {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MakeBlockOfSingleValues {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))] 
                      | MakeArray {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MakeClosure {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Raise _ => []
                      | PushHandler _ => []
                      | PopHandler _ => []
                      | Label _ => []
                      | Location _ => []
                      | SwitchInt _ => []
                      | SwitchWord _ => []
                      | SwitchChar _ => []
                      | SwitchString _ => []
                      | Jump _ => []
                      | Exit => []
                      | Return_0 => []
                      | Return_1 _ => []
                      | Return_MS _ => []
                      | Return_ML _ => []
                      | Return_MF _ => []
                      | Return_MV _ => []
                      | ConstString _ => []
                      | AddInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AddInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AddReal_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AddReal_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AddWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AddWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AddByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | AddByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SubInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SubInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SubReal_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SubReal_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SubWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SubWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SubByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | SubByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MulInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MulInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MulReal_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MulReal_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MulWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MulWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MulByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | MulByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | DivInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | DivInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | DivReal_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | DivReal_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | DivWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | DivWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | DivByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | DivByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | ModInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | ModInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | ModWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | ModWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | ModByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | ModByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | QuotInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | QuotInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | RemInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | RemInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtReal_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtReal_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtChar_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LtChar_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtReal_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtReal_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtChar_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GtChar_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqReal_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqReal_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqChar_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | LteqChar_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqInt_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqInt_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqReal_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqReal_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqWord_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqWord_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqByte_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqByte_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqChar_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | GteqChar_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_andb_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_andb_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_orb_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_orb_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_xorb_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_xorb_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_leftShift_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_leftShift_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_logicalRightShift_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_logicalRightShift_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_arithmeticRightShift_Const_1 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
                      | Word_arithmeticRightShift_Const_2 {destination,...} => [valOf(AUX.VarMap.find (arg_map,destination))]
    in Vector.fromList (map aux inst)
    end 

  
  
fun use arg_map inst =
    let fun aux ins =  
            case ins of LoadInt _  => [] : int list
                      | LoadWord _ => []
                      | LoadString _ => []
                      | LoadFloat _  => []
                      | LoadReal _ => []
                      | LoadChar _ => []
                      | LoadEmptyBlock _  => []
                      | Access {variableEntry, variableSize,...} => 
                        map (findNumbers arg_map) (variableEntry :: (entryOfSize variableSize))
                      | AccessEnv {variableSize,...} => map (findNumbers arg_map) (entryOfSize variableSize)
                      | AccessNestedEnv {variableSize,...} => map (findNumbers arg_map) (entryOfSize variableSize)
                      | GetField {fieldSize,blockEntry,...} => map (findNumbers arg_map) (blockEntry :: (entryOfSize fieldSize))
                      | GetFieldIndirect {fieldOffsetEntry,fieldSize,blockEntry,...} 
                        => map (findNumbers arg_map) 
                               ([fieldOffsetEntry,blockEntry] @ (entryOfSize fieldSize))
                      | GetNestedField {fieldSize,blockEntry,...} => map (findNumbers arg_map) (blockEntry :: (entryOfSize fieldSize))
                      | GetNestedFieldIndirect {nestLevelEntry,fieldOffsetEntry,fieldSize,blockEntry,...} => 
                        map (findNumbers arg_map) 
                            ([nestLevelEntry,fieldOffsetEntry,blockEntry] @ (entryOfSize fieldSize))
                      | SetField {fieldSize,blockEntry,newValueEntry,...} => 
                        map (findNumbers arg_map) ([blockEntry,newValueEntry] @ (entryOfSize fieldSize))
                      | SetFieldIndirect {fieldOffsetEntry,fieldSize,blockEntry,newValueEntry}  => 
                        map (findNumbers arg_map) ([blockEntry,newValueEntry,fieldOffsetEntry] @ (entryOfSize fieldSize))
                      | SetNestedField {fieldSize,blockEntry,newValueEntry,...} => 
                        map (findNumbers arg_map) ([blockEntry,newValueEntry] @ (entryOfSize fieldSize))
                      | SetNestedFieldIndirect {nestLevelEntry,fieldOffsetEntry,fieldSize,blockEntry,newValueEntry} => 
                        map (findNumbers arg_map) ([nestLevelEntry,fieldOffsetEntry,blockEntry,newValueEntry] @ (entryOfSize fieldSize))
                      | CopyBlock {blockEntry,nestLevelEntry,...} => map (findNumbers arg_map) [blockEntry,nestLevelEntry]
                      | GetGlobal {variableSize,...} => map (findNumbers arg_map) (entryOfSize variableSize)
                      | SetGlobal {newValueEntry,variableSize,...} => map (findNumbers arg_map) (newValueEntry :: 
                                                                                                 (entryOfSize variableSize))
                      | InitGlobalArrayUnboxed _ => []
                      | InitGlobalArrayBoxed _ => []
                      | InitGlobalArrayDouble _ => []
                      | GetEnv _ => []
                      | CallPrim {argEntries,...} => map (findNumbers arg_map) (argEntries)
                      | ForeignApply {closureEntry,argEntries,...} => map (findNumbers arg_map) (closureEntry :: argEntries)
                      | RegisterCallback {closureEntry,...} => [valOf(AUX.VarMap.find (arg_map,closureEntry))]
                      | Apply_0 {closureEntry,...} => [valOf(AUX.VarMap.find (arg_map,closureEntry))]
                      | Apply_1 {closureEntry,argEntry,argSize,...} => 
                        map (findNumbers arg_map) ([closureEntry,argEntry] @ (entryOfSize argSize))
                      | Apply_MS {closureEntry,argEntries,...} => map (findNumbers arg_map) (closureEntry :: argEntries)
                      | Apply_ML {closureEntry,argEntries,lastArgSize,...} => 
                        map (findNumbers arg_map) (closureEntry::argEntries  @ (entryOfSize lastArgSize))
                      | Apply_MF {closureEntry,argEntries,...} => 
                        map (findNumbers arg_map) (closureEntry::argEntries)
                      | Apply_MV {closureEntry,argEntries,argSizeEntries,...} => 
                        map (findNumbers arg_map) (closureEntry :: argEntries @ argSizeEntries)
                      | TailApply_0 {closureEntry} => [valOf(AUX.VarMap.find (arg_map,closureEntry))]
                      | TailApply_1 {closureEntry,argEntry,argSize} => 
                        map (findNumbers arg_map) ([closureEntry,argEntry] @ (entryOfSize argSize))
                      | TailApply_MS {closureEntry,argEntries} => map (findNumbers arg_map) (closureEntry :: argEntries)
                      | TailApply_ML {closureEntry,argEntries,lastArgSize} => 
                        map (findNumbers arg_map) (closureEntry::argEntries  @ (entryOfSize lastArgSize))
                      | TailApply_MF {closureEntry,argEntries,...} => 
                        map (findNumbers arg_map) (closureEntry::argEntries)
                      | TailApply_MV {closureEntry,argEntries,argSizeEntries} => 
                        map (findNumbers arg_map) (closureEntry :: argEntries @ argSizeEntries)
                      | CallStatic_0 {envEntry,...} => [valOf(AUX.VarMap.find (arg_map,envEntry))]
                      | CallStatic_1 {envEntry,argEntry,argSize,...} => 
                        (map (findNumbers arg_map) ([envEntry,argEntry]@(entryOfSize argSize)))
                      | CallStatic_MS {envEntry,argEntries,...} => map (findNumbers arg_map) (envEntry::argEntries)
                      | CallStatic_ML {envEntry,argEntries,lastArgSize,...} => 
                        map (findNumbers arg_map) (envEntry::argEntries @ (entryOfSize lastArgSize))
                      | CallStatic_MF {envEntry,argEntries,...} => map (findNumbers arg_map) (envEntry::argEntries)
                      | CallStatic_MV {envEntry,argEntries,argSizeEntries,...} => 
                        map (findNumbers arg_map) (envEntry :: argEntries @ argSizeEntries)
                      | TailCallStatic_0 {envEntry,...} => [valOf(AUX.VarMap.find (arg_map,envEntry))]
                      | TailCallStatic_1 {envEntry,argEntry,argSize,...} => 
                        (map (findNumbers arg_map) ([envEntry,argEntry]@(entryOfSize argSize)))
                      | TailCallStatic_MS {envEntry,argEntries,...} => map (findNumbers arg_map) (envEntry::argEntries)
                      | TailCallStatic_ML {envEntry,argEntries,lastArgSize,...} => 
                        map (findNumbers arg_map) (envEntry::argEntries @ (entryOfSize lastArgSize))
                      | TailCallStatic_MF {envEntry,argEntries,...} => map (findNumbers arg_map) (envEntry::argEntries)
                      | TailCallStatic_MV {envEntry,argEntries,argSizeEntries,...} => map (findNumbers arg_map) 
                                                                                          (envEntry :: argEntries @ argSizeEntries)
                      | RecursiveCallStatic_0 _ => []
                      | RecursiveCallStatic_1 {argEntry,argSize,...} => 
                        (map (findNumbers arg_map) (argEntry :: (entryOfSize argSize)))
                      | RecursiveCallStatic_MS {argEntries,...} => map (findNumbers arg_map) (argEntries)
                      | RecursiveCallStatic_ML {argEntries,lastArgSize,...} => 
                        map (findNumbers arg_map) (argEntries @ (entryOfSize lastArgSize))
                      | RecursiveCallStatic_MF {argEntries,...} => map (findNumbers arg_map) (argEntries)
                      | RecursiveCallStatic_MV {argEntries,argSizeEntries,...} => 
                        map (findNumbers arg_map) (argEntries @ argSizeEntries)
                      | RecursiveTailCallStatic_0 _ => []
                      | RecursiveTailCallStatic_1 {argEntry,argSize,...} => 
                        (map (findNumbers arg_map) (argEntry :: (entryOfSize argSize)))
                      | RecursiveTailCallStatic_MS {argEntries,...} => map (findNumbers arg_map) (argEntries)
                      | RecursiveTailCallStatic_ML {argEntries,lastArgSize,...} => 
                        map (findNumbers arg_map) (argEntries @ (entryOfSize lastArgSize))
                      | RecursiveTailCallStatic_MF {argEntries,...} 
                        => map (findNumbers arg_map) (argEntries)
                      | RecursiveTailCallStatic_MV {argEntries,argSizeEntries,...} 
                        => map (findNumbers arg_map) (argEntries @ argSizeEntries)
                      | MakeBlock {bitmapEntry,sizeEntry,fieldEntries,fieldSizeEntries,...} 
                        => map (findNumbers arg_map) ([bitmapEntry,sizeEntry]@fieldEntries@fieldSizeEntries) 
                      | MakeFixedSizeBlock {bitmapEntry,fieldEntries,...} => map (findNumbers arg_map) (bitmapEntry :: fieldEntries)
                      | MakeBlockOfSingleValues {fieldEntries,bitmapEntry,...} => map (findNumbers arg_map) (bitmapEntry :: fieldEntries)
                      | MakeArray {bitmapEntry,sizeEntry,initialValueEntry,initialValueSize,...} => 
                        map (findNumbers arg_map) ([bitmapEntry,sizeEntry,initialValueEntry] @  (entryOfSize initialValueSize))
                      | MakeClosure {envEntry,...} => [valOf(AUX.VarMap.find (arg_map,envEntry))]
                      | Raise {exceptionEntry} => [valOf(AUX.VarMap.find (arg_map,exceptionEntry))]
                      | PushHandler {exceptionEntry,...} => [valOf(AUX.VarMap.find (arg_map,exceptionEntry))]
                      | PopHandler _ => []
                      | Label _ => []
                      | Location _ => []
                      | SwitchInt {targetEntry,...} => [valOf(AUX.VarMap.find (arg_map,targetEntry))]
                      | SwitchWord {targetEntry,...} => [valOf(AUX.VarMap.find (arg_map,targetEntry))] 
                      | SwitchChar {targetEntry,...} => [valOf(AUX.VarMap.find (arg_map,targetEntry))] 
                      | SwitchString {targetEntry,...} => [valOf(AUX.VarMap.find (arg_map,targetEntry))] 
                      | Jump _ => []
                      | Exit => []
                      | Return_0 => []
                      | Return_1 {variableEntry,variableSize} => map (findNumbers arg_map) (variableEntry :: (entryOfSize variableSize))
                      | Return_MS {variableEntries} => map (findNumbers arg_map) (variableEntries)
                      | Return_ML {variableEntries,lastVariableSize} 
                        => map (findNumbers arg_map) (variableEntries @ (entryOfSize lastVariableSize))
                      | Return_MF {variableEntries,...} => map (findNumbers arg_map) (variableEntries)
                      | Return_MV {variableEntries,variableSizeEntries} 
                        => map (findNumbers arg_map) (variableEntries @ variableSizeEntries)
                      | ConstString _ => []
                      | AddInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | AddInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | AddReal_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | AddReal_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | AddWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | AddWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | AddByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | AddByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | SubInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | SubInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | SubReal_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | SubReal_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | SubWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | SubWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | SubByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | SubByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | MulInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | MulInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | MulReal_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | MulReal_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | MulWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | MulWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | MulByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | MulByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | DivInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | DivInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | DivReal_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | DivReal_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | DivWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | DivWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | DivByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | DivByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | ModInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | ModInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | ModWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | ModWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | ModByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | ModByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | QuotInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | QuotInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | RemInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | RemInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LtInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LtInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LtReal_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LtReal_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LtWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LtWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LtByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LtByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LtChar_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LtChar_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GtInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GtInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GtReal_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GtReal_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GtWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GtWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GtByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GtByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GtChar_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GtChar_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LteqInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LteqInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LteqReal_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LteqReal_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LteqWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LteqWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LteqByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LteqByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | LteqChar_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | LteqChar_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GteqInt_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GteqInt_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GteqReal_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GteqReal_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GteqWord_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GteqWord_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GteqByte_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GteqByte_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | GteqChar_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | GteqChar_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | Word_andb_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | Word_andb_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | Word_orb_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | Word_orb_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | Word_xorb_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | Word_xorb_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | Word_leftShift_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | Word_leftShift_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | Word_logicalRightShift_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | Word_logicalRightShift_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
                      | Word_arithmeticRightShift_Const_1 {argEntry2,...} => [valOf(AUX.VarMap.find (arg_map,argEntry2))]
                      | Word_arithmeticRightShift_Const_2 {argEntry1,...} => [valOf(AUX.VarMap.find (arg_map,argEntry1))]
    in Vector.fromList (map aux inst) 
    end


end
