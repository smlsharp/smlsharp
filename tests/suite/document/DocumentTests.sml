(**
 * document based test
 *
 * @copyright (c) 2017, Tohoku University.
 *)

structure DocumentTests =
struct
open SMLUnit.Test SMLUnit.Assert Compiler
structure N = NameEvalError
structure M = MatchError
structure T = TypeInferenceError
structure C = ConstantError

  fun testExec name srcfile objfiles =
      let
        val srcfilePath = "document/" ^ srcfile
        val objfilePaths = map (fn file => "document/" ^ file) objfiles
        fun exec () = execute (link srcfilePath (compile objfilePaths))
      in
        Test (name, exec)
      end

  fun testExecError name srcfile objfiles errorFn =
      let
        val srcfilePath = "document/" ^ srcfile
        val objfilePaths = map (fn file => "document/" ^ file) objfiles
        fun exec () = (execute (link srcfilePath (compile objfilePaths));
                       fail "must cause a compile error")
      in
        Test (name, fn () => errorFn exec)
      end
  
  val tests = TestList [
    (* interface file test *)
    testExec
      "ProvideVal" 
      "ProvideValMain.smi" 
      ["ProvideVal.sml", "ProvideValMain.sml"],
    testExec
      "ProvideType" 
      "ProvideTypeMain.smi" 
      ["ProvideType.sml", "ProvideTypeMain.sml"],
    testExec
      "ProvideTypeRepAtomic" 
      "ProvideTypeRepAtomicMain.smi" 
      ["ProvideTypeRepAtomic.sml", "ProvideTypeRepAtomicMain.sml"],
    testExec
      "ProvideTypeRepContag" 
      "ProvideTypeRepContagMain.smi" 
      ["ProvideTypeRepContag.sml", "ProvideTypeRepContagMain.sml"],
    testExec
      "ProvideTypeRepBoxed" 
      "ProvideTypeRepBoxedMain.smi" 
      ["ProvideTypeRepBoxed.sml", "ProvideTypeRepBoxedMain.sml"],
    testExec
      "ProvideDatatype" 
      "ProvideDatatypeMain.smi" 
      ["ProvideDatatype.sml", "ProvideDatatypeMain.sml"],
    testExec
      "ProvideException" 
      "ProvideExceptionMain.smi" 
      ["ProvideException.sml", "ProvideExceptionMain.sml"],
    testExec
      "ProvideStr" 
      "ProvideStrMain.smi" 
      ["ProvideStr.sml", "ProvideStrMain.sml"],
    testExec
      "Require" 
      "RequireMain.smi" 
      ["Require.sml", "RequireMain.sml"],
    testExec
      "RequireSigFileMain" 
      "RequireSigFileMain.smi" 
      ["RequireSigFile.sml", "RequireSigFileMain.sml"],
    testExec
      "Interface" 
      "InterfaceMain.smi" 
      ["Interface.sml", "InterfaceMain.sml"],
    testExec
      "ReplicationDecl" 
      "ReplicationDeclMain.smi" 
      ["ReplicationDecl1.sml",
       "ReplicationDecl2.sml",
       "ReplicationDeclMain.sml"],
    testExec
      "ReplicationDatatypeDecl" 
      "ReplicationDatatypeDeclMain.smi" 
      ["ReplicationDatatypeDecl1.sml",
       "ReplicationDatatypeDecl2.sml",
       "ReplicationDatatypeDeclMain.sml"],

    testExecError 
      "RequireLocal" 
      "RequireLocalMain.smi" 
      ["RequireLocal.sml", "RequireLocalMain.sml"]
      (fn exec => exec ()
          handle CompileError (s, [(_, _, N.ProvideUndefinedID _)]) => ()),

(* これは dummy typpe warning で正しい？
    (* expression test *)
    testExec
      "ExpressionFieldSelectorDummyType" 
      "ExpressionFieldSelectorDummyType.smi" 
      ["ExpressionFieldSelectorDummyType.sml"],
*)

    testExec
      "LiteralMultibyteChar" 
      "LiteralMultibyteChar.smi" 
      ["LiteralMultibyteChar.sml"],
    testExec
      "FunDeclRecTyped" 
      "FunDeclRecTyped.smi" 
      ["FunDeclRecTyped.sml"],

    testExecError
      "CaseOfZeroAndMinusZero" 
      "CaseOfZeroAndMinusZero.smi" 
      ["CaseOfZeroAndMinusZero.sml"]
      (fn exec => exec ()
          handle CompileError (s, [(_, _, M.MatchError _)]) => ()),
    testExecError
      "CaseOfDecAndHexInt" 
      "CaseOfDecAndHexInt.smi" 
      ["CaseOfDecAndHexInt.sml"]
      (fn exec => exec ()
          handle CompileError (s, [(_, _, M.MatchError _)]) => ()),
    testExecError
      "CaseOfDecAndHexWord" 
      "CaseOfDecAndHexWord.smi" 
      ["CaseOfDecAndHexWord.sml"]
      (fn exec => exec ()
          handle CompileError (s, [(_, _, M.MatchError _)]) => ()),
(* 確かにおかしいが、一度エラーが起こった後のエラーは、不正確でありうるので、
   当面対処せず。
    testExecError
      "TypeErrorOutput" 
      "TypeErrorOutput.smi" 
      ["TypeErrorOutput.sml"]
      (fn exec => exec ()
          handle CompileError (s, [(_, _, T.TypeAnnotationNotAgree _)]) => ()),
*)
    testExecError
      "FunDeclDatatypePattern" 
      "FunDeclDatatypePattern.smi" 
      ["FunDeclDatatypePattern.sml"]
      (fn exec => exec ()
          handle CompileError (s, [(_, _, T.TypeAnnotationNotAgree _)]) => ()),
    testExecError
      "LiteralLargeConstantError" 
      "LiteralLargeConstantError.smi" 
      ["LiteralLargeConstantError.sml"]
      (fn exec => exec ()
          handle CompileError (s, [(_, _, C.TooLargeConstant)]) => ())
  ]

end
