(**
 * exceptions indicating runtime error.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RuntimeErrors.sml,v 1.5 2006/02/28 16:11:13 kiyoshiy Exp $
 *)
structure RuntimeErrors =
struct

  (***************************************************************************)

  (** raised if program aborts by user error *)
  exception Abort

  (** raised if an signal interrupted the exeuction. *)
  exception Interrupted

  (** indicates maybe a bug in compiler *)
  exception InvalidCode of string

  (** indicates an invalid status maybe due to a bug. *)
  exception InvalidStatus of string

  (** indicates unexpected arity or type of arguments to a primitive
   * operator. *)
  exception UnexpectedPrimitiveArguments of string

  (** general exception for other causes. *)
  exception Error of string

  (***************************************************************************)

end;
