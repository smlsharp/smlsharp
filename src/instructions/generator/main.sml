
fun main () =
InstructionGenerator.generateFiles
"../Instructions.sml"
[
  "../compiler/main/INSTRUCTION_SERIALIZER.sig",
  "../compiler/main/InstructionSerializer.sml",
  "../compiler/main/Instructions.sml",
  "../runtime/main/Instructions.cc",
  "../runtime/main/Instructions.hh"
]
