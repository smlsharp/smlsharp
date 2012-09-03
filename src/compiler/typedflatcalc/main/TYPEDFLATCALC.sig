(**
 * The typed flat pattern calculus after module compilation
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @author Atsushi Ohori
 * @version $Id: TYPEDFLATCALC.sig,v 1.15 2007/06/19 22:19:12 ohori Exp $
 *)
signature TYPEDFLATCALC = sig

 type loc
 type id
 type ty
 type tvar
 type tyCon
 type callingConvention
 type conInfo
 type varIdInfo
 type primInfo
 type oprimInfo
 type btvKind
 type caseKind
 datatype constant = datatype ConstantTerm.constant
 type fields
 type patfields
 type valIdent

 datatype exnbind =
          TFPEXNBINDDEF of conInfo
        | TFPEXNBINDREP  of string * string

(*
 datatype valIdent =  VALDECIDENT of varIdInfo | VALDECIDENTWILD of ty
*)
 datatype tfppat
   = TFPPATWILD of ty * loc
   | TFPPATVAR of varIdInfo * loc
   | TFPPATCONSTANT of constant * ty * loc
   | TFPPATCONSTRUCT of 
       {
        conPat:conInfo, 
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
          convention : callingConvention,
	  loc: loc
        }
    | TFPEXPORTCALLBACK of 
        {
          funExp : tfpexp,
          instTyList:ty list,
          argTyList : ty list,
          resultTy : ty,
          loc: loc
        }
   | TFPSIZEOF of ty * loc
   | TFPCONSTANT of constant * loc
   | TFPVAR of varIdInfo * loc
   | TFPGETGLOBALVALUE of BasicTypes.UInt32 * int * ty * loc
   | TFPGETFIELD of tfpexp * int * ty * loc
   | TFPARRAY of {
                  sizeExp : tfpexp,
                  initExp : tfpexp,
                  elementTy : ty ,
		  resultTy : ty,
		  loc :loc
		  }
   | TFPPRIMAPPLY of {primOp:primInfo, instTyList:ty list, argExpOpt:tfpexp option, loc:loc}
   | TFPOPRIMAPPLY of {oprimOp:oprimInfo, instances:ty list, argExpOpt:tfpexp option, loc:loc}
   | TFPCONSTRUCT of {con:conInfo, instTyList:ty list, argExpOpt:tfpexp option,loc:loc}
   | TFPAPPM of {funExp:tfpexp,funTy:ty, argExpList:tfpexp list,loc:loc}
   | TFPMONOLET of {binds:(varIdInfo * tfpexp) list, bodyExp:tfpexp, loc:loc}
   | TFPLET of tfpdecl list * tfpexp list * ty list * loc
   | TFPRECORD of {fields:fields, recordTy:ty,loc:loc}
   | TFPSELECT of {label:string, exp:tfpexp, expTy:ty, loc:loc}
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
   | TFPPOLYFNM of {btvEnv:btvKind IEnv.map, argVarList: varIdInfo list, bodyTy:ty, bodyExp:tfpexp, loc:loc}
   | TFPPOLY of {btvEnv:btvKind IEnv.map, expTyWithoutTAbs:ty, exp:tfpexp, loc:loc}
   | TFPTAPP of {exp:tfpexp, expTy:ty, instTyList:ty list, loc:loc}
   | TFPSEQ of {expList:tfpexp list, expTyList:ty list, loc:loc}      (* this must be primitive *)
   | TFPLIST of {expList:tfpexp list, listTy:ty, loc:loc}
   | TFPCAST of tfpexp * ty * loc
 and tfpdecl 
   = TFPVAL of (valIdent * tfpexp) list * loc
   | TFPVALREC of (varIdInfo * ty * tfpexp ) list * loc
   | TFPVALPOLYREC of btvKind IEnv.map * (varIdInfo * ty * tfpexp) list * loc
   | TFPLOCALDEC of tfpdecl list * tfpdecl list * loc
   | TFPSETFIELD of tfpexp * tfpexp * int * ty * loc
   | TFPSETGLOBALVALUE of BasicTypes.UInt32 * int * tfpexp * ty * loc
   | TFPINITARRAY of BasicTypes.UInt32 * int * ty * loc
   | TFPSETGLOBAL of string * tfpexp * loc

 val format_tfpdecl : (int * Types.btvEnv) list
                      -> tfpdecl SMLFormat.BasicFormatters.formatter
			 
 val format_tfpexp : (int * Types.btvEnv) list
                     -> tfpexp SMLFormat.BasicFormatters.formatter
 val format_tfppat : (int * Types.btvEnv) list
                     -> tfppat -> SMLFormat.FormatExpression.expression list
 val untypedformat_tfppat :
     tfppat -> SMLFormat.FormatExpression.expression list
	       
end
