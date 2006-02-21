(**
 * Copyright (c) 2006, Tohoku University.
 *
 * (imperative version).
 * @author Liu Bochao
 * @version $Id: TYPE_INFERENCER.sig,v 1.14 2006/02/18 04:59:33 ohori Exp $
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

end

