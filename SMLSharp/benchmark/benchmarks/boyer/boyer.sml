(* boyer.sml:
 *
 * Tautology checker
 *)

signature BOYER =
  sig
    include TERMS
    val tautp: term -> bool
  end

structure Boyer: BOYER =
  struct

open Terms

fun mem x [] = false
  | mem x (y::L) = x=y orelse mem x L

fun truep (x, lst) =
  case x of
    Prop(head, _) =>
      headname head = "true" orelse mem x lst
  | _ =>
      mem x lst

and falsep (x, lst) =
  case x of
    Prop(head, _) =>
      headname head = "false" orelse mem x lst
  | _ =>
      mem x lst

fun tautologyp (x, true_lst, false_lst) =
 if truep (x, true_lst) then true else
 if falsep (x, false_lst) then false else
 (case x of
     Var _ => false
   | Prop (head,[test, yes, no]) =>
        if headname head = "if" then
          if truep (test, true_lst) then
            tautologyp (yes, true_lst, false_lst)
          else if falsep (test, false_lst) then
            tautologyp (no, true_lst, false_lst)
          else tautologyp (yes, test::true_lst, false_lst) andalso
               tautologyp (no, true_lst, test::false_lst)
        else
          false)

    fun tautp x = tautologyp(rewrite x, [], []);

  end; (* Boyer *)

(* the benchmark *)
structure Main =
  struct

    open Terms;
    open Boyer;

val subst =
[Bind(23,
             Prop
              (get "f",
               [Prop
                (get "plus",
                 [Prop (get "plus",[Var 0, Var 1]),
                  Prop (get "plus",[Var 2, Prop (get "zero",[])])])])),
 Bind(24,
             Prop
              (get "f",
               [Prop
                (get "times",
                 [Prop (get "times",[Var 0, Var 1]),
                  Prop (get "plus",[Var 2, Var 3])])])),
 Bind(25,
             Prop
              (get "f",
               [Prop
                (get "reverse",
                 [Prop
                  (get "append",
                   [Prop (get "append",[Var 0, Var 1]),
                    Prop (get "nil",[])])])])),
 Bind(20,
             Prop
              (get "equal",
               [Prop (get "plus",[Var 0, Var 1]),
                Prop (get "difference",[Var 23, Var 24])])),
 Bind(22,
             Prop
              (get "lt",
               [Prop (get "remainder",[Var 0, Var 1]),
                Prop (get "member",[Var 0, Prop (get "length",[Var 1])])]))]

val term =
           Prop
            (get "implies",
             [Prop
              (get "and",
               [Prop (get "implies",[Var 23, Var 24]),
                Prop
                (get "and",
                 [Prop (get "implies",[Var 24, Var 25]),
                  Prop
                  (get "and",
                   [Prop (get "implies",[Var 25, Var 20]),
                    Prop (get "implies",[Var 20, Var 22])])])]),
              Prop (get "implies",[Var 23, Var 22])])
(*
    fun testit outstrm = if tautp (apply_subst subst term)
	  then TextIO.output (outstrm, "Proved!\n")
	  else TextIO.output (outstrm, "Cannot prove!\n")
*)
    fun doit () = (tautp (apply_subst subst term); ())

  end; (* Main *)

