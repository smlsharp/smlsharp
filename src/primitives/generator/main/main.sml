fun main () =
    (
      PrimitiveTable.generateFiles
	  "../../primitives.csv"
	  [
	    "../../compiler/main/Primitives.ppg",
	    "../../runtime/main/Primitives.cc",
	    "../../runtime/main/Primitives.hh",
	    "../../../instructions/Instructions.sml"
          ];
      ConstantTable.generateFiles
	  "../../constants.csv"
	  [
	    "../../compiler/main/Constants.sml",
	    "../../runtime/main/Constants.cc",
	    "../../runtime/main/Constants.hh"
          ]
    )
