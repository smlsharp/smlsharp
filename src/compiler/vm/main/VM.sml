(**
 * The implementation of IML runtime.
 * <p>
 * This module provides a virtual machine which executes IML instructions.
 * </p>
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Nguyen Huu Duc
 * @version $Id: VM.sml,v 1.111 2006/03/01 08:55:47 kiyoshiy Exp $
 *)
structure VM :> VM =
struct

  (***************************************************************************)

  open RuntimeTypes
  open BasicTypes
  structure E = Executable
  structure BTS = BasicTypeSerializer
  structure I = Instructions
  structure RM = RawMemory
  structure H = Heap
  structure C = Counter
  structure SU = SignalUtility
  structure GT = GlobalTable
  structure FS = FrameStack
  structure HS = HandlerStack
  structure RC = RuntimeCounters
  structure RE = RuntimeErrors
  structure SLD = SourceLanguageDatatypes
  structure U = Utility

  (***************************************************************************)

  val instTrace = ref false
  val stateTrace = ref false
  val heapTrace = ref false

  (***************************************************************************)

  datatype VM =
           VMStatus of
           {
             name : string,
             arguments : string list,
             (** table of boxed globals. *)
             globalTableBoxed : GT.table,
             (** table of unboxed globals. *)
             globalTableUnboxed : GT.table,
             (** heap *)
             heap : H.heap,
             (** frame stack *)
             frameStack : FS.stack,
             (** handler stack. *)
             handlerStack : HS.stack,
             ENV : cellValue ref,
             (** channel to used as standard input. *)
             standardInput : CharacterStreamWrapper.InputStream,
             (** channel to used as standard output. *)
             standardOutput : CharacterStreamWrapper.OutputStream,
             (** channel to used as standard error. *)
             standardError : CharacterStreamWrapper.OutputStream,
             (** the address of flag which indicates a received signal. *)
             signalFlagAddress : cellValue RM.pointer,
             primitives : primitive IEnv.map,
             debuggerOpt : debugger option,
             CurCb : executable ref,
             nextInstOffsetRef : UInt32 ref
           }

  withtype primitive =
       {
         name : string,
         function
         : VM
           -> Heap.heap
           -> RuntimeTypes.cellValue list
           -> RuntimeTypes.cellValue list,
         argSizes : BasicTypes.UInt32 list
       }

  and debugger =
      {
        onBreakPointHit
        : VM
          -> RuntimeTypes.codeRef
          -> (Instructions.OPCODE_instruction * bool),
        onUncaughtException
        : VM -> RuntimeTypes.codeRef -> RuntimeTypes.cellValue -> unit,
        onRuntimeError : VM -> RuntimeTypes.codeRef -> exn -> unit
      }

  (***************************************************************************)

  exception PrimitiveException of RuntimeTypes.cellValue

  (***************************************************************************)

  (** print a string to the standard output. *)
  fun print (VMStatus {standardOutput, ...}) string =
      #print standardOutput string

  (** print a string to the standard error. *)
  fun printError (VMStatus {standardError, ...}) string =
      #print standardError string

  (** textual representation of machine status. *)
  fun statusToString (VMStatus {frameStack, ENV, ...}) = 
      " ENV : " ^ (cellValueToString (!ENV)) ^ "\n" ^
      "frame: "
      ^ FS.frameToString frameStack (FS.getCurrentFrame frameStack) ^ "\n"

  (* signal flag occupies one cell of memory. *)
  val signalFlagSize = 0w1 : UInt32; 

  fun initialize
          {
            name,
            arguments,
            heapSize,
            frameStackSize,
            handlerStackSize,
            globalCount,
            standardInput,
            standardOutput,
            standardError,
            primitives,
            debuggerOpt
          } = 
      let
        val memory =
            RM.initialize
            (
              Word 0w0,
              signalFlagSize
              + heapSize
              + frameStackSize
              + handlerStackSize
              + (globalCount * 0w2)
            )
        val freeArea = ref memory

        (* setup registers *)
        val signalFlagAddress = memory
        val _ = freeArea := RM.advance(!freeArea, signalFlagSize)
        val ENV = ref (Pointer (!freeArea)) (* dummy value *)
        fun traceRegisters traceRoot =
            app (fn register => register := traceRoot (!register)) [ENV]

        (* setup frame stack *)
        val frameStack =
            FS.initialize {memory = !freeArea, size = frameStackSize}
        val traceFrameStack = FrameStack.traceStack frameStack
        val _ = freeArea := RM.advance(!freeArea, frameStackSize)

        (* setup handler stack *)
        val handlerStack =
            HS.initialize {memory = !freeArea, size = handlerStackSize}
        val _ = freeArea := RM.advance(!freeArea, handlerStackSize)

        (* setup global table *)
        val globalTableBoxed = GT.initialize(!freeArea, globalCount)
        val _ = freeArea := RM.advance(!freeArea, globalCount)
        val globalTableUnboxed = GT.initialize(!freeArea, globalCount)
        val _ = freeArea := RM.advance(!freeArea, globalCount)
        val traceGlobalTable = GT.traceTable globalTableBoxed

        (* setup heap *)
        val heap =
            H.initialize
            {
              memory = !freeArea,
              memorySize = heapSize,
              rootSets = [traceRegisters, traceFrameStack, traceGlobalTable]
            }
        val _ = freeArea := RM.advance(!freeArea, heapSize)
      in
        (* build machine status *)
        VMStatus
        {
          name = name,
          arguments = arguments,
          globalTableBoxed = globalTableBoxed,
          globalTableUnboxed = globalTableUnboxed,
          heap = heap,
          frameStack = frameStack,
          handlerStack = handlerStack,
          ENV = ENV,
          standardInput = CharacterStreamWrapper.wrapIn standardInput,
          standardOutput = CharacterStreamWrapper.wrapOut standardOutput,
          standardError = CharacterStreamWrapper.wrapOut standardError,
          signalFlagAddress = signalFlagAddress,
          primitives = primitives,
          debuggerOpt = debuggerOpt,
          CurCb = ref emptyExecutable,
          nextInstOffsetRef = ref 0w0
        }
      end
    
  exception Exit

  fun getFrameStack (VMStatus{frameStack, ...}) = frameStack

  fun getHeap (VMStatus{heap, ...}) = heap

  fun getCurrentCodeRef (VMStatus{CurCb, nextInstOffsetRef, ...}) =
      {executable = !CurCb, offset = !nextInstOffsetRef}

  fun getStackTraceStrings (VM as VMStatus{frameStack, ...}) =
      let
        fun toString NONE = "???"
          | toString (SOME loc) = AbsynFormatter.locToString loc

        val frames = FS.getFrames frameStack
        val codeRefs =
            (getCurrentCodeRef VM) :: (map FS.getReturnAddressOfFrame frames)
        val locs =
            map
                (fn codeRef => LocationTable.getLocationOfCodeRef codeRef)
                codeRefs
      in
        map toString locs
      end

  fun execute
      (
        VM as
        VMStatus {
             globalTableBoxed,
             globalTableUnboxed,
             heap,
             frameStack,
             handlerStack,
             ENV,
             standardInput,
             standardOutput,
             standardError,
             signalFlagAddress,
             primitives,
             debuggerOpt,
             CurCb,
             nextInstOffsetRef,
             ...
           },
        executable
      ) =
      let

        (********************)

        (* setup initial status.
         * <ul>
         *   <li>initialize registers.</li>
         *   <li>allocates a frame which contains one pointer slot where ENV
         *       is saved.</li>
         * </ul>
         *)
        val _ = FS.popAllFrames frameStack
        val _ = HS.popAllHandlers handlerStack
(*
val _ = TextIO.print "initialize registers\n"
*)

        val _ = CurCb := executable
        val _ = nextInstOffsetRef := 0w0

        val cp = ref (!nextInstOffsetRef)
        val nextInstOpcodeRef = ref I.OPCODE_Nop
        val _ =
            ENV :=
            Pointer
                (H.allocateBlock
                     heap
                     {bitmap = 0w0, size = 0w0, blockType = RecordBlock})
