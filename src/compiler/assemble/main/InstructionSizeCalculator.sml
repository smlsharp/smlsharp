(**
 * This module calculates the size of instruction in words.
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu Duc
 * @version $Id: InstructionSizeCalculator.sml,v 1.24 2006/02/09 16:55:08 duchuu Exp $
 *)
structure InstructionSizeCalculator : INSTRUCTION_SIZE_CALCULATOR =
struct

  (***************************************************************************)

  structure AI = AllocationInfo
  structure BT = BasicTypes
  structure P = Primitives
  structure SI = SymbolicInstructions

  (***************************************************************************)

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
      | SI.LoadReal _ => 0w4
      | SI.LoadChar _ => 0w3
      | SI.LoadEmptyBlock _ => 0w2

      | SI.Access {variableSize = SI.SINGLE,...} => 0w3
      | SI.Access {variableSize = SI.DOUBLE,...} => 0w3
      | SI.Access {variableSize = SI.VARIANT _,...} => 0w4

      | SI.AccessEnv {variableSize = SI.SINGLE,...} => 0w3
      | SI.AccessEnv {variableSize = SI.DOUBLE,...} => 0w3
      | SI.AccessEnv {variableSize = SI.VARIANT v,...} => 0w4

      | SI.AccessEnvIndirect {variableSize = SI.SINGLE,...} => 0w3
      | SI.AccessEnvIndirect {variableSize = SI.DOUBLE,...} => 0w3
      | SI.AccessEnvIndirect {variableSize = SI.VARIANT v,...} => 0w4

      | SI.AccessNestedEnv {variableSize = SI.SINGLE,...} => 0w4
      | SI.AccessNestedEnv {variableSize = SI.DOUBLE,...} => 0w4
      | SI.AccessNestedEnv {variableSize = SI.VARIANT v,...} => 0w5

      | SI.AccessNestedEnvIndirect {variableSize = SI.SINGLE,...} => 0w4
      | SI.AccessNestedEnvIndirect {variableSize = SI.DOUBLE,...} => 0w4
      | SI.AccessNestedEnvIndirect {variableSize = SI.VARIANT v,...} => 0w5

      | SI.GetField {fieldSize = SI.SINGLE,...} => 0w4
      | SI.GetField {fieldSize = SI.DOUBLE,...} => 0w4
      | SI.GetField {fieldSize = SI.VARIANT v,...} => 0w5

      | SI.GetFieldIndirect {fieldSize = SI.SINGLE,...} => 0w4
      | SI.GetFieldIndirect {fieldSize = SI.DOUBLE,...} => 0w4
      | SI.GetFieldIndirect {fieldSize = SI.VARIANT v,...} => 0w5

      | SI.GetNestedFieldIndirect {fieldSize = SI.SINGLE,...} => 0w5
      | SI.GetNestedFieldIndirect {fieldSize = SI.DOUBLE,...} => 0w5
      | SI.GetNestedFieldIndirect {fieldSize = SI.VARIANT v,...} => 0w6

      | SI.SetField {fieldSize = SI.SINGLE,...} => 0w4
      | SI.SetField {fieldSize = SI.DOUBLE,...} => 0w4
      | SI.SetField {fieldSize = SI.VARIANT v,...} => 0w5

      | SI.SetFieldIndirect {fieldSize = SI.SINGLE,...} => 0w4
      | SI.SetFieldIndirect {fieldSize = SI.DOUBLE,...} => 0w4
      | SI.SetFieldIndirect {fieldSize = SI.VARIANT v,...} => 0w5

      | SI.SetNestedFieldIndirect {fieldSize = SI.SINGLE,...} => 0w5
      | SI.SetNestedFieldIndirect {fieldSize = SI.DOUBLE,...} => 0w5
      | SI.SetNestedFieldIndirect {fieldSize = SI.VARIANT v,...} => 0w6

      | SI.CopyBlock _ => 0w3

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
      | SI.CallPrim {argsCount, primitive, ...} =>
        (case #instruction primitive of
           P.Internal1 _ => 0w3
         | P.Internal2 _ => 0w4
         | P.Internal3 _ => 0w5
         | P.InternalN _ => 0w3 + argsCount
         | P.External _ => 0w4 + argsCount)
      | SI.ForeignApply {argsCount, ...} => 0w4 + argsCount

      | SI.Apply_S {argSize = SI.SINGLE, ...} => 0w4
      | SI.Apply_S {argSize = SI.DOUBLE, ...} => 0w4
      | SI.Apply_S {argSize = SI.VARIANT v, ...} => 0w5
      | SI.Apply_ML {argsCount, lastArgSize = SI.SINGLE, ...} => 0w4 + argsCount
      | SI.Apply_ML {argsCount, lastArgSize = SI.DOUBLE, ...} => 0w4 + argsCount
      | SI.Apply_ML {argsCount, lastArgSize = SI.VARIANT v, ...} => 0w5 + argsCount
      | SI.Apply_M {argsCount, ...} => 0w4 + argsCount + argsCount

      | SI.TailApply_S {argSize = SI.SINGLE, ...} => 0w3
      | SI.TailApply_S {argSize = SI.DOUBLE, ...} => 0w3
      | SI.TailApply_S {argSize = SI.VARIANT v, ...} => 0w4
      | SI.TailApply_ML {argsCount, lastArgSize = SI.SINGLE, ...} => 0w3 + argsCount
      | SI.TailApply_ML {argsCount, lastArgSize = SI.DOUBLE, ...} => 0w3 + argsCount
      | SI.TailApply_ML {argsCount, lastArgSize = SI.VARIANT v, ...} => 0w4 + argsCount
      | SI.TailApply_M {argsCount, ...} => 0w3 + argsCount + argsCount

      | SI.CallStatic_S {argSize = SI.SINGLE, ...} => 0w5
      | SI.CallStatic_S {argSize = SI.DOUBLE, ...} => 0w5
      | SI.CallStatic_S {argSize = SI.VARIANT v, ...} => 0w6
      | SI.CallStatic_ML {argsCount, lastArgSize = SI.SINGLE, ...} => 0w5 + argsCount
      | SI.CallStatic_ML {argsCount, lastArgSize = SI.DOUBLE, ...} => 0w5 + argsCount
      | SI.CallStatic_ML {argsCount, lastArgSize = SI.VARIANT v, ...} => 0w6 + argsCount
      | SI.CallStatic_M {argsCount, ...} => 0w4 + argsCount + argsCount

      | SI.TailCallStatic_S {argSize = SI.SINGLE, ...} => 0w4
      | SI.TailCallStatic_S {argSize = SI.DOUBLE, ...} => 0w4
      | SI.TailCallStatic_S {argSize = SI.VARIANT v, ...} => 0w5
      | SI.TailCallStatic_ML {argsCount, lastArgSize = SI.SINGLE, ...} => 0w4 + argsCount
      | SI.TailCallStatic_ML {argsCount, lastArgSize = SI.DOUBLE, ...} => 0w4 + argsCount
      | SI.TailCallStatic_ML {argsCount, lastArgSize = SI.VARIANT v, ...} => 0w5 + argsCount
      | SI.TailCallStatic_M {argsCount, ...} => 0w4 + argsCount + argsCount

      | SI.RecursiveCallStatic_S {argSize = SI.SINGLE,...} => 0w4
      | SI.RecursiveCallStatic_S {argSize = SI.DOUBLE,...} => 0w4
      | SI.RecursiveCallStatic_S {argSize = SI.VARIANT v,...} => 0w5
      | SI.RecursiveCallStatic_M {argsCount,...} => 0w4 + argsCount + argsCount

      | SI.RecursiveTailCallStatic_S {argSize = SI.SINGLE,...} => 0w3
      | SI.RecursiveTailCallStatic_S {argSize = SI.DOUBLE,...} => 0w3
      | SI.RecursiveTailCallStatic_S {argSize = SI.VARIANT v,...} => 0w4
      | SI.RecursiveTailCallStatic_M {argsCount,...} => 0w3 + argsCount + argsCount

      | SI.SelfRecursiveCallStatic_S {argSize = SI.SINGLE,...} => 0w4
      | SI.SelfRecursiveCallStatic_S {argSize = SI.DOUBLE,...} => 0w4
      | SI.SelfRecursiveCallStatic_S {argSize = SI.VARIANT v,...} => 0w5
      | SI.SelfRecursiveCallStatic_M {argsCount,...} => 0w4 + argsCount + argsCount

      | SI.SelfRecursiveTailCallStatic_S {argSize = SI.SINGLE,...} => 0w3
      | SI.SelfRecursiveTailCallStatic_S {argSize = SI.DOUBLE,...} => 0w3
      | SI.SelfRecursiveTailCallStatic_S {argSize = SI.VARIANT v,...} => 0w4
      | SI.SelfRecursiveTailCallStatic_M {argsCount,...} => 0w3 + argsCount + argsCount

      | SI.MakeBlock {fieldsCount, ...} => 0w5 + fieldsCount * 0w2
      | SI.MakeBlockOfSingleValues {fieldsCount, ...} => 0w4 + fieldsCount

      | SI.MakeArray {initialValueSize = SI.SINGLE,...} => 0w5
      | SI.MakeArray {initialValueSize = SI.DOUBLE,...} => 0w5
      | SI.MakeArray {initialValueSize = SI.VARIANT v,...} => 0w6

      | SI.MakeClosure _ => 0w4
      | SI.Raise _ => 0w2
      | SI.PushHandler _ => 0w3
      | SI.PopHandler => 0w1
      | SI.Label _ => 0w0
      | SI.Location _ => 0w0
      | SI.SwitchInt {casesCount, ...} => 0w4 + (casesCount * 0w2)
      | SI.SwitchWord {casesCount, ...} => 0w4 + (casesCount * 0w2)
      | SI.SwitchChar {casesCount, ...} => 0w4 + (casesCount * 0w2)
      | SI.SwitchString {casesCount, ...} => 0w4 + (casesCount * 0w2)
      | SI.Jump _ => 0w2
      | SI.Exit => 0w1

      | SI.Return {variableSize = SI.SINGLE,...} => 0w2
      | SI.Return {variableSize = SI.DOUBLE,...} => 0w2
      | SI.Return {variableSize = SI.VARIANT v,...} => 0w3

      | SI.ConstString {string, ...} =>
        0w2 + BT.IntToUInt32(BT.StringToPaddedUInt8ListLength string)
      | SI.FFIVal _ => 0w4

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

(* temporarily disable

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

*)

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
