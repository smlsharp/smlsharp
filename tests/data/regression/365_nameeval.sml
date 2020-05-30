structure Word32 =
struct
  type t = Word.word
  val wordSize = Word32.wordSize
end

(*
2020-05-18 katsu

This causes BUG.

uncaught exception: Bug.Bug: unionExternDecls extern at src/compiler/compilePhases/llvmgen/main/LLVMGen.sml:772.26

Basis Libraryと同名のストラクチャをprovideできてしまう．
NameEvalのチェック漏れと思われる．

*)