(*
val _ = TextIO.print "finish initialization of registers\n"
*)
        (********************)

        fun traceInst instructionOffset opcode =
            if !instTrace
            then
              let
                val message = 
                    UInt32.toString instructionOffset
                    ^ ":"
                    ^ Instructions.opcodeToString opcode
                    ^ "\n"
              in
                printError VM message
              end
            else ()
        fun traceState VM =
            if !stateTrace then printError VM (statusToString VM) else ()
        fun traceHeap message =
            if !heapTrace then printError VM message else ()

        (********************)

        fun setSignalFlag signalReceived =
            RM.store
                (signalFlagAddress, Word (if signalReceived then 0w1 else 0w0))

        fun getSignalFlag () =
            case RM.load signalFlagAddress of
              Word 0w0 => false
            | Word 0w1 => true
            | value =>
              raise
                RE.InvalidStatus ("getSignalFlag:" ^ (cellValueToString value))

        (********************)

        fun makeReader address =
            let
              val buffer = #instructionsArray(!CurCb)
              val pos = ref address
            in
              fn () => Word8Array.sub (buffer, !pos) before pos := !pos + 1
            end
        (* functions which retrieve operands from the code block. *)
        fun getSInt32At address =
            BTS.deserializeSInt32
                  (makeReader (UInt32ToInt (address * BytesOfUInt32)))
        fun getUInt32At address =
              BTS.deserializeUInt32
                  (makeReader (UInt32ToInt (address * BytesOfUInt32)))
        fun getUInt32ListAt address count =
            List.tabulate
            (
              UInt32ToInt count,
              fn offset => getUInt32At (address + IntToUInt32 offset)
            )
        fun getReal64At address =
            BTS.deserializeReal64
                (makeReader (UInt32ToInt (address * BytesOfUInt32)))
        fun getUInt8ListAt address wordsCount =
            let
              val addressInBytes = UInt32ToInt (address * BytesOfUInt32)
            in
              List.tabulate
              (
                UInt32ToInt (wordsCount * BytesOfUInt32),
                fn index =>
                   BTS.deserializeUInt8 (makeReader (addressInBytes + index))
              )
            end

        fun getSInt32 () = getSInt32At (!cp) before cp := !cp + 0w1
        fun getUInt32 () = getUInt32At (!cp) before cp := !cp + 0w1
        fun getUInt32List count =
            List.tabulate (UInt32ToInt count, fn _ => getUInt32 ())
        fun getReal64 () = getReal64At (!cp) before cp := !cp + 0w2
        fun getUInt8List wordsCount =
            getUInt8ListAt (!cp) wordsCount
            before cp := !cp + wordsCount
        fun getOpcodeAt address = U.getOpcodeAt (!CurCb) address
        fun setOpcodeAt address opcode = U.setOpcodeAt (!CurCb) address opcode

        (********************)

        fun raiseInvalidArguments message argValues =
            raise
              RE.InvalidCode
                  (message ^ 
                   ": " ^
                   (concat
                    (map
                         (fn value => cellValueToString value ^ ",")
                         argValues)))

        (********************)

        fun fetchConstString stringAddress =
            let
              val opcode = getOpcodeAt stringAddress
              val _ =
                  if I.OPCODE_ConstString = opcode
                  then ()
                  else
                    raise
                      RE.InvalidCode
                      ("ConstString expected, but " ^
                       Instructions.opcodeToString opcode)
              val length = getUInt32At (stringAddress + 0w1)
              val lengthInWords = (length + BytesOfUInt32) div BytesOfUInt32
              val byteArray =
                  Word8Array.fromList
                      (getUInt8ListAt (stringAddress + 0w2) lengthInWords)
            in (byteArray, length) end

        (********************)

        val INDEX_OF_ENTRYPOINT_IN_CLOSURE = 0w0 : UInt32
        val INDEX_OF_ENV_IN_CLOSURE = 0w1 : UInt32
        val BITMAP_OF_CLOSURE = 0w2 : UInt32 (* [1, 0] *)
        val INDEX_OF_NEST_POINTER = 0w0 : UInt32

        fun allocateClosure (entryPoint, ENVIndex) =
            let
              val blockAddress =
                  H.allocateBlock
                      heap
                      {
                        size = 0w2,
                        bitmap = BITMAP_OF_CLOSURE,
                        blockType = RecordBlock
                      }
              val ENVBlock = FS.load (frameStack, ENVIndex)
              val _ =
                  H.setFields
                      heap
                      (
                        blockAddress,
                        0w0,
                        [
                          CodeRef{executable = !CurCb, offset = entryPoint},
                          ENVBlock
                        ]
                      )
            in
              blockAddress
            end

        fun expandClosure closureIndex =
            let
              (* expand closure *)
              val closureAddress =
                  pointerOf "closure" (FS.load (frameStack, closureIndex))

              (* check *)
              val _ = case H.getSize heap closureAddress of
                        0w2 => ()
                      | size =>
                        raise
                          RE.InvalidCode
                              ("invalid closure of " ^ UInt32.toString size ^
                               " fields")
              val _ = let val bitmap = H.getBitmap heap closureAddress
                      in
                        if BITMAP_OF_CLOSURE = bitmap
                        then ()
                        else
                          raise
                            RE.InvalidCode
                                ("invalid bitmap of closure " ^
                                 UInt32.toString bitmap)
                      end

              val entryPoint =
                  codeRefOf
                      "entryPoint in closure"
                      (H.getField
                           heap
                           (closureAddress, INDEX_OF_ENTRYPOINT_IN_CLOSURE))
              val restoredENV = 
                  H.getField
                      heap
                      (closureAddress, INDEX_OF_ENV_IN_CLOSURE)
            in (entryPoint, restoredENV) end

        (********************)

        (**
         * <p>
         * Every function call passes a block as the first argument.
         * This block is used as the environment block in the called
         * function.
         * </p>
         * <p>
         * It is to be noted that this special argument is specified
         * differently by the caller (= Apply/CallStaic) and the callee
         * (= FunEntry). In the caller site, this argument is included
         * in arguments list explicitly. On the other hand, in the callee
         * site, this argument is not specified. Therefore, the number
         * of elements in the arguValues is one more than the arity in
         * the FunEntry.
         * </p>
         *)
        fun callFunction (_, [], _) =
            raise RE.InvalidCode "at least one argument is required."
          | callFunction
            (
              {executable, offset},
              [Pointer newENVAddress] :: argValues,
              returnAddress
            ) =
            let
              val _ = CurCb := executable
              val funinfoAddress = {executable = executable, offset = offset} 
              val _ = cp := (offset + 0w1) (* skip 'FunEntry' *)
              val frameSize = getUInt32 ()
              val startOffset = getUInt32 ()
              val arity = getUInt32 () (* not include ENV *)
              val argsdest = 
                  if 0w0 = arity 
                  then [] (* special case for the entry point function. *)
                  else getUInt32List arity (* not include ENV *)
              val bitmapvalsFreesCount = getUInt32 ()
              val bitmapvalsFrees = getUInt32List bitmapvalsFreesCount
              val bitmapvalsArgsCount = getUInt32 ()
              val bitmapvalsArgs = getUInt32List bitmapvalsArgsCount
              val pointers = getUInt32 () (* ENV is included *)
              val atoms = getUInt32 ()
              val recordGroupsCount = getUInt32 ()
              val recordGroups = getUInt32List recordGroupsCount

              val _ =
                  if 
                    0w0 < arity 
                    andalso UInt32ToInt arity <> List.length argValues
                  then
                    raise
                      RE.InvalidCode
                          ("arity is " ^ UInt32.toString arity ^
                           ", but the number of passed arguments is " ^
                           Int.toString(List.length argValues))
                  else ()

              fun getBitmapFromArg index =
                  if index < arity
                  then 
                    let
                      val values = List.nth (argValues, UInt32ToInt index)
                    in
                      case values of
                        [value] => value
                      | _ => 
                        raise 
                          RE.InvalidCode "bitmapvalArg must be a single word"
                    end
                  else
                    raise
                      RE.InvalidCode
                          ("bitmapvalArgs specify " ^ UInt32.toString index ^
                           ", but arity is " ^ UInt32.toString arity)
              val newENVFields = H.getSize heap newENVAddress
              fun getBitmapFromFree index =
                  if index < newENVFields
                  then H.getField heap (newENVAddress, index)
                  else 
                    raise
                      RE.InvalidCode
                          ("bitmapvalFrees specify " ^ UInt32.toString index ^
                           ", but ENV has " ^ UInt32.toString newENVFields)

              (*  get bitmaps from locations that are indicated by indexes,
               * and compose them to make a result bitmap.
               *)
              fun buildBitmapFromIndexes getOneBitmap initialBitmap indexes =
                  foldr
                      (fn (index, bitmap) =>
                          let val bit = wordOf "bitmap" (getOneBitmap index)
                          in
(*
                            TextIO.print ("composing bitmap = " ^ UInt32.toString bitmap ^ "\n");
                            TextIO.print ("compose bit = " ^ UInt32.toString bit ^ "\n");
*)
                            UInt32.orb(UInt32.<<(bitmap, 0w1), bit)
                          end)
                      initialBitmap
                      indexes
              val bitmap =
                  buildBitmapFromIndexes getBitmapFromFree 0w0 bitmapvalsFrees
(*
val _ = print VM ("composed bitmap(free) = " ^ UInt32.toString bitmap ^ "\n")
*)
              val bitmap =
                  buildBitmapFromIndexes getBitmapFromArg bitmap bitmapvalsArgs
