fun symToString sym =
    SMLFormat.prettyPrint nil (RefTreesFormatter.format_sym sym)
fun reftreeToString refTree =
    SMLFormat.prettyPrint nil (RefTreesFormatter.format_refTree refTree)
fun printSym sym = print (symToString sym ^ "\n")
fun printRefTree refTree = print (reftreeToString refTree ^ "\n")
val f1 = "src/compiler/compilePhases/toplevel/main/Top.smi";
val nodeList = RefUtiles.listDefsInFile f1;
val t = RefUtiles.makeTree {endPos = 5361, fileId = 27965, startPos = 5355, symbol = "compile"}
val _ = printNodeTree t;
