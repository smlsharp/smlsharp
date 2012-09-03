(**
 * Parser of ML source code.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: PARSER.sig,v 1.13 2007/12/05 04:07:33 kiyoshiy Exp $
 *)
signature PARSER =
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
        isPrelude : bool,
        (** if true, the parser prints prompt string before reads each line
         * of input.
         * Prompt string is specified by Control.firstLinePrompt and
         * Control.secondLinePrompt.
         *)
        withPrompt : bool,
        (**
         * A function used to print prompt.
         *)
        print : string -> unit
      }
      -> context

  (**
   * refresh parser context.
   * This function should be called to clear error status after lex/parse
   * error is found.
   *)
  val resumeContext : context -> context

  (** parse.
   * @params context
   * @param context parse context
   * @return parse result and new context. 
   *)
  val parse : context -> (Absyn.unitparseresult * context)

  val errorToString : string * Loc.pos * Loc.pos -> string

  (***************************************************************************)

end
