(**
 * (imperative version).
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: TYPE_INFERENCER.sig,v 1.31 2008/08/04 13:25:37 bochao Exp $
 *)
signature TYPE_INFERENCER =
sig

  val infer :
      InitialTypeContext.topTypeContext
      -> Counters.stamps
      -> NameMap.basicNameNPEnv
      -> PatternCalcWithTvars.pttopdec list 
      -> (
          TypeContext.context *
          Counters.stamps * 
          TypedCalc.tptopdecl list *
          UserError.errorInfo list
         )

end

