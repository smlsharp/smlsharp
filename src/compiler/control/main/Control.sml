(**
 * switches to control compiler's behavior.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: Control.sml,v 1.45 2007/06/20 03:17:25 ohori Exp $
 *)
structure Control = 
struct

  (****************************************)
  (* switches to control conpilation pahse *)
  val Elab      = 2
  val FunOpt    = 3
  val TVar      = 4
  val TyInf     = 5
  val LayoutOpt = 6
  val Print     = 7
  val Module    = 8
  val MatchComp = 9
  val Lambda    = 10
  val Static    = 11
  val Unbox     = 12
  val RefElim   = 13
  val DeadCode  = 14
  val Cluster   = 15
  val RBUComp   = 16
  val Anormal   = 17
  val SI        = 18
  val SIOpt     = 19
  val Assem     = 20
  val Code      = 21
  val Run       = 22

  val doUntil = ref Run

  fun doPhase current = current <=  !doUntil

  (***************************************************************************)

  datatype switch =
           IntSwitch of int ref
         | BoolSwitch of bool ref
         | StringSwitch of string ref

  type switchTable = switch SEnv.map

  (***************************************************************************)

  (**
   * indicates a bug of compiler implementation.
   *)
  exception Bug = UserError.Bug

  exception BugWithLoc = UserError.BugWithLoc

  (***************************************************************************)
  (* switches *)

  val printWidth = ref 80
  fun prettyPrint expressions =
      let
        val ppgenParameter = [SMLFormat.Columns (!printWidth)]
      in
        SMLFormat.prettyPrint ppgenParameter expressions
      end

  (****************************************)
  (* switches to control informations reported to user *)

  (** true if binding informations are to be printed. *)
  val printBinds = ref true

  (** true if every warning should be printed. *)
  val printWarning = ref true

  (** true if no formatter is generated and no binding information is printed.
   *)
  val skipPrinter = ref false

  (** If true, information which is required to implement the exnHistory is
   * embedded in the output Executable. *)
  val generateExnHistory = ref true

  (** If true, information for debugger is embedded in the output Executable.
   *)
  val generateDebugInfo = ref false

  (****************************************)
  (* switches to control optimizations *)

  (* list expression optimization *)
  val doListExpressionOptimization = ref true

  (*
   * Ohori: Dec 17, 2006.
     This trun on the large FFI switch in VirtualMachine.cc
     THIS MUST BE ON TOGETHER WITH
       #define LARGEFFISWITCH
    in VirtualMachine.cc
   *)
  val LARGEFFISWITCH = ref true

  val doUncurryOptimization = ref true

  val enableUnboxedFloat = ref true
  val alignRecord = ref true

  val doSymbolicInstructionsOptimization = ref true
  val doConstantFolding = ref true
  val doFunctionCallSpecialization = ref true
  val limitOfBlockFields = ref 15

  val doTailCallOptimize = ref true

  (** If true, recursive call is optimized
   *)
  val doRecursiveCallOptimize = ref true

  (** If flase, self recursive call is compiled in the same way as non-self
   * recursive call.
   * If both of doRecursiveCallOptimize and this switch are true,
   * self-recursive call is compiled into a more specialized instruction than
   * an instruction for non-self recursive call. *)
  val doSelfRecursiveCallOptimize = ref true

  (** If true, the match compiler tries inlining case branch, rather than
   * translates each case branch into a function.
   *)
  val doInlineCaseBranch = ref true

  (**
   * if a brach size exceed this limit then a closure will be created
   * otherwise the expression is copied to every activation point.
   *)
  val limitOfInlineCaseBranch = ref 15

  val doUncurryingOptimizeInMachCompile = ref true

  val doRecordUnboxing = ref true

  (** If true, the compiler will try to optimizing multiple value terms
   *)
  val doMultipleValueOptimization = ref true

  val doCommonSubexpressionElimination = ref true

  val doRepresentationAnalysis = ref true

  (** If true, the compiler will try to remove all dead code
   *  in MultipleValueCalc
   *)
  val doUselessCodeElimination = ref true

  val doStackReallocation = ref true

  val pageSizeOfGlobalArray = ref 1024

  (****************************************)
  (* switches to runtime parameter *)

  val runtimePath = ref Configuration.RuntimePath

  val VMHeapSize = ref 4096000

