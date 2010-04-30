(**
 * The pattern calculus for the core.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @version $Id: PATTERNCALC.sig,v 1.22 2008/08/24 03:54:41 ohori Exp $
 *)
signature PATTERNCALC = sig

 datatype caseKind =
     BIND
   | MATCH
   | HANDLE
          
 datatype plexbind =
          PLEXBINDDEF of bool * string * Absyn.ty option * Loc.loc
        | PLEXBINDREP of bool * string * bool * Absyn.longid * Loc.loc

 datatype plexp = 
     PLCONSTANT of Absyn.constant * Loc.loc
   | PLGLOBALSYMBOL of string * Absyn.globalSymbolKind * Loc.loc
   | PLVAR of Absyn.longid * Loc.loc
   | PLTYPED of plexp *  Absyn.ty * Loc.loc
   | PLAPPM of plexp * plexp list * Loc.loc
   | PLLET of pdecl list * plexp list * Loc.loc
   | PLRECORD of (string * plexp) list * Loc.loc
   | PLRECORD_UPDATE of plexp * (string * plexp) list * Loc.loc
   | PLTUPLE of plexp list * Loc.loc
   | PLLIST of plexp list * Loc.loc
   | PLRAISE of plexp * Loc.loc
   | PLHANDLE of plexp * (plpat * plexp) list * Loc.loc
   | PLFNM of (plpat list * plexp) list * Loc.loc
   | PLCASEM of plexp list *  (plpat list * plexp) list * caseKind * Loc.loc
   | PLRECORD_SELECTOR of string * Loc.loc
   | PLSELECT of string * plexp * Loc.loc
   | PLSEQ of plexp list * Loc.loc
   | PLCAST of plexp * Loc.loc
   | PLFFIIMPORT of plexp * Absyn.ty * Loc.loc
   | PLFFIEXPORT of plexp * Absyn.ty * Loc.loc
   | PLFFIAPPLY of Absyn.ffiAttributes * plexp * ffiArg list * Absyn.ty * Loc.loc

 and ffiArg =
     PLFFIARG of plexp * Absyn.ty * Loc.loc
   | PLFFIARGSIZEOF of Absyn.ty * plexp option * Loc.loc
  
 and pdecl = 
     PDVAL of Absyn.kindedTvar list * (plpat * plexp ) list * Loc.loc 
   | PDDECFUN of Absyn.kindedTvar list * (plpat * (plpat list * plexp) list) list * Loc.loc 
   | PDNONRECFUN of Absyn.kindedTvar list * (plpat * (plpat list * plexp) list) * Loc.loc 
   | PDVALREC of Absyn.kindedTvar list * (plpat * plexp ) list * Loc.loc
   | (** used only for PrinterGeneration to keep the original order of bindings. *)
     PDVALRECGROUP of string list * pdecl list * Loc.loc
   | PDTYPE of (Absyn.tvar list * string * Absyn.ty) list * Loc.loc
   | PDDATATYPE of
     (Absyn.tvar list * string * (bool * string * Absyn.ty option) list) list * Loc.loc
   | PDREPLICATEDAT of string * Absyn.longid * Loc.loc
   | PDABSTYPE of
       (Absyn.tvar list * string * (bool * string * Absyn.ty option) list) list 
       * pdecl list
       * Loc.loc
   | PDEXD of plexbind list * Loc.loc
   | PDLOCALDEC of pdecl list * pdecl list * Loc.loc
   | PDOPEN of Absyn.longid list * Loc.loc
   | PDINFIXDEC of int * string list * Loc.loc
   | PDINFIXRDEC of int * string list * Loc.loc
   | PDNONFIXDEC of string list * Loc.loc
   | PDEMPTY 

 and plpat =
     PLPATWILD of Loc.loc
   | PLPATID of Absyn.longid * Loc.loc
   | PLPATCONSTANT of Absyn.constant * Loc.loc
   | PLPATCONSTRUCT of plpat * plpat * Loc.loc
   | PLPATRECORD of bool * (string * plpat) list * Loc.loc
   | PLPATLAYERED of string * Absyn.ty option * plpat * Loc.loc
   | PLPATTYPED of plpat * Absyn.ty * Loc.loc
   | PLPATORPAT of plpat * plpat * Loc.loc

 and plstrdec =
     PLCOREDEC of pdecl * Loc.loc
   | PLSTRUCTBIND of (string * plstrexp) list * Loc.loc
   | PLSTRUCTLOCAL of plstrdec list * plstrdec list * Loc.loc

 and plstrexp =
     PLSTREXPBASIC of plstrdec list * Loc.loc (*basic*)
   | PLSTRID of Absyn.longid * Loc.loc (*structure identifier*)
   | PLSTRTRANCONSTRAINT of plstrexp * plsigexp * Loc.loc (*transparent constraint*)
   | PLSTROPAQCONSTRAINT of plstrexp * plsigexp * Loc.loc (*opaque constraint*)
   | PLFUNCTORAPP of string * plstrexp * Loc.loc (* functor application*)
   | PLSTRUCTLET  of plstrdec list * plstrexp * Loc.loc (*local declaration*)

 and plsigexp = 
     PLSIGEXPBASIC of plspec * Loc.loc (*basic*)
   | PLSIGID of string * Loc.loc (*signature identifier*)
   | PLSIGWHERE of plsigexp * (Absyn.tvar list * Absyn.longid * Absyn.ty) list * Loc.loc (* type realisation *) 

 and plspec =
     PLSPECVAL of (string * Absyn.ty) list * Loc.loc (* value *)
   | PLSPECTYPE of (Absyn.tvar list * string) list * Loc.loc (* type *)
   | PLSPECTYPEEQUATION of (Absyn.tvar list * string * Absyn.ty) * Loc.loc
   | PLSPECEQTYPE of (Absyn.tvar list * string) list * Loc.loc (* eqtype *)
   | PLSPECDATATYPE of (Absyn.tvar list * string * (string * Absyn.ty option) list ) list * Loc.loc (* datatype*)
   | PLSPECREPLIC of string * Absyn.longid * Loc.loc (* replication *)
   | PLSPECEXCEPTION of (string * Absyn.ty option) list * Loc.loc (* exception *)
   | PLSPECSTRUCT of (string * plsigexp) list * Loc.loc (* structure *)
   | PLSPECINCLUDE of plsigexp * Loc.loc (* include *)
   | PLSPECSEQ of plspec * plspec * Loc.loc 
   | PLSPECSHARE of plspec * Absyn.longid list * Loc.loc 
   | PLSPECSHARESTR of plspec * Absyn.longid list * Loc.loc 
(*
   | PLSPECFUNCTOR of (string * plsigexp * plsigexp) list * Loc.loc 
*)
   | PLSPECEMPTY

 and pltopdec = 
     PLTOPDECSTR of plstrdec * Loc.loc
   | PLTOPDECSIG of ( string * plsigexp ) list * Loc.loc 
   | PLTOPDECFUN of  (string * string * plsigexp  * plstrexp * Loc.loc) list * Loc.loc 

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
