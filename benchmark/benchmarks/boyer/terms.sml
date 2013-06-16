(* terms.sml:
 *
 * Manipulations over terms
 *)

signature TERMS =
  sig
    type head;
    datatype term =
      Var of int
    | Prop of head * term list;
    datatype binding = Bind of int * term;      
    val get: string -> head
    and headname: head -> string
    and add_lemma: term -> unit
    and apply_subst: binding list -> term -> term
    and rewrite: term -> term
  end;

structure Terms:TERMS =
  struct

    datatype term
      = Var of int
      | Prop of { name: string, props: (term * term) list ref } * term list

    type head = { name: string, props: (term * term) list ref }

    val lemmas = ref ([] : head list)

(* replacement for property lists *)

    fun headname {name = n, props=p} = n;

fun get name =
  let fun get_rec ((hd1 as {name=n,...})::hdl) =
      if n = name then hd1 else get_rec hdl
        | get_rec [] =
      let val entry = {name = name, props = ref []} in
        lemmas := entry :: !lemmas;
        entry
      end
  in
    get_rec (!lemmas)
  end
;

fun add_lemma (Prop(_, [(left as Prop({props=r,...},_)), right])) =
  r := (left, right) :: !r
;

(* substitutions *)

exception failure of string;

datatype binding = Bind of int * term
;

fun get_binding v =
  let fun get_rec [] = raise (failure "unbound")
        | get_rec (Bind(w,t)::rest) =
            if v = w then t else get_rec rest
  in
    get_rec
  end
;

fun apply_subst alist =
  let fun as_rec (term as Var v) =
            ((get_binding v alist) handle failure _ => term)
        | as_rec (Prop (head,argl)) =
            Prop (head, map as_rec argl)
  in
    as_rec
  end
;

exception Unify;

fun unify (term1, term2) = unify1 (term1, term2, [])
and unify1 (term1, term2, unify_subst) =
 (case term2 of
    Var v =>
      ((if get_binding v unify_subst = term1
        then unify_subst
        else raise Unify)
       handle failure _ =>
        Bind(v,term1)::unify_subst)
  | Prop (head2,argl2) =>
      case term1 of
         Var _ => raise Unify
       | Prop (head1,argl1) =>
           if head1=head2 then unify1_lst (argl1, argl2, unify_subst)
                          else raise Unify)
and unify1_lst ([], [], unify_subst) = unify_subst
  | unify1_lst (h1::r1, h2::r2, unify_subst) =
      unify1_lst(r1, r2, unify1(h1, h2, unify_subst))
  | unify1_lst _ = raise Unify
;

fun rewrite (term as Var _) = term
  | rewrite (Prop ((head as {props=p,...}), argl)) =
      rewrite_with_lemmas (Prop (head, map rewrite argl),  !p)
and rewrite_with_lemmas (term, []) = term
  | rewrite_with_lemmas (term, (t1,t2)::rest) =
        rewrite (apply_subst (unify (term, t1)) t2)
      handle unify =>
        rewrite_with_lemmas (term, rest)
;
end;
