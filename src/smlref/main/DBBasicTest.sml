val f1 = "src/compiler/compilePhases/nameevaluation/main/NameEval.smi"
val f2 = "src/compiler/compilePhases/nameevaluation/main/NameEval.sml"
val id1 = DBBasics.fileNameToFileId f1;
val id2 = DBBasics.fileNameToFileId f2;
val symList = DBBasics.findSymInFile {fileName = f1, symbol = "nameEval"};
val symList2 = DBBasics.findSymInFile {fileName = f2, symbol = "nameEval"};
val symList3 = DBBasics.findSymInFile {fileName = f2, symbol = "topdecsInclude"};
val parents = DBBasics.findParents {fileId = id2, startPos = 109992, endPos = 110005, symbol = "topdecsInclude"};
Dynamic.pp f1;
Dynamic.pp id1;
Dynamic.pp f2;
Dynamic.pp id2;
Dynamic.pp symList;
Dynamic.pp symList2;
Dynamic.pp symList3;
Dynamic.pp parents;
