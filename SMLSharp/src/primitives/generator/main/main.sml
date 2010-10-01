structure Main = struct
fun main (_, args) =
    (
      case args of h::t => OS.FileSys.chDir h | _ => ();
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
          ];
      OS.Process.success
    )
    handle PrimitiveTable.ParseError line =>
           raise Fail ("error in primitives.csv at " ^ Int.toString line)
         | ConstantTable.ParseError line =>
           raise Fail ("error in constants.csv at " ^ Int.toString line)
end
