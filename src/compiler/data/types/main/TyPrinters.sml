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
  val print = fn s => if !Bug.debugPrint then print s else ()
  fun printPath path =
      if !Bug.debugPrint
      then print (String.concatWith "." path)
      else ()
  fun printTy ty =
      if !Bug.debugPrint
      then print (Bug.prettyPrint (T.format_ty ty))
      else ()
  fun printTpVarInfo var =
      if !Bug.debugPrint
      then print (Bug.prettyPrint (T.formatWithType_varInfo var))
      else ()
end
end
