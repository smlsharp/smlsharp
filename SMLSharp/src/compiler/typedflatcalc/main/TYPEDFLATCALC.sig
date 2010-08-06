(**
 * The typed flat pattern calculus after module compilation
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @author Atsushi Ohori
 * @version $Id: TYPEDFLATCALC.sig,v 1.29 2008/08/05 14:44:00 bochao Exp $
 *)
signature TYPEDFLATCALC = sig

 type loc
 type id
 type ty
 type tvar
 type tyCon
 type ffiAttributes
 type conInfo
 type exnInfo
 type varIdInfo
 type primInfo
 type oprimInfo
 type btvEnv
 type caseKind
 datatype constant = datatype ConstantTerm.constant
 type fields
 type patfields
 type valIdent
 type functorDecInfo
 type functorLinkInfo
(*
 datatype valIdent =  VALDECIDENT of varIdInfo | VALDECIDENTWILD of ty
*)
 datatype tfppat
   = TFPPATWILD of ty * loc
   | TFPPATVAR of varIdInfo * loc
   | TFPPATCONSTANT of constant * ty * loc
   | TFPPATDATACONSTRUCT of 
       {
        conPat:conInfo, 
        instTyList:ty list, 
        argPatOpt:tfppat option, 
        patTy:ty, 
        loc:loc
        }
   | TFPPATEXNCONSTRUCT of 
       {
        exnPat:exnInfo, 
        instTyList:ty list, 
        argPatOpt:tfppat option, 
        patTy:ty, 
        loc:loc
        }
   | TFPPATRECORD of {fields:patfields, recordTy:ty, loc:loc}
   | TFPPATLAYERED of {varPat:tfppat, asPat:tfppat, loc:loc}
   | TFPPATORPAT of tfppat * tfppat * loc

 datatype tfpexp = 
      TFPFOREIGNAPPLY of 
        {
          funExp : tfpexp, 
	  funTy: ty,
	  instTyList:ty list,
	  argExpList:tfpexp list, 
	  argTyList : ty list, 
          attributes : ffiAttributes,
	  loc: loc
        }
    | TFPEXPORTCALLBACK of 
        {
          funExp : tfpexp,
          argTyList : ty list,
          resultTy : ty,
          attributes : ffiAttributes,
          loc: loc
        }
   | TFPSIZEOF of ty * loc
   | TFPCONSTANT of constant * loc
   | TFPGLOBALSYMBOL of string * Absyn.globalSymbolKind * ty * loc
   | TFPVAR of varIdInfo * loc
