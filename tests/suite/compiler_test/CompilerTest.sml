structure CompilerTest =
struct
  open SMLUnit.Test Compiler

  val smlfiles = [
    "../compiler_test/tests.sml",
    "../compiler_test/dotest.sml"
  ]

  val documentFiles =
      let
        val docDir1 = "../compiler_test/document/"
        val docDir2 = "./tests/compiler_test/document/"

        val dirstream = OS.FileSys.openDir docDir2
        fun readFiles fileList =
            case OS.FileSys.readDir dirstream of
                 NONE => rev fileList
               | SOME file => readFiles (file::fileList)
        val fileList = readFiles []
        val _ = OS.FileSys.closeDir dirstream
        val fileList = List.filter (String.isSuffix ".sml") fileList
        val fileList = map (fn file => docDir1 ^ file) fileList
      in
        fileList
      end


  val smlfiles = documentFiles @ smlfiles

  fun dotest () =
      execute
        (link "../compiler_test/dotest.smi"
              (compile smlfiles))
      handle e => (Main.printExn "compiler_test" e; raise e)

  val tests = Test ("test", dotest)

end
