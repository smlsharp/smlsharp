(**
 * ArithmeticOptimizer.
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: ARITHMETICOPTIMIZER.sig,v 1.3 2008/01/10 04:43:12 katsu Exp $
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
   | SUB of exp * exp
   | NOT of exp

  type batch

  val initialize : unit -> unit

  val empty : batch

  val insert : batch * exp -> batch * var

  val extract : batch * var list -> (var * exp) list

end
