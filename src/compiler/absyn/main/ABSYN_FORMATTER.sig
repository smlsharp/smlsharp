(**
 * a pretty printer for the raw symtax of core ML.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ABSYN_FORMATTER.sig,v 1.6 2006/02/28 16:10:58 kiyoshiy Exp $
 *)
signature ABSYN_FORMATTER =
sig

  (***************************************************************************)

  (** translates parse result to string. *)
  val parseResultToString : Absyn.parseresult -> string

  (** translates location to string. *)
  val locToString : Loc.loc -> string

  (** translates declaration to string. *)
  val decToString : Absyn.dec -> string

  (** translates expression to string. *)
  val expToString : Absyn.exp -> string

  (** translates top level declaration to string. *)
  val topdecToString : Absyn.topdec -> string

  (***************************************************************************)

end
	
