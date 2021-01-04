structure RecordCalcUtils =
struct
local
  structure RC = RecordCalc
  structure BT = BuiltinTypes
  structure TB = TypesBasics
  structure T = Types
in
  fun newRCVarInfo (ty:Types.ty) =
      let
        val newVarId = VarID.generate()
      in
        {path=[], id=newVarId, ty = ty}
      end

  fun expansive tpexp =
      case tpexp of
        RC.RCCONSTANT _ => false
      | RC.RCFOREIGNSYMBOL _ => false
      | RC.RCVAR _ => false
      | RC.RCEXVAR exVarInfo => false
      | RC.RCFNM {argVarList, bodyTy, bodyExp, loc} => false
      | RC.RCEXNCONSTRUCT {argExpOpt=NONE, exn, loc} => false
      | RC.RCEXNTAG {exnInfo, loc} => false
      | RC.RCEXEXNTAG {exExnInfo, loc} => false
      | RC.RCINDEXOF _ => false
      | RC.RCTAGOF _ => false
      | RC.RCSIZEOF _ => false
      | RC.RCREIFYTY _ => false
      | RC.RCDATACONSTRUCT {argExpOpt=NONE, con, instTyList, loc} => false
      | RC.RCDATACONSTRUCT {con={path, id, ty}, instTyList, argExpOpt= SOME tpexp, loc} =>
        let
          val tyCon = TB.tyConFromConTy ty
        in
          TypID.eq (#id tyCon, #id BT.refTyCon)
          orelse expansive tpexp
        end
      | RC.RCEXNCONSTRUCT {argExpOpt= SOME tpexp, exn, loc} =>
        expansive tpexp
      | RC.RCRECORD {fields, recordTy=ty, loc=loc} =>
          RecordLabel.Map.foldli
          (fn (string, tpexp1, isExpansive) =>
           isExpansive orelse expansive tpexp1)
          false
          fields
      | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} => 
        expansive exp orelse expansive indexExp
      | RC.RCMODIFY  {elementExp:RC.rcexp, elementTy:Types.ty, indexExp:RC.rcexp,
                   label:RecordLabel.label, loc, recordExp:RC.rcexp, recordTy:Types.ty} =>
        expansive recordExp orelse expansive indexExp orelse expansive elementExp
      | RC.RCLET {decls, body, loc} => true
      | RC.RCPOLY {exp=tpexp,...} => expansive tpexp
      | RC.RCTAPP {exp, ...} => expansive exp
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy, funExp=RC.RCFFIFUN (ptrExp, _)}, ty, loc) =>
        expansive ptrExp
      | RC.RCFFI (RC.RCFFIIMPORT {ffiTy, funExp=RC.RCFFIEXTERN _}, ty, loc) =>
        false
      | RC.RCCAST ((rcexp, expTy), ty, loc) => expansive rcexp 
      | RC.RCAPPM _ => true
      | RC.RCCASE _ => true
      | RC.RCPRIMAPPLY _ => true
      | RC.RCOPRIMAPPLY _ => true
      | RC.RCRAISE _ => true
      | RC.RCHANDLE _ => true
      | RC.RCEXNCASE _ => true
      | RC.RCCALLBACKFN _ => true
      | RC.RCFOREIGNAPPLY _ => true
      | RC.RCSWITCH _ => true
      | RC.RCCATCH _ => true
      | RC.RCTHROW _ => true
      | RC.RCJOIN {isJoin, ty,args=(arg1,arg2),argTys,loc} => 
        expansive arg1 orelse expansive arg2
      | RC.RCDYNAMIC {exp,ty,elemTy, coerceTy,loc} => expansive exp
      | RC.RCDYNAMICIS {exp,ty,elemTy, coerceTy,loc} => expansive exp
      | RC.RCDYNAMICNULL {ty, coerceTy,loc} => false
      | RC.RCDYNAMICTOP {ty, coerceTy,loc} => false
      | RC.RCDYNAMICVIEW {exp,ty,elemTy, coerceTy,loc} => expansive exp
      | RC.RCDYNAMICCASE _ => true
      | RC.RCDYNAMICEXISTTAPP _ => true

  fun isAtom tpexp =
      case tpexp of
        RC.RCCONSTANT {const, loc, ty} => true
      | RC.RCFOREIGNSYMBOL {loc, name, ty} => true
      | RC.RCVAR var => true
      | RC.RCEXVAR exVarInfo => true
      | _ => false

 (* 2017-1-03 TypedCalcUtils から ReifyTopEnvで使用 *)
  fun newVarInfo loc (ty:T.ty) =
      let
        val newVarId = VarID.generate()
      in
        {path=[], id=newVarId, ty = ty}
      end

end
end