(*
val _ = print VM ("composed bitmap(arg) = " ^ UInt32.toString bitmap ^ "\n")
*)
(*
val _ = TextIO.print ("# recordGroups = " ^ UInt32.toString recordGroupsCount ^ "\n")
val _ = TextIO.print ("composed bitmap = " ^ UInt32.toString bitmap ^ "\n")
*)
              val _ =
                  FS.allocateFrame
                  (
                    frameStack,
                    frameSize,
                    funinfoAddress,
                    bitmap,
                    returnAddress
                  )
              val _ =
                  app
                  (fn (index, value) => FS.store_N (frameStack, index, value))
                  (ListPair.zip (argsdest, argValues))

              val _ = ENV := Pointer newENVAddress
            in () end
          | callFunction (_, [ENVArg] :: argValues, _) =
            raise
              RE.InvalidCode
                  ("the first argument should be a reference to ablock, " ^
                   "but found " ^ cellValueToString ENVArg)

        (********************)

        fun doSwitch (getObject, getTag) =
            let
              val targetIndex = getUInt32 ()
              (* target is one word object*)
              val targetValue = getObject(FS.load (frameStack, targetIndex))
              val casesCount = getUInt32 ()
              fun scan 0w0 =
                  let val defaultDestination = getUInt32 ()
                  in cp := defaultDestination end
                | scan remainCases =
                  let
                    val pattern = getTag ()
                    val destination = getUInt32 ()
                  in
                    if pattern = targetValue
                    then cp := destination
                    else scan (remainCases - 0w1)
                  end
            in
              scan casesCount 
            end

        (********************)
        fun rshift (w1 : UInt32, w2 : UInt32) =
            UInt32.>>(w1, Word.fromLargeWord w2)

        fun lshift (w1 : UInt32, w2 : UInt32) =
            UInt32.<<(w1, Word.fromLargeWord w2)

        fun doPrimitive1 name argSize operation =
            let
              val argOffset = getUInt32 ()
              val destination = getUInt32 ()
              val arg = FS.load_N (frameStack, argOffset, argSize)
              val resultValue = operation arg
                  handle Match =>
                         raiseInvalidArguments
                             ("invalid arguments to " ^ name) arg
              val _ =  FS.store_N (frameStack, destination, resultValue)
            in () end

        fun doIntPrimitive1 name operation =
            doPrimitive1 name 0w1 (fn [Int value] => [Int (operation value)])

        fun doWordPrimitive1 name operation =
            doPrimitive1 name 0w1 (fn [Word value] => [Word (operation value)])

        fun doCharPrimitive1 name 0w1 operation =
            doPrimitive1 name 0w1 (fn [Word value] => [Word (operation value)])
        val doBytePrimitive1 = doCharPrimitive1

        fun doRealPrimitive1 name operation =
            doPrimitive1 
                name 
                0w2
                (fn [Real value, Word 0w0] =>
                    [Real (operation value), Word 0w0])

        fun doBoxedRealPrimitive1 name operation =
            doPrimitive1 
                name 
                0w1
                (fn [arg as Pointer _] =>
                    let val value = SLD.expandRealBlock heap arg
                    in
                      [Pointer (SLD.allocateRealBlock heap (operation value))]
                    end)

        fun doPrimitive2 name (argSize1, argSize2) operation =
            let
              val argOffset1 = getUInt32 ()
              val argOffset2 = getUInt32 ()
              val destination = getUInt32 ()
              val arg1 = FS.load_N (frameStack, argOffset1, argSize1)
              val arg2 = FS.load_N (frameStack, argOffset2, argSize2)
              val resultValue =
                  operation (arg1, arg2)
                  handle Match =>
                         raiseInvalidArguments
                             ("invalid arguments to " ^ name) (arg1 @ arg2)
              val _ = FS.store_N (frameStack, destination, resultValue)
            in () end

        fun doIntPrimitiveConst2_1 name operation =
            let
              val argValue1 = getSInt32 ()
              val argOffset2 = getUInt32 ()
              val destination = getUInt32 ()

              val argValue2 = 
                  intOf
                      name
                      (FS.load (frameStack,argOffset2))
              val resultValue = Int (operation (argValue1,argValue2))
              val _ = FS.store (frameStack, destination, resultValue)
            in () end

        fun doIntPrimitiveConst2_2 name operation =
            let
              val argOffset1 = getUInt32 ()
              val argValue2 = getSInt32 ()
              val destination = getUInt32 ()

              val argValue1 = 
                  intOf
                      name
                      (FS.load (frameStack,argOffset1))
              val resultValue = Int (operation (argValue1,argValue2))
              val _ = FS.store (frameStack, destination, resultValue)
            in () end

        fun doWordPrimitiveConst2_1 name operation =
            let
              val argValue1 = getUInt32 ()
              val argOffset2 = getUInt32 ()
              val destination = getUInt32 ()

              val argValue2 = 
                  wordOf
                      name
                      (FS.load (frameStack,argOffset2))
              val resultValue = Word (operation (argValue1,argValue2))
              val _ = FS.store (frameStack, destination, resultValue)
            in () end

        fun doWordPrimitiveConst2_2 name operation =
            let
              val argOffset1 = getUInt32 ()
              val argValue2 = getUInt32 ()
              val destination = getUInt32 ()

              val argValue1 = 
                  wordOf
                      name
                      (FS.load (frameStack,argOffset1))
              val resultValue = Word (operation (argValue1,argValue2))
              val _ = FS.store (frameStack, destination, resultValue)
            in () end

        fun doRealPrimitiveConst2_1 name operation =
            let
              val argValue1 = getReal64 ()
              val argOffset2 = getUInt32 ()
              val destination = getUInt32 ()

              val argValue2 = 
                  realOf
                      name
                      (FS.load_N (frameStack,argOffset2,0w2))
              val resultValue = Real64ToCellValues (operation (argValue1,argValue2))
              val _ = FS.store_N (frameStack, destination, resultValue)
            in () end

        fun doRealPrimitiveConst2_2 name operation =
            let
              val argOffset1 = getUInt32 ()
              val argValue2 = getReal64 ()
              val destination = getUInt32 ()

              val argValue1 = 
                  realOf
                      name
                      (FS.load_N (frameStack,argOffset1,0w2))
              val resultValue = Real64ToCellValues (operation (argValue1,argValue2))
              val _ = FS.store_N (frameStack, destination, resultValue)
            in () end

        fun doCharPrimitiveConst2_1 name operation =
            let
              val argValue1 = getUInt32 ()
              val argOffset2 = getUInt32 ()
              val destination = getUInt32 ()

              val argValue2 = 
                  charOf
                      name
                      (FS.load (frameStack,argOffset2))
              val resultValue = Word (operation (argValue1,argValue2))
              val _ = FS.store (frameStack, destination, resultValue)
            in () end

        fun doCharPrimitiveConst2_2 name operation =
            let
              val argOffset1 = getUInt32 ()
              val argValue2 = getUInt32 ()
              val destination = getUInt32 ()

              val argValue1 = 
                  charOf
                      name
                      (FS.load (frameStack,argOffset1))
              val resultValue = Word (operation (argValue1,argValue2))
              val _ = FS.store (frameStack, destination, resultValue)
            in () end

        val doBytePrimitiveConst2_1  = doCharPrimitiveConst2_1
        val doBytePrimitiveConst2_2  = doCharPrimitiveConst2_2


        fun doIntPrimitive2 name operation =
            doPrimitive2
                name
                (0w1,0w1)
                (fn ([Int left], [Int right]) =>
                    [Int (operation (left, right))])

        fun doWordPrimitive2 name operation =
            doPrimitive2
                name
                (0w1,0w1)
                (fn ([Word left], [Word right]) =>
                    [Word (operation (left, right))])

        fun doCharPrimitive2 name operation =
            doPrimitive2
                name
                (0w1,0w1)
                (fn ([Word left], [Word right]) =>
                    [Word (operation (left, right))])
        val doBytePrimitive2 = doCharPrimitive2

        fun doRealPrimitive2 name operation =
            doPrimitive2
                name
                (0w2,0w2)
                (fn ([Real left, Word 0w0], [Real right, Word 0w0]) 
                    => [Real (operation (left, right)), Word 0w0])

        fun doBoxedRealPrimitive2 name operation =
            doPrimitive2
                name
                (0w1,0w1)
                (fn ([left as Pointer _],[right as Pointer _]) =>
                    let
                      val leftValue = SLD.expandRealBlock heap left
                      val rightValue = SLD.expandRealBlock heap right
                      val resultValue = operation (leftValue, rightValue)
                      val resultBlock = SLD.allocateRealBlock heap resultValue
                    in
                      [Pointer resultBlock]
                    end)

        fun doPredicate1 name argSize operation =
            doPrimitive1
                name
                argSize
                (fn arg =>
                    if operation arg
                    then [SLD.boolToValue heap true]
                    else [SLD.boolToValue heap false])

        fun doPredicate2 name (argSize1,argSize2) operation =
            doPrimitive2
                name
                (argSize1,argSize2)
                (fn arg =>
                    if operation arg
                    then [SLD.boolToValue heap true]
                    else [SLD.boolToValue heap false])

        fun doIntPredicate2 name operation =
            doPredicate2
                name
                (0w1,0w1)
                (fn ([Int left], [Int right]) => operation (left, right))

        fun doWordPredicate2 name operation =
            doPredicate2
                name
                (0w1,0w1)
                (fn ([Word left], [Word right]) => operation (left, right))

        fun doCharPredicate2 name operation =
            doPredicate2
                name
                (0w1,0w1)
                (fn ([Word left], [Word right]) => operation (left, right))
        val doBytePredicate2 = doCharPredicate2

        fun doRealPredicate2 name operation =
            doPredicate2
                name 
                (0w2,0w2)
                (fn ([Real left, Word 0w0], [Real right, Word 0w0]) 
                    => operation (left, right) )

        fun doBoxedRealPredicate2 name operation =
            doPredicate2
                name 
                (0w1,0w1)
                (fn ([left as Pointer _], [right as Pointer _]) =>
                    let
                      val leftValue = SLD.expandRealBlock heap left
                      val rightValue = SLD.expandRealBlock heap right
                    in operation (leftValue, rightValue) end)
            
        fun doStringPredicate2 name operation =
            doPredicate2
                name
                (0w1,0w1)
                (fn ([left], [right]) =>
                    let
                      val leftString =
                          UInt8ArrayToString (SLD.expandStringBlock heap left)
                      val rightString =
                          UInt8ArrayToString (SLD.expandStringBlock heap right)
                    in operation (leftString, rightString) end)

        (****************************************)

        fun loadSingleSize () = 0w1 : UInt32
        fun loadDoubleSize () = 0w2 : UInt32
        fun loadVariantSize () =
            let
              val sizeOffset = getUInt32()
            in
              wordOf
                  "loadVariantSize"
                  (FS.load (frameStack, sizeOffset))
            end

        fun getNestedBlock (0, blockAddress) = blockAddress
          | getNestedBlock (n, blockAddress) =
            getNestedBlock
                (
                  n - 1,
                  pointerOf
                      "nest pointer"
                      (H.getField heap (blockAddress, INDEX_OF_NEST_POINTER))
                )

        fun doAccess sizeLoader =
            let
              val variableOffset = getUInt32 ()
              val variableSize = sizeLoader () 
              val destination = getUInt32 ()

              val value = FS.load_N (frameStack, variableOffset, variableSize)

              val _ = FS.store_N (frameStack, destination, value)
            in () end

        fun doAccessEnv sizeLoader =
            let
              val offset = getUInt32 ()
              val variableSize = sizeLoader ()
              val destination = getUInt32 ()
                                
              val ENVAddress = pointerOf "ENV" (!ENV)
              val value = H.getFields heap (ENVAddress, offset, variableSize)
              val _ = FS.store_N (frameStack, destination, value)
            in () end

        fun doAccessEnvIndirect sizeLoader =
            let
              val indirectOffset = getUInt32 ()
              val variableSize = sizeLoader ()
              val destination = getUInt32 ()

              val ENVAddress = pointerOf "ENV" (!ENV)
              val offset =
                  wordOf
                      ("variable offset in AccessEnvIndirect")
                      (H.getField heap (ENVAddress, indirectOffset))

              val value = H.getFields heap (ENVAddress, offset, variableSize)
              val _ = FS.store_N (frameStack, destination, value)
            in () end

        fun doAccessNestedEnv sizeLoader =
            let
              val nestLevel = getUInt32 ()
              val offset = getUInt32 ()
              val variableSize = sizeLoader ()
              val destination = getUInt32 ()
                                
              val ENVAddress = pointerOf "ENV" (!ENV)

              val blockAddress =
                  getNestedBlock(UInt32.toInt nestLevel, ENVAddress)

              val value = H.getFields heap (blockAddress, offset, variableSize)
              val _ = FS.store_N (frameStack, destination, value)
            in () end

        fun doAccessNestedEnvIndirect sizeLoader =
            let
              val nestLevel = getUInt32 ()
              val indirectOffset = getUInt32 ()
              val variableSize = sizeLoader ()
              val destination = getUInt32 ()

              val ENVAddress = pointerOf "ENV" (!ENV)
              val blockAddress =
                  getNestedBlock(UInt32.toInt nestLevel, ENVAddress)

              val offset =
                  wordOf
                      ("variable offset in AccessNestedEnvIndirect")
                      (H.getField heap (blockAddress, indirectOffset))

              val value = H.getFields heap (blockAddress, offset, variableSize)
              val _ = FS.store_N (frameStack, destination, value)
            in () end


        fun doGetField sizeLoader =
            let
              val fieldOffset = getUInt32 ()
              val fieldSize = sizeLoader ()
              val blockOffset = getUInt32 ()
              val destination = getUInt32 ()
                                
              val blockAddress =
                  pointerOf
                      "block in GetField"
                      (FS.load (frameStack, blockOffset))
              val fieldValue =
                  H.getFields heap (blockAddress, fieldOffset, fieldSize)
              val _ = FS.store_N (frameStack, destination, fieldValue)
            in () end

        fun doGetFieldIndirect sizeLoader =
            let
              val fieldVariableOffset = getUInt32 ()
              val fieldSize = sizeLoader ()
              val blockOffset = getUInt32 ()
              val destination = getUInt32 ()
                                
              val fieldOffset =
                  wordOf
                      "field offset of GetFieldIndirect"
                      (FS.load (frameStack, fieldVariableOffset))
              val blockAddress =
                  pointerOf
                      "block in GetFieldIndirect"
                      (FS.load (frameStack, blockOffset))
              val fieldValue =
                  H.getFields heap (blockAddress, fieldOffset, fieldSize)
              val _ = FS.store_N (frameStack, destination, fieldValue)
            in () end

        fun doGetNestedFieldIndirect sizeLoader =
            let
              val nestLevelOffset = getUInt32 ()
              val fieldVariableOffset = getUInt32 ()
              val fieldSize = sizeLoader ()
              val blockOffset = getUInt32 ()
              val destination = getUInt32 ()

              val nestLevel =
                  wordOf
                      "nest level of GetNestedFieldIndirect"
                      (FS.load (frameStack, nestLevelOffset))

              val fieldOffset =
                  wordOf
                      "field offset of GetNestedFieldIndirect"
                      (FS.load (frameStack, fieldVariableOffset))
              val rootBlockAddress =
                  pointerOf
                      "root block in GetNestedFieldIndirect"
                      (FS.load (frameStack, blockOffset))

              val blockAddress =
                  getNestedBlock(UInt32.toInt nestLevel, rootBlockAddress)

              val fieldValue =
                  H.getFields heap (blockAddress, fieldOffset, fieldSize)
              val _ = FS.store_N (frameStack, destination, fieldValue)
            in () end

        fun doSetField sizeLoader =
            let
              val fieldOffset = getUInt32 ()
              val fieldSize = sizeLoader ()
              val blockOffset = getUInt32 ()
              val valueOffset = getUInt32 ()

              val blockAddress =
                  pointerOf
                      "block in SetField"
                      (FS.load (frameStack, blockOffset))
              val value = FS.load_N (frameStack, valueOffset, fieldSize)
              val _ = H.setFields heap (blockAddress, fieldOffset, value)
            in () end

        fun doSetFieldIndirect sizeLoader =
            let
              val fieldVariableOffset = getUInt32 ()
              val fieldSize = sizeLoader ()
              val blockOffset = getUInt32 ()
              val valueOffset = getUInt32 ()

              val fieldOffset =
                  wordOf
                      "field offset of SetFieldIndirect"
                      (FS.load (frameStack, fieldVariableOffset))
              val blockAddress =
                  pointerOf
                      "block in SetFieldIndirect"
                      (FS.load (frameStack, blockOffset))
              val value = FS.load_N (frameStack, valueOffset, fieldSize)
              val _ = H.setFields heap (blockAddress, fieldOffset, value)
            in () end

        fun doSetNestedFieldIndirect sizeLoader =
            let
              val nestLevelOffset = getUInt32 ()
              val fieldVariableOffset = getUInt32 ()
              val fieldSize = sizeLoader ()
              val blockOffset = getUInt32 ()
              val valueOffset = getUInt32 ()

              val nestLevel =
                  wordOf
                      "nest level of SetNestedFieldIndirect"
                      (FS.load (frameStack, nestLevelOffset))

              val fieldOffset =
                  wordOf
                      "field offset of SetNestedFieldIndirect"
                      (FS.load (frameStack, fieldVariableOffset))

              val rootBlockAddress =
                  pointerOf
                      "root block in SetNestedFieldIndirect"
                      (FS.load (frameStack, blockOffset))

              val blockAddress =
                  getNestedBlock(UInt32.toInt nestLevel, rootBlockAddress)

              val value = FS.load_N (frameStack, valueOffset, fieldSize)
              val _ = H.setFields heap (blockAddress, fieldOffset, value)
            in () end


        fun doGetGlobal sizeLoader = 
            let
              val globalArrayIndex = getUInt32 ()
              val offset = getUInt32 ()
              val destination = getUInt32 ()
              val variableSize = sizeLoader ()
                                
              val globalArray = 
                  pointerOf
                      "GetGlobal"
                      (GT.get globalTableBoxed globalArrayIndex)
              val value = H.getFields heap (globalArray, offset, variableSize)
              val _ = FS.store_N (frameStack, destination, value)
            in () end

        fun doSetGlobal sizeLoader = 
            let
              val globalArrayIndex = getUInt32 ()
              val offset = getUInt32 ()
              val variableOffset = getUInt32 ()
              val variableSize = sizeLoader ()
                                
              val globalArray = 
                  pointerOf
                      "GetGlobal"
                      (GT.get globalTableBoxed globalArrayIndex)
              val value = FS.load_N (frameStack, variableOffset, variableSize)
              val _ = H.setFields heap (globalArray, offset, value)
            in () end

        fun doInitGlobalArray {bitmap, blockType} = 
            let
              val globalArrayIndex = getUInt32 ()
              val arraySize = getUInt32 ()
                              
              val blockAddress =
                  H.allocateBlock
                      heap
                      {
                       size = arraySize,
                       bitmap = bitmap,
                       blockType = blockType
                      }
              val elementCount = 
                  case blockType of
                    SingleArrayBlock => arraySize
                  | DoubleArrayBlock => Word32.>>(arraySize, 0w1)
              val nullAddress = H.getEmptyBlockAddress heap
              val (initialValue, initialValueSize) =
                  case (bitmap, blockType) of
                    (0w0,SingleArrayBlock) => ([Word 0w0],0w1)
                  | (0w0,DoubleArrayBlock) => ([Word 0w0, Word 0w0],0w2)
                  | (0w1,_) => ([Pointer nullAddress],0w1)
              val _ =
                  List.tabulate
                      (
                       UInt32ToInt elementCount,
                       fn index => 
                           H.setFields 
                               heap 
                               (
                                 blockAddress,
                                 (IntToUInt32 index) * initialValueSize, initialValue
                               )
                      )
              val _ = GT.set globalTableBoxed (globalArrayIndex, Pointer blockAddress)
            in () end

        fun doApply_S sizeLoader =
            let
              val closureOffset = getUInt32 ()
              val argOffset = getUInt32 ()
              val argSize = sizeLoader ()
              val returnAddress = (* the address of the destination *)
                  {executable = !CurCb, offset = !cp} 
              val destination = getUInt32 () (* this is not used here. *)
                                
              val (entryAddress, restoredENV) = expandClosure closureOffset
              val argValues = [FS.load_N (frameStack, argOffset, argSize)]
                  
              val _ = FS.storeENV (frameStack, !ENV)
                      
              val _ =
                  callFunction
                      (
                        entryAddress,
                        [restoredENV] :: argValues,
                        returnAddress
                      )
            in 
              ()
            end

        fun doApply_ML sizeLoader =
            let
              val closureOffset = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List (argsCount - 0w1)
              val lastArgOffset = getUInt32 ()
              val lastArgSize = sizeLoader ()
              val returnAddress = (* the address of the destination *)
                  {executable = !CurCb, offset = !cp} 
              val destination = getUInt32 () (* this is not used here. *)
                                
              val (entryAddress, restoredENV) = expandClosure closureOffset
              val argValues =
                  map (fn offset => [FS.load (frameStack, offset)]) argOffsets
              val lastArgValue =
                  FS.load_N (frameStack, lastArgOffset, lastArgSize)
                  
              val _ = FS.storeENV (frameStack, !ENV)
                      
              val _ =
                  callFunction
                      (
                        entryAddress,
                        [restoredENV] :: (argValues @ [lastArgValue]),
                        returnAddress
                      )
            in 
              ()
            end

        fun doApply_M () =
            let
              val closureOffset = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List argsCount
              val argSizeOffsets = getUInt32List argsCount
              val returnAddress = (* the address of the destination *)
                  {executable = !CurCb, offset = !cp} 
              val destination = getUInt32 () (* this is not used here. *)

              val (entryAddress, restoredENV) = expandClosure closureOffset
              val argSizes =
                  map 
                      (fn offset =>
                          wordOf
                              "Apply"
                              (FS.load (frameStack,offset))
                      )
                      argSizeOffsets
              val argValues =
                  ListPair.map 
                      (fn (offset,size) => FS.load_N (frameStack, offset, size)) 
                      (argOffsets,argSizes)
                  
              val _ = FS.storeENV (frameStack, !ENV)
                      
              val _ =
                  callFunction
                      (
                        entryAddress,
                        [restoredENV] :: argValues,
                        returnAddress
                      )
            in 
              ()
            end

        fun doTailApply_S sizeLoader =
            let
              val closureOffset = getUInt32 ()
              val argOffset = getUInt32 ()
              val argSize = sizeLoader ()
                                
              val (entryAddress, restoredENV) = expandClosure closureOffset
              val argValues = [FS.load_N (frameStack, argOffset, argSize)]

              val returnAddress =
                  FS.popFrame frameStack (* caller of current *)

              val _ =
                  callFunction
                      (
                        entryAddress,
                        [restoredENV] :: argValues,
                        returnAddress
                      )
            in 
              ()
            end

        fun doTailApply_ML sizeLoader =
            let
              val closureOffset = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List (argsCount - 0w1)
              val lastArgOffset = getUInt32 ()
              val lastArgSize = sizeLoader ()
                                
              val (entryAddress, restoredENV) = expandClosure closureOffset
              val argValues =
                  map (fn offset => [FS.load (frameStack, offset)]) argOffsets
              val lastArgValue =
                  FS.load_N (frameStack, lastArgOffset, lastArgSize)

              val returnAddress =
                  FS.popFrame frameStack (* caller of current *)

              val _ =
                  callFunction
                      (
                        entryAddress,
                        [restoredENV] :: (argValues @ [lastArgValue]),
                        returnAddress
                      )
            in 
              ()
            end

        fun doTailApply_M () =
            let
              val closureOffset = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List argsCount
              val argSizeOffsets = getUInt32List argsCount
                                
              val (entryAddress, restoredENV) = expandClosure closureOffset
              val argSizes =
                  map 
                      (fn offset =>
                          wordOf
                              "Apply"
                              (FS.load (frameStack,offset))
                      )
                      argSizeOffsets
              val argValues =
                  ListPair.map 
                      (fn (offset,size) => FS.load_N (frameStack, offset,size)) 
                      (argOffsets,argSizes)

              val returnAddress =
                  FS.popFrame frameStack (* caller of current *)

              val _ =
                  callFunction
                      (
                        entryAddress,
                        [restoredENV] :: argValues,
                        returnAddress
                      )
            in 
              ()
            end

        fun doCallStatic_S sizeLoader =
            let
              val entryPoint = getUInt32 ()
              val envOffset = getUInt32 ()
              val argOffset = getUInt32 ()
              val argSize = sizeLoader ()
              val returnAddress = (* the address of the destination *)
                  {executable = !CurCb, offset = !cp}
              val destination = getUInt32 () (* this is not used here. *)

              val envBlock = FS.load (frameStack,envOffset)
              val argValues = [FS.load_N (frameStack, argOffset, argSize)]
                  
              val _ = FS.storeENV (frameStack, !ENV)

              val _ =
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [envBlock]::argValues,
                        returnAddress
                      )
            in
              ()
            end

        fun doCallStatic_ML sizeLoader =
            let
              val entryPoint = getUInt32 ()
              val envOffset = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List (argsCount - 0w1)
              val lastArgOffset = getUInt32 ()
              val lastArgSize = sizeLoader ()
              val returnAddress = (* the address of the destination *)
                  {executable = !CurCb, offset = !cp}
              val destination = getUInt32 () (* this is not used here. *)

              val envBlock = FS.load (frameStack,envOffset)
              val argValues = 
                  map (fn offset => [FS.load (frameStack, offset)]) argOffsets
              val lastArgValue =
                  FS.load_N (frameStack, lastArgOffset, lastArgSize)
              val _ = FS.storeENV (frameStack, !ENV)

              val _ =
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [envBlock]::(argValues @ [lastArgValue]),
                        returnAddress
                      )
            in
              ()
            end

        fun doCallStatic_M () =
            let
              val entryPoint = getUInt32 ()
              val envOffset = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List argsCount
              val argSizeOffsets = getUInt32List argsCount
              val returnAddress = (* the address of the destination *)
                  {executable = !CurCb, offset = !cp}
              val destination = getUInt32 () (* this is not used here. *)

              val envBlock = FS.load (frameStack,envOffset)
              val argSizes =
                  map 
                      (fn offset =>
                          wordOf
                              "Apply"
                              (FS.load (frameStack,offset))
                      )
                      argSizeOffsets
              val argValues = 
                  ListPair.map 
                      (fn (offset,size) => FS.load_N (frameStack, offset,size)) 
                      (argOffsets,argSizes)
              val _ = FS.storeENV (frameStack, !ENV)

              val _ =
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [envBlock]::argValues,
                        returnAddress
                      )
            in
              ()
            end

        fun doTailCallStatic_S sizeLoader =
            let
              val entryPoint = getUInt32 ()
              val envOffset = getUInt32 ()
              val argOffset = getUInt32 ()
              val argSize = sizeLoader ()

              val envBlock = FS.load (frameStack,envOffset)
              val argValues = [FS.load_N (frameStack, argOffset, argSize)]
                  
              val returnAddress =
                  FS.popFrame frameStack (* caller of current *)

              val _ = 
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [envBlock]::argValues,
                        returnAddress
                      )
            in
              ()
            end

        fun doTailCallStatic_ML sizeLoader =
            let
              val entryPoint = getUInt32 ()
              val envOffset = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List (argsCount - 0w1)
              val lastArgOffset = getUInt32 ()
              val lastArgSize = sizeLoader ()

              val envBlock = FS.load (frameStack,envOffset)
              val argValues =
                  map (fn offset => [FS.load (frameStack, offset)]) argOffsets
              val lastArgValue =
                  FS.load_N (frameStack, lastArgOffset, lastArgSize)
              val returnAddress =
                  FS.popFrame frameStack (* caller of current *)

              val _ = 
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [envBlock]::(argValues @ [lastArgValue]),
                        returnAddress
                      )
            in
              ()
            end

        fun doTailCallStatic_M () =
            let
              val entryPoint = getUInt32 ()
              val envOffset = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List argsCount
              val argSizeOffsets = getUInt32List argsCount

              val envBlock = FS.load (frameStack,envOffset)
              val argSizes =
                  map 
                      (fn offset =>
                          wordOf
                              "Apply"
                              (FS.load (frameStack,offset))
                      )
                      argSizeOffsets
              val argValues =
                  ListPair.map 
                      (fn (offset,size) => FS.load_N (frameStack, offset,size)) 
                      (argOffsets,argSizes)
              val returnAddress =
                  FS.popFrame frameStack (* caller of current *)

              val _ = 
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [envBlock]::argValues,
                        returnAddress
                      )
            in
              ()
            end

        fun doRecursiveCallStatic_S sizeLoader =
            let
              val entryPoint = getUInt32 ()
              val argOffset = getUInt32 ()
              val argSize = sizeLoader ()
              val returnAddress = (* the address of the destination *)
                  {executable = !CurCb, offset = !cp}
              val destination = getUInt32 () (* this is not used here. *)

              val argValue = FS.load_N (frameStack, argOffset, argSize)
              val _ = FS.storeENV (frameStack, !ENV)

              val _ =
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [!ENV] :: [argValue],
                        returnAddress
                      )
            in
              ()
            end

        fun doRecursiveCallStatic_M () =
            let
              val entryPoint = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List argsCount
              val argSizeOffsets = getUInt32List argsCount
              val returnAddress = (* the address of the destination *)
                  {executable = !CurCb, offset = !cp}
              val destination = getUInt32 () (* this is not used here. *)

              val argSizes =
                  map 
                      (fn offset =>
                          wordOf
                              "Apply"
                              (FS.load (frameStack,offset))
                      )
                      argSizeOffsets
              val argValues = 
                  ListPair.map
                      (fn (offset,size) => FS.load_N (frameStack, offset, size))
                      (argOffsets,argSizes)
              val _ = FS.storeENV (frameStack, !ENV)

              val _ =
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [!ENV] :: argValues,
                        returnAddress
                      )
            in
              ()
            end

        fun doRecursiveTailCallStatic_S sizeLoader =
            let
              val entryPoint = getUInt32 ()
              val argOffset = getUInt32 ()
              val argSize = sizeLoader ()

              val argValue = FS.load_N (frameStack, argOffset, argSize)
              val returnAddress =
                  FS.popFrame frameStack (* caller of current *)

              val _ = 
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [!ENV] :: [argValue],
                        returnAddress
                      )
            in
              ()
            end


        fun doRecursiveTailCallStatic_M () =
            let
              val entryPoint = getUInt32 ()
              val argsCount = getUInt32 ()
              val argOffsets = getUInt32List argsCount
              val argSizeOffsets = getUInt32List argsCount

              val argSizes =
                  map 
                      (fn offset =>
                          wordOf
                              "Apply"
                              (FS.load (frameStack,offset))
                      )
                      argSizeOffsets
              val argValues = 
                  ListPair.map
                      (fn (offset,size) => FS.load_N (frameStack, offset, size))
                      (argOffsets,argSizes)     
              val returnAddress =
                  FS.popFrame frameStack (* caller of current *)

              val _ = 
                  callFunction
                      (
                        {executable = !CurCb, offset = entryPoint},
                        [!ENV] :: argValues,
                        returnAddress
                      )
            in
              ()
            end

        fun doSelfRecursiveCallStatic_S sizeLoader =
            doRecursiveCallStatic_S sizeLoader

        fun doSelfRecursiveCallStatic_M () =
            doRecursiveCallStatic_M ()

        fun doSelfRecursiveTailCallStatic_S sizeLoader =
            doRecursiveTailCallStatic_S sizeLoader

        fun doSelfRecursiveTailCallStatic_M () =
            doRecursiveTailCallStatic_M ()

        fun doMakeArray sizeLoader =
            let
              val bitmapIndex = getUInt32 ()
              val sizeIndex = getUInt32 ()
              val initialValueIndex = getUInt32 ()
              val initialValueSize = sizeLoader ()
              val destination = getUInt32 ()
                                
              val bitmapValue =
                  wordOf
                      "bitmap in MakeArray"
                      (FS.load (frameStack, bitmapIndex))

              val sizeValue =
                  wordOf
                      "size in MakeArray"
                      (FS.load (frameStack, sizeIndex))

              val blockType =
                  case initialValueSize of
                    0w1 => SingleArrayBlock
                  | 0w2 => DoubleArrayBlock
                  | _ =>
                    raise
                      Control.Bug
                          ("wrong initial value size:"
                           ^ UInt32.toString initialValueSize)

              val blockAddress =
                  H.allocateBlock
                      heap
                      {
                        size = sizeValue,
                        bitmap = bitmapValue,
                        blockType = blockType
                      }

              val elementCount = 
                  case blockType of
                    SingleArrayBlock => sizeValue
                  | DoubleArrayBlock => Word32.>>(sizeValue, 0w1)
              (* NOTE : get the value AFTER block is allcated. *)
              val value =
                  FS.load_N
                      (frameStack, initialValueIndex, initialValueSize)
              val _ =
                  List.tabulate
                      (
                        UInt32ToInt elementCount,
                        fn index => 
                           H.setFields 
                               heap 
                               (
                                 blockAddress,
                                 (IntToUInt32 index) * initialValueSize, value
                               )
                      )
              val _ =
                  FS.store (frameStack, destination, Pointer blockAddress)
            in () end

        fun doReturn sizeLoader =
            let
              val variableOffset = getUInt32 ()
              val variableSize = sizeLoader ()
                                 
              val _ =
                  HS.popHandlersOfCurrentFrame
                      (handlerStack, FS.getCurrentFrame frameStack)

              val value = FS.load_N (frameStack, variableOffset, variableSize)
              val {executable, offset} = FS.popFrame frameStack
              val _ = CurCb := executable
              val _ = cp := offset
              val _ = ENV := FS.loadENV frameStack
              val storeOffset = getUInt32 ()
              val _ = FS.store_N (frameStack, storeOffset, value)
            in () end

        fun doRaiseException exceptionValue =
            if HS.isEmpty handlerStack
            then
              case debuggerOpt of
                NONE => raise RE.Abort
              | SOME {onUncaughtException, ...} =>
                let 
                  val currentCodeRef =
                      {executable = !CurCb, offset = !nextInstOffsetRef}
                in
                  onUncaughtException VM currentCodeRef exceptionValue;
                  raise RE.Abort (* ToDo : ? *)
                end
            else
              let
                val (restoredFrame, exceptionDestination, handlerAddress) =
                    HS.popHandler handlerStack
                val _ = FS.popFramesUntil (frameStack, restoredFrame)
                val _ = ENV := FS.loadENV frameStack
                val _ =
                    FS.store
                        (frameStack, exceptionDestination, exceptionValue)
                val _ = CurCb := #executable handlerAddress
                val _ = cp := #offset handlerAddress
              in () end

        (****************************************)
