(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MULTIPLEVALUECALCUTILS.sig,v 1.2 2007/04/18 09:04:00 ducnh Exp $
 *)
signature MULTIPLEVALUECALCUTILS = sig

  val getLocOfExp : MultipleValueCalc.mvexp -> MultipleValueCalc.loc

  val getLocOfDecl : MultipleValueCalc.mvdecl -> MultipleValueCalc.loc

end
