(**
 * Abstract Instructions.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AbstractInstructionUtils.sml,v 1.9 2008/02/05 08:54:35 katsu Exp $
 *)

structure AbstractInstructionUtils =
struct

  structure AI = AbstractInstruction

  fun getLoc insn =
      case insn of
        AI.Move {loc, ...} => loc
      | AI.Load {loc, ...} => loc
      | AI.Update {loc, ...} => loc
      | AI.Alloc {loc, ...} => loc
      | AI.PrimOp1 {loc, ...} => loc
      | AI.PrimOp2 {loc, ...} => loc
      | AI.CallExt {loc, ...} => loc
      | AI.Call {loc, ...} => loc
      | AI.TailCall {loc, ...} => loc
      | AI.ExportClosure {loc, ...} => loc
      | AI.Return {loc, ...} => loc
      | AI.If {loc, ...} => loc
      | AI.Raise {loc, ...} => loc
      | AI.CheckBoundary {loc, ...} => loc
      | AI.Jump {loc, ...} => loc

  fun tagOf ty =
      case ty of
        AI.UNION {tag, ...} => tag
      | AI.UINT => AI.Unboxed
      | AI.SINT => AI.Unboxed
      | AI.BYTE => AI.Unboxed
      | AI.CHAR => AI.Unboxed
      | AI.BOXED => AI.Boxed
      | AI.HEAPPOINTER => AI.Unboxed
      | AI.CODEPOINTER => AI.Unboxed
      | AI.CPOINTER => AI.Unboxed
      | AI.ENTRY => AI.Unboxed
      | AI.FLOAT => AI.Unboxed
      | AI.DOUBLE => AI.Unboxed
      | AI.INDEX => AI.Unboxed
      | AI.BITMAP => AI.Unboxed
      | AI.OFFSET => AI.Unboxed
      | AI.SIZE => AI.Unboxed
      | AI.TAG => AI.Unboxed
      | AI.EXNTAG => AI.Unboxed
      | AI.ATOMty => AI.Unboxed
      | AI.DOUBLEty => AI.Unboxed

  fun succs insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} => []
      | AI.Load {dst, ty, block, offset, size, loc} => []
      | AI.Update {block, offset, size, ty, value, barrier, loc} => []
      | AI.Alloc {dst, objectType, bitmaps, payloadSize, fieldInfo, loc} => []
      | AI.PrimOp1 {dst, op1, arg, loc} => []
      | AI.PrimOp2 {dst, op2, arg1, arg2, loc} => []
      | AI.CallExt {dstVarList, callee, argList, calleeTy, loc} => []
      | AI.Call {dstVarList, entry, env, argList, argSizeList, argTyList,
                 resultTyList, loc} => []
      | AI.TailCall {entry, env, argList, argSizeList, argTyList,
                     resultTyList, loc} => []
      | AI.ExportClosure {dst, entry, env, exportTy, loc} => []
      | AI.Return {valueList, valueSizeList, tyList, loc} => []
      | AI.If {op2, value1, value2, thenLabel, elseLabel, loc} =>
        [thenLabel, elseLabel]
      | AI.Raise {exn, loc} => []
      | AI.CheckBoundary {block, offset, passLabel, failLabel, loc} =>
        [passLabel, failLabel]
      | AI.Jump {label, knownDestinations, loc} => knownDestinations

  fun defs insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} => [dst]
      | AI.Load {dst, ty, block, offset, size, loc} => [dst]
      | AI.Update {block, offset, size, ty, value, barrier, loc} => []
      | AI.Alloc {dst, objectType, bitmaps, payloadSize, fieldInfo, loc} =>
        [dst]
      | AI.PrimOp1 {dst, op1, arg, loc} => [dst]
      | AI.PrimOp2 {dst, op2, arg1, arg2, loc} => [dst]
      | AI.CallExt {dstVarList, callee, argList, calleeTy, loc} => dstVarList
      | AI.Call {dstVarList, entry, env, argList, argSizeList, argTyList,
                 resultTyList, loc} => dstVarList
      | AI.TailCall {entry, env, argList, argSizeList, argTyList,
                     resultTyList, loc} => []
      | AI.ExportClosure {dst, entry, env, exportTy, loc} => [dst]
      | AI.Return {valueList, valueSizeList, tyList, loc} => []
      | AI.If {op2, value1, value2, thenLabel, elseLabel, loc} => []
      | AI.Raise {exn, loc} => []
      | AI.CheckBoundary {block, offset, passLabel, failLabel, loc} => []
      | AI.Jump {label, knownDestinations, loc} => []

  local
    fun useValue value =
        case value of
          AI.UInt _ => nil
        | AI.SInt _ => nil
        | AI.Real _ => nil
        | AI.Float _ => nil
        | AI.Var var => [var]
        | AI.Param _ => nil
        | AI.Exn _ => nil
        | AI.Env => nil
        | AI.Empty => nil
        | AI.Nowhere => nil
        | AI.Null => nil
        | AI.Const _ => nil
        | AI.Init _ => nil
        | AI.Entry _ => nil
        | AI.Label _ => nil
        | AI.Global _ => nil
        | AI.Extern _ => nil

    fun useValueList values = foldr (fn (x,z) => useValue x @ z) nil values

    fun useBarrier barrier =
        case barrier of
          AI.NoBarrier => nil
        | AI.WriteBarrier => nil
        | AI.BarrierTag v => useValue v

    fun useExtCallee callee =
        case callee of
          AI.Primitive _ => nil
        | AI.Foreign {function, attributes} => useValue function
  in

  fun uses insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} => useValue value
      | AI.Load {dst, ty, block, offset, size, loc} =>
        useValue block @ useValue offset @ useValue size
      | AI.Update {block, offset, size, ty, value, barrier, loc} =>
        useValue block @ useValue offset @ useValue size @ useValue value @
        useBarrier barrier
      | AI.Alloc {dst, objectType, bitmaps, payloadSize, fieldInfo, loc} =>
        useValueList bitmaps @ useValue payloadSize
      | AI.PrimOp1 {dst, op1, arg, loc} => useValue arg
      | AI.PrimOp2 {dst, op2, arg1, arg2, loc} => useValue arg1 @ useValue arg2
      | AI.CallExt {dstVarList, callee, argList, calleeTy, loc} =>
        useExtCallee callee @ useValueList argList
      | AI.Call {dstVarList, entry, env, argList, argSizeList, argTyList,
                 resultTyList, loc} =>
        useValue entry @ useValue env @ useValueList argList
      | AI.TailCall {entry, env, argList, argSizeList, argTyList,
                     resultTyList, loc} =>
        useValue entry @ useValue env @ useValueList argList
      | AI.ExportClosure {dst, entry, env, exportTy, loc} =>
        useValue entry @ useValue env
      | AI.Return {valueList, valueSizeList, tyList, loc} =>
        useValueList valueList
      | AI.If {op2, value1, value2, thenLabel, elseLabel, loc} =>
        useValue value1 @ useValue value2
      | AI.Raise {exn, loc} => useValue exn
      | AI.CheckBoundary {block, offset, passLabel, failLabel, loc} =>
        useValue block @ useValue offset
      | AI.Jump {label, knownDestinations, loc} =>
        useValue label

  end

  fun isConst value =
      case value of
        AI.UInt _ => true
      | AI.SInt _ => true
      | AI.Real _ => true
      | AI.Float _ => true
      | AI.Var _ => false
      | AI.Param _ => false
      | AI.Exn _ => false
      | AI.Env => false
      | AI.Empty => true
      | AI.Nowhere => true
      | AI.Null => true
      | AI.Const _ => true
      | AI.Init _ => true
      | AI.Entry _ => true
      | AI.Label _ => false  (* Label value depends on program counter *)
      | AI.Global _ => true
      | AI.Extern _ => true

end
