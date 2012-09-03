(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure PrinterGeneration  : 
sig
  val generate
    : NameEvalEnv.topEnv
      -> NameEvalEnv.topEnv * TypedCalc.tpdecl list * TypedCalc.tpdecl list
end
=
struct
local
  fun bug s = Control.Bug ("PrinterGeneration:" ^ s)
  structure T = Types
  structure TC = TypedCalc
  structure R = Reify
  structure RD = ReifiedTermData
  structure BE = BuiltinEnv
  val externals =
      [
       RD.makeArrayTerm,
       RD.makeListTerm,
       RD.makeConsTerm,
       RD.makeFieldTerm,
       RD.makeConsField,
       RD.fieldNil,
       RD.reifiedTermNil,
       RD.makeEXVAR,
       RD.makeEXEXN,
       RD.makeEXEXNREP,
       RD.makeTstr,
       RD.idstatusNil,
       RD.idstatusCons,
       RD.tstrNil,
       RD.tstrCons,
       RD.makeENV,
       RD.makeStrentry,
       RD.strentryNil,
       RD.strentryCons,
       RD.stringNil,
       RD.stringCons,
       RD.makeSigentry,
       RD.sigentryNil,
       RD.sigentryCons,
       RD.makeReifiedTopenv,
       RD.format_topEnv,
       RD.printTopEnv
      ]

  fun externDecls() =
      map 
        (fn varRef =>
          case !varRef of
            NONE => 
            (print "PrinterGeneration: external not set\n";
             raise bug "external not set"
            )
          | SOME (TC.TPEXVAR var, ty) => TC.TPEXTERNVAR var
          | _ => 
            (print "PrinterGeneration: non var external\n";
             raise bug "non-var external var"
            )
        )
        externals 
in
  fun generate topEnv = 
      let
        val externDecls = externDecls()
        val (topEnv, term) = R.reifyTopEnv topEnv
        val printTerm = R.makeMonoApply RD.printTopEnv term
        val id = VarID.generate ()
        val newVar = {path = ["_PrinterGeneration"], ty = BE.UNITty, id = id} : T.varInfo
      in
        (topEnv,
         externDecls,
         [TC.TPVAL ([(newVar, printTerm)], Loc.noloc)]
        )
      end
end
end
