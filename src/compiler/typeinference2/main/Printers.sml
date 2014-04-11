(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure Printers = 
struct
local
  structure T = Types
  structure TC = TypedCalc
  structure TIC = TypeInferenceContext
  structure IC = IDCalc
in
 (* for debugging *)
  val print = fn s => if !Bug.debugPrint then print s else ()
  fun printPath path =
      print (String.concatWith "." path)
  fun printITy ty =
      print (Bug.prettyPrint (IC.format_ty ty))
  fun printTy ty =
      print (Bug.prettyPrint (T.format_ty nil ty))
  fun printTpdecl tpdecl =
      print (Bug.prettyPrint (TC.format_tpdecl nil tpdecl))
  fun printTpexp tpexp =
      print (Bug.prettyPrint (TC.formatWithType_tpexp nil tpexp))
  fun printVarEnv varE =
      print (Bug.prettyPrint (TIC.format_varEnv varE))
  fun printTpVarInfo var =
      print (Bug.prettyPrint (T.formatWithType_varInfo nil var))
  fun printContext context =
      print (Bug.prettyPrint (TypeInferenceContext.format_context context) ^ "\n")
  fun printIcexp exp =
      print (Bug.prettyPrint (IC.format_icexp exp) ^ "\n")
  fun printIcpat pat =
      print (Bug.prettyPrint (IC.format_icpat pat) ^ "\n")
  fun printIcdecl icdecl =
      print (Bug.prettyPrint (IC.format_icdecl icdecl) ^ "\n")
  fun printIcVarInfo var =
      print (Bug.prettyPrint (IC.format_varInfo var))
end
end