(*
val _ = TextIO.print "setup initial frame\n"
*)
        val _ =
            callFunction
            (
              {executable = !CurCb, offset = !cp},
              [[!ENV],[Word 0w0]],
              {executable = !CurCb, offset = 0w0}
            )
(*
val _ = TextIO.print "begin\n"
*)
        val _ = traceState VM

        (*
         * execute one instruction pointed by curcb(=current code block)
         * and cp(=offset in code block)
         *)
        fun execinst () =
            let
              val _ =
                  if getSignalFlag ()
                  then raise RE.Interrupted
                  else ()

              val _ = nextInstOpcodeRef := getOpcodeAt (!cp)
              val _ = nextInstOffsetRef := !cp
              val _ = cp := !cp + 0w1

              val _ = traceInst (!cp - 0w1) (!nextInstOpcodeRef)
              val _ = traceState VM
              val _ =
                  if !Control.doProfile
                  then
                    (
                      #inc RC.totalInstructionsCounter ();
                      let
                        val opcodeName =
                            Instructions.opcodeToString (!nextInstOpcodeRef)
                        val C.AccumulationCounter counter =
                            case #find RC.instructionCounterSet opcodeName of
                              SOME counter => counter
                            | NONE =>
                              #addAccumulation
                                  RC.instructionCounterSet opcodeName
                      in #inc counter () end
                    )
                  else ()
