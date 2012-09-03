(**
 * Parser of ML source code.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: INTERFACEPARSER.sig,v 1.1 2007/10/18 01:20:41 bochao Exp $
 *)
signature INTERFACEPARSER =
sig

  (***************************************************************************)

  (** parse context *)
  type context

  (***************************************************************************)

  (** raised when whole source code is parsed. *)
  exception EndOfParse

  (** parse error *)
  exception ParseError

  (***************************************************************************)

  (**
   * create fresh parse context.
   *)
  val createContext :
      {
        (** name of source *)
        sourceName : string,
        (** called when lex/parse error found. *)
        onError : string * Loc.pos * Loc.pos -> unit,
        (** this should return one line from source. *)
        getLine : int -> string,
        (** enables special syntax for prelude *)
        isPrelude : bool
      }
      -> context

  val resumeContext : context -> context

  (** parse.
   * @params context
   * @param context parse context
   * @return parse result and new context. 
   *)
  val parse : context -> (Absyn.interfaceparseresult * context)

  val errorToString : string * Loc.pos * Loc.pos -> string

  (***************************************************************************)

end
