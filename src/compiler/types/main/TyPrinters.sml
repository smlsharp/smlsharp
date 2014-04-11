(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure TyPrinters = 
struct
local
  structure T = Types
in
 (* for debugging *)
  val print = fn s => if !Bug.printInfo then print s else ()
  fun printPath path =
      print (String.concatWith "." path)
  fun printTy ty =
      print (Bug.prettyPrint (T.format_ty nil ty))
  fun printTpVarInfo var =
      print (Bug.prettyPrint (T.formatWithType_varInfo nil var))
end
end