(*
              val _ = traceHeap (H.toString heap)
*)
            in
              case !nextInstOpcodeRef of

                I.OPCODE_LoadInt => 
                let
                  val value = getSInt32 ()
                  val destination = getUInt32 ()

                  val _ = FS.store (frameStack, destination, Int value)
                in () end

              | I.OPCODE_LoadWord => 
                let
                  val value = getUInt32 ()
                  val destination = getUInt32 ()

                  val _ = FS.store (frameStack, destination, Word value)
                in () end

              | I.OPCODE_LoadString =>
                let
                  val stringAddress = getUInt32 ()
                  val destination = getUInt32 ()

                  val (byteArray, length) = fetchConstString stringAddress

                  val blockAddress = 
                      SLD.allocateStringBlock heap (byteArray, length)
                  val _ =
                      FS.store (frameStack, destination, Pointer blockAddress)
                in () end

              | I.OPCODE_LoadReal => 
                let
                  val value = getReal64 ()
                  val destination = getUInt32 ()
                  val realValue = Real64ToCellValues value

                  val _ = FS.store_N (frameStack, destination, realValue)

                in () end

              | I.OPCODE_LoadBoxedReal => 
                let
                  val value = getReal64 ()
                  val destination = getUInt32 ()

                  val block = SLD.allocateRealBlock heap value
                  val _ = FS.store (frameStack, destination, Pointer block)

                in () end

              | I.OPCODE_LoadChar => 
                let
                  val value = getUInt32 ()
                  val destination = getUInt32 ()

                  val _ = FS.store (frameStack, destination, Word value)
                in () end

              | I.OPCODE_LoadEmptyBlock => 
                let
                  val destination = getUInt32 ()
                  val blockAddress = H.getEmptyBlockAddress heap
                  val _ = FS.store (frameStack, destination, Pointer blockAddress)
                in () end

              | I.OPCODE_Access_S => doAccess loadSingleSize
              | I.OPCODE_Access_D => doAccess loadDoubleSize
              | I.OPCODE_Access_V => doAccess loadVariantSize

              | I.OPCODE_AccessEnv_S => doAccessEnv loadSingleSize
              | I.OPCODE_AccessEnv_D => doAccessEnv loadDoubleSize
              | I.OPCODE_AccessEnv_V => doAccessEnv loadVariantSize

              | I.OPCODE_AccessEnvIndirect_S =>
                doAccessEnvIndirect loadSingleSize
              | I.OPCODE_AccessEnvIndirect_D =>
                doAccessEnvIndirect loadDoubleSize
              | I.OPCODE_AccessEnvIndirect_V =>
                doAccessEnvIndirect loadVariantSize

              | I.OPCODE_AccessNestedEnv_S => doAccessNestedEnv loadSingleSize
              | I.OPCODE_AccessNestedEnv_D => doAccessNestedEnv loadDoubleSize
              | I.OPCODE_AccessNestedEnv_V => doAccessNestedEnv loadVariantSize

              | I.OPCODE_AccessNestedEnvIndirect_S =>
                doAccessNestedEnvIndirect loadSingleSize
              | I.OPCODE_AccessNestedEnvIndirect_D =>
                doAccessNestedEnvIndirect loadDoubleSize
              | I.OPCODE_AccessNestedEnvIndirect_V =>
                doAccessNestedEnvIndirect loadVariantSize

              | I.OPCODE_GetField_S => doGetField loadSingleSize
              | I.OPCODE_GetField_D => doGetField loadDoubleSize
              | I.OPCODE_GetField_V => doGetField loadVariantSize
                  
              | I.OPCODE_GetFieldIndirect_S =>
                doGetFieldIndirect loadSingleSize
              | I.OPCODE_GetFieldIndirect_D =>
                doGetFieldIndirect loadDoubleSize
              | I.OPCODE_GetFieldIndirect_V =>
                doGetFieldIndirect loadVariantSize

              | I.OPCODE_GetNestedFieldIndirect_S =>
                doGetNestedFieldIndirect loadSingleSize
              | I.OPCODE_GetNestedFieldIndirect_D =>
                doGetNestedFieldIndirect loadDoubleSize
              | I.OPCODE_GetNestedFieldIndirect_V =>
                doGetNestedFieldIndirect loadVariantSize

              | I.OPCODE_SetField_S => doSetField loadSingleSize
              | I.OPCODE_SetField_D => doSetField loadDoubleSize
              | I.OPCODE_SetField_V => doSetField loadVariantSize

              | I.OPCODE_SetFieldIndirect_S =>
                doSetFieldIndirect loadSingleSize
              | I.OPCODE_SetFieldIndirect_D =>
                doSetFieldIndirect loadDoubleSize
              | I.OPCODE_SetFieldIndirect_V =>
                doSetFieldIndirect loadVariantSize

              | I.OPCODE_SetNestedFieldIndirect_S =>
                doSetNestedFieldIndirect loadSingleSize
              | I.OPCODE_SetNestedFieldIndirect_D =>
                doSetNestedFieldIndirect loadDoubleSize
              | I.OPCODE_SetNestedFieldIndirect_V =>
                doSetNestedFieldIndirect loadVariantSize

              | I.OPCODE_CopyBlock =>
                let
                  val blockOffset = getUInt32 ()
                  val destination = getUInt32 ()

                  val blockAddress =
                      pointerOf
                          "block in CopyBlock"
                          (FS.load (frameStack, blockOffset))
                  val newBlockAddress =
		      H.allocateBlock
		          heap
		          {
		           size = H.getSize heap blockAddress,
		           bitmap = H.getBitmap heap blockAddress,
		           blockType = H.getBlockType heap blockAddress
		          }

                  val blockAddress =
                      pointerOf
                          "block in CopyBlock"
                          (FS.load (frameStack, blockOffset))

                  val _ = 
                      H.copyBlock heap (blockAddress,newBlockAddress)
                  val _ =
                      FS.store
                          (frameStack, destination, Pointer newBlockAddress)
                in () end

