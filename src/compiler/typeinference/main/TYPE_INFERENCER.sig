(**
 * (imperative version).
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: TYPE_INFERENCER.sig,v 1.18 2006/07/12 06:30:12 bochao Exp $
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
          StaticTypeEnv.staticTypeEnv *
          TypedCalc.tptopdecl list *
          UserError.errorInfo list
         )

  val inferInterface :
      StaticTypeEnv.typeEnv
      -> 
      PatternCalcWithTvars.pttopdec list 
      -> 
      ((Types.tyConIdSet * StaticTypeEnv.typeEnv) * UserError.errorInfo list)

  val exportSigCheck : 
      (StaticTypeEnv.exportTypeEnv * (Types.tyConIdSet * StaticTypeEnv.typeEnv) * Loc.loc)
      -> StaticTypeEnv.exportTypeEnv * UserError.errorInfo list
      
end

