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

  (* error *)

  val sml_str_new =
      _import "sml_str_new"
      : __attribute__((no_callback, alloc)) char ptr -> string

  exception LLVMError of string

  val sml_llvm_version =
      _import "sml_llvm_version"
      : __attribute__((no_callback, alloc)) () -> char ptr

  fun getVersion () =
      sml_str_new (sml_llvm_version ())

  val LLVMDisposeMessage =
      _import "LLVMDisposeMessage"
      : __attribute__((no_callback))
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
      : __attribute__((no_callback))
        (string, LLVMMemoryBufferRef ref, char ptr ref) -> LLVMBool
                                                                          
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
      : __attribute__((no_callback))
        LLVMMemoryBufferRef -> ()
                                              
  (* context *)

  type LLVMContextRef = unit ptr

  val LLVMGetGlobalContext =
      _import "LLVMGetGlobalContext"
      : __attribute__((no_callback))
        () -> LLVMContextRef

  val LLVMContextCreate =
      _import "LLVMContextCreate"
      : __attribute__((no_callback))
        () -> LLVMContextRef

  val LLVMContextDispose =
      _import "LLVMContextDispose"
      : __attribute__((no_callback))
        LLVMContextRef -> ()

  (* module *)

  type LLVMModuleRef = unit ptr

  val LLVMModuleCreateWithNameInContext =
      _import "LLVMModuleCreateWithNameInContext"
      : __attribute__((no_callback))
        (string, LLVMContextRef) -> LLVMModuleRef

  val LLVMDisposeModule =
      _import "LLVMDisposeModule"
      : __attribute__((no_callback))
        LLVMModuleRef -> ()

  val LLVMDumpModule =
      _import "LLVMDumpModule"
      : __attribute__((no_callback))
        LLVMModuleRef -> ()

  val LLVMGetModuleContext =
      _import "LLVMGetModuleContext"
      : __attribute__((no_callback))
        LLVMModuleRef -> LLVMContextRef

  val LLVMPrintModuleToFile =
      _import "LLVMPrintModuleToFile"
      : __attribute__((no_callback))
        (LLVMModuleRef, string, char ptr ref) -> LLVMBool

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
      : __attribute__((no_callback))
        (LLVMModuleRef, string) -> int

  val LLVMWriteBitcodeToFile =
      fn x =>
         if LLVMWriteBitcodeToFile x = 0
         then ()
         else raise LLVMError "LLVMWriteBitcodeToFile failed"

  val LLVMParseBitcodeInContext =
      _import "LLVMParseBitcodeInContext"
      : __attribute__((no_callback))
        (LLVMContextRef, LLVMMemoryBufferRef, LLVMModuleRef ref, char ptr ref)
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
      : __attribute__((no_callback))
        LLVMBasicBlockRef -> ()

  type LLVMBuilderRef = unit ptr

  val LLVMCreateBuilderInContext =
      _import "LLVMCreateBuilderInContext"
      : __attribute__((no_callback))
        LLVMContextRef -> LLVMBuilderRef

  val LLVMDisposeBuilder =
      _import "LLVMDisposeBuilder"
      : __attribute__((no_callback))
        LLVMBuilderRef -> ()

  val LLVMPositionBuilderAtEnd =
      _import "LLVMPositionBuilderAtEnd"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMBasicBlockRef) -> ()

  val LLVMSetDataLayout =
      _import "LLVMSetDataLayout"
      : __attribute__((no_callback))
        (LLVMModuleRef, string) -> ()

  val LLVMSetTarget =
      _import "LLVMSetTarget"
      : __attribute__((no_callback))
        (LLVMModuleRef, string) -> ()

  val LLVMGetTarget =
      _import "LLVMGetTarget"
      : __attribute__((no_callback))
        LLVMModuleRef -> char ptr

  val LLVMGetTarget =
      fn x => sml_str_new (LLVMGetTarget x)

  (* type *)

  type LLVMTypeRef = unit ptr
  type LLVMTypeRef_Struct = unit ptr
  val castStruct : LLVMTypeRef_Struct -> LLVMTypeRef = fn x => x

  val LLVMFloatTypeInContext =
      _import "LLVMFloatTypeInContext"
      : __attribute__((no_callback))
        LLVMContextRef -> LLVMTypeRef

  val LLVMDoubleTypeInContext =
      _import "LLVMDoubleTypeInContext"
      : __attribute__((no_callback))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt1TypeInContext =
      _import "LLVMInt1TypeInContext"
      : __attribute__((no_callback))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt8TypeInContext =
      _import "LLVMInt8TypeInContext"
      : __attribute__((no_callback))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt32TypeInContext =
      _import "LLVMInt32TypeInContext"
      : __attribute__((no_callback))
        LLVMContextRef -> LLVMTypeRef

  val LLVMInt64TypeInContext =
      _import "LLVMInt64TypeInContext"
      : __attribute__((no_callback))
        LLVMContextRef -> LLVMTypeRef

  val LLVMFunctionType =
      _import "LLVMFunctionType"
      : __attribute__((no_callback))
        (LLVMTypeRef, LLVMTypeRef vector, word, LLVMBool) -> LLVMTypeRef

  val LLVMPointerType =
      _import "LLVMPointerType"
      : __attribute__((no_callback))
        (LLVMTypeRef, word) -> LLVMTypeRef

  val LLVMVoidTypeInContext =
      _import "LLVMVoidTypeInContext"
      : __attribute__((no_callback))
        LLVMContextRef -> LLVMTypeRef

  val LLVMStructTypeInContext =
      _import "LLVMStructTypeInContext"
      : __attribute__((no_callback))
        (LLVMContextRef, LLVMTypeRef vector, word, LLVMBool) -> LLVMTypeRef

  val LLVMArrayType =
      _import "LLVMArrayType"
      : __attribute__((no_callback))
        (LLVMTypeRef, word) -> LLVMTypeRef

  (* value *)

  type LLVMValueRef = unit ptr

  val LLVMDumpValue =
      _import "LLVMDumpValue"
      : __attribute__((no_callback))
        LLVMValueRef -> ()

  val LLVMConstNull =
      _import "LLVMConstNull"
      : __attribute__((no_callback))
        LLVMTypeRef -> LLVMValueRef

  val LLVMConstReal =
      _import "LLVMConstReal"
      : __attribute__((no_callback))
        (LLVMTypeRef, real) -> LLVMValueRef

  val LLVMConstRealOfString =
      _import "LLVMConstRealOfString"
      : __attribute__((no_callback))
        (LLVMTypeRef, string) -> LLVMValueRef

  val LLVMConstIntOfString =
      _import "LLVMConstIntOfString"
      : __attribute__((no_callback))
        (LLVMTypeRef, string, Word8.word) -> LLVMValueRef

  val LLVMConstBitCast =
      _import "LLVMConstBitCast"
      : __attribute__((no_callback))
        (LLVMValueRef, LLVMTypeRef) -> LLVMValueRef

  val LLVMConstIntToPtr =
      _import "LLVMConstIntToPtr"
      : __attribute__((no_callback))
        (LLVMValueRef, LLVMTypeRef) -> LLVMValueRef

  val LLVMConstPtrToInt =
      _import "LLVMConstPtrToInt"
      : __attribute__((no_callback))
        (LLVMValueRef, LLVMTypeRef) -> LLVMValueRef

  val LLVMConstSub =
      _import "LLVMConstSub"
      : __attribute__((no_callback))
        (LLVMValueRef, LLVMValueRef) -> LLVMValueRef

  val LLVMConstGEP =
      _import "LLVMConstGEP"
      : __attribute__((no_callback))
        (LLVMValueRef, LLVMValueRef vector, word) -> LLVMValueRef

  val LLVMConstInBoundsGEP =
      _import "LLVMConstInBoundsGEP"
      : __attribute__((no_callback))
        (LLVMValueRef, LLVMValueRef vector, word) -> LLVMValueRef

  val LLVMConstStringInContext =
      _import "LLVMConstStringInContext"
      : __attribute__((no_callback))
        (LLVMContextRef, string, word, LLVMBool) -> LLVMValueRef

  val LLVMConstStructInContext =
      _import "LLVMConstStructInContext"
      : __attribute__((no_callback))
        (LLVMContextRef, LLVMValueRef vector, word, LLVMBool) -> LLVMValueRef

  val LLVMConstArray =
      _import "LLVMConstArray"
      : __attribute__((no_callback))
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
      : __attribute__((no_callback))
        (LLVMModuleRef, string, LLVMTypeRef) -> LLVMValueRef_Function

