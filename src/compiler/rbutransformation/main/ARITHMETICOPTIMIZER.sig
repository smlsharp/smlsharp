(**
 * ArithmeticOptimizer.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ARITHMETICOPTIMIZER.sig,v 1.2 2007/04/18 09:07:04 ducnh Exp $
 *)
signature ARITHMETICOPTIMIZER = sig

  type const = Word32.word
  type var = int
  type tid = int

  datatype exp =
     CONST of const
   | VAR of var
   | ADD of exp * exp
   | AND of exp * exp
   | OR of exp * exp
   | LSHIFT of exp * exp
   | RSHIFT of exp * exp
   | SIZE of tid
   | TAG of tid

  type batch

  val initialize : unit -> unit

  val empty : batch

  val insert : batch * exp -> batch * var

  val extract : batch * var list -> (var * exp) list

end
