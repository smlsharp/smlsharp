(**
 * @copyright (c) 2012- Tohoku University.
 * @author Atsushi Ohori
 *)
structure Reify =
struct
local
  structure I = IDCalc
  structure T = Types
  structure ITy = EvalIty
  structure TC = TypedCalc
  structure TB = TypesBasics
  structure TCU = TypedCalcUtils
  structure V = NameEvalEnv
  val pos = Loc.makePos {fileName="ReifiedTermData.sml", line=0, col=0}
  val loc = (pos,pos)

in
  fun needInstantiattion ty = 
      not (TB.monoTy ty) andalso
      case TB.derefTy ty of
        T.POLYty {boundtvars, body} =>
        (case TB.derefTy body 
          of T.FUNMty _ => false
           | _ => true)
      | T.RECORDty tyFields => 
        LabelEnv.foldl (fn (ty, res) => res orelse needInstantiattion ty) false tyFields
      | T.CONSTRUCTty {tyCon, args} =>
        foldl (fn (ty, res) => res orelse needInstantiattion ty) false args
      | _ => false

  val instantiatePrefix = Symbol.mkLongsymbol ["_Instantiate"] loc
  fun instantiatedLongsymbol longsymbol = Symbol.concatPath (instantiatePrefix, longsymbol)

  fun instantiateIdstatus (name, idstatus)  decls =
      case idstatus of
      I.IDEXVAR {exInfo=exInfo as {longsymbol, ty=ity, version}, used, internalId = SOME id} =>
      let
        val ty = ITy.evalIty ITy.emptyContext ity
      in
        if needInstantiattion ty then 
          let
            val accessLongsymbol = Symbol.setVersion(longsymbol, version)
            val instantiatedAccessLongsymbol = Symbol.setVersion(instantiatedLongsymbol longsymbol, version)
            val originalVar = TC.TPVAR {longsymbol=accessLongsymbol, ty=ty, id=id, opaque=false}
            val (instantiatedTy, originalTpexp) = TCU.groundInst (ty, originalVar)
            val newVarinfo = TCU.newTCVarInfoWithLongsymbol (instantiatedAccessLongsymbol, instantiatedTy)
          in
            decls @ [TC.TPVAL ([(newVarinfo, originalTpexp)], loc), TC.TPEXPORTVAR newVarinfo]
          end
        else decls
      end
    | I.IDEXVAR {exInfo={longsymbol, ty=ity, version}, used, internalId = NONE,...} =>
      let
        val ty = ITy.evalIty ITy.emptyContext ity
      in
        if needInstantiattion ty then 
          let
            val accessLongsymbol = Symbol.setVersion(longsymbol, version)
            val instantiatedAccessLongsymbol = Symbol.setVersion(instantiatedLongsymbol longsymbol, version)
            val originalVar = TC.TPEXVAR {longsymbol=accessLongsymbol, ty=ty}
            val (instantiatedTy, originalTpexp) = TCU.groundInst (ty, originalVar)
            val newVarinfo = TCU.newTCVarInfoWithLongsymbol (instantiatedAccessLongsymbol, instantiatedTy)
          in
            decls @ [TC.TPVAL ([(newVarinfo, originalTpexp)], loc), TC.TPEXPORTVAR newVarinfo]
          end
        else decls
      end
    | I.IDEXVAR_TOBETYPED _ => decls
    | I.IDVAR varId => decls
    | I.IDVAR_TYPED _ => decls
    | I.IDBUILTINVAR {primitive, ty} => decls
    | I.IDCON _ => decls
    | I.IDEXN _ => decls
    | I.IDEXNREP _ => decls
    | I.IDEXEXN ({longsymbol, ty, version}, used) => decls
    | I.IDEXEXNREP ({longsymbol, ty, version}, used) => decls
    | I.IDOPRIM _ => decls
    | I.IDSPECVAR _ => decls
    | I.IDSPECEXN _ => decls
    | I.IDSPECCON _ => decls

  fun instantiateEnv env decls = 
      let
        val env = NormalizeTy.reduceEnv env
        val V.ENV {varE, tyE, strE=V.STR strE} = env

        (* strE *)
        val decls =
            SymbolEnv.foldri
            (fn (name, {env, strKind}, decls) => instantiateEnv env decls)
            decls
            strE

        (* varE *)
        val decls =
            SymbolEnv.foldri
            (fn (name, idstatus, decls) => instantiateIdstatus (name, idstatus) decls)
            decls
            varE
      in
        decls
      end

  fun instantiateTopEnv (topEnv:V.topEnv as {Env, SigE, FunE}) =
      instantiateEnv Env nil

end
end