(*   | TFPGETGLOBALVALUE of BasicTypes.UInt32 * int * ty * loc*)
   | TFPGETFIELD of tfpexp * int * ty * loc
   | TFPARRAY of {
                  sizeExp : tfpexp,
                  initExp : tfpexp,
                  elementTy : ty ,
		  resultTy : ty,
		  loc :loc
		  }
   | TFPPRIMAPPLY of {primOp:primInfo, instTyList:ty list, argExpOpt:tfpexp option, loc:loc}
   | TFPOPRIMAPPLY of
      {oprimOp:oprimInfo,
       keyTyList:ty list,
       instances:ty list,
       argExpOpt:tfpexp option,
       loc:loc}
   | TFPDATACONSTRUCT of {con:conInfo, instTyList:ty list, argExpOpt:tfpexp option,loc:loc}
   | TFPEXNCONSTRUCT of {exn:exnInfo, instTyList:ty list, argExpOpt:tfpexp option,loc:loc}
   | TFPAPPM of {funExp:tfpexp,funTy:ty, argExpList:tfpexp list,loc:loc}
   | TFPMONOLET of {binds:(varIdInfo * tfpexp) list, bodyExp:tfpexp, loc:loc}
   | TFPLET of tfpdecl list * tfpexp list * ty list * loc
   | TFPRECORD of {fields:fields, recordTy:ty,loc:loc}
   | TFPSELECT of {label:string, exp:tfpexp, expTy:ty, resultTy:ty, loc:loc}
   | TFPMODIFY of 
      {
       label:string, 
       recordExp:tfpexp, 
       recordTy:ty, 
       elementExp:tfpexp, 
       elementTy:ty, 
       loc:loc
       }
   | TFPRAISE of tfpexp * ty * loc
   | TFPHANDLE of {exp:tfpexp, exnVar:varIdInfo, handler:tfpexp, loc:loc}
   | TFPCASEM of 
       {
        expList:tfpexp list,
        expTyList:ty list,
        ruleList: (tfppat list * tfpexp) list,
        ruleBodyTy:ty,
        caseKind: caseKind,
        loc:loc
        }
   | TFPFNM of {argVarList: varIdInfo list, bodyTy:ty, bodyExp:tfpexp, loc:loc}
   | TFPPOLYFNM of {btvEnv:btvEnv, argVarList: varIdInfo list, bodyTy:ty, bodyExp:tfpexp, loc:loc}
   | TFPPOLY of {btvEnv:btvEnv, expTyWithoutTAbs:ty, exp:tfpexp, loc:loc}
   | TFPTAPP of {exp:tfpexp, expTy:ty, instTyList:ty list, loc:loc}
   | TFPSEQ of {expList:tfpexp list, expTyList:ty list, loc:loc}      (* this must be primitive *)
   | TFPLIST of {expList:tfpexp list, listTy:ty, loc:loc}
   | TFPCAST of tfpexp * ty * loc
 and tfpdecl 
   = TFPVAL of (valIdent * tfpexp) list * loc
   | TFPVALREC of (varIdInfo * ty * tfpexp ) list * loc
   | TFPVALPOLYREC of btvEnv * (varIdInfo * ty * tfpexp) list * loc
   | TFPLOCALDEC of tfpdecl list * tfpdecl list * loc
   | TFPSETFIELD of tfpexp * tfpexp * int * ty * loc
   | TFPEXNBINDDEF of Types.exnInfo list
   | TFPFUNCTORDEC of {name : string, 
                       formalAbstractTypeIDSet : TyConID.Set.set, 
                       formalVarIDSet : ExVarID.Set.set,
                       formalExnIDSet : ExnTagID.Set.set,
                       generativeVarIDSet : ExVarID.Set.set,
                       generativeExnIDSet : ExnTagID.Set.set,
                       bodyCode : tfpdecl list}
   | TFPLINKFUNCTORDEC of {name : string, 
                           actualArgName : string,
                           typeResolutionTable : Types.tyBindInfo TyConID.Map.map,
                           exnTagResolutionTable : ExnTagID.id ExnTagID.Map.map,
                           externalVarIDResolutionTable : ExVarID.id ExVarID.Map.map,
                           refreshedExceptionTagTable : ExnTagID.id ExnTagID.Map.map,
                           refreshedExternalVarIDTable : ExVarID.id ExVarID.Map.map,
                           loc : loc}

 datatype basicBlock =
          TFPVALBLOCK of {code : tfpdecl list, exnIDSet : ExnTagID.Set.set}
        | TFPLINKFUNCTORBLOCK of functorLinkInfo

 datatype topBlock = 
          TFPFUNCTORBLOCK of {name : string, 
                              formalAbstractTypeIDSet : TyConID.Set.set, 
                              formalVarIDSet : ExVarID.Set.set,
                              formalExnIDSet : ExnTagID.Set.set,
                              generativeVarIDSet : ExVarID.Set.set,
                              generativeExnIDSet : ExnTagID.Set.set,
                              bodyCode : basicBlock list}      
        | TFPBASICBLOCK of basicBlock

 val format_tfpdecl : Types.formatBtvEnv
                      -> tfpdecl SMLFormat.BasicFormatters.formatter
			 
 val format_tfpexp : Types.formatBtvEnv
                     -> tfpexp SMLFormat.BasicFormatters.formatter
 val format_tfppat : Types.formatBtvEnv
                     -> tfppat -> SMLFormat.FormatExpression.expression list
 val untypedformat_tfppat :
     tfppat -> SMLFormat.FormatExpression.expression list

 val format_topBlock : topBlock -> SMLFormat.FormatExpression.expression list
end
