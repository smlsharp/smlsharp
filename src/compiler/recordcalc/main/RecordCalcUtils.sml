structure RecordCalcUtils =
struct
local
  structure RC = RecordCalc
  structure BT = BuiltinTypes
  structure TU = TypesUtils
  val tempVarNamePrefix = "$R_"
in
  fun newRCVarName () =  tempVarNamePrefix ^ Gensym.gensym()
  fun newRCVarInfo (ty:Types.ty) =
      let
        val newVarId = VarID.generate()
      in
        {path=[newRCVarName()], id=newVarId, ty = ty}
      end

  fun expansive tpexp =
      case tpexp of
        RC.RCCONSTANT _ => false
      | RC.RCGLOBALSYMBOL _ => false
      | RC.RCVAR _ => false
      | RC.RCEXVAR (exVarInfo, loc) => false
      | RC.RCFNM {argVarList, bodyTy, bodyExp, loc} => false
      | RC.RCEXNCONSTRUCT {argExpOpt=NONE, exn, instTyList, loc} => false
      | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} => false
      | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} => false
      | RC.RCPOLYFNM _ => false
      | RC.RCSQL _ => false
      | RC.RCINDEXOF _ => false
      | RC.RCTAGOF _ => false
      | RC.RCSIZEOF _ => false
      | RC.RCDATACONSTRUCT {argExpOpt=NONE, argTyOpt, con, instTyList, loc} => false
      | RC.RCDATACONSTRUCT {con={path, id, ty}, instTyList, argTyOpt, argExpOpt= SOME tpexp, loc} =>
        let
          val tyCon = TU.tyConFromConTy ty
        in
          TypID.eq (#id tyCon, #id BT.refTyCon)
          orelse expansive tpexp
        end
      | RC.RCEXNCONSTRUCT {argExpOpt= SOME tpexp, exn, instTyList, loc} =>
        expansive tpexp
      | RC.RCRECORD {fields, recordTy=ty, loc=loc} =>
          LabelEnv.foldli
          (fn (string, tpexp1, isExpansive) =>
           isExpansive orelse expansive tpexp1)
          false
          fields
      | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} => 
        expansive exp orelse expansive indexExp
      | RC.RCMODIFY  {elementExp:RC.rcexp, elementTy:Types.ty, indexExp:RC.rcexp,
                   label:string, loc, recordExp:RC.rcexp, recordTy:Types.ty} =>
        expansive recordExp orelse expansive indexExp orelse expansive elementExp
      | RC.RCMONOLET {binds=varPathInfoTpexpList, bodyExp=tpexp, loc} =>
          foldl
          (fn ((v,tpexp1), isExpansive) => isExpansive orelse expansive tpexp1)
          (expansive tpexp)
          varPathInfoTpexpList
      | RC.RCLET {decls, body, tys,loc} => true
      | RC.RCPOLY {exp=tpexp,...} => expansive tpexp
      | RC.RCTAPP {exp, ...} => expansive exp
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy, ptrExp}, ty, loc) =>
        expansive ptrExp
      | RC.RCCAST (rcexp, ty, loc) => expansive rcexp 
      | RC.RCAPPM _ => true
      | RC.RCCASE _ => true
      | RC.RCPRIMAPPLY _ => true
      | RC.RCOPRIMAPPLY _ => true
      | RC.RCSEQ _ => true
      | RC.RCRAISE _ => true
      | RC.RCHANDLE _ => true
      | RC.RCEXNCASE _ => true
      | RC.RCEXPORTCALLBACK _ => true
      | RC.RCFOREIGNAPPLY _ => true
      | RC.RCSWITCH _ => true

  fun isAtom tpexp =
      case tpexp of
        RC.RCCONSTANT {const, loc, ty} => true
      | RC.RCGLOBALSYMBOL {kind, loc, name, ty} => true
      | RC.RCVAR (var, loc) => true
      | RC.RCEXVAR (exVarInfo, loc) => true
      | _ => false
end
end