(*
              | I.OPCODE_CopyAndUpdateField =>
                let
                  val fieldIndex = getUInt32 ()
                  val blockIndex = getUInt32 ()
		  val valueIndex = getUInt32 ()
                  val destination = getUInt32 ()

		  val newBlockAddress =
		      copyAndUpdateBlock (blockIndex, fieldIndex, valueIndex)
                  val _ =
                      FS.store
                          (frameStack, destination, Pointer newBlockAddress)
                in () end
		      
              | I.OPCODE_CopyAndUpdateFieldIndirect =>
                let
                  val fieldVariableIndex = getUInt32 ()
                  val blockIndex = getUInt32 ()
		  val valueIndex = getUInt32 ()
                  val destination = getUInt32 ()

                  (* ToDo : index variable is an int, but should be a word. *)
                  val fieldIndex =
                      SInt32ToUInt32
                          (intOf
                               "fieldIndex of CopyAndUpdateFieldIndirect"
                               (FS.load (frameStack, fieldVariableIndex)))

		  val newBlockAddress =
		      copyAndUpdateBlock (blockIndex, fieldIndex, valueIndex)
                  val _ =
                      FS.store
                          (frameStack, destination, Pointer newBlockAddress)
		in () end
*)
              | I.OPCODE_GetGlobal_S => doGetGlobal loadSingleSize
              | I.OPCODE_GetGlobal_D => doGetGlobal loadDoubleSize

              | I.OPCODE_SetGlobal_S => doSetGlobal loadSingleSize
              | I.OPCODE_SetGlobal_D => doSetGlobal loadDoubleSize

              | I.OPCODE_InitGlobalArrayUnboxed => 
                doInitGlobalArray {bitmap=0w0, blockType = SingleArrayBlock}
              | I.OPCODE_InitGlobalArrayBoxed => 
                doInitGlobalArray {bitmap=0w1, blockType = SingleArrayBlock}
              | I.OPCODE_InitGlobalArrayDouble => 
                doInitGlobalArray {bitmap=0w0, blockType = DoubleArrayBlock}

              | I.OPCODE_GetEnv =>
                let
                  val destination = getUInt32 ()

                  val _ = FS.store (frameStack, destination, !ENV)
                in () end

              | I.OPCODE_CallPrim =>
                (let
                   val primitiveIndex = getUInt32 ()
                   val argsCount = getUInt32 ()
                   val argIndexes = getUInt32List argsCount
                   val destination = getUInt32 ()
                  
                   val primitive =
                       case
                         IEnv.find (primitives, UInt32ToInt primitiveIndex)
                        of
                         SOME primitive => primitive
                       | NONE => 
                         raise
                           RE.InvalidCode
                               ("BUG: unknown primitive index"
                                ^ UInt32.toString primitiveIndex)

                   val argValues =
                       ListPair.foldl 
                           (fn (index, size, L) =>
                               L @ (FS.load_N (frameStack, index, size)))
                           []
                           (argIndexes, #argSizes primitive)

                   val resultValue =
                       (#function primitive) VM heap argValues
                       handle RE.UnexpectedPrimitiveArguments operation =>
                              raiseInvalidArguments
                                  ("unexpected arguments to " ^ operation)
                                  argValues

                   val _ = FS.store_N (frameStack, destination, resultValue)
                 in () end
                   handle PrimitiveException exceptionValue =>
                          doRaiseException exceptionValue)

              (**************************************************)
              (* instructions implementing primitive operators *)

              | I.OPCODE_Equal =>
                let
                  fun equal ([Int left], [Int right]) = left = right 
                    | equal ([Word left], [Word right]) = left = right
(*
                    | equal ([Char left], [Char right]) = left = right
*)
                    | equal ([Pointer left], [Pointer right]) =
                      (case
                         (H.getBlockType heap left, H.getBlockType heap right)
                        of
                         (RecordBlock, RecordBlock) =>
                         (H.getSize heap left = H.getSize heap right)
                         andalso
                         (List.all
                          (fn index =>
                              equal
                              (
                                [H.getField heap (left, (IntToUInt32 index))],
                                [H.getField heap (right, (IntToUInt32 index))]
                              ))
                          (List.tabulate
                           (UInt32ToInt(H.getSize heap left), fn x => x)))
                       | (SingleArrayBlock, SingleArrayBlock) =>
                         RM.== (left, right)
                       | (DoubleArrayBlock, DoubleArrayBlock) =>
                         RM.== (left, right)
                       | (StringBlock, StringBlock) =>
                         let
                           val leftString =
                               UInt8ArrayToString
                                   (SLD.expandStringBlock heap (Pointer left))
                           val rightString =
                               UInt8ArrayToString
                                   (SLD.expandStringBlock heap (Pointer right))
                         in
                           leftString = rightString
                         end)
                in
                  doPredicate2 "equal" (0w1,0w1) equal
                end

              | I.OPCODE_AddInt => doIntPrimitive2 "addInt" (op +)
              | I.OPCODE_AddReal => doRealPrimitive2 "addReal" (op +)
              | I.OPCODE_AddWord => doWordPrimitive2 "addWord" (op +)
              | I.OPCODE_AddByte => doBytePrimitive2 "addByte" (op +)
              | I.OPCODE_SubInt => doIntPrimitive2 "subInt" (op -)
              | I.OPCODE_SubReal => doRealPrimitive2 "subReal" (op -)
              | I.OPCODE_SubWord => doWordPrimitive2 "subWord" (op -)
              | I.OPCODE_SubByte => doBytePrimitive2 "subByte" (op -)
              | I.OPCODE_MulInt => doIntPrimitive2 "mulInt" (op * )
              | I.OPCODE_MulReal => doRealPrimitive2 "mulReal" (op * )
              | I.OPCODE_MulWord => doWordPrimitive2 "mulWord" (op * )
              | I.OPCODE_MulByte => doBytePrimitive2 "mulByte" (op * )
              | I.OPCODE_DivInt => doIntPrimitive2 "divInt" (op div)
              | I.OPCODE_DivWord => doWordPrimitive2 "divWord" (op div)
              | I.OPCODE_DivByte => doBytePrimitive2 "divByte" (op div)
              | I.OPCODE_DivReal => doRealPrimitive2 "divReal" (op /)
              | I.OPCODE_ModInt => doIntPrimitive2 "modInt" (op mod)
              | I.OPCODE_ModWord => doWordPrimitive2 "modWord" (op mod)
              | I.OPCODE_ModByte => doBytePrimitive2 "modByte" (op mod)
              | I.OPCODE_QuotInt => doIntPrimitive2 "quotInt" SInt32.quot
              | I.OPCODE_RemInt => doIntPrimitive2 "remInt" SInt32.rem
              | I.OPCODE_NegInt => doIntPrimitive1 "negInt" ~
              | I.OPCODE_NegReal => doRealPrimitive1 "negReal" ~
              | I.OPCODE_AbsInt => doIntPrimitive1 "absInt" abs
              | I.OPCODE_AbsReal => doRealPrimitive1 "absReal" abs

              | I.OPCODE_Word_toIntX =>
                doPrimitive1
                "Word_toIntx"
                0w1
                (fn ([Word arg]) => [Int(UInt32.toLargeIntX arg)])
              | I.OPCODE_Word_fromInt =>
                doPrimitive1
                "Word_fromInt"
                0w1
                (fn ([Int arg]) => [Word(UInt32.fromLargeInt arg)])
              | I.OPCODE_Word_andb => doWordPrimitive2 "Word_andb" UInt32.andb
              | I.OPCODE_Word_orb => doWordPrimitive2 "Word_orb" UInt32.orb
              | I.OPCODE_Word_xorb => doWordPrimitive2 "Word_xorb" UInt32.xorb
              | I.OPCODE_Word_notb => doWordPrimitive1 "Word_notb" UInt32.notb
              | I.OPCODE_Word_leftShift =>
                doWordPrimitive2
                    "Word_leftShift"
                    (fn (left, right) => UInt32.<<(left, UInt32ToWord right))
              | I.OPCODE_Word_logicalRightShift =>
                doWordPrimitive2
                    "Word_logicalRightShift"
                    (fn (left, right) => UInt32.>>(left, UInt32ToWord right))
              | I.OPCODE_Word_arithmeticRightShift =>
                doWordPrimitive2
                    "Word_arithmeticRightShift =>" 
                    (fn (left, right) => UInt32.~>>(left, UInt32ToWord right))

              | I.OPCODE_LtInt => doIntPredicate2 "ltInt" (op <)
              | I.OPCODE_LtReal => doRealPredicate2 "ltReal" (op <)
              | I.OPCODE_LtWord => doWordPredicate2 "ltWord" (op <)
              | I.OPCODE_LtByte => doBytePredicate2 "ltByte" (op <)
              | I.OPCODE_LtChar => doCharPredicate2 "ltChar" (op <)
              | I.OPCODE_LtString => doStringPredicate2 "ltString" (op <)

              | I.OPCODE_GtInt => doIntPredicate2 "gtInt" (op >)
              | I.OPCODE_GtReal => doRealPredicate2 "gtReal" (op >)
              | I.OPCODE_GtWord => doWordPredicate2 "gtWord" (op >)
              | I.OPCODE_GtByte => doBytePredicate2 "gtByte" (op >)
              | I.OPCODE_GtChar => doCharPredicate2 "gtChar" (op >)
              | I.OPCODE_GtString => doStringPredicate2 "gtString" (op >)

              | I.OPCODE_LteqInt => doIntPredicate2 "lteqInt" (op <=)
              | I.OPCODE_LteqReal => doRealPredicate2 "lteqReal" (op <=)
              | I.OPCODE_LteqWord => doWordPredicate2 "lteqWord" (op <=)
              | I.OPCODE_LteqByte => doBytePredicate2 "lteqByte" (op <=)
              | I.OPCODE_LteqChar => doCharPredicate2 "lteqChar" (op <=)
              | I.OPCODE_LteqString => doStringPredicate2 "lteqString" (op <=)

              | I.OPCODE_GteqInt => doIntPredicate2 "gteqInt" (op >=)
              | I.OPCODE_GteqReal => doRealPredicate2 "gteqReal" (op >=)
              | I.OPCODE_GteqWord => doWordPredicate2 "gteqWord" (op >=)
              | I.OPCODE_GteqByte => doBytePredicate2 "gteqByte" (op >=)
              | I.OPCODE_GteqChar => doCharPredicate2 "gteqChar" (op >=)
              | I.OPCODE_GteqString => doStringPredicate2 "gteqString" (op >=)

              | I.OPCODE_Array_length =>
                let
                  val blockOffset = getUInt32 ()
                  val destination = getUInt32 ()

                  val blockAddress =
                      pointerOf
                          "block in Array_length"
                          (FS.load (frameStack, blockOffset))
                  val blockSize = H.getSize heap blockAddress
                  val blockType = H.getBlockType heap blockAddress
                  val fieldSize =
                      case blockType of
                        SingleArrayBlock => 0w1
                      | DoubleArrayBlock => 0w2
                      | RecordBlock =>
                        if 0w0 = blockSize
                        then 0w1 (* empty array *)
                        else raise Control.Bug "non empty RecordBlock array."
                      | _ =>
                        raise Control.Bug "invalid block type in Array_length"

                  val blockLength =
                      UInt32ToSInt32(blockSize div fieldSize)
                  val _ = FS.store (frameStack, destination, Int blockLength)
                in () end
                
              | I.OPCODE_CurrentIP =>
                let
                  fun getCurrentIP [_] =
                      let
                        val currentExecutable =
                            FS.getCurrentExecutable frameStack
                        val executableHandle =
                            SLD.addExecutable currentExecutable
                        val tuple = 
                            SLD.tupleElementsToValue
                                heap
                                0w0
                                [
                                  Word executableHandle,
                                  Word (!nextInstOffsetRef)
                                ]
                      in
                        [tuple]
                      end
                in
                  doPrimitive1 "CurrentIP" 0w1 getCurrentIP
                end
              | I.OPCODE_StackTrace =>
                let
                  fun getStackTrace [_] = 
                      let
                        val frames = FS.getFrames frameStack
                        val codeRefs = map FS.getReturnAddressOfFrame frames
                        fun makeIPTuple {executable, offset} =
                            let
                              val executableHandle =
                                  SLD.addExecutable executable
                              val tuple = 
                                  SLD.tupleElementsToValue
                                      heap
                                      0w0
                                      [Word executableHandle, Word offset]
                            in
                              tuple
                            end
                        val list = SLD.listToValue heap makeIPTuple codeRefs
                      in
                        [list]
                      end
                in
                  doPrimitive1 "StackTrace" 0w1 getStackTrace
                end

              | I.OPCODE_AddInt_Const_1 => doIntPrimitiveConst2_1 "addIntConst1" (op + )
              | I.OPCODE_AddInt_Const_2 => doIntPrimitiveConst2_2 "addIntConst2" (op + )
              | I.OPCODE_AddWord_Const_1 => doWordPrimitiveConst2_1 "addWordConst1" (op + )
              | I.OPCODE_AddWord_Const_2 => doWordPrimitiveConst2_2 "addWordConst2" (op + )
              | I.OPCODE_AddReal_Const_1 => doRealPrimitiveConst2_1 "addRealConst1" (op + )
              | I.OPCODE_AddReal_Const_2 => doRealPrimitiveConst2_2 "addRealConst2" (op + )
              | I.OPCODE_AddByte_Const_1 => doBytePrimitiveConst2_1 "addByteConst1" (op + )
              | I.OPCODE_AddByte_Const_2 => doBytePrimitiveConst2_2 "addByteConst2" (op + )

              | I.OPCODE_SubInt_Const_1 => doIntPrimitiveConst2_1 "subIntConst1" (op - )
              | I.OPCODE_SubInt_Const_2 => doIntPrimitiveConst2_2 "subIntConst2" (op - )
              | I.OPCODE_SubWord_Const_1 => doWordPrimitiveConst2_1 "subWordConst1" (op - )
              | I.OPCODE_SubWord_Const_2 => doWordPrimitiveConst2_2 "subWordConst2" (op - )
              | I.OPCODE_SubReal_Const_1 => doRealPrimitiveConst2_1 "subRealConst1" (op - )
              | I.OPCODE_SubReal_Const_2 => doRealPrimitiveConst2_2 "subRealConst2" (op - )
              | I.OPCODE_SubByte_Const_1 => doBytePrimitiveConst2_1 "subByteConst1" (op - )
              | I.OPCODE_SubByte_Const_2 => doBytePrimitiveConst2_2 "subByteConst2" (op - )

              | I.OPCODE_MulInt_Const_1 => doIntPrimitiveConst2_1 "mulIntConst1" (op * )
              | I.OPCODE_MulInt_Const_2 => doIntPrimitiveConst2_2 "mulIntConst2" (op * )
              | I.OPCODE_MulWord_Const_1 => doWordPrimitiveConst2_1 "mulWordConst1" (op * )
              | I.OPCODE_MulWord_Const_2 => doWordPrimitiveConst2_2 "mulWordConst2" (op * )
              | I.OPCODE_MulReal_Const_1 => doRealPrimitiveConst2_1 "mulRealConst1" (op * )
              | I.OPCODE_MulReal_Const_2 => doRealPrimitiveConst2_2 "mulRealConst2" (op * )
              | I.OPCODE_MulByte_Const_1 => doBytePrimitiveConst2_1 "mulByteConst1" (op * )
              | I.OPCODE_MulByte_Const_2 => doBytePrimitiveConst2_2 "mulByteConst2" (op * )

              | I.OPCODE_DivInt_Const_1 => doIntPrimitiveConst2_1 "divIntConst1" (op div )
              | I.OPCODE_DivInt_Const_2 => doIntPrimitiveConst2_2 "divIntConst2" (op div )
              | I.OPCODE_DivWord_Const_1 => doWordPrimitiveConst2_1 "divWordConst1" (op div )
              | I.OPCODE_DivWord_Const_2 => doWordPrimitiveConst2_2 "divWordConst2" (op div )
              | I.OPCODE_DivReal_Const_1 => doRealPrimitiveConst2_1 "divRealConst1" (op / )
              | I.OPCODE_DivReal_Const_2 => doRealPrimitiveConst2_2 "divRealConst2" (op / )
              | I.OPCODE_DivByte_Const_1 => doBytePrimitiveConst2_1 "divByteConst1" (op div )
              | I.OPCODE_DivByte_Const_2 => doBytePrimitiveConst2_2 "divByteConst2" (op div )

              | I.OPCODE_ModInt_Const_1 => doIntPrimitiveConst2_1 "modIntConst1" (op mod )
              | I.OPCODE_ModInt_Const_2 => doIntPrimitiveConst2_2 "modIntConst2" (op mod )
              | I.OPCODE_ModWord_Const_1 => doWordPrimitiveConst2_1 "modWordConst1" (op mod )
              | I.OPCODE_ModWord_Const_2 => doWordPrimitiveConst2_2 "modWordConst2" (op mod )
              | I.OPCODE_ModByte_Const_1 => doBytePrimitiveConst2_1 "modByteConst1" (op mod )
              | I.OPCODE_ModByte_Const_2 => doBytePrimitiveConst2_2 "modByteConst2" (op mod )

              | I.OPCODE_QuotInt_Const_1 => doIntPrimitiveConst2_1 "quotIntConst1" (SInt32.quot )
              | I.OPCODE_QuotInt_Const_2 => doIntPrimitiveConst2_2 "quotIntConst2" (SInt32.quot )

              | I.OPCODE_RemInt_Const_1 => doIntPrimitiveConst2_1 "remIntConst1" (SInt32.rem )
              | I.OPCODE_RemInt_Const_2 => doIntPrimitiveConst2_2 "remIntConst2" (SInt32.rem )

              | I.OPCODE_Word_andb_Const_1 => doWordPrimitiveConst2_1 "Word_andb_Const_1" (UInt32.andb)
              | I.OPCODE_Word_andb_Const_2 => doWordPrimitiveConst2_2 "Word_andb_Const_2" (UInt32.andb)

              | I.OPCODE_Word_orb_Const_1 => doWordPrimitiveConst2_1 "Word_orb_Const_1" (UInt32.orb)
              | I.OPCODE_Word_orb_Const_2 => doWordPrimitiveConst2_2 "Word_orb_Const_2" (UInt32.orb)

              | I.OPCODE_Word_xorb_Const_1 => doWordPrimitiveConst2_1 "Word_xorb_Const_1" (UInt32.xorb)
              | I.OPCODE_Word_xorb_Const_2 => doWordPrimitiveConst2_2 "Word_xorb_Const_2" (UInt32.xorb)

              | I.OPCODE_Word_leftShift_Const_1 => 
                doWordPrimitiveConst2_1 
                    "Word_leftShift_Const_1" 
                    (fn (left, right) => UInt32.<<(left, UInt32ToWord right))
              | I.OPCODE_Word_leftShift_Const_2 => 
                doWordPrimitiveConst2_2 
                    "Word_leftShift_Const_2" 
                    (fn (left, right) => UInt32.<<(left, UInt32ToWord right))

              | I.OPCODE_Word_logicalRightShift_Const_1 => 
                doWordPrimitiveConst2_1 
                    "Word_logicalRightShift_Const_1" 
                    (fn (left, right) => UInt32.>>(left, UInt32ToWord right))
              | I.OPCODE_Word_logicalRightShift_Const_2 => 
                doWordPrimitiveConst2_2 
                    "Word_logicalRightShift_Const_2" 
                    (fn (left, right) => UInt32.>>(left, UInt32ToWord right))

              | I.OPCODE_Word_arithmeticRightShift_Const_1 => 
                doWordPrimitiveConst2_1 
                    "Word_arithmeticRightShift_Const_1" 
                    (fn (left, right) => UInt32.~>>(left, UInt32ToWord right))
              | I.OPCODE_Word_arithmeticRightShift_Const_2 => 
                doWordPrimitiveConst2_2 
                    "Word_arithmeticRightShift_Const_2" 
                    (fn (left, right) => UInt32.~>>(left, UInt32ToWord right))

              (**************************************************)

              | I.OPCODE_ForeignApply =>
                let
                  val closureIndex = getUInt32 ()
                  val argsCount = getUInt32 ()
                  val argIndexes = getUInt32List argsCount
                  val destination = getUInt32 ()

                  val argValues =
                      map
                          (fn offset => FS.load (frameStack, offset))
                          argIndexes
val _ =
    TextIO.print ("#args of FF apply = " ^ UInt32.toString(argsCount) ^ "\n")
val _ =
    TextIO.print ("arguments:\n")
val _ =
    app
        (fn value => TextIO.print ("   " ^ cellValueToString value ^ "\n"))
        argValues
                 in
                  FS.store (frameStack, destination, Word 0w0)
                 end

              | I.OPCODE_Apply_S => doApply_S loadSingleSize
              | I.OPCODE_Apply_D => doApply_S loadDoubleSize
              | I.OPCODE_Apply_V => doApply_S loadVariantSize
              | I.OPCODE_Apply_ML_S => doApply_ML loadSingleSize
              | I.OPCODE_Apply_ML_D => doApply_ML loadDoubleSize
              | I.OPCODE_Apply_ML_V => doApply_ML loadVariantSize
              | I.OPCODE_Apply_M => doApply_M ()

              | I.OPCODE_TailApply_S => doTailApply_S loadSingleSize
              | I.OPCODE_TailApply_D => doTailApply_S loadDoubleSize
              | I.OPCODE_TailApply_V => doTailApply_S loadVariantSize
              | I.OPCODE_TailApply_ML_S => doTailApply_ML loadSingleSize
              | I.OPCODE_TailApply_ML_D => doTailApply_ML loadDoubleSize
              | I.OPCODE_TailApply_ML_V => doTailApply_ML loadVariantSize
              | I.OPCODE_TailApply_M => doTailApply_M ()

              | I.OPCODE_CallStatic_S => doCallStatic_S loadSingleSize
              | I.OPCODE_CallStatic_D => doCallStatic_S loadDoubleSize
              | I.OPCODE_CallStatic_V => doCallStatic_S loadVariantSize
              | I.OPCODE_CallStatic_ML_S => doCallStatic_ML loadSingleSize
              | I.OPCODE_CallStatic_ML_D => doCallStatic_ML loadDoubleSize
              | I.OPCODE_CallStatic_ML_V => doCallStatic_ML loadVariantSize
              | I.OPCODE_CallStatic_M => doCallStatic_M ()

              | I.OPCODE_TailCallStatic_S => doTailCallStatic_S loadSingleSize
              | I.OPCODE_TailCallStatic_D => doTailCallStatic_S loadDoubleSize
              | I.OPCODE_TailCallStatic_V => doTailCallStatic_S loadVariantSize
              | I.OPCODE_TailCallStatic_ML_S => doTailCallStatic_ML loadSingleSize
              | I.OPCODE_TailCallStatic_ML_D => doTailCallStatic_ML loadDoubleSize
              | I.OPCODE_TailCallStatic_ML_V => doTailCallStatic_ML loadVariantSize
              | I.OPCODE_TailCallStatic_M => doTailCallStatic_M ()

              | I.OPCODE_RecursiveCallStatic_S =>
                doRecursiveCallStatic_S loadSingleSize
              | I.OPCODE_RecursiveCallStatic_D =>
                doRecursiveCallStatic_S loadDoubleSize
              | I.OPCODE_RecursiveCallStatic_V =>
                doRecursiveCallStatic_S loadVariantSize
              | I.OPCODE_RecursiveCallStatic_M =>
                doRecursiveCallStatic_M ()

              | I.OPCODE_RecursiveTailCallStatic_S =>
                doRecursiveTailCallStatic_S loadSingleSize
              | I.OPCODE_RecursiveTailCallStatic_D =>
                doRecursiveTailCallStatic_S loadDoubleSize
              | I.OPCODE_RecursiveTailCallStatic_V =>
                doRecursiveTailCallStatic_S loadVariantSize
              | I.OPCODE_RecursiveTailCallStatic_M =>
                doRecursiveTailCallStatic_M ()

              | I.OPCODE_SelfRecursiveCallStatic_S =>
                doSelfRecursiveCallStatic_S loadSingleSize
              | I.OPCODE_SelfRecursiveCallStatic_D =>
                doSelfRecursiveCallStatic_S loadDoubleSize
              | I.OPCODE_SelfRecursiveCallStatic_V =>
                doSelfRecursiveCallStatic_S loadVariantSize
              | I.OPCODE_SelfRecursiveCallStatic_M =>
                doSelfRecursiveCallStatic_M ()

              | I.OPCODE_SelfRecursiveTailCallStatic_S =>
                doSelfRecursiveTailCallStatic_S loadSingleSize
              | I.OPCODE_SelfRecursiveTailCallStatic_D =>
                doSelfRecursiveTailCallStatic_S loadDoubleSize
              | I.OPCODE_SelfRecursiveTailCallStatic_V =>
                doSelfRecursiveTailCallStatic_S loadVariantSize
              | I.OPCODE_SelfRecursiveTailCallStatic_M =>
                doSelfRecursiveTailCallStatic_M ()

              | I.OPCODE_MakeBlock =>
                let
                  val bitmapIndex = getUInt32 ()
                  val sizeIndex = getUInt32 ()
                  val fieldsCount = getUInt32 ()
                  val fieldIndexes = getUInt32List fieldsCount
                  val fieldSizeIndexes = getUInt32List fieldsCount
                  val destination = getUInt32 ()

                  val bitmapValue =
                      wordOf
                          "bitmap in MakeBlock"
                          (FS.load (frameStack, bitmapIndex))
                  val sizeValue =
                      wordOf
                          "size in MakeBlock"
                          (FS.load (frameStack, sizeIndex))
                  val blockAddress =
                      H.allocateBlock
                          heap
                          {
                            size = sizeValue,
                            bitmap = bitmapValue,
                            blockType = RecordBlock
                          }
(*
                  val _ = print VM ("\nbitmap=" ^ (UInt32.toString bitmapValue))
                  val _ = print VM ("\nsize=" ^ (UInt32.toString sizeValue))
*)
                  fun storeField (fieldIndex, fieldSizeIndex, offset) =
                      let
                        val fieldSize =
                            wordOf
                                "field size in MakeBlock"
                                (FS.load (frameStack, fieldSizeIndex))
                      in
                        if fieldSize = 0w0 
                        then offset
                        else
                          let
                            val fieldValue =
                                FS.load_N (frameStack,fieldIndex,fieldSize)
                            val _ =
                                H.setFields
                                    heap (blockAddress, offset, fieldValue)
                          in
                            offset + fieldSize
                          end
                      end
                  val _ = 
                      ListPair.foldl
                          storeField 0w0 (fieldIndexes, fieldSizeIndexes)
                  val _ =
                      FS.store (frameStack, destination, Pointer blockAddress)
                in () end

              | I.OPCODE_MakeBlockOfSingleValues =>
                let
                  val bitmapIndex = getUInt32 ()
                  val fieldsCount = getUInt32 ()
                  val fieldIndexes = getUInt32List fieldsCount
                  val destination = getUInt32 ()

                  val bitmapValue =
                      wordOf
                          "bitmap in MakeBlock"
                          (FS.load (frameStack, bitmapIndex))
                  val blockAddress =
                      H.allocateBlock
                          heap
                          {
                            size = fieldsCount,
                            bitmap = bitmapValue,
                            blockType = RecordBlock
                          }
                  val fieldValues =
                      map
                          (fn index => FS.load (frameStack, index))
                          fieldIndexes
                  val _ = 
                      if fieldsCount > 0w0
                      then
                        H.setFields heap (blockAddress, 0w0, fieldValues)
                      else ()
                  val _ =
                      FS.store (frameStack, destination, Pointer blockAddress)
                in () end

              | I.OPCODE_MakeArray_S => doMakeArray loadSingleSize
              | I.OPCODE_MakeArray_D => doMakeArray loadDoubleSize
              | I.OPCODE_MakeArray_V => doMakeArray loadVariantSize

              | I.OPCODE_MakeClosure =>
                let
                  val entryPoint = getUInt32 ()
                  val ENVIndex = getUInt32 ()
                  val destination = getUInt32 ()

                  val closureAddress = allocateClosure (entryPoint, ENVIndex)
                  val _ =
                      FS.store(frameStack, destination, Pointer closureAddress)
                in () end

              | I.OPCODE_Raise =>
                let
                  val exceptionIndex = getUInt32 ()
                  val exceptionValue = FS.load (frameStack, exceptionIndex)

                in doRaiseException exceptionValue end

              | I.OPCODE_PushHandler =>
                let
                  val handler = getUInt32 ()
                  val exceptionIndex = getUInt32 ()

                  val currentFrame = FS.getCurrentFrame frameStack
                  val handlerAddress = {executable = !CurCb, offset = handler}
                  val _ =
                      HS.pushHandler
                      (
                        handlerStack,
                        currentFrame,
                        exceptionIndex,
                        handlerAddress
                      )
                in () end

              | I.OPCODE_PopHandler =>
                let val _ = HS.popHandler handlerStack in () end

              | I.OPCODE_SwitchInt =>
                doSwitch (intOf "object of SwitchInt", getSInt32)
              | I.OPCODE_SwitchWord =>
                doSwitch (wordOf "object of SwitchWord" , getUInt32)
              | I.OPCODE_SwitchChar =>
                doSwitch (charOf "object of SwitchChar", getUInt32)
              | I.OPCODE_SwitchString =>
                let
                  fun getObjectString value =
                      UInt8ArrayToString (SLD.expandStringBlock heap value)
                  fun getTagString () =
                      let
                        val stringAddress = getUInt32 ()
                      in UInt8ArrayToString(fetchConstString stringAddress) end
                in doSwitch (getObjectString, getTagString)
                end

              | I.OPCODE_Jump =>
                let val destination = getUInt32 () in cp := destination end

              | I.OPCODE_Exit => raise Exit

              | I.OPCODE_Return_S => doReturn loadSingleSize
              | I.OPCODE_Return_D => doReturn loadDoubleSize
              | I.OPCODE_Return_V => doReturn loadVariantSize
              | I.OPCODE_FFIVal =>
                let
                  val funNameIndex = getUInt32 ()
                  val libNameIndex = getUInt32 ()
                  val destination = getUInt32 ()

                  fun getString index =
                      UInt8ArrayToString
                          (SLD.expandStringBlock
                               heap (FS.load (frameStack, index)))
                  val funName = getString funNameIndex
                  val libName = getString libNameIndex

                  val _ =
                      TextIO.print
                          ("FFIVAL instruction: "
                           ^ funName ^ " of " ^ libName ^ "\n")
                  (* ToDo : this is dummy value. *)
                  val blockAddress =
                      H.allocateBlock
                          heap
                          {size = 0w1, bitmap = 0w0, blockType = RecordBlock}
                  val _ =
                      FS.store (frameStack, destination, Pointer blockAddress)
                in () end

              | I.OPCODE_DebuggerBreak =>
                (case debuggerOpt of
                   NONE => ()
                 | SOME {onBreakPointHit, ...} =>
                   let 
                     val currentCodeRef =
                         {executable = !CurCb, offset = !nextInstOffsetRef}
                     val (originalOpcode, keepBreakPoint) =
                         onBreakPointHit VM currentCodeRef
                   in
                     (* resume *)
                     setOpcodeAt (!nextInstOffsetRef) originalOpcode;
                     cp := !nextInstOffsetRef;
                     execinst ();

                     if keepBreakPoint
                     then (* this break point should be kept. *)
                       setOpcodeAt (!nextInstOffsetRef) I.OPCODE_DebuggerBreak
                     else () (* this break point has been deleted. *)
                   end)
              | _ =>
                raise
                  RE.InvalidCode
                      ("Sorry ! " ^
                       Instructions.opcodeToString (!nextInstOpcodeRef) ^
                       " is not implemented yet.")
            end

        fun loop () = (execinst (); loop ())

        val _ = setSignalFlag false
        fun signalHandler signal = setSignalFlag true

        val _ = CurCb := executable (* ToDo : why update here ??? *)

      in
        (SU.doWithAction [SU.SIGINT] (SU.Handle signalHandler) loop ())
        handle Exit => traceState VM
             | exn =>
               (
                 printError VM "Runtime error:\n";
                 printError
                     VM
                     ("instruction:" ^ 
                      (Instructions.opcodeToString (!nextInstOpcodeRef))
                      ^ "\n");
                 printError VM "backTrace:\n";
                 app
                     (fn history => printError VM ("  " ^ history ^ "\n"))
                     (getStackTraceStrings VM);
                 printError VM "\n";
                 case debuggerOpt of
                   NONE => ()
                 | SOME{onRuntimeError, ...} =>
                   let 
                     val currentCodeRef =
                         {executable = !CurCb, offset = !nextInstOffsetRef}
                   in
                     onRuntimeError VM currentCodeRef exn
                   end;
                 case exn of
                   RE.Abort => raise RE.Abort
                 | RE.Interrupted => raise RE.Interrupted
                 | H.Error message => 
                   (
                     printError VM ("Heap: " ^ message ^ "\n");
                     app
                         (fn history => printError VM (history ^ "\n"))
                         (SMLofNJ.exnHistory exn);
                     raise RE.Error message
                   )
                 | _ =>
                   (
                     printError VM (exnMessage exn ^ "\n");
                     app
                         (fn history => printError VM (history ^ "\n"))
                         (SMLofNJ.exnHistory exn);
                     raise exn
                   )
              )
      end

  fun getName (VMStatus {name, ...}) = name
  fun getArguments (VMStatus {arguments, ...}) = arguments

  (***************************************************************************)

end