(*
  val LLVMAddFunctionAttr =
      _import "LLVMAddFunctionAttr"
      : __attribute__((no_callback))
        (LLVMValueRef_Function, LLVMAttribute) -> ()

  val LLVMAddFunctionAttr =
      fn (func, attrs) => LLVMAddFunctionAttr (func, foldl Word.orb 0w0 attrs)
*)

  val sml_llvm_add_func_attr =
      _import "sml_llvm_add_func_attr"
      : __attribute__((no_callback))
        (LLVMValueRef_Function, word, LLVMAttribute) -> ()

  fun addFunctionAttribute (func, index, attrs) =
      sml_llvm_add_func_attr (func, index, foldl Word.orb 0w0 attrs)

  val LLVMSetLinkage_Function =
      _import "LLVMSetLinkage"
      : __attribute__((no_callback))
        (LLVMValueRef_Function, LLVMLinkage) -> ()

  val LLVMSetFunctionCallConv =
      _import "LLVMSetFunctionCallConv"
      : __attribute__((no_callback))
        (LLVMValueRef_Function, LLVMCallConv) -> ()

  val LLVMSetGC =
      _import "LLVMSetGC"
      : __attribute__((no_callback))
        (LLVMValueRef_Function, string) -> ()

  val LLVMCountParams =
      _import "LLVMCountParams"
      : __attribute__((no_callback))
        LLVMValueRef_Function -> word

  val LLVMGetParams =
      _import "LLVMGetParams"
      : __attribute__((no_callback))
        (LLVMValueRef_Function, LLVMValueRef_Arg array) -> ()

  val LLVMGetParams =
      fn func =>
         let
           val n = LLVMCountParams func
           val buf = Array.array (Word.toInt n, _NULL)
         in
           LLVMGetParams (func, buf);
           buf
         end

