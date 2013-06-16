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
  val print = fn s => if !Control.printInfo then print s else ()
  fun printPath path =
      print (String.concatWith "." path)
  fun printTy ty =
      print (Control.prettyPrint (T.format_ty nil ty))
  fun printTpVarInfo var =
      print (Control.prettyPrint (T.formatWithType_varInfo nil var))
end
end
