(**
 * @copyright (c) 2006, Tohoku University.
 * @author NGUYEN Huu-Duc
 * @version $Id: BUCCOMPILECONTEXT.sig,v 1.6 2006/02/28 17:05:50 duchuu Exp $
 *)

signature BUCCOMPILECONTEXT = sig
  
  type context
  datatype bookmark = SIZE of int | TAG of int | FRAMEBITMAP of BUCCalc.id

  val makeContext : Types.btvEnv list -> context
  val getTyEnv : context -> Types.btvEnv list

  val findVariable : context * BUCCalc.id -> BUCCalc.varInfo option
  val lookupSize : context * int -> BUCCalc.varInfo 
  val lookupTag : context * int -> BUCCalc.varInfo 

  val insertVariable : context * BUCCalc.varInfo -> context
  val insertVariables : context * BUCCalc.varInfo list -> context
  val updateVariable : context * BUCCalc.varInfo -> context
  val updateVariables : context * BUCCalc.varInfo list -> context
  val mergeVariable : context * BUCCalc.varInfo -> context * BUCCalc.varInfo
  val mergeVariables : context * BUCCalc.varInfo list -> context * BUCCalc.varInfo list
  val updateVarKind : context * BUCCalc.id * BUCCalc.varKind -> context

  val listFreeVariables : context -> BUCCalc.varInfo list
  val listLocalBitmapVariables : context -> BUCCalc.varInfo list
  val listExtraLocalVariables : context -> BUCCalc.varInfo list
  val getFrameBitmapIDs : context -> ID.Set.set

  val isBoundTypeVariable : context * int -> bool

  val prepareFunctionContext : context * Types.btvEnv * TypedLambda.varIdInfo list 
                                 -> context * BUCCalc.varInfo list

  val setBookmark : context * bookmark * BUCCalc.varInfo -> unit
  val getBookmark : context * bookmark -> BUCCalc.varInfo option

end
