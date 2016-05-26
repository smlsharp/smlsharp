(**
 * LLVM binding
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure LLVM =
struct

  val _ = (_import "sml_llvm_initialize" : () -> ()) ()

  val ASMEXT = "ll"
  val OBJEXT = "bc"

  type LLVMBool = int
  val True = 1 : LLVMBool
  val False = 0 : LLVMBool

  (* error *)

  val sml_str_new =
      _import "sml_str_new"
      : __attribute__((unsafe,fast,gc)) char ptr -> string

  exception LLVMError of string

  val sml_llvm_version =
      _import "sml_llvm_version"
      : __attribute__((pure,fast)) () -> char ptr

  fun getVersion () =
      sml_str_new (sml_llvm_version ())

  val LLVMDisposeMessage =
      _import "LLVMDisposeMessage"
      : __attribute__((fast))
        char ptr -> ()

  fun importMessage ptr =
      let
        val s = sml_str_new ptr
      in
        LLVMDisposeMessage ptr;
        s
      end

  (* memory buffer *)
        
  type LLVMMemoryBufferRef = unit ptr

  val LLVMCreateMemoryBufferWithContentsOfFile =
      _import "LLVMCreateMemoryBufferWithContentsOfFile"
      : (string, LLVMMemoryBufferRef ref, char ptr ref) -> LLVMBool
                                                                          
  val LLVMCreateMemoryBufferWithContentsOfFile =
   fn filename =>
      let
        val retBuf = ref (Pointer.NULL ())
        val retMsg = ref (Pointer.NULL ())
        val ret = LLVMCreateMemoryBufferWithContentsOfFile
                    (filename, retBuf, retMsg)
      in
        if ret = 0 then () else raise LLVMError (importMessage (!retMsg));
        !retBuf
      end
        
  val LLVMDisposeMemoryBuffer =
      _import "LLVMDisposeMemoryBuffer"
      : __attribute__((fast))
        LLVMMemoryBufferRef -> ()
                                              
  (* context *)

  type LLVMContextRef = unit ptr

  val LLVMGetGlobalContext =
      _import "LLVMGetGlobalContext"
      : __attribute__((fast))
        () -> LLVMContextRef

  val LLVMContextCreate =
      _import "LLVMContextCreate"
      : __attribute__((fast))
        () -> LLVMContextRef

  val LLVMContextDispose =
      _import "LLVMContextDispose"
      : __attribute__((fast))
        LLVMContextRef -> ()

  (* module *)

  type LLVMModuleRef = unit ptr

  val LLVMModuleCreateWithNameInContext =
      _import "LLVMModuleCreateWithNameInContext"
      : __attribute__((fast))
        (string, LLVMContextRef) -> LLVMModuleRef

  val LLVMDisposeModule =
      _import "LLVMDisposeModule"
      : __attribute__((fast))
        LLVMModuleRef -> ()

  val LLVMDumpModule =
      _import "LLVMDumpModule"
      : LLVMModuleRef -> ()

  val LLVMGetModuleContext =
      _import "LLVMGetModuleContext"
      : __attribute__((fast))
        LLVMModuleRef -> LLVMContextRef

  val LLVMPrintModuleToFile =
      _import "LLVMPrintModuleToFile"
      : (LLVMModuleRef, string, char ptr ref) -> LLVMBool

  val LLVMPrintModuleToFile =
      fn (module, filename) =>
         let
           val retMsg = ref (Pointer.NULL ())
           val ret = LLVMPrintModuleToFile (module, filename, retMsg)
         in
           if ret = 0 then () else raise LLVMError (importMessage (!retMsg))
         end

  val LLVMWriteBitcodeToFile =
      _import "LLVMWriteBitcodeToFile"
      : (LLVMModuleRef, string) -> int

  val LLVMWriteBitcodeToFile =
      fn x =>
         if LLVMWriteBitcodeToFile x = 0
         then ()
         else raise LLVMError "LLVMWriteBitcodeToFile failed"

  val LLVMParseBitcodeInContext =
      _import "LLVMParseBitcodeInContext"
      : (LLVMContextRef, LLVMMemoryBufferRef, LLVMModuleRef ref, char ptr ref)
        -> LLVMBool

  val LLVMParseBitcodeInContext =
      fn (context, membuf) =>
         let
           val retMod = ref _NULL
           val retMsg = ref (Pointer.NULL ())
           val ret = LLVMParseBitcodeInContext (context, membuf, retMod, retMsg)
         in
           if ret = 0 then () else raise LLVMError (importMessage (!retMsg));
           !retMod
         end

  (* builder *)

  type LLVMBasicBlockRef = unit ptr

  val LLVMDeleteBasicBlock =
      _import "LLVMDeleteBasicBlock"
      : __attribute__((fast))
        LLVMBasicBlockRef -> ()

  type LLVMBuilderRef = unit ptr

  val LLVMCreateBuilderInContext =
      _import "LLVMCreateBuilderInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMBuilderRef

  val LLVMDisposeBuilder =
      _import "LLVMDisposeBuilder"
      : __attribute__((fast))
        LLVMBuilderRef -> ()

  val LLVMPositionBuilderAtEnd =
      _import "LLVMPositionBuilderAtEnd"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMBasicBlockRef) -> ()

  val LLVMSetDataLayout =
      _import "LLVMSetDataLayout"
      : __attribute__((fast))
        (LLVMModuleRef, string) -> ()

  val LLVMSetTarget =
      _import "LLVMSetTarget"
      : __attribute__((fast))
        (LLVMModuleRef, string) -> ()

  val LLVMGetTarget =
      _import "LLVMGetTarget"
      : __attribute__((fast))
        LLVMModuleRef -> char ptr

  val LLVMGetTarget =
      fn x => sml_str_new (LLVMGetTarget x)

  (* type *)

  type LLVMTypeRef = unit ptr
  type LLVMTypeRef_Struct = unit ptr
  val castStruct : LLVMTypeRef_Struct -> LLVMTypeRef = fn x => x

  val LLVMFloatTypeInContext =
      _import "LLVMFloatTypeInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMTypeRef

  val LLVMDoubleTypeInContext =
      _import "LLVMDoubleTypeInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt1TypeInContext =
      _import "LLVMInt1TypeInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt8TypeInContext =
      _import "LLVMInt8TypeInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt16TypeInContext =
      _import "LLVMInt16TypeInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt32TypeInContext =
      _import "LLVMInt32TypeInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt64TypeInContext =
      _import "LLVMInt64TypeInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMTypeRef

  val LLVMFunctionType =
      _import "LLVMFunctionType"
      : __attribute__((fast))
        (LLVMTypeRef, LLVMTypeRef vector, word, LLVMBool) -> LLVMTypeRef

  val LLVMPointerType =
      _import "LLVMPointerType"
      : __attribute__((fast))
        (LLVMTypeRef, word) -> LLVMTypeRef

  val LLVMVoidTypeInContext =
      _import "LLVMVoidTypeInContext"
      : __attribute__((fast))
        LLVMContextRef -> LLVMTypeRef

  val LLVMStructTypeInContext =
      _import "LLVMStructTypeInContext"
      : __attribute__((fast))
        (LLVMContextRef, LLVMTypeRef vector, word, LLVMBool) -> LLVMTypeRef

  val LLVMArrayType =
      _import "LLVMArrayType"
      : __attribute__((fast))
        (LLVMTypeRef, word) -> LLVMTypeRef

  (* value *)

  type LLVMValueRef = unit ptr

  val LLVMDumpValue =
      _import "LLVMDumpValue"
      : LLVMValueRef -> ()

  val LLVMGetUndef =
      _import "LLVMGetUndef"
      : __attribute__((fast))
        LLVMTypeRef -> LLVMValueRef

  val LLVMConstNull =
      _import "LLVMConstNull"
      : __attribute__((fast))
        LLVMTypeRef -> LLVMValueRef

  val LLVMConstReal =
      _import "LLVMConstReal"
      : __attribute__((fast))
        (LLVMTypeRef, real) -> LLVMValueRef

  val LLVMConstRealOfString =
      _import "LLVMConstRealOfString"
      : __attribute__((fast))
        (LLVMTypeRef, string) -> LLVMValueRef

  val LLVMConstInt =
      _import "LLVMConstInt"
      : __attribute__((fast))
        (LLVMTypeRef, Word64.word, LLVMBool) -> LLVMValueRef

  val LLVMConstIntOfString =
      _import "LLVMConstIntOfString"
      : __attribute__((fast))
        (LLVMTypeRef, string, Word8.word) -> LLVMValueRef

  val LLVMConstBitCast =
      _import "LLVMConstBitCast"
      : __attribute__((fast))
        (LLVMValueRef, LLVMTypeRef) -> LLVMValueRef

  val LLVMConstIntToPtr =
      _import "LLVMConstIntToPtr"
      : __attribute__((fast))
        (LLVMValueRef, LLVMTypeRef) -> LLVMValueRef

  val LLVMConstPtrToInt =
      _import "LLVMConstPtrToInt"
      : __attribute__((fast))
        (LLVMValueRef, LLVMTypeRef) -> LLVMValueRef

  val LLVMConstSub =
      _import "LLVMConstSub"
      : __attribute__((fast))
        (LLVMValueRef, LLVMValueRef) -> LLVMValueRef

  val LLVMConstNSWSub =
      _import "LLVMConstNSWSub"
      : __attribute__((fast))
        (LLVMValueRef, LLVMValueRef) -> LLVMValueRef

  val LLVMConstNUWSub =
      _import "LLVMConstSub"
      : __attribute__((fast))
        (LLVMValueRef, LLVMValueRef) -> LLVMValueRef

  val LLVMConstGEP =
      _import "LLVMConstGEP"
      : __attribute__((fast))
        (LLVMValueRef, LLVMValueRef vector, word) -> LLVMValueRef

  val LLVMConstInBoundsGEP =
      _import "LLVMConstInBoundsGEP"
      : __attribute__((fast))
        (LLVMValueRef, LLVMValueRef vector, word) -> LLVMValueRef

  val LLVMConstStringInContext =
      _import "LLVMConstStringInContext"
      : __attribute__((fast))
        (LLVMContextRef, string, word, LLVMBool) -> LLVMValueRef

  val LLVMConstStructInContext =
      _import "LLVMConstStructInContext"
      : __attribute__((fast))
        (LLVMContextRef, LLVMValueRef vector, word, LLVMBool) -> LLVMValueRef

  val LLVMConstArray =
      _import "LLVMConstArray"
      : __attribute__((fast))
        (LLVMTypeRef, LLVMValueRef vector, word) -> LLVMValueRef

  (* function *)

  type LLVMAttribute = word
  val LLVMZExtAttribute : LLVMAttribute = 0wx00000001
  val LLVMSExtAttribute : LLVMAttribute = 0wx00000002
  val LLVMNoReturnAttribute : LLVMAttribute = 0wx00000004
  val LLVMInRegAttribute : LLVMAttribute = 0wx00000008
  val LLVMStructRetAttribute : LLVMAttribute = 0wx00000010
  val LLVMNoUnwindAttribute : LLVMAttribute = 0wx00000020
  val LLVMNoAliasAttribute : LLVMAttribute = 0wx00000040
  val LLVMByValAttribute : LLVMAttribute = 0wx00000080
  val LLVMNestAttribute : LLVMAttribute = 0wx00000100
  val LLVMReadNoneAttribute : LLVMAttribute = 0wx00000200
  val LLVMReadOnlyAttribute : LLVMAttribute = 0wx00000400
  val LLVMNoInlineAttribute : LLVMAttribute = 0wx00000800
  val LLVMAlwaysInlineAttribute : LLVMAttribute = 0wx00001000
  val LLVMOptimizeForSizeAttribute : LLVMAttribute = 0wx00002000
  val LLVMStackProtectAttribute : LLVMAttribute = 0wx00004000
  val LLVMStackProtectReqAttribute : LLVMAttribute = 0wx00008000
  val LLVMAlignment : LLVMAttribute = 0wx001f0000
  val LLVMNoCaptureAttribute : LLVMAttribute = 0wx00200000
  val LLVMNoRedZoneAttribute : LLVMAttribute = 0wx00400000
  val LLVMNoImplicitFloatAttribute : LLVMAttribute = 0wx00800000
  val LLVMNakedAttribute : LLVMAttribute = 0wx01000000
  val LLVMInlineHintAttribute : LLVMAttribute = 0wx02000000
  val LLVMStackAlignment : LLVMAttribute = 0wx1c000000
  val LLVMReturnsTwice : LLVMAttribute = 0wx20000000
  val LLVMUWTable : LLVMAttribute = 0wx40000000
  val LLVMNonLazyBind : LLVMAttribute = 0wx80000000

  type LLVMLinkage = int
  val LLVMExternalLinkage : LLVMLinkage = 0
  val LLVMAvailableExternallyLinkage : LLVMLinkage = 1
  val LLVMLinkOnceAnyLinkage : LLVMLinkage = 2
  val LLVMLinkOnceODRLinkage : LLVMLinkage = 3
  val LLVMLinkOnceODRAutoHideLinkage : LLVMLinkage = 4
  val LLVMWeakAnyLinkage : LLVMLinkage = 5
  val LLVMWeakODRLinkage : LLVMLinkage = 6
  val LLVMAppendingLinkage : LLVMLinkage = 7
  val LLVMInternalLinkage : LLVMLinkage = 8
  val LLVMPrivateLinkage : LLVMLinkage = 9
  val LLVMDLLImportLinkage : LLVMLinkage = 10
  val LLVMDLLExportLinkage : LLVMLinkage = 11
  val LLVMExternalWeakLinkage : LLVMLinkage = 12
  val LLVMGhostLinkage : LLVMLinkage = 13
  val LLVMCommonLinkage : LLVMLinkage = 14
  val LLVMLinkerPrivateLinkage : LLVMLinkage = 15
  val LLVMLinkerPrivateWeakLinkage : LLVMLinkage = 16

  type LLVMCallConv = word
  val LLVMCCallConv : LLVMCallConv = 0w0
  val LLVMFastCallConv : LLVMCallConv = 0w8
  val LLVMColdCallConv : LLVMCallConv = 0w9
  val LLVMX86StdcallCallConv : LLVMCallConv = 0w64
  val LLVMX86FastcallCallConv : LLVMCallConv = 0w65

  type LLVMValueRef_Function = LLVMValueRef
  type LLVMValueRef_Arg = LLVMValueRef
  val castFunc : LLVMValueRef_Function -> LLVMValueRef = fn x => x
  val castArg : LLVMValueRef_Arg -> LLVMValueRef = fn x => x

  val LLVMAddFunction =
      _import "LLVMAddFunction"
      : __attribute__((fast))
        (LLVMModuleRef, string, LLVMTypeRef) -> LLVMValueRef_Function

  val LLVMAddFunctionAttr =
      _import "LLVMAddFunctionAttr"
      : __attribute__((fast))
        (LLVMValueRef_Function, LLVMAttribute) -> ()

  val LLVMAddFunctionAttr =
      fn (func, nil) => ()
       | (func, attrs) => LLVMAddFunctionAttr (func, foldl Word.orb 0w0 attrs)

  val LLVMAddFunctionReturnAttr =
      _import "sml_LLVMAddFunctionReturnAttr"
      : __attribute__((fast))
        (LLVMValueRef_Function, LLVMAttribute) -> ()

  val LLVMAddFunctionReturnAttr =
      fn (func, nil) => ()
       | (func, attrs) =>
         LLVMAddFunctionReturnAttr (func, foldl Word.orb 0w0 attrs)

  val LLVMSetLinkage_Function =
      _import "LLVMSetLinkage"
      : __attribute__((fast))
        (LLVMValueRef_Function, LLVMLinkage) -> ()

  val LLVMSetFunctionCallConv =
      _import "LLVMSetFunctionCallConv"
      : __attribute__((fast))
        (LLVMValueRef_Function, LLVMCallConv) -> ()

  val LLVMSetGC =
      _import "LLVMSetGC"
      : __attribute__((fast))
        (LLVMValueRef_Function, string) -> ()

  val LLVMCountParams =
      _import "LLVMCountParams"
      : __attribute__((fast))
        LLVMValueRef_Function -> word

  val LLVMGetParams =
      _import "LLVMGetParams"
      : __attribute__((fast))
        (LLVMValueRef_Function, LLVMValueRef_Arg array) -> ()

  val LLVMGetParams =
      fn func =>
         let
           val n = LLVMCountParams func
           val buf = Array.array (Word.toInt n, _NULL)
         in
           LLVMGetParams (func, buf);
           List.tabulate (Array.length buf, fn i => Array.sub (buf, i))
         end

  val LLVMAddAttribute =
      _import "LLVMAddAttribute"
      : __attribute__((fast))
        (LLVMValueRef_Arg, LLVMAttribute) -> ()

  val LLVMAddAttribute =
      fn (arg, nil) => ()
       | (arg, attrs) => LLVMAddAttribute (arg, foldl Word.orb 0w0 attrs)

  val LLVMSetValueName =
      _import "LLVMSetValueName"
      : __attribute__((fast))
        (LLVMValueRef_Arg, string) -> ()

  val LLVMAppendBasicBlockInContext =
      _import "LLVMAppendBasicBlockInContext"
      : __attribute__((fast))
        (LLVMContextRef, LLVMValueRef_Function, string) -> LLVMBasicBlockRef

  (* global *)

  type LLVMValueRef_GlobalVariable = LLVMValueRef
  val castGlobalVar : LLVMValueRef_GlobalVariable -> LLVMValueRef = fn x => x

  val LLVMAddGlobal =
      _import "LLVMAddGlobal"
      : __attribute__((fast))
        (LLVMModuleRef, LLVMTypeRef, string)
        -> LLVMValueRef_GlobalVariable

  val LLVMSetInitializer =
      _import "LLVMSetInitializer"
      : __attribute__((fast))
        (LLVMValueRef_GlobalVariable, LLVMValueRef) -> ()

  val LLVMSetGlobalConstant =
      _import "LLVMSetGlobalConstant"
      : __attribute__((fast))
        (LLVMValueRef_GlobalVariable, LLVMBool) -> ()

  val LLVMSetLinkage_GlobalVar =
      _import "LLVMSetLinkage"
      : __attribute__((fast))
        (LLVMValueRef_GlobalVariable, LLVMLinkage) -> ()

  val LLVMSetAlignment =
      _import "LLVMSetAlignment"
      : __attribute__((fast))
        (LLVMValueRef, word) -> ()

  val LLVMSetAlignment_GlobalVar = LLVMSetAlignment

  val LLVMSetUnnamedAddr =
      _import "LLVMSetUnnamedAddr"
      : __attribute__((fast))
        (LLVMValueRef_GlobalVariable, LLVMBool) -> ()

  val LLVMAddAlias =
      _import "LLVMAddAlias"
      : __attribute__((fast))
        (LLVMModuleRef, LLVMTypeRef, LLVMValueRef, string)
        -> LLVMValueRef_GlobalVariable

  (* instructions *)

  type LLVMIntPredicate = int
  val LLVMIntEQ : LLVMIntPredicate = 32
  val LLVMIntNE : LLVMIntPredicate = 33
  val LLVMIntUGT : LLVMIntPredicate = 34
  val LLVMIntUGE : LLVMIntPredicate = 35
  val LLVMIntULT : LLVMIntPredicate = 36
  val LLVMIntULE : LLVMIntPredicate = 37
  val LLVMIntSGT : LLVMIntPredicate = 38
  val LLVMIntSGE : LLVMIntPredicate = 39
  val LLVMIntSLT : LLVMIntPredicate = 40
  val LLVMIntSLE : LLVMIntPredicate = 41

  type LLVMRealPredicate = int
  val LLVMRealPredicateFalse : LLVMRealPredicate = 0
  val LLVMRealOEQ : LLVMRealPredicate = 1
  val LLVMRealOGT : LLVMRealPredicate = 2
  val LLVMRealOGE : LLVMRealPredicate = 3
  val LLVMRealOLT : LLVMRealPredicate = 4
  val LLVMRealOLE : LLVMRealPredicate = 5
  val LLVMRealONE : LLVMRealPredicate = 6
  val LLVMRealORD : LLVMRealPredicate = 7
  val LLVMRealUNO : LLVMRealPredicate = 8
  val LLVMRealUEQ : LLVMRealPredicate = 9
  val LLVMRealUGT : LLVMRealPredicate = 10
  val LLVMRealUGE : LLVMRealPredicate = 11
  val LLVMRealULT : LLVMRealPredicate = 12
  val LLVMRealULE : LLVMRealPredicate = 13
  val LLVMRealUNE : LLVMRealPredicate = 14
  val LLVMRealPredicateTrue : LLVMRealPredicate = 15

  type AtomicOrdering = int  (* defined in llvm/IR/Instructions.h *)
  val AtomicOrderingNotAtomic = 0
  val AtomicOrderingUnordered = 1
  val AtomicOrderingMonotonic = 2
  val AtomicOrderingAcquire = 4
  val AtomicOrderingRelease = 5
  val AtomicOrderingAcquireRelease = 6
  val AtomicOrderingSequentiallyConsistent = 7

  type SynchronizationScope = int  (* defined in llvm/IR/Instructions.h *)
  val SingleThread = 0
  val CrossThread = 1

  type LLVMValueRef_Load = LLVMValueRef
  type LLVMValueRef_Store = LLVMValueRef
  type LLVMValueRef_Switch = LLVMValueRef
  type LLVMValueRef_Phi = LLVMValueRef
  type LLVMValueRef_Call = LLVMValueRef
  type LLVMValueRef_LandingPad = LLVMValueRef
  val castPhi : LLVMValueRef_Phi -> LLVMValueRef = fn x => x
  val castLoad : LLVMValueRef_Load -> LLVMValueRef = fn x => x
  val castCall : LLVMValueRef_Call -> LLVMValueRef = fn x => x
  val castLandingPad : LLVMValueRef_LandingPad -> LLVMValueRef = fn x => x

  val LLVMBuildRetVoid =
      _import "LLVMBuildRetVoid"
      : __attribute__((fast))
        LLVMBuilderRef -> LLVMValueRef

  val LLVMBuildRet =
      _import "LLVMBuildRet"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef) -> LLVMValueRef

  val LLVMBuildBr =
      _import "LLVMBuildBr"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMBasicBlockRef) -> LLVMValueRef

  val LLVMBuildCondBr =
      _import "LLVMBuildCondBr"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMBasicBlockRef,
                 LLVMBasicBlockRef) -> LLVMValueRef

  val LLVMBuildSwitch =
      _import "LLVMBuildSwitch"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMBasicBlockRef, word)
        -> LLVMValueRef_Switch

  val LLVMAddCase =
      _import "LLVMAddCase"
      : __attribute__((fast))
        (LLVMValueRef_Switch, LLVMValueRef, LLVMBasicBlockRef) -> ()

  (*
  val LLVMBuildIndirectBr =
      _import "LLVMBuildIndirectBr"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, word) -> LLVMValueRef_IndirectBr

  val LLVMAddDestination =
      _import "LLVMAddDestination"
      : __attribute__((fast))
        (LLVMValueRef_IndirectBr, LLVMBasicBlockRef) -> ()
  *)

  val LLVMBuildResume =
      _import "LLVMBuildResume"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef) -> LLVMValueRef

  val LLVMBuildUnreachable =
      _import "LLVMBuildUnreachable"
      : __attribute__((fast))
        LLVMBuilderRef -> LLVMValueRef

  val LLVMBuildAdd =
      _import "LLVMBuildAdd"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNSWAdd =
      _import "LLVMBuildNSWAdd"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNUWAdd =
      _import "LLVMBuildNUWAdd"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFAdd =
      _import "LLVMBuildFAdd"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildSub =
      _import "LLVMBuildSub"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNSWSub =
      _import "LLVMBuildNSWSub"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNUWSub =
      _import "LLVMBuildNUWSub"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFSub =
      _import "LLVMBuildFSub"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildMul =
      _import "LLVMBuildMul"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNSWMul =
      _import "LLVMBuildNSWMul"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNUWMul =
      _import "LLVMBuildNUWMul"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFMul =
      _import "LLVMBuildFMul"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildUDiv =
      _import "LLVMBuildUDiv"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildSDiv =
      _import "LLVMBuildSDiv"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildExactSDiv =
      _import "LLVMBuildExactSDiv"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFDiv =
      _import "LLVMBuildFDiv"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildURem =
      _import "LLVMBuildURem"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildSRem =
      _import "LLVMBuildSRem"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFRem =
      _import "LLVMBuildFRem"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildShl =
      _import "LLVMBuildShl"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildLShr =
      _import "LLVMBuildLShr"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildAShr =
      _import "LLVMBuildAShr"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildAnd =
      _import "LLVMBuildAnd"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildOr =
      _import "LLVMBuildOr"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildXor =
      _import "LLVMBuildXor"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  (*
  val LLVMBuildBinOp =
      _import "LLVMBuildBinOp"
      : __attribute__((fast))
        (LLVMBuilderRef, Opcode, LLVMValueRef, LLVMValueRef, string)
        -> LLVMValueRef
  *)

  val LLVMBuildNeg =
      _import "LLVMBuildNeg"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNSWNeg =
      _import "LLVMBuildNSWNeg"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNUWNeg =
      _import "LLVMBuildNUWNeg"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFNeg =
      _import "LLVMBuildFNeg"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNot =
      _import "LLVMBuildNot"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildAlloca =
      _import "LLVMBuildAlloca"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildLoad =
      _import "LLVMBuildLoad"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildStore =
      _import "LLVMBuildStore"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef) -> LLVMValueRef

  val LLVMBuildGEP =
      _import "LLVMBuildGEP"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef vector, word, string)
        -> LLVMValueRef

  val LLVMBuildInBoundsGEP =
      _import "LLVMBuildInBoundsGEP"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef vector, word, string)
        -> LLVMValueRef

  val LLVMBuildStructGEP =
      _import "LLVMBuildStructGEP"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, word, string) -> LLVMValueRef

  val LLVMBuildExtractValue =
      _import "LLVMBuildExtractValue"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, word, string) -> LLVMValueRef

  val LLVMBuildInsertValue =
      _import "LLVMBuildInsertValue"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, word, string)
        -> LLVMValueRef

  val LLVMBuildTrunc =
      _import "LLVMBuildTrunc"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildZExt =
      _import "LLVMBuildZExt"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildSExt =
      _import "LLVMBuildSExt"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildFPToUI =
      _import "LLVMBuildFPToUI"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildFPToSI =
      _import "LLVMBuildFPToSI"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildUIToFP =
      _import "LLVMBuildUIToFP"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildSIToFP =
      _import "LLVMBuildSIToFP"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildFPTrunc =
      _import "LLVMBuildFPTrunc"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildFPExt =
      _import "LLVMBuildFPExt"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildPtrToInt =
      _import "LLVMBuildPtrToInt"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildIntToPtr =
      _import "LLVMBuildIntToPtr"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildBitCast =
      _import "LLVMBuildBitCast"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildZExtOrBitCast =
      _import "LLVMBuildZExtOrBitCast"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildSExtOrBitCast =
      _import "LLVMBuildSExtOrBitCast"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildTruncOrBitCast =
      _import "LLVMBuildTruncOrBitCast"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildICmp =
      _import "LLVMBuildICmp"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMIntPredicate, LLVMValueRef, LLVMValueRef, string)
        -> LLVMValueRef

  val LLVMBuildFCmp =
      _import "LLVMBuildFCmp"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMRealPredicate, LLVMValueRef, LLVMValueRef, string)
        -> LLVMValueRef

  val LLVMBuildSelect =
      _import "LLVMBuildSelect"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, LLVMValueRef, string)
        -> LLVMValueRef

  val LLVMBuildPhi =
      _import "LLVMBuildPhi"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMTypeRef, string) -> LLVMValueRef_Phi

  val LLVMAddIncoming =
      _import "LLVMAddIncoming"
      : __attribute__((fast))
        (LLVMValueRef_Phi, LLVMValueRef vector, LLVMBasicBlockRef vector, word)
        -> ()

  val LLVMSetPersonalityFn =
      _import "LLVMSetPersonalityFn"
      : __attribute__((fast))
        (LLVMValueRef_Function, LLVMValueRef) -> ()

  val LLVMBuildLandingPad =
      _import "LLVMBuildLandingPad"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMTypeRef, LLVMValueRef, word, string)
        -> LLVMValueRef_LandingPad

  (* From LLVM 3.7.0, the reference to the personality function is moved
   * from landingpad instruction to the parent function.  Following this
   * change, LLVM 3.7.0 removes the third argument (personalityFn) of
   * LLVMBuildLandingPad and introduces LLVMSetPersonalityFn instead.
   * For backward compatibility, LLVM 3.7.1 reverts the third argument
   * as an optional argument that will be propagated to LLVMSetPersonalityFn
   * if given.  We follow the new mechanism for the personality function,
   * i.e. we use LLVMSetPersonalityFn and do not set the third argument
   * of LLVMBuildLandingPad. *)
  val LLVMBuildLandingPad =
      fn (b, t, n, s) =>
         LLVMBuildLandingPad (b, t, Pointer.NULL (), n, s)

  val LLVMAddClause =
      _import "LLVMAddClause"
      : __attribute__((fast))
        (LLVMValueRef_LandingPad, LLVMValueRef) -> ()

  val LLVMSetCleanup =
      _import "LLVMSetCleanup"
      : __attribute__((fast))
        (LLVMValueRef_LandingPad, LLVMBool) -> ()

  val LLVMBuildInvoke =
      _import "LLVMBuildInvoke"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef vector, word,
         LLVMBasicBlockRef, LLVMBasicBlockRef, string)
        -> LLVMValueRef_Call

  val LLVMBuildCall =
      _import "LLVMBuildCall"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef vector, word, string)
        -> LLVMValueRef_Call

  val LLVMSetTailCall =
      _import "LLVMSetTailCall"
      : __attribute__((fast))
        (LLVMValueRef_Call, LLVMBool) -> ()

  val SetMustTailCall =
      _import "sml_SetMustTailCall"
      : __attribute__((fast))
        LLVMValueRef_Call -> ()

  val LLVMSetInstructionCallConv =
      _import "LLVMSetInstructionCallConv"
      : __attribute__((fast))
        (LLVMValueRef_Call, LLVMCallConv) -> ()

  val LLVMAddInstrAttribute =
      _import "LLVMAddInstrAttribute"
      : __attribute__((fast))
        (LLVMValueRef_Call, word, LLVMAttribute) -> ()

  val LLVMAddInstrAttribute =
      fn (call, index, attrs) =>
         LLVMAddInstrAttribute (call, index, foldl Word.orb 0w0 attrs)

  val ReturnIndex = 0w0               (* AttributeSet::ReturnIndex *)
  val FunctionIndex = Word.notb 0w0   (* AttributeSet::FunctionIndex *)

  val SetAtomic =
      _import "sml_SetAtomic"
      : __attribute__((fast))
        (LLVMValueRef, AtomicOrdering, SynchronizationScope) -> ()

  val SetAtomic_Load = SetAtomic
  val SetAtomic_Store = SetAtomic
  val LLVMSetAlignment_Load = LLVMSetAlignment
  val LLVMSetAlignment_Store = LLVMSetAlignment


  (*
  val LLVMBuildSelect =
      _import "LLVMBuildSelect"
      : __attribute__((fast))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, LLVMValueRef,
                 string) -> LLVMValueRef
  *)

  (* linker *)

  type LLVMLinkerMode = int
  val LLVMLinkerDestroySource : LLVMLinkerMode = 0
  val LLVMLinkerPreserveSource : LLVMLinkerMode = 1

  val LLVMLinkModules =
      _import "LLVMLinkModules"
      : (LLVMModuleRef, LLVMModuleRef, LLVMLinkerMode, char ptr ref)
        -> LLVMBool

  val LLVMLinkModules =
      fn (dst, src, mode) =>
         let
           val retMsg = ref (Pointer.NULL ())
           val ret = LLVMLinkModules (dst, src, mode, retMsg)
         in
           if ret = 0 then () else raise LLVMError (importMessage (!retMsg))
         end

  (* compile *)

  type OptLevel = word
  val OptNone : OptLevel = 0w0
  val OptLess : OptLevel = 0w1
  val OptDefault : OptLevel = 0w2
  val OptAggressive : OptLevel = 0w3

  type RelocModel = word
  val RelocDefault : RelocModel = 0w0
  val RelocStatic : RelocModel = 0w1
  val RelocPIC : RelocModel = 0w2
  val RelocDynamicNoPIC : RelocModel = 0w3

  type CodeModel = word
  val CodeModelDefault : CodeModel = 0w0
  val CodeModelJITDefault : CodeModel = 0w1
  val CodeModelSmall : CodeModel = 0w2
  val CodeModelKernel : CodeModel = 0w3
  val CodeModelMedium : CodeModel = 0w4
  val CodeModelLarge : CodeModel = 0w5

  type LLVMTargetRef = unit ptr

  val LLVMGetTargetFromArchAndTriple =
      _import "sml_LLVMGetTargetFromArchAndTriple"
      : __attribute__((fast))
        (string, string, LLVMTargetRef ref, char ptr ref) -> LLVMBool

  val LLVMGetTargetFromArchAndTriple =
      fn (arch, triple) =>
         let
           val retTarget = ref (Pointer.NULL ())
           val retMsg = ref (Pointer.NULL ())
           val ret = LLVMGetTargetFromArchAndTriple
                       (arch, triple, retTarget, retMsg)
         in
           if ret = 0 then !retTarget
           else raise LLVMError (importMessage (!retMsg))
         end

  type LLVMTargetMachineRef = unit ptr

  val LLVMCreateTargetMachine =
      _import "LLVMCreateTargetMachine"
      : __attribute__((fast))
        (LLVMTargetRef, string, string, string, OptLevel,
         RelocModel, CodeModel) -> LLVMTargetMachineRef

  type LLVMTargetDataRef = unit ptr

  val LLVMGetTargetMachineData =
      _import "LLVMGetTargetMachineData"
      : __attribute__((fast))
	LLVMTargetMachineRef -> LLVMTargetDataRef

  val LLVMPointerSize =
      _import "LLVMPointerSize"
      : __attribute__((fast))
	LLVMTargetDataRef -> word

  val LLVMDisposeTargetMachine =
      _import "LLVMDisposeTargetMachine"
      : __attribute__((fast))
        LLVMTargetMachineRef -> ()