(*
  val LLVMAddAttribute =
      _import "LLVMAddAttribute"
      : __attribute__((no_callback))
        (LLVMValueRef_Arg, LLVMAttribute) -> ()
*)

  val LLVMSetValueName =
      _import "LLVMSetValueName"
      : __attribute__((no_callback))
        (LLVMValueRef_Arg, string) -> ()

  val LLVMAppendBasicBlockInContext =
      _import "LLVMAppendBasicBlockInContext"
      : __attribute__((no_callback))
        (LLVMContextRef, LLVMValueRef_Function, string) -> LLVMBasicBlockRef

  (* global *)

  type LLVMValueRef_GlobalVariable = LLVMValueRef
  val castGlobalVar : LLVMValueRef_GlobalVariable -> LLVMValueRef = fn x => x

  val LLVMAddGlobal =
      _import "LLVMAddGlobal"
      : __attribute__((no_callback))
        (LLVMModuleRef, LLVMTypeRef, string)
        -> LLVMValueRef_GlobalVariable

  val LLVMSetInitializer =
      _import "LLVMSetInitializer"
      : __attribute__((no_callback))
        (LLVMValueRef_GlobalVariable, LLVMValueRef) -> ()

  val LLVMSetGlobalConstant =
      _import "LLVMSetGlobalConstant"
      : __attribute__((no_callback))
        (LLVMValueRef_GlobalVariable, LLVMBool) -> ()

  val LLVMSetLinkage_GlobalVar =
      _import "LLVMSetLinkage"
      : __attribute__((no_callback))
        (LLVMValueRef_GlobalVariable, LLVMLinkage) -> ()

  val LLVMSetAlignment =
      _import "LLVMSetAlignment"
      : __attribute__((no_callback))
        (LLVMValueRef_GlobalVariable, word) -> ()

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

  type LLVMValueRef_Switch = LLVMValueRef
  type LLVMValueRef_Phi = LLVMValueRef
  type LLVMValueRef_Call = LLVMValueRef
  type LLVMValueRef_LandingPad = LLVMValueRef
  val castPhi : LLVMValueRef_Phi -> LLVMValueRef = fn x => x
  val castCall : LLVMValueRef_Call -> LLVMValueRef = fn x => x
  val castLandingPad : LLVMValueRef_LandingPad -> LLVMValueRef = fn x => x

  val LLVMBuildRetVoid =
      _import "LLVMBuildRetVoid"
      : __attribute__((no_callback))
        LLVMBuilderRef -> LLVMValueRef

  val LLVMBuildRet =
      _import "LLVMBuildRet"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef) -> LLVMValueRef

  val LLVMBuildBr =
      _import "LLVMBuildBr"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMBasicBlockRef) -> LLVMValueRef

  val LLVMBuildCondBr =
      _import "LLVMBuildCondBr"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMBasicBlockRef,
                 LLVMBasicBlockRef) -> LLVMValueRef

  val LLVMBuildSwitch =
      _import "LLVMBuildSwitch"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMBasicBlockRef, word)
        -> LLVMValueRef_Switch

  val LLVMAddCase =
      _import "LLVMAddCase"
      : __attribute__((no_callback))
        (LLVMValueRef_Switch, LLVMValueRef, LLVMBasicBlockRef) -> ()

  (*
  val LLVMBuildIndirectBr =
      _import "LLVMBuildIndirectBr"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, word) -> LLVMValueRef_IndirectBr

  val LLVMAddDestination =
      _import "LLVMAddDestination"
      : __attribute__((no_callback))
        (LLVMValueRef_IndirectBr, LLVMBasicBlockRef) -> ()
  *)

  val LLVMBuildResume =
      _import "LLVMBuildResume"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef) -> LLVMValueRef

  val LLVMBuildUnreachable =
      _import "LLVMBuildUnreachable"
      : __attribute__((no_callback))
        LLVMBuilderRef -> LLVMValueRef

  val LLVMBuildAdd =
      _import "LLVMBuildAdd"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNSWAdd =
      _import "LLVMBuildNSWAdd"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNUWAdd =
      _import "LLVMBuildNUWAdd"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFAdd =
      _import "LLVMBuildFAdd"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildSub =
      _import "LLVMBuildSub"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNSWSub =
      _import "LLVMBuildNSWSub"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNUWSub =
      _import "LLVMBuildNUWSub"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFSub =
      _import "LLVMBuildFSub"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildMul =
      _import "LLVMBuildMul"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNSWMul =
      _import "LLVMBuildNSWMul"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNUWMul =
      _import "LLVMBuildNUWMul"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFMul =
      _import "LLVMBuildFMul"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildUDiv =
      _import "LLVMBuildUDiv"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildSDiv =
      _import "LLVMBuildSDiv"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildExactSDiv =
      _import "LLVMBuildExactSDiv"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFDiv =
      _import "LLVMBuildFDiv"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildURem =
      _import "LLVMBuildURem"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildSRem =
      _import "LLVMBuildSRem"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFRem =
      _import "LLVMBuildFRem"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildShl =
      _import "LLVMBuildShl"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildLShr =
      _import "LLVMBuildLShr"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildAShr =
      _import "LLVMBuildAShr"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildAnd =
      _import "LLVMBuildAnd"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildOr =
      _import "LLVMBuildOr"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildXor =
      _import "LLVMBuildXor"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, string) -> LLVMValueRef

  (*
  val LLVMBuildBinOp =
      _import "LLVMBuildBinOp"
      : __attribute__((no_callback))
        (LLVMBuilderRef, Opcode, LLVMValueRef, LLVMValueRef, string)
        -> LLVMValueRef
  *)

  val LLVMBuildNeg =
      _import "LLVMBuildNeg"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNSWNeg =
      _import "LLVMBuildNSWNeg"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNUWNeg =
      _import "LLVMBuildNUWNeg"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildFNeg =
      _import "LLVMBuildFNeg"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildNot =
      _import "LLVMBuildNot"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildAlloca =
      _import "LLVMBuildAlloca"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildLoad =
      _import "LLVMBuildLoad"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, string) -> LLVMValueRef

  val LLVMBuildStore =
      _import "LLVMBuildStore"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef) -> LLVMValueRef

  val LLVMBuildGEP =
      _import "LLVMBuildGEP"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef vector, word, string)
        -> LLVMValueRef

  val LLVMBuildInBoundsGEP =
      _import "LLVMBuildInBoundsGEP"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef vector, word, string)
        -> LLVMValueRef

  val LLVMBuildStructGEP =
      _import "LLVMBuildStructGEP"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, word, string) -> LLVMValueRef

  val LLVMBuildExtractValue =
      _import "LLVMBuildExtractValue"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, word, string) -> LLVMValueRef

  val LLVMBuildTrunc =
      _import "LLVMBuildTrunc"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildZExt =
      _import "LLVMBuildZExt"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildSExt =
      _import "LLVMBuildSExt"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildFPToUI =
      _import "LLVMBuildFPToUI"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildFPToSI =
      _import "LLVMBuildFPToSI"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildUIToFP =
      _import "LLVMBuildUIToFP"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildSIToFP =
      _import "LLVMBuildSIToFP"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildFPTrunc =
      _import "LLVMBuildFPTrunc"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildFPExt =
      _import "LLVMBuildFPExt"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildPtrToInt =
      _import "LLVMBuildPtrToInt"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildIntToPtr =
      _import "LLVMBuildIntToPtr"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildBitCast =
      _import "LLVMBuildBitCast"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildZExtOrBitCast =
      _import "LLVMBuildZExtOrBitCast"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildSExtOrBitCast =
      _import "LLVMBuildSExtOrBitCast"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildTruncOrBitCast =
      _import "LLVMBuildTruncOrBitCast"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMTypeRef, string) -> LLVMValueRef

  val LLVMBuildICmp =
      _import "LLVMBuildICmp"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMIntPredicate, LLVMValueRef, LLVMValueRef, string)
        -> LLVMValueRef

  val LLVMBuildFCmp =
      _import "LLVMBuildFCmp"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMRealPredicate, LLVMValueRef, LLVMValueRef, string)
        -> LLVMValueRef

  val LLVMBuildPhi =
      _import "LLVMBuildPhi"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMTypeRef, string) -> LLVMValueRef_Phi

  val LLVMAddIncoming =
      _import "LLVMAddIncoming"
      : __attribute__((no_callback))
        (LLVMValueRef_Phi, LLVMValueRef vector, LLVMBasicBlockRef vector, word)
        -> ()

  val LLVMBuildLandingPad =
      _import "LLVMBuildLandingPad"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMTypeRef, LLVMValueRef, word, string)
        -> LLVMValueRef_LandingPad

  val LLVMAddClause =
      _import "LLVMAddClause"
      : __attribute__((no_callback))
        (LLVMValueRef_LandingPad, LLVMValueRef) -> ()

  val LLVMSetCleanup =
      _import "LLVMSetCleanup"
      : __attribute__((no_callback))
        (LLVMValueRef_LandingPad, LLVMBool) -> ()

  val LLVMBuildInvoke =
      _import "LLVMBuildInvoke"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef vector, word,
         LLVMBasicBlockRef, LLVMBasicBlockRef, string)
        -> LLVMValueRef_Call

  val LLVMBuildCall =
      _import "LLVMBuildCall"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef vector, word, string)
        -> LLVMValueRef_Call

  val LLVMSetTailCall =
      _import "LLVMSetTailCall"
      : __attribute__((no_callback))
        (LLVMValueRef_Call, LLVMBool) -> ()

  val LLVMSetInstructionCallConv =
      _import "LLVMSetInstructionCallConv"
      : __attribute__((no_callback))
        (LLVMValueRef_Call, LLVMCallConv) -> ()

  val LLVMAddInstrAttribute =
      _import "LLVMAddInstrAttribute"
      : __attribute__((no_callback))
        (LLVMValueRef_Call, word, LLVMAttribute) -> ()

  val LLVMAddInstrAttribute =
      fn (call, index, attrs) =>
         LLVMAddInstrAttribute (call, index, foldl Word.orb 0w0 attrs)

  (*
  val LLVMBuildSelect =
      _import "LLVMBuildSelect"
      : __attribute__((no_callback))
        (LLVMBuilderRef, LLVMValueRef, LLVMValueRef, LLVMValueRef,
                 string) -> LLVMValueRef
  *)

  (* linker *)

  type LLVMLinkerMode = int
  val LLVMLinkerDestroySource : LLVMLinkerMode = 0
  val LLVMLinkerPreserveSource : LLVMLinkerMode = 1

  val LLVMLinkModules =
      _import "LLVMLinkModules"
      : __attribute__((no_callback))
        (LLVMModuleRef, LLVMModuleRef, LLVMLinkerMode, char ptr ref)
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

  type SizeLevel = word
  val SizeDefault : SizeLevel = 0w0
  val SizeSmall : SizeLevel = 0w1
  val SizeVerySmall : SizeLevel = 0w2

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

  type FileType = word
  val NullFile : FileType = 0w0
  val AssemblyFile : FileType = 0w1
  val ObjectFile : FileType = 0w2
  val IRFile : FileType = 0w3
  val BitcodeFile : FileType = 0w4

  type compile_options =
      {arch : string,
       cpu : string,
       attrs : string list,
       optLevel : OptLevel,
       sizeLevel : SizeLevel,
       relocModel : RelocModel,
       codeModel : CodeModel}

  val sml_llvm_compile_c =
      _import "sml_llvm_compile_c"
      : (LLVMModuleRef, string, string, string vector, int, OptLevel, SizeLevel,
         RelocModel, CodeModel, FileType, string, char ptr ref) -> LLVMBool

  fun compile {arch, cpu, attrs, optLevel, sizeLevel, relocModel, codeModel}
              (module, fileType, outputFilename) =
      let
        val retMsg = ref (Pointer.NULL ())
        val attrs = Vector.fromList attrs
        val ret = sml_llvm_compile_c (module, arch, cpu,
                                      attrs, Vector.length attrs,
                                      optLevel, sizeLevel,
                                      relocModel, codeModel, fileType,
                                      outputFilename, retMsg)
      in
        if ret = 0 then () else raise LLVMError (importMessage (!retMsg))
      end

