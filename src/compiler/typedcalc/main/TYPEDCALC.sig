(**
 * The typed pattern calculus for the IML.
 * Patters are explicitly typde.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: TYPEDCALC.sig,v 1.12 2007/02/28 15:31:26 katsu Exp $
 *)

signature TYPEDCALC = sig

  type btvKind
  type callingConvention
  type caseKind
  type conPathInfo
  type fields
  type funBindInfo
  type idState
  type loc
  type oprimInfo
  type patfields
  type primInfo
  type strInfo
  type strPathInfo
  type tvar
  type ty
  type tyBindInfo
  type tyCon
  type valId
  type varInfo
  type varPathInfo
  type constant
  type path

  datatype tpexp = 
      TPFOREIGNAPPLY of 
        {
          funExp : tpexp, 
          funTy: ty,
	  instTyList:ty list,
	  argExpList:tpexp list, 
	  argTyList : ty list,
          convention : callingConvention,
	  loc: loc
        }
   | TPEXPORTCALLBACK of 
       {
         funExp : tpexp,
         instTyList:ty list,
	 argTyList : ty list,
	 resultTy : ty,
         loc: loc
       }
   | TPSIZEOF of ty * loc
   | TPERROR
   | TPCONSTANT of constant * ty * loc
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
         instances:ty list, 
         argExpOpt:tpexp option, 
         loc: loc
        }
   | TPCONSTRUCT of 
       {
        con:conPathInfo,
        instTyList:ty list,
        argExpOpt:tpexp option,
        loc:loc
        }
   | TPAPPM of {funExp:tpexp, funTy:ty, argExpList:tpexp list, loc:loc}
   | TPMONOLET of {binds:(varPathInfo * tpexp) list, bodyExp:tpexp, loc:loc}
   | TPLET of tpdecl list * tpexp list * ty list * loc
   | TPRECORD of {fields:fields, recordTy:ty, loc:loc}
   | TPSELECT of {label:string, exp:tpexp, expTy:ty, loc:loc}
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
        btvEnv:btvKind IEnv.map,
        argVarList:varPathInfo list,
        bodyTy:ty,
        bodyExp:tpexp,
        loc:loc
        }
   | TPPOLY of {btvEnv:btvKind IEnv.map, expTyWithoutTAbs:ty, exp:tpexp, loc:loc}
   | TPTAPP of {exp:tpexp, expTy:ty, instTyList:ty list, loc:loc}
   | TPSEQ of {expList:tpexp list, expTyList:ty list, loc:loc}
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
   | TPVALREC of {var:{name:string, ty:ty }, expTy:ty, exp:tpexp } list * loc
   | TPVALRECGROUP of string list * tpdecl list * loc
   | TPPOLYFUNDECL of 
                   btvKind IEnv.map 
                   * 
                   {funVar:varPathInfo,
                    argTyList:ty list,
                    bodyTy:ty,
                    ruleList : (tppat list * tpexp) list
                    } list 
                   * 
                   loc 
   | TPVALPOLYREC of
       btvKind IEnv.map * {var:{name:string, ty:ty}, expTy:ty, exp:tpexp} list * loc
   | TPLOCALDEC of tpdecl list * tpdecl list * loc
   | TPOPEN of strPathInfo list * loc
   | TPTYPE of Types.tyBindInfo list * loc
   | TPDATADEC of tyCon list * loc
   | TPABSDEC of
     {absTyCons : tyCon list, rawTyCons : tyCon list, decls : tpdecl list}
     * loc
   | TPDATAREPDEC of
     {left : tyCon, right : {relativePath : (path * string), tyCon : tyCon}}
      * loc
   | TPEXNDEC of tpexnbind list * loc
   | TPINFIXDEC of int * string list * loc
   | TPINFIXRDEC of int * string list * loc
   | TPNONFIXDEC of string list * loc

 and tppat
   = TPPATWILD of ty * loc
   | TPPATVAR of varPathInfo * loc
   | TPPATCONSTANT of constant * ty * loc
   | TPPATCONSTRUCT of 
       {
        conPat:conPathInfo, 
        instTyList:ty list, 
        argPatOpt:tppat option, 
        patTy:ty, 
        loc:loc
        }
   | TPPATRECORD of {fields:patfields, recordTy:ty, loc:loc}
   | TPPATLAYERED of {varPat:tppat, asPat:tppat, loc:loc}
   |  TPPATORPAT of tppat * tppat * loc

 and tpexnbind =
     TPEXNBINDDEF of conPathInfo
   | TPEXNBINDREP of string * (path * string)

 (*************added for modules**************************)
		 
 datatype tpmstrdecl =
     TPMCOREDEC of tpdecl list * loc
   | TPMSTRBIND of (strInfo * tpmstrexp) list * loc
   | TPMLOCALDEC of tpmstrdecl list * tpmstrdecl list * loc
		   
 and tpmstrexp = 
      TPMSTRUCT  of tpmstrdecl list * loc
    | TPMLONGSTRID of strPathInfo * loc
    | TPMOPAQCONS  of tpmstrexp * tpmsigexp * Types.Env * loc
    | TPMTRANCONS  of tpmstrexp * tpmsigexp * Types.Env * loc
    | TPMFUNCTORAPP of
      Types.funBindInfo
      * {strArg:tpmstrexp, env:Types.Env} 
      * int IEnv.map
      * tyBindInfo ID.Map.map
      * path 
      * loc
    | TPMLET  of tpmstrdecl list * tpmstrexp * loc (* let strdecs in tptopexp end *)
  and tpmsigexp = 
      TPMSIGEXPBASIC of tpmspec 
    | TPMSIGID of string
    | TPMSIGWHERE of
      tpmsigexp *
      (path * {name: string, tyargs : btvKind IEnv.map, body : ty}) list 

  and tpmspec =
      TPMSPECERROR
    | TPMSPECVAL of {name : string,ty : ty} list 
    | TPMTYPEEQUATION of Types.tyBindInfo 
    | TPMSPECTYPE of Types.tySpec list 
    | TPMSPECEQTYPE of Types.tySpec list 
    | TPMSPECDATATYPE of tyCon list
    | TPMSPECREPLIC of {left : tyCon, right : {relativePath : (path * string), tyCon : tyCon}}
    | TPMSPECEXCEPTION of conPathInfo list
    | TPMSPECSTRUCT of (strPathInfo * tpmsigexp) list 
    | TPMSPECINCLUDE of tpmsigexp 
    | TPMSPECSEQ of tpmspec * tpmspec
    | TPMSPECSHARE of tpmspec * (path * string) list 
    | TPMSPECSHARESTR of tpmspec * path list  
    | TPMSPECEMPTY

  and tptopdecl =
      TPMDECSTR of tpmstrdecl * loc (* structure *)
    | TPMDECSIG of (Types.sigBindInfo * tpmsigexp) list * loc
    | TPMDECFUN of (funBindInfo  * string * tpmsigexp  * tpmstrexp) list * loc
    | TPMDECIMPORT of tpmspec * Types.Env * loc

  val format_btvKind : (int
                        * {eqKind:Types.eqKind, index:int,
                           recKind:Types.recKind} IEnv.map) list
                       -> {eqKind:Types.eqKind, index:int,
                           recKind:Types.recKind}
                          -> SMLFormat.FormatExpression.expression list
  val format_caseKind : caseKind -> SMLFormat.FormatExpression.expression list
  val format_conPathInfo : {funtyCon:'a, name:string, strpath:path, tag:'b,
                            ty:'c, tyCon:'d}
                           -> SMLFormat.FormatExpression.expression list
  val format_fields : (int
                       * {eqKind:Types.eqKind, index:int,
                          recKind:Types.recKind} IEnv.map) list
                      -> fields -> SMLFormat.FormatExpression.expression list
  val format_idState : (int
                        * {eqKind:Types.eqKind, index:int,
                           recKind:Types.recKind} IEnv.map) list
                       -> idState -> SMLFormat.FormatExpression.expression list
  val format_oprimInfo : {instances:'a, name:string, ty:'b}
                         -> SMLFormat.FormatExpression.expression list
  val format_patfields : (int
                          * {eqKind:Types.eqKind, index:int,
                             recKind:Types.recKind} IEnv.map) list
                         -> patfields
                            -> SMLFormat.FormatExpression.expression list
  val format_primInfo : {name:string, ty:'a}
                        -> SMLFormat.FormatExpression.expression list
  val format_strInfo : 'a list
                       -> {env:'b, id:'c, name:string}
                          -> SMLFormat.FormatExpression.expression list
  val format_strPathInfo : (int
                            * {eqKind:Types.eqKind, index:int,
                               recKind:Types.recKind} IEnv.map) list
                           -> strPathInfo
                              -> SMLFormat.FormatExpression.expression list
  val format_tpdecl : (int
                       * {eqKind:Types.eqKind, index:int,
                          recKind:Types.recKind} IEnv.map) list
                      -> tpdecl SMLFormat.BasicFormatters.formatter
  val format_tpexnbind : (int
                          * {eqKind:Types.eqKind, index:int,
                             recKind:Types.recKind} IEnv.map) list
                         -> tpexnbind SMLFormat.BasicFormatters.formatter
  val format_tpexp : (int
                      * {eqKind:Types.eqKind, index:int, recKind:Types.recKind}
                          IEnv.map) list
                     -> tpexp -> SMLFormat.FormatExpression.expression list
  val format_tpmsigexp : (int
                          * {eqKind:Types.eqKind, index:int,
                             recKind:Types.recKind} IEnv.map) list
                         -> tpmsigexp
                            -> SMLFormat.FormatExpression.expression list
  val format_tpmspec : (int
                        * {eqKind:Types.eqKind, index:int,
                           recKind:Types.recKind} IEnv.map) list
                       -> tpmspec -> SMLFormat.FormatExpression.expression list
  val format_tpmstrdecl : (int
                           * {eqKind:Types.eqKind, index:int,
                              recKind:Types.recKind} IEnv.map) list
                          -> tpmstrdecl SMLFormat.BasicFormatters.formatter
  val format_tpmstrexp : (int
                          * {eqKind:Types.eqKind, index:int,
                             recKind:Types.recKind} IEnv.map) list
                         -> tpmstrexp
                            -> SMLFormat.FormatExpression.expression list
  val format_tppat : (int
                      * {eqKind:Types.eqKind, index:int, recKind:Types.recKind}
                          IEnv.map) list
                     -> tppat SMLFormat.BasicFormatters.formatter
  val format_tptopdecl : (int
                          * {eqKind:Types.eqKind, index:int,
                             recKind:Types.recKind} IEnv.map) list
                         -> tptopdecl
                            -> SMLFormat.FormatExpression.expression list
  val format_tvar : tvar -> SMLFormat.FormatExpression.expression list
  val format_ty : (int
                   * {eqKind:Types.eqKind, index:int, recKind:Types.recKind} 
                       IEnv.map) list
                  -> ty -> SMLFormat.FormatExpression.expression list
  val format_tyCon : (int
                      * {eqKind:Types.eqKind, index:int, recKind:Types.recKind}
                          IEnv.map) list
                     -> tyCon -> SMLFormat.FormatExpression.expression list
  val format_valId : (int
                      * {eqKind:Types.eqKind, index:int, recKind:Types.recKind}
                          IEnv.map) list
                     -> valId -> SMLFormat.FormatExpression.expression list
  val format_varInfo : (int
                         * {eqKind:Types.eqKind, index:int,
                            recKind:Types.recKind} IEnv.map) list
                           -> {name:string, ty:ty}
                           -> SMLFormat.FormatExpression.expression list
  val format_varPathInfo : (int
                            * {eqKind:Types.eqKind, index:int,
                               recKind:Types.recKind} IEnv.map) list
                           -> varPathInfo
                              -> SMLFormat.FormatExpression.expression list
end
