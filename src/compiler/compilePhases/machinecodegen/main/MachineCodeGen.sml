(**
 * generate machine code
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure MachineCodeGen : sig

  val compile : ANormal.program
                -> MachineCode.program

end =
struct

  structure A = ANormal
  structure M = MachineCode
  structure T = Types
  structure R = RuntimeTypes
  structure P = BuiltinPrimitive
  structure B = BuiltinTypes

  fun optionToList NONE = nil
    | optionToList (SOME x) = [x]

  fun natural ty =
      case TypeLayout2.propertyOf BoundTypeVarID.Map.empty ty of
        SOME {tag = R.TAG t, size = R.SIZE s, rep = r} =>
        (ty, {tag = t, size = s, rep = r})
      | _ => raise Bug.Bug "natural"

  fun int32Ty () = natural BuiltinTypes.int32Ty
  fun word32Ty () = natural BuiltinTypes.word32Ty
  fun intConst n =
      M.ANCONST {const = M.NVINT32 n, ty = int32Ty ()}
  fun wordConst n =
      M.ANCONST {const = M.NVWORD32 n, ty = word32Ty ()}

  fun unitTy () = natural BuiltinTypes.unitTy
  fun unitConst () =
      M.ANCONST {const = M.NVUNIT, ty = unitTy ()}
  fun singleConst ty =
      M.ANCONST {const = M.NVUNIT, ty = ty}

  fun sizeTy ty = natural (T.SINGLETONty (T.SIZEty ty))
  fun tagTy ty = natural (T.SINGLETONty (T.TAGty ty))
  fun boxedTy () = natural BuiltinTypes.boxedTy
  fun exnTy () = natural BuiltinTypes.exnTy

  val empty = fn x:M.mcexp => x
  fun mid m = fn (mids, last):M.mcexp => (m::mids, last):M.mcexp
  fun last l = fn () => (nil, l):M.mcexp

  fun tagExp ((ty, {tag, ...}):M.ty) =
      M.ANCONST {const = M.NVTAG {tag = tag, ty = ty}, ty = tagTy ty}

  fun Int32_mul_unsafe (resultVar, op1, op2, loc) =
      mid (M.MCPRIMAPPLY
             {resultVar = resultVar,
              primInfo =
                {primitive = P.Int_mul_unsafe,
                 ty = {boundtvars = BoundTypeVarID.Map.empty,
                       argTyList = [B.int32Ty, B.int32Ty],
                       resultTy = B.int32Ty}},
              argExpList = [op1, op2],
              argTyList = [int32Ty (), int32Ty ()],
              resultTy = int32Ty (),
              instTyList = [],
              instTagList = [],
              instSizeList = [],
              loc = loc})

  fun Alloc {resultVar, objType, payloadSize, allocSize, initExp, loc} =
      mid (M.MCALLOC
             {resultVar = resultVar,
              objType = objType,
              payloadSize = payloadSize,
              allocSize = allocSize,
              loc = loc})
      o initExp
      o mid M.MCALLOC_COMPLETED

  fun If {condExp, condTy, const, thenExp, elseExp, loc} =
      let
        val nextLabel = FunLocalLabel.generate nil
        val thenLabel = FunLocalLabel.generate nil
        val elseLabel = FunLocalLabel.generate nil
        val goto : M.mcexp =
            (nil, M.MCGOTO {id = nextLabel, argList = nil, loc = loc})
      in
        fn K =>
           (nil,
            M.MCLOCALCODE
              {recursive = false,
               binds = [{id = nextLabel,
                         argVarList = nil,
                         bodyExp = K}],
               loc = loc,
               nextExp =
                 (nil,
                  M.MCLOCALCODE
                    {recursive = false,
                     binds = [{id = thenLabel,
                               argVarList = nil,
                               bodyExp = thenExp goto},
                              {id = elseLabel,
                               argVarList = nil,
                               bodyExp = elseExp goto}],
                     loc = loc,
                     nextExp =
                       (nil,
                        M.MCSWITCH
                          {switchExp = condExp,
                           expTy = condTy,
                           branches = [(const, thenLabel)],
                           default = elseLabel,
                           loc = loc})})})
      end

  fun switchByTag {tagExp, tagOfTy, ifBoxed, ifUnboxed, loc} =
      If {condExp = tagExp,
          condTy = tagTy tagOfTy,
          const = M.NVTAG {tag = RuntimeTypes.UNBOXED, ty = tagOfTy},
          thenExp = ifUnboxed,
          elseExp = ifBoxed,
          loc = loc}

  fun arrayBytes (numElems, elemSize, elemTy:M.ty, loc) =
      let
        val sizeVar = {id = VarID.generate (), ty = int32Ty ()}
      in
        (Int32_mul_unsafe
           (sizeVar,
            M.ANCAST {exp = elemSize,
                      expTy = sizeTy (#1 elemTy),
                      targetTy = int32Ty ()},
            numElems,
            loc),
         M.ANVAR sizeVar)
      end

  fun allocArray {resultVar, resultTy, objType, elemTy, elemTag, elemSize,
                  numElems, loc} =
      let
        val (proc1, sizeExp) = arrayBytes (numElems, elemSize, elemTy, loc)
        val proc2 =
            Alloc
              {resultVar = resultVar,
               objType = objType,
               payloadSize = sizeExp,
               allocSize = sizeExp,
               initExp =
                 switchByTag
                   {tagExp = elemTag,
                    tagOfTy = #1 elemTy,
                    ifBoxed =
                      (* initialize with NULL *)
                      mid (M.MCBZERO
                            {recordExp = M.ANVAR resultVar,
                             recordSize = sizeExp,
                             loc = loc}),
                    ifUnboxed = empty,
                    loc = loc},
               loc = loc}
      in
        proc1 o proc2
      end

  fun mask (subst, vars) =
      foldl (fn ({id,...}:A.varInfo, subst) =>
                if VarID.Map.inDomain (subst, id)
                then #1 (VarID.Map.remove (subst, id))
                else subst)
            subst
            vars

  fun compileValue subst value =
      case value of
        A.ANCONST _ => value
      | A.ANBOTTOM => value
      | A.ANCAST {exp, expTy, targetTy} =>
        A.ANCAST {exp = compileValue subst exp, expTy = expTy,
                  targetTy = targetTy}
      | A.ANVAR {id, ty} =>
        case VarID.Map.find (subst, id) of
          NONE => value
        | SOME value => value

  fun compileAddress subst loc address =
      case address of
        A.AAPTR ptrExp =>
        M.MAPTR (compileValue subst ptrExp)
      | A.AARECORDFIELD {recordExp, fieldIndex} =>
        M.MARECORDFIELD {recordExp = compileValue subst recordExp,
                         fieldIndex = compileValue subst fieldIndex}
      | A.AAARRAYELEM {arrayExp, elemSize, elemIndex} =>
        M.MAARRAYELEM {arrayExp = compileValue subst arrayExp,
                       elemSize = compileValue subst elemSize,
                       elemIndex = compileValue subst elemIndex}

  fun compileInitField subst dstAddr loc (fieldTy, initField) =
      case initField of
        A.INIT_VALUE value =>
        mid (M.MCSTORE {dstAddr = dstAddr,
                        srcExp = compileValue subst value,
                        srcTy = fieldTy,
                        barrier = false,
                        loc = loc})
      | A.INIT_COPY {srcExp, fieldSize} =>
        (* initializer does not need write barrier *)
        mid (M.MCMEMCPY_FIELD
               {dstAddr = dstAddr,
                srcAddr = M.MAPACKED (compileValue subst srcExp),
                copySize = compileValue subst fieldSize,
                loc = loc})
      | A.INIT_IF {tagExp, tagOfTy, ifBoxed, ifUnboxed} =>
        switchByTag
          {tagExp = compileValue subst tagExp,
           tagOfTy = tagOfTy,
           ifBoxed = compileInitField subst dstAddr loc (fieldTy, ifBoxed),
           ifUnboxed = compileInitField subst dstAddr loc (fieldTy, ifUnboxed),
           loc = loc}

  fun compileRecordField subst objPtrVar loc {fieldExp, fieldTy, fieldIndex} =
      let
        val dstAddr =
            M.MARECORDFIELD
              {recordExp = M.ANVAR objPtrVar,
               fieldIndex = compileValue subst fieldIndex}
      in
        compileInitField subst dstAddr loc (fieldTy, fieldExp)
      end

  fun compileRecordFieldList subst objPtrVar loc fields =
      foldl (fn (x,z) => z o compileRecordField subst objPtrVar loc x)
            empty
            fields

  fun compileRecordBitmap subst objPtrVar loc {bitmapIndex, bitmapExp} =
      let
        val dstAddr =
            M.MAOFFSET {base = M.ANVAR objPtrVar,
                        offset = compileValue subst bitmapIndex}
      in
        mid (M.MCSTORE {dstAddr = dstAddr,
                        srcExp = compileValue subst bitmapExp,
                        srcTy = word32Ty (),
                        barrier = false,
                        loc = loc})
      end

  fun compileRecordBitmapList subst objPtrVar loc bitmaps =
      foldl (fn (x,z) => z o compileRecordBitmap subst objPtrVar loc x)
            empty
            bitmaps

  fun compilePrim subst {resultVar, resultTy, primInfo = {primitive, ty},
                         argExpList, argTyList, instTyList, instTagList,
                         instSizeList, loc} =
      case (primitive, instTyList, instTagList, instSizeList, argExpList) of
        (P.Array_alloc_unsafe, [ty], [tag], [size], [len]) =>
        (allocArray
           {resultVar = resultVar,
            resultTy = resultTy,
            objType = M.OBJTYPE_ARRAY tag,
            elemTy = ty,
            elemTag = tag,
            elemSize = size,
            numElems = len,
            loc = loc},
         mask (subst, [resultVar]))
      | (P.Array_alloc_unsafe, _, _, _, _) =>
        raise Bug.Bug "compileExp: Array_alloc_unsafe"

      | (P.Vector_alloc_unsafe, [ty], [tag], [size], [len]) =>
        (allocArray
           {resultVar = resultVar,
            resultTy = resultTy,
            objType = M.OBJTYPE_VECTOR tag,
            elemTy = ty,
            elemTag = tag,
            elemSize = size,
            numElems = len,
            loc = loc},
         mask (subst, [resultVar]))
      | (P.Vector_alloc_unsafe, _, _, _, _) =>
        raise Bug.Bug "compileExp: Vector_alloc_unsafe"

      | (P.Record_alloc_unsafe, [], [], [], [payloadSize, allocSize]) =>
        (Alloc
           {resultVar = resultVar,
            objType = M.OBJTYPE_RECORD,
            payloadSize = payloadSize,
            allocSize = allocSize,
            initExp = mid (M.MCBZERO {recordExp = M.ANVAR resultVar,
                                      recordSize = allocSize,
                                      loc = loc}),
            loc = loc},
         mask (subst, [resultVar]))
      | (P.Record_alloc_unsafe, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Record_alloc_unsafe"

      | (P.Array_copy_unsafe, [ty], [tag], [size],
         [src, si, dst, di, len]) =>
        (switchByTag
           {tagExp = tag,
            tagOfTy = #1 ty,
            ifBoxed =
              mid (M.MCMEMMOVE_BOXED_ARRAY
                     {srcArray = src,
                      srcIndex = si,
                      dstArray = dst,
                      dstIndex = di,
                      numElems = len,
                      loc = loc}),
            ifUnboxed =
              mid (M.MCMEMMOVE_UNBOXED_ARRAY
                     {srcAddr = M.MAARRAYELEM
                                  {arrayExp = src,
                                   elemSize = size,
                                   elemIndex = si},
                      dstAddr = M.MAARRAYELEM
                                  {arrayExp = dst,
                                   elemSize = size,
                                   elemIndex = di},
                      numElems = len,
                      elemSize = size,
                      loc = loc}),
            loc = loc},
         VarID.Map.insert (subst, #id resultVar, unitConst ()))
      | (P.Array_copy_unsafe, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Array_copy_unsafe"

      | (P.Boxed_deref, [], [], [], [ptr, index]) =>
        (mid (M.MCLOAD
                {resultVar = resultVar,
                 srcAddr = M.MAOFFSET {base = ptr, offset = index},
                 loc = loc}),
         mask (subst, [resultVar]))
      | (P.Boxed_deref, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Boxed_deref"

      | (P.Boxed_store, [], [], [], [ptr, index, value]) =>
        (case argTyList of
           [_, _, srcTy] =>
           (mid (M.MCSTORE
                   {dstAddr = M.MAOFFSET {base = ptr, offset = index},
                    srcExp = value,
                    srcTy = srcTy,
                    barrier = case srcTy of (_, {tag=R.BOXED,...}) => true
                                          | _ => false,
                    loc = loc}),
            VarID.Map.insert (subst, #id resultVar, unitConst ()))
         | _ => raise Bug.Bug "compilePrim: Boxed_store")
      | (P.Boxed_store, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Boxed_store"

      | (P.Boxed_copy, [], [], [], [dst, dstIndex, src, srcIndex, tag, size]) =>
        let
          val tmpVar = {id = VarID.generate (), ty = boxedTy ()}
          val dstAddr = M.MAOFFSET {base = dst, offset = dstIndex}
          val srcAddr = M.MAOFFSET {base = src, offset = srcIndex}
        in
          (If {condExp = tag,
               condTy = word32Ty (),
               const = M.NVWORD32 (Word.fromInt
                                     (RuntimeTypes.tagValue
                                        RuntimeTypes.UNBOXED)),
               thenExp = mid (M.MCMEMCPY_FIELD {dstAddr = dstAddr,
                                                srcAddr = srcAddr,
                                                copySize = size,
                                                loc = loc}),
               elseExp =
                 mid (M.MCLOAD {resultVar = tmpVar,
                                srcAddr = srcAddr,
                                loc = loc})
                 o mid (M.MCSTORE {dstAddr = dstAddr,
                                   srcExp = M.ANVAR tmpVar,
                                   srcTy = boxedTy (),
                                   barrier = true,
                                   loc = loc}),
               loc = loc},
           VarID.Map.insert (subst, #id resultVar, unitConst ()))
        end
      | (P.Boxed_copy, _, _, _, _) =>
        raise Bug.Bug "compilePrim: Boxed_copy"

      | (P.KeepAlive, [ty], [tag], [size], [value]) =>
        (mid (M.MCKEEPALIVE {value = value, loc = loc}),
         VarID.Map.insert (subst, #id resultVar, unitConst ()))
      | (P.KeepAlive, _, _, _, _) =>
        raise Bug.Bug "compilePrim: KeepAlive"

      | (P.M prim, _, _, _, _) =>
        (mid (M.MCPRIMAPPLY {resultVar = resultVar,
                             primInfo = {primitive = prim, ty = ty},
                             argExpList = argExpList,
                             argTyList = argTyList,
                             resultTy = resultTy,
                             instTyList = instTyList,
                             instTagList = instTagList,
                             instSizeList = instSizeList,
                             loc = loc}),
         mask (subst, [resultVar]))

  fun compileExp subst anexp =
      case anexp of
        A.ANINTINF {resultVar, dataLabel, nextExp, loc} =>
        mid (M.MCINTINF
               {resultVar = resultVar,
                dataLabel = dataLabel,
                loc = loc})
        o compileExp (mask (subst, [resultVar])) nextExp
      | A.ANFOREIGNAPPLY {resultVar, funExp, attributes, argExpList,
                          handler, nextExp, loc} =>
        let
          val {causeGC, fast, ...} = attributes
          val argExpList = map (compileValue subst) argExpList
          val keepInsns =
              if causeGC orelse not fast
              then
                foldl
                  (fn (v as M.ANVAR {ty = (_, {tag = R.BOXED, ...}), ...}, z) =>
                      z o mid (M.MCKEEPALIVE {value = v, loc = loc})
                    | (_, z) => z)
                  empty
                  argExpList
              else empty
        in
          mid (M.MCFOREIGNAPPLY
                 {resultVar = resultVar,
                  funExp = compileValue subst funExp,
                  attributes = attributes,
                  argExpList = argExpList,
                  handler = handler,
                  loc = loc})
          o keepInsns
          o compileExp (mask (subst, optionToList resultVar)) nextExp
        end
      | A.ANEXPORTCALLBACK {resultVar, codeExp, closureEnvExp, instTyvars,
                            nextExp, loc} =>
        mid (M.MCEXPORTCALLBACK
               {resultVar = resultVar,
                codeExp = compileValue subst codeExp,
                closureEnvExp = compileValue subst closureEnvExp,
                instTyvars = instTyvars,
                loc = loc})
        o compileExp (mask (subst, [resultVar])) nextExp
      | A.ANEXVAR {resultVar, id, nextExp, loc} =>
        mid (M.MCEXVAR
               {resultVar = resultVar,
                id = id,
                loc = loc})
        o compileExp (mask (subst, [resultVar])) nextExp
      | A.ANPACK {resultVar, exp, expTy, nextExp, loc} =>
        let
          val size = intConst (RuntimeTypes.getSize (#size (#2 expTy)))
          val resultTy = (#1 expTy, boxedTy ())
        in
          Alloc
            {resultVar = resultVar,
             objType = M.OBJTYPE_VECTOR (tagExp expTy),
             payloadSize = size,
             allocSize = size,
             initExp =
               mid (M.MCSTORE
                      {dstAddr = M.MAPACKED (M.ANVAR resultVar),
                       srcExp = compileValue subst exp,
                       srcTy = expTy,
                       barrier = false,
                       loc = loc}),
             loc = loc}
          o compileExp (mask (subst, [resultVar])) nextExp
        end
      | A.ANUNPACK {resultVar, exp, nextExp, loc} =>
        mid (M.MCLOAD
               {resultVar = resultVar,
                srcAddr = M.MAPACKED (compileValue subst exp),
                loc = loc})
        o compileExp (mask (subst, [resultVar])) nextExp
      | A.ANDUP {resultVar, srcAddr, valueSize, nextExp, loc} =>
        let
          val valueSize = compileValue subst valueSize
        in
          Alloc
            {resultVar = resultVar,
             objType = M.OBJTYPE_UNBOXED_VECTOR,
             payloadSize = valueSize,
             allocSize = valueSize,
             initExp =
               mid (M.MCMEMCPY_FIELD
                      {dstAddr = M.MAPACKED (M.ANVAR resultVar),
                       srcAddr = compileAddress subst loc srcAddr,
                       copySize = valueSize,
                       loc = loc}),
             loc = loc}
          o compileExp (mask (subst, [resultVar])) nextExp
        end
      | A.ANLOAD {resultVar, srcAddr, nextExp, loc} =>
        mid (M.MCLOAD
               {resultVar = resultVar,
                srcAddr = compileAddress subst loc srcAddr,
                loc = loc})
        o compileExp (mask (subst, [resultVar])) nextExp
      | A.ANPRIMAPPLY {resultVar, primInfo, argExpList,
                       instTyList, instTagList,
                       argTyList, resultTy, instSizeList, nextExp, loc} =>
        let
          val (proc1, subst) =
              compilePrim
                subst
                {resultVar = resultVar,
                 resultTy = resultTy,
                 primInfo = primInfo,
                 argExpList = map (compileValue subst) argExpList,
                 argTyList = argTyList,
                 instTyList = instTyList,
                 instTagList = map (compileValue subst) instTagList,
                 instSizeList = map (compileValue subst) instSizeList,
                 loc = loc}
        in
          proc1
          o compileExp subst nextExp
        end
      | A.ANBITCAST {resultVar, exp, expTy, targetTy, nextExp, loc} =>
        mid (M.MCBITCAST
               {resultVar = resultVar,
                exp = compileValue subst exp,
                expTy = expTy,
                targetTy = targetTy,
                loc = loc})
        o compileExp (mask (subst, [resultVar])) nextExp
      | A.ANCALL {resultVar, codeExp, closureEnvExp, argExpList, nextExp,
                  handler, loc} =>
        let
          val resultTy = #ty resultVar
          val (resultVar, subst) =
              case #rep (#2 resultTy) of
                R.DATA R.LAYOUT_SINGLE =>
                (NONE,
                 VarID.Map.insert (subst, #id resultVar, unitConst ()))
              | _ =>
                (SOME resultVar, mask (subst, [resultVar]))
        in
          mid (M.MCCALL
                 {resultVar = resultVar,
                  resultTy = resultTy,
                  codeExp = compileValue subst codeExp,
                  closureEnvExp = Option.map (compileValue subst) closureEnvExp,
                  argExpList = map (compileValue subst) argExpList,
                  tail = false,
                  handler = handler,
                  loc = loc})
          o compileExp subst nextExp
        end
      | A.ANTAILCALL {resultTy, codeExp, closureEnvExp, argExpList, loc} =>
        let
          val (resultVar, retValue) =
              case #rep (#2 resultTy) of
                R.DATA R.LAYOUT_SINGLE =>
                (NONE, singleConst resultTy)
              | _ =>
                let
                  val resultVar = {id = VarID.generate (), ty = resultTy}
                in
                  (SOME resultVar, M.ANVAR resultVar)
                end
        in
          mid (M.MCCALL
                 {resultVar = resultVar,
                  resultTy = resultTy,
                  codeExp = compileValue subst codeExp,
                  closureEnvExp = Option.map (compileValue subst) closureEnvExp,
                  argExpList = map (compileValue subst) argExpList,
                  tail = true,
                  handler = NONE,
                  loc = loc})
          o last (M.MCRETURN {value = retValue, loc = loc})
        end
      | A.ANRECORD {resultVar, fieldList, isMutable, clearPad,
                    allocSizeExp, bitmaps, nextExp, loc} =>
        let
          val allocSizeExp = compileValue subst allocSizeExp
          val proc1 =
              if clearPad
              then mid (M.MCBZERO
                          {recordExp = M.ANVAR resultVar,
                           recordSize = allocSizeExp,
                           loc = loc})
              else empty
          val proc2 =
              compileRecordFieldList subst resultVar loc fieldList
          val proc3 =
              compileRecordBitmapList subst resultVar loc bitmaps
          val payloadSize =
              case bitmaps of
                {bitmapIndex, ...}::_ => compileValue subst bitmapIndex
              | _ => raise Bug.Bug "compileExp: ANRECORD: no bitmap record"
        in
          Alloc
            {resultVar = resultVar,
             objType = M.OBJTYPE_RECORD, (* FIXME: ANRECORD: objtype depends on bitmap *)
             payloadSize = payloadSize,
             allocSize = allocSizeExp,
             initExp = proc1 o proc2 o proc3,
             loc = loc}
          o compileExp (mask (subst, [resultVar])) nextExp
        end
      | A.ANMODIFY {resultVar, recordExp, indexExp, valueExp, valueTy,
                    nextExp, loc} =>
        let
          val addr =
              M.MARECORDFIELD
                {recordExp = M.ANVAR resultVar,
                 fieldIndex = compileValue subst indexExp}
          val copySizeVar = {id = VarID.generate (), ty = word32Ty ()}
          val srcRecord = compileValue subst recordExp
        in
          mid (M.MCRECORDDUP_ALLOC
                 {resultVar = resultVar,
                  copySizeVar = copySizeVar,
                  recordExp = srcRecord,
                  loc = loc})
          o mid (M.MCRECORDDUP_COPY
                   {dstRecord = M.ANVAR resultVar,
                    srcRecord = srcRecord,
                    copySize = M.ANVAR copySizeVar,
                    loc = loc})
          o compileRecordField
              subst
              resultVar
              loc
              {fieldExp = valueExp,
               fieldTy = valueTy,
               fieldIndex = indexExp}
          o mid M.MCALLOC_COMPLETED
          o compileExp (mask (subst, [resultVar])) nextExp
        end
      | A.ANRETURN {value, ty, loc} =>
        last (M.MCRETURN
                {value = compileValue subst value,
                 loc = loc})
      | A.ANCOPY {srcExp, dstAddr, valueSize, nextExp, loc} =>
        mid (M.MCMEMCPY_FIELD
               {dstAddr = compileAddress subst loc dstAddr,
                srcAddr = M.MAPACKED (compileValue subst srcExp),
                copySize = compileValue subst valueSize,
                loc = loc})
        o compileExp subst nextExp
      | A.ANSTORE {srcExp, srcTy, dstAddr, nextExp, loc} =>
        mid (M.MCSTORE
               {srcExp = compileValue subst srcExp,
                srcTy = srcTy,
                dstAddr = compileAddress subst loc dstAddr,
                barrier = case srcTy of (_, {tag=R.BOXED,...}) => true
                                      | _ => false,
                loc = loc})
        o compileExp subst nextExp
      | A.ANEXPORTVAR {id, ty, valueExp, nextExp, loc} =>
        mid (M.MCEXPORTVAR
               {id = id,
                ty = ty,
                valueExp = compileValue subst valueExp,
                loc = loc})
        o compileExp subst nextExp
      | A.ANRAISE {argExp, cleanup, loc} =>
        let
          val argExp = compileValue subst argExp
          val bufVar = {id = VarID.generate (), ty = boxedTy ()}
        in
          Alloc
            {resultVar = bufVar,
             objType = M.OBJTYPE_RECORD,
             payloadSize = wordConst 0w56,
             allocSize = wordConst 0w60,
             initExp =
               mid (M.MCSTORE
                      {dstAddr = M.MAOFFSET {base = M.ANVAR bufVar,
                                             offset = intConst 56},
                       srcExp = wordConst 0w1,
                       srcTy = word32Ty (),
                       barrier = false,
                       loc = loc})
               o mid (M.MCSTORE
                        {dstAddr = M.MAPTR (M.ANVAR bufVar),
                         srcExp = argExp,
                         srcTy = exnTy (),
                         barrier = false,
                         loc = loc}),
             loc = loc}
          o last (M.MCRAISE
                    {argExp = M.ANVAR bufVar,
                     cleanup = cleanup,
                     loc = loc})
        end
      | A.ANHANDLER {nextExp, exnVar, id, handlerExp, cleanup, loc} =>
        last (M.MCHANDLER
                {nextExp = compileExp subst nextExp (),
                 id = id,
                 exnVar = exnVar,
                 handlerExp = compileExp (mask (subst, [exnVar])) handlerExp (),
                 cleanup = cleanup,
                 loc = loc})
      | A.ANSWITCH {switchExp, expTy, branches, default, loc} =>
        last (M.MCSWITCH
                {switchExp = compileValue subst switchExp,
                 expTy = expTy,
                 branches = branches,
                 default = default,
                 loc = loc})
      | A.ANGOTO {id, argList, loc} =>
        last (M.MCGOTO
                {id = id,
                 argList = map (compileValue subst) argList,
                 loc = loc})
      | A.ANLOCALCODE {recursive, binds, nextExp, loc} =>
        last (M.MCLOCALCODE
                {recursive = recursive,
                 binds = map (compileLocalCode subst) binds,
                 nextExp = compileExp subst nextExp (),
                 loc = loc})
      | A.ANUNREACHABLE =>
        last M.MCUNREACHABLE

  and compileLocalCode subst {id, argVarList, bodyExp} =
      {id = id,
       argVarList = argVarList,
       bodyExp = compileExp (mask (subst, argVarList)) bodyExp ()}

  fun compileTopdec topdec =
      case topdec of
        A.ATFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar, bodyExp,
                      retTy, gcCheck, loc} =>
        M.MTFUNCTION
          {id = id,
           tyvarKindEnv = tyvarKindEnv,
           argVarList = argVarList,
           closureEnvVar = closureEnvVar,
           frameSlots = SlotID.Map.empty,
           bodyExp = compileExp VarID.Map.empty bodyExp (),
           retTy = retTy,
           gcCheck = gcCheck,
           loc = loc}
      | A.ATCALLBACKFUNCTION {id, tyvarKindEnv, argVarList, closureEnvVar,
                              bodyExp, attributes, retTy, cleanupHandler,
                              loc} =>
        M.MTCALLBACKFUNCTION
          {id = id,
           tyvarKindEnv = tyvarKindEnv,
           argVarList = argVarList,
           closureEnvVar = closureEnvVar,
           bodyExp = compileExp VarID.Map.empty bodyExp (),
           frameSlots = SlotID.Map.empty,
           attributes = attributes,
           retTy = retTy,
           cleanupHandler = cleanupHandler,
           loc = loc}

  fun compile ({topdata, topdecs, topExp, topCleanupHandler}:A.program) =
      let
        val topdecs = map compileTopdec topdecs
        val topExp = compileExp VarID.Map.empty topExp ()
        val toplevel = {frameSlots = SlotID.Map.empty,
                        bodyExp = topExp,
                        cleanupHandler = topCleanupHandler}
      in
        {topdata = topdata, topdecs = topdecs, toplevel = toplevel} : M.program
      end

end
