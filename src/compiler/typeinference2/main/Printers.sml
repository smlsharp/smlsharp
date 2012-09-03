(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure Printers = 
struct
local
  structure T = Types
  structure TC = TypedCalc
  structure IC = IDCalc
in
 (* for debugging *)
  val print = fn s => if !Control.debugPrint then print s else ()
  fun printPath path =
      print (String.concatWith "." path)
  fun printTy ty =
      print (Control.prettyPrint (T.format_ty nil ty))
  fun printTpdecl tpdecl =
      print (Control.prettyPrint (TC.format_tpdecl nil tpdecl))
  fun printTpexp tpexp =
      print (Control.prettyPrint (TC.format_tpexp nil tpexp))
  fun printTpVarInfo var =
      print (Control.prettyPrint (T.format_varInfo var))
  fun printContext context =
      print (Control.prettyPrint (TypeInferenceContext.format_context context) ^ "\n")
  fun printIcexp exp =
      print (Control.prettyPrint (IC.format_icexp exp) ^ "\n")
  fun printIcpat pat =
      print (Control.prettyPrint (IC.format_icpat pat) ^ "\n")
  fun printIcdecl icdecl =
      print (Control.prettyPrint (IC.format_icdecl icdecl) ^ "\n")
  fun printIcVarInfo var =
      print (Control.prettyPrint (IC.format_varInfo var))
end
end
