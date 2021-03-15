(*
[{endPos = 3086, fileId = 29421, startPos = 3080, symbol = "typeinf"}]
"src/compiler/compilePhases/typeinference/main/InferTypes2.sml"
21863
[{endPos = 259572, fileId = 21863, startPos = 259566, symbol = "typeinf"}]
*)
val f1 = "src/compiler/compilePhases/main/main/Main.sml"
val f2 = "src/compiler/compilePhases/analyzefiles/main/Analyzers.sml"
val symList = DBBasics.listSymsInFile f1
val symList2 = DBBasics.findSymInFile {fileName = f2, symbol = "analyzeIdstatus"};
Dynamic.pp symList;
Dynamic.pp symList2;
print "************************************************\n";
val trees = map RefTrees.makeTree symList;
Dynamic.pp trees;
print "************************************************\n";
val trees2 = map RefTrees.makeTree symList;
Dynamic.pp trees2;