(*
  (* target *)

  type LLVMTargetRef = unit ptr

  val LLVMGetFirstTarget =
      _import "LLVMGetFirstTarget"
      : __attribute__((no_callback))
        () -> LLVMTargetRef

  val LLVMGetNextTarget =
      _import "LLVMGetNextTarget"
      : __attribute__((no_callback))
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
      : __attribute__((no_callback))
        LLVMTargetRef -> char ptr

  val LLVMGetTargetName =
      fn x => sml_str_new (LLVMGetTargetName x)

  val LLVMGetTargetDescription =
      _import "LLVMGetTargetDescription"
      : __attribute__((no_callback))
        LLVMTargetRef -> char ptr

  val LLVMGetTargetDescription =
      fn x => sml_str_new (LLVMGetTargetDescription x)

  val LLVMTargetHasJIT =
      _import "LLVMTargetHasJIT"
      : __attribute__((no_callback))
        LLVMTargetRef -> LLVMBool

  val LLVMTargetHasTargetMachine =
      _import "LLVMTargetHasTargetMachine"
      : __attribute__((no_callback))
        LLVMTargetRef -> LLVMBool

  val LLVMTargetHasAsmBackend =
      _import "LLVMTargetHasAsmBackend"
      : __attribute__((no_callback))
        LLVMTargetRef -> LLVMBool

  val sml_llvm_lookup_target =
      _import "sml_llvm_lookup_target"
      : __attribute__((no_callback))
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
      : __attribute__((no_callback))
        (LLVMTargetRef, string, string, string, LLVMCodeGenOptLevel,
         LLVMRelocMode, LLVMCodeModel) -> LLVMTargetMachineRef

  val LLVMDisposeTargetMachine =
      _import "LLVMDisposeTargetMachine"
      : __attribute__((no_callback))
        LLVMTargetMachineRef -> ()

  val LLVMTargetMachineEmitToFile =
      _import "LLVMTargetMachineEmitToFile"
      : __attribute__((no_callback))
        (LLVMTargetMachineRef, LLVMModuleRef, string, LLVMCodeGenFileType,
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
      : __attribute__((no_callback))
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
      : __attribute__((no_callback))
        (LLVMExecutionEngineRef ref, LLVMModuleRef, char ptr ref) -> LLVMBool

  val LLVMCreateJITCompilerForModule =
      _import "LLVMCreateJITCompilerForModule"
      : __attribute__((no_callback))
        (LLVMExecutionEngineRef ref, LLVMModuleRef, word, char ptr ref)
        -> LLVMBool
*)

  val LLVMDisposeExecutionEngine =
      _import "LLVMDisposeExecutionEngine"
      : __attribute__((no_callback))
        LLVMExecutionEngineRef -> ()

  val LLVMAddModule =
      _import "LLVMAddModule"
      : __attribute__((no_callback))
        (LLVMExecutionEngineRef, LLVMModuleRef) -> ()

  val LLVMFindFunction =
      _import "LLVMFindFunction"
      : __attribute__((no_callback))
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
