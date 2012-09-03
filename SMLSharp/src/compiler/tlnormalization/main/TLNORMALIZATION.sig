(**
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc NGUYEN
 * @version $Id: TLNORMALIZATION.sig,v 1.6 2008/06/09 03:15:09 ohori Exp $
 *)
signature TLNORMALIZATION =
sig
    val normalize : 
      Counters.stamp
       -> RecordCalc.topBlock list
          -> Counters.stamp * TypedLambda.topBlock list

    val isAtomicTyCon :
        Types.tyCon -> bool

end
