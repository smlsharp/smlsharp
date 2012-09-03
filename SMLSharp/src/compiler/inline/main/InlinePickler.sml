(**
 * @copyright (c) 2007, Tohoku University.
 * @author Isao Sasano
 * @version $Id: InlinePickler.sml,v 1.8 2008/03/18 06:20:49 bochao Exp $
 *)

structure InlinePickler =
struct
local
structure P = Pickle
structure MP = MultipleValueCalcPickler
structure ATP = AnnotatedTypesPickler
structure MV = MultipleValueCalc

structure GlobalEnvPickler = OrdMapPickler(ExVarID.Map)


val globalInlineInfo = 
    let fun toInt (InlineEnv.GFN _) = 0
	  | toInt (InlineEnv.GPFN _) = 1
	  | toInt (InlineEnv.GSIMPLE _) = 2
	fun pu_GFN pu = P.con1 InlineEnv.GFN
			       (fn InlineEnv.GFN arg => arg
                                  | _ => raise Control.Bug "inlinePickler non GFN to pu_GFN"
                                )
			       (P.tuple2 (MP.mvexp,P.string))
	fun pu_GPFN pu = P.con1 InlineEnv.GPFN
				(fn InlineEnv.GPFN arg => arg
                                  | _ => raise Control.Bug "inlinePickler non GPFN to pu_GPFN"
                                )
				(P.tuple4
				     (ATP.btvEnv,MP.mvexp,P.int,P.string))
	fun pu_GSIMPLE pu = P.con1 InlineEnv.GSIMPLE
				   (fn InlineEnv.GSIMPLE arg => arg
                                      | _ => raise Control.Bug "inlinePickler non GSIMPLE to pu_GSIMPLE"
                                    )
				   (P.tuple2 (MP.mvexp,P.string))
    in 
	P.data (toInt, [pu_GFN, pu_GPFN, pu_GSIMPLE])
    end

val gmapP = GlobalEnvPickler.map (ExVarID.pu_ID, globalInlineInfo)

in

val globalInlineEnv = 
    let fun toInt (InlineEnv.GIE _) = 0
	fun pu_GIE pu = P.con1 InlineEnv.GIE
			      (fn InlineEnv.GIE arg => arg) 
			      gmapP
    in P.data (toInt, [pu_GIE])
    end

end
end
