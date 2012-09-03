(**
 * The typed pattern calculus for the IML.
 * Patters are explicitly typde.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TYPEDCALC.sig,v 1.27 2008/08/06 17:23:40 ohori Exp $
 *)

signature TYPEDCALC = sig

  type btvEnv
  type ffiAttributes
  type caseKind
  type conPathInfo
  type exnPathInfo
  type fields
  type funBindInfo
  type idState
  type loc
  type oprimInfo
  type patfields
  type primInfo
(*
  type strInfo
*)
  type ty
  type tyBindInfo
  type tyCon
  type valId
  type varInfo
  type varPathInfo
  type constant
  type path
  type printSigInfo

  datatype tpexp = 
      TPFOREIGNAPPLY of 
        {
          funExp : tpexp, 
          funTy: ty,
	  instTyList:ty list,
	  argExpList:tpexp list, 
	  argTyList : ty list,
          attributes : ffiAttributes,
	  loc: loc
        }
   | TPEXPORTCALLBACK of 
       {
         funExp : tpexp,
	 argTyList : ty list,
	 resultTy : ty,
         attributes: ffiAttributes,
         loc: loc
       }
   | TPSIZEOF of ty * loc
   | TPERROR
   | TPCONSTANT of constant * ty * loc
   | TPGLOBALSYMBOL of string * Absyn.globalSymbolKind * ty * loc
   | TPVAR of varPathInfo * loc
   | TPRECFUNVAR of {var:varPathInfo, arity:int, loc:loc}
   | TPPRIMAPPLY of 
       {
         primOp:primInfo, 
         instTyList:ty list, 
         argExpOpt:tpexp option, 
         loc: loc
        }
   | TPOPRIMAPPLY of 
       {
         oprimOp:oprimInfo,
         keyTyList:ty list,
         instances:ty list,
         argExpOpt:tpexp option,
         loc: loc
        }
   | TPDATACONSTRUCT of 
       {
        con:conPathInfo,
        instTyList:ty list,
        argExpOpt:tpexp option,
        loc:loc
        }
   | TPEXNCONSTRUCT of 
       {
        exn:exnPathInfo,
        instTyList:ty list,
        argExpOpt:tpexp option,
        loc:loc
        }
   | TPAPPM of {funExp:tpexp, funTy:ty, argExpList:tpexp list, loc:loc}
   | TPMONOLET of {binds:(varPathInfo * tpexp) list, bodyExp:tpexp, loc:loc}
   | TPLET of tpdecl list * tpexp list * ty list * loc
   | TPRECORD of {fields:fields, recordTy:ty, loc:loc}
   | TPSELECT of {label:string, exp:tpexp, expTy:ty, resultTy:ty, loc:loc}
   | TPMODIFY of 
      {
       label:string, 
       recordExp:tpexp, 
       recordTy:ty, 
       elementExp:tpexp, 
       elementTy:ty, 
       loc:loc
       }
   | TPRAISE of tpexp * ty * loc
   | TPHANDLE of {exp:tpexp, exnVar:varPathInfo, handler:tpexp, loc:loc}
   | TPCASEM of 
       {
        expList:tpexp list,
        expTyList:ty list,
        ruleList: (tppat list * tpexp) list,
        ruleBodyTy:ty,
        caseKind: caseKind,
        loc:loc
        }
   | TPFNM of {argVarList: varPathInfo list, bodyTy:ty, bodyExp:tpexp, loc:loc}
   | TPPOLYFNM of 
       {
        btvEnv:btvEnv,
        argVarList:varPathInfo list,
        bodyTy:ty,
        bodyExp:tpexp,
        loc:loc
        }
   | TPPOLY of {btvEnv:btvEnv, expTyWithoutTAbs:ty, exp:tpexp, loc:loc}
   | TPTAPP of {exp:tpexp, expTy:ty, instTyList:ty list, loc:loc}
   | TPSEQ of {expList:tpexp list, expTyList:ty list, loc:loc}
   | TPLIST of {expList:tpexp list, listTy:ty, loc:loc}
   | TPCAST of tpexp * ty * loc

 and tpdecl 
   = TPVAL of (valId * tpexp) list * loc
   | TPFUNDECL of {
                    funVar:varPathInfo, 
                    argTyList:ty list,
                    bodyTy: ty,
                    ruleList : (tppat list * tpexp) list
                   } list
                   *
                   loc
   | TPVALREC of {var: varPathInfo, expTy:ty, exp:tpexp } list * loc
   | TPVALRECGROUP of string list * tpdecl list * loc
   | TPPOLYFUNDECL of 
                   btvEnv
                   * 
                   {funVar:varPathInfo,
                    argTyList:ty list,
                    bodyTy:ty,
                    ruleList : (tppat list * tpexp) list
                    } list 
                   * 
                   loc 
   | TPVALPOLYREC of
       btvEnv * {var:varPathInfo, expTy:ty, exp:tpexp} list * loc
   | TPLOCALDEC of tpdecl list * tpdecl list * loc
   | TPINTRO of NameMap.basicNameNPEnv * Types.Env * {original:Path.path, current:Path.path} * loc
   | TPTYPE of Types.tyBindInfo list * loc
   | TPDATADEC of Types.dataTyInfo list * loc
   | TPABSDEC of
     {absDataTyInfos : Types.dataTyInfo list, rawDataTyInfos : Types.dataTyInfo list, decls : tpdecl list}
     * loc
   | TPDATAREPDEC of
     {
      left : Types.dataTyInfo, 
      right : {name : string, dataTyInfo : Types.dataTyInfo}
     }
      * loc
   | TPEXNDEC of tpexnbind list * loc
   | TPINFIXDEC of int * string list * loc
   | TPINFIXRDEC of int * string list * loc
   | TPNONFIXDEC of string list * loc
   | TPREPLICATETYPE of (NameMap.namePath * tyBindInfo) * NameMap.namePath * loc

 and tppat
   = TPPATWILD of ty * loc
   | TPPATVAR of varPathInfo * loc
   | TPPATCONSTANT of constant * ty * loc
   | TPPATDATACONSTRUCT of 
       {
        conPat:conPathInfo, 
        instTyList:ty list, 
        argPatOpt:tppat option, 
        patTy:ty, 
        loc:loc
        }
   | TPPATEXNCONSTRUCT of 
       {
        exnPat:exnPathInfo, 
        instTyList:ty list, 
        argPatOpt:tppat option, 
        patTy:ty, 
        loc:loc
        }
   | TPPATRECORD of {fields:patfields, recordTy:ty, loc:loc}
   | TPPATLAYERED of {varPat:tppat, asPat:tppat, loc:loc}
   |  TPPATORPAT of tppat * tppat * loc

 and tpexnbind =
     TPEXNBINDDEF of exnPathInfo
   | TPEXNBINDREP of NameMap.namePath * NameMap.namePath

 and tpstrdecl =
     TPCOREDEC of tpdecl list * loc 
   | TPCONSTRAINT of tpstrdecl list *  NameMap.basicNameNPEnv * loc
   | TPFUNCTORAPP of {prefix : path,
                      funBindInfo : Types.funBindInfo,
                      argNameMapInfo : {argNamePath : path, env : NameMap.basicNameNPEnv},
                      exnTagResolutionTable : ExnTagID.id ExnTagID.Map.map,
                      refreshedExceptionTagTable : ExnTagID.id ExnTagID.Map.map,
                      typeResolutionTable : tyBindInfo TyConID.Map.map,
                      loc : loc}
   | TPANDFLATTENED of (printSigInfo * tpstrdecl list) list * loc 
   | TPSTRLOCAL of tpstrdecl list * tpstrdecl list * loc
                       
 datatype tptopdecl =
          TPDECSTR of tpstrdecl list * loc
        | TPDECSIG of (Types.sigBindInfo * PatternCalc.plsigexp) list * loc  
        | TPDECFUN of {funBindInfo :Types.funBindInfo,
                       argName : string,
                       argSpec : PatternCalc.plsigexp * NameMap.basicNameNPEnv,
                       bodyDec : (tpstrdecl list * NameMap.basicNameMap * PatternCalc.plsigexp option)
                      } list
                      * loc

  val format_caseKind : caseKind -> SMLFormat.FormatExpression.expression list
  val format_conPathInfo : conPathInfo -> SMLFormat.FormatExpression.expression list
  val format_fields : Types.formatBtvEnv
                      -> fields -> SMLFormat.FormatExpression.expression list
  val format_idState : Types.formatBtvEnv
                       -> idState -> SMLFormat.FormatExpression.expression list
  val format_oprimInfo : oprimInfo
                         -> SMLFormat.FormatExpression.expression list
  val format_patfields : Types.formatBtvEnv
                         -> patfields
                            -> SMLFormat.FormatExpression.expression list
  val format_primInfo : primInfo
                        -> SMLFormat.FormatExpression.expression list
  val format_tpdecl : Types.formatBtvEnv
                      -> tpdecl SMLFormat.BasicFormatters.formatter
  val format_tpexnbind : Types.formatBtvEnv
                         -> tpexnbind SMLFormat.BasicFormatters.formatter
  val format_tpexp : Types.formatBtvEnv
                     -> tpexp -> SMLFormat.FormatExpression.expression list
  val format_ty : Types.formatBtvEnv
                  -> ty -> SMLFormat.FormatExpression.expression list
  val format_valId : Types.formatBtvEnv
                     -> valId -> SMLFormat.FormatExpression.expression list
  val format_varInfo : Types.formatBtvEnv
                           -> {name:string, ty:ty}
                           -> SMLFormat.FormatExpression.expression list
  val format_varPathInfo : Types.formatBtvEnv
                           -> varPathInfo
                              -> SMLFormat.FormatExpression.expression list
  val format_tptopdecl : Types.formatBtvEnv ->
                         tptopdecl ->  
                         SMLFormat.FormatExpression.expression list

  val getLocTptopdecls : tptopdecl list -> Loc.loc
end
