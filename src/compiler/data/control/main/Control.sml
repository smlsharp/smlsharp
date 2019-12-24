(**
 * switches to control compiler's behavior.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @version $Id: Control.ppg,v 1.28 2008/03/11 08:53:54 katsu Exp $
 *)
structure Control =
struct

  (***************************************************************************)

  datatype switch =
           IntSwitch of int ref
         | BoolSwitch of bool ref
         | StringSwitch of string ref

  type switchTable = (string * string * switch) list

  (***************************************************************************)
  (* switches *)

  (* switches for interactive printing *)
  val printWidth = ref 80
  val printMaxDepth = ref 200
  val printMaxOverloadInstances = ref 4

  val printMaxNestLevel = ref 5
  val printMaxExnNestLevel = ref 1
  val importAllExceptions = ref true
  val generateExnMessage = ref false

  (****************************************)
  (* internal compiler mode (user cannot specify them by -x option) *)

  val interactiveMode = ref false

  (****************************************)
  (* switches to control informations reported to user *)

  (* print what compiler does *)
  val doProfile = ref false
  val profileMaxPhases = ref 5
  val printTimer = ref false
  val printCommand = ref false
  val traceFileLoad = ref false

  (* print intermediate representations *)
  val printParse = ref false
  val printLoadFile = ref false
  val printDependency = ref false
  val printElab = ref false
  val printNameEval = ref false
  val printTypeInf = ref false
  val printPrinterGen = ref false
  val printUncurryOpt = ref false
  val printPolyTyElim = ref false
  val verbosePolyTyElim = ref 0
  val printTCOpt = ref false
  val printRCOpt = ref false
  val printVALRECOpt = ref false
  val printFundeclElab = ref false
  val printMatchCompile = ref false
  val printTypedElaboration = ref false
  val printReifyTopEnv = ref false
  val printFFICompile = ref false
  val printRecordCompile = ref false
  val printDatatypeCompile = ref false
  val printStaticAnalysis = ref false
  val printSystemDecls = ref false
  val printRecordUnboxing = ref false
  val printBitmapCompile = ref false
  val printBitmapANormal = ref false
  val printBitmapANormalReorder = ref false
  val printClosureConversion = ref false
  val printCConvCompile = ref false
  val printANormal = ref false
  val printANormalOpt = ref false
  val printStaticAlloc = ref false
  val printAIGeneration = ref false
  val printRTLSelect = ref false
  val printRTLStabilize = ref false
  val printRTLRename = ref false
  val printRTLColoring = ref false
  val printRTLFrame = ref false
  val printRTLEmit = ref false
  val printInsertCheckGC = ref false
  val printStackAllocation = ref false
  val printMachineCodeGen = ref false
  val printLLVMGen = ref false
  val printLLVMEmit = ref false
  val printGenerateMain = ref false

  (** true if detailed type information should be printed. *)
  val printWithType = ref false
  val printEnvs = ref true

  val printWarning = ref true
  val printDiagnosis = ref true

  (* control toplevel *)
  val checkType = ref false
  val doBitmapANormalReorder = ref true
  val doRecordUnboxing = ref true
  val doUncurryOptimization = ref true
  val doPolyTyElimination = ref true
  val doTCOptimization = ref true
  val doRCOptimization = ref false
  (** true if no formatter is generated and no binding information is printed *)
  val skipPrinter = ref false

  (* switches for parser *)
  val allow8bitId = ref false

  (* switches for elaboration *)
  val doListExpressionOptimization = ref true

  (* switches for match compilation *)
  val doUncurryingOptimizeInMatchCompile = ref true

  (** If true, the match compiler compiles case branches by local code,
   * rather than translates each case branch into a function.
   * this overrides doInlineCaseBranch. *)
  val doLocalizeCaseBranch = ref true

  (** If true, the match compiler tries inlining case branch, rather than
   * translates each case branch into a function. *)
  val doInlineCaseBranch = ref true

  (** if a brach size exceed this limit then a closure will be created
   * otherwise the expression is copied to every activation point. *)
  val limitOfInlineCaseBranch = ref 15

  (* switches for backend *)
  val debugCodeGen = ref false
  val doFrameCompaction = ref true
  val doRegisterCoalescing = ref true
  val enableUnboxedFloat = ref true
  val insertCheckGC = ref true
  val useMustTail = ref false
  val branchByCConvRigidity = ref false

  (****************************************)
  (* switch table for -x options *)

  val switchTable : switchTable =
      [
        ("profileMaxPhases", "number of phases to be displayed (default 5)",
         IntSwitch profileMaxPhases),
        ("printWidth", "print width (default 80)",
         IntSwitch printWidth),
        ("printMaxDepth", "maximum depth in printing lists and arrays (default 200)",
         IntSwitch printMaxDepth),
        ("printMaxOverloadInstances", "maximum overloaded instances to be printed (default 4)",
         IntSwitch printMaxOverloadInstances),
        ("printMaxNestLevel", "maximum depth in printing recursive datatypes (default 5)",
         IntSwitch printMaxNestLevel),
        ("printMaxExnNestLevel", "maximum depth in printing recursive exceptions",
         IntSwitch printMaxExnNestLevel),
        ("importAllExceptions", "import all exceptions for printing",
         BoolSwitch importAllExceptions),
        ("generateExnMessage", "generate exnMessage in ReifiedTerm at each interactive sesseion",
         BoolSwitch generateExnMessage),
        ("8bitId", "allow 8 bit chars for identifier",
         BoolSwitch allow8bitId),
        ("checkType", "do type checking of intermediate representations",
         BoolSwitch checkType),
        ("debugCodeGen", "switch for backend",
         BoolSwitch debugCodeGen),
        ("debugPrint", "print debug messages",
         BoolSwitch Bug.debugPrint),
        ("doBitmapANormalReorder", "turn on BitmapANormal reordering",
         BoolSwitch doBitmapANormalReorder),
        ("doFrameCompaction", "turn on stack frame compaction",
         BoolSwitch doFrameCompaction),
        ("doLocalizeCaseBranch", "switch for match compilation",
         BoolSwitch doLocalizeCaseBranch),
        ("doInlineCaseBranch", "switch for match compilation",
         BoolSwitch doInlineCaseBranch),
        ("doListExpressionOptimization", "switch for elaboration",
         BoolSwitch doListExpressionOptimization),
        ("doPolyTyElimination", "turn on polyty elimination",
         BoolSwitch doPolyTyElimination),
        ("doProfile", "print profiling information at exit",
         BoolSwitch doProfile),
        ("doRCOptimization", "turn on RC optimization",
         BoolSwitch doRCOptimization),
        ("doRecordUnboxing", "turn on record unboxing",
         BoolSwitch doRecordUnboxing),
        ("doRegisterCoalescing", "turn on register coalescing",
         BoolSwitch doRegisterCoalescing),
        ("doTCOptimization", "turn on TC optimization",
         BoolSwitch doTCOptimization),
        ("doUncurryOptimization", "turn on uncurry optimization",
         BoolSwitch doUncurryOptimization),
        ("doUncurryingOptimizeInMatchCompile", "switch for match compilation",
         BoolSwitch doUncurryingOptimizeInMatchCompile),
        ("enableUnboxedFloat", "enable unboxed floats",
         BoolSwitch enableUnboxedFloat),
        ("insertCheckGC", "switch for backend",
         BoolSwitch insertCheckGC),
        ("limitOfInlineCaseBranch", "parameter for match compilation",
         IntSwitch limitOfInlineCaseBranch),
        ("printParse", "print result of Parse",
         BoolSwitch printParse),
        ("printLoadFile", "print result of LoadFile",
         BoolSwitch printLoadFile),
        ("printDependency", "print file dependency generated by LoadFile",
         BoolSwitch printDependency),
        ("printElab", "print result of Elaboration",
         BoolSwitch printElab),
        ("printNameEval", "print result of NameEval",
         BoolSwitch printNameEval),
        ("printTypeInf", "print result of InferTypes",
         BoolSwitch printTypeInf),
        ("printPrinterGen", "print result of PrinterGeneration",
         BoolSwitch printPrinterGen),
        ("printPolyTyElim", "print result of PolyTyElimination",
         BoolSwitch printPolyTyElim),
        ("verbosePolyTyElim", "print intermediates of PolyTyElimination",
         IntSwitch verbosePolyTyElim),
        ("printUncurryOpt", "print result of UncurryOptimization",
         BoolSwitch printUncurryOpt),
        ("printTCOpt", "print result of TCOptimization",
         BoolSwitch printTCOpt),
        ("printRCOpt", "print result of RCOptimization",
         BoolSwitch printRCOpt),
        ("printVALRECOpt", "print result of VALRECOptimization",
         BoolSwitch printVALRECOpt),
        ("printFundeclElab", "print result of FundeclElaboration",
         BoolSwitch printFundeclElab),
        ("printMatchCompile", "print result of MatchCompile",
         BoolSwitch printMatchCompile),
        ("printTypedElaboration", "print result of TypedElaboration",
         BoolSwitch printTypedElaboration),
        ("printReifyTopEnv", "print result of ReifyTopEnv",
         BoolSwitch printReifyTopEnv),
        ("printFFICompile", "print result of FFICompilation",
         BoolSwitch printFFICompile),
        ("printRecordCompile", "print result of RecordCompile",
         BoolSwitch printRecordCompile),
        ("printDatatypeCompile", "print result of DatatypeCompilation",
         BoolSwitch printDatatypeCompile),
        ("printStaticAnalysis", "print result of StaticAnalysis",
         BoolSwitch printStaticAnalysis),
        ("printSystemDecls", "print system declarations ",
         BoolSwitch printSystemDecls),
        ("printRecordUnboxing", "print result of RecordUnboxing",
         BoolSwitch printRecordUnboxing),
        ("printBitmapCompile", "print result of BitmapCompilation",
         BoolSwitch printBitmapCompile),
        ("printBitmapANormal", "print result of BitmapANormalization",
         BoolSwitch printBitmapANormal),
        ("printBitmapANormalReorder", "print result of BitmapANormalReorder",
         BoolSwitch printBitmapANormalReorder),
        ("printClosureConversion", "print result of ClosureConversion",
         BoolSwitch printClosureConversion),
        ("printCConvCompile", "print result of CConvCompile",
         BoolSwitch printCConvCompile),
        ("printANormal", "print result of ToYAANormal",
         BoolSwitch printANormal),
        ("printANormalOpt", "print result of ANormalOptimization",
         BoolSwitch printANormalOpt),
        ("printStaticAlloc", "print result of StaticAllocation",
         BoolSwitch printStaticAlloc),
        ("printAIGeneration", "print result of AIGeneration",
         BoolSwitch printAIGeneration),
        ("printRTLSelect", "print result of RTLSelect",
         BoolSwitch printRTLSelect),
        ("printRTLStabilize", "print result of RTLStabilize",
         BoolSwitch printRTLStabilize),
        ("printRTLRename", "print result of RTLRename",
         BoolSwitch printRTLRename),
        ("printRTLColoring", "print result of RTLColoring",
         BoolSwitch printRTLColoring),
        ("printRTLFrame", "print result of RTLFrame",
         BoolSwitch printRTLFrame),
        ("printRTLEmit", "print result of RTLEmit",
         BoolSwitch printRTLEmit),
        ("printInsertCheckGC", "print result of insertCheckGC",
         BoolSwitch printInsertCheckGC),
        ("printStackAllocation", "print result of StackAllocaiton",
         BoolSwitch printStackAllocation),
        ("printMachineCodeGen", "print result of MachineCodeGen",
         BoolSwitch printMachineCodeGen),
        ("printLLVMGen", "print result of LLVMGen",
         BoolSwitch printLLVMGen),
        ("printLLVMEmit", "print result of LLVMEmit",
         BoolSwitch printLLVMEmit),
        ("printGenerateMain", "print the result of GenerateMain",
         BoolSwitch printGenerateMain),
        ("printCommand", "print external commands invoked by compiler",
         BoolSwitch printCommand),
        ("printDiagnosis", "show internal diagnosis messages",
         BoolSwitch printDiagnosis),
        ("printInfo", "show internal informative messages",
         BoolSwitch Bug.printInfo),
        ("printTimer", "print when every compile phase begins/ends",
         BoolSwitch printTimer),
        ("printWarning", "show warning messages",
         BoolSwitch printWarning),
        ("printWithType", "print intermediate representations in detail",
         BoolSwitch printWithType),
        ("printEnvs", "print SEnv.map and IEnv.map)",
         BoolSwitch printEnvs),
        ("skipPrinter", "skip value printer generation",
         BoolSwitch skipPrinter),
        ("traceFileLoad", "print filenames loaded by compiler",
         BoolSwitch traceFileLoad),
        ("useMustTail", "use musttail instead of tail as much as possible",
         BoolSwitch useMustTail),
        ("branchByCConvRigidity", "insert branch code for calling convention rigidity",
         BoolSwitch branchByCConvRigidity)
      ]

  fun switchToString (IntSwitch intRef) = Int.toString (!intRef)
    | switchToString (BoolSwitch boolRef) = if !boolRef then "yes" else "no"
    | switchToString (StringSwitch stringRef) = !stringRef

  fun interpretControlOption (name, switch, value) =
      (
        case switch of
          IntSwitch intRef =>
          (case Int.fromString value of
             SOME int => intRef := int
           | NONE => raise Fail (name ^ " should be number."))
        | BoolSwitch boolRef =>
          (case value of
             "yes" => boolRef := true
           | "no" => boolRef := false
           | _ => raise Fail (name ^ " should be yes or no."))
        | StringSwitch stringRef => stringRef := value;
        if !printCommand
        then print ("set control option: " ^ name ^ " = "
                    ^ switchToString switch ^ "\n")
        else ()
      )

end
