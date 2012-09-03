(**
 * Symbolic Instruction Generator
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: SIGenerator.sml,v 1.13 2008/08/06 17:23:41 ohori Exp $
 *
 * Generated symbolic instructions by this generator is not completely
 * compatible with one by another generator, because
 * - This one may produce LoadAddress and IndirectJump instruction.
 * - How to deal with exception is different from another one.
 *   Generated code emulates semantics of AI over SI by using
 *   one Push/PopHandler pair and one IndirectJump.
 *
 * Assembler works fine, but StackReallocator does not work due to the
 * above reasons.
 *
 *)
structure YASIGenerator : YASIGENERATOR =
struct

  structure AI = AbstractInstruction
  structure SI = SymbolicInstructions
  structure Target = AbstractInstruction.Target

  (* FIXME: 0w0 is not always a null pointer. *)
  val NullValue = 0w0 : BasicTypes.UInt32

  fun tagEq (AI.Boxed, AI.Boxed) = true
    | tagEq (AI.Unboxed, AI.Unboxed) = true
    | tagEq (AI.ParamTag p1, AI.ParamTag p2) = LocalVarID.eq (#id p1, #id p2)
    | tagEq (AI.IndirectTag {offset=o1, bit=b1},
             AI.IndirectTag {offset=o2, bit=b2}) = o1 = o2 andalso b1 = b2
    | tagEq _ = false

  fun sizeEq (SI.SINGLE, SI.SINGLE) = true
    | sizeEq (SI.DOUBLE, SI.DOUBLE) = true
    | sizeEq (SI.VARIANT v1, SI.VARIANT v2) = LocalVarID.eq (#id v1, #id v2)
    | sizeEq _ = false

  fun newAIVar ty =
      let
        val id = Counters.newLocalId ()
        val displayName = "$" ^ LocalVarID.toString id
      in
        {id = id, ty = ty, displayName = displayName} : AI.varInfo
      end

  (***************************************************************************)
  (* copy from SIGenerator.sml *)

  fun sizeToCaseTag SI.SINGLE = 0w1 : BasicTypes.UInt32
    | sizeToCaseTag SI.DOUBLE = 0w2
    | sizeToCaseTag (SI.VARIANT _) = raise Control.Bug "sizeToCaseTag"

  fun funTypeToCaseTag (argTys, resultTy) =
      let
        fun tag (h::t) = sizeToCaseTag h + 0w2 * tag t
          | tag nil = 0w0 : BasicTypes.UInt32
      in
        tag (rev (resultTy::argTys))
      end

  (***************************************************************************)
  (* copy from SIOptimizer.sml *)

  datatype SizeListKind =
           EmptySizeList
         | SingletonSizeList of SI.size
         | SingleSizeList
         | LastArbitrarySizeList of SI.size
         | FixedSizeList of BasicTypes.UInt32 list
         | VariantSizeList

  fun wordOf SI.SINGLE = SOME 0w1
    | wordOf SI.DOUBLE = SOME 0w2
    | wordOf (SI.VARIANT _) = NONE : BasicTypes.UInt32 option

  fun allFixedSizes [] L = SOME (rev L)
    | allFixedSizes (sizeEntry::rest) L =
      (
       case wordOf sizeEntry of
         SOME w => allFixedSizes rest (w::L)
       | NONE => NONE
      )

  fun computeSizeListKind [] = EmptySizeList
    | computeSizeListKind [sizeEntry] =
      (
       case wordOf sizeEntry of
         SOME 0w1 => SingletonSizeList SI.SINGLE
       | SOME 0w2 => SingletonSizeList SI.DOUBLE
       | _ => SingletonSizeList sizeEntry
      )
    | computeSizeListKind sizeEntries =
      let
        val L = rev sizeEntries
        val sizeEntries = rev (List.tl L)
        val lastSizeEntry = List.hd L
      in
        case allFixedSizes sizeEntries [] of
          SOME sizes =>
          (
           if List.all (fn w => w = 0w1) sizes
           then
             case wordOf lastSizeEntry of
               SOME 0w0 => FixedSizeList (sizes @ [0w0])
             | SOME 0w1 => SingleSizeList
             | SOME 0w2 => LastArbitrarySizeList SI.DOUBLE
             | NONE => LastArbitrarySizeList lastSizeEntry
             | _ => raise Control.Bug "computeSizeListKind"
           else
             case wordOf lastSizeEntry of
               SOME w => FixedSizeList (sizes @ [w])
             | _ => VariantSizeList
          )
        | NONE => VariantSizeList
      end

  (***************************************************************************)

  fun sizeof ty =
      case ty of
        AI.UINT => SI.SINGLE
      | AI.SINT => SI.SINGLE
      | AI.BYTE => SI.SINGLE
      | AI.CHAR => SI.SINGLE
      | AI.BOXED => SI.SINGLE          (* SI assumes 32bit architecture *)
      | AI.HEAPPOINTER => SI.SINGLE    (* SI assumes 32bit architecture *)
      | AI.CODEPOINTER => SI.SINGLE    (* SI assumes 32bit architecture *)
      | AI.CPOINTER => SI.SINGLE       (* SI assumes 32bit architecture *)
      | AI.FLOAT => SI.SINGLE
      | AI.DOUBLE => SI.DOUBLE
      | AI.INDEX => SI.SINGLE
      | AI.BITMAP => SI.SINGLE
      | AI.OFFSET => SI.SINGLE
      | AI.SIZE => SI.SINGLE
      | AI.TAG => SI.SINGLE
      | AI.EXNTAG => SI.SINGLE
      | AI.ENTRY => SI.SINGLE
      | AI.UNION {variants, ...} =>
        let
          fun max (SI.SINGLE, SI.SINGLE::t) = max (SI.SINGLE, t)
            | max (SI.SINGLE, SI.DOUBLE::t) = max (SI.DOUBLE, t)
            | max (SI.DOUBLE, SI.SINGLE::t) = max (SI.DOUBLE, t)
            | max (SI.DOUBLE, SI.DOUBLE::t) = max (SI.DOUBLE, t)
            | max (x, nil) = x
            | max _ = raise Control.Bug "sizeof: variable size union"
        in
          max (SI.SINGLE, map sizeof variants)
        end
      | AI.ATOMty => SI.SINGLE
      | AI.DOUBLEty => SI.DOUBLE

  (***************************************************************************)

  type localVarInfo =
       SI.varInfo * AI.tag * SI.size

  type context =
       {
         isTopLevel: bool,
         constants: AI.const LocalVarID.Map.map,
         pendingBlocks: AI.label list,
         visitedBlocks: LocalVarID.Set.set,
         localVars: localVarInfo LocalVarID.Map.map,   (* local variables *)
         localLabels: AI.label LocalVarID.Map.map,     (* AI.label -> SI.label *)
         exnVar: SI.varInfo option,            (* exception catcher *)
         handlerVar: SI.varInfo option,        (* current handler address *)
         handlerLabel: AI.label option,        (* the global handler *)
         epilogue: SI.instruction list
       }

  fun newVar (context as {localVars, ...}:context) tag size =
      let
        val id = Counters.newLocalId ()
        val displayName = "$" ^ LocalVarID.toString id
        val varInfo = {id = id, displayName = displayName} : SI.varInfo
        val localVarInfo = (varInfo, tag, size)
      in
        ({
           isTopLevel = #isTopLevel context,
           constants = #constants context,
           pendingBlocks = #pendingBlocks context,
           visitedBlocks = #visitedBlocks context,
           localVars = LocalVarID.Map.insert (#localVars context, id, localVarInfo),
           localLabels = #localLabels context,
           exnVar = #exnVar context,
           handlerVar = #handlerVar context,
           handlerLabel = #handlerLabel context,
           epilogue = #epilogue context
         } : context,
         varInfo)
      end

  fun addLocalVar (context:context) (varInfo as {ty, id, ...}:AI.varInfo) =
      let
        val tag = AbstractInstructionUtils.tagOf ty
        (*
         * NOTE: "sizeof ty" is not always good for symbolic instruction
         *       because "sizeof ty" returns maximum size of ty but SI
         *       requies accurate size.
         *       However in this case this difference does not cause
         *       problems because size information calculated here will
         *       be ignored if this size is different from the size required
         *       by SI. Only one exception case is UNBOXED; UNBOXED slots
         *       will be regarded as DOUBLEs in regenerated frameInfo,
         *       but it is not problematic.
         *)
        val size = sizeof ty
        val sivarInfo = {id = id, displayName = #displayName varInfo}
        val localVarInfo = (sivarInfo, tag, size)

        val localVars =
            case LocalVarID.Map.find (#localVars context, id) of
              NONE => LocalVarID.Map.insert (#localVars context, id, localVarInfo)
            | SOME (_, tag2, size2) =>
              if tagEq (tag, tag2) andalso sizeEq (size, size2)
              then #localVars context
              else raise Control.Bug ("local var " ^ LocalVarID.toString id
                                      ^ " in different type")
      in
        ({
           isTopLevel = #isTopLevel context,
           constants = #constants context,
           pendingBlocks = #pendingBlocks context,
           visitedBlocks = #visitedBlocks context,
           localVars = localVars,
           localLabels = #localLabels context,
           exnVar = #exnVar context,
           handlerVar = #handlerVar context,
           handlerLabel = #handlerLabel context,
           epilogue = #epilogue context
         } : context,
         sivarInfo)
      end

  fun addLocalVarList context (var::varList) =
      let
        val (context, var) = addLocalVar context var
        val (context, vars) = addLocalVarList context varList
      in
        (context, var::vars)
      end
    | addLocalVarList context nil = (context, nil)

  fun addParamList context paramList =
      #1 (addLocalVarList context paramList)

  fun addLocalLabel (context as {localLabels, ...}:context) ailabel =
      case LocalVarID.Map.find (localLabels, ailabel) of
        SOME newLabel => (context, newLabel)
      | NONE =>
        let
          val newLabel = Counters.newLocalId ()
        in
          ({
             isTopLevel = #isTopLevel context,
             constants = #constants context,
             pendingBlocks = #pendingBlocks context,
             visitedBlocks = #visitedBlocks context,
             localVars = #localVars context,
             localLabels = LocalVarID.Map.insert (localLabels, ailabel, newLabel),
             exnVar = #exnVar context,
             handlerVar = #handlerVar context,
             handlerLabel = #handlerLabel context,
             epilogue = #epilogue context
           } : context,
           newLabel)
        end

  fun requireHandler (context as {handlerVar, handlerLabel, ...}:context) =
      case (handlerVar, handlerLabel) of
        (SOME _, SOME _) => context
      | _ =>
        let
          val (context, exnVar) = newVar context AI.Boxed SI.SINGLE
          val (context, handlerVar) = newVar context AI.Unboxed SI.SINGLE
          val handlerLabel = Counters.newLocalId ()
        in
          {
            isTopLevel = #isTopLevel context,
            constants = #constants context,
            pendingBlocks = #pendingBlocks context,
            visitedBlocks = #visitedBlocks context,
            localVars = #localVars context,
            localLabels = #localLabels context,
            exnVar = SOME exnVar,
            handlerVar = SOME handlerVar,
            handlerLabel = SOME (Counters.newLocalId ()),
            (* guardedStart is dummy *)
            epilogue = [SI.PopHandler {guardedStart = handlerLabel}]
          } : context
        end

  fun requestBlock context blockLabel =
      let
        val (context, newLabel) = addLocalLabel context blockLabel

        val pendingBlocks =
            if LocalVarID.Set.member (#visitedBlocks context, blockLabel)
            then #pendingBlocks context
            else blockLabel :: #pendingBlocks context
      in
        ({
           isTopLevel = #isTopLevel context,
           constants = #constants context,
           pendingBlocks = pendingBlocks,
           visitedBlocks = LocalVarID.Set.add (#visitedBlocks context, blockLabel),
           localVars = #localVars context,
           localLabels = #localLabels context,
           exnVar = #exnVar context,
           handlerVar = #handlerVar context,
           handlerLabel = #handlerLabel context,
           epilogue = #epilogue context
         } : context,
         newLabel)
      end

  fun popRequestedBlockLabel (context as {pendingBlocks, ...}:context) =
      case pendingBlocks of
        nil => (context, NONE)
      | h::t =>
        ({
           isTopLevel = #isTopLevel context,
           constants = #constants context,
           pendingBlocks = t,
           visitedBlocks = #visitedBlocks context,
           localVars = #localVars context,
           localLabels = #localLabels context,
           exnVar = #exnVar context,
           handlerVar = #handlerVar context,
           handlerLabel = #handlerLabel context,
           epilogue = #epilogue context
         } : context,
         SOME h)

  (***************************************************************************)

  fun transformVarInfo ({id, displayName, ...} : AI.varInfo) =
      {id = id, displayName = displayName} : SI.varInfo

  fun transformParamInfo (paramInfo:AI.paramInfo) =
      transformVarInfo paramInfo

  fun transformMove (context:context) dst size value =
      case value of
        AI.SInt x =>
        (context,
         [ SI.LoadInt {destination = dst, value = Target.SIntToSInt32 x} ])
      | AI.UInt x =>
        (context,
         [ SI.LoadWord {destination = dst, value = Target.UIntToUInt32 x} ])
      | AI.Real x =>
        (context,
         [ SI.LoadReal {destination = dst, value = x} ])
      | AI.Float x =>
        (context,
         [ SI.LoadFloat {destination = dst, value = x} ])
      | AI.Var var =>
        (context,
         [ SI.Access {destination = dst,
                      variableSize = size,
                      variableEntry = transformVarInfo var} ])
      | AI.Param param =>
        (context,
         [ SI.Access {destination = dst,
                      variableSize = size,
                      variableEntry = transformParamInfo param} ])
      | AI.Exn param =>
        (context,
         [ SI.Access {destination = dst,
                      variableSize = size,
                      variableEntry = transformParamInfo param} ])
      | AI.Env =>
        (context, [ SI.GetEnv {destination = dst} ])
      | AI.Nowhere =>
        transformMove context dst size AI.Null
      | AI.Null =>
        (context, [ SI.LoadWord {destination = dst, value = NullValue} ])
      | AI.Empty =>
        (context, [ SI.LoadEmptyBlock {destination = dst} ])
      | AI.Entry {clusterId, entry} =>
        (context, [ SI.LoadAddress {address = entry, destination = dst} ])
      | AI.Label label =>
        let
          val (context, label) = requestBlock context label
        in
          (context, [ SI.LoadAddress {address = label, destination = dst} ])
        end
      | AI.Global {label = {label, ...}, ...} =>
        (* AI.Global and AI.Extern are translated by transformInsn *)
        raise Control.Bug ("transformMove: Global "^label)
      | AI.Extern {label = {value = SOME (AI.GLOBAL_TAG x), ...}, ...} =>
        transformMove context dst size (AI.UInt (Target.toUInt x))
      | AI.Extern {label = {label, ...}, ...} =>
        raise Control.Bug ("transformMove: Extern "^label)
      | AI.Init constId =>
        transformMove context dst size (AI.Const constId)
      | AI.Const constId =>
        case LocalVarID.Map.find (#constants context, constId) of
          SOME (AI.ConstReal x) =>
          (* FIXME: actually a boxed real *)
          (context, [ SI.LoadReal {destination = dst, value = x} ])
        | SOME (AI.ConstString _) =>
          let
            val (context, newId) = addLocalLabel context constId
          in
            (context, [ SI.LoadString {destination = dst, string = newId} ])
          end
        | SOME (AI.ConstIntInf _) =>
          let
            val (context, newId) = addLocalLabel context constId
          in
            (context, [ SI.LoadLargeInt {destination = dst, value = newId} ])
          end
        | SOME (AI.ConstObject _) =>
          raise Control.Bug "transformMove: ConstObject is not supported"
        | NONE =>
          raise Control.Bug "transformMove: Const"

  fun transformArg context value =
      let
        fun load tag size value =
            let
              val (context, dst) = newVar context tag size
              val (context, insn) = transformMove context dst size value
            in
              (context, insn, dst)
            end
      in
        case value of
          AI.SInt x => load AI.Unboxed SI.SINGLE value
        | AI.UInt x => load AI.Unboxed SI.SINGLE value
        | AI.Real x => load AI.Unboxed SI.DOUBLE value
        | AI.Float x => load AI.Unboxed SI.SINGLE value
        | AI.Var var => (context, nil, transformVarInfo var)
        | AI.Param param => (context, nil, transformParamInfo param)
        | AI.Exn param => (context, nil, transformParamInfo param)
        | AI.Env => load AI.Boxed SI.SINGLE value
        | AI.Nowhere => transformArg context AI.Null
        | AI.Null =>
          load AI.Unboxed SI.SINGLE (AI.UInt (Target.toUInt NullValue))
        | AI.Empty => load AI.Boxed SI.SINGLE value
        | AI.Init _ => load AI.Boxed SI.SINGLE value (* always boxed *)
        | AI.Const _ => load AI.Boxed SI.SINGLE value
        | AI.Label x => load AI.Unboxed SI.SINGLE value
        | AI.Entry x => load AI.Unboxed SI.SINGLE value
        | AI.Global _ => load AI.Unboxed SI.SINGLE value
        | AI.Extern _ => load AI.Unboxed SI.SINGLE value
      end

  fun transformArgList context (value::valueList) =
      let
        val (context, insn1, value) = transformArg context value
        val (context, insn2, values) = transformArgList context valueList
      in
        (context, insn1 @ insn2, value::values)
      end
    | transformArgList context nil = (context, nil, nil)

  fun transformSize value =
      case value of
        AI.SISINGLE => SI.SINGLE
      | AI.SIDOUBLE => SI.DOUBLE
      | AI.SIVARIANT varInfo => SI.VARIANT (transformVarInfo varInfo)
      | AI.SIPARAMVARIANT paramInfo => SI.VARIANT (transformParamInfo paramInfo)
      | AI.SIIGNORE => raise Control.Bug "transformSize"

  fun transformAISize value =
      transformSize
          (case value of
             AI.UInt 0w1 => AI.SISINGLE
           | AI.UInt 0w2 => AI.SIDOUBLE
           | AI.Var varInfo => AI.SIVARIANT varInfo
           | AI.Param paramInfo => AI.SIPARAMVARIANT paramInfo
           | _ => raise Control.Bug "transformAISize")

  fun bindSizeList context nil =
      (context, nil, nil)
    | bindSizeList context (size::sizeList) =
      case wordOf size of
        SOME w =>
        let
          val (context, var) = newVar context AI.Unboxed SI.SINGLE
          val (context, insn, vars) = bindSizeList context sizeList
        in
          (context, SI.LoadWord {destination = var, value = w}::insn, var::vars)
        end
      | NONE =>
        let
          val var = case size of SI.VARIANT var => var
                               | _ => raise Control.Bug "bindSizeList"
          val (context, insn, vars) = bindSizeList context sizeList
        in
          (context, insn, var::vars)
        end

  fun calcSizeTag (argTys, [retTy]) =
      funTypeToCaseTag (map sizeof argTys, sizeof retTy)
    | calcSizeTag _ = raise Control.Bug "calcSizeTag"

  fun findPrimitive primName =
      valOf (List.find (fn prim as {bindName, ...} => primName = bindName)
                       Primitives.allPrimitives)
      handle Option =>
             raise Control.Bug ("findPrimitive: undefined: " ^ primName)

  fun transformCopyBlock context dstEntry argList =
      let
        val (context, insn1, argEntries) = transformArgList context argList
        val blockEntry =
            case argEntries of
              [x] => x
            | _ => raise Control.Bug "transformCopyBlock"

        val (context, nestEntry) = newVar context AI.Unboxed SI.SINGLE
      in
        (context,
         insn1 @
         [
          SI.LoadWord {destination = nestEntry, value = 0w0},
          SI.CopyBlock {destination = dstEntry,
                        blockEntry = blockEntry,
                        nestLevelEntry = nestEntry}
          ])
      end

  fun transformStrCmp context dstEntry argList =
      let
        val (context, insn1, argEntries) = transformArgList context argList
        val (context, lt) = newVar context AI.Unboxed SI.SINGLE
        val (context, gt) = newVar context AI.Unboxed SI.SINGLE
      in
        (*
         * kludge: emulate StrCmp by ltString and gtString.
         * According to VirtualMachine.cc, ltString and gtString returns
         * either 0 (false) or 1 (true). Thus,
         *
         * strcmp (s1, s2) = gtString (s1, s2) - ltString (s1, s2)
         *)
        (context,
         insn1 @
         [
           SI.CallPrim {destination = gt,
                        primitive = findPrimitive "gtString",
                        argEntries = argEntries},
           SI.CallPrim {destination = lt,
                        primitive = findPrimitive "ltString",
                        argEntries = argEntries},
           SI.CallPrim {destination = dstEntry,
                        primitive = findPrimitive "subInt",
                        argEntries = [gt, lt]}
         ])
      end

  fun transformIntInfCmp context dstEntry argList =
      let
        val (context, insn1, argEntries) = transformArgList context argList
        val (context, lt) = newVar context AI.Unboxed SI.SINGLE
        val (context, gt) = newVar context AI.Unboxed SI.SINGLE
      in
        (* kludge: similar to transformStrCmp *)
        (context,
         insn1 @
         [
           SI.CallPrim {destination = gt,
                        primitive = findPrimitive "gtLargeInt",
                        argEntries = argEntries},
           SI.CallPrim {destination = lt,
                        primitive = findPrimitive "ltLargeInt",
                        argEntries = argEntries},
           SI.CallPrim {destination = dstEntry,
                        primitive = findPrimitive "subLargeInt",
                        argEntries = [gt, lt]}
         ])
      end

  fun transformLoadIntInf context dstEntry argList =
      let
        val (context, insn1, argEntries) = transformArgList context argList
        val argEntry =
            case argEntries of
              [x] => x
            | _ => raise Control.Bug "transformLoadIntInf"
      in
        (* loadIntInf is not needed because ConstIntInf is translated into
         * LoadLargeInt. *)
        (context,
         insn1 @
         [
           SI.Access {destination = dstEntry,
                      variableSize = SI.SINGLE,
                      variableEntry = argEntry}
         ])
      end

  fun transformMemcpy context dstEntry argList =
      let
        val (dst, dstOffset, src, srcOffset, length, tag) =
            case argList of
              [x1, x2, x3, x4, x5, x6] => (x1, x2, x3, x4, x5, x6)
            | _ => raise Control.Bug "transformMemcpy"

        val (context, insn1, src) = transformArg context src
        val (context, insn2, srcOffset) = transformArg context srcOffset
        val (context, insn3, dst) = transformArg context dst
        val (context, insn4, dstOffset) = transformArg context dstOffset
        val (context, insn5, length) = transformArg context length
      in
        (context,
         insn1 @ insn2 @ insn3 @ insn4 @ insn5 @
         [
           SI.CopyArray {srcEntry = src,
                         srcOffsetEntry = srcOffset,
                         dstEntry = dst,
                         dstOffsetEntry = dstOffset,
                         lengthEntry = length,
                         elementSize = SI.SINGLE}
         ])
      end

  fun transformPolyEqual context dstEntry argList =
      let
        val args =
            case argList of
              [arg1, arg2, sz, tag] => [arg1, arg2]
            | _ => raise Control.Bug "transformPolyEqual"

        val (context, insn1, argEntries) = transformArgList context args
      in
        (context,
         insn1 @
         [
           SI.CallPrim {destination = dstEntry,
                        primitive = findPrimitive "=",
                        argEntries = argEntries}
         ])
      end

  val specialPrimitives =
      foldl (fn ((k, v), map) => SEnv.insert (map, k, v))
            SEnv.empty
            [(AIPrimitive.copyBlockPrimName, transformCopyBlock),
             (AIPrimitive.strCmpPrimName, transformStrCmp),
             (AIPrimitive.intInfCmpPrimName, transformIntInfCmp),
             (AIPrimitive.loadIntInfPrimName, transformLoadIntInf),
             (AIPrimitive.memcpyPrimName, transformMemcpy),
             (AIPrimitive.polyEqualPrimName, transformPolyEqual)]

  fun transformPrim1 context {dst, op1, arg, loc} =
      let
        val primName =
            case op1 of
              (AI.Neg, AI.SINT, AI.SINT) => "negInt"
            | (AI.Neg, AI.DOUBLE, AI.DOUBLE) => "negReal"
            | (AI.Neg, AI.FLOAT, AI.FLOAT) => "negFloat"
            | (AI.Abs, AI.SINT, AI.SINT) => "absInt"
            | (AI.Abs, AI.DOUBLE, AI.DOUBLE) => "absReal"
            | (AI.Abs, AI.FLOAT, AI.FLOAT) => "absFloat"
            | (AI.Cast, AI.UINT, AI.SINT) => "Word_toIntX"
            | (AI.Cast, AI.SINT, AI.UINT) => "Word_fromInt"
            | (AI.Cast, AI.SINT, AI.DOUBLE) => "Real_fromInt"
            | (AI.Cast, AI.DOUBLE, AI.FLOAT) => "Real_toFloat"
            | (AI.Cast, AI.FLOAT, AI.DOUBLE) => "Real_fromFloat"
            | (AI.Cast, AI.CHAR, AI.SINT) => "Char_ord"
            | (AI.Cast, AI.SINT, AI.CHAR) => "Char_chr"
            | (AI.Notb, AI.UINT, AI.UINT) => "Word_notb"
(*
            | (AI.Length, AI.BOXED, AI.UINT) => "Array_length"
*)
            | _ => raise Control.Bug "transformPrim1"

        val (context, dst) = addLocalVar context dst
        val (context, insn1, argEntry) = transformArg context arg
      in
        (context,
         insn1 @
         [
           SI.CallPrim {destination = dst,
                        primitive = findPrimitive primName,
                        argEntries = [argEntry]}
         ])
      end

  fun transformPrim2 context {dst, op2, arg1, arg2, loc} =
      let
        val (context, dst) = addLocalVar context dst

        fun callPrim primName =
          let
            val (context, insn1, argEntry1) = transformArg context arg1
            val (context, insn2, argEntry2) = transformArg context arg2
          in
            (context,
             insn1 @ insn2 @
             [
               SI.CallPrim {destination = dst,
                            primitive = findPrimitive primName,
                            argEntries = [argEntry1, argEntry2]}
             ])
          end

        fun primInsn primName const1 const2 getConst =
            case (getConst arg1, getConst arg2) of
              (SOME argValue, NONE) =>
              let
                val (context, insn1, argEntry) = transformArg context arg2
              in
                (context,
                 insn1 @
                 [
                   const1 {destination = dst,
                           argValue1 = argValue,
                           argEntry2 = argEntry}
                 ])
              end
            | (NONE, SOME argValue) =>
              let
                val (context, insn1, argEntry) = transformArg context arg1
              in
                (context,
                 insn1 @
                 [
                   const2 {destination = dst,
                           argEntry1 = argEntry,
                           argValue2 = argValue}
                 ])
              end
            | _ =>
              callPrim primName

        fun argInt (AI.SInt x) = SOME (Target.SIntToSInt32 x)
          | argInt _ = NONE
        fun argWord (AI.UInt x) = SOME (Target.UIntToUInt32 x)
          | argWord _ = NONE
        fun argReal (AI.Real s) = SOME s
          | argReal _ = NONE
        fun argFloat (AI.Float s) = SOME s
          | argFloat _ = NONE
        val argByte = argWord
        val argChar = argWord
      in
        case op2 of
          (AI.MonoEqual, AI.DOUBLE, AI.DOUBLE, AI.UINT) =>
          callPrim "Real_equal"
        | (AI.MonoEqual, _, _, AI.UINT) =>
          callPrim "="
        | (AI.Add, AI.SINT, AI.SINT, AI.SINT) =>
          primInsn "addInt" SI.AddInt_Const_1 SI.AddInt_Const_2 argInt
        | (AI.Add, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE) =>
          primInsn "addReal" SI.AddReal_Const_1 SI.AddReal_Const_2 argReal
        | (AI.Add, AI.FLOAT, AI.FLOAT, AI.FLOAT) =>
          primInsn "addFloat" SI.AddFloat_Const_1 SI.AddFloat_Const_2 argFloat
        | (AI.Add, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "addWord" SI.AddWord_Const_1 SI.AddWord_Const_2 argWord
        | (AI.Add, AI.BYTE, AI.BYTE, AI.BYTE) =>
          primInsn "addByte" SI.AddByte_Const_1 SI.AddByte_Const_2 argByte
        | (AI.Sub, AI.SINT, AI.SINT, AI.SINT) =>
          primInsn "subInt" SI.SubInt_Const_1 SI.SubInt_Const_2 argInt
        | (AI.Sub, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE) =>
          primInsn "subReal" SI.SubReal_Const_1 SI.SubReal_Const_2 argReal
        | (AI.Sub, AI.FLOAT, AI.FLOAT, AI.FLOAT) =>
          primInsn "subFloat" SI.SubFloat_Const_1 SI.SubFloat_Const_2 argFloat
        | (AI.Sub, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "subWord" SI.SubWord_Const_1 SI.SubWord_Const_2 argWord
        | (AI.Sub, AI.BYTE, AI.BYTE, AI.BYTE) =>
          primInsn "subByte" SI.SubByte_Const_1 SI.SubByte_Const_2 argByte
        | (AI.Mul, AI.SINT, AI.SINT, AI.SINT) =>
          primInsn "mulInt" SI.MulInt_Const_1 SI.MulInt_Const_2 argInt
        | (AI.Mul, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE) =>
          primInsn "mulReal" SI.MulReal_Const_1 SI.MulReal_Const_2 argReal
        | (AI.Mul, AI.FLOAT, AI.FLOAT, AI.FLOAT) =>
          primInsn "mulFloat" SI.MulFloat_Const_1 SI.MulFloat_Const_2 argFloat
        | (AI.Mul, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "mulWord" SI.MulWord_Const_1 SI.MulWord_Const_2 argWord
        | (AI.Mul, AI.BYTE, AI.BYTE, AI.BYTE) =>
          primInsn "mulByte" SI.MulByte_Const_1 SI.MulByte_Const_2 argByte
        | (AI.Div, AI.SINT, AI.SINT, AI.SINT) =>
          primInsn "divInt" SI.DivInt_Const_1 SI.DivInt_Const_2 argInt
        | (AI.Div, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "divWord" SI.DivWord_Const_1 SI.DivWord_Const_2 argWord
        | (AI.Div, AI.BYTE, AI.BYTE, AI.BYTE) =>
          primInsn "divByte" SI.DivByte_Const_1 SI.DivByte_Const_2 argByte
        | (AI.Div, AI.DOUBLE, AI.DOUBLE, AI.DOUBLE) =>
          primInsn "/" SI.DivReal_Const_1 SI.DivReal_Const_2 argReal
        | (AI.Div, AI.FLOAT, AI.FLOAT, AI.FLOAT) =>
          primInsn "divFloat" SI.DivFloat_Const_1 SI.DivFloat_Const_2 argFloat
        | (AI.Mod, AI.SINT, AI.SINT, AI.SINT) =>
          primInsn "modInt" SI.ModInt_Const_1 SI.ModInt_Const_2 argInt
        | (AI.Mod, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "modWord" SI.ModWord_Const_1 SI.ModWord_Const_2 argWord
        | (AI.Mod, AI.BYTE, AI.BYTE, AI.BYTE) =>
          primInsn "modByte" SI.ModByte_Const_1 SI.ModByte_Const_2 argByte
        | (AI.Quot, AI.SINT, AI.SINT, AI.SINT) =>
          primInsn "quotInt" SI.QuotInt_Const_1 SI.QuotInt_Const_2 argInt
        | (AI.Rem, AI.SINT, AI.SINT, AI.SINT) =>
          primInsn "remInt" SI.RemInt_Const_1 SI.RemInt_Const_2 argInt
        | (AI.Lt, AI.SINT, AI.SINT, AI.UINT) =>
          primInsn "ltInt" SI.LtInt_Const_1 SI.LtInt_Const_2 argInt
        | (AI.Lt, AI.DOUBLE, AI.DOUBLE, AI.UINT) =>
          primInsn "ltReal" SI.LtReal_Const_1 SI.LtReal_Const_2 argReal
        | (AI.Lt, AI.FLOAT, AI.FLOAT, AI.UINT) =>
          primInsn "ltFloat" SI.LtFloat_Const_1 SI.LtFloat_Const_2 argFloat
        | (AI.Lt, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "ltWord" SI.LtWord_Const_1 SI.LtWord_Const_2 argWord
        | (AI.Lt, AI.BYTE, AI.BYTE, AI.UINT) =>
          primInsn "ltByte" SI.LtByte_Const_1 SI.LtByte_Const_2 argByte
        | (AI.Lt, AI.CHAR, AI.CHAR, AI.UINT) =>
          primInsn "ltChar" SI.LtChar_Const_1 SI.LtChar_Const_2 argChar
        | (AI.Gt, AI.SINT, AI.SINT, AI.UINT) =>
          primInsn "gtInt" SI.GtInt_Const_1 SI.GtInt_Const_2 argInt
        | (AI.Gt, AI.DOUBLE, AI.DOUBLE, AI.UINT) =>
          primInsn "gtReal" SI.GtReal_Const_1 SI.GtReal_Const_2 argReal
        | (AI.Gt, AI.FLOAT, AI.FLOAT, AI.UINT) =>
          primInsn "gtFloat" SI.GtFloat_Const_1 SI.GtFloat_Const_2 argFloat
        | (AI.Gt, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "gtWord" SI.GtWord_Const_1 SI.GtWord_Const_2 argWord
        | (AI.Gt, AI.BYTE, AI.BYTE, AI.UINT) =>
          primInsn "gtByte" SI.GtByte_Const_1 SI.GtByte_Const_2 argByte
        | (AI.Gt, AI.CHAR, AI.CHAR, AI.UINT) =>
          primInsn "gtChar" SI.GtChar_Const_1 SI.GtByte_Const_2 argChar
        | (AI.Lteq, AI.SINT, AI.SINT, AI.UINT) =>
          primInsn "lteqInt" SI.LteqInt_Const_1 SI.LteqInt_Const_2 argInt
        | (AI.Lteq, AI.DOUBLE, AI.DOUBLE, AI.UINT) =>
          primInsn "lteqReal" SI.LteqReal_Const_1 SI.LteqReal_Const_2 argReal
        | (AI.Lteq, AI.FLOAT, AI.FLOAT, AI.UINT) =>
          primInsn "lteqFloat" SI.LteqFloat_Const_1 SI.LteqFloat_Const_2
                   argFloat
        | (AI.Lteq, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "lteqWord" SI.LteqWord_Const_1 SI.LteqWord_Const_2 argWord
        | (AI.Lteq, AI.BYTE, AI.BYTE, AI.UINT) =>
          primInsn "lteqByte" SI.LteqByte_Const_1 SI.LteqByte_Const_2 argByte
        | (AI.Lteq, AI.CHAR, AI.CHAR, AI.UINT) =>
          primInsn "lteqChar" SI.LteqChar_Const_1 SI.LteqChar_Const_2 argChar
        | (AI.Gteq, AI.SINT, AI.SINT, AI.UINT) =>
          primInsn "gteqInt" SI.GteqInt_Const_1 SI.GteqInt_Const_2 argInt
        | (AI.Gteq, AI.DOUBLE, AI.DOUBLE, AI.UINT) =>
          primInsn "gteqReal" SI.GteqReal_Const_1 SI.GteqReal_Const_2 argReal
        | (AI.Gteq, AI.FLOAT, AI.FLOAT, AI.UINT) =>
          primInsn "gteqFloat" SI.GteqFloat_Const_1 SI.GteqFloat_Const_2
                   argFloat
        | (AI.Gteq, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "gteqWord" SI.GteqWord_Const_1 SI.GteqWord_Const_2 argWord
        | (AI.Gteq, AI.BYTE, AI.BYTE, AI.UINT) =>
          primInsn "gteqByte" SI.GteqByte_Const_1 SI.GteqByte_Const_2 argByte
        | (AI.Gteq, AI.CHAR, AI.CHAR, AI.UINT) =>
          primInsn "gteqChar" SI.GteqChar_Const_1 SI.GteqChar_Const_2 argChar
        | (AI.Andb, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "Word_andb" SI.Word_andb_Const_1 SI.Word_andb_Const_2 argWord
        | (AI.Orb, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "Word_orb" SI.Word_orb_Const_1 SI.Word_orb_Const_2 argWord
        | (AI.Xorb, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "Word_xorb" SI.Word_xorb_Const_1 SI.Word_xorb_Const_2 argWord
        | (AI.LShift, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "Word_leftShift"
                   SI.Word_leftShift_Const_1 SI.Word_leftShift_Const_2 argWord
        | (AI.RShift, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "Word_logicalRightShift"
                   SI.Word_logicalRightShift_Const_1
                   SI.Word_logicalRightShift_Const_2 argWord
        | (AI.ArithRShift, AI.UINT, AI.UINT, AI.UINT) =>
          primInsn "Word_arithmeticRightShift"
                   SI.Word_arithmeticRightShift_Const_1
                   SI.Word_arithmeticRightShift_Const_2 argWord
        | (op2, ty1, ty2, ty3) =>
          raise Control.Bug
                    ("transformPrim2: " ^
                     Control.prettyPrint (AI.format_op2 (nil, nil) op2) ^ ", " ^
                     Control.prettyPrint (AI.format_ty ty1) ^ ", " ^
                     Control.prettyPrint (AI.format_ty ty2) ^ ", " ^
                     Control.prettyPrint (AI.format_ty ty3))
      end

  (* kludge: equivalent to implementation of MakeClosure. *)
  fun makeClosure context entry env =
      let
        val (context, bitmapEntry) = newVar context AI.Unboxed SI.SINGLE
        val (context, dstEntry) = newVar context AI.Boxed SI.SINGLE
      in
        (context,
         [
           SI.LoadWord {destination = bitmapEntry, value = 0w2},
           SI.MakeBlockOfSingleValues {destination = dstEntry,
                                       bitmapEntry = bitmapEntry,
                                       fieldEntries = [entry, env]}
         ],
         dstEntry)
      end

  fun transformInsn context insn =
      case insn of
        AI.Move {dst, ty, value, loc, size} =>
        let
          val (context, dst) = addLocalVar context dst
          val size = transformSize size
          val (context, insn1) = transformMove context dst size value
        in
          (context, insn1)
        end

      | AI.Load {dst, ty, block = AI.Extern {label, ty = bty},
                 offset = AI.UInt 0w0, size, loc} =>
        transformInsn context
          (AI.Load {dst = dst,
                    ty = ty,
                    block = AI.Global {label = label, ty = bty},
                    offset = AI.UInt 0w0,
                    size = size,
                    loc = loc})

      | AI.Load {dst, ty,
                 block = AI.Global
                             {label = {value = SOME (AI.GLOBAL_VAR
                                                       {arrayIndex, offset}),
                                       ...}, ...},
                 offset = AI.UInt 0w0, size, loc} =>
        let
          val (context, dst) = addLocalVar context dst
        in
          (context,
           [
             SI.GetGlobal {globalArrayIndex = arrayIndex,
                           offset = offset,
                           variableSize = transformAISize size,
                           destination = dst}
           ])
        end

      | AI.Load {dst, ty, block = AI.Env, offset = AI.UInt offset, size, loc} =>
        let
          val (context, dst) = addLocalVar context dst
        in
          (context,
           [
             SI.AccessEnv {destination = dst,
                           variableSize = transformAISize size,
                           offset = Target.UIntToUInt32 offset}
           ])
        end

      | AI.Load {dst, ty, block, offset = AI.UInt offset, size, loc} =>
        let
          val (context, dst) = addLocalVar context dst
          val (context, insn1, blockEntry) = transformArg context block
        in
          (context,
           insn1 @
           [
             SI.GetField {destination = dst,
                          blockEntry = blockEntry,
                          fieldOffset = Target.UIntToUInt32 offset,
                          fieldSize = transformAISize size}
           ])
        end

      | AI.Load {dst, ty, block, offset, size, loc} =>
        let
          val (context, dst) = addLocalVar context dst
          val (context, insn1, blockEntry) = transformArg context block
          val (context, insn2, offsetEntry) = transformArg context offset
        in
          (context,
           insn1 @ insn2 @
           [
             SI.GetFieldIndirect {destination = dst,
                                  blockEntry = blockEntry,
                                  fieldOffsetEntry = offsetEntry,
                                  fieldSize = transformAISize size}
           ])
        end

      | AI.Update {block = AI.Extern {label, ty=bty},
                   offset = AI.UInt 0w0, size, ty, value, barrier, loc} =>
        transformInsn context
          (AI.Update {block = AI.Global {label = label, ty = bty},
                      offset = AI.UInt 0w0,
                      size = size, ty = ty, value = value,
                      barrier = barrier, loc = loc})

      | AI.Update {block = AI.Global
                               {label = {value = SOME (AI.GLOBAL_VAR
                                                         {arrayIndex, offset}),
                                         ...}, ...},
                   offset = AI.UInt 0w0,
                   size, ty, value, barrier, loc} =>
        let
          val (context, insn1, valueEntry) = transformArg context value
        in
          (context,
           insn1 @
           [
             SI.SetGlobal {newValueEntry = valueEntry,
                           globalArrayIndex = Target.UIntToUInt32 arrayIndex,
                           offset = Target.UIntToUInt32 offset,
                           variableSize = transformAISize size}
           ])
        end

      | AI.Update {block, offset = AI.UInt offset, size, ty, value, barrier,
                   loc} =>
        let
          val (context, insn1, blockEntry) = transformArg context block
          val (context, insn2, valueEntry) = transformArg context value
        in
          (context,
           insn1 @ insn2 @
           [
             SI.SetField {blockEntry = blockEntry,
                          fieldOffset = Target.UIntToUInt32 offset,
                          newValueEntry = valueEntry,
                          fieldSize = transformAISize size}
           ])
        end

      | AI.Update {block, offset, size, ty, value, barrier, loc} =>
        let
          val (context, insn1, blockEntry) = transformArg context block
          val (context, insn2, offsetEntry) = transformArg context offset
          val (context, insn3, valueEntry) = transformArg context value
        in
          (context,
           insn1 @ insn2 @ insn3 @
           [
             SI.SetFieldIndirect {blockEntry = blockEntry,
                                  fieldOffsetEntry = offsetEntry,
                                  newValueEntry = valueEntry,
                                  fieldSize = transformAISize size}
           ])
        end

      | AI.Alloc {dst, objectType = AI.Record, bitmaps = [bitmap],
                  payloadSize, fieldInfo, loc} =>
        let
          val (context, insn1, bitmapEntry) = transformArg context bitmap
          val (context, dstEntry) = addLocalVar context dst

          (*
           * kludge: emulate AllocBlock by MakeBlock.
           *
           * Even if initial values are not given, MakeBlock itself works fine
           * and allocates an block without initialization. But GC may be
           * collapsed by such uninitialized block.
           * We need to construct dummy initial values here for at least
           * pointer slots.
           *
           * Yeah, this is a really kludge ;p
           *)
          val var1 = ref NONE
          val var2 = ref NONE

          fun touch context varref =
              case !varref of
                SOME var => (context, var)
              | NONE =>
                let
                  val (context, var) = newVar context AI.Unboxed SI.SINGLE
                in
                  varref := SOME var;
                  (context, var)
                end

          fun makeInitValues context nil =
              (context, nil, nil, nil)
            | makeInitValues context ({size, tag}::fieldInfoList) =
              let
                val size = transformSize size

                val (context, insn1, sizes, values) =
                    case tag of
                      AI.Unboxed =>
                      (* Current MakeBlock implementation allows to initialize
                       * DOUBLE slots with SINGLE values.
                       * In order to reduce the number of the dummy variables,
                       * here we use two SINGLE entries for initializing a
                       * DOUBLE slot.
                       *)
                      let
                        val (context, var) =
                            case size of
                              SI.VARIANT _ => newVar context tag size
                            | _ => touch context var1
                      in
                        case size of
                          SI.DOUBLE =>
                          (context, nil, [SI.SINGLE, SI.SINGLE], [var, var])
                        | _ =>
                          (context, nil, [size], [var])
                      end
                    | AI.Boxed =>
                      (* For boxed field, we use dstEntry with being
                       * initialized by LoadEmptyBlock as initial value.
                       *)
                      (context, nil, [size], [dstEntry])
                    | tag =>
                      (* Since tag is not known statically, we need to
                       * select appropriate initialValue at runtime.
                       * We allocate an dummy entry for initial value, and
                       * if tag = 0 then initialize the entry with
                       * LoadEmptyBlock.
                       *)
                      let
                        val (context, var) = newVar context tag size
                        val initLabel = Counters.newLocalId ()
                        val allocLabel = Counters.newLocalId ()

                        val (context, insn, tagvar) =
                            case tag of
                              AI.ParamTag param =>
                              (context, nil, transformParamInfo param)
                            | AI.IndirectTag {offset, bit} =>
                              let
                                val (context, var) = touch context var1
                              in
                                (context,
                                 [
                                   SI.AccessEnv
                                       {destination = var,
                                        variableSize = SI.SINGLE,
                                        offset = Target.UIntToUInt32 offset},
                                   SI.Word_andb_Const_2
                                       {destination = var,
                                        argEntry1 = var,
                                        argValue2 = Target.UInt.<< (0w1, bit)}
                                 ],
                                 var)
                              end
                            | _ => raise Control.Bug "makeInitValues"
                      in
                        (context,
                         insn @
                         [
                           SI.SwitchWord {targetEntry = tagvar,
                                          cases = [{const = 0w0,
                                                    destination = allocLabel}],
                                          default = initLabel},
                           SI.Label initLabel,
                           SI.LoadEmptyBlock {destination = var},
                           SI.Label allocLabel
                         ],
                         [size], [var])
                      end

                val (context, insn2, sizeList, valueList) =
                    makeInitValues context fieldInfoList
              in
                (context, insn1 @ insn2, sizes @ sizeList, values @ valueList)
              end

          val (context, insn2, fieldSizeList, initEntries) =
              makeInitValues context fieldInfo

          (* If dst is used as an initial value, we need to initialize dst
           * prior to MakeBlock. *)
          val insn3 =
              if List.exists (fn {id,...} => LocalVarID.eq (id, #id dstEntry))
                             initEntries
              then [SI.LoadEmptyBlock {destination = dstEntry}]
              else nil

          val fixedTotalSize = case payloadSize of
                                 AI.UInt x => SOME x | _ => NONE
          val sizeListKind = computeSizeListKind fieldSizeList
        in
          (* select appropriate instruction according to sizes. *)
          if (case sizeListKind of
                SingleSizeList => true
              | SingletonSizeList SI.SINGLE => true
              | LastArbitrarySizeList SI.SINGLE => true
              | _ => false)
             andalso fixedTotalSize
                     = SOME (Target.intToUInt (length initEntries))
          then
            (context,
             insn1 @ insn2 @ insn3 @
             [
               SI.MakeBlockOfSingleValues {destination = dstEntry,
                                           bitmapEntry = bitmapEntry,
                                           fieldEntries = initEntries}
             ])
          else
            case (fixedTotalSize, sizeListKind) of
              (SOME 0w2, SingletonSizeList SI.DOUBLE) =>
              (context,
               insn1 @ insn2 @ insn3 @
               [
                 SI.MakeFixedSizeBlock {destination = dstEntry,
                                        bitmapEntry = bitmapEntry,
                                        size = 0w2,
                                        fieldEntries = initEntries,
                                        fieldSizes = [0w2]}
               ])
            | (SOME payloadSize, LastArbitrarySizeList SI.DOUBLE) =>
              (context,
               insn1 @ insn2 @ insn3 @
               [
                 SI.MakeFixedSizeBlock
                     {destination = dstEntry,
                      bitmapEntry = bitmapEntry,
                      size = Target.UIntToUInt32 payloadSize,
                      fieldEntries = initEntries,
                      fieldSizes = map (valOf o wordOf) fieldSizeList}
               ])
            | (SOME payloadSize, FixedSizeList sizeList) =>
              (context,
               insn1 @ insn2 @ insn3 @
               [
                 SI.MakeFixedSizeBlock {destination = dstEntry,
                                        bitmapEntry = bitmapEntry,
                                        size = Target.UIntToUInt32 payloadSize,
                                        fieldEntries = initEntries,
                                        fieldSizes = sizeList}
               ])
            | _ =>
              let
                val (context, insn4, sizeEntry) =
                    transformArg context payloadSize

                (* MakeBlock requires that all size information are bound
                 * to some entries.
                 *)
                val (context, fieldSizeEntries) =
                    foldr
                      (fn (SI.VARIANT var, (context, entries)) =>
                          (context, var::entries)
                        | (SI.SINGLE, (context, entries)) =>
                          let
                            val (context, var) = touch context var1
                          in
                            (context, var::entries)
                          end
                        | (SI.DOUBLE, (context, entries)) =>
                          let
                            val (context, var) = touch context var2
                          in
                            (context, var::entries)
                          end)
                      (context, nil)
                      fieldSizeList

                fun initSizeEntryIfUsed entry initValue =
                    case !entry of
                      NONE => nil
                    | SOME (var as {id = x,...}) =>
                      if List.exists (fn {id,...} => LocalVarID.eq (id, x))
                                     fieldSizeEntries
                      then [SI.LoadWord {destination = var, value = initValue}]
                      else nil

                val insn5 = initSizeEntryIfUsed var1 0w1
                val insn6 = initSizeEntryIfUsed var2 0w2
              in
                (context,
                 insn1 @ insn2 @ insn3 @ insn4 @ insn5 @ insn6 @
                 [
                   SI.MakeBlock {destination = dstEntry,
                                 bitmapEntry = bitmapEntry,
                                 sizeEntry = sizeEntry,
                                 fieldEntries = initEntries,
                                 fieldSizeEntries = fieldSizeEntries}
                 ])
              end
        end

      | AI.Alloc {dst, objectType, bitmaps = [bitmap],
                  payloadSize, fieldInfo = [{size, tag}], loc} =>
        let
          (* kludge: emulate AllocArray by MakeArray.
           *         To do this, we need to pass through several
           *         validity checks.
           *)
          (* NOTE: MakeArray has polymorphic behaviour according to
           *       bitmap and initialValueSize. *)
          val (context, insn1, bitmapEntry) = transformArg context bitmap
          val (context, insn2, sizeEntry) = transformArg context payloadSize
          val size = transformSize size
          val (context, dstEntry) = addLocalVar context dst
          val isMutable =
              case objectType
               of AI.Array => true
                | AI.Vector => false
                | _ =>
                  raise
                    Control.Bug "transformIsmn: Alloc unexpected objectType"
        in
          case (bitmap, size) of
            (AI.UInt 0w0, SI.SINGLE) =>
            (context,
             insn1 @ insn2 @
             [
               (* use bitmapEntry as initialValue. *)
               SI.MakeArray {destination = dstEntry,
                             bitmapEntry = bitmapEntry,
                             sizeEntry = sizeEntry,
                             initialValueEntry = bitmapEntry,
                             initialValueSize = size,
                             isMutable = isMutable}
             ])

          (* if bitmap = 0, initialValue never be checked its validity.
           * So we can use safely an uninitialized entry as initialValue.
           * Either Assembler or StackReallocator might complain ;p
           *)
          | (AI.UInt 0w0, _) =>
            let
              val (context, var) = newVar context AI.Unboxed size
            in
              (context,
               insn1 @ insn2 @
               [
                 SI.MakeArray {destination = dstEntry,
                               bitmapEntry = bitmapEntry,
                               sizeEntry = sizeEntry,
                               initialValueEntry = var,
                               initialValueSize = size,
                               isMutable = isMutable}
               ])
            end

          (* if bitmap = 1, initialValue must be an valid pointer.
           * Here we use the destination entry as not only destination
           * but also initialValue with initializing it by Empty.
           *)
          | (AI.UInt 0w1, _) =>
            (context,
             insn1 @ insn2 @
             [
               SI.LoadEmptyBlock {destination = dstEntry},
               SI.MakeArray {destination = dstEntry,
                             bitmapEntry = bitmapEntry,
                             sizeEntry = sizeEntry,
                             initialValueEntry = dstEntry,
                             initialValueSize = size,
                             isMutable = isMutable}
             ])

          (* otherwise, we need to choice appropriate initialValue at runtime.
           * At first, we allocate an entry for initial value.
           * Just before MakeArray, we check the value of bitmap.
           * if bitmap = 1, then LoadEmptyBlock to the entry.
           * Otherwise, we don't need to initialize the entry.
           *)
          | _ =>
            let
              val (context, initValueEntry) = newVar context tag size
              val initLabel = Counters.newLocalId ()
              val allocLabel = Counters.newLocalId ()
            in
              (context,
               insn1 @ insn2 @
               [
                 SI.SwitchWord {targetEntry = bitmapEntry,
                                cases = [{const = 0w1,
                                          destination = initLabel}],
                                default = allocLabel},
                 SI.Label initLabel,
                 SI.LoadEmptyBlock {destination = initValueEntry},
                 SI.Label allocLabel,
                 SI.MakeArray {destination = dstEntry,
                               bitmapEntry = bitmapEntry,
                               sizeEntry = sizeEntry,
                               initialValueEntry = initValueEntry,
                               initialValueSize = size,
                               isMutable = isMutable}
               ])
            end
        end

      | AI.Alloc _ =>
        raise Control.Bug "transformInsn: Alloc"

      | AI.PrimOp1 prim1 =>
        transformPrim1 context prim1

      | AI.PrimOp2 prim2 =>
        transformPrim2 context prim2

      | AI.CallExt {dstVarList = [dst],
                    callee = AI.Primitive {oldPrimName, name, ...},
                    argList, calleeTy, loc} =>
        let
          val (context, dst) = addLocalVar context dst
        in
          case SEnv.find (specialPrimitives, name) of
            SOME f => f context dst argList
          | NONE =>
            let
              val (context, insn1, argEntries) =
                  transformArgList context argList
            in
              (context,
               insn1 @
               [
                 SI.CallPrim {destination = dst,
                              primitive = findPrimitive oldPrimName,
                              argEntries = argEntries}
               ])
            end
        end

      | AI.CallExt {dstVarList = [dst],
                    callee = AI.Foreign {function, attributes},
                    argList, calleeTy, loc} =>
        let
          val (context, dst) = addLocalVar context dst
          val (context, insn1, funEntry) = transformArg context function
          val (context, insn2, argEntries) = transformArgList context argList
        in
          (context,
           insn1 @ insn2 @
           [
             SI.ForeignApply {destination = dst,
                              switchTag = calcSizeTag calleeTy,
                              attributes = attributes,
                              closureEntry = funEntry,
                              argEntries = argEntries}
           ])
        end

      | AI.CallExt {dstVarList = [], callee, argList,
                    calleeTy = (argTys, []), loc} =>
        transformInsn context
            (AI.CallExt {dstVarList = [newAIVar AI.UINT],
                         callee = callee,
                         argList = argList,
                         calleeTy = (argTys, [AI.UINT]),
                         loc = loc})

      | AI.CallExt _ =>
        raise Control.Bug "transformInsn: CallExt"

      | AI.ExportClosure {dst, entry, env, exportTy, loc} =>
        let
          val (context, dst) = addLocalVar context dst
          val (context, insn1, entry) = transformArg context entry
          val (context, insn2, env) = transformArg context env
          val (context, insn3, closureEntry) = makeClosure context entry env
        in
          (context,
           insn1 @ insn2 @ insn3 @
           [
             SI.RegisterCallback {destination = dst,
                                  sizeTag = calcSizeTag exportTy,
                                  closureEntry = closureEntry}
           ])
        end

      | AI.Call {dstVarList, entry = AI.Entry {entry, ...}, env,
                 argList, argSizeList, argTyList, resultTyList, loc} =>
        let
          (* NOTE: We never use RecursiveCallStatic family.
           *       RecursiveCallStatic requires that the size of stack
           *       frame of callee is equal to one of caller.
           *       YASIGenerator cannot satisfy this requirement because
           *       we devide cluster for each functions, and calculates
           *       frameInfo for each individual clusters.
           *)
          val (context, insn1, envEntry) = transformArg context env
          val (context, insn2, argEntries) = transformArgList context argList
          val argSizes = map transformSize argSizeList
          val (context, dsts) = addLocalVarList context dstVarList
        in
          case computeSizeListKind argSizes of
            EmptySizeList =>
            (context,
             insn1 @ insn2 @
             [ SI.CallStatic_0 {destinations = dsts,
                                entryPoint = entry,
                                envEntry = envEntry} ])
          | SingletonSizeList size =>
            (context,
             insn1 @ insn2 @
             [ SI.CallStatic_1 {destinations = dsts,
                                entryPoint = entry,
                                envEntry = envEntry,
                                argEntry = List.hd argEntries,
                                argSize = List.hd argSizes} ])
          | SingleSizeList =>
            (context,
             insn1 @ insn2 @
             [ SI.CallStatic_MS {destinations = dsts,
                                 entryPoint = entry,
                                 envEntry = envEntry,
                                 argEntries = argEntries} ])
          | LastArbitrarySizeList size =>
            (context,
             insn1 @ insn2 @
             [ SI.CallStatic_ML {destinations = dsts,
                                 entryPoint = entry,
                                 envEntry = envEntry,
                                 argEntries = argEntries,
                                 lastArgSize = size} ])
          | FixedSizeList sizeList =>
            (context,
             insn1 @ insn2 @
             [ SI.CallStatic_MF {destinations = dsts,
                                 entryPoint = entry,
                                 envEntry = envEntry,
                                 argEntries = argEntries,
                                 argSizes = sizeList} ])
          | VariantSizeList =>
            let
              val (context, insn3, sizeEntries) = bindSizeList context argSizes
            in
              (context,
               insn1 @ insn2 @ insn3 @
               [ SI.CallStatic_MV {destinations = dsts,
                                   entryPoint = entry,
                                   envEntry = envEntry,
                                   argEntries = argEntries,
                                   argSizeEntries = sizeEntries} ])
            end
        end

      | AI.Call {dstVarList, entry, env, argList, argSizeList, argTyList,
                 resultTyList, loc} =>
        let
          val (context, insn1, entry) = transformArg context entry
          val (context, insn2, env) = transformArg context env
          val (context, insn3, funEntry) = makeClosure context entry env
          val (context, insn4, argEntries) = transformArgList context argList
          val argSizes = map transformSize argSizeList
          val (context, dsts) = addLocalVarList context dstVarList
        in
          case computeSizeListKind argSizes of
            EmptySizeList =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @
             [ SI.Apply_0 {destinations = dsts,
                           closureEntry = funEntry} ])
          | SingletonSizeList size =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @
             [ SI.Apply_1 {destinations = dsts,
                           closureEntry = funEntry,
                           argEntry = List.hd argEntries,
                           argSize = List.hd argSizes} ])
          | SingleSizeList =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @
             [ SI.Apply_MS {destinations = dsts,
                            closureEntry = funEntry,
                            argEntries = argEntries} ])
          | LastArbitrarySizeList size =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @
             [ SI.Apply_ML {destinations = dsts,
                            closureEntry = funEntry,
                            argEntries = argEntries,
                            lastArgSize = size} ])
          | FixedSizeList sizeList =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @
             [ SI.Apply_MF {destinations = dsts,
                            closureEntry = funEntry,
                            argEntries = argEntries,
                            argSizes = sizeList} ])
          | VariantSizeList =>
            let
              val (context, insn5, sizeEntries) = bindSizeList context argSizes
            in
              (context,
               insn1 @ insn2 @ insn3 @ insn4 @ insn5 @
               [ SI.Apply_MV {destinations = dsts,
                              closureEntry = funEntry,
                              argEntries = argEntries,
                              argSizeEntries = sizeEntries} ])
            end
        end

      | AI.TailCall {entry = AI.Entry {entry, ...}, env, argList,
                     argSizeList, argTyList, resultTyList, loc} =>
        let
          (* NOTE: We never use RecursiveTailCallStatic family.
           *       RecursiveTailCallStatic requires that the size of stack
           *       frame of callee is equal to one of caller.
           *       we devide cluster for each functions, and calculates
           *       frameInfo for each individual clusters.
           *
           *       RecursiveTailCallStatic is as fast as Jump,  but we
           *       already have Jump and we already have replaced recursive
           *       tail call with jumps as many as possible.
           *)
          val (context, insn1, envEntry) = transformArg context env
          val (context, insn2, argEntries) = transformArgList context argList
          val argSizes = map transformSize argSizeList
        in
          case computeSizeListKind argSizes of
            EmptySizeList =>
            (context,
             insn1 @ insn2 @ #epilogue context @
             [ SI.TailCallStatic_0 {entryPoint = entry,
                                    envEntry = envEntry} ])
          | SingletonSizeList size =>
            (context,
             insn1 @ insn2 @ #epilogue context @
             [ SI.TailCallStatic_1 {entryPoint = entry,
                                    envEntry = envEntry,
                                    argEntry = List.hd argEntries,
                                    argSize = List.hd argSizes} ])
          | SingleSizeList =>
            (context,
             insn1 @ insn2 @ #epilogue context @
             [ SI.TailCallStatic_MS {entryPoint = entry,
                                     envEntry = envEntry,
                                     argEntries = argEntries} ])
          | LastArbitrarySizeList size =>
            (context,
             insn1 @ insn2 @ #epilogue context @
             [ SI.TailCallStatic_ML {entryPoint = entry,
                                     envEntry = envEntry,
                                     argEntries = argEntries,
                                     lastArgSize = size} ])
          | FixedSizeList sizeList =>
            (context,
             insn1 @ insn2 @ #epilogue context @
             [ SI.TailCallStatic_MF {entryPoint = entry,
                                     envEntry = envEntry,
                                     argEntries = argEntries,
                                     argSizes = sizeList} ])
          | VariantSizeList =>
            let
              val (context, insn3, sizeEntries) = bindSizeList context argSizes
            in
              (context,
               insn1 @ insn2 @ insn3 @ #epilogue context @
               [ SI.TailCallStatic_MV {entryPoint = entry,
                                       envEntry = envEntry,
                                       argEntries = argEntries,
                                       argSizeEntries = sizeEntries} ])
            end
        end

      | AI.TailCall {entry, env, argList, argSizeList, argTyList,
                     resultTyList, loc} =>
        let
          val (context, insn1, entry) = transformArg context entry
          val (context, insn2, env) = transformArg context env
          val (context, insn3, funEntry) = makeClosure context entry env
          val (context, insn4, argEntries) = transformArgList context argList
          val argSizes = map transformSize argSizeList
        in
          case computeSizeListKind argSizes of
            EmptySizeList =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @ #epilogue context @
             [ SI.TailApply_0 {closureEntry = funEntry} ])
          | SingletonSizeList size =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @ #epilogue context @
             [ SI.TailApply_1 {closureEntry = funEntry,
                               argEntry = List.hd argEntries,
                               argSize = List.hd argSizes} ])
          | SingleSizeList =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @ #epilogue context @
             [ SI.TailApply_MS {closureEntry = funEntry,
                                argEntries = argEntries} ])
          | LastArbitrarySizeList size =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @ #epilogue context @
             [ SI.TailApply_ML {closureEntry = funEntry,
                                argEntries = argEntries,
                                lastArgSize = size} ])
          | FixedSizeList sizeList =>
            (context,
             insn1 @ insn2 @ insn3 @ insn4 @ #epilogue context @
             [ SI.TailApply_MF {closureEntry = funEntry,
                                argEntries = argEntries,
                                argSizes = sizeList} ])
          | VariantSizeList =>
            let
              val (context, insn5, sizeEntries) =
                  bindSizeList context argSizes
            in
              (context,
               insn1 @ insn2 @ insn3 @ insn4 @ insn5 @ #epilogue context @
               [ SI.TailApply_MV {closureEntry = funEntry,
                                  argEntries = argEntries,
                                  argSizeEntries = sizeEntries} ])
            end
        end

      | AI.Return {valueList, tyList, valueSizeList, loc} =>
        if #isTopLevel context
        then
          (context, #epilogue context @ [ SI.Exit ])
        else
          let
            val (context, insn1, values) = transformArgList context valueList
            val sizes = map transformSize valueSizeList
          in
            case computeSizeListKind sizes of
              EmptySizeList =>
              (context,
               insn1 @ #epilogue context @
               [ SI.Return_0 ])
            | SingletonSizeList size =>
              (context,
               insn1 @ #epilogue context @
               [ SI.Return_1 {variableEntry = List.hd values,
                              variableSize = size} ])
            | SingleSizeList =>
              (context,
               insn1 @ #epilogue context @
               [ SI.Return_MS {variableEntries = values} ])
            | LastArbitrarySizeList size =>
              (context,
               insn1 @ #epilogue context @
               [ SI.Return_ML {variableEntries = values,
                               lastVariableSize = size} ])
            | FixedSizeList sizeList =>
              (context,
               insn1 @ #epilogue context @
               [ SI.Return_MF {variableEntries = values,
                               variableSizes = sizeList} ])
            | VariantSizeList =>
              let
                val (context, insn2, sizeEntries) = bindSizeList context sizes
              in
                (context,
                 insn1 @ insn2 @ #epilogue context @
                 [ SI.Return_MV {variableEntries = values,
                                 variableSizeEntries = sizeEntries} ])
              end
          end

      | AI.If {op2 as (_, _, _, ty), value1, value2, thenLabel, elseLabel,
               loc} =>
        let
          val var = newAIVar ty

          val (context, insn1) =
              transformPrim2 context
                  {dst = var, op2 = op2, arg1 = value1, arg2 = value2,
                   loc = loc}

          val (context, targetEntry) = addLocalVar context var
          val (context, thenLabel) = requestBlock context thenLabel
          val (context, elseLabel) = requestBlock context elseLabel
        in
          (context,
           insn1 @
           [
             SI.SwitchWord {targetEntry = targetEntry,
                            cases = [{const = 0w0,
                                      destination = elseLabel}],
                            default = thenLabel}
           ])
        end

      | AI.Raise {exn, loc} =>
        let
          val (context, insn1, exceptionEntry) = transformArg context exn
        in
          (* NOTE: Epilogue (= PopHandler) must be after Raise.
           *       If a handler is enabled, the destination of Raise is
           *       the handler.
           *)
          (context,
           insn1 @
           [
             SI.Raise {exceptionEntry = exceptionEntry}
           ] @
           #epilogue context)
        end

      | AI.CheckBoundary {block, offset, passLabel, failLabel, loc} =>
        (* Just ignore it. Current VM does not perform array boundary check
         * by itself. *)
        (context, [])

      | AI.Jump {label, knownDestinations, loc} =>
        (case knownDestinations of
           [destination] =>
           (* direct jump *)
           let
             val alreadyVisited =
                 LocalVarID.Set.member (#visitedBlocks context, destination)

             val (context, label) = requestBlock context destination
           in
             if alreadyVisited
             then
               (context,
                [
                  SI.Jump {destination = label}
                ])
             else
               (* If this is the first time to visit the destination block,
                * Jump can be ommitted. The next block will be immediately after
                * current block.
                *)
               (context, nil)
           end
         | _ =>
           (* indirect jump *)
           let
             val (context, insn1, dest) = transformArg context label

             val context =
                 foldl (fn (label, context) => #1 (requestBlock context label))
                       context
                       knownDestinations
           in
             (context,
              [
                SI.IndirectJump {destination = dest}
              ])
           end)

  and transformInsnList context (insn::insnList) =
      let
        val loc = AbstractInstructionUtils.getLoc insn
        val insns1 =
            case insn of
              AI.Jump _ => nil
            | _ => if loc = Loc.noloc
                   then nil else [ SI.Location loc ]
        val (context, insns2) = transformInsn context insn
        val (context, insns3) =
            case insn of
              AI.Jump _ => (context, nil)
            | _ => transformInsnList context insnList
      in
        (context, insns1 @ insns2 @ insns3)
      end
    | transformInsnList context nil = (context, nil)

  fun transformBody basicBlockMap context =
      case popRequestedBlockLabel context of
        (context, NONE) => (context, nil)
      | (context, SOME blockLabel) =>
        let
          val block : AI.basicBlock =
              case LocalVarID.Map.find (basicBlockMap, blockLabel) of
                SOME block => block
              | NONE => raise Control.Bug ("transformBody: "
                                           ^ LocalVarID.toString blockLabel)

          val (context, blockLabel) = addLocalLabel context blockLabel

          val context =
              case #blockKind block of
                AI.FunEntry params => addParamList context params
              | AI.Handler var => addParamList context [var]
              | _ => context

          val (context, blockPrologue) =
              (
                case #handler block of
                  AI.NoHandler =>
                  (
                    case #handlerVar context of
                      NONE => (context, nil)
                    | SOME var =>
                      (context,
                       [ SI.LoadWord {destination = var, value = NullValue} ])
                  )
                | AI.StaticHandler handlerBlockLabel =>
                  let
                    val (context, handlerLabel) =
                        requestBlock context handlerBlockLabel
                  in
                    (context,
                     [
                       SI.LoadAddress
                           {destination = valOf (#handlerVar context),
                            address = handlerLabel}
                     ])
                  end
                | AI.DynamicHandler {current, handlers, ...} =>
                  let
                    val (context, currentVar) = addLocalVar context current
                    val context =
                        foldl (fn (label, context) =>
                                  #1 (requestBlock context label))
                              context
                              handlers
                  in
                    (context,
                     [
                       SI.Access {destination = valOf (#handlerVar context),
                                  variableSize = SI.SINGLE,
                                  variableEntry = currentVar}
                     ])
                  end
              )
              handle Option => raise Control.Bug "transformBody: Option"

          val (context, blockPrologue) =
              (
                case #blockKind block of
                  AI.Handler var =>
                  let
                    val (context, var) = addLocalVar context var
                  in
                    (context,
                     [
                       SI.Access {destination = var,
                                  variableSize = SI.SINGLE,
                                  variableEntry = valOf (#exnVar context)}
                     ] @ blockPrologue)
                  end
                | _ =>
                  (context, blockPrologue)
              )
              handle Option => raise Control.Bug "transformBody: Option2"

          val (context, insn1) =
              transformInsnList context (#instructionList block)
          val (context, insn2) =
              transformBody basicBlockMap context
        in
          (context, SI.Label blockLabel :: blockPrologue @ insn1 @ insn2)
        end

  (***************************************************************************)

  (* generate ConstString only for strings used in current context. *)
  fun generateConst ({localLabels, constants, ...}:context) =
      LocalVarID.Map.foldli
        (fn (constId, const, insn) =>
            case LocalVarID.Map.find (localLabels, constId) of
              NONE => insn
            | SOME newId =>
              case const of
                AI.ConstString str =>
                SI.Label newId :: SI.ConstString {string = str} :: insn
              | AI.ConstIntInf n =>
                let
                  val s = BigInt.toCString n
                in
                  SI.Label newId :: SI.ConstString {string = s} :: insn
                end
              | AI.ConstReal _ =>
                (* actually a boxed real *)
                raise Control.Bug "transformConst: Real"
              | AI.ConstObject _ =>
                raise Control.Bug "transformConst: ConstObject")
        nil
        constants

  fun makeFrameInfo localVars =
      let
        val {atoms, pointers, doubles,
             argsRecords, freesRecords, unboxedRecords} =
            LocalVarID.Map.foldl
              (fn (localVarInfo,
                   {atoms, pointers, doubles,
                    argsRecords, freesRecords, unboxedRecords}) =>
                  case localVarInfo of
                    (var, AI.Unboxed, SI.SINGLE) =>
                    {atoms = var :: atoms,
                     pointers = pointers,
                     doubles = doubles,
                     argsRecords = argsRecords,
                     freesRecords = freesRecords,
                     unboxedRecords = unboxedRecords}
                  | (var, AI.Boxed, SI.SINGLE) =>
                    {atoms = atoms,
                     pointers = var :: pointers,
                     doubles = doubles,
                     argsRecords = argsRecords,
                     freesRecords = freesRecords,
                     unboxedRecords = unboxedRecords}
                  | (var, AI.Unboxed, SI.DOUBLE) =>
                    {atoms = atoms,
                     pointers = pointers,
                     doubles = var :: doubles,
                     argsRecords = argsRecords,
                     freesRecords = freesRecords,
                     unboxedRecords = unboxedRecords}
                  | (var, AI.Unboxed, _) =>
                    {atoms = atoms,
                     pointers = pointers,
                     doubles = doubles,
                     argsRecords = argsRecords,
                     freesRecords = freesRecords,
                     unboxedRecords = var :: unboxedRecords}
                  | (var, AI.ParamTag param, _) =>
                    {atoms = atoms,
                     pointers = pointers,
                     doubles = doubles,
                     argsRecords = (param, var) :: argsRecords,
                     freesRecords = freesRecords,
                     unboxedRecords = unboxedRecords}
                  | (var, AI.IndirectTag {offset, bit}, _) =>
                    {atoms = atoms,
                     pointers = pointers,
                     doubles = doubles,
                     argsRecords = argsRecords,
                     freesRecords = (offset, bit, var) :: freesRecords,
                     unboxedRecords = unboxedRecords}
                  | ({id,...}:SI.varInfo, _, _) =>
                    raise Control.Bug ("makeFrameInfo " ^ LocalVarID.toString id))
              {atoms = nil,
               pointers = nil,
               doubles = nil,
               argsRecords = nil,
               freesRecords = nil,
               unboxedRecords = nil}
              localVars

        val (argMap, argsRecordsMap) =
            foldl
              (fn ((param, varInfo), (argMap, argRecordsMap)) =>
                  let
                    val arg = transformParamInfo param
                    val id = #id arg
                    val argMap = LocalVarID.Map.insert (argMap, id, arg)
                    val argRecordsMap =
                        case LocalVarID.Map.find (argRecordsMap, id) of
                          SOME l =>
                          LocalVarID.Map.insert (argRecordsMap, id, varInfo::l)
                        | NONE =>
                          LocalVarID.Map.insert (argRecordsMap, id, [varInfo])
                  in
                    (argMap, argRecordsMap)
                  end)
              (LocalVarID.Map.empty, LocalVarID.Map.empty)
              argsRecords

        val bitmapArgs = LocalVarID.Map.listItems argMap
        val argsRecords =
            map (fn {id, ...} => valOf (LocalVarID.Map.find (argsRecordsMap, id)))
                bitmapArgs

        val freesIndex =
            foldl (fn ((index, bit, varInfo), SOME x) =>
                      if index = x then SOME x
                      else raise Control.Bug "# of bitmapVals frees > 1"
                    | ((index, bit, varInfo), NONE) => SOME index)
                  NONE
                  freesRecords

        val freesRecords =
            case freesIndex of
              NONE => []
            | SOME index =>
              let
                val maxBits =
                    foldl (fn ((index, bit, varInfo), maxBits) =>
                              if bit > maxBits then bit else maxBits)
                          0w0
                          freesRecords
              in
                List.tabulate
                    (Word.toInt maxBits + 1,
                     fn n =>
                        foldl (fn ((index, bit, varInfo), vars) =>
                                  if bit = Word.fromInt n
                                  then varInfo::vars else vars)
                              nil
                              freesRecords)
              end
      in
        {
          bitmapvals =
              {
                args = bitmapArgs,
                frees = case freesIndex of
                          SOME x => [Target.UIntToUInt32 x]
                        | NONE => nil
              },
          pointers = pointers,
          atoms = atoms,
          doubles = doubles,
          records = argsRecords @ freesRecords @ [unboxedRecords]
        } : SI.frameInfo
      end

  fun mapAccum f z nil = (nil, z)
    | mapAccum f z (h::t) =
      let
        val (h, z) = f (h, z)
        val (t, z) = mapAccum f z t
      in
        (h::t, z)
      end

  fun transformCluster isTopLevel constants ({body, loc, ...}:AI.cluster) =
      let
        val basicBlockMap =
            foldl
              (fn (block as {label, ...}, blockMap) =>
                  LocalVarID.Map.insert (blockMap, label, block))
              LocalVarID.Map.empty
              body

        val funEntries =
            foldl
              (fn (block as {label, blockKind, ...}, funEntries) =>
                  case blockKind of
                    AI.FunEntry params => (block, params) :: funEntries
                  | _ => funEntries)
              nil
              body
      in
        (*
         * Generate individual cluster for each FunEntry.
         * Currently it is legal. Actually current implementation of
         * assembler doesn't accept cluster as it is, so it splits
         * a cluster into functions and copies frameInfo for each function
         * before performing code generation.
         *)
        map
          (fn (block as {label, ...}, params) =>
              let
                val context =
                    {
                      isTopLevel = isTopLevel,
                      constants = constants,
                      pendingBlocks = [label],
                      visitedBlocks = LocalVarID.Set.singleton label,
                      localVars = LocalVarID.Map.empty,
                      localLabels = LocalVarID.Map.singleton (label, Counters.newLocalId ()),
                      exnVar = NONE,
                      handlerVar = NONE,
                      handlerLabel = NONE,
                      epilogue = nil
                    } : context

                val context =
                    if List.exists (fn {handler = AI.NoHandler, ...} => false
                                     | _ => true)
                                   body
                    then requireHandler context
                    else context

                val (context, bodyInsn) =
                    transformBody basicBlockMap context

                val (prelude, handlerInsn) =
                    case context of
                      {handlerLabel = SOME handlerLabel,
                       handlerVar = SOME handlerVar,
                       exnVar = SOME exnVar, ...} =>
                      ([
                         SI.LoadWord    {destination = handlerVar,
                                         value = NullValue},
                         SI.PushHandler {handlerStart = handlerLabel,
                                         handlerEnd = handlerLabel, (*dummy*)
                                         exceptionEntry = exnVar}
                       ],
                       let
                         val enableLabel = Counters.newLocalId ()
                         val disableLabel = Counters.newLocalId ()
                       in
                         [
                           SI.Location loc,
                           SI.Label handlerLabel,
                           SI.SwitchWord
                               {targetEntry = handlerVar,
                                cases = [{const = NullValue,
                                          destination = disableLabel}],
                                default = enableLabel},
                           SI.Label enableLabel,
                           SI.PushHandler {handlerStart = handlerLabel,
                                           handlerEnd = handlerLabel, (*dummy*)
                                           exceptionEntry = exnVar},
                           SI.IndirectJump {destination = handlerVar},
                           SI.Label disableLabel,
                           SI.Raise {exceptionEntry = exnVar}
                         ]
                       end)
                    | _ => (nil, nil)

                val constInsn = generateConst context

                val functionCode =
                    {
                      name = {id = label,
                              displayName = LocalVarID.toString label},
                      loc = #loc block,
                      args = map transformParamInfo params,
                      instructions = prelude
                                     @ bodyInsn
                                     @ handlerInsn
                                     @ constInsn
                    } : SI.functionCode
              in
                {
                  frameInfo = makeFrameInfo (#localVars context),
                  functionCodes = [functionCode],
                  loc = loc
                } : SI.clusterCode
              end)
          funEntries
      end

  fun generate stamp (globalArrays, {clusters, constants, ...}:AI.program) =
      let
        val _ = Counters.init stamp
        val (topLevelCluster, clusters) =
            case clusters of
              h::t => (h, t)
            | nil => raise Control.Bug "generate: no toplevel cluster"

        val topLevelCode =
            transformCluster true constants topLevelCluster

        val clusterCodes =
            map (fn cluster => transformCluster false constants cluster)
                clusters

        val clusterCodes =
            List.concat (topLevelCode :: clusterCodes)

        val initCode =
            map
              (fn (arrayIndex, ANormal.ATOM) =>
                  SI.InitGlobalArrayUnboxed
                      {globalArrayIndex = arrayIndex,
                       arraySize = GlobalIndexEnv.globalAtomArraySize}
                | (arrayIndex, ANormal.BOXED) =>
                  SI.InitGlobalArrayBoxed
                      {globalArrayIndex = arrayIndex,
                       arraySize = GlobalIndexEnv.globalBoxedArraySize}
                | (arrayIndex, ANormal.DOUBLE) =>
                  SI.InitGlobalArrayDouble
                      {globalArrayIndex = arrayIndex,
                       arraySize = GlobalIndexEnv.globalDoubleArraySize}
                | _ =>
                  raise Control.Bug "invalid global object type")
              globalArrays

        val clusterCodes =
            case clusterCodes of
              {frameInfo, functionCodes = [{name, loc, args, instructions}],
               loc = clusterLoc} :: clusterCodes =>
              {
                frameInfo = frameInfo,
                functionCodes =
                  [{
                    name = name,
                    loc = loc,
                    args = args,
                    instructions = initCode @ instructions
                   } : SI.functionCode],
                loc = clusterLoc
              }
              :: clusterCodes
            | _ =>
              raise Control.Bug "toplevel cluster doesn't exist"
      in
        (Counters.getCounterStamp(), clusterCodes)
      end

end
