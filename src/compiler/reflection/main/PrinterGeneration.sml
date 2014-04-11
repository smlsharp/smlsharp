(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure PrinterGeneration =
struct
local
  fun bug s = Bug.Bug ("PrinterGeneration:" ^ s)
  val pos = Loc.makePos {fileName="PrinterGeneration.sml", line=0, col=0}
  val loc = (pos,pos)
  structure T = Types
  structure TC = TypedCalc
  structure R = Reify
  structure RD = ReifiedTermData
  structure BT = BuiltinTypes
  val externals =
      [
       RD.makeDATATYPEtyRepNOARG,
       RD.makeDATATYPEtyRepWITHARG,
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
       RD.printTopEnv,
       RD.termToString,
       RD.exnToStringFunRef,
       RD.updateExnToString
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
  fun setControlParams () =
      (ReflectionControl.maxDepth := !Control.printMaxDepth;
       ReflectionControl.maxNestLevel := !Control.printMaxNestLevel;
       ReflectionControl.maxExnNestLevel := !Control.printMaxExnNestLevel;
       ReflectionControl.printWidth := !Control.printWidth
      )
       
  fun generate exnConList topEnv = 
      let
        val _ = setControlParams()
        val externDecls = externDecls()
        val (topEnv, term) = R.reifyTopEnv exnConList topEnv
        val printTerm = R.makeMonoApply RD.printTopEnv term
        val id = VarID.generate ()
        val newVar = {longsymbol = Symbol.mkLongsymbol ["_PrinterGeneration"] loc, 
                      ty = BT.unitTy,
                      opaque = false,
                      id = id} : T.varInfo
        val decls = [TC.TPVAL ([(newVar, printTerm)], loc)]
        val decls =
            if !Control.generateExnMessage then
              let
                val exnToStringId = VarID.generate ()
                val exnToStringVar = {longsymbol = Symbol.mkLongsymbol ["_exnToString"] loc, 
                                      ty = BT.unitTy,
                                      opaque = false,
                                      id = exnToStringId} : T.varInfo
              in
                TC.TPVAL ([(exnToStringVar, R.exnToString())], loc) :: decls
              end
            else decls
      in
        (topEnv,
         externDecls,
         decls
        )
      end
end
end
