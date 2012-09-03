(**
 * switches to control compiler's behavior.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: Control.sml,v 1.23 2006/03/02 12:43:31 bochao Exp $
 *)
structure Control = 
struct

  (***************************************************************************)

  datatype switch =
           IntSwitch of int ref
         | BoolSwitch of bool ref

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
        val ppgenParameter =
            {spaceString = " ", newlineString = "\n", columns = !printWidth}
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
  val limitOfInlineCaseBranch = ref 10

  val doUncurryingOptimizeInMachCompile = ref true

  val pageSizeOfGlobalArray = ref 1024

  (****************************************)
  (* switches to runtime parameter *)

  val VMHeapSize = ref 4096000

  val VMStackSize = ref 4096000

  (****************************************)
  (* internal switches for development *)

  (** true if trace of compilation should be printed. *)
  val switchTrace = ref false

  val printSource = ref false
  val printPL = ref false
  val printUC = ref false
  val printTP = ref false
  val printTFP = ref false
  val printRC = ref false
  val printTL = ref false
  val printBUC = ref false
  val printAN = ref false
  val printLS = ref false
  val printIS = ref false

  val checkType = ref true

  (** true if every diagnosis should be printed. *)
  val printDiagnosis = ref true

  val doProfile = ref false

  (** If true, then in separate compilation mode 
   *)
  val doSeparateCompilation = ref false

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
    ("doSelfRecursiveCallOptimize", BoolSwitch doSelfRecursiveCallOptimize),
    ("doTailCallOptimize", BoolSwitch doTailCallOptimize),
    ("doUncurryOptimization", BoolSwitch doUncurryOptimization),
    ("doUncurryingOptimizeInMachCompile", BoolSwitch doUncurryingOptimizeInMachCompile),
    ("enableUnboxedFloat", BoolSwitch enableUnboxedFloat),
    ("generateDebugInfo", BoolSwitch generateDebugInfo),
    ("generateExnHistory", BoolSwitch generateExnHistory),
    ("limitOfBlockFields", IntSwitch limitOfBlockFields),
    ("limitOfInlineCaseBranch", IntSwitch limitOfInlineCaseBranch),
    ("pageSizeOfGlobalArray", IntSwitch pageSizeOfGlobalArray),
    ("printAN", BoolSwitch printAN),
    ("printBUC", BoolSwitch printBUC),
    ("printBinds", BoolSwitch printBinds),
    ("printDiagnosis", BoolSwitch printDiagnosis),
    ("printIS", BoolSwitch printIS),
    ("printLS", BoolSwitch printLS),
    ("printPL", BoolSwitch printPL),
    ("printRC", BoolSwitch printRC),
    ("printSource", BoolSwitch printSource),
    ("printTFP", BoolSwitch printTFP),
    ("printTL", BoolSwitch printTL),
    ("printTP", BoolSwitch printTP),
    ("printUC", BoolSwitch printUC),
    ("printWarning", BoolSwitch printWarning),
    ("printWidth", IntSwitch printWidth),
    ("skipPrinter", BoolSwitch skipPrinter),
    ("switchTrace", BoolSwitch switchTrace),
    ("VMHeapSize", IntSwitch VMHeapSize),
    ("VMStackSize", IntSwitch VMStackSize)
          ]

  (****************************************)
  (* utility *)

  fun switchToString (IntSwitch intRef) = Int.toString (!intRef)
    | switchToString (BoolSwitch boolRef) = if !boolRef then "yes" else "no"

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
