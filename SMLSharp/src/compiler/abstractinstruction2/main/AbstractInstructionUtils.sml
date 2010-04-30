(**
 * Abstract Instructions version 2.
 * @copyright (c) 2007-2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: AbstractInstructionUtils.sml,v 1.9 2008/02/05 08:54:35 katsu Exp $
 *)

structure AbstractInstruction2Utils =
struct
  structure AbstractInstruction = AbstractInstruction2

  structure AI = AbstractInstruction

  fun getLoc insn =
      case insn of
        AI.Move {loc, ...} => loc
      | AI.Load {loc, ...} => loc
      | AI.Update {loc, ...} => loc
      | AI.Get {loc, ...} => loc
      | AI.Set {loc, ...} => loc
      | AI.Alloc {loc, ...} => loc
      | AI.PrimOp1 {loc, ...} => loc
      | AI.PrimOp2 {loc, ...} => loc
      | AI.CallExt {loc, ...} => loc
      | AI.Call {loc, ...} => loc
      | AI.TailCall {loc, ...} => loc
      | AI.ExportClosure {loc, ...} => loc
      | AI.Return {loc, ...} => loc
      | AI.If {loc, ...} => loc
      | AI.CheckBoundary {loc, ...} => loc
      | AI.Raise {loc, ...} => loc
      | AI.Jump {loc, ...} => loc
      | AI.ChangeHandler {loc, ...} => loc

  fun tagOf genericTyRep ty =
      case ty of
        AI.GENERIC tid =>
        (case IEnv.find (genericTyRep, tid) of
           SOME ({tag, ...}:AI.genericTyRep) => tag
         | NONE => raise Control.Bug "tagOf")
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
      | AI.Get {dst, ty, src, loc} => [] 
      | AI.Set {dst, ty, value, loc} => []
      | AI.Alloc {dst, objectType, bitmaps, payloadSize, fieldInfo, loc} => []
      | AI.PrimOp1 {dst, op1, arg, loc} => []
      | AI.PrimOp2 {dst, op2, arg1, arg2, loc} => []
      | AI.CallExt {dstVarList, callee, argList, calleeTy, loc} => []
      | AI.Call {dstVarList, entry, env, argList, argSizeList, argTyList,
                 resultTyList, loc} => []
      | AI.TailCall {entry, env, argList, argSizeList, argTyList,
                     resultTyList, loc} => []
      | AI.ExportClosure {dst, entry, env, exportTy, loc} => []
      | AI.Return {varList, valueSizeList, argTyList, retTyList, loc} => []
      | AI.If {op2, value1, value2, thenLabel, elseLabel, loc} =>
        [thenLabel, elseLabel]
      | AI.CheckBoundary {offset, size, objectSize, passLabel, failLabel,
                          loc} =>
        [passLabel, failLabel]
      | AI.Raise {exn, loc} => []
      | AI.Jump {label, knownDestinations, loc} => knownDestinations
      | AI.ChangeHandler {change, previousHandler, newHandler, tryBlock,
                          loc} => []

  fun defs insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} => [dst]
      | AI.Load {dst, ty, block, offset, size, loc} => [dst]
      | AI.Update {block, offset, size, ty, value, barrier, loc} => []
      | AI.Get {dst, ty, src, loc} => [dst] 
      | AI.Set {dst, ty, value, loc} => []
      | AI.Alloc {dst, objectType, bitmaps, payloadSize, fieldInfo, loc} =>
        [dst]
      | AI.PrimOp1 {dst, op1, arg, loc} => [dst]
      | AI.PrimOp2 {dst, op2, arg1, arg2, loc} => [dst]
      | AI.CallExt {dstVarList, callee, argList, calleeTy, loc} => []
      | AI.Call {dstVarList, entry, env, argList, argSizeList, argTyList,
                 resultTyList, loc} => []
      | AI.TailCall {entry, env, argList, argSizeList, argTyList,
                     resultTyList, loc} => []
      | AI.ExportClosure {dst, entry, env, exportTy, loc} => [dst]
      | AI.Return {varList, valueSizeList, argTyList, retTyList, loc} => []
      | AI.If {op2, value1, value2, thenLabel, elseLabel, loc} => []
      | AI.CheckBoundary {offset, size, objectSize, passLabel, failLabel,
                          loc} => []
      | AI.Raise {exn, loc} => []
      | AI.Jump {label, knownDestinations, loc} => []
      | AI.ChangeHandler {change, previousHandler, newHandler, tryBlock,
                          loc} => []

  local
    fun useValue value =
        case value of
          AI.UInt _ => nil
        | AI.SInt _ => nil
        | AI.Var var => [var]
        | AI.Empty => nil
        | AI.Nowhere => nil
        | AI.Null => nil
        | AI.Const _ => nil
        | AI.Init _ => nil
        | AI.Entry _ => nil
        | AI.Label _ => nil
        | AI.Extern _ => nil
        | AI.Global _ => nil

    fun useValueList values = foldr (fn (x,z) => useValue x @ z) nil values

    fun useBarrier barrier =
        case barrier of
          AI.NoBarrier => nil
        | AI.WriteBarrier => nil
        | AI.BarrierTag v => useValue v

    fun useExtCallee callee =
        case callee of
          AI.Primitive _ => nil
        | AI.Foreign {function, convention} => useValue function
  in

  fun uses insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} => useValue value
      | AI.Load {dst, ty, block, offset, size, loc} =>
        useValue block @ useValue offset @ useValue size
      | AI.Update {block, offset, size, ty, value, barrier, loc} =>
        useValue block @ useValue offset @ useValue size @ useValue value @
        useBarrier barrier
      | AI.Get {dst, ty, src, loc} => [] 
      | AI.Set {dst, ty, value, loc} => useValue value
      | AI.Alloc {dst, objectType, bitmaps, payloadSize, fieldInfo, loc} =>
        useValueList bitmaps @ useValue payloadSize
      | AI.PrimOp1 {dst, op1, arg, loc} => useValue arg
      | AI.PrimOp2 {dst, op2, arg1, arg2, loc} => useValue arg1 @ useValue arg2
      | AI.CallExt {dstVarList, callee, argList, calleeTy, loc} =>
        useExtCallee callee
      | AI.Call {dstVarList, entry, env, argList, argSizeList, argTyList,
                 resultTyList, loc} =>
        useValue entry
      | AI.TailCall {entry, env, argList, argSizeList, argTyList,
                     resultTyList, loc} =>
        useValue entry
      | AI.ExportClosure {dst, entry, env, exportTy, loc} =>
        useValue entry @ useValue env
      | AI.Return {varList, valueSizeList, argTyList, retTyList, loc} => nil
      | AI.If {op2, value1, value2, thenLabel, elseLabel, loc} =>
        useValue value1 @ useValue value2
      | AI.CheckBoundary {offset, size, objectSize, passLabel, failLabel,
                          loc} =>
        useValue offset @ useValue size @ useValue objectSize
      | AI.Raise {exn, loc} => []
      | AI.Jump {label, knownDestinations, loc} =>
        useValue label
      | AI.ChangeHandler {change, previousHandler, newHandler, tryBlock,
                          loc} => []

  end

  fun isConst value =
      case value of
        AI.UInt _ => true
      | AI.SInt _ => true
      | AI.Var _ => false
      | AI.Empty => true
      | AI.Nowhere => true
      | AI.Null => true
      | AI.Const _ => true
      | AI.Init _ => true
      | AI.Entry _ => true
      | AI.Label _ => false  (* Label value depends on program counter *)
      | AI.Global _ => true
      | AI.Extern _ => true



(*
  fun predecessors blocks =
      let
        val entries =
            List.mapPartial
              (fn {label, blockKind, ...}:AI.basicBlock =>
                  case blockKind of
                    AI.FunEntry _ => SOME label
                  | _ => NONE)
              blocks

        val succ =
            map (fn {label, instructionList, ...} =>
                    case List.last instructionList of
                      
                    


                  





      in





      end




*)




























end
