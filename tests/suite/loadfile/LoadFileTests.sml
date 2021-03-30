(**
 * tests for LoadFile
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

structure LoadFileTests =
struct

  fun formatDependencyOpt dependency =
      SMLFormat.prettyPrint
        nil
        (case dependency of
           NONE => nil
         | SOME dep =>
           InterfaceName.format_file_dependency dep
           @ [SMLFormat.FormatExpression.Newline])

  fun compile sml () =
      let
        val result = Compiler.checkCompileError (Compiler.compile' [sml])
        val dependency =
            case #dependency result of
              [dep] => dep
            | _ => raise Fail "non-single dependency for single sml file"
        val actual = formatDependencyOpt dependency
        val expect =
            CoreUtils.readTextFile
              (Filename.replaceSuffix "dep" (Compiler.dataFile sml))
      in
        SMLUnit.Assert.assertEqualString ("\n" ^ expect) ("\n" ^ actual)
      end

  fun link smi smls () =
      let
        val result = Compiler.checkCompileError
                       (Compiler.link' smi (Compiler.compile smls))
        val actual = formatDependencyOpt (#dependency result)
        val expect =
            CoreUtils.readTextFile
              (Filename.replaceSuffix "link" (Compiler.dataFile smi))
      in
        SMLUnit.Assert.assertEqualString ("\n" ^ expect) ("\n" ^ actual)
      end

  fun positiveTest smi smls =
      map (fn sml => SMLUnit.Test.Test (sml, compile sml)) smls
      @ [SMLUnit.Test.Test (smi, link smi smls)]

  fun negativeTest handler smls =
      [SMLUnit.Test.Test
         (hd smls,
          fn () => Compiler.raiseCompileError (#errors (Compiler.compile' smls))
                   handle e as Compiler.CompileError (_, [(_, _, error)]) =>
                          if handler error then () else raise e)]

  val tests =
      SMLUnit.Test.TestList (
        positiveTest
          "loadfile/000_interface.smi"
          ["loadfile/000_interface.sml"]
        @
        positiveTest
          "loadfile/001_interface2.smi"
          ["loadfile/001_interface.sml"]
        @
        positiveTest
          "loadfile/002_interface/002_interface.smi"
          ["loadfile/002_interface.sml"]
        @
        positiveTest
          "loadfile/003_interface/003_interface.smi"
          ["loadfile/003_interface.sml",
           "loadfile/003_interface2.sml"]
        @
        positiveTest
          "loadfile/010_require.smi"
          ["loadfile/010_require.sml",
           "loadfile/010_require2.sml",
           "loadfile/010_require3.sml"]
        @
        positiveTest
          "loadfile/011_require.smi"
          ["loadfile/011_require.sml",
           "loadfile/011_require2.sml",
           "loadfile/011_require3.sml"]
        @
        positiveTest
          "loadfile/012_require.smi"
          ["loadfile/012_require.sml",
           "loadfile/012_require2.sml",
           "loadfile/012_require3.sml",
           "loadfile/012_require4.sml"]
        @
        positiveTest
          "loadfile/013_require.smi"
          ["loadfile/013_require.sml",
           "loadfile/013_require/013_require2.sml",
           "loadfile/013_require/013_require3.sml"]
        @
        positiveTest
          "loadfile/020_local.smi"
          ["loadfile/020_local.sml",
           "loadfile/020_local2.sml"]
        @
        positiveTest
          "loadfile/021_local.smi"
          ["loadfile/021_local.sml",
           "loadfile/021_local2.sml",
           "loadfile/021_local3.sml"]
        @
        positiveTest
          "loadfile/022_local.smi"
          ["loadfile/022_local.sml",
           "loadfile/022_local2.sml",
           "loadfile/022_local3.sml",
           "loadfile/022_local4.sml"]
        @
        negativeTest
          (fn LoadFileError.CircularLoad _ => true | _ => false)
          ["loadfile/030_cycle.sml"]
        @
        negativeTest
          (fn LoadFileError.CircularLoad _ => true | _ => false)
          ["loadfile/031_cycle.sml"]
        @
        negativeTest
          (fn LoadFileError.CircularLoad _ => true | _ => false)
          ["loadfile/032_cycle.sml"]
        @
        negativeTest
          (fn LoadFileError.CircularLoad _ => true | _ => false)
          ["loadfile/033_cycle.sml"]
        @
        negativeTest
          (fn LoadFileError.CircularLoad _ => true | _ => false)
          ["loadfile/034_cycle.sml"]
        @
        negativeTest
          (fn LoadFileError.CircularLoad _ => true | _ => false)
          ["loadfile/035_cycle.sml"]
        @
        negativeTest
          (fn LoadFileError.CircularLoad _ => true | _ => false)
          ["loadfile/036_cycle.sml"]
        @
        positiveTest
          "loadfile/040_alias.smi"
          ["loadfile/040_alias.sml",
           "loadfile/040_alias2.sml"]
        @
        positiveTest
          "loadfile/041_alias.smi"
          ["loadfile/041_alias.sml",
           "loadfile/041_alias/041_alias2.sml"]
        @
        positiveTest
          "loadfile/050_use.smi"
          ["loadfile/050_use.sml"]
        @
        positiveTest
          "loadfile/051_use.smi"
          ["loadfile/051_use.sml"]
        @
        positiveTest
          "loadfile/052_use.smi"
          ["loadfile/052_use.sml"]
        @
        negativeTest
          (fn LoadFileError.UseNotAllowed _ => true | _ => false)
          ["loadfile/060_useerror.sml"]
        @
        negativeTest
          (fn LoadFileError.UseNotAllowed _ => true | _ => false)
          ["loadfile/061_useerror.sml"]
        @
        positiveTest
          "loadfile/070_include.smi"
          ["loadfile/070_include.sml",
           "loadfile/070_include3.sml",
           "loadfile/070_include4.sml"]
        @
        positiveTest
          "loadfile/071_include.smi"
          ["loadfile/071_include.sml",
           "loadfile/071_include4.sml",
           "loadfile/071_include5.sml",
           "loadfile/071_include6.sml"]
        @
        positiveTest
          "loadfile/072_include.smi"
          ["loadfile/072_include.sml",
           "loadfile/072_include4.sml",
           "loadfile/072_include5.sml",
           "loadfile/072_include6.sml"]
        @
        positiveTest
          "loadfile/080_sig.smi"
          ["loadfile/080_sig.sml"]
        @
        positiveTest
          "loadfile/081_sig.smi"
          ["loadfile/081_sig.sml"]
        @
        positiveTest
          "loadfile/082_sig.smi"
          ["loadfile/082_sig.sml",
           "loadfile/082_sig4.sml"]
        @
        positiveTest
          "loadfile/083_sig.smi"
          ["loadfile/083_sig.sml",
           "loadfile/083_sig3.sml"]
        @
        positiveTest
          "loadfile/084_sig.smi"
          ["loadfile/084_sig.sml",
           "loadfile/084_sig3.sml"]
      )

end