(*
  val VMStackSize = ref 4096000
*)
  val VMStackSize = ref 4096000
  (****************************************)
  (* internal switches for development *)

  (** true if trace of compilation should be printed. *)
  val switchTrace = ref false

  val traceFileLoad = ref false
  val tracePrelude = ref false
  val printSource = ref false
  val printPL = ref false
  val printUC = ref false
  val printTP = ref false
  val printTFP = ref false
  val printRC = ref false
  val printTL = ref false
  val printAC = ref false
  val printMV = ref false
  val printCC = ref false
  val printRBU = ref false
  val printAN =  ref false
  val printIL =  ref false
  val printLS =  ref false
  val printIS =  ref false
  val printSR = ref false
  val checkType = ref true

  (** true if every diagnosis should be printed. *)
  val printDiagnosis = ref true

  val doProfile = ref false

  (* several switch for separate compilation *)
  val doCompileObj = ref false
  val doLinking = ref false

  (****************************************)
  (* other *)

  (** a string that SML# inserts at the head of output executable.
   *)
  val headerOfExecutable = ref ("#!" ^ Configuration.RuntimePath ^ "\n")

  (* true if the compiler should skip the shebang line of the argument source
   * file. *)
  val skipShebang = ref true

  (****************************************)

  (* MEMO: procedure to generate switches list.
   * (1) get signature of Control structure.
   *   - structure C = Control;
   * (2) copy and paste specifications of switches.
   *   ex.
   *     val alignRecord : bool ref
   *     val checkType : bool ref
   *     val doConstantPropagation : bool ref
   * (3) query-replace-regexp
   *    from:
   *       val \([^ ]*\) : \([^ ]*\) ref
   *    to:
   *       ("\1", \2Switch \1),
   * (4) replace
   *     boolSwitch ==> BoolSwitch
   *     intSwitch ==> IntSwitch
   *)

  val switchTable : switchTable =
      SEnv.fromList
          [
    ("alignRecord", BoolSwitch alignRecord),
    ("checkType", BoolSwitch checkType),
    ("doInlineCaseBranch", BoolSwitch doInlineCaseBranch),
    ("doProfile", BoolSwitch doProfile),
    ("doRecursiveCallOptimize", BoolSwitch doRecursiveCallOptimize),
    ("doSymbolicInstructionsOptimization", BoolSwitch doSymbolicInstructionsOptimization),
    ("doConstantFolding", BoolSwitch doConstantFolding),
    ("doFunctionCallSpecialization", BoolSwitch doFunctionCallSpecialization),
    ("doListExpressionOptimization", BoolSwitch doListExpressionOptimization),
    ("doSelfRecursiveCallOptimize", BoolSwitch doSelfRecursiveCallOptimize),
    ("doTailCallOptimize", BoolSwitch doTailCallOptimize),
    ("doUncurryOptimization", BoolSwitch doUncurryOptimization),
    ("doUncurryingOptimizeInMachCompile", BoolSwitch doUncurryingOptimizeInMachCompile),
    ("doRecordUnboxing", BoolSwitch doRecordUnboxing),
    ("doMultipleValueOptimization", BoolSwitch doMultipleValueOptimization),
    ("doCommonSubexpressionElimination", BoolSwitch doCommonSubexpressionElimination),
    ("doRepresentationAnalysis", BoolSwitch doRepresentationAnalysis),
    ("doUselessCodeElimination", BoolSwitch doUselessCodeElimination),
    ("enableUnboxedFloat", BoolSwitch enableUnboxedFloat),
    ("generateDebugInfo", BoolSwitch generateDebugInfo),
    ("generateExnHistory", BoolSwitch generateExnHistory),
    ("headerOfExecutable", StringSwitch headerOfExecutable),
    ("limitOfBlockFields", IntSwitch limitOfBlockFields),
    ("limitOfInlineCaseBranch", IntSwitch limitOfInlineCaseBranch),
    ("pageSizeOfGlobalArray", IntSwitch pageSizeOfGlobalArray),
    ("printAC", BoolSwitch printAC),
    ("printMV", BoolSwitch printMV),
    ("printCC", BoolSwitch printCC),
    ("printRBU", BoolSwitch printRBU),
    ("printAN", BoolSwitch printAN),
    ("printBinds", BoolSwitch printBinds),
    ("printDiagnosis", BoolSwitch printDiagnosis),
    ("printIL", BoolSwitch printIL),
    ("printIS", BoolSwitch printIS),
    ("printLS", BoolSwitch printLS),
    ("printSR", BoolSwitch printSR),
    ("doStackReallocation", BoolSwitch doStackReallocation),
    ("printPL", BoolSwitch printPL),
    ("printRC", BoolSwitch printRC),
    ("printSource", BoolSwitch printSource),
    ("printTFP", BoolSwitch printTFP),
    ("printTL", BoolSwitch printTL),
    ("printTP", BoolSwitch printTP),
    ("printUC", BoolSwitch printUC),
    ("printWarning", BoolSwitch printWarning),
    ("printWidth", IntSwitch printWidth),
    ("runtimePath", StringSwitch runtimePath),
    ("skipPrinter", BoolSwitch skipPrinter),
    ("skipShebang", BoolSwitch skipShebang),
    ("switchTrace", BoolSwitch switchTrace),
    ("traceFileLoad", BoolSwitch traceFileLoad),
    ("tracePrelude", BoolSwitch tracePrelude),
    ("VMHeapSize", IntSwitch VMHeapSize),
    ("VMStackSize", IntSwitch VMStackSize)
          ]

  (****************************************)
  (* utility *)

  fun switchToString (IntSwitch intRef) = Int.toString (!intRef)
    | switchToString (BoolSwitch boolRef) = if !boolRef then "yes" else "no"
    | switchToString (StringSwitch stringRef) = !stringRef

  fun interpretControlOption (name, switch, value) =
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
      | StringSwitch stringRef => stringRef := value

  (**
   * usage:
   * <pre>
   *   setControlOptions "IML" OS.Process.getEnv
   * </pre>
   *)
  fun setControlOptions prefix getValue =
      app
          (fn (name, switch) =>
              case getValue (prefix ^ name) of
                SOME value =>
                (
                  interpretControlOption (name, switch, value);
                  print
                      ("set control option: "
                       ^ name ^ " = "
                       ^ switchToString switch ^ "\n")
                )
              | NONE => ())
          (SEnv.listItemsi switchTable)

  (***************************************************************************)

end
