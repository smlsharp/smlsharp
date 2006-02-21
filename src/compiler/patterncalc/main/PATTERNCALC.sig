(**
 * Copyright (c) 2006, Tohoku University.
 *
 * The pattern calculus for the core.
 *
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @version $Id: PATTERNCALC.sig,v 1.3 2006/02/18 04:59:25 ohori Exp $
 *)
signature PATTERNCALC = sig

 type loc
 type ty
 datatype constant = datatype Absyn.constant
 type tvar

 type caseKind

 type longid

 datatype plexbind =
          PLEXBINDDEF of bool * string * ty option * loc
        | PLEXBINDREP of bool * string * bool * longid * loc

 datatype plexp = 
     PLCONSTANT of constant * loc
   | PLVAR of longid * loc
   | PLTYPED of plexp *  ty * loc
   | PLAPPM of plexp * plexp list * loc
   | PLLET of pdecl list * plexp list * loc
   | PLRECORD of (string * plexp) list * loc
   | PLRECORD_UPDATE of plexp * (string * plexp) list * loc
   | PLTUPLE of plexp list * loc
   | PLRAISE of plexp * loc
   | PLHANDLE of plexp * (plpat * plexp) list * loc
   | PLFNM of (plpat list * plexp) list * loc
   | PLCASEM of plexp list *  (plpat list * plexp) list * caseKind * loc
   | PLRECORD_SELECTOR of string * loc
   | PLSELECT of string * plexp * loc
   | PLSEQ of plexp list * loc
   | PLCAST of plexp * loc

 and pdecl = 
     PDVAL of tvar list * (plpat * plexp ) list * loc 
   | PDDECFUN of tvar list * (plpat * (plpat list * plexp) list) list * loc 
   | PDNONRECFUN of tvar list * (plpat * (plpat list * plexp) list) * loc 
   | PDVALREC of tvar list * (plpat * plexp ) list * loc
   | (** used only for PrinterGeneration to keep the original order of bindings. *)
     PDVALRECGROUP of string list * pdecl list * loc
   | PDTYPE of (tvar list * string * ty) list * loc
   | PDDATATYPE of
     (tvar list * string * (bool * string * ty option) list) list * loc
   | PDREPLICATEDAT of string * longid * loc
   | PDABSTYPE of
       (tvar list * string * (bool * string * ty option) list) list 
       * pdecl list
       * loc
   | PDEXD of plexbind list * loc
   | PDLOCALDEC of pdecl list * pdecl list * loc
   | PDOPEN of longid list * loc
   | PDINFIXDEC of int * string list * loc
   | PDINFIXRDEC of int * string list * loc
   | PDNONFIXDEC of string list * loc
   | PDFFIVAL of {name:string, funExp:plexp, libExp:plexp, argTyList:ty list, resultTy:ty, loc:loc}
   | PDEMPTY 

 and plpat =
     PLPATWILD of loc
   | PLPATID of longid * loc
   | PLPATCONSTANT of constant * loc
   | PLPATCONSTRUCT of plpat * plpat * loc
   | PLPATRECORD of bool * (string * plpat) list * loc
   | PLPATLAYERED of string * ty option * plpat * loc
   | PLPATTYPED of plpat * ty * loc
 and plstrdec =
     PLCOREDEC of pdecl * loc
   | PLSTRUCTBIND of (string * plstrexp) list * loc
   | PLSTRUCTLOCAL of plstrdec list * plstrdec list * loc

 and plstrexp =
     PLSTREXPBASIC of plstrdec list * loc (*basic*)
   | PLSTRID of longid * loc (*structure identifier*)
   | PLSTRTRANCONSTRAINT of plstrexp * plsigexp * loc (*transparent constraint*)
   | PLSTROPAQCONSTRAINT of plstrexp * plsigexp * loc (*opaque constraint*)
   | PLFUNCTORAPP of string * plstrexp * loc (* functor application*)
   | PLSTRUCTLET  of plstrdec list * plstrexp * loc (*local declaration*)

 and plsigexp = 
     PLSIGEXPBASIC of plspec * loc (*basic*)
   | PLSIGID of string * loc (*signature identifier*)
   | PLSIGWHERE of plsigexp * (tvar list * longid * ty) list * loc (* type realisation *) 

 and plspec =
     PLSPECVAL of (string * ty) list * loc (* value *)
   | PLSPECTYPE of (tvar list * string) list * loc (* type *)
   | PLSPECTYPEEQUATION of (tvar list * string * ty) * loc
   | PLSPECEQTYPE of (tvar list * string) list * loc (* eqtype *)
   | PLSPECDATATYPE of (tvar list * string * (string * ty option) list ) list * loc (* datatype*)
   | PLSPECREPLIC of string * longid * loc (* replication *)
   | PLSPECEXCEPTION of (string * ty option) list * loc (* exception *)
   | PLSPECSTRUCT of (string * plsigexp) list * loc (* structure *)
   | PLSPECINCLUDE of plsigexp * loc (* include *)
   | PLSPECSEQ of plspec * plspec * loc 
   | PLSPECSHARE of plspec * longid list * loc 
   | PLSPECSHARESTR of plspec * longid list * loc 
   | PLSPECEMPTY


 and pltopdec = 
     PLTOPDECSTR of plstrdec * loc (* structure-level declaration *)
   | PLTOPDECSIG of ( string * plsigexp ) list * loc 
   | PLTOPDECFUN of  (string * string * plsigexp  * plstrexp * loc) list * loc 

  val getLeftPosExp :  plexp  -> Loc.pos
  val getRightPosExp :  plexp  -> Loc.pos 
  val getRightPosPat : plpat -> Loc.pos
  val getLeftPosPat : plpat -> Loc.pos
  val getLocExp : plexp -> Loc.loc
  val getLocPat : plpat -> Loc.loc
  val getLocDec : pdecl -> Loc.loc

  val format_caseKind : caseKind -> SMLFormat.FormatExpression.expression list
  val format_pdecl 
      : (plexp -> SMLFormat.FormatExpression.expression list) list
        * (plpat -> SMLFormat.FormatExpression.expression list) list
         -> pdecl SMLFormat.BasicFormatters.formatter
  val format_plexp 
      : (plexp -> SMLFormat.FormatExpression.expression list) list
        * (plpat -> SMLFormat.FormatExpression.expression list) list
            -> plexp -> SMLFormat.FormatExpression.expression list
  val format_plpat 
     : (plexp -> SMLFormat.FormatExpression.expression list) list
       * (plpat -> SMLFormat.FormatExpression.expression list) list
          -> plpat -> SMLFormat.FormatExpression.expression list
  val format_pltopdec
      : (plexp -> SMLFormat.FormatExpression.expression list) list
        * (plpat -> SMLFormat.FormatExpression.expression list) list
        -> pltopdec SMLFormat.BasicFormatters.formatter
  val format_plspec
      :   (plexp -> SMLFormat.FormatExpression.expression list) list
        * (plpat -> SMLFormat.FormatExpression.expression list) list
        -> plspec SMLFormat.BasicFormatters.formatter

  val format_plsigexp
      :   (plexp -> SMLFormat.FormatExpression.expression list) list
        * (plpat -> SMLFormat.FormatExpression.expression list) list
        -> plsigexp SMLFormat.BasicFormatters.formatter

  val format_plstrexp
      :   (plexp -> SMLFormat.FormatExpression.expression list) list
        * (plpat -> SMLFormat.FormatExpression.expression list) list
        -> plstrexp SMLFormat.BasicFormatters.formatter
  val format_plstrdec
      :   (plexp -> SMLFormat.FormatExpression.expression list) list
        * (plpat -> SMLFormat.FormatExpression.expression list) list
        -> plstrdec SMLFormat.BasicFormatters.formatter

end
