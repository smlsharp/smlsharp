(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: RECORDCALC.sig,v 1.19 2008/03/11 08:53:55 katsu Exp $
 *)
signature RECORDCALC = sig

 type loc
 type ty
 type tvar
 type tyCon 
 type callingConvention
 type conInfo
 type exnInfo
 type valIdent
 type id
 type varIdInfo
 type varIdInfoWithType
 type primInfo
 type oprimInfo
 type btvKind
 type fields
 type constant

 datatype rcexp 
   = RCFOREIGNAPPLY of 
        {
          funExp : rcexp, 
	  instTyList:ty list,
	  argExpList:rcexp list, 
	  argTyList : ty list, 
	  loc: loc
        }
   | RCEXPORTCALLBACK of 
       {
         funExp : rcexp,
         instTyList:ty list,
	 argTyList : ty list,
	 resultTy : ty,
         loc: loc
       }
   | RCSIZEOF of ty * loc
   | RCCONSTANT of constant * loc
   | RCGLOBALSYMBOL of string * Absyn.globalSymbolKind * ty * loc
   | RCVAR of varIdInfoWithType * loc
   | RCGETFIELD of rcexp * int * ty * loc
   | RCARRAY of
       {
        sizeExp : rcexp,
        initExp : rcexp,
        elementTy : ty ,
        resultTy : ty,
        loc :loc
        }
   | RCPRIMAPPLY of {primOp:primInfo, instTyList:ty list, argExpOpt:rcexp option, loc:loc}
   | RCOPRIMAPPLY of {oprimOp:oprimInfo, instances:ty list, argExpOpt:rcexp option, loc:loc}
   | RCDATACONSTRUCT of {con:conInfo, instTyList:ty list, argExpOpt:rcexp option,loc:loc}
   | RCEXNCONSTRUCT of {exn:exnInfo, instTyList:ty list, argExpOpt:rcexp option,loc:loc}
   | RCAPPM of {funExp:rcexp,funTy:ty, argExpList:rcexp list,loc:loc}
   | RCMONOLET of {binds:(varIdInfoWithType * rcexp) list, bodyExp:rcexp, loc:loc}
   | RCLET of rcdecl list * rcexp list * ty list * loc
   | RCRECORD of {fields:fields, recordTy:ty,loc:loc}
   | RCSELECT of {label:string, exp:rcexp, expTy:ty, resultTy:ty, loc:loc}
   | RCMODIFY of 
      {
       label:string, 
       recordExp:rcexp, 
       recordTy:ty, 
       elementExp:rcexp, 
       elementTy:ty, 
       loc:loc
       }
   | RCRAISE of rcexp * ty * loc
   | RCHANDLE of {exp:rcexp, exnVar:varIdInfo, handler:rcexp, loc:loc}
   | RCCASE of 
       {
        exp:rcexp,
        expTy:ty,
        ruleList:(conInfo * varIdInfoWithType option * rcexp) list,
        defaultExp:rcexp,
        loc:loc
        }
   | RCEXNCASE of 
       {
        exp:rcexp,
        expTy:ty,
        ruleList:(exnInfo * varIdInfoWithType option * rcexp) list,
        defaultExp:rcexp,
        loc:loc
        }
   | RCSWITCH of
       {
        switchExp:rcexp, 
        expTy:ty, 
        branches:(constant * rcexp) list, 
        defaultExp:rcexp, 
        loc:loc
        }
   | RCFNM of {argVarList:varIdInfo list, bodyTy:ty, bodyExp: rcexp, loc:loc}
   | RCPOLYFNM of 
     {
      btvEnv:btvKind IEnv.map, 
      argVarList:varIdInfo list,
      bodyTy:ty,
      bodyExp:rcexp,
      loc:loc
      }
   | RCPOLY of {btvEnv:btvKind IEnv.map, expTyWithoutTAbs:ty, exp:rcexp, loc:loc}
   | RCTAPP of {exp:rcexp, expTy:ty, instTyList:ty list, loc:loc}
   | RCSEQ of {expList:rcexp list, expTyList:ty list, loc:loc}
   | RCLIST of {expList:rcexp list, listTy:ty, loc:loc}
   | RCCAST of rcexp * ty * loc
     RCFUNCTOR of {name : string, 
                   formalAbstractTypeIDSet : TyConID.Set.set, 
                   formalExnIDSet : ExnTagID.Set.set,
                   formalVarIDSet : ExternalVarID.Set.set,
                   generativeExnIDSet : ExnTagID.Set.set,
                   generativeVarIDSet : ExternalVarID.set,
                   bodyCode : rcdecl list}
   | RCLINKFUNCTOR of {name : string, 
                       actualArgName : string,
                       typeResolutionTable : Types.tyBindInfo GlobalID.Map.map,
                       exnTagResolutionTable : GlobalTag.globalTag GlobalTag.Map.map,
                       externalVarIDResolutionTable : 
                       ExternalVarID.externalVarID ExternalVarID.Map.map,
                       refreshedExceptionTagTable : GlobalTag.globalTag GlobalTag.Map.map,
                       refreshedExternalVarIDTable : ExternalVarID.externalVarID ExternalVarID.Map.map,
                       loc : loc}

 and rcdecl 
   = RCVAL of (valIdent * rcexp) list * loc
   | RCVALREC of {var:varIdInfo, expTy:ty, exp:rcexp} list * loc
   | RCVALPOLYREC of btvKind IEnv.map * {var:varIdInfo, expTy:ty, exp:rcexp} list * loc
   | RCLOCALDEC of rcdecl list * rcdecl list * loc
   | RCSETFIELD of rcexp * rcexp * int * ty * loc
   | RCEMPTY of loc

  val format_rcdecl : (int * Types.btvEnv) list  -> rcdecl SMLFormat.BasicFormatters.formatter
  val format_rcexp : (int * Types.btvEnv) list  -> rcexp SMLFormat.BasicFormatters.formatter
end
