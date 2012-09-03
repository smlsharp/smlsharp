(**
 * This module calculates the size of instruction in words.
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu Duc
 * @version $Id: InstructionSizeCalculator.sml,v 1.33 2007/06/20 06:50:41 kiyoshiy Exp $
 *)
structure InstructionSizeCalculator : INSTRUCTION_SIZE_CALCULATOR =
struct

  (***************************************************************************)

  structure AI = AllocationInfo
  structure BT = BasicTypes
  structure P = Primitives
  structure SI = SymbolicInstructions

  fun length L = BT.UInt32.fromInt(List.length L)

  (**
   *  Calculates the size of instruction in its binary form.
   * The size of opcode is included.
   * 
   * @params instruction
   * @param instruction the instruction
   * @return the number of 32bit words the instruction occupies in its
   *       binary form
   *)
  fun wordsOfInstruction instruction =
      case instruction of
        SI.LoadInt _ => 0w3 : BT.UInt32
      | SI.LoadWord _ => 0w3
      | SI.LoadString {string, ...} => 0w3
      | SI.LoadFloat _ => 0w3
      | SI.LoadReal _ => 0w4
      | SI.LoadChar _ => 0w3
      | SI.LoadEmptyBlock _ => 0w2

      | SI.Access {variableSize = SI.SINGLE,...} => 0w3
      | SI.Access {variableSize = SI.DOUBLE,...} => 0w3
      | SI.Access {variableSize = SI.VARIANT _,...} => 0w4

      | SI.AccessEnv {variableSize = SI.SINGLE,...} => 0w3
      | SI.AccessEnv {variableSize = SI.DOUBLE,...} => 0w3
      | SI.AccessEnv {variableSize = SI.VARIANT v,...} => 0w4

      | SI.AccessNestedEnv {variableSize = SI.SINGLE,...} => 0w4
      | SI.AccessNestedEnv {variableSize = SI.DOUBLE,...} => 0w4
      | SI.AccessNestedEnv {variableSize = SI.VARIANT v,...} => 0w5

      | SI.GetField {fieldSize = SI.SINGLE,...} => 0w4
      | SI.GetField {fieldSize = SI.DOUBLE,...} => 0w4
      | SI.GetField {fieldSize = SI.VARIANT v,...} => 0w5

      | SI.GetFieldIndirect {fieldSize = SI.SINGLE,...} => 0w4
      | SI.GetFieldIndirect {fieldSize = SI.DOUBLE,...} => 0w4
      | SI.GetFieldIndirect {fieldSize = SI.VARIANT v,...} => 0w5

      | SI.GetNestedField {fieldSize = SI.SINGLE,...} => 0w5
      | SI.GetNestedField {fieldSize = SI.DOUBLE,...} => 0w5
      | SI.GetNestedField {fieldSize = SI.VARIANT v,...} => 0w6

      | SI.GetNestedFieldIndirect {fieldSize = SI.SINGLE,...} => 0w5
      | SI.GetNestedFieldIndirect {fieldSize = SI.DOUBLE,...} => 0w5
      | SI.GetNestedFieldIndirect {fieldSize = SI.VARIANT v,...} => 0w6

      | SI.SetField {fieldSize = SI.SINGLE,...} => 0w4
      | SI.SetField {fieldSize = SI.DOUBLE,...} => 0w4
      | SI.SetField {fieldSize = SI.VARIANT v,...} => 0w5

      | SI.SetFieldIndirect {fieldSize = SI.SINGLE,...} => 0w4
      | SI.SetFieldIndirect {fieldSize = SI.DOUBLE,...} => 0w4
      | SI.SetFieldIndirect {fieldSize = SI.VARIANT v,...} => 0w5

      | SI.SetNestedField {fieldSize = SI.SINGLE,...} => 0w5
      | SI.SetNestedField {fieldSize = SI.DOUBLE,...} => 0w5
      | SI.SetNestedField {fieldSize = SI.VARIANT v,...} => 0w6

      | SI.SetNestedFieldIndirect {fieldSize = SI.SINGLE,...} => 0w5
      | SI.SetNestedFieldIndirect {fieldSize = SI.DOUBLE,...} => 0w5
      | SI.SetNestedFieldIndirect {fieldSize = SI.VARIANT v,...} => 0w6

      | SI.CopyBlock _ => 0w4

      | SI.GetGlobal{variableSize = SI.SINGLE,...} => 0w4
      | SI.GetGlobal{variableSize = SI.DOUBLE,...} => 0w4
      | SI.GetGlobal{variableSize = SI.VARIANT v,...} => 0w5

      | SI.SetGlobal{variableSize = SI.SINGLE,...} => 0w4
      | SI.SetGlobal{variableSize = SI.DOUBLE,...} => 0w4
      | SI.SetGlobal{variableSize = SI.VARIANT v,...} => 0w5

      | SI.InitGlobalArrayUnboxed _  => 0w3
      | SI.InitGlobalArrayBoxed _  => 0w3
      | SI.InitGlobalArrayDouble _  => 0w3

      | SI.GetEnv _ => 0w2
      | SI.CallPrim {argEntries, primitive, ...} =>
        (case #instruction primitive of
           P.Internal1 _ => 0w3
         | P.Internal2 _ => 0w4
         | P.Internal3 _ => 0w5
         | P.InternalN _ => 0w3 + (length argEntries)
         | P.External _ => 0w4 + (length argEntries))
      | SI.ForeignApply {argEntries, ...} => 
           (*
             Ohori: Dec 18, 2006. the additional 0x4 is for switchTag field 
            *)
           0w6 + (length argEntries)
      | SI.RegisterCallback _ => 0w4

      | SI.Apply_0 {destinations = [],...} => 0w2
      | SI.Apply_1 {argSize = SI.SINGLE,destinations = [],...} => 0w3
      | SI.Apply_1 {argSize = SI.DOUBLE,destinations = [],...} => 0w3
      | SI.Apply_1 {argSize = SI.VARIANT v,destinations = [],...} => 0w4
      | SI.Apply_MS {argEntries, destinations = [],...} => 0w3 + (length argEntries)
      | SI.Apply_ML {argEntries, lastArgSize = SI.SINGLE, destinations = [],...} => 
        0w3 + (length argEntries)
      | SI.Apply_ML {argEntries, lastArgSize = SI.DOUBLE, destinations = [],...} => 
        0w3 + (length argEntries)
      | SI.Apply_ML {argEntries, lastArgSize = SI.VARIANT v, destinations = [],...} => 
        0w4 + (length argEntries)
      | SI.Apply_MF {argEntries, destinations = [],...} => 0w3 + (length argEntries) * 0w2
      | SI.Apply_MV {argEntries, destinations = [],...} => 0w3 + (length argEntries) * 0w2

      | SI.Apply_0 {destinations = [d],...} => 0w3
      | SI.Apply_1 {argSize = SI.SINGLE,destinations = [d],...} => 0w4
      | SI.Apply_1 {argSize = SI.DOUBLE,destinations = [d],...} => 0w4
      | SI.Apply_1 {argSize = SI.VARIANT v,destinations = [d],...} => 0w5
      | SI.Apply_MS {argEntries, destinations = [d],...} => 0w4 + (length argEntries)
      | SI.Apply_ML {argEntries, lastArgSize = SI.SINGLE, destinations = [d],...} => 
        0w4 + (length argEntries)
      | SI.Apply_ML {argEntries, lastArgSize = SI.DOUBLE, destinations = [d],...} => 
        0w4 + (length argEntries)
      | SI.Apply_ML {argEntries, lastArgSize = SI.VARIANT v, destinations = [d],...} => 
        0w5 + (length argEntries)
      | SI.Apply_MF {argEntries, destinations = [d],...} => 0w4 + (length argEntries) * 0w2
      | SI.Apply_MV {argEntries, destinations = [d],...} => 0w4 + (length argEntries) * 0w2

      | SI.Apply_0 {destinations,...} => 0w3 + (length destinations)
      | SI.Apply_1 {argSize = SI.SINGLE,destinations,...} => 0w4 + (length destinations)
      | SI.Apply_1 {argSize = SI.DOUBLE,destinations,...} => 0w4 + (length destinations)
      | SI.Apply_1 {argSize = SI.VARIANT v,destinations,...} => 0w5 + (length destinations)
      | SI.Apply_MS {argEntries, destinations,...} => 0w4 + (length argEntries) + (length destinations)
      | SI.Apply_ML {argEntries, lastArgSize = SI.SINGLE, destinations,...} => 
        0w4 + (length argEntries) + (length destinations)
      | SI.Apply_ML {argEntries, lastArgSize = SI.DOUBLE, destinations,...} => 
        0w4 + (length argEntries) + (length destinations)
      | SI.Apply_ML {argEntries, lastArgSize = SI.VARIANT v, destinations,...} => 
        0w5 + (length argEntries) + (length destinations)
      | SI.Apply_MF {argEntries, destinations,...} => 0w4 + (length argEntries) * 0w2 + (length destinations)
      | SI.Apply_MV {argEntries, destinations,...} => 0w4 + (length argEntries) * 0w2 + (length destinations)

      | SI.TailApply_0 _ => 0w2
      | SI.TailApply_1 {argSize = SI.SINGLE,...} => 0w3
      | SI.TailApply_1 {argSize = SI.DOUBLE,...} => 0w3
      | SI.TailApply_1 {argSize = SI.VARIANT v,...} => 0w4
      | SI.TailApply_MS {argEntries,...} => 0w3 + (length argEntries)
      | SI.TailApply_ML {argEntries,lastArgSize = SI.SINGLE,...} => 
        0w3 + (length argEntries)
      | SI.TailApply_ML {argEntries,lastArgSize = SI.DOUBLE,...} => 
        0w3 + (length argEntries)
      | SI.TailApply_ML {argEntries,lastArgSize = SI.VARIANT v,...} => 
        0w4 + (length argEntries)
      | SI.TailApply_MF {argEntries,...} => 0w3 + (length argEntries) * 0w2
      | SI.TailApply_MV {argEntries,...} => 0w3 + (length argEntries) * 0w2

      | SI.CallStatic_0 {destinations = [],...} => 0w3
      | SI.CallStatic_1 {argSize = SI.SINGLE,destinations = [],...} => 0w4
      | SI.CallStatic_1 {argSize = SI.DOUBLE,destinations = [],...} => 0w4
      | SI.CallStatic_1 {argSize = SI.VARIANT v,destinations = [],...} => 0w5
      | SI.CallStatic_MS {argEntries, destinations = [],...} => 0w4 + (length argEntries)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.SINGLE, destinations = [],...} => 
        0w4 + (length argEntries)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.DOUBLE, destinations = [],...} => 
        0w4 + (length argEntries)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.VARIANT v, destinations = [],...} => 
        0w5 + (length argEntries)
      | SI.CallStatic_MF {argEntries, destinations = [],...} => 0w4 + (length argEntries) * 0w2
      | SI.CallStatic_MV {argEntries, destinations = [],...} => 0w4 + (length argEntries) * 0w2

      | SI.CallStatic_0 {destinations = [d],...} => 0w4
      | SI.CallStatic_1 {argSize = SI.SINGLE,destinations = [d],...} => 0w5
      | SI.CallStatic_1 {argSize = SI.DOUBLE,destinations = [d],...} => 0w5
      | SI.CallStatic_1 {argSize = SI.VARIANT v,destinations = [d],...} => 0w6
      | SI.CallStatic_MS {argEntries, destinations = [d],...} => 0w5 + (length argEntries)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.SINGLE, destinations = [d],...} => 
        0w5 + (length argEntries)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.DOUBLE, destinations = [d],...} => 
        0w5 + (length argEntries)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.VARIANT v, destinations = [d],...} => 
        0w6 + (length argEntries)
      | SI.CallStatic_MF {argEntries, destinations = [d],...} => 0w5 + (length argEntries) * 0w2
      | SI.CallStatic_MV {argEntries, destinations = [d],...} => 0w5 + (length argEntries) * 0w2

      | SI.CallStatic_0 {destinations,...} => 0w4 + (length destinations)
      | SI.CallStatic_1 {argSize = SI.SINGLE,destinations,...} => 0w5 + (length destinations)
      | SI.CallStatic_1 {argSize = SI.DOUBLE,destinations,...} => 0w5 + (length destinations)
      | SI.CallStatic_1 {argSize = SI.VARIANT v,destinations,...} => 0w6 + (length destinations)
      | SI.CallStatic_MS {argEntries, destinations,...} => 0w5 + (length argEntries) + (length destinations)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.SINGLE, destinations,...} => 
        0w5 + (length argEntries) + (length destinations)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.DOUBLE, destinations,...} => 
        0w5 + (length argEntries) + (length destinations)
      | SI.CallStatic_ML {argEntries, lastArgSize = SI.VARIANT v, destinations,...} => 
        0w6 + (length argEntries) + (length destinations)
      | SI.CallStatic_MF {argEntries, destinations,...} => 0w5 + (length argEntries) * 0w2 + (length destinations)
      | SI.CallStatic_MV {argEntries, destinations,...} => 0w5 + (length argEntries) * 0w2 + (length destinations)

      | SI.TailCallStatic_0 _ => 0w3
      | SI.TailCallStatic_1 {argSize = SI.SINGLE,...} => 0w4
      | SI.TailCallStatic_1 {argSize = SI.DOUBLE,...} => 0w4
      | SI.TailCallStatic_1 {argSize = SI.VARIANT v,...} => 0w5
      | SI.TailCallStatic_MS {argEntries,...} => 0w4 + (length argEntries)
      | SI.TailCallStatic_ML {argEntries,lastArgSize = SI.SINGLE,...} => 0w4 + (length argEntries)
      | SI.TailCallStatic_ML {argEntries,lastArgSize = SI.DOUBLE,...} => 0w4 + (length argEntries)
      | SI.TailCallStatic_ML {argEntries,lastArgSize = SI.VARIANT v,...} => 0w5 + (length argEntries)
      | SI.TailCallStatic_MF {argEntries,...} => 0w4 + (length argEntries) * 0w2
      | SI.TailCallStatic_MV {argEntries,...} => 0w4 + (length argEntries) * 0w2

      | SI.RecursiveCallStatic_0 {destinations = [],...} => 0w2
      | SI.RecursiveCallStatic_1 {argSize = SI.SINGLE,destinations = [],...} => 0w3
      | SI.RecursiveCallStatic_1 {argSize = SI.DOUBLE,destinations = [],...} => 0w3
      | SI.RecursiveCallStatic_1 {argSize = SI.VARIANT v,destinations = [],...} => 0w4
      | SI.RecursiveCallStatic_MS {argEntries, destinations = [],...} => 0w3 + (length argEntries)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.SINGLE, destinations = [],...} => 
        0w3 + (length argEntries)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.DOUBLE, destinations = [],...} => 
        0w3 + (length argEntries)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.VARIANT v, destinations = [],...} => 
        0w3 + (length argEntries)
      | SI.RecursiveCallStatic_MF {argEntries, destinations = [],...} => 0w3 + (length argEntries) * 0w2
      | SI.RecursiveCallStatic_MV {argEntries, destinations = [],...} => 0w3 + (length argEntries) * 0w2

      | SI.RecursiveCallStatic_0 {destinations = [d],...} => 0w3
      | SI.RecursiveCallStatic_1 {argSize = SI.SINGLE,destinations = [d],...} => 0w4
      | SI.RecursiveCallStatic_1 {argSize = SI.DOUBLE,destinations = [d],...} => 0w4
      | SI.RecursiveCallStatic_1 {argSize = SI.VARIANT v,destinations = [d],...} => 0w5
      | SI.RecursiveCallStatic_MS {argEntries, destinations = [d],...} => 0w4 + (length argEntries)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.SINGLE, destinations = [d],...} => 
        0w4 + (length argEntries)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.DOUBLE, destinations = [d],...} => 
        0w4 + (length argEntries)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.VARIANT v, destinations = [d],...} => 
        0w5 + (length argEntries)
      | SI.RecursiveCallStatic_MF {argEntries, destinations = [d],...} => 0w4 + (length argEntries) * 0w2
      | SI.RecursiveCallStatic_MV {argEntries, destinations = [d],...} => 0w4 + (length argEntries) * 0w2

      | SI.RecursiveCallStatic_0 {destinations,...} => 0w3 + (length destinations)
      | SI.RecursiveCallStatic_1 {argSize = SI.SINGLE,destinations,...} => 0w4 + (length destinations)
      | SI.RecursiveCallStatic_1 {argSize = SI.DOUBLE,destinations,...} => 0w4 + (length destinations)
      | SI.RecursiveCallStatic_1 {argSize = SI.VARIANT v,destinations,...} => 0w5 + (length destinations)
      | SI.RecursiveCallStatic_MS {argEntries, destinations,...} => 0w4 + (length argEntries) + (length destinations)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.SINGLE, destinations,...} => 
        0w4 + (length argEntries) + (length destinations)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.DOUBLE, destinations,...} => 
        0w4 + (length argEntries) + (length destinations)
      | SI.RecursiveCallStatic_ML {argEntries, lastArgSize = SI.VARIANT v, destinations,...} => 
        0w5 + (length argEntries) + (length destinations)
      | SI.RecursiveCallStatic_MF {argEntries, destinations,...} => 0w4 + (length argEntries) * 0w2 + (length destinations)
      | SI.RecursiveCallStatic_MV {argEntries, destinations,...} => 0w4 + (length argEntries) * 0w2 + (length destinations)

      | SI.RecursiveTailCallStatic_0 _ => 0w2
      | SI.RecursiveTailCallStatic_1 {argSize = SI.SINGLE,...} => 0w3
      | SI.RecursiveTailCallStatic_1 {argSize = SI.DOUBLE,...} => 0w3
      | SI.RecursiveTailCallStatic_1 {argSize = SI.VARIANT v,...} => 0w4
      | SI.RecursiveTailCallStatic_MS {argEntries,...} => 0w3 + (length argEntries)
      | SI.RecursiveTailCallStatic_ML {argEntries,lastArgSize = SI.SINGLE,...} => 0w3 + (length argEntries)
      | SI.RecursiveTailCallStatic_ML {argEntries,lastArgSize = SI.DOUBLE,...} => 0w3 + (length argEntries)
      | SI.RecursiveTailCallStatic_ML {argEntries,lastArgSize = SI.VARIANT v,...} => 0w4 + (length argEntries)
      | SI.RecursiveTailCallStatic_MF {argEntries,...} => 0w3 + (length argEntries) * 0w2
      | SI.RecursiveTailCallStatic_MV {argEntries,...} => 0w3 + (length argEntries) * 0w2

      | SI.MakeBlock {fieldEntries, ...} => 0w5 + (length fieldEntries) * 0w2
      | SI.MakeFixedSizeBlock {fieldEntries, ...} => 0w5 + (length fieldEntries) * 0w2
      | SI.MakeBlockOfSingleValues {fieldEntries, ...} => 0w4 + (length fieldEntries)

      | SI.MakeArray {initialValueSize = SI.SINGLE,...} => 0w5
      | SI.MakeArray {initialValueSize = SI.DOUBLE,...} => 0w5
      | SI.MakeArray {initialValueSize = SI.VARIANT v,...} => 0w6

      | SI.MakeClosure _ => 0w4
      | SI.Raise _ => 0w2
      | SI.PushHandler _ => 0w3
      | SI.PopHandler _ => 0w1
      | SI.Label _ => 0w0
      | SI.Location _ => 0w0
      | SI.SwitchInt {cases, ...} => 0w4 + ((length cases) * 0w2)
      | SI.SwitchWord {cases, ...} => 0w4 + ((length cases) * 0w2)
      | SI.SwitchChar {cases, ...} => 0w4 + ((length cases) * 0w2)
      | SI.SwitchString {cases, ...} => 0w4 + ((length cases) * 0w2)
      | SI.Jump _ => 0w2
      | SI.Exit => 0w1

      | SI.Return_0 => 0w1
      | SI.Return_1 {variableSize = SI.SINGLE,...} => 0w2
      | SI.Return_1 {variableSize = SI.DOUBLE,...} => 0w2
      | SI.Return_1 {variableSize = SI.VARIANT v,...} => 0w3
      | SI.Return_MS {variableEntries = []} => 0w1
      | SI.Return_MS {variableEntries = [variableEntry]} => 0w2
      | SI.Return_MS {variableEntries} => 0w2 + (length variableEntries)
      | SI.Return_ML {variableEntries = [variableEntry],lastVariableSize = SI.SINGLE} => 0w2
      | SI.Return_ML {variableEntries = [variableEntry],lastVariableSize = SI.DOUBLE} => 0w2
      | SI.Return_ML {variableEntries = [variableEntry],lastVariableSize = SI.VARIANT v} => 0w3
      | SI.Return_ML {variableEntries,lastVariableSize = SI.SINGLE} => 0w2 + (length variableEntries)
      | SI.Return_ML {variableEntries,lastVariableSize = SI.DOUBLE} => 0w2 + (length variableEntries)
      | SI.Return_ML {variableEntries,lastVariableSize = SI.VARIANT v} => 0w3 + (length variableEntries)
      | SI.Return_MF {variableEntries = [],...} => 0w1
      | SI.Return_MF {variableEntries = [variableEntry],...} => 0w2
      | SI.Return_MF {variableEntries,...} => 0w2 + (length variableEntries) * 0w2
      | SI.Return_MV {variableEntries = [],...} => 0w1
      | SI.Return_MV {variableEntries = [variableEntry],...} => 0w3
      | SI.Return_MV {variableEntries,...} => 0w2 + (length variableEntries) * 0w2

      | SI.ConstString {string, ...} =>
        0w2 + BT.IntToUInt32(BT.StringToPaddedUInt8ListLength string)

      | SI.AddInt_Const_1 _ => 0w4
      | SI.AddInt_Const_2 _ => 0w4
      | SI.AddReal_Const_1 _ => 0w5
      | SI.AddReal_Const_2 _ => 0w5
      | SI.AddWord_Const_1 _ => 0w4
      | SI.AddWord_Const_2 _ => 0w4
      | SI.AddByte_Const_1 _ => 0w4
      | SI.AddByte_Const_2 _ => 0w4

      | SI.SubInt_Const_1 _ => 0w4
      | SI.SubInt_Const_2 _ => 0w4
      | SI.SubReal_Const_1 _ => 0w5
      | SI.SubReal_Const_2 _ => 0w5
      | SI.SubWord_Const_1 _ => 0w4
      | SI.SubWord_Const_2 _ => 0w4
      | SI.SubByte_Const_1 _ => 0w4
      | SI.SubByte_Const_2 _ => 0w4

      | SI.MulInt_Const_1 _ => 0w4
      | SI.MulInt_Const_2 _ => 0w4
      | SI.MulReal_Const_1 _ => 0w5
      | SI.MulReal_Const_2 _ => 0w5
      | SI.MulWord_Const_1 _ => 0w4
      | SI.MulWord_Const_2 _ => 0w4
      | SI.MulByte_Const_1 _ => 0w4
      | SI.MulByte_Const_2 _ => 0w4

      | SI.DivInt_Const_1 _ => 0w4
      | SI.DivInt_Const_2 _ => 0w4
      | SI.DivReal_Const_1 _ => 0w5
      | SI.DivReal_Const_2 _ => 0w5
      | SI.DivWord_Const_1 _ => 0w4
      | SI.DivWord_Const_2 _ => 0w4
      | SI.DivByte_Const_1 _ => 0w4
      | SI.DivByte_Const_2 _ => 0w4

      | SI.ModInt_Const_1 _ => 0w4
      | SI.ModInt_Const_2 _ => 0w4
      | SI.ModWord_Const_1 _ => 0w4
      | SI.ModWord_Const_2 _ => 0w4
      | SI.ModByte_Const_1 _ => 0w4
      | SI.ModByte_Const_2 _ => 0w4

      | SI.QuotInt_Const_1 _ => 0w4
      | SI.QuotInt_Const_2 _ => 0w4

      | SI.RemInt_Const_1 _ => 0w4
      | SI.RemInt_Const_2 _ => 0w4

      | SI.LtInt_Const_1 _ => 0w4
      | SI.LtInt_Const_2 _ => 0w4
      | SI.LtReal_Const_1 _ => 0w5
      | SI.LtReal_Const_2 _ => 0w5
      | SI.LtWord_Const_1 _ => 0w4
      | SI.LtWord_Const_2 _ => 0w4
      | SI.LtByte_Const_1 _ => 0w4
      | SI.LtByte_Const_2 _ => 0w4
      | SI.LtChar_Const_1 _ => 0w4
      | SI.LtChar_Const_2 _ => 0w4

      | SI.GtInt_Const_1 _ => 0w4
      | SI.GtInt_Const_2 _ => 0w4
      | SI.GtReal_Const_1 _ => 0w5
      | SI.GtReal_Const_2 _ => 0w5
      | SI.GtWord_Const_1 _ => 0w4
      | SI.GtWord_Const_2 _ => 0w4
      | SI.GtByte_Const_1 _ => 0w4
      | SI.GtByte_Const_2 _ => 0w4
      | SI.GtChar_Const_1 _ => 0w4
      | SI.GtChar_Const_2 _ => 0w4

      | SI.LteqInt_Const_1 _ => 0w4
      | SI.LteqInt_Const_2 _ => 0w4
      | SI.LteqReal_Const_1 _ => 0w5
      | SI.LteqReal_Const_2 _ => 0w5
      | SI.LteqWord_Const_1 _ => 0w4
      | SI.LteqWord_Const_2 _ => 0w4
      | SI.LteqByte_Const_1 _ => 0w4
      | SI.LteqByte_Const_2 _ => 0w4
      | SI.LteqChar_Const_1 _ => 0w4
      | SI.LteqChar_Const_2 _ => 0w4

      | SI.GteqInt_Const_1 _ => 0w4
      | SI.GteqInt_Const_2 _ => 0w4
      | SI.GteqReal_Const_1 _ => 0w5
      | SI.GteqReal_Const_2 _ => 0w5
      | SI.GteqWord_Const_1 _ => 0w4
      | SI.GteqWord_Const_2 _ => 0w4
      | SI.GteqByte_Const_1 _ => 0w4
      | SI.GteqByte_Const_2 _ => 0w4
      | SI.GteqChar_Const_1 _ => 0w4
      | SI.GteqChar_Const_2 _ => 0w4

      | SI.Word_andb_Const_1 _ => 0w4
      | SI.Word_andb_Const_2 _ => 0w4

      | SI.Word_orb_Const_1 _ => 0w4
      | SI.Word_orb_Const_2 _ => 0w4

      | SI.Word_xorb_Const_1 _ => 0w4
      | SI.Word_xorb_Const_2 _ => 0w4

      | SI.Word_leftShift_Const_1 _ => 0w4
      | SI.Word_leftShift_Const_2 _ => 0w4

      | SI.Word_logicalRightShift_Const_1 _ => 0w4
      | SI.Word_logicalRightShift_Const_2 _ => 0w4

      | SI.Word_arithmeticRightShift_Const_1 _ => 0w4
      | SI.Word_arithmeticRightShift_Const_2 _ => 0w4


  (** get the number of word occupied by a FunEntry instruction generated
   * from the funInfo.
   * @params funInfo
   * @param funInfo information of the function
   * @return the number of 32bit words required for a FunEntry with required
   *       operands.
   *)
  fun wordsOfFunEntry (funInfo : SI.funInfo) =
        let
          val entrySize =  
              1 + (* opcode *)
              1 + (* frameSize *)
              1 + (* startOffset *)
              1 + (* arity *)
              List.length(#args funInfo) + (* argsdest *) 
              1 + (* bitmapvals.argsCount *)
              List.length(#args(#bitmapvals funInfo)) + (* bitmapvals.args *)
              1 + (* bitmapvals.freesCount *)
              List.length(#frees(#bitmapvals funInfo)) +(* bitmapvals.frees *)
              1 + (* pointers *)
              1 + (* atoms *)
              1 + (* recordsCount *)
              List.length(#records funInfo) (* records *)
        in BT.IntToUInt32 entrySize end

  (***************************************************************************)

end
