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

  datatype 'a exp =
      APP of 'a exp * 'a exp * Loc.loc
    | OP2 of 'a exp * ('a exp * 'a exp) * Loc.loc
    | TERM of 'a * Loc.loc

  datatype error =
      Conflict
    | BeginWithInfix
    | EndWithInfix

  datatype action = SHIFT | REDUCE | CONFLICT

  fun action (INFIX x, INFIX y) = if x < y then SHIFT else REDUCE
    | action (INFIXR x, INFIXR y) = if x <= y then SHIFT else REDUCE
    | action (INFIX x, INFIXR y) =
      if x = y then CONFLICT else if x < y then SHIFT else REDUCE
    | action (INFIXR x, INFIX y) =
      if x = y then CONFLICT else if x < y then SHIFT else REDUCE
    | action (NONFIX, _) = raise Bug.Bug "action"
    | action (_, NONFIX) = raise Bug.Bug "action"

  fun parse error terms =
      let
        fun loc (APP (_, _, l)) = l
          | loc (OP2 (_, _, l)) = l
          | loc (TERM (_, l)) = l
        fun app (x, y) = APP (x, y, Loc.mergeLocs (loc x, loc y))
        fun op2 (f, x, y) = OP2 (f, (x, y), Loc.mergeLocs (loc x, loc y))
        fun loop stack input =
            case (stack, input) of
              ((NONFIX, y) :: (NONFIX, x) :: t, _) =>
              loop ((NONFIX, app (x, y)) :: t) input
            | (_, (NONFIX, x, l) :: t) =>
              loop ((NONFIX, TERM (x, l)) :: stack) t
            | ((NONFIX, z) :: (a, y) :: (NONFIX, x) :: t, (b, w, l) :: s) =>
              (case action (a, b) of
                 SHIFT => loop ((b, TERM (w, l)) :: stack) s
               | REDUCE => loop ((NONFIX, op2 (y, x, z)) :: t) input
               | CONFLICT => (error (Conflict, w, l);
                              loop ((b, TERM (w, l)) :: stack) s))
            | ((NONFIX, z) :: (a, y) :: (NONFIX, x) :: t, nil) =>
              loop ((NONFIX, op2 (y, x, z)) :: t) nil
            | ((NONFIX, x) :: _, (a, y, l) :: s) =>
              loop ((a, TERM (y, l)) :: stack) s
            | (_, (a, x, l) :: s) =>
              (error (BeginWithInfix, x, l);
               loop ((NONFIX, TERM (x, l)) :: stack) s)
            | ((NONFIX, x) :: nil, nil) =>
              x
            | ((a, TERM (x, l)) :: t, nil) =>
              (error (EndWithInfix, x, l);
               loop ((NONFIX, TERM (x, l)) :: t) nil)
            | ((a, x) :: t, nil) =>
              raise Bug.Bug "Fixity.parse: 1"
            | (nil, nil) =>
              raise Bug.Bug "Fixity.parse: 2"
      in
        loop nil terms
      end

end
