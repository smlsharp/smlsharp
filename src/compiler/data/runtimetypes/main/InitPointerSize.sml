(**
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure InitPointerSize : sig

  val init : LLVMUtils.compile_options -> unit

end =
struct

  fun init ({triple, arch, cpu, features, ...}:LLVMUtils.compile_options) =
      let
        val t = LLVM.LLVMGetTargetFromArchAndTriple (arch, triple)
        val tm = LLVM.LLVMCreateTargetMachine
                   (t, triple, cpu, features, LLVM.OptDefault,
                    LLVM.RelocDefault, LLVM.CodeModelDefault)
        val tmd = LLVM.LLVMGetTargetMachineData tm
        val pointerSize = Word.toInt (LLVM.LLVMPointerSize tmd)
      in
        SMLSharp_PointerSize.pointerSize := pointerSize;
        LLVM.LLVMDisposeTargetMachine tm
      end

end
