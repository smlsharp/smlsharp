(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Parser of ML source code.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: PARSER.sig,v 1.6 2006/02/18 04:59:24 ohori Exp $
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
        getLine : int -> string
      }
      -> context

  val resumeContext : context -> context

  (** parse.
   * @params context
   * @param context parse context
   * @return parse result and new context. 
   *)
  val parse : context -> (Absyn.parseresult * context)

  val errorToString : string * Loc.pos * Loc.pos -> string

  (***************************************************************************)

end
