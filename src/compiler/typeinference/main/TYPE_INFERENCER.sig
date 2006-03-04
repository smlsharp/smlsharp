(**
 * (imperative version).
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: TYPE_INFERENCER.sig,v 1.16 2006/03/02 12:53:25 bochao Exp $
 *)
signature TYPE_INFERENCER =
sig

  val infer :
      InitialTypeContext.topTypeContext
      -> PatternCalcWithTvars.pttopdec list 
      -> (
          TypeContext.context *
          TypedCalc.tptopdecl list *
          UserError.errorInfo list
         )
  val inferLinkageUnit :
      PatternCalcWithTvars.pttopdec list 
      -> (
          TypeContext.staticTypeEnv *
          TypedCalc.tptopdecl list *
          UserError.errorInfo list
         )

end