(*
  (* target *)

  type LLVMTargetRef = unit ptr

  val LLVMGetFirstTarget =
      _import "LLVMGetFirstTarget"
      : __attribute__((fast))
        () -> LLVMTargetRef

  val LLVMGetNextTarget =
      _import "LLVMGetNextTarget"
      : __attribute__((fast))
        LLVMTargetRef -> LLVMTargetRef

  val LLVMGetNextTarget =
      fn target =>
         let
           val target = LLVMGetNextTarget target
         in
           if target = _NULL then NONE else SOME target
         end

  val LLVMGetTargetName =
      _import "LLVMGetTargetName"
      : __attribute__((fast))
        LLVMTargetRef -> char ptr

  val LLVMGetTargetName =
      fn x => sml_str_new (LLVMGetTargetName x)

  val LLVMGetTargetDescription =
      _import "LLVMGetTargetDescription"
      : __attribute__((fast))
        LLVMTargetRef -> char ptr

  val LLVMGetTargetDescription =
      fn x => sml_str_new (LLVMGetTargetDescription x)

  val LLVMTargetHasJIT =
      _import "LLVMTargetHasJIT"
      : __attribute__((fast))
        LLVMTargetRef -> LLVMBool

  val LLVMTargetHasTargetMachine =
      _import "LLVMTargetHasTargetMachine"
      : __attribute__((fast))
        LLVMTargetRef -> LLVMBool

  val LLVMTargetHasAsmBackend =
      _import "LLVMTargetHasAsmBackend"
      : __attribute__((fast))
        LLVMTargetRef -> LLVMBool

  val sml_llvm_lookup_target =
      _import "sml_llvm_lookup_target"
      : __attribute__((fast))
        (LLVMTargetRef ref, string, string, char ptr ref) -> LLVMBool

  fun lookupTarget (arch, triple) =
      let
        val retTarget = ref _NULL
        val retMsg = ref (Pointer.NULL ())
        val ret = sml_llvm_lookup_target (retTarget, arch, triple, retMsg)
      in
        if ret = 0 then () else raise LLVMError (importMessage (!retMsg));
        !retTarget
      end

  (* target machine *)

  type LLVMCodeGenOptLevel = int
  val LLVMCodeGenLevelNone : LLVMCodeGenOptLevel = 0
  val LLVMCodeGenLevelLess : LLVMCodeGenOptLevel = 1
  val LLVMCodeGenLevelDefault : LLVMCodeGenOptLevel = 2
  val LLVMCodeGenLevelAggressive : LLVMCodeGenOptLevel = 3

  type LLVMRelocMode = int
  val LLVMRelocDefault : LLVMRelocMode = 0
  val LLVMRelocStatic : LLVMRelocMode = 1
  val LLVMRelocPIC : LLVMRelocMode = 2
  val LLVMRelocDynamicNoPic : LLVMRelocMode = 3

  type LLVMCodeModel = int
  val LLVMCodeModelDefault : LLVMCodeModel = 0
  val LLVMCodeModelJITDefault : LLVMCodeModel = 1
  val LLVMCodeModelSmall : LLVMCodeModel = 2
  val LLVMCodeModelKernel : LLVMCodeModel = 3
  val LLVMCodeModelMedium : LLVMCodeModel = 4
  val LLVMCodeModelLarge : LLVMCodeModel = 5

  type LLVMCodeGenFileType = int
  val LLVMAssemblyFile : LLVMCodeGenFileType = 0
  val LLVMObjectFile : LLVMCodeGenFileType = 1

  type LLVMTargetMachineRef = unit ptr

  val LLVMCreateTargetMachine =
      _import "LLVMCreateTargetMachine"
      : __attribute__((fast))
        (LLVMTargetRef, string, string, string, LLVMCodeGenOptLevel,
         LLVMRelocMode, LLVMCodeModel) -> LLVMTargetMachineRef

  val LLVMTargetMachineEmitToFile =
      _import "LLVMTargetMachineEmitToFile"
      : (LLVMTargetMachineRef, LLVMModuleRef, string, LLVMCodeGenFileType,
         char ptr ref) -> LLVMBool

  val LLVMTargetMachineEmitToFile =
      fn (machine, module, filename, filetype) =>
         let
           val retMsg = ref (Pointer.NULL ())
           val ret = LLVMTargetMachineEmitToFile
                       (machine, module, filename, filetype, retMsg)
         in
           if ret = 0 then () else raise LLVMError (importMessage (!retMsg))
         end

  (* execution engine *)

  type LLVMExecutionEngineRef = unit ptr
  type LLVMGenericValueRef = unit ptr

  val LLVMCreateExecutionEngineForModule =
      _import "LLVMCreateExecutionEngineForModule"
      : __attribute__((fast))
        (LLVMExecutionEngineRef ref, LLVMModuleRef, char ptr ref) -> LLVMBool

  val LLVMCreateExecutionEngineForModule =
      fn module =>
         let
           val retEngine = ref _NULL
           val retMsg = ref (Pointer.NULL ())
           val ret = LLVMCreateExecutionEngineForModule
                       (retEngine, module, retMsg)
         in
           if ret = 0 then () else raise LLVMError (importMessage (!retMsg));
           !retEngine
         end

(*
  val LLVMCreateInterpreterForModule =
      _import "LLVMCreateInterpreterForModule"
      : __attribute__((fast))
        (LLVMExecutionEngineRef ref, LLVMModuleRef, char ptr ref) -> LLVMBool

  val LLVMCreateJITCompilerForModule =
      _import "LLVMCreateJITCompilerForModule"
      : __attribute__((fast))
        (LLVMExecutionEngineRef ref, LLVMModuleRef, word, char ptr ref)
        -> LLVMBool
*)

  val LLVMDisposeExecutionEngine =
      _import "LLVMDisposeExecutionEngine"
      : __attribute__((fast))
        LLVMExecutionEngineRef -> ()

  val LLVMAddModule =
      _import "LLVMAddModule"
      : __attribute__((fast))
        (LLVMExecutionEngineRef, LLVMModuleRef) -> ()

  val LLVMFindFunction =
      _import "LLVMFindFunction"
      : __attribute__((fast))
        (LLVMExecutionEngineRef, string, LLVMValueRef_Function ref) -> LLVMBool

  val LLVMFindFunction =
      fn (engine, name) =>
         let
           val retVal = ref _NULL
           val ret = LLVMFindFunction (engine, name, retVal)
         in
           if ret = 0 then SOME (!retVal) else NONE
         end

  val LLVMRunFunction =
      _import "LLVMRunFunction"
      : (LLVMExecutionEngineRef, LLVMValueRef_Function, word,
         LLVMGenericValueRef vector) -> LLVMBool
*)
      
end
