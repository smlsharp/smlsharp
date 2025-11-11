(**
 * fixity of operator.
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori 
 * @version $Id: Fixity.sml,v 1.1 2008/08/06 07:37:49 ohori Exp $
 *)
structure Fixity =
struct

  (***************************************************************************)

  datatype fixity = INFIX of int | INFIXR of int | NONFIX
  fun fixityToString fixity =
      case fixity of
         INFIX n => "infix " ^ (Int.toString n)
       | INFIXR n => "infixr " ^ (Int.toString n)
       | NONFIX => "nonfix"

  (***************************************************************************)

  type loc = Loc.pos * Loc.pos

  datatype 'a exp =
      APP of 'a exp * 'a exp * loc
    | OP2 of 'a exp * ('a exp * 'a exp) * loc
    | TERM of 'a * loc

  datatype dir = L of int | R of int

  datatype 'a item =
      Infix of dir * ('a * loc)
    | Nonfix of 'a exp

  datatype 'a error =
      Conflict of ('a * loc) * ('a * loc)
    | BeginWithInfix of 'a * loc
    | EndWithInfix of 'a * loc

  datatype action = SHIFT | REDUCE | CONFLICT

  fun action (L x, INFIX y) = if x < y then SHIFT else REDUCE
    | action (R x, INFIXR y) = if x <= y then SHIFT else REDUCE
    | action (L x, INFIXR y) =
      if x = y then CONFLICT else if x < y then SHIFT else REDUCE
    | action (R x, INFIX y) =
      if x = y then CONFLICT else if x < y then SHIFT else REDUCE
    | action (_, NONFIX) = SHIFT

  fun item (INFIX x, exp, loc) = Infix (L x, (exp, loc))
    | item (INFIXR x, exp, loc) = Infix (R x, (exp, loc))
    | item (NONFIX, exp, loc) = Nonfix (TERM (exp, loc))

  fun parse error terms =
      let
        fun loc (APP (_, _, l)) = l
          | loc (OP2 (_, _, l)) = l
          | loc (TERM (_, l)) = l
        fun app (x, y) = APP (x, y, Loc.mergeRange (loc x, loc y))
        fun op2 (f, x, y) = OP2 (TERM f, (x, y), Loc.mergeRange (loc x, loc y))
        fun loop stack input =
            case (stack, input) of
              (h ::> Nonfix x ::> Nonfix y, _) =>
              loop (h ::> Nonfix (app (x, y))) input
            | (_, (NONFIX, x, l) :: t) =>
              loop (stack ::> Nonfix (TERM (x, l))) t
            | (h ::> Nonfix x ::> Infix (a, y) ::> Nonfix z, (b, w, l) :: s) =>
              (case action (a, b) of
                 SHIFT => loop (stack ::> item (b, w, l)) s
               | REDUCE => loop (h ::> Nonfix (op2 (y, x, z))) input
               | CONFLICT =>
                 (error (Conflict (y, (w, l)));
                  loop (stack ::> item (b, w, l)) s))
            | (h ::> Nonfix x ::> Infix (a, y) ::> Nonfix z, nil) =>
              loop (h ::> Nonfix (op2 (y, x, z))) nil
            | (h ::> Nonfix x, i :: s) =>
              loop (stack ::> item i) s
            | (_, (_, x, l) :: s) =>
              (error (BeginWithInfix (x, l));
               loop (stack ::> Nonfix (TERM (x, l))) s)
            | (h ::> Infix (_, e), nil) =>
              (error (EndWithInfix e);
               loop (h ::> Nonfix (TERM e)) nil)
            | (_ ::> Nonfix x, nil) =>
              x
            | (NIL, nil) =>
              raise Bug.Bug "Fixity.parse"
      in
        loop NIL terms
      end

end
